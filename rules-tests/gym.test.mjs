import { after, before, beforeEach, describe, test } from "node:test";

import {
  deleteDoc,
  doc,
  getDoc,
  setDoc,
  updateDoc,
} from "firebase/firestore";

import {
  asMember,
  asSignedOut,
  asTrainer,
  assertFails,
  assertSucceeds,
  classSession,
  created,
  testEnv,
  updated,
} from "./helpers.mjs";

let env;

before(async () => {
  env = await testEnv();
});

after(async () => {
  await env?.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "events/event1"), {
      title: "Open Day",
      description: "Come along.",
      startsAt: new Date("2026-12-20T10:00:00Z"),
      venue: "Main floor",
      ...created,
    });
    await setDoc(doc(db, "class_sessions/session1"), classSession());
    await setDoc(
      doc(db, "class_sessions/session2"),
      classSession({ capacity: 1, bookedCount: 1 })
    );
  });
});

describe("events", () => {
  test("any signed-in member reads events", async () => {
    await assertSucceeds(getDoc(doc(asMember(env), "events/event1")));
  });

  test("signed out reads nothing", async () => {
    await assertFails(getDoc(doc(asSignedOut(env), "events/event1")));
  });

  test("a member cannot create an event", async () => {
    await assertFails(
      setDoc(doc(asMember(env), "events/event2"), {
        title: "Fake",
        startsAt: new Date(),
        ...created,
      })
    );
  });

  test("a trainer creates an event", async () => {
    await assertSucceeds(
      setDoc(doc(asTrainer(env), "events/event2"), {
        title: "Charity run",
        startsAt: new Date("2027-01-10T08:00:00Z"),
        ...created,
      })
    );
  });
});

describe("event RSVPs", () => {
  test("a member RSVPs for themselves", async () => {
    await assertSucceeds(
      setDoc(doc(asMember(env), "event_rsvps/event1_member1"), {
        eventId: "event1",
        memberId: "member1",
        ...created,
      })
    );
  });

  test("a member cannot RSVP on someone else's behalf", async () => {
    await assertFails(
      setDoc(doc(asMember(env), "event_rsvps/event1_member2"), {
        eventId: "event1",
        memberId: "member2",
        ...created,
      })
    );
  });

  test("the document id must match the member and event", async () => {
    // The id is what makes one-RSVP-per-member structural rather than
    // something a query has to enforce.
    await assertFails(
      setDoc(doc(asMember(env), "event_rsvps/whatever"), {
        eventId: "event1",
        memberId: "member1",
        ...created,
      })
    );
  });

  test("a member cancels their own RSVP", async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      await setDoc(
        doc(context.firestore(), "event_rsvps/event1_member1"),
        { eventId: "event1", memberId: "member1", ...created }
      );
    });

    await assertSucceeds(
      deleteDoc(doc(asMember(env), "event_rsvps/event1_member1"))
    );
  });
});

describe("class sessions", () => {
  test("a member reads sessions", async () => {
    await assertSucceeds(getDoc(doc(asMember(env), "class_sessions/session1")));
  });

  test("a member cannot create a session", async () => {
    await assertFails(
      setDoc(doc(asMember(env), "class_sessions/session3"), classSession())
    );
  });

  test("a member may move only the counters", async () => {
    await assertSucceeds(
      updateDoc(doc(asMember(env), "class_sessions/session1"), {
        bookedCount: 1,
        ...updated,
      })
    );
  });

  test("a member cannot raise the capacity", async () => {
    // Otherwise the oversell guard is worthless: raise capacity, then book.
    await assertFails(
      updateDoc(doc(asMember(env), "class_sessions/session2"), {
        capacity: 99,
        ...updated,
      })
    );
  });

  test("a member cannot book past capacity", async () => {
    await assertFails(
      updateDoc(doc(asMember(env), "class_sessions/session2"), {
        bookedCount: 2,
        ...updated,
      })
    );
  });

  test("counters cannot go negative", async () => {
    await assertFails(
      updateDoc(doc(asMember(env), "class_sessions/session1"), {
        bookedCount: -1,
        ...updated,
      })
    );
  });

  test("a member cannot move the start time", async () => {
    await assertFails(
      updateDoc(doc(asMember(env), "class_sessions/session1"), {
        startsAt: new Date("2027-01-01T06:00:00Z"),
        ...updated,
      })
    );
  });
});

describe("bookings", () => {
  test("a member books a place for themselves", async () => {
    await assertSucceeds(
      setDoc(doc(asMember(env), "bookings/session1_member1"), {
        sessionId: "session1",
        memberId: "member1",
        status: "booked",
        position: 0,
        memberName: "Alex",
        ...created,
      })
    );
  });

  test("a member cannot book for someone else", async () => {
    await assertFails(
      setDoc(doc(asMember(env), "bookings/session1_member2"), {
        sessionId: "session1",
        memberId: "member2",
        status: "booked",
        position: 0,
        ...created,
      })
    );
  });

  test("a booking cannot be created already cancelled", async () => {
    await assertFails(
      setDoc(doc(asMember(env), "bookings/session1_member1"), {
        sessionId: "session1",
        memberId: "member1",
        status: "cancelled",
        position: 0,
        ...created,
      })
    );
  });

  describe("with an existing booking", () => {
    beforeEach(async () => {
      await env.withSecurityRulesDisabled(async (context) => {
        await setDoc(doc(context.firestore(), "bookings/session1_member1"), {
          sessionId: "session1",
          memberId: "member1",
          status: "waitlisted",
          position: 1,
          ...created,
        });
      });
    });

    test("a member cancels their own booking", async () => {
      await assertSucceeds(
        updateDoc(doc(asMember(env), "bookings/session1_member1"), {
          status: "cancelled",
          ...updated,
        })
      );
    });

    test("a member cannot promote themselves off the waitlist", async () => {
      // Promotion is onBookingCancelled's job, in a transaction with the
      // session counters. A self-promotion would oversell the class.
      await assertFails(
        updateDoc(doc(asMember(env), "bookings/session1_member1"), {
          status: "booked",
          position: 0,
          ...updated,
        })
      );
    });

    test("a member cannot jump the waitlist", async () => {
      await assertFails(
        updateDoc(doc(asMember(env), "bookings/session1_member1"), {
          position: 0,
          ...updated,
        })
      );
    });

    test("a booking cannot be hard-deleted", async () => {
      await assertFails(
        deleteDoc(doc(asMember(env), "bookings/session1_member1"))
      );
    });

    test("a member cannot read another member's booking", async () => {
      await env.withSecurityRulesDisabled(async (context) => {
        await setDoc(doc(context.firestore(), "bookings/session1_member2"), {
          sessionId: "session1",
          memberId: "member2",
          status: "booked",
          position: 0,
          ...created,
        });
      });

      await assertFails(
        getDoc(doc(asMember(env), "bookings/session1_member2"))
      );
      await assertSucceeds(
        getDoc(doc(asTrainer(env), "bookings/session1_member2"))
      );
    });
  });
});
