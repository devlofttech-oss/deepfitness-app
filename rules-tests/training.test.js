import { afterAll, beforeAll, beforeEach, describe, expect, test } from 'vitest';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDoc,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import {
  asAdmin,
  asMember,
  asTrainer,
  createTestEnv,
  seed,
} from './helpers.js';

let env;

beforeAll(async () => {
  env = await createTestEnv();
});

afterAll(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await seed(env, async (db) => {
    await setDoc(doc(db, 'exercises/ex-1'), { name: 'Squat', deletedAt: null });
    await setDoc(doc(db, 'assigned_plans/plan-1'), {
      memberId: 'member-1',
      planId: 'template-1',
      title: 'Leg day',
      exercises: [{ exerciseId: 'ex-1', name: 'Squat', sets: 3, reps: 10 }],
      currentIndex: 0,
      status: 'active',
      deletedAt: null,
    });
  });
});

describe('exercise library', () => {
  test('any signed-in member reads it', async () => {
    await assertSucceeds(getDoc(doc(asMember(env), 'exercises/ex-1')));
  });

  test('a member cannot write it', async () => {
    await assertFails(
      updateDoc(doc(asMember(env), 'exercises/ex-1'), { name: 'Mine now' }),
    );
  });

  test('staff write it', async () => {
    await assertSucceeds(
      updateDoc(doc(asTrainer(env), 'exercises/ex-1'), { name: 'Back squat' }),
    );
  });
});

describe('assigned plans', () => {
  test('a member reads their own plan', async () => {
    await assertSucceeds(getDoc(doc(asMember(env), 'assigned_plans/plan-1')));
  });

  test('a member cannot read another member plan', async () => {
    await assertFails(
      getDoc(doc(asMember(env, 'member-2'), 'assigned_plans/plan-1')),
    );
  });

  test('a member advances their own progress', async () => {
    await assertSucceeds(
      updateDoc(doc(asMember(env), 'assigned_plans/plan-1'), {
        currentIndex: 1,
        status: 'active',
        updatedAt: new Date(),
      }),
    );
  });

  test('a member cannot swap the exercise snapshot', async () => {
    // If this were allowed, a member could rewrite what they were asked
    // to do and every report built on it.
    await assertFails(
      updateDoc(doc(asMember(env), 'assigned_plans/plan-1'), {
        exercises: [],
        updatedAt: new Date(),
      }),
    );
  });

  test('a member cannot reassign the plan to themselves', async () => {
    await assertFails(
      updateDoc(doc(asMember(env, 'member-2'), 'assigned_plans/plan-1'), {
        memberId: 'member-2',
      }),
    );
  });

  test('a member cannot retitle the plan while advancing it', async () => {
    await assertFails(
      updateDoc(doc(asMember(env), 'assigned_plans/plan-1'), {
        currentIndex: 1,
        title: 'Something else',
        updatedAt: new Date(),
      }),
    );
  });

  test('a member cannot assign themselves a plan', async () => {
    await assertFails(
      addDoc(collection(asMember(env), 'assigned_plans'), {
        memberId: 'member-1',
        title: 'Self serve',
        exercises: [],
        currentIndex: 0,
        status: 'active',
      }),
    );
  });

  test('staff assign and remove plans', async () => {
    await assertSucceeds(
      addDoc(collection(asTrainer(env), 'assigned_plans'), {
        memberId: 'member-1',
        title: 'Push day',
        exercises: [],
        currentIndex: 0,
        status: 'active',
        deletedAt: null,
      }),
    );
    await assertSucceeds(
      deleteDoc(doc(asAdmin(env), 'assigned_plans/plan-1')),
    );
  });
});

describe('completion logs', () => {
  test('a member writes their own log', async () => {
    await assertSucceeds(
      addDoc(collection(asMember(env), 'completion_logs'), {
        memberId: 'member-1',
        assignedPlanId: 'plan-1',
        exerciseName: 'Squat',
        setsDone: 3,
        skipped: false,
        completedAt: new Date(),
      }),
    );
  });

  test('a member cannot write a log as somebody else', async () => {
    await assertFails(
      addDoc(collection(asMember(env, 'member-2'), 'completion_logs'), {
        memberId: 'member-1',
        assignedPlanId: 'plan-1',
        exerciseName: 'Squat',
        setsDone: 3,
        skipped: false,
      }),
    );
  });

  test('a log cannot be edited after the fact', async () => {
    // Append-only is what makes the reports trustworthy: a log that
    // could be rewritten would make every number negotiable.
    await seed(env, (db) =>
      setDoc(doc(db, 'completion_logs/log-1'), {
        memberId: 'member-1',
        assignedPlanId: 'plan-1',
        exerciseName: 'Squat',
        setsDone: 3,
        skipped: false,
      }),
    );

    await assertFails(
      updateDoc(doc(asMember(env), 'completion_logs/log-1'), { setsDone: 99 }),
    );
    await assertFails(
      deleteDoc(doc(asMember(env), 'completion_logs/log-1')),
    );
  });

  test('not even an admin can edit a log', async () => {
    await seed(env, (db) =>
      setDoc(doc(db, 'completion_logs/log-2'), {
        memberId: 'member-1',
        assignedPlanId: 'plan-1',
        exerciseName: 'Squat',
        setsDone: 3,
        skipped: false,
      }),
    );

    await assertFails(
      updateDoc(doc(asAdmin(env), 'completion_logs/log-2'), { setsDone: 0 }),
    );
  });

  test('a member reads their own logs and nobody else', async () => {
    await seed(env, (db) =>
      setDoc(doc(db, 'completion_logs/log-3'), {
        memberId: 'member-1',
        assignedPlanId: 'plan-1',
        exerciseName: 'Squat',
        setsDone: 3,
        skipped: false,
      }),
    );

    await assertSucceeds(
      getDoc(doc(asMember(env), 'completion_logs/log-3')),
    );
    await assertFails(
      getDoc(doc(asMember(env, 'member-2'), 'completion_logs/log-3')),
    );
    await assertSucceeds(
      getDoc(doc(asTrainer(env), 'completion_logs/log-3')),
    );
  });
});
