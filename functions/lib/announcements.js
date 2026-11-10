"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendAnnouncement = void 0;
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/v2/https");
const shared_1 = require("./shared");
const audiences = ["all", "members", "trainers"];
/**
 * Fans out an FCM message and mirrors it into `announcements`.
 *
 * The mirror is the point: a push is transient, so a member who swipes the
 * notification away would otherwise have no way back to it. The in-app list
 * reads the mirrored document.
 */
exports.sendAnnouncement = (0, https_1.onCall)(async (request) => {
    const senderId = (0, shared_1.requireRole)(request, "admin");
    const title = String(request.data?.title ?? "").trim();
    const body = String(request.data?.body ?? "").trim();
    const audience = String(request.data?.audience ?? "all");
    const deepLink = request.data?.deepLink
        ? String(request.data.deepLink)
        : null;
    if (!title || !body) {
        throw new https_1.HttpsError("invalid-argument", "Give it a title and a body.");
    }
    if (!audiences.includes(audience)) {
        throw new https_1.HttpsError("invalid-argument", "That is not a known audience.");
    }
    const senderDoc = await shared_1.db
        .collection(shared_1.Collections.members)
        .doc(senderId)
        .get();
    // Mirror first: if the send fails the announcement is still on record, which
    // is easier to reconcile than a push nobody can trace.
    const ref = await shared_1.db.collection(shared_1.Collections.announcements).add({
        title,
        body,
        audience,
        deepLink,
        sentBy: String(senderDoc.data()?.name ?? senderId),
        sentAt: firestore_1.FieldValue.serverTimestamp(),
        ...(0, shared_1.onCreate)(senderId),
    });
    await shared_1.messaging.send({
        topic: audience,
        notification: { title, body },
        data: {
            announcementId: ref.id,
            ...(deepLink ? { deepLink } : {}),
        },
    });
    return { announcementId: ref.id };
});
//# sourceMappingURL=announcements.js.map