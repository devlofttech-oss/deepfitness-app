# Deep Fitness — Implementation Checklist

Source of truth: `guide/Deep-Fitness-Developer-Guide.pdf` (Devloft Technologies, 25 Oct 2026).
UI reference: Stitch project `13029041100569647567`.

Tick a box only when the item is implemented **and** verified (`flutter analyze` + `flutter test` clean).

---

## 0. Blockers

- [x] **B1. Backend conflict resolved — migrate to Firebase**, as the guide states. The Supabase client, config and service are gone from `lib/`; the old schema is parked in `legacy/supabase/`. Items marked **[FB]** are no longer blocked.
- [ ] **B1a. Move the live Supabase data into Firestore.** Members, exercises, plans and history exist only in Postgres today. This needs an export/transform/import script and a cutover plan. The hard part is accounts: Firebase Auth issues new UIDs, so every member has to be re-created and re-invited, or matched on email/phone — and member documents are keyed by UID, so the mapping decides every other collection's foreign keys.
- [ ] **B1b. Port the maintenance scripts.** `scripts/import_exercise_metadata.ps1`, `scripts/migrate_workouts_to_dataset_exercises.ps1` and `scripts/upload_exercise_images.ps1` all target Supabase and no longer work.
- [ ] **B2. Stitch design not readable.** `stitch.withgoogle.com` requires a Google sign-in the tooling cannot perform. Need an export (Figma link, screenshots, or the generated HTML/CSS) before any screen can be checked against the design.
- [ ] **B3. Confirm the production project.** The guide says the app is already live and data changes must be additive. Confirm which Firebase project is production, and what happens to the live Supabase project, before the cutover.

---

## Migration status

The backend cut-over is done, and the screens have caught up with it.

**Landed:** Firebase bootstrap with emulator support, Analytics/Crashlytics
gated to release; `AppFirebase` as the single SDK gateway; `RepositoryFailure`
+ `guard()` for typed errors; `fetchPage`/`fetchAllPaged` for cursor
pagination; base fields and soft delete; defensive reads via `Val`; the
assignment snapshot (`AssignedPlan`/`AssignedExercise`) and append-only
`CompletionLog`; sequential unlock and skip-with-reason; Firebase Auth with
phone OTP and email fallback, roles as custom claims; `firestore.rules`,
`storage.rules` and `firestore.indexes.json`; all six Cloud Functions in
TypeScript; Android and iOS platform wiring.

The screens have now caught up with it: locking, skipping, OTP, onboarding
and the renewal screen are all wired, with 47 unit and widget tests behind
them.

**Next, in order:**

1. **Rules tests in the emulator** — the rules are written but unverified, and
   the guide is explicit that rules written last are rules written loosely.
   This is the gate before any deploy.
2. **Events and classes/booking** (modules 04 and 05) — models, rules and the
   functions exist; the repositories, the member-side booking transaction and
   the screens do not.
3. **Charts on the progress screen** — `fl_chart` is in, nothing draws with it
   yet, and the week/month presets are not exposed.
4. **Notifications UI** — the in-app announcements list.
5. **Admin dashboard** (module 08) on Flutter Web.
6. **Data migration** (B1a) and the release checklist.

---

## 1. Overview & member path (Guide §01)

- [x] Flutter + Dart, single codebase, Android & iOS
- [x] **[FB]** Firebase as the backend
- [x] Member signs in; profile row created
- [x] Phone OTP sign-in as the **primary** method — `AuthRepository.sendOtp` / `confirmOtp`; a non-email identifier routes to OTP, email falls back to password
- [x] Phone OTP wired into the login screen UI — a Phone/Email segmented control, phone first, with a send-code then verify step
- [x] Assigned plan visible on the home screen
- [x] **Sequential unlock** in the data layer: `AssignedPlan.currentIndex` + `isLockedAt`, surfaced as `Exercise.isLocked` / `WorkoutPlan.isUnlocked`
- [x] Sequential unlock enforced in the UI — a locked row is dimmed with a lock icon and refuses the tap; "Start Workout" opens `currentExercise`
- [x] **Skip with reason** that still advances — `AppDataRepository.skipExercise`, reason required
- [x] Skip surfaced in the UI — a "Skip this exercise" button opens a reason sheet with four one-tap presets and a free-text box
- [x] Completion log written on completion — `completion_logs`, append-only, written with the index advance in one batch
- [ ] Classes & events: browse class videos, book a live class, RSVP to events (module absent)
- [x] Roles: member and trainer
- [x] Role `admin` exists as a custom claim and in the rules
- [ ] `admin` represented in the Dart `UserRole` enum (currently folded into `trainer`)
- [x] Brand palette set once in the theme file (`app_colors.dart`, `app_theme.dart`)

