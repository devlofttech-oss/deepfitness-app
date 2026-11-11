import { FieldValue } from "firebase-admin/firestore";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";

import { Collections, db, onUpdate, pushToMember } from "./shared";

/**
 * Promotes the first waitlisted member when a booking is cancelled.
 *
 * Runs in a transaction alongside the session counters, so a cancellation and
 * a fresh booking arriving at the same instant cannot both claim the freed
 * place.
 */
export const onBookingCancelled = onDocumentUpdated(
  `${Collections.bookings}/{bookingId}`,
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    // Only a booked place frees a slot; a cancelled waitlist entry does not.
    const freedAPlace =
      before.status === "booked" && after.status === "cancelled";
    if (!freedAPlace) return;

    const sessionId = String(after.sessionId ?? "");
    if (!sessionId) return;

    const sessionRef = db.collection(Collections.classSessions).doc(sessionId);

    const promotedId = await db.runTransaction(async (tx) => {
      const session = await tx.get(sessionRef);
      if (!session.exists) return null;

      const waitlist = await tx.get(
        db
          .collection(Collections.bookings)
          .where("sessionId", "==", sessionId)
          .where("status", "==", "waitlisted")
          .orderBy("position")
          .limit(1)
      );

      const data = session.data() ?? {};
      const bookedCount = Number(data.bookedCount ?? 0);
      const waitlistCount = Number(data.waitlistCount ?? 0);

      if (waitlist.empty) {
        // Nobody waiting: the place simply goes back on sale.
        tx.update(sessionRef, {
          bookedCount: Math.max(0, bookedCount - 1),
          ...onUpdate(),
        });
        return null;
      }

      const next = waitlist.docs[0];
      tx.update(next.ref, {
        status: "booked",
        position: 0,
        promotedAt: FieldValue.serverTimestamp(),
        ...onUpdate(),
      });

      // The freed place is handed straight to the promoted member, so
      // bookedCount is unchanged.
      tx.update(sessionRef, {
        waitlistCount: Math.max(0, waitlistCount - 1),
        ...onUpdate(),
      });

      return String(next.data().memberId ?? "");
    });

    if (!promotedId) return;

    const session = await sessionRef.get();
    const title = String(session.data()?.classTitle ?? "your class");

    await pushToMember(
      promotedId,
      {
        title: "You're in!",
        body: `A place opened up in ${title}. You are booked.`,
      },
      { deepLink: "/classes", sessionId }
    );
  }
);
