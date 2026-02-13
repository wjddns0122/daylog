import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getFunctions } from "firebase-admin/functions";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { onTaskDispatched } from "firebase-functions/v2/tasks";
import { generateCurationAndMusic } from "./ai";

admin.initializeApp();
const db = admin.firestore();

const PROCESS_DELAY_SECONDS = 1 * 60; // TODO: revert to 6 * 60 * 60 after testing
const PROCESSING_LEASE_MS = 10 * 60 * 1000;

type ProcessPostPayload = {
  postId: string;
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

const sendReleaseNotificationPlaceholder = async (
  userId: string,
  postId: string,
): Promise<void> => {
  console.info("FCM placeholder: send RELEASED notification", {
    userId,
    postId,
  });
};

export const createPostIntent = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be logged in.",
      );
    }

    const uid = context.auth.uid;
    const { imagePath, caption, requestId } = data as {
      imagePath?: string;
      caption?: string;
      requestId?: string;
    };

    if (!imagePath || !caption || !requestId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required fields.",
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
          imageUrl: imagePath,
          caption,
          releaseTime,
          createdAt: FieldValue.serverTimestamp(),
          dailyKey,
          version: 1,
          requestId,
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

const processPostDirect = async (postId: string): Promise<void> => {
  if (typeof postId !== "string" || postId.trim().length === 0) {
    console.error("processPostDirect: invalid postId", postId);
    return;
  }

  const postRef = db.collection("posts").doc(postId);

  let imageUrl = "";
  let authorId = "";
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

    const aiResult = await generateCurationAndMusic(imageUrl);

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
        },
        processedAt: FieldValue.serverTimestamp(),
        leaseOwner: FieldValue.delete(),
        leaseExpiresAt: FieldValue.delete(),
      });
    });

    await sendReleaseNotificationPlaceholder(authorId, postId);
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

export const processPost = onTaskDispatched(async (request) => {
  const payload = request.data as ProcessPostPayload | undefined;
  const postId = payload?.postId;

  if (typeof postId !== "string" || postId.trim().length === 0) {
    console.error("processPost: invalid payload", payload);
    return;
  }

  await processPostDirect(postId);
});

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
