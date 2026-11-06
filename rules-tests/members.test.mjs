import { after, before, beforeEach, describe, test } from "node:test";

import { doc, getDoc, setDoc, updateDoc } from "firebase/firestore";

import {
  as,
  asAdmin,
  asMember,
  asSignedOut,
  asTrainer,
  assertFails,
  assertSucceeds,
  created,
  member,
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
    await setDoc(doc(db, "members/member1"), member());
    await setDoc(
      doc(db, "members/member2"),
      member({ name: "Sam", email: "sam@example.com" })
    );
  });
});

describe("members", () => {
  test("signed out reads nothing", async () => {
    await assertFails(getDoc(doc(asSignedOut(env), "members/member1")));
  });

  test("a member reads their own document", async () => {
    await assertSucceeds(getDoc(doc(asMember(env), "members/member1")));
  });

  test("a member cannot read another member's document", async () => {
    await assertFails(getDoc(doc(asMember(env), "members/member2")));
  });

  test("a trainer reads any member", async () => {
    await assertSucceeds(getDoc(doc(asTrainer(env), "members/member2")));
  });

  test("a member edits their own profile", async () => {
    await assertSucceeds(
      updateDoc(doc(asMember(env), "members/member1"), {
        name: "Alexandra",
        goal: "Build muscle",
        ...updated,
      })
    );
  });

  test("a member cannot promote themselves", async () => {
    // The whole access model rests on this one being denied.
    await assertFails(
      updateDoc(doc(asMember(env), "members/member1"), {
        role: "admin",
        ...updated,
      })
    );
  });

  test("a member cannot extend their own membership", async () => {
    await assertFails(
      updateDoc(doc(asMember(env), "members/member1"), {
        expiryDate: new Date("2099-01-01"),
        ...updated,
      })
    );
  });

  test("a member cannot un-lapse themselves", async () => {
    await assertFails(
      updateDoc(doc(asMember(env), "members/member1"), {
        membershipStatus: "active",
        ...updated,
      })
    );
  });

  test("a member cannot edit someone else's profile", async () => {
    await assertFails(
      updateDoc(doc(asMember(env), "members/member2"), {
        name: "Hacked",
        ...updated,
      })
    );
  });

  test("a write without a server timestamp is refused", async () => {
    // A device clock must never be able to order one member's history ahead
    // of another's.
    await assertFails(
      updateDoc(doc(asMember(env), "members/member1"), {
        name: "Alexandra",
        updatedAt: new Date("2020-01-01"),
      })
    );
  });

  test("a trainer may set membership state", async () => {
    await assertSucceeds(
      updateDoc(doc(asTrainer(env), "members/member1"), {
        membershipStatus: "lapsed",
        ...updated,
      })
    );
  });

  test("a trainer still cannot set a role", async () => {
    // Roles change through setUserRole alone, even for staff.
    await assertFails(
      updateDoc(doc(asTrainer(env), "members/member1"), {
        role: "admin",
        ...updated,
      })
    );
  });

  test("only an admin creates a member document", async () => {
    await assertFails(
      setDoc(doc(asTrainer(env), "members/member3"), member())
    );
    await assertSucceeds(
      setDoc(doc(asAdmin(env), "members/member3"), member())
    );
  });

  test("nobody deletes a member document", async () => {
    const { deleteDoc } = await import("firebase/firestore");
    await assertFails(deleteDoc(doc(asAdmin(env), "members/member1")));
  });

  test("an account with no role claim reads its own document", async () => {
    // A brand-new account sits here until onMemberCreate sets the claim.
    await env.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), "members/fresh1"), member());
    });
    const fresh = env.authenticatedContext("fresh1", {}).firestore();
    await assertSucceeds(getDoc(doc(fresh, "members/fresh1")));
  });

  test("a forged role claim is the only thing that matters, not the field", async () => {
    // The stored role field says "member"; the claim says trainer. The rules
    // read the claim, so this succeeds — which is why the field is never
    // writable by the member.
    await assertSucceeds(
      getDoc(doc(as(env, "someone", "trainer"), "members/member2"))
    );
  });
});

describe("exercise library", () => {
  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), "exercises/bench"), {
        name: "Bench Press",
        muscleGroup: "Chest",
        ...created,
      });
    });
  });

  test("any signed-in user reads the library", async () => {
    await assertSucceeds(getDoc(doc(asMember(env), "exercises/bench")));
  });

  test("signed out reads nothing", async () => {
    await assertFails(getDoc(doc(asSignedOut(env), "exercises/bench")));
  });

  test("a member cannot edit the library", async () => {
    await assertFails(
      updateDoc(doc(asMember(env), "exercises/bench"), {
        name: "Renamed",
        ...updated,
      })
    );
  });

  test("a trainer edits the library", async () => {
    await assertSucceeds(
      updateDoc(doc(asTrainer(env), "exercises/bench"), {
        name: "Barbell Bench Press",
        ...updated,
      })
    );
  });
});

describe("announcements", () => {
  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), "announcements/a1"), {
        title: "Closed Monday",
        body: "Public holiday.",
        audience: "all",
        ...created,
      });
    });
  });

  test("a member reads announcements", async () => {
    await assertSucceeds(getDoc(doc(asMember(env), "announcements/a1")));
  });

  test("not even an admin writes one from the client", async () => {
    // sendAnnouncement writes these with admin credentials, which bypass
    // rules. A client-side write would mean a push nobody sent.
    await assertFails(
      setDoc(doc(asAdmin(env), "announcements/a2"), {
        title: "Fake",
        body: "Fake",
        audience: "all",
        ...created,
      })
    );
  });
});

describe("deny by default", () => {
  test("an unmatched collection is closed", async () => {
    await assertFails(
      setDoc(doc(asAdmin(env), "something_else/doc1"), { a: 1 })
    );
    await assertFails(getDoc(doc(asAdmin(env), "something_else/doc1")));
  });
});