---

## 2. Architecture & tech stack (Guide §02)

- [x] Riverpod for state, providers per feature
- [x] go_router with an auth redirect guard
- [x] No custom API server; client talks to the backend directly
- [x] **[FB]** Cloud Firestore as the database
- [x] **[FB]** Firebase Authentication (phone OTP + email/password)
- [x] **[FB]** Firebase Cloud Storage wired, with `storage.rules` validating content type and size
- [ ] Photo upload implemented in the app, resized on device before upload
- [x] **[FB]** Cloud Functions (TypeScript) — all six from the guide, compiling clean
- [x] **[FB]** Firebase Cloud Messaging wired — `PushService`, `fcmTokens[]`, iOS background mode declared
- [ ] APNs key uploaded and push capability enabled in Xcode (needs the real project)
- [ ] Class videos as external links (store `videoProvider` + `videoId`, embed the player)
- [x] Firebase Analytics + Crashlytics, release builds only — both gated on `kReleaseMode` in `main.dart`
- [ ] Flutter Web admin dashboard on Firebase Hosting
- [x] Request path: widget → provider → repository → SDK (`app_data_repository.dart` is the single gateway)
- [x] Widgets never touch the backend SDK directly — everything goes through `AppFirebase`; no screen imports `cloud_firestore`
- [x] Access control enforced server-side — `firestore.rules`, deny-by-default
- [ ] Rules verified against the role matrix in the emulator (written, not yet tested)

---

## 3. Project structure & setup (Guide §03)

- [ ] Restructure `lib/` to the guide's layout: `app/`, `core/{models,repositories,services,widgets,utils}`, `features/<module>/{data,domain,presentation}`, `admin/`
  - [x] `features/` is feature-first
  - [ ] Each feature split into `data/` + `domain/` + `presentation/` (only `auth/` is; the rest are presentation-only)
  - [x] `core/models/`, `core/repositories/`, `core/services/`, `core/utils/` created and in use
  - [ ] `shared/models/deepfitness_models.dart` moved into `core/models/` (UI models still live there)
  - [ ] `core/utils/` for formatters, validators, date helpers
  - [ ] `app/router.dart` + `app/theme.dart` (currently `core/router/`, `core/theme/`)
- [ ] `admin/` folder for the Flutter Web dashboard
- [x] **[FB]** `functions/` (TypeScript), `firestore.rules`, `storage.rules`, `firestore.indexes.json`, `firebase.json`, `.firebaserc`
- [ ] **[FB]** FlutterFire CLI configured; `firebase_options.dart` generated per platform — currently a dart-define-driven placeholder, needs a real project
- [x] **[FB]** Both platform config files are gitignored; the Google Services and Crashlytics Gradle plugins are applied and `minSdk` raised to 23
- [ ] **[FB]** `google-services.json` / `GoogleService-Info.plist` placed (needs a real project)
- [x] **[FB]** Emulator suite configured in `firebase.json` and honoured by `main.dart` via `USE_EMULATOR`
- [ ] Two environments (dev + prod) selected by build flavor, so a debug build can never point at production data
- [x] Setup documented in `README.md`, rewritten for Firebase

---

## 4. Conventions (Guide §04)

