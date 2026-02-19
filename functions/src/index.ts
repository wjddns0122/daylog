import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getFunctions } from "firebase-admin/functions";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { onTaskDispatched } from "firebase-functions/v2/tasks";
import { generateCurationAndMusic, suggestKeywordsFromImage } from "./ai";

admin.initializeApp();
const db = admin.firestore();

const PROCESS_DELAY_SECONDS = 1 * 60; // TODO: revert to 6 * 60 * 60 after testing
const PROCESSING_LEASE_MS = 10 * 60 * 1000;

type ProcessPostPayload = {
  postId: string;
};

type FollowRequestStatus = "PENDING" | "ACCEPTED" | "REJECTED" | "CANCELED";

type FollowRequestDoc = {
  requesterId: string;
  targetUserId: string;
  status: FollowRequestStatus;
  createdAt?: unknown;
  updatedAt?: unknown;
};

const isEmulator = process.env.FUNCTIONS_EMULATOR === "true";

const enqueueProcessPost = async (
  postId: string,
  scheduleDelaySeconds: number,
): Promise<void> => {
  if (isEmulator) {
    // In emulator, Cloud Tasks is not available. Use setTimeout instead.
    console.info(
      `[Emulator] Scheduling processPostDirect for ${postId} in ${scheduleDelaySeconds}s`,
    );
    setTimeout(() => {
      processPostDirect(postId).catch((err) =>
        console.error("[Emulator] processPostDirect failed:", err),
      );
    }, scheduleDelaySeconds * 1000);
    return;
  }

  await getFunctions()
    .taskQueue("processPost")
    .enqueue({ postId }, { scheduleDelaySeconds });
};

const followEdgeDocId = (followerId: string, followingId: string): string =>
  `${followerId}_${followingId}`;

const createNotification = async (
  userId: string,
  type: string,
  title: string,
  message: string,
  payload: Record<string, unknown>,
): Promise<void> => {
  await db.collection("notifications").add({
    userId,
    type,
    title,
    message,
    isRead: false,
    payload,
    createdAt: FieldValue.serverTimestamp(),
  });
};

const sendReleaseNotification = async (
  userId: string,
  postId: string,
): Promise<void> => {
  await db.collection("notifications").add({
    userId,
    postId,
    type: "filmDeveloped",
    isRead: false,
    createdAt: FieldValue.serverTimestamp(),
    payload: {
      relatedPostId: postId,
    },
  });
};

/**
 * Suggest mood keywords from an uploaded image.
 * Called from Compose Screen before post creation.
 */
export const suggestMoodKeywords = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be logged in.",
      );
    }

    const { imageUrl } = data as { imageUrl?: string };

    if (!imageUrl) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required field: imageUrl",
      );
    }

    try {
      const keywords = await suggestKeywordsFromImage(imageUrl);
      return { success: true, keywords };
    } catch (error) {
      console.error("suggestMoodKeywords failed:", error);
      return {
        success: true,
        keywords: ["감성적", "따뜻한", "잔잔한", "추억", "평화로운"],
      };
    }
  },
);

