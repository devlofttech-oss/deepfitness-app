# Module status

Measured against `pdfs/Deep-Fitness-Developer-Guide.pdf` (25 October 2026),
which is the source of truth for scope. Only the modules named there belong
in this repository.

**Overall: roughly 20% built.**

Nothing in this repository has been compiled or analysed yet. Percentages
below describe code written against the specification, not code proven to
run. `flutter analyze`, `flutter test` and the Firestore rules tests all
still need to pass before any of this counts as done.

| # | Module | Done |
|---|--------|------|
| 01 | Authentication & member profile | 60% |
| 02 | Workout plans | 0% |
| 03 | Workout reports | 0% |
| 04 | Events | 0% |
| 05 | Group classes & booking | 10% |
| 06 | Notifications | 30% |
| 07 | iOS app | 0% |
| 08 | Admin dashboard (Flutter Web) | 0% |
| — | Cross-cutting (rules, indexes, functions, release) | 45% |

---

## 01 · Authentication & member profile — 60%

- [x] Phone OTP sign-in, with resend
- [x] Email and password as the fallback, with password reset
- [x] Member document created on first login, keyed by the Firebase UID
- [x] Role read from the `role` custom claim, never a client field
- [x] FCM token added to `fcmTokens[]` on login
- [x] FCM token removed on logout, before the sign-out itself
- [x] Router redirects on auth state: signed out, no profile, ready
- [x] Lapsed membership is a state on the document, not a sign-out
- [ ] Profile edit screen writing only the member's own document
- [ ] Profile photo resized on device before upload to Cloud Storage
- [ ] Renewal screen for a lapsed membership (currently one line on home)
- [ ] Rules tests covering what a member may and may not write

## 02 · Workout plans — 0%

The largest module. Nothing built.

- [ ] `Exercise`, `WorkoutPlan`, `AssignedPlan` models with converters
- [ ] Repositories for each, through `BaseRepository`
- [ ] Assignment snapshots exercise details onto `assigned_plans`
- [ ] `currentIndex` drives the unlock; an exercise is locked when its
      index exceeds it
- [ ] Completing an exercise writes a log and advances `currentIndex` in
      one batch
- [ ] Skip requires a reason, still advances, so a member is never stuck
- [ ] Unlock progress persists across sessions; it does not reset daily
- [ ] Plan screen states: locked, active, complete, skipped, empty
- [ ] Widget tests for those five states
- [ ] Unit tests for unlock advance and skip

Reference: `legacy/supabase-era/workout/`, `legacy/supabase-era/home/`.

## 03 · Workout reports — 0%

- [ ] Range selector: week, month, custom, as one query on `completedAt`
- [ ] Completion rate, streaks and sets completed derived in Dart
- [ ] Charts with a Flutter charting package, no server round trip
- [ ] Shareable summary rendered as an image from the widget tree
- [ ] Unit tests for the report maths

No charting package is in `pubspec.yaml` yet.
Reference: `legacy/supabase-era/progress/`.

## 04 · Events — 0%

- [ ] `Event` and `EventRsvp` models and repositories
- [ ] List filtered `startsAt >= now`, ascending, paginated
- [ ] RSVP creates one document per member per event
- [x] Rules allow a member only their own RSVP
- [x] Index for `startsAt` and for the event/member RSVP lookup
- [ ] Reminder push the day before (function exists, unverified)

## 05 · Group classes & booking — 10%

- [ ] `GroupClass`, `ClassSession`, `Booking` models and repositories
- [ ] Video stored as `videoProvider` + `videoId`, embed URL built in app
- [ ] Player embedded in-app, not a jump out to YouTube
- [ ] Booking in a Firestore transaction: read `bookedCount` against
      `capacity`, then write booking and counter together
- [ ] Full session adds a waitlisted booking with a position
- [ ] Cancelling frees the slot and promotes the first waitlisted member
      in the same transaction
- [x] `onBookingCancelled` function exists (compiled only, untested)
- [x] Rules: members book and cancel their own; promotion is privileged
- [x] Indexes for session/status/position and member/status/createdAt
- [ ] Admin view listing bookings per session
- [ ] Unit tests for booking capacity

