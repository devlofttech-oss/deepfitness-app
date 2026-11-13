// Deep Fitness — Cloud Functions.
//
// Kept to the work a client cannot be trusted to do: privileged writes, push
// dispatch and scheduled jobs. Everything else stays client-direct against
// Firestore, with the security rules as the access control.

export { onMemberCreate, setUserRole, createMember } from "./members";
export { sendAnnouncement } from "./announcements";
export { onBookingCancelled } from "./bookings";
export { dailyReminders, inactivityNudge } from "./scheduled";

// Temporary: grants the first admin so the dashboard can be reached at
// all. Remove once that admin exists -- it refuses after the first use,
// but an endpoint with this name should not linger.
export { bootstrapAdmin } from "./bootstrap";