export const createPostIntent = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be logged in.",
      );
    }

    const uid = context.auth.uid;
    const { imagePath, caption, requestId, visibility, moodKeywords } =
      data as {
        imagePath?: string;
        caption?: string;
        requestId?: string;
        visibility?: string;
        moodKeywords?: string[];
      };

    const normalizedVisibility =
      typeof visibility === "string" ? visibility.toUpperCase() : "PRIVATE";

    if (!imagePath || !requestId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required fields (imagePath, requestId).",
      );
    }

    const safeCaption = caption ?? "";
    const safeMoodKeywords = Array.isArray(moodKeywords) ? moodKeywords : [];

    if (!["PRIVATE", "PUBLIC"].includes(normalizedVisibility)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Invalid visibility value.",
      );
    }

    const today = new Date().toISOString().split("T")[0];
    const dailyKey = `${uid}_${today}`;
    const releaseTime = Timestamp.fromDate(
      new Date(Date.now() + PROCESS_DELAY_SECONDS * 1000),
    );

    const postRef = db.collection("posts").doc();
    let targetPostId = postRef.id;
    let targetReleaseTime = releaseTime;
    let shouldEnqueue = false;

    try {
      await db.runTransaction(async (t) => {
        const lockRef = db.collection("daily_locks").doc(dailyKey);
        const lockDoc = await t.get(lockRef);

        if (lockDoc.exists) {
          throw new functions.https.HttpsError(
            "already-exists",
            "ALREADY_POSTED",
          );
        }

        const existingByRequest = await t.get(
          db.collection("posts").where("requestId", "==", requestId).limit(1),
        );

        if (!existingByRequest.empty) {
          const existingDoc = existingByRequest.docs[0];
          targetPostId = existingDoc.id;

          const existingData = existingDoc.data();
          if (existingData.releaseTime instanceof Timestamp) {
            targetReleaseTime = existingData.releaseTime;
          }

          return;
        }

        t.set(lockRef, {
          createdAt: FieldValue.serverTimestamp(),
          postId: postRef.id,
        });

        t.set(postRef, {
          authorId: uid,
          status: "PENDING",
          visibility: normalizedVisibility,
          imageUrl: imagePath,
          caption: safeCaption,
          moodKeywords: safeMoodKeywords,
          releaseTime,
          createdAt: FieldValue.serverTimestamp(),
          dailyKey,
          version: 1,
          requestId,
          likedBy: [],
        });

        shouldEnqueue = true;
      });

      if (shouldEnqueue) {
        try {
          await enqueueProcessPost(targetPostId, PROCESS_DELAY_SECONDS);
        } catch (error) {
          console.error("Failed to enqueue processPost:", error);
          throw new functions.https.HttpsError(
            "internal",
            "Post was created, but scheduling failed.",
          );
        }
      }

      return {
        success: true,
        data: {
          postId: targetPostId,
          status: "PENDING",
          visibility: normalizedVisibility,
          releaseTime: targetReleaseTime.toDate().toISOString(),
        },
      };
    } catch (error: unknown) {
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      console.error("createPostIntent failed:", error);
      throw new functions.https.HttpsError("internal", "Transaction failed");
    }
  },
);

export const sendFollowRequest = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
  }

  const requesterId = context.auth.uid;
  const { targetUserId } = data as { targetUserId?: string };

  if (!targetUserId || typeof targetUserId !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "Missing targetUserId.");
  }
  if (targetUserId === requesterId) {
    throw new functions.https.HttpsError("invalid-argument", "Cannot follow yourself.");
  }

  const edgeRef = db.collection("follows").doc(followEdgeDocId(requesterId, targetUserId));
  const requesterUserRef = db.collection("users").doc(requesterId);
  const targetUserRef = db.collection("users").doc(targetUserId);

  await db.runTransaction(async (t) => {
    const existingEdge = await t.get(edgeRef);

    if (existingEdge.exists) {
      return;
    }

    t.set(edgeRef, {
      followerId: requesterId,
      followingId: targetUserId,
      createdAt: FieldValue.serverTimestamp(),
    });
    t.set(
      requesterUserRef,
      {
        followingCount: FieldValue.increment(1),
      },
      { merge: true },
    );
    t.set(
      targetUserRef,
      {
        followersCount: FieldValue.increment(1),
      },
      { merge: true },
    );
  });

  await createNotification(
    targetUserId,
    "follow_accepted",
    "새 팔로워",
    "새로운 사용자가 회원님을 팔로우합니다.",
    {
      actorUserId: requesterId,
      targetUserId,
    },
  );

  return { success: true, status: "FOLLOWING_CREATED" };
});

export const cancelFollowRequest = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
  }

  const followerId = context.auth.uid;
  const { targetUserId } = data as { targetUserId?: string };

  if (!targetUserId || typeof targetUserId !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "Missing targetUserId.");
  }

  const edgeRef = db.collection("follows").doc(followEdgeDocId(followerId, targetUserId));

  await db.runTransaction(async (t) => {
    const edgeDoc = await t.get(edgeRef);
    if (!edgeDoc.exists) {
      return;
    }

    t.delete(edgeRef);
    t.set(
      db.collection("users").doc(followerId),
      {
        followingCount: FieldValue.increment(-1),
      },
      { merge: true },
    );
    t.set(
      db.collection("users").doc(targetUserId),
      {
        followersCount: FieldValue.increment(-1),
      },
      { merge: true },
    );
  });

  return { success: true };
});

