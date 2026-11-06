import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import {
  Collections,
  db,
  messaging,
  onCreate,
  requireRole,
} from "./shared";

const audiences = ["all", "members", "trainers"] as const;
type Audience = (typeof audiences)[number];

/**
 * Fans out an FCM message and mirrors it into `announcements`.
 *
 * The mirror is the point: a push is transient, so a member who swipes the
 * notification away would otherwise have no way back to it. The in-app list
 * reads the mirrored document.
 */
export const sendAnnouncement = onCall(async (request) => {
  const senderId = requireRole(request, "admin");

  const title = String(request.data?.title ?? "").trim();
  const body = String(request.data?.body ?? "").trim();
  const audience = String(request.data?.audience ?? "all") as Audience;
  const deepLink = request.data?.deepLink
    ? String(request.data.deepLink)
    : null;

  if (!title || !body) {
    throw new HttpsError("invalid-argument", "Give it a title and a body.");
  }
  if (!audiences.includes(audience)) {
    throw new HttpsError("invalid-argument", "That is not a known audience.");
  }

  const senderDoc = await db
    .collection(Collections.members)
    .doc(senderId)
    .get();

  // Mirror first: if the send fails the announcement is still on record, which
  // is easier to reconcile than a push nobody can trace.
  const ref = await db.collection(Collections.announcements).add({
    title,
    body,
    audience,
    deepLink,
    sentBy: String(senderDoc.data()?.name ?? senderId),
    sentAt: FieldValue.serverTimestamp(),
    ...onCreate(senderId),
  });

  await messaging.send({
    topic: audience,
    notification: { title, body },
    data: {
      announcementId: ref.id,
      ...(deepLink ? { deepLink } : {}),
    },
  });

  return { announcementId: ref.id };
});
