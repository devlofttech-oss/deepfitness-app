"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onBookingCancelled = void 0;
const firestore_1 = require("firebase-admin/firestore");
const firestore_2 = require("firebase-functions/v2/firestore");
const shared_1 = require("./shared");
/**
 * Promotes the first waitlisted member when a booking is cancelled.
 *
 * Runs in a transaction alongside the session counters, so a cancellation and
 * a fresh booking arriving at the same instant cannot both claim the freed
 * place.
 */
exports.onBookingCancelled = (0, firestore_2.onDocumentUpdated)(`${shared_1.Collections.bookings}/{bookingId}`, async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after)
        return;
    // Only a booked place frees a slot; a cancelled waitlist entry does not.
    const freedAPlace = before.status === "booked" && after.status === "cancelled";
    if (!freedAPlace)
        return;
    const sessionId = String(after.sessionId ?? "");
    if (!sessionId)
        return;
    const sessionRef = shared_1.db.collection(shared_1.Collections.classSessions).doc(sessionId);
    const promotedId = await shared_1.db.runTransaction(async (tx) => {
        const session = await tx.get(sessionRef);
        if (!session.exists)
            return null;
        const waitlist = await tx.get(shared_1.db
            .collection(shared_1.Collections.bookings)
            .where("sessionId", "==", sessionId)
            .where("status", "==", "waitlisted")
            .orderBy("position")
            .limit(1));
        const data = session.data() ?? {};
        const bookedCount = Number(data.bookedCount ?? 0);
        const waitlistCount = Number(data.waitlistCount ?? 0);
        if (waitlist.empty) {
            // Nobody waiting: the place simply goes back on sale.
            tx.update(sessionRef, {
                bookedCount: Math.max(0, bookedCount - 1),
                ...(0, shared_1.onUpdate)(),
            });
            return null;
        }
        const next = waitlist.docs[0];
        tx.update(next.ref, {
            status: "booked",
            position: 0,
            promotedAt: firestore_1.FieldValue.serverTimestamp(),
            ...(0, shared_1.onUpdate)(),
        });
        // The freed place is handed straight to the promoted member, so
        // bookedCount is unchanged.
        tx.update(sessionRef, {
            waitlistCount: Math.max(0, waitlistCount - 1),
            ...(0, shared_1.onUpdate)(),
        });
        return String(next.data().memberId ?? "");
    });
    if (!promotedId)
        return;
    const session = await sessionRef.get();
    const title = String(session.data()?.classTitle ?? "your class");
    await (0, shared_1.pushToMember)(promotedId, {
        title: "You're in!",
        body: `A place opened up in ${title}. You are booked.`,
    }, { deepLink: "/classes", sessionId });
});
//# sourceMappingURL=bookings.js.map