export const acceptFollowRequest = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
  }

  const targetUserId = context.auth.uid;
  const { requestId } = data as { requestId?: string };
  if (!requestId || typeof requestId !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "Missing requestId.");
  }

  const requestRef = db.collection("follow_requests").doc(requestId);

  let requesterId = "";
  await db.runTransaction(async (t) => {
    const requestDoc = await t.get(requestRef);
    if (!requestDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Follow request not found.");
    }

    const request = requestDoc.data() as FollowRequestDoc;
    if (request.targetUserId !== targetUserId) {
      throw new functions.https.HttpsError("permission-denied", "Not allowed.");
    }

    requesterId = request.requesterId;
    if (request.status !== "PENDING") {
      return;
    }

    const edgeRef = db.collection("follows").doc(followEdgeDocId(request.requesterId, targetUserId));
    const requesterUserRef = db.collection("users").doc(request.requesterId);
    const targetUserRef = db.collection("users").doc(targetUserId);

    t.set(edgeRef, {
      followerId: request.requesterId,
      followingId: targetUserId,
      createdAt: FieldValue.serverTimestamp(),
    });
    t.update(requestRef, {
      status: "ACCEPTED",
      updatedAt: FieldValue.serverTimestamp(),
    });
    t.set(
      requesterUserRef,
      {
        followingCount: FieldValue.increment(1),
      },
      { merge: true },
    );
    t.set(
      targetUserRef,
      {
        followersCount: FieldValue.increment(1),
      },
      { merge: true },
    );
  });

  if (requesterId) {
    await createNotification(
      requesterId,
      "follow_accepted",
      "팔로우 요청 수락됨",
      "당신의 팔로우 요청이 수락되었습니다.",
      {
        requesterId,
        targetUserId,
        requestId,
      },
    );
  }

  return { success: true };
});

export const rejectFollowRequest = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
  }

  const targetUserId = context.auth.uid;
  const { requestId } = data as { requestId?: string };
  if (!requestId || typeof requestId !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "Missing requestId.");
  }

  const requestRef = db.collection("follow_requests").doc(requestId);
  let requesterId = "";

  await db.runTransaction(async (t) => {
    const requestDoc = await t.get(requestRef);
    if (!requestDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Follow request not found.");
    }

    const request = requestDoc.data() as FollowRequestDoc;
    if (request.targetUserId !== targetUserId) {
      throw new functions.https.HttpsError("permission-denied", "Not allowed.");
    }

    requesterId = request.requesterId;
    if (request.status !== "PENDING") {
      return;
    }

    t.update(requestRef, {
      status: "REJECTED",
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  if (requesterId) {
    await createNotification(
      requesterId,
      "follow_rejected",
      "팔로우 요청 거절됨",
      "당신의 팔로우 요청이 거절되었습니다.",
      {
        requesterId,
        targetUserId,
        requestId,
      },
    );
  }

  return { success: true };
});

export const unfollowUser = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
  }

  const followerId = context.auth.uid;
  const { targetUserId } = data as { targetUserId?: string };
  if (!targetUserId || typeof targetUserId !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "Missing targetUserId.");
  }

  const edgeRef = db.collection("follows").doc(followEdgeDocId(followerId, targetUserId));

  await db.runTransaction(async (t) => {
    const edgeDoc = await t.get(edgeRef);
    if (!edgeDoc.exists) {
      return;
    }

    t.delete(edgeRef);
    t.set(
      db.collection("users").doc(followerId),
      {
        followingCount: FieldValue.increment(-1),
      },
      { merge: true },
    );
    t.set(
      db.collection("users").doc(targetUserId),
      {
        followersCount: FieldValue.increment(-1),
      },
      { merge: true },
    );
  });

  return { success: true };
});