- [x] Models over maps — Dart models exist in `deepfitness_models.dart`
- [x] New models have `fromFirestore` / `toFirestore`: `Member`, `AssignedPlan`, `CompletionLog`, `GymEvent`, `GroupClass`, `ClassSession`, `Booking`, `Announcement`, `Exercise`
- [ ] `withConverter` used at the collection reference rather than mapping per call
- [x] No raw `Map<String, dynamic>` above the repository layer
- [x] Repositories only: widgets/providers call repositories
- [x] **Base fields on every document**: `BaseFields.onCreate` / `onUpdate` / `onDelete`
- [x] Timestamps written with `FieldValue.serverTimestamp()`, and the rules reject a write whose `updatedAt` is not `request.time`
- [x] **Soft delete**: `deletedAt` set on delete, `fetchPage` filters it out by default, `allow delete: if false` on the log collections
- [x] **Defensive reads**: every field read goes through `Val`, which defaults rather than throwing
- [x] **Pagination**: `fetchPage` (limit + `startAfterDocument`) and a capped `fetchAllPaged`; `fetchTrainerStats` uses server-side `count()`
- [x] **Enums for status**, stored as strings: `AssignedPlanStatus` (with `canMoveTo`), `MembershipStatus`, `BookingStatus`, `VideoProvider`, `AnnouncementAudience`
- [x] **Typed failures**: `RepositoryFailure` + `guard()`; every public repository method is wrapped
- [x] **Naming**: plural `snake_case` collections in `FirestorePaths`, `snake_case.dart` files, `UpperCamelCase` classes
- [x] `flutter analyze` clean and `flutter test` passing as of this change
- [ ] Enforced in CI

---

## 5. Authentication & access (Guide §05)

- [x] Phone OTP as the primary sign-in method
- [x] Email + password as the fallback
- [x] Member profile created on first login (`create-member` function)
- [x] Profile keyed by the auth UID — `members/{uid}`, and every other collection references that uid
- [x] **Role as a custom claim** (`member` / `trainer` / `admin`), set only by `onMemberCreate` / `setUserRole`; never a client-writable field
- [x] Router redirects on auth state: signed out → login
- [x] Signed in **without a profile → onboarding** — `/onboarding` collects name, goal, gender, age and height
- [x] Signed in with a profile → home
- [x] **Lapsed membership is a state, not a sign-out** — `/renew` is shown and only the training routes are diverted, so progress, profile and history stay readable
- [x] Access rules written alongside each feature — every collection was ruled as it was modelled
- [ ] Rules unit-tested in the emulator: for each role, what is allowed and what must be denied
- [x] Rules deny by default; no collection left world-readable or writable

---

## 6. Data model (Guide §06)

Every collection below is modelled in Dart and covered by `firestore.rules`.
"Modelled" means the converters and rules exist; it does not mean a screen
reads it yet.

- [x] `members` — `Member`, keyed by the Firebase UID, with `photoUrl`, `joinedAt`, `membershipStatus`, `expiryDate`, `fcmTokens[]`
- [x] `exercises` — `Exercise.fromFirestore`, the admin-managed library
- [x] `workout_plans` — reusable template holding its own exercise array
- [x] `assigned_plans` with an **exercise snapshot** taken at assignment time (`memberId`, `planId`, `title`, `exercises[]`, `currentIndex`, `status`, `assignedAt`)
  - The snapshot is the fix for the old model, which referenced the library: editing an exercise used to rewrite every member's completed history retroactively and break the reports.
  - Subcollection `assigned_plans/{id}/progress/{order}` holds in-progress sets and the member's note, so `completion_logs` stays append-only while a half-finished exercise still survives the app closing.
- [x] `completion_logs` — `CompletionLog`, the single append-only source for every report (`memberId`, `assignedPlanId`, `exerciseIndex`, `exerciseName`, `setsDone`, `sets[]`, `skipped`, `skipReason`, `completedAt`)
- [x] `events` — `GymEvent`
- [x] `event_rsvps` — `EventRsvp`, id `${eventId}_${memberId}` so uniqueness is structural rather than query-enforced
- [x] `group_classes` — `GroupClass`
- [x] `class_sessions` — `ClassSession`
- [x] `bookings` — `Booking`, id `${sessionId}_${memberId}`; the transaction itself is in `onBookingCancelled`, and the member-side booking transaction is still to write
- [x] `announcements` — `Announcement`, written only by `sendAnnouncement`
- [x] Compound-query indexes declared in `firestore.indexes.json`, not created from a console error link
- [ ] Indexes actually deployed (needs a real project)

Kept from the old model, not in the guide — confirm they stay: `trainers`,
`measurements`, `diet_plans` (meals now embedded), `diet_logs`, `water_logs`.
`exercise_notes` and `workout_completions` are gone: notes moved into the plan
progress subcollection, and completions are derived from `completion_logs` plus
the plan's own status.

