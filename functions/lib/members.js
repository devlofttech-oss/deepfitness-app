"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.createMember = exports.setUserRole = exports.onMemberCreate = void 0;
const firestore_1 = require("firebase-admin/firestore");
const functionsV1 = __importStar(require("firebase-functions/v1"));
const https_1 = require("firebase-functions/v2/https");
const shared_1 = require("./shared");
/**
 * Creates the member document and sets the default role claim.
 *
 * The role is a custom claim and never a field the client can write, so this
 * is the only place a brand-new account gets one.
 */
exports.onMemberCreate = functionsV1.auth.user().onCreate(async (user) => {
    const ref = shared_1.db.collection(shared_1.Collections.members).doc(user.uid);
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
            joinedAt: firestore_1.FieldValue.serverTimestamp(),
            notificationsEnabled: true,
            preferredUnit: "kg",
            fcmTokens: [],
            ...(0, shared_1.onCreate)(user.uid),
        });
    }
    const claims = (user.customClaims ?? {});
    if (!claims.role) {
        await shared_1.auth.setCustomUserClaims(user.uid, { role: "member" });
    }
});
/**
 * Sets a custom claim. The only way a role ever changes.
 */
exports.setUserRole = (0, https_1.onCall)(async (request) => {
    (0, shared_1.requireRole)(request, "admin");
    const uid = String(request.data?.uid ?? "");
    const role = String(request.data?.role ?? "");
    if (!uid) {
        throw new https_1.HttpsError("invalid-argument", "Pass the user's uid.");
    }
    if (!["member", "trainer", "admin"].includes(role)) {
        throw new https_1.HttpsError("invalid-argument", "That is not a known role.");
    }
    await shared_1.auth.setCustomUserClaims(uid, { role });
    // Mirrored onto the document for the UI only; the claim stays the authority.
    await shared_1.db
        .collection(shared_1.Collections.members)
        .doc(uid)
        .set({ role, ...(0, shared_1.onUpdate)() }, { merge: true });
    // Forces the next client token refresh to pick up the new claim.
    await shared_1.auth.revokeRefreshTokens(uid);
    return { uid, role };
});
/**
 * Creates a member account on a trainer's behalf and returns the invite text.
 *
 * Privileged: the client has no business creating another user's auth record,
 * so this never runs on the device.
 */
exports.createMember = (0, https_1.onCall)(async (request) => {
    const trainerId = (0, shared_1.requireRole)(request, "trainer", "admin");
    const name = String(request.data?.name ?? "").trim();
    const email = request.data?.email
        ? String(request.data.email).trim()
        : undefined;
    const phone = request.data?.phone
        ? String(request.data.phone).trim()
        : undefined;
    const password = String(request.data?.password ?? "");
    if (!name) {
        throw new https_1.HttpsError("invalid-argument", "A name is required.");
    }
    if (!email && !phone) {
        throw new https_1.HttpsError("invalid-argument", "Give the member an email address or a phone number.");
    }
    if (password.length < 6) {
        throw new https_1.HttpsError("invalid-argument", "Choose a password of at least six characters.");
    }
    let user;
    try {
        user = await shared_1.auth.createUser({
            displayName: name,
            email,
            phoneNumber: phone,
            password,
        });
    }
    catch (error) {
        const code = error.code;
        if (code === "auth/email-already-exists" ||
            code === "auth/phone-number-already-exists") {
            throw new https_1.HttpsError("already-exists", "An account already uses those details.");
        }
        throw new https_1.HttpsError("internal", "Could not create that member.");
    }
    await shared_1.auth.setCustomUserClaims(user.uid, { role: "member" });
    const trainerDoc = await shared_1.db
        .collection(shared_1.Collections.members)
        .doc(trainerId)
        .get();
    const trainerName = String(trainerDoc.data()?.name ?? "your trainer");
    const weight = Number(request.data?.weight ?? 0);
    const member = {
        name,
        email: email ?? "",
        phone: phone ?? null,
        role: "member",
        membershipStatus: "active",
        joinedAt: firestore_1.FieldValue.serverTimestamp(),
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
        ...(0, shared_1.onCreate)(trainerId),
    };
    await shared_1.db.collection(shared_1.Collections.members).doc(user.uid).set(member);
    if (weight > 0) {
        await shared_1.db.collection("measurements").add({
            memberId: user.uid,
            weight,
            notes: "Joining weight",
            measuredAt: firestore_1.FieldValue.serverTimestamp(),
            ...(0, shared_1.onCreate)(trainerId),
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
//# sourceMappingURL=members.js.map