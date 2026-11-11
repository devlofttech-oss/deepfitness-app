import { afterAll, beforeAll, beforeEach, describe, test } from 'vitest';
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  deleteDoc,
  doc,
  getDoc,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import {
  asAdmin,
  asAnon,
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
    await setDoc(doc(db, 'events/event-1'), {
      title: 'Open day',
      startsAt: new Date('2027-03-01'),
      deletedAt: null,
    });
    await setDoc(doc(db, 'announcements/note-1'), {
      title: 'Closed Monday',
      audience: 'all',
      sentAt: new Date(),
    });
  });
});

describe('events and RSVPs', () => {
  test('members read events, nobody signed out does', async () => {
    await assertSucceeds(getDoc(doc(asMember(env), 'events/event-1')));
    await assertFails(getDoc(doc(asAnon(env), 'events/event-1')));
  });

  test('a member cannot edit an event', async () => {
    await assertFails(
      updateDoc(doc(asMember(env), 'events/event-1'), { title: 'Cancelled' }),
    );
  });

  test('staff manage events', async () => {
    await assertSucceeds(
      updateDoc(doc(asTrainer(env), 'events/event-1'), { venue: 'Main hall' }),
    );
  });

  test('a member RSVPs for themselves and can withdraw', async () => {
    const db = asMember(env);
    await assertSucceeds(
      setDoc(doc(db, 'event_rsvps/event-1_member-1'), {
        eventId: 'event-1',
        memberId: 'member-1',
      }),
    );
    await assertSucceeds(
      deleteDoc(doc(db, 'event_rsvps/event-1_member-1')),
    );
  });

  test('a member cannot RSVP as somebody else', async () => {
    await assertFails(
      setDoc(
        doc(asMember(env, 'member-2'), 'event_rsvps/event-1_member-1'),
        { eventId: 'event-1', memberId: 'member-1' },
      ),
    );
  });

  test('an RSVP cannot be edited, only made or withdrawn', async () => {
    await seed(env, (db) =>
      setDoc(doc(db, 'event_rsvps/event-1_member-1'), {
        eventId: 'event-1',
        memberId: 'member-1',
      }),
    );

    await assertFails(
      updateDoc(doc(asMember(env), 'event_rsvps/event-1_member-1'), {
        eventId: 'event-2',
      }),
    );
  });
});

describe('announcements', () => {
  test('a member reads them', async () => {
    await assertSucceeds(getDoc(doc(asMember(env), 'announcements/note-1')));
  });

  test('nobody writes them from a client, not even an admin', async () => {
    // They are written by sendAnnouncement with the Admin SDK, which
    // bypasses these rules. A client write would be an announcement
    // with no push behind it.
    await assertFails(
      updateDoc(doc(asAdmin(env), 'announcements/note-1'), { title: 'Edit' }),
    );
    await assertFails(
      setDoc(doc(asAdmin(env), 'announcements/note-2'), { title: 'New' }),
    );
  });
});

describe('collections nobody declared', () => {
  test('an undeclared collection is denied even to an admin', async () => {
    // The catch-all at the bottom of the rules. A new collection has to
    // arrive with its own rules rather than inherit an open default.
    await assertFails(
      setDoc(doc(asAdmin(env), 'secret_notes/note-1'), { body: 'hello' }),
    );
    await assertFails(getDoc(doc(asMember(env), 'secret_notes/note-1')));
  });
});
