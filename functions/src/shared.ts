import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import { getMessaging } from "firebase-admin/messaging";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";

initializeApp();

export const db = getFirestore();
export const auth = getAuth();
export const messaging = getMessaging();

export const Collections = {
  members: "members",
  exercises: "exercises",
  workoutPlans: "workout_plans",
  assignedPlans: "assigned_plans",
  completionLogs: "completion_logs",
  events: "events",
  eventRsvps: "event_rsvps",
  groupClasses: "group_classes",
  classSessions: "class_sessions",
  bookings: "bookings",
  announcements: "announcements",
} as const;

export type Role = "member" | "trainer" | "admin";

/** The base fields every document carries. */
export function onCreate(by?: string) {
  return {
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    createdBy: by ?? null,
    deletedAt: null,
  };
}

export function onUpdate() {
  return { updatedAt: FieldValue.serverTimestamp() };
}

export function requireSignedIn(request: CallableRequest): string {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }
  return uid;
}

export function requireRole(
  request: CallableRequest,
  ...allowed: Role[]
): string {
  const uid = requireSignedIn(request);
  const role = request.auth?.token.role as Role | undefined;
  if (!role || !allowed.includes(role)) {
    throw new HttpsError(
      "permission-denied",
      "You do not have access to that."
    );
  }
  return uid;
}

/** `yyyy-MM-dd`, the key every day-scoped document uses. */
export function dayKey(date: Date): string {
  const month = `${date.getUTCMonth() + 1}`.padStart(2, "0");
  const day = `${date.getUTCDate()}`.padStart(2, "0");
  return `${date.getUTCFullYear()}-${month}-${day}`;
}

export function daysFromNow(days: number): Timestamp {
  return Timestamp.fromDate(new Date(Date.now() + days * 86_400_000));
}

/**
 * Sends one notification to a set of device tokens and prunes the ones the
 * service rejects.
 *
 * A token goes stale whenever an app is reinstalled, so without the pruning a
 * member's token array grows without limit and every send wastes quota on
 * addresses that will never deliver.
 */
export async function pushToTokens(
  memberId: string,
  tokens: string[],
  notification: { title: string; body: string },
  data: Record<string, string> = {}
): Promise<number> {
  const unique = [...new Set(tokens.filter((token) => token.length > 0))];
  if (unique.length === 0) return 0;

  const response = await messaging.sendEachForMulticast({
    tokens: unique,
    notification,
    data,
  });

  const stale: string[] = [];
  response.responses.forEach((result, index) => {
    const code = result.error?.code;
    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token" ||
      code === "messaging/invalid-argument"
    ) {
      stale.push(unique[index]);
    }
  });

  if (stale.length > 0) {
    await db
      .collection(Collections.members)
      .doc(memberId)
      .update({
        fcmTokens: FieldValue.arrayRemove(...stale),
        ...onUpdate(),
      });
  }

  return response.successCount;
}

/** Sends to one member, honouring their notification preference. */
export async function pushToMember(
  memberId: string,
  notification: { title: string; body: string },
  data: Record<string, string> = {}
): Promise<number> {
  const doc = await db.collection(Collections.members).doc(memberId).get();
  const member = doc.data();
  if (!member) return 0;
  if (member.notificationsEnabled === false) return 0;

  const tokens: string[] = Array.isArray(member.fcmTokens)
    ? member.fcmTokens
    : [];
  return pushToTokens(memberId, tokens, notification, data);
}
