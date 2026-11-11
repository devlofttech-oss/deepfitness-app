import { afterAll, beforeAll, beforeEach, describe, test } from 'vitest';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  deleteDoc,
  doc,
  getDoc,
  runTransaction,
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
    await setDoc(doc(db, 'class_sessions/session-1'), {
      classId: 'class-1',
      capacity: 2,
      bookedCount: 0,
      waitlistCount: 0,
      startsAt: new Date('2027-01-01'),
      deletedAt: null,
    });
  });
});

describe('class sessions', () => {
  test('a member reads the timetable', async () => {
    await assertSucceeds(
      getDoc(doc(asMember(env), 'class_sessions/session-1')),
    );
  });

  test('a member may move the counters, because booking does', async () => {
    await assertSucceeds(
      updateDoc(doc(asMember(env), 'class_sessions/session-1'), {
        bookedCount: 1,
        updatedAt: new Date(),
      }),
    );
  });

  test('a member cannot raise the capacity to let themselves in', async () => {
    await assertFails(
      updateDoc(doc(asMember(env), 'class_sessions/session-1'), {
        capacity: 99,
      }),
    );
  });

  test('a member cannot move the session', async () => {
    await assertFails(
      updateDoc(doc(asMember(env), 'class_sessions/session-1'), {
        startsAt: new Date('2027-06-01'),
      }),
    );
  });

  test('staff create and remove sessions', async () => {
    await assertSucceeds(
      setDoc(doc(asTrainer(env), 'class_sessions/session-2'), {
        classId: 'class-1',
        capacity: 10,
        bookedCount: 0,
        waitlistCount: 0,
        startsAt: new Date('2027-02-01'),
        deletedAt: null,
      }),
    );
    await assertSucceeds(
      deleteDoc(doc(asAdmin(env), 'class_sessions/session-1')),
    );
  });
});

describe('bookings', () => {
  test('a member books themselves in', async () => {
    await assertSucceeds(
      setDoc(doc(asMember(env), 'bookings/session-1_member-1'), {
        sessionId: 'session-1',
        memberId: 'member-1',
        status: 'booked',
        position: 0,
      }),
    );
  });

  test('a member cannot book somebody else in', async () => {
    await assertFails(
      setDoc(doc(asMember(env, 'member-2'), 'bookings/session-1_member-1'), {
        sessionId: 'session-1',
        memberId: 'member-1',
        status: 'booked',
        position: 0,
      }),
    );
  });

  test('a booking cannot be created already cancelled', async () => {
    await assertFails(
      setDoc(doc(asMember(env), 'bookings/session-1_member-1'), {
        sessionId: 'session-1',
        memberId: 'member-1',
        status: 'cancelled',
        position: 0,
      }),
    );
  });

  test('a member cancels their own booking', async () => {
    await seed(env, (db) =>
      setDoc(doc(db, 'bookings/session-1_member-1'), {
        sessionId: 'session-1',
        memberId: 'member-1',
        status: 'booked',
        position: 0,
      }),
    );

    await assertSucceeds(
      updateDoc(doc(asMember(env), 'bookings/session-1_member-1'), {
        status: 'cancelled',
        updatedAt: new Date(),
      }),
    );
  });

  test('a member cannot promote themselves off the waitlist', async () => {
    // Promotion is onBookingCancelled's job. If a member could do it,
    // the waitlist order would mean nothing.
    await seed(env, (db) =>
      setDoc(doc(db, 'bookings/session-1_member-1'), {
        sessionId: 'session-1',
        memberId: 'member-1',
        status: 'waitlisted',
        position: 3,
      }),
    );

    await assertFails(
      updateDoc(doc(asMember(env), 'bookings/session-1_member-1'), {
        status: 'booked',
        updatedAt: new Date(),
      }),
    );
  });

  test('a member cannot move up the queue', async () => {
    await seed(env, (db) =>
      setDoc(doc(db, 'bookings/session-1_member-1'), {
        sessionId: 'session-1',
        memberId: 'member-1',
        status: 'waitlisted',
        position: 5,
      }),
    );

    await assertFails(
      updateDoc(doc(asMember(env), 'bookings/session-1_member-1'), {
        position: 1,
        updatedAt: new Date(),
      }),
    );
  });

  test('a member cannot cancel somebody else to free a place', async () => {
    await seed(env, (db) =>
      setDoc(doc(db, 'bookings/session-1_member-9'), {
        sessionId: 'session-1',
        memberId: 'member-9',
        status: 'booked',
        position: 0,
      }),
    );

    await assertFails(
      updateDoc(doc(asMember(env), 'bookings/session-1_member-9'), {
        status: 'cancelled',
      }),
    );
  });

  test('a member reads only their own bookings', async () => {
    await seed(env, (db) =>
      setDoc(doc(db, 'bookings/session-1_member-9'), {
        sessionId: 'session-1',
        memberId: 'member-9',
        status: 'booked',
        position: 0,
      }),
    );

    await assertFails(
      getDoc(doc(asMember(env), 'bookings/session-1_member-9')),
    );
    await assertSucceeds(
      getDoc(doc(asTrainer(env), 'bookings/session-1_member-9')),
    );
  });

  test('the booking transaction the app runs is allowed end to end', async () => {
    // The pieces pass individually above; this is the shape the client
    // actually commits, booking and counter together.
    const db = asMember(env);
    await assertSucceeds(
      runTransaction(db, async (transaction) => {
        const sessionRef = doc(db, 'class_sessions/session-1');
        const snapshot = await transaction.get(sessionRef);
        transaction.set(doc(db, 'bookings/session-1_member-1'), {
          sessionId: 'session-1',
          memberId: 'member-1',
          status: 'booked',
          position: 0,
        });
        transaction.update(sessionRef, {
          bookedCount: snapshot.data().bookedCount + 1,
          waitlistCount: snapshot.data().waitlistCount,
          updatedAt: new Date(),
        });
      }),
    );
  });
});
