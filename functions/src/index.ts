import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { Timestamp, FieldValue } from "firebase-admin/firestore";

admin.initializeApp();
const db = admin.firestore();

export const createPostIntent = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be logged in.",
      );
    }
    const uid = context.auth.uid;
    const { imagePath, caption, requestId } = data;

    if (!imagePath || !caption || !requestId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required fields.",
      );
    }

    const today = new Date().toISOString().split("T")[0];
    const dailyKey = `${uid}_${today}`;
    const releaseTime = Timestamp.fromDate(
      new Date(Date.now() + 6 * 60 * 60 * 1000),
    );

    const postRef = db.collection("posts").doc();

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

        const querySnapshot = await t.get(
          db.collection("posts").where("requestId", "==", requestId).limit(1),
        );
        if (!querySnapshot.empty) {
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
      });

      return {
        success: true,
        data: {
          postId: postRef.id,
          status: "PENDING",
          releaseTime: releaseTime.toDate().toISOString(),
        },
      };
    } catch (error: any) {
      if (error.code === "already-exists") {
        throw error;
      }
      console.error("Transaction failure:", error);
      throw new functions.https.HttpsError("internal", "Transaction failed");
    }
  },
);

export const releaseWorker = functions.https.onRequest(async (req, res) => {
  const { postId } = req.body;
  if (!postId) {
    res.status(400).send("Missing postId");
    return;
  }

  const postRef = db.collection("posts").doc(postId);

  try {
    await db.runTransaction(async (t) => {
      const doc = await t.get(postRef);
      if (!doc.exists) return;

      const data = doc.data()!;
      if (data.status !== "PENDING") return;

      const now = Timestamp.now();
      if (now < data.releaseTime) return;

      t.update(postRef, {
        status: "PROCESSING",
        version: FieldValue.increment(1),
        leaseOwner: "worker_" + Date.now(),
        leaseExpiresAt: Timestamp.fromMillis(Date.now() + 10 * 60 * 1000),
      });
    });

    await db.runTransaction(async (t) => {
      const doc = await t.get(postRef);
      if (!doc.exists) return;
      const data = doc.data()!;
      if (data.status !== "PROCESSING") return;

      t.update(postRef, {
        status: "RELEASED",
        version: FieldValue.increment(1),
        ai: { mood: "Simulated Warmth", music: "LoFi Beats" },
        processedAt: FieldValue.serverTimestamp(),
      });
    });

    res.json({ success: true });
  } catch (error) {
    console.error(error);
    res.status(500).send("Internal Error");
  }
});

export const repairWorker = functions.https.onRequest(async (req, res) => {
  const now = Timestamp.now();
  const snapshot = await db
    .collection("posts")
    .where("status", "==", "PROCESSING")
    .where("leaseExpiresAt", "<", now)
    .get();

  const batch = db.batch();
  let count = 0;

  snapshot.forEach((doc) => {
    batch.update(doc.ref, {
      status: "PENDING",
      leaseOwner: FieldValue.delete(),
      leaseExpiresAt: FieldValue.delete(),
      processAttempts: FieldValue.increment(1),
    });
    count++;
  });

  if (count > 0) {
    await batch.commit();
  }

  res.json({ repaired: count });
});
