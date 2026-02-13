"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.repairWorker = exports.releaseWorker = exports.createPostIntent = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const firestore_1 = require("firebase-admin/firestore");
admin.initializeApp();
const db = admin.firestore();
exports.createPostIntent = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
    }
    const uid = context.auth.uid;
    const { imagePath, caption, requestId } = data;
    if (!imagePath || !caption || !requestId) {
        throw new functions.https.HttpsError("invalid-argument", "Missing required fields.");
    }
    const today = new Date().toISOString().split("T")[0];
    const dailyKey = `${uid}_${today}`;
    const releaseTime = firestore_1.Timestamp.fromDate(new Date(Date.now() + 6 * 60 * 60 * 1000));
    const postRef = db.collection("posts").doc();
    try {
        await db.runTransaction(async (t) => {
            const lockRef = db.collection("daily_locks").doc(dailyKey);
            const lockDoc = await t.get(lockRef);
            if (lockDoc.exists) {
                throw new functions.https.HttpsError("already-exists", "ALREADY_POSTED");
            }
            const querySnapshot = await t.get(db.collection("posts").where("requestId", "==", requestId).limit(1));
            if (!querySnapshot.empty) {
                return;
            }
            t.set(lockRef, {
                createdAt: firestore_1.FieldValue.serverTimestamp(),
                postId: postRef.id,
            });
            t.set(postRef, {
                authorId: uid,
                status: "PENDING",
                imageUrl: imagePath,
                caption,
                releaseTime,
                createdAt: firestore_1.FieldValue.serverTimestamp(),
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
    }
    catch (error) {
        if (error.code === "already-exists") {
            throw error;
        }
        console.error("Transaction failure:", error);
        throw new functions.https.HttpsError("internal", "Transaction failed");
    }
});
exports.releaseWorker = functions.https.onRequest(async (req, res) => {
    const { postId } = req.body;
    if (!postId) {
        res.status(400).send("Missing postId");
        return;
    }
    const postRef = db.collection("posts").doc(postId);
    try {
        await db.runTransaction(async (t) => {
            const doc = await t.get(postRef);
            if (!doc.exists)
                return;
            const data = doc.data();
            if (data.status !== "PENDING")
                return;
            const now = firestore_1.Timestamp.now();
            if (now < data.releaseTime)
                return;
            t.update(postRef, {
                status: "PROCESSING",
                version: firestore_1.FieldValue.increment(1),
                leaseOwner: "worker_" + Date.now(),
                leaseExpiresAt: firestore_1.Timestamp.fromMillis(Date.now() + 10 * 60 * 1000),
            });
        });
        await db.runTransaction(async (t) => {
            const doc = await t.get(postRef);
            if (!doc.exists)
                return;
            const data = doc.data();
            if (data.status !== "PROCESSING")
                return;
            t.update(postRef, {
                status: "RELEASED",
                version: firestore_1.FieldValue.increment(1),
                ai: { mood: "Simulated Warmth", music: "LoFi Beats" },
                processedAt: firestore_1.FieldValue.serverTimestamp(),
            });
        });
        res.json({ success: true });
    }
    catch (error) {
        console.error(error);
        res.status(500).send("Internal Error");
    }
});
exports.repairWorker = functions.https.onRequest(async (req, res) => {
    const now = firestore_1.Timestamp.now();
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
            leaseOwner: firestore_1.FieldValue.delete(),
            leaseExpiresAt: firestore_1.FieldValue.delete(),
            processAttempts: firestore_1.FieldValue.increment(1),
        });
        count++;
    });
    if (count > 0) {
        await batch.commit();
    }
    res.json({ repaired: count });
});
//# sourceMappingURL=index.js.map