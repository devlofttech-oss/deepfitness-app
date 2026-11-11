import { Timestamp } from "firebase-admin/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions";

import {
  Collections,
  db,
  daysFromNow,
  onUpdate,
  pushToMember,
} from "./shared";

const TIMEZONE = "Asia/Kolkata";

/**
 * Class reminders, event reminders and membership-expiry warnings.
 *
 * None of these writes a document that would re-trigger this function — the
 * usual cause of a surprise bill.
 */
export const dailyReminders = onSchedule(
  { schedule: "every day 07:00", timeZone: TIMEZONE },
  async () => {
    const now = Timestamp.now();
    const tomorrow = daysFromNow(1);

    await remindClassBookings(now, tomorrow);
    await remindEventRsvps(now, tomorrow);
    await warnExpiringMemberships();
  }
);

/** Members booked into a session starting in the next 24 hours. */
async function remindClassBookings(now: Timestamp, tomorrow: Timestamp) {
  const sessions = await db
    .collection(Collections.classSessions)
    .where("startsAt", ">=", now)
    .where("startsAt", "<=", tomorrow)
    .get();

  for (const session of sessions.docs) {
    const bookings = await db
      .collection(Collections.bookings)
      .where("sessionId", "==", session.id)
      .where("status", "==", "booked")
      .get();

    const title = String(session.data().classTitle ?? "your class");
    for (const booking of bookings.docs) {
      await pushToMember(
        String(booking.data().memberId ?? ""),
        { title: "Class tomorrow", body: `${title} is on tomorrow.` },
        { route: "/classes", type: "class_reminder", sessionId: session.id }
      );
    }
  }

  logger.info(`Class reminders sent for ${sessions.size} sessions.`);
}

/** Members who RSVPed to an event starting in the next 24 hours. */
async function remindEventRsvps(now: Timestamp, tomorrow: Timestamp) {
  const events = await db
    .collection(Collections.events)
    .where("startsAt", ">=", now)
    .where("startsAt", "<=", tomorrow)
    .get();

  for (const event of events.docs) {
    const rsvps = await db
      .collection(Collections.eventRsvps)
      .where("eventId", "==", event.id)
      .get();

    const title = String(event.data().title ?? "a gym event");
    for (const rsvp of rsvps.docs) {
      await pushToMember(
        String(rsvp.data().memberId ?? ""),
        { title: "Tomorrow at the gym", body: `${title} is on tomorrow.` },
        { route: "/events", type: "event_reminder", eventId: event.id }
      );
    }
  }

  logger.info(`Event reminders sent for ${events.size} events.`);
}

/** Memberships expiring within a week, plus the ones that just lapsed. */
async function warnExpiringMemberships() {
  const expiring = await db
    .collection(Collections.members)
    .where("membershipStatus", "==", "active")
    .where("expiryDate", "<=", daysFromNow(7))
    .get();

  const now = Timestamp.now();

  for (const doc of expiring.docs) {
    const expiry = doc.data().expiryDate as Timestamp | undefined;
    if (!expiry) continue;

    if (expiry.toMillis() <= now.toMillis()) {
      // A lapsed membership is a state, not a sign-out: the member keeps read
      // access to their own history.
      await doc.ref.update({ membershipStatus: "lapsed", ...onUpdate() });
      await pushToMember(doc.id, {
        title: "Your membership has lapsed",
        body: "Renew at the front desk to get back to training.",
      });
      continue;
    }

    const days = Math.ceil((expiry.toMillis() - now.toMillis()) / 86_400_000);
    await pushToMember(doc.id, {
      title: "Membership expiring soon",
      body: `Your membership ends in ${days} day${days === 1 ? "" : "s"}.`,
    });
  }

  logger.info(`Checked ${expiring.size} expiring memberships.`);
}

/** Nudges members with no completion log in the last 10 days. */
export const inactivityNudge = onSchedule(
  { schedule: "every monday 09:00", timeZone: TIMEZONE },
  async () => {
    const cutoff = daysFromNow(-10);

    const members = await db
      .collection(Collections.members)
      .where("role", "==", "member")
      .where("membershipStatus", "==", "active")
      .get();

    let nudged = 0;
    for (const member of members.docs) {
      const recent = await db
        .collection(Collections.completionLogs)
        .where("memberId", "==", member.id)
        .where("completedAt", ">=", cutoff)
        .limit(1)
        .get();

      if (!recent.empty) continue;

      await pushToMember(member.id, {
        title: "We have missed you",
        body: "It has been a while. Your plan is waiting whenever you are.",
      });
      nudged += 1;
    }

    logger.info(`Nudged ${nudged} inactive members.`);
  }
);
