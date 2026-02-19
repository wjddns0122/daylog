"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.repairWorker = exports.processPost = exports.createPostIntent = exports.suggestMoodKeywords = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const functions_1 = require("firebase-admin/functions");
const firestore_1 = require("firebase-admin/firestore");
const tasks_1 = require("firebase-functions/v2/tasks");
const ai_1 = require("./ai");
admin.initializeApp();
const db = admin.firestore();
const PROCESS_DELAY_SECONDS = 1 * 60; // TODO: revert to 6 * 60 * 60 after testing
const PROCESSING_LEASE_MS = 10 * 60 * 1000;
const isEmulator = process.env.FUNCTIONS_EMULATOR === "true";
const enqueueProcessPost = async (postId, scheduleDelaySeconds) => {
    if (isEmulator) {
        // In emulator, Cloud Tasks is not available. Use setTimeout instead.
        console.info(`[Emulator] Scheduling processPostDirect for ${postId} in ${scheduleDelaySeconds}s`);
        setTimeout(() => {
            processPostDirect(postId).catch((err) => console.error("[Emulator] processPostDirect failed:", err));
        }, scheduleDelaySeconds * 1000);
        return;
    }
    await (0, functions_1.getFunctions)()
        .taskQueue("processPost")
        .enqueue({ postId }, { scheduleDelaySeconds });
};
const sendReleaseNotification = async (userId, postId) => {
    await db.collection("notifications").add({
        userId,
        postId,
        type: "filmDeveloped",
        isRead: false,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        payload: {
            relatedPostId: postId,
        },
    });
};
/**
 * Suggest mood keywords from an uploaded image.
 * Called from Compose Screen before post creation.
 */