const processPostDirect = async (postId: string): Promise<void> => {
  if (typeof postId !== "string" || postId.trim().length === 0) {
    console.error("processPostDirect: invalid postId", postId);
    return;
  }

  const postRef = db.collection("posts").doc(postId);

  let imageUrl = "";
  let authorId = "";
  let caption = "";
  let moodKeywords: string[] = [];
  let acquiredLease = false;

  try {
    await db.runTransaction(async (t) => {
      const snapshot = await t.get(postRef);
      if (!snapshot.exists) {
        return;
      }

      const post = snapshot.data()!;

      if (post.status === "RELEASED") {
        return;
      }

      if (post.status !== "PENDING") {
        return;
      }

      if (
        post.releaseTime instanceof Timestamp &&
        Timestamp.now() < post.releaseTime
      ) {
        return;
      }

      if (
        typeof post.imageUrl !== "string" ||
        typeof post.authorId !== "string"
      ) {
        throw new Error("Invalid post payload for processing");
      }

      imageUrl = post.imageUrl;
      authorId = post.authorId;
      caption = post.caption || "";
      moodKeywords = Array.isArray(post.moodKeywords) ? post.moodKeywords : [];
      acquiredLease = true;

      t.update(postRef, {
        status: "PROCESSING",
        version: FieldValue.increment(1),
        leaseOwner: `task_${Date.now()}`,
        leaseExpiresAt: Timestamp.fromMillis(Date.now() + PROCESSING_LEASE_MS),
        processingStartedAt: FieldValue.serverTimestamp(),
      });
    });

    if (!acquiredLease) {
      return;
    }

    const aiResult = await generateCurationAndMusic(
      imageUrl,
      moodKeywords,
      caption,
    );

    await db.runTransaction(async (t) => {
      const snapshot = await t.get(postRef);
      if (!snapshot.exists) {
        return;
      }

      const post = snapshot.data()!;
      if (post.status !== "PROCESSING") {
        return;
      }

      t.update(postRef, {
        status: "RELEASED",
        version: FieldValue.increment(1),
        ai: {
          curation: aiResult.curation,
          youtubeUrl: aiResult.youtubeUrl,
          youtubeTitle: aiResult.youtubeTitle,
          songTitle: aiResult.songTitle,
          musicReason: aiResult.musicReason,
        },
        processedAt: FieldValue.serverTimestamp(),
        leaseOwner: FieldValue.delete(),
        leaseExpiresAt: FieldValue.delete(),
      });
    });

    await sendReleaseNotification(authorId, postId);
  } catch (error) {
    console.error("processPostDirect failed:", { postId, error });

    if (acquiredLease) {
      await postRef.update({
        status: "PENDING",
        leaseOwner: FieldValue.delete(),
        leaseExpiresAt: FieldValue.delete(),
        lastError: String(error),
        processAttempts: FieldValue.increment(1),
      });
    }

    throw error;
  }
};

export const processPost = onTaskDispatched(
  {
    memory: "512MiB",
    timeoutSeconds: 120,
  },
  async (request) => {
    const payload = request.data as ProcessPostPayload | undefined;
    const postId = payload?.postId;

    if (typeof postId !== "string" || postId.trim().length === 0) {
      console.error("processPost: invalid payload", payload);
      return;
    }

    await processPostDirect(postId);
  },
);

export const repairWorker = functions.https.onRequest(async (_req, res) => {
  const now = Timestamp.now();
  const snapshot = await db
    .collection("posts")
    .where("status", "==", "PROCESSING")
    .where("leaseExpiresAt", "<", now)
    .get();

  const batch = db.batch();
  const requeueJobs: Array<Promise<void>> = [];
  let count = 0;

  snapshot.forEach((doc) => {
    batch.update(doc.ref, {
      status: "PENDING",
      leaseOwner: FieldValue.delete(),
      leaseExpiresAt: FieldValue.delete(),
      processAttempts: FieldValue.increment(1),
    });

    requeueJobs.push(enqueueProcessPost(doc.id, 0));
    count++;
  });

  if (count > 0) {
    await batch.commit();

    const requeueResults = await Promise.allSettled(requeueJobs);
    const failedRequeues = requeueResults.filter(
      (r) => r.status === "rejected",
    ).length;

    if (failedRequeues > 0) {
      console.error("repairWorker: failed to requeue some posts", {
        failedRequeues,
      });
    }

    res.json({ repaired: count, failedRequeues });
    return;
  }

  res.json({ repaired: 0, failedRequeues: 0 });
});
