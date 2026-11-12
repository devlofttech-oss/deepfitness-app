import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // The four suites share one emulator, and each clears Firestore
    // between its own tests. Run in parallel they wipe each other's
    // seeded documents mid-flight, which shows up as NOT_FOUND on a
    // document that was just written, or a rule failing on a null
    // `resource` — both of which look like rule bugs and are not.
    fileParallelism: false,

    // Starting the emulator and seeding is slower than a unit test.
    testTimeout: 15000,
    hookTimeout: 30000,
  },
});