exports.suggestMoodKeywords = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
    }
    const { imageUrl } = data;
    if (!imageUrl) {
        throw new functions.https.HttpsError("invalid-argument", "Missing required field: imageUrl");
    }
    try {
        const keywords = await (0, ai_1.suggestKeywordsFromImage)(imageUrl);
        return { success: true, keywords };
    }
    catch (error) {
        console.error("suggestMoodKeywords failed:", error);
        return {
            success: true,
            keywords: ["감성적", "따뜻한", "잔잔한", "추억", "평화로운"],
        };
    }
});
exports.createPostIntent = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be logged in.");
    }
    const uid = context.auth.uid;
    const { imagePath, caption, requestId, visibility, moodKeywords } = data;
    const normalizedVisibility = typeof visibility === "string" ? visibility.toUpperCase() : "PRIVATE";
    if (!imagePath || !requestId) {
        throw new functions.https.HttpsError("invalid-argument", "Missing required fields (imagePath, requestId).");
    }
    const safeCaption = caption !== null && caption !== void 0 ? caption : "";
    const safeMoodKeywords = Array.isArray(moodKeywords) ? moodKeywords : [];
    if (!["PRIVATE", "PUBLIC"].includes(normalizedVisibility)) {
        throw new functions.https.HttpsError("invalid-argument", "Invalid visibility value.");
    }
    const today = new Date().toISOString().split("T")[0];
    const dailyKey = `${uid}_${today}`;
    const releaseTime = firestore_1.Timestamp.fromDate(new Date(Date.now() + PROCESS_DELAY_SECONDS * 1000));
    const postRef = db.collection("posts").doc();
    let targetPostId = postRef.id;
    let targetReleaseTime = releaseTime;
    let shouldEnqueue = false;
    try {
        await db.runTransaction(async (t) => {
            const lockRef = db.collection("daily_locks").doc(dailyKey);
            const lockDoc = await t.get(lockRef);
            if (lockDoc.exists) {
                throw new functions.https.HttpsError("already-exists", "ALREADY_POSTED");
            }
            const existingByRequest = await t.get(db.collection("posts").where("requestId", "==", requestId).limit(1));
            if (!existingByRequest.empty) {
                const existingDoc = existingByRequest.docs[0];
                targetPostId = existingDoc.id;
                const existingData = existingDoc.data();
                if (existingData.releaseTime instanceof firestore_1.Timestamp) {
                    targetReleaseTime = existingData.releaseTime;
                }
                return;
            }
            t.set(lockRef, {
                createdAt: firestore_1.FieldValue.serverTimestamp(),
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
                createdAt: firestore_1.FieldValue.serverTimestamp(),
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
            }
            catch (error) {
                console.error("Failed to enqueue processPost:", error);
                throw new functions.https.HttpsError("internal", "Post was created, but scheduling failed.");
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
    }
    catch (error) {
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        console.error("createPostIntent failed:", error);
        throw new functions.https.HttpsError("internal", "Transaction failed");
    }
});
const processPostDirect = async (postId) => {
    if (typeof postId !== "string" || postId.trim().length === 0) {
        console.error("processPostDirect: invalid postId", postId);
        return;
    }
    const postRef = db.collection("posts").doc(postId);
    let imageUrl = "";
    let authorId = "";
    let caption = "";
    let moodKeywords = [];
    let acquiredLease = false;
    try {
        await db.runTransaction(async (t) => {
            const snapshot = await t.get(postRef);
            if (!snapshot.exists) {
                return;
            }
            const post = snapshot.data();
            if (post.status === "RELEASED") {
                return;
            }
            if (post.status !== "PENDING") {
                return;
            }
            if (post.releaseTime instanceof firestore_1.Timestamp &&
                firestore_1.Timestamp.now() < post.releaseTime) {
                return;
            }
            if (typeof post.imageUrl !== "string" ||
                typeof post.authorId !== "string") {
                throw new Error("Invalid post payload for processing");
            }
            imageUrl = post.imageUrl;
            authorId = post.authorId;
            caption = post.caption || "";
            moodKeywords = Array.isArray(post.moodKeywords) ? post.moodKeywords : [];
            acquiredLease = true;
            t.update(postRef, {
                status: "PROCESSING",
                version: firestore_1.FieldValue.increment(1),
                leaseOwner: `task_${Date.now()}`,
                leaseExpiresAt: firestore_1.Timestamp.fromMillis(Date.now() + PROCESSING_LEASE_MS),
                processingStartedAt: firestore_1.FieldValue.serverTimestamp(),
            });
        });
        if (!acquiredLease) {
            return;
        }
        const aiResult = await (0, ai_1.generateCurationAndMusic)(imageUrl, moodKeywords, caption);
        await db.runTransaction(async (t) => {
            const snapshot = await t.get(postRef);
            if (!snapshot.exists) {
                return;
            }
            const post = snapshot.data();
            if (post.status !== "PROCESSING") {
                return;
            }
            t.update(postRef, {
                status: "RELEASED",
                version: firestore_1.FieldValue.increment(1),
                ai: {
                    curation: aiResult.curation,
                    youtubeUrl: aiResult.youtubeUrl,
                    youtubeTitle: aiResult.youtubeTitle,
                    songTitle: aiResult.songTitle,
                    musicReason: aiResult.musicReason,
                },
                processedAt: firestore_1.FieldValue.serverTimestamp(),
                leaseOwner: firestore_1.FieldValue.delete(),
                leaseExpiresAt: firestore_1.FieldValue.delete(),
            });
        });
        await sendReleaseNotification(authorId, postId);
    }
    catch (error) {
        console.error("processPostDirect failed:", { postId, error });
        if (acquiredLease) {
            await postRef.update({
                status: "PENDING",
                leaseOwner: firestore_1.FieldValue.delete(),
                leaseExpiresAt: firestore_1.FieldValue.delete(),
                lastError: String(error),
                processAttempts: firestore_1.FieldValue.increment(1),
            });
        }
        throw error;
    }
};
exports.processPost = (0, tasks_1.onTaskDispatched)({
    memory: "512MiB",
    timeoutSeconds: 120,
}, async (request) => {
    const payload = request.data;
    const postId = payload === null || payload === void 0 ? void 0 : payload.postId;
    if (typeof postId !== "string" || postId.trim().length === 0) {
        console.error("processPost: invalid payload", payload);
        return;
    }
    await processPostDirect(postId);
});
exports.repairWorker = functions.https.onRequest(async (_req, res) => {
    const now = firestore_1.Timestamp.now();
    const snapshot = await db
        .collection("posts")
        .where("status", "==", "PROCESSING")
        .where("leaseExpiresAt", "<", now)
        .get();
    const batch = db.batch();
    const requeueJobs = [];
    let count = 0;
    snapshot.forEach((doc) => {
        batch.update(doc.ref, {
            status: "PENDING",
            leaseOwner: firestore_1.FieldValue.delete(),
            leaseExpiresAt: firestore_1.FieldValue.delete(),
            processAttempts: firestore_1.FieldValue.increment(1),
        });
        requeueJobs.push(enqueueProcessPost(doc.id, 0));
        count++;
    });
    if (count > 0) {
        await batch.commit();
        const requeueResults = await Promise.allSettled(requeueJobs);
        const failedRequeues = requeueResults.filter((r) => r.status === "rejected").length;
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
//# sourceMappingURL=index.js.map