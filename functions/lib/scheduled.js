"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.inactivityNudge = exports.dailyReminders = void 0;
const firestore_1 = require("firebase-admin/firestore");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const firebase_functions_1 = require("firebase-functions");
const shared_1 = require("./shared");
const TIMEZONE = "Asia/Kolkata";
/**
 * Class reminders, event reminders and membership-expiry warnings.
 *
 * None of these writes a document that would re-trigger this function — the
 * usual cause of a surprise bill.
 */
exports.dailyReminders = (0, scheduler_1.onSchedule)({ schedule: "every day 07:00", timeZone: TIMEZONE }, async () => {
    const now = firestore_1.Timestamp.now();
    const tomorrow = (0, shared_1.daysFromNow)(1);
    await remindClassBookings(now, tomorrow);
    await remindEventRsvps(now, tomorrow);
    await warnExpiringMemberships();
});
/** Members booked into a session starting in the next 24 hours. */
async function remindClassBookings(now, tomorrow) {
    const sessions = await shared_1.db
        .collection(shared_1.Collections.classSessions)
        .where("startsAt", ">=", now)
        .where("startsAt", "<=", tomorrow)
        .get();
    for (const session of sessions.docs) {
        const bookings = await shared_1.db
            .collection(shared_1.Collections.bookings)
            .where("sessionId", "==", session.id)
            .where("status", "==", "booked")
            .get();
        const title = String(session.data().classTitle ?? "your class");
        for (const booking of bookings.docs) {
            await (0, shared_1.pushToMember)(String(booking.data().memberId ?? ""), { title: "Class tomorrow", body: `${title} is on tomorrow.` }, { deepLink: "/classes", sessionId: session.id });
        }
    }
    firebase_functions_1.logger.info(`Class reminders sent for ${sessions.size} sessions.`);
}
/** Members who RSVPed to an event starting in the next 24 hours. */
async function remindEventRsvps(now, tomorrow) {
    const events = await shared_1.db
        .collection(shared_1.Collections.events)
        .where("startsAt", ">=", now)
        .where("startsAt", "<=", tomorrow)
        .get();
    for (const event of events.docs) {
        const rsvps = await shared_1.db
            .collection(shared_1.Collections.eventRsvps)
            .where("eventId", "==", event.id)
            .get();
        const title = String(event.data().title ?? "a gym event");
        for (const rsvp of rsvps.docs) {
            await (0, shared_1.pushToMember)(String(rsvp.data().memberId ?? ""), { title: "Tomorrow at the gym", body: `${title} is on tomorrow.` }, { deepLink: "/events", eventId: event.id });
        }
    }
    firebase_functions_1.logger.info(`Event reminders sent for ${events.size} events.`);
}
/** Memberships expiring within a week, plus the ones that just lapsed. */
async function warnExpiringMemberships() {
    const expiring = await shared_1.db
        .collection(shared_1.Collections.members)
        .where("membershipStatus", "==", "active")
        .where("expiryDate", "<=", (0, shared_1.daysFromNow)(7))
        .get();
    const now = firestore_1.Timestamp.now();
    for (const doc of expiring.docs) {
        const expiry = doc.data().expiryDate;
        if (!expiry)
            continue;
        if (expiry.toMillis() <= now.toMillis()) {
            // A lapsed membership is a state, not a sign-out: the member keeps read
            // access to their own history.
            await doc.ref.update({ membershipStatus: "lapsed", ...(0, shared_1.onUpdate)() });
            await (0, shared_1.pushToMember)(doc.id, {
                title: "Your membership has lapsed",
                body: "Renew at the front desk to get back to training.",
            });
            continue;
        }
        const days = Math.ceil((expiry.toMillis() - now.toMillis()) / 86_400_000);
        await (0, shared_1.pushToMember)(doc.id, {
            title: "Membership expiring soon",
            body: `Your membership ends in ${days} day${days === 1 ? "" : "s"}.`,
        });
    }
    firebase_functions_1.logger.info(`Checked ${expiring.size} expiring memberships.`);
}
/** Nudges members with no completion log in the last 10 days. */
exports.inactivityNudge = (0, scheduler_1.onSchedule)({ schedule: "every monday 09:00", timeZone: TIMEZONE }, async () => {
    const cutoff = (0, shared_1.daysFromNow)(-10);
    const members = await shared_1.db
        .collection(shared_1.Collections.members)
        .where("role", "==", "member")
        .where("membershipStatus", "==", "active")
        .get();
    let nudged = 0;
    for (const member of members.docs) {
        const recent = await shared_1.db
            .collection(shared_1.Collections.completionLogs)
            .where("memberId", "==", member.id)
            .where("completedAt", ">=", cutoff)
            .limit(1)
            .get();
        if (!recent.empty)
            continue;
        await (0, shared_1.pushToMember)(member.id, {
            title: "We have missed you",
            body: "It has been a while. Your plan is waiting whenever you are.",
        });
        nudged += 1;
    }
    firebase_functions_1.logger.info(`Nudged ${nudged} inactive members.`);
});
//# sourceMappingURL=scheduled.js.map