No video player package is in `pubspec.yaml` yet.

## 06 · Notifications — 30%

- [x] `sendAnnouncement` function fans out and mirrors to `announcements`
- [x] Rules make `announcements` read-only from any client
- [x] Index on audience and `sentAt`
- [x] Permission requested and token registered on sign-in
- [ ] In-app announcements list, so a dismissed push survives
- [ ] Invalid tokens pruned from `fcmTokens[]` on send failure (needs
      checking inside the function)
- [ ] Foreground and background message handling in the app
- [ ] Notification tap routing to the right screen
- [ ] APNs key uploaded to Firebase, push capability enabled in Xcode

## 07 · iOS app — 0%

- [ ] `GoogleService-Info.plist` in `ios/Runner/` and added to the target
- [ ] APNs key uploaded, push capability enabled
- [ ] Phone-auth reCAPTCHA fallback configured with the URL scheme
- [ ] `Info.plist` usage strings for camera and photos
- [ ] Layout checked from iPhone SE to Pro Max, notch safe areas
- [ ] Apple sign-in, if any other social login is added

Requires a Mac. `flutterfire configure` registered the iOS app but the
plist was never placed.

## 08 · Admin dashboard (Flutter Web) — 0%

- [ ] Web target configured (`flutterfire configure` was run without it)
- [ ] `lib/admin/` screens, sharing models and repositories with the app
- [ ] Manage the exercise library, plans and assignments
- [ ] Create events, classes and class sessions
- [ ] Member list with workout history
- [ ] Compose and send announcements
- [x] Admin-only enforced in rules by custom claim, not hidden in the UI
- [ ] Deployed to Firebase Hosting

Reference: `legacy/supabase-era/trainer/` — 2,655 lines covering the
exercise library, plan builder, assignment flow and member list. That is
the bulk of this module's work, written against Supabase.

## Cross-cutting — 45%

- [x] `firestore.rules` for all eleven collections, deny by default
- [x] `storage.rules` with content type and size checks
- [x] `firestore.indexes.json` for every compound query in the model
- [x] Base document fields: server timestamps, soft delete, audit
- [x] Defensive reads: every model defaults a missing field
- [x] Pagination through `BaseRepository`, never a full collection read
- [x] Typed failures; screens show a sentence, not an exception
- [x] Models over maps, repositories only
- [ ] Rules tests in the emulator, per role
- [ ] Integration test: sign in, assigned plan, complete, report
- [ ] `flutter analyze` and `flutter test` clean
- [ ] Analytics and Crashlytics, release builds only
- [ ] Staged rollout and the release checklist

---

## Where this deviates from the document

These are open, and each needs a decision.

1. **One Firebase project, and its id is misspelled.** The document asks
   for `deepfitness-dev` and `deepfitness-prod` with build flavors. What
   exists is a single `deepfitess-app`. A project id cannot be renamed.
2. **Cloud Functions have no source.** `functions/` holds compiled
   JavaScript in `lib/` only — no `src/`, no `package.json`, no
   `tsconfig.json`. The document requires TypeScript. As it stands the
   functions cannot be built or deployed from a clone, and no function has
   been read against its specification.
3. **No emulator use yet.** The document asks for rules written alongside
   each feature and tested in the emulator. The rules are written; none
   has been run.
4. **Brand palette is inherited, not the gym's.** `lib/app/colors.dart`
   still carries the previous build's orange.
5. **`legacy/` is not in the document's layout.** It holds the Supabase-era
   screens as reference for modules 02 to 08 and is excluded from
   analysis. It should be empty and deleted by the end.
6. **Colours live in `app/colors.dart`,** beside `app/theme.dart` rather
   than inside it. Cosmetic.
7. **The document says `google-services.json` is not committed.** It is
   committed here. Harmless, but it is a divergence.

## What is blocked on the client

- Blaze plan: `dailyReminders` and `inactivityNudge` cannot deploy on Spark.
- The gym's brand colours.
- A Mac for the iOS build and signing.
- The decision on recreating the Firebase projects.
