import { readFileSync } from 'node:fs';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';

/**
 * One emulator environment shared by every test file.
 *
 * The rules are read from the repository rather than inlined, so these
 * tests fail when the real rules change, which is the only way they are
 * worth anything.
 */
export async function createTestEnv() {
  return initializeTestEnvironment({
    // A `demo-` prefix is a guarantee, not a convention: the
    // emulators refuse to reach live services for such a project, so a
    // misconfigured host cannot touch real member data.
    projectId: 'demo-deepfitness',
    firestore: {
      rules: readFileSync('../firestore.rules', 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
    storage: {
      rules: readFileSync('../storage.rules', 'utf8'),
      host: '127.0.0.1',
      port: 9199,
    },
  });
}

/** A signed-in member. */
export const asMember = (env, uid = 'member-1') =>
  env.authenticatedContext(uid, { role: 'member' }).firestore();

/** A signed-in trainer. */
export const asTrainer = (env, uid = 'trainer-1') =>
  env.authenticatedContext(uid, { role: 'trainer' }).firestore();

/** A signed-in admin. */
export const asAdmin = (env, uid = 'admin-1') =>
  env.authenticatedContext(uid, { role: 'admin' }).firestore();

/** Nobody. */
export const asAnon = (env) => env.unauthenticatedContext().firestore();

/**
 * A signed-in user carrying no role claim at all.
 *
 * This is the state between a first sign-in and onMemberCreate setting
 * the claim, so it is a real case and not a hypothetical one.
 */
export const asClaimless = (env, uid = 'new-1') =>
  env.authenticatedContext(uid).firestore();

/** Seeds documents with the rules switched off. */
export const seed = (env, write) => env.withSecurityRulesDisabled(
  (context) => write(context.firestore()),
);