---

## 7. Module reference (Guide §07)

### Module 01 — Authentication & Member Profile
- [x] Phone OTP sign-in
- [x] Email sign-in
- [x] Profile created on first login
- [x] Profile edit writes only the member's own record
- [x] Profile edit enforced by server rules — `members/{uid}` update is key-restricted, so a member cannot set their own role or membership state
- [ ] Photo upload, resized on device before upload
- [x] FCM token saved to `fcmTokens[]` on login and removed on logout — `PushService.start` / `stop`

### Module 02 — Workout Plans *(the largest module)*
- [x] Exercise library (admin/trainer side)
- [x] Plan builder (trainer side)
- [ ] Plan builder on the **web dashboard**
- [x] Assignment **snapshots** exercise details onto `assigned_plans` — `AssignedExercise.snapshot`, taken in `saveWorkoutPlan`
- [x] `currentIndex` drives the unlock — `AssignedPlan.isLockedAt`, enforced in the rules too (a member may only move it forward)
- [x] Completing or skipping writes a log **and** advances `currentIndex` in one batch — `_writeCompletion`
- [x] Skip requires a reason and still advances — enforced in `skipExercise` and again in the rules
- [x] Unlock progress persists — `currentIndex` is a stored field, never recomputed per day
- [x] Exercise logging screen with sets, reps, weight
- [x] Rest timer / per-exercise notes

### Module 03 — Workout Reports
- [x] Progress screen exists
- [x] Range selector as a single query on `completedAt`; `selectLastWeek` / `selectThisMonth` / custom on `ProgressDateRangeController`
- [ ] Week and month presets exposed in the progress screen UI
- [x] Completion rate, streaks, personal bests and muscle split all derived in Dart from `completion_logs`, nothing stored
- [x] `fl_chart` added as the charting package
- [ ] Charts actually drawn with it on the progress screen
- [ ] Shareable summary rendered as an image from the widget tree (`share_plus` is present but shares text)

### Module 04 — Events
- [x] `events` / `event_rsvps` modelled, ruled and indexed (`GymEvent`, `EventRsvp`)
- [ ] Event list query: `startsAt >= now`, ascending, paginated — repository method not written
- [ ] Event detail screen
- [ ] RSVP creates one document; rules allow a member only their own
- [x] Scheduled function sends a reminder push the day before — `dailyReminders`
- [ ] Admin creates/edits events

### Module 05 — Group Classes & Booking
- [ ] Class list with thumbnails
- [x] Videos as external links — `videoProvider` + `videoId` stored, embed URL built by `VideoProvider.embedUrl`
- [ ] Player embedded in-app (member is never thrown out to YouTube)
- [ ] Session list per class
- [ ] Booking runs in a transaction: read `bookedCount` against `capacity`, then write the booking and the counter together — two members tapping at once cannot oversell the last place
- [ ] Full session adds a waitlisted booking with a position
- [x] Cancelling frees the slot and promotes the first waitlisted member in one transaction, then pushes them — `onBookingCancelled`
- [ ] Admin view lists bookings per session

### Module 06 — Notifications
- [x] FCM wired on Android
- [ ] FCM wired on iOS (APNs key uploaded, push capability enabled in Xcode)
- [x] `sendAnnouncement` fans out to a topic and is admin-only
- [ ] Admin compose UI (needs the dashboard)
- [x] Every push mirrored into `announcements` — written before the send, so a failed send is still on record
- [ ] In-app announcements list
- [x] Invalid tokens pruned from `fcmTokens[]` on send failure — `pushToTokens`
- [x] Notification on/off preference stored and honoured — `pushToMember` returns early when it is false

### Module 07 — iOS App
- [ ] APNs key + push capability
- [x] `Info.plist` usage strings for camera and photos, plus the remote-notification background mode
- [ ] Phone-auth reCAPTCHA fallback — `CFBundleURLTypes` is in place with a `REVERSED_CLIENT_ID` placeholder to swap once the project exists
- [ ] Layout checked from iPhone SE through Pro Max widths, with notch safe areas
- [ ] Apple sign-in (required by App Store policy if any other social login is added)

