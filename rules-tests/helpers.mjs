import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from "@firebase/rules-unit-testing";
import { serverTimestamp } from "firebase/firestore";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(here, "..");

export { assertFails, assertSucceeds, serverTimestamp };

/**
 * One emulator environment shared by every test file.
 *
 * `demo-` project ids never reach a real Firebase project, so these tests run
 * offline and cannot touch production by accident.
 */
export async function testEnv() {
  return initializeTestEnvironment({
    projectId: "demo-deepfitness",
    firestore: {
      rules: readFileSync(join(repoRoot, "firestore.rules"), "utf8"),
      host: "127.0.0.1",
      port: 8080,
    },
  });
}

/** A signed-in client carrying the role claim the rules read. */
export function as(env, uid, role) {
  return env.authenticatedContext(uid, { role }).firestore();
}

export function asMember(env, uid = "member1") {
  return as(env, uid, "member");
}

export function asTrainer(env, uid = "trainer1") {
  return as(env, uid, "trainer");
}

export function asAdmin(env, uid = "admin1") {
  return as(env, uid, "admin");
}

/** Signed in but with no role claim, as a brand-new account would be. */
export function asRoleless(env, uid = "fresh1") {
  return env.authenticatedContext(uid, {}).firestore();
}

export function asSignedOut(env) {
  return env.unauthenticatedContext().firestore();
}

/** The base fields the rules require on a create. */
export const created = {
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  createdBy: null,
  deletedAt: null,
};

/** The base fields the rules require on an update. */
export const updated = { updatedAt: serverTimestamp() };

export function member(overrides = {}) {
  return {
    name: "Alex",
    email: "alex@example.com",
    phone: null,
    role: "member",
    membershipStatus: "active",
    notificationsEnabled: true,
    preferredUnit: "kg",
    fcmTokens: [],
    ...created,
    ...overrides,
  };
}

export function assignedPlan(overrides = {}) {
  return {
    memberId: "member1",
    planId: "template1",
    title: "Push Day",
    focus: "Chest",
    level: "",
    durationMinutes: 45,
    estimatedCalories: 300,
    scheduledDate: "2026-11-06",
    exercises: [
      { order: 0, exerciseId: "bench", name: "Bench Press", sets: 3 },
      { order: 1, exerciseId: "fly", name: "Cable Fly", sets: 3 },
    ],
    currentIndex: 0,
    status: "active",
    assignedBy: "trainer1",
    assignedAt: serverTimestamp(),
    ...created,
    ...overrides,
  };
}

export function completionLog(overrides = {}) {
  return {
    memberId: "member1",
    assignedPlanId: "plan1",
    exerciseIndex: 0,
    exerciseId: "bench",
    exerciseName: "Bench Press",
    muscleGroup: "Chest",
    setsPlanned: 3,
    setsDone: 3,
    sets: [{ setNumber: 1, weight: 40, reps: 10 }],
    skipped: false,
    skipReason: null,
    tracksWeight: true,
    topWeight: 40,
    volume: 400,
    completedAt: serverTimestamp(),
    ...created,
    ...overrides,
  };
}

export function classSession(overrides = {}) {
  return {
    classId: "class1",
    classTitle: "Spin",
    instructor: "Sam",
    startsAt: new Date("2026-12-01T06:00:00Z"),
    capacity: 10,
    bookedCount: 0,
    waitlistCount: 0,
    ...created,
    ...overrides,
  };
}
