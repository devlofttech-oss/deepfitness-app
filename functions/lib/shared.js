"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Collections = exports.messaging = exports.auth = exports.db = void 0;
exports.onCreate = onCreate;
exports.onUpdate = onUpdate;
exports.requireSignedIn = requireSignedIn;
exports.requireRole = requireRole;
exports.dayKey = dayKey;
exports.daysFromNow = daysFromNow;
exports.pushToTokens = pushToTokens;
exports.pushToMember = pushToMember;
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const auth_1 = require("firebase-admin/auth");
const messaging_1 = require("firebase-admin/messaging");
const https_1 = require("firebase-functions/v2/https");
(0, app_1.initializeApp)();
exports.db = (0, firestore_1.getFirestore)();
exports.auth = (0, auth_1.getAuth)();
exports.messaging = (0, messaging_1.getMessaging)();
exports.Collections = {
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
};
/** The base fields every document carries. */
function onCreate(by) {
    return {
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        createdBy: by ?? null,
        deletedAt: null,
    };
}
function onUpdate() {
    return { updatedAt: firestore_1.FieldValue.serverTimestamp() };
}
function requireSignedIn(request) {
    const uid = request.auth?.uid;
    if (!uid) {
        throw new https_1.HttpsError("unauthenticated", "Sign in first.");
    }
    return uid;
}
function requireRole(request, ...allowed) {
    const uid = requireSignedIn(request);
    const role = request.auth?.token.role;
    if (!role || !allowed.includes(role)) {
        throw new https_1.HttpsError("permission-denied", "You do not have access to that.");
    }
    return uid;
}
/** `yyyy-MM-dd`, the key every day-scoped document uses. */
function dayKey(date) {
    const month = `${date.getUTCMonth() + 1}`.padStart(2, "0");
    const day = `${date.getUTCDate()}`.padStart(2, "0");
    return `${date.getUTCFullYear()}-${month}-${day}`;
}
function daysFromNow(days) {
    return firestore_1.Timestamp.fromDate(new Date(Date.now() + days * 86_400_000));
}
/**
 * Sends one notification to a set of device tokens and prunes the ones the
 * service rejects.
 *
 * A token goes stale whenever an app is reinstalled, so without the pruning a
 * member's token array grows without limit and every send wastes quota on
 * addresses that will never deliver.
 */
async function pushToTokens(memberId, tokens, notification, data = {}) {
    const unique = [...new Set(tokens.filter((token) => token.length > 0))];
    if (unique.length === 0)
        return 0;
    const response = await exports.messaging.sendEachForMulticast({
        tokens: unique,
        notification,
        data,
    });
    const stale = [];
    response.responses.forEach((result, index) => {
        const code = result.error?.code;
        if (code === "messaging/registration-token-not-registered" ||
            code === "messaging/invalid-registration-token" ||
            code === "messaging/invalid-argument") {
            stale.push(unique[index]);
        }
    });
    if (stale.length > 0) {
        await exports.db
            .collection(exports.Collections.members)
            .doc(memberId)
            .update({
            fcmTokens: firestore_1.FieldValue.arrayRemove(...stale),
            ...onUpdate(),
        });
    }
    return response.successCount;
}
/** Sends to one member, honouring their notification preference. */
async function pushToMember(memberId, notification, data = {}) {
    const doc = await exports.db.collection(exports.Collections.members).doc(memberId).get();
    const member = doc.data();
    if (!member)
        return 0;
    if (member.notificationsEnabled === false)
        return 0;
    const tokens = Array.isArray(member.fcmTokens)
        ? member.fcmTokens
        : [];
    return pushToTokens(memberId, tokens, notification, data);
}
//# sourceMappingURL=shared.js.map