### Module 08 — Admin Dashboard (Flutter Web)
- [ ] Web target builds from the same codebase, sharing models and repositories
- [ ] Manage the exercise library, plans and assignments
- [ ] Create events, classes and class sessions
- [ ] Member list with workout history
- [ ] Compose and send announcements
- [ ] Admin-only by custom claim, enforced in rules and not merely hidden in the UI
- [ ] Deployed to hosting

---

## 8. Cloud Functions (Guide §08)

- [x] `onMemberCreate` (auth create) — creates the member document and sets the default role claim, without overwriting one `createMember` just wrote
- [x] `createMember` (callable, trainer/admin) — replaces the Supabase edge function; creates the auth user, the member document, the joining measurement and the invite text
- [x] `setUserRole` (callable, admin) — sets the claim and revokes refresh tokens so it takes effect
- [x] `sendAnnouncement` (callable, admin) — fans out an FCM message and mirrors it into `announcements`
- [x] `onBookingCancelled` (write trigger) — promotes the first waitlisted member in a transaction and notifies them
- [x] `dailyReminders` (scheduled, daily) — class reminders, event reminders, membership-expiry warnings, and flips a lapsed membership
- [x] `inactivityNudge` (scheduled, weekly) — pushes members with no completion log in the last 10 days
- [ ] Blaze plan enabled for scheduled functions
- [ ] Budget alert set on the project
- [x] No function writes a document that re-triggers itself — `onBookingCancelled` only fires on a booked→cancelled transition, and nothing else writes `bookings`

---

## 9. Testing, release & handover (Guide §09)

### Testing
- [x] Unit tests for unlock advance, skip, report maths, defensive reads, phone normalisation and membership state — 47 passing
- [ ] Unit tests for booking capacity (the member-side booking transaction is not written yet)
- [ ] Security-rules tests in the emulator: per role, what is allowed and what must be denied
- [ ] Widget tests for every plan screen state: locked, active, complete, skipped, empty — the login screen has three; the plan screens need a fake repository first
- [ ] Integration test of the full path: sign in → assigned plan → complete → report
- [ ] Device testing on a spread of real Android handsets and iPhone sizes, not only emulators
- [x] `flutter analyze` clean
- [x] `flutter test` clean — 47 tests

### Release
- [ ] Bump `version` in `pubspec.yaml`; build number increases on every store upload
- [ ] Android: app bundle → Play Console → staged rollout (10% / 50% / 100%)
- [ ] iOS: archive → App Store Connect → review
- [ ] Rules, indexes and functions deployed with the release, **rules before** the client that depends on them
- [ ] Previous bundle kept so a rollback is possible
- [ ] Data changes additive only — new fields alongside old ones, every new field with a default (older builds read these rows for weeks)

### Security checklist
- [x] Rules deny by default — a catch-all `match /{document=**}` denies everything not matched above
- [x] Roles are custom claims — the `role` field is excluded from every member-writable key list
- [x] Storage rules validate content type and size
- [x] No service-account key or API secret in the repository
- [x] Analytics and crash reporting off in debug builds

### Handover
- [ ] Full source code delivered
- [ ] Backend project ownership transferred
- [ ] Store listings handed over
- [ ] Written user guide
- [ ] This developer guide delivered
- [ ] Training session for gym staff
- [ ] Anything outside the agreed eight modules is a separate change, not added to these modules ad hoc

---

## 10. UI design (Stitch)

- [ ] Obtain a readable export of the Stitch project (blocked — see B2)
- [ ] Map every Stitch screen to a route in `app_router.dart`
- [ ] Reconcile colours, typography and spacing with `app_colors.dart` / `app_theme.dart`
- [ ] Identify screens in the design that have no implementation yet
- [ ] Identify screens implemented that are not in the design

---

## 11. Out of guide — present in the repo

Decide whether each stays, moves behind a flag, or is removed.

- [ ] Diet / nutrition module — migrated to Firestore (`diet_plans` with embedded meals, `diet_logs`, `water_logs`) and still hidden in the UI; decide whether it stays
- [ ] Body-measurement tracking (`measurements`, body assets under `assets/body/`)
- [ ] Muscle-progress and personal-best detail screens
- [ ] WhatsApp member-invite flow (`CreatedMemberInvite`)
- [ ] `dandiya-night-2026/` — an unrelated event microsite in the repository
- [ ] `docs/` marketing + policy site
