/**
 * Imports the Vital Animations pack into the `exercises` collection.
 *
 * Run it after `scripts/build_exercise_media.py` has produced the manifest
 * and `scripts/upload_exercise_media.ps1` has pushed the media, since the
 * URLs this writes are only good once the objects are actually there.
 *
 *   node functions/tools/import-exercises.js \
 *     --manifest X:/Code/DeepFitness_Assets/build/manifest.json \
 *     --base-url https://media.example.com/exercises \
 *     --dry-run
 *
 * It lives under functions/ so that `require('firebase-admin')` resolves
 * against the Cloud Functions install rather than needing a second copy of
 * the SDK at the repository root. It is excluded from deploys in
 * firebase.json; nothing here runs in production.
 *
 * Credentials come from the environment, never from a key committed to the
 * repository: either GOOGLE_APPLICATION_CREDENTIALS pointing at a service
 * account file, or `gcloud auth application-default login`.
 *
 * Re-running is safe. An exercise that already exists has only its media and
 * its pack metadata refreshed — name, description and the default sets and
 * reps are left alone, because a trainer may have edited them in the
 * dashboard and an import should not undo that.
 */

"use strict";

const fs = require("fs");
const admin = require("firebase-admin");

const PROJECT_ID = "deepfitess-app";
const COLLECTION = "exercises";
const CREATED_BY = "import:vital-animations";

function parseArgs(argv) {
  const args = { dryRun: false, limit: 0 };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--dry-run") args.dryRun = true;
    else if (a === "--manifest") args.manifest = argv[++i];
    else if (a === "--base-url") args.baseUrl = argv[++i];
    else if (a === "--limit") args.limit = Number(argv[++i]);
    else throw new Error(`unknown argument: ${a}`);
  }
  if (!args.manifest) throw new Error("--manifest is required");
  if (!args.baseUrl) throw new Error("--base-url is required");
  args.baseUrl = args.baseUrl.replace(/\/+$/, "");
  return args;
}

/** The fields a re-import is allowed to overwrite. */
function mediaFields(entry, baseUrl) {
  return {
    videoUrl: `${baseUrl}/${entry.video}`,
    posterUrl: `${baseUrl}/${entry.poster}`,
    muscleGroup: entry.target ?? "",
    bodyPart: entry.bodyPart ?? "",
    equipment: entry.equipment ?? "",
    secondaryMuscles: entry.secondaryMuscles ?? [],
    // Carried even though the Dart model does not read them yet: the pack
    // has them, they are the step-by-step coaching text, and discarding
    // them here would mean re-running the whole import to get them back.
    instructions: entry.instructions ?? [],
    source: "vital-animations",
  };
}

/** The rest of the document, written only when creating. */
function createOnlyFields(entry) {
  return {
    name: entry.name ?? "",
    description: entry.description ?? "",
    photoUrls: [],
    defaultSets: 3,
    defaultReps: 10,
  };
}

async function main() {
  const args = parseArgs(process.argv);

  const manifest = JSON.parse(fs.readFileSync(args.manifest, "utf8"));
  const entries = args.limit ? manifest.slice(0, args.limit) : manifest;
  console.log(`${entries.length} exercises in ${args.manifest}`);
  console.log(`base url: ${args.baseUrl}`);

  if (args.dryRun) {
    const sample = entries[0];
    console.log("\n--dry-run, nothing will be written. First document:");
    console.log(
      JSON.stringify(
        {
          _id: sample.id,
          ...createOnlyFields(sample),
          ...mediaFields(sample, args.baseUrl),
        },
        null,
        2,
      ),
    );
    return 0;
  }

  admin.initializeApp({
    projectId: PROJECT_ID,
    credential: admin.credential.applicationDefault(),
  });
  const db = admin.firestore();
  const { FieldValue } = admin.firestore;

  // Which already exist, so the import refreshes those and creates the rest.
  // getAll takes references in one round trip per chunk rather than 832.
  const existing = new Set();
  for (let i = 0; i < entries.length; i += 300) {
    const refs = entries
      .slice(i, i + 300)
      .map((e) => db.collection(COLLECTION).doc(e.id));
    const snaps = await db.getAll(...refs);
    for (const snap of snaps) if (snap.exists) existing.add(snap.id);
  }
  console.log(`${existing.size} already present, ${entries.length - existing.size} new`);

  const writer = db.bulkWriter();
  let created = 0;
  let refreshed = 0;
  let failed = 0;

  writer.onWriteError((error) => {
    if (error.failedAttempts < 3) return true;
    failed++;
    console.error(`  FAILED ${error.documentRef.id}: ${error.message}`);
    return false;
  });

  for (const entry of entries) {
    const ref = db.collection(COLLECTION).doc(entry.id);
    if (existing.has(entry.id)) {
      refreshed++;
      writer.set(
        ref,
        { ...mediaFields(entry, args.baseUrl), updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
    } else {
      created++;
      writer.set(ref, {
        ...createOnlyFields(entry),
        ...mediaFields(entry, args.baseUrl),
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        createdBy: CREATED_BY,
        deletedAt: null,
      });
    }
  }

  await writer.close();
  console.log(`\ncreated   : ${created}`);
  console.log(`refreshed : ${refreshed}`);
  if (failed) {
    console.log(`failed    : ${failed}`);
    return 1;
  }
  return 0;
}

main()
  .then((code) => process.exit(code))
  .catch((error) => {
    console.error(`\n${error.message}`);
    if (/credential|authenticat|default/i.test(error.message)) {
      console.error(
        "\nNo credentials. Either run `gcloud auth application-default login`,\n" +
          "or set GOOGLE_APPLICATION_CREDENTIALS to a service account key path.",
      );
    }
    process.exit(1);
  });
