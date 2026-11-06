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
  asTrainer,
  assertFails,
  assertSucceeds,
  assignedPlan,
  completionLog,
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
    await setDoc(doc(db, "assigned_plans/plan1"), assignedPlan());
    await setDoc(
      doc(db, "assigned_plans/plan2"),
      assignedPlan({ memberId: "member2" })
    );
    await setDoc(doc(db, "completion_logs/log1"), completionLog());
  });
});

describe("assigned plans", () => {
  test("a member reads their own plan", async () => {
    await assertSucceeds(getDoc(doc(asMember(env), "assigned_plans/plan1")));
  });

  test("a member cannot read another member's plan", async () => {
    await assertFails(getDoc(doc(asMember(env), "assigned_plans/plan2")));
  });

  test("a member advances their own unlock", async () => {
    await assertSucceeds(
      updateDoc(doc(asMember(env), "assigned_plans/plan1"), {
        currentIndex: 1,
        ...updated,
      })
    );
  });

  test("a member cannot move the unlock backwards", async () => {
    // Rewinding would let a member re-log a finished exercise and inflate
    // every report built on the completion log.
    await env.withSecurityRulesDisabled(async (context) => {
      await updateDoc(doc(context.firestore(), "assigned_plans/plan1"), {
        currentIndex: 2,
      });
    });

    await assertFails(
      updateDoc(doc(asMember(env), "assigned_plans/plan1"), {
        currentIndex: 0,
        ...updated,
      })
    );
  });

  test("a member cannot skip past the end of the plan", async () => {
    await assertFails(
      updateDoc(doc(asMember(env), "assigned_plans/plan1"), {
        currentIndex: 99,
        ...updated,
      })
    );
  });

  test("a member cannot rewrite the assigned exercises", async () => {
    // The snapshot is the record of what was assigned. If a member could edit
    // it, their own history would stop meaning anything.
    await assertFails(
      updateDoc(doc(asMember(env), "assigned_plans/plan1"), {
        exercises: [{ order: 0, exerciseId: "easy", name: "Nothing", sets: 1 }],
        ...updated,
      })
    );
  });

  test("a member cannot reassign a plan to themselves", async () => {
    await assertFails(
      updateDoc(doc(asMember(env), "assigned_plans/plan2"), {
        memberId: "member1",
        ...updated,
      })
    );
  });

  test("a member cannot assign themselves a new plan", async () => {
    await assertFails(
      setDoc(doc(asMember(env), "assigned_plans/plan3"), assignedPlan())
    );
  });

  test("a trainer assigns and deletes plans", async () => {
    await assertSucceeds(
      setDoc(doc(asTrainer(env), "assigned_plans/plan3"), assignedPlan())
    );
    await assertSucceeds(
      deleteDoc(doc(asTrainer(env), "assigned_plans/plan3"))
    );
  });

  test("a member writes their own in-progress sets", async () => {
    await assertSucceeds(
      setDoc(doc(asMember(env), "assigned_plans/plan1/progress/0"), {
        memberId: "member1",
        exerciseId: "bench",
        sets: [{ setNumber: 1, weight: 40, reps: 10, completed: true }],
        ...updated,
      })
    );
  });

  test("a member cannot write progress on another member's plan", async () => {
    await assertFails(
      setDoc(doc(asMember(env), "assigned_plans/plan2/progress/0"), {
        memberId: "member1",
        sets: [],
        ...updated,
      })
    );
  });
});

describe("completion logs", () => {
  test("a member reads their own log", async () => {
    await assertSucceeds(getDoc(doc(asMember(env), "completion_logs/log1")));
  });

  test("a trainer reads a member's log", async () => {
    await assertSucceeds(getDoc(doc(asTrainer(env), "completion_logs/log1")));
  });

  test("a member writes their own completion", async () => {
    await assertSucceeds(
      setDoc(doc(asMember(env), "completion_logs/log2"), completionLog())
    );
  });

  test("a member cannot write a log for someone else", async () => {
    await assertFails(
      setDoc(
        doc(asMember(env), "completion_logs/log3"),
        completionLog({ memberId: "member2" })
      )
    );
  });

  test("a skip must carry a reason", async () => {
    await assertFails(
      setDoc(
        doc(asMember(env), "completion_logs/log4"),
        completionLog({ skipped: true, skipReason: null, setsDone: 0 })
      )
    );

    await assertSucceeds(
      setDoc(
        doc(asMember(env), "completion_logs/log5"),
        completionLog({
          skipped: true,
          skipReason: "Equipment in use",
          setsDone: 0,
        })
      )
    );
  });

  test("completedAt must be the server's clock", async () => {
    await assertFails(
      setDoc(
        doc(asMember(env), "completion_logs/log6"),
        completionLog({ completedAt: new Date("2020-01-01") })
      )
    );
  });

  test("a log cannot be edited after the fact", async () => {
    // Append-only is what makes the log trustworthy as the single source for
    // every report.
    await assertFails(
      updateDoc(doc(asMember(env), "completion_logs/log1"), {
        setsDone: 99,
        ...updated,
      })
    );
  });

  test("a log cannot be hard-deleted", async () => {
    await assertFails(deleteDoc(doc(asMember(env), "completion_logs/log1")));
    await assertFails(deleteDoc(doc(asTrainer(env), "completion_logs/log1")));
  });

  test("a log may be soft-deleted, for a plan reset", async () => {
    await assertSucceeds(
      updateDoc(doc(asMember(env), "completion_logs/log1"), {
        deletedAt: new Date(),
        ...updated,
      })
    );
  });
});

describe("workout plan templates", () => {
  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), "workout_plans/template1"), {
        title: "Push Day",
        exercises: [],
        ...created,
      });
    });
  });

  test("templates are staff-only", async () => {
    // A member sees the plan assigned to them, never the library of templates.
    await assertFails(getDoc(doc(asMember(env), "workout_plans/template1")));
    await assertSucceeds(
      getDoc(doc(asTrainer(env), "workout_plans/template1"))
    );
  });
});
