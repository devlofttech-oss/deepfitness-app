import { HttpsError, onCall } from "firebase-functions/v2/https";

import { Collections, auth, db, onUpdate, requireSignedIn } from "./shared";

/**
 * Grants the caller the admin role, once, when the gym has no admin yet.
 *
 * Roles are custom claims and claims are only set by setUserRole, which
 * itself requires an admin. A brand new project therefore has no way to
 * produce its first one: the dashboard, the exercise library and every
 * trainer action stay unreachable forever.
 *
 * This closes that loop without a service-account key on somebody's laptop.
 * It is safe by construction rather than by trust: it refuses the moment an
 * admin exists, so the first successful call is also the last. It cannot be
 * used to add a second admin, or to take the role back after a demotion.
 *
 * Delete this function once the first admin is in place. It is a bootstrap,
 * not a feature, and an endpoint named "make me an admin" should not outlive
 * the one minute it is needed.
 */
export const bootstrapAdmin = onCall(async (request) => {
  const uid = requireSignedIn(request);

  // An existing admin is the signal that bootstrapping is over. Checked
  // against the member documents setUserRole mirrors the claim onto, since
  // Auth offers no "list users by claim".
  const existing = await db
    .collection(Collections.members)
    .where("role", "==", "admin")
    .limit(1)
    .get();

  if (!existing.empty) {
    throw new HttpsError(
      "failed-precondition",
      "This gym already has an admin. Ask them to grant the role instead.",
    );
  }

  await auth.setCustomUserClaims(uid, { role: "admin" });

  await db
    .collection(Collections.members)
    .doc(uid)
    .set({ role: "admin", ...onUpdate() }, { merge: true });

  // The caller's current token still says member; force a refresh.
  await auth.revokeRefreshTokens(uid);

  return { uid, role: "admin" };
});
