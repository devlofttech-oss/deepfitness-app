import { afterAll, beforeAll, beforeEach, describe, expect, test } from 'vitest';
import {
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';
import {
  asAdmin,
  asAnon,
  asClaimless,
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
  await seed(env, (db) =>
    setDoc(doc(db, 'members/member-1'), {
      name: 'Asha',
      membershipStatus: 'active',
      expiryDate: new Date('2027-01-01'),
      deletedAt: null,
    }),
  );
});

describe('members', () => {
  test('a member reads their own document', async () => {
    await assertSucceeds(getDoc(doc(asMember(env), 'members/member-1')));
  });

  test('a member cannot read somebody else', async () => {
    await assertFails(
      getDoc(doc(asMember(env, 'member-2'), 'members/member-1')),
    );
  });

  test('staff read any member', async () => {
    await assertSucceeds(getDoc(doc(asTrainer(env), 'members/member-1')));
    await assertSucceeds(getDoc(doc(asAdmin(env), 'members/member-1')));
  });

  test('nobody signed out reads anything', async () => {
    await assertFails(getDoc(doc(asAnon(env), 'members/member-1')));
  });

  test('a member edits their own name', async () => {
    await assertSucceeds(
      updateDoc(doc(asMember(env), 'members/member-1'), { name: 'Asha K' }),
    );
  });

  test('a member cannot extend their own membership', async () => {
    // The whole point of the protected-field rule.
    await assertFails(
      updateDoc(doc(asMember(env), 'members/member-1'), {
        expiryDate: new Date('2030-01-01'),
      }),
    );
  });

  test('a member cannot change their own membership status', async () => {
    await assertFails(
      updateDoc(doc(asMember(env), 'members/member-1'), {
        membershipStatus: 'active',
      }),
    );
  });

  test('a member cannot smuggle a protected field alongside a legal one', async () => {
    await assertFails(
      updateDoc(doc(asMember(env), 'members/member-1'), {
        name: 'Asha K',
        expiryDate: new Date('2030-01-01'),
      }),
    );
  });

  test('a member cannot rewrite their own audit trail', async () => {
    await assertFails(
      updateDoc(doc(asMember(env), 'members/member-1'), {
        createdBy: 'somebody-else',
      }),
    );
  });

  test('a member cannot soft delete themselves out of the roll', async () => {
    await assertFails(
      updateDoc(doc(asMember(env), 'members/member-1'), {
        deletedAt: new Date(),
      }),
    );
  });

  test('an admin sets membership', async () => {
    await assertSucceeds(
      updateDoc(doc(asAdmin(env), 'members/member-1'), {
        membershipStatus: 'lapsed',
        expiryDate: new Date('2020-01-01'),
      }),
    );
  });

  test('a trainer cannot set membership', async () => {
    // Trainers read the roll; they do not sell memberships.
    await assertFails(
      updateDoc(doc(asTrainer(env), 'members/member-1'), {
        membershipStatus: 'active',
      }),
    );
  });

  test('a first sign-in creates its own profile before the claim lands', async () => {
    // onMemberCreate sets the role claim, but the app may reach the
    // onboarding write first. If this failed, a new member would be
    // stuck on the onboarding screen.
    await assertSucceeds(
      setDoc(doc(asClaimless(env, 'new-1'), 'members/new-1'), {
        name: 'New person',
      }),
    );
  });

  test('a new sign-in cannot create somebody else', async () => {
    await assertFails(
      setDoc(doc(asClaimless(env, 'new-1'), 'members/member-9'), {
        name: 'Not mine',
      }),
    );
  });

  test('a new sign-in cannot hand itself a membership', async () => {
    await assertFails(
      setDoc(doc(asClaimless(env, 'new-2'), 'members/new-2'), {
        name: 'Chancer',
        membershipStatus: 'active',
        expiryDate: new Date('2030-01-01'),
      }),
    );
  });

  test('only an admin deletes a member', async () => {
    const { deleteDoc } = await import('firebase/firestore');
    await assertFails(deleteDoc(doc(asMember(env), 'members/member-1')));
    await assertFails(deleteDoc(doc(asTrainer(env), 'members/member-1')));
    await assertSucceeds(deleteDoc(doc(asAdmin(env), 'members/member-1')));
  });
});
