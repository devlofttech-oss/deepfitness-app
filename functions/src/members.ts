import { FieldValue } from "firebase-admin/firestore";
import * as functionsV1 from "firebase-functions/v1";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import {
  auth,
  Collections,
  db,
  onCreate,
  onUpdate,
  requireRole,
  type Role,
} from "./shared";

/**
 * Creates the member document and sets the default role claim.
 *
 * The role is a custom claim and never a field the client can write, so this
 * is the only place a brand-new account gets one.
 */
export const onMemberCreate = functionsV1.auth.user().onCreate(async (user) => {
  const ref = db.collection(Collections.members).doc(user.uid);
  const existing = await ref.get();

  // createMember writes the document itself before the trigger fires, so this
  // must not overwrite the details a trainer just typed.
  if (!existing.exists) {
    await ref.set({
      name: user.displayName ?? "",
      email: user.email ?? "",
      phone: user.phoneNumber ?? null,
      photoUrl: user.photoURL ?? null,
      role: "member",
      membershipStatus: "active",
      joinedAt: FieldValue.serverTimestamp(),
      notificationsEnabled: true,
      preferredUnit: "kg",
      fcmTokens: [],
      ...onCreate(user.uid),
    });
  }

  const claims = (user.customClaims ?? {}) as { role?: Role };
  if (!claims.role) {
    await auth.setCustomUserClaims(user.uid, { role: "member" });
  }
});

/**
 * Sets a custom claim. The only way a role ever changes.
 */
export const setUserRole = onCall(async (request) => {
  requireRole(request, "admin");

  const uid = String(request.data?.uid ?? "");
  const role = String(request.data?.role ?? "") as Role;

  if (!uid) {
    throw new HttpsError("invalid-argument", "Pass the user's uid.");
  }
  if (!["member", "trainer", "admin"].includes(role)) {
    throw new HttpsError("invalid-argument", "That is not a known role.");
  }

  await auth.setCustomUserClaims(uid, { role });

  // Mirrored onto the document for the UI only; the claim stays the authority.
  await db
    .collection(Collections.members)
    .doc(uid)
    .set({ role, ...onUpdate() }, { merge: true });

  // Forces the next client token refresh to pick up the new claim.
  await auth.revokeRefreshTokens(uid);

  return { uid, role };
});

/**
 * Creates a member account on a trainer's behalf and returns the invite text.
 *
 * Privileged: the client has no business creating another user's auth record,
 * so this never runs on the device.
 */
export const createMember = onCall(async (request) => {
  const trainerId = requireRole(request, "trainer", "admin");

  const name = String(request.data?.name ?? "").trim();
  const email = request.data?.email
    ? String(request.data.email).trim()
    : undefined;
  const phone = request.data?.phone
    ? String(request.data.phone).trim()
    : undefined;
  const password = String(request.data?.password ?? "");

  if (!name) {
    throw new HttpsError("invalid-argument", "A name is required.");
  }
  if (!email && !phone) {
    throw new HttpsError(
      "invalid-argument",
      "Give the member an email address or a phone number."
    );
  }
  if (password.length < 6) {
    throw new HttpsError(
      "invalid-argument",
      "Choose a password of at least six characters."
    );
  }

  let user;
  try {
    user = await auth.createUser({
      displayName: name,
      email,
      phoneNumber: phone,
      password,
    });
  } catch (error) {
    const code = (error as { code?: string }).code;
    if (
      code === "auth/email-already-exists" ||
      code === "auth/phone-number-already-exists"
    ) {
      throw new HttpsError(
        "already-exists",
        "An account already uses those details."
      );
    }
    throw new HttpsError("internal", "Could not create that member.");
  }

  await auth.setCustomUserClaims(user.uid, { role: "member" });

  const trainerDoc = await db
    .collection(Collections.members)
    .doc(trainerId)
    .get();
  const trainerName = String(trainerDoc.data()?.name ?? "your trainer");

  const weight = Number(request.data?.weight ?? 0);
  const member = {
    name,
    email: email ?? "",
    phone: phone ?? null,
    role: "member" as const,
    membershipStatus: "active" as const,
    joinedAt: FieldValue.serverTimestamp(),
    goal: String(request.data?.goal ?? "Fitness"),
    gender: request.data?.gender ? String(request.data.gender) : null,
    age: request.data?.age == null ? null : Number(request.data.age),
    heightCm: Number(request.data?.heightCm ?? 0),
    currentWeight: weight,
    trainerId,
    trainerName,
    notificationsEnabled: true,
    preferredUnit: "kg",
    fcmTokens: [],
    ...onCreate(trainerId),
  };

  await db.collection(Collections.members).doc(user.uid).set(member);

  if (weight > 0) {
    await db.collection("measurements").add({
      memberId: user.uid,
      weight,
      notes: "Joining weight",
      measuredAt: FieldValue.serverTimestamp(),
      ...onCreate(trainerId),
    });
  }

  const signInWith = email ?? phone;
  const inviteText = [
    `Hi ${name}, welcome to Deep Fitness!`,
    "",
    "Your account is ready. Download the app and sign in with:",
    `  ${signInWith}`,
    `  Password: ${password}`,
    "",
    "Change your password after your first sign-in.",
    `See you at the gym — ${trainerName}`,
  ].join("\n");

  return {
    member: {
      id: user.uid,
      name,
      email: email ?? "",
      phone: phone ?? null,
      goal: member.goal,
      heightCm: member.heightCm,
      weight,
      trainerName,
    },
    inviteText,
  };
});
