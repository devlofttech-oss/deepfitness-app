# Module status

Measured against `pdfs/Deep-Fitness-Developer-Guide.pdf` (25 October 2026),
which is the source of truth for scope. Only the modules named there belong
in this repository.

**Overall: roughly 65% built.**

Nothing in this repository has been compiled or analysed yet. Percentages
below describe code written against the specification, not code proven to
run. `flutter analyze`, `flutter test` and the Firestore rules tests all
still need to pass before any of this counts as done.

| # | Module | Done |
|---|--------|------|
| 01 | Authentication & member profile | 90% |
| 02 | Workout plans | 85% |
| 03 | Workout reports | 90% |
| 04 | Events | 85% |
| 05 | Group classes & booking | 85% |
| 06 | Notifications | 75% |
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
- [x] Profile edit screen writing only the member's own document
- [x] Profile photo resized on device before upload to Cloud Storage
- [x] Renewal screen for a lapsed membership, with the profile still open
- [ ] Rules tests covering what a member may and may not write

## 02 · Workout plans — 85%

- [x] `Exercise`, `WorkoutPlan`, `AssignedPlan`, `CompletionLog` models
      with Firestore converters and defaulted reads
- [x] `AssignedPlanRepository` through `BaseRepository`
- [x] `PlanExercise.snapshot` copies exercise details at assignment time
- [x] `currentIndex` drives the unlock; an exercise is locked when its
      index exceeds it
- [x] Completing writes a log and advances `currentIndex` in one batch
- [x] Skip requires a reason, still advances, so a member is never stuck
- [x] Unlock progress persists; it is stored, not reset daily
- [x] Plan screen states: locked, active, complete, skipped, empty
- [x] Set counter, with an undo on the last tap
- [x] Home screen shows the plan and what is next
- [x] Widget tests for the five states
- [x] Unit tests for unlock, advance, completion and progress
- [ ] Plan history beyond the current assignment (repository is ready,
      no screen yet)
- [ ] The assignment side itself, which is dashboard work in module 08

Reference: `legacy/supabase-era/workout/`, `legacy/supabase-era/home/`.

## 03 · Workout reports — 90%

- [x] Range selector: week, month, custom, as one query on `completedAt`
- [x] Completion rate, streaks and sets derived in Dart, nothing stored
- [x] Per-day series, including days with no activity
- [x] Bar chart of sets per day (fl_chart), no server round trip
- [x] Shareable summary rendered as a PNG from the widget tree
- [x] Empty and error states
- [x] Unit tests for the report maths: rate, streaks, ranges, day bucketing
- [ ] Personal bests, if the client wants them (not in the document)
- [ ] Widget test of the range selector changing the query

Decisions worth knowing: the completion rate divides by what the member
got through, not what was assigned, so an untouched exercise ahead of them
is not counted as a failure. A streak ending yesterday still counts while
today is young, so the number does not flicker through the day. A log
whose server timestamp has not landed yet is left out rather than guessed
onto a day.

## 04 · Events — 85%

- [x] `Event` and `EventRsvp` models with converters
- [x] `EventRepository` through `BaseRepository`
- [x] List filtered `startsAt >= now`, ascending, paginated
- [x] Infinite scroll, pull to refresh, empty and error states
- [x] RSVP creates one document per member per event, via a derived id so
      a second tap overwrites rather than duplicates
- [x] RSVP can be withdrawn
- [x] Rules allow a member only their own RSVP
- [x] Index for `startsAt` and for the event/member RSVP lookup
- [x] Unit tests for the RSVP id rule
- [ ] Event detail screen (the card carries everything for now)
- [ ] Reminder push the day before — `dailyReminders` exists in the
      functions but has not been read against this module or run

## 05 · Group classes & booking — 85%

- [x] `GroupClass`, `ClassSession`, `Booking` models and repositories
- [x] Video stored as `videoProvider` + `videoId`, embed URL built in app
- [x] Player embedded in-app via a web view, locked to the embed URL so a
      tap on a related video cannot turn it into a browser
- [x] Booking in a Firestore transaction: the session is read and its
      counter written atomically with the booking
- [x] Full session adds a waitlisted booking with a position
- [x] Cancelling frees the counter the member actually held, in a
      transaction
- [x] One booking per member per session, via a derived document id
- [x] Class list, class detail with the timetable, book and cancel
- [x] `onBookingCancelled` function exists (compiled only, unverified)
- [x] Rules: members book and cancel their own; promotion is privileged
- [x] Indexes for session/status/position and member/status/createdAt
- [x] Unit tests for capacity, the waitlist boundary and cancellation
- [ ] Promotion off the waitlist proven end to end — the client side is
      done, but `onBookingCancelled` has not been read or run
- [ ] Push to the promoted member (same function)
- [ ] Admin view listing bookings per session — module 08
- [ ] Emulator test of two members booking the last place at once

## 06 · Notifications — 75%

- [x] `sendAnnouncement` function fans out and mirrors to `announcements`
- [x] In-app notices list, paginated, so a dismissed push survives
- [x] Permission requested and token registered on sign-in
- [x] Token removed on sign-out, before the sign-out itself
- [x] Rotated tokens written back, so delivery does not quietly stop
- [x] Foreground messages shown as an in-app banner with a View action
- [x] Background handler registered as a top-level entry point
- [x] Tap routing from the payload, with an unknown type falling back to
      the notices list rather than doing nothing
- [x] A payload route that is not an in-app path is ignored
- [x] Unit tests for the routing table
- [ ] Invalid tokens pruned from `fcmTokens[]` on send failure — this is
      inside `sendAnnouncement`, which has not been read
- [ ] Android notification channel for heads-up delivery
- [ ] APNs key uploaded to Firebase, push capability enabled in Xcode
      (module 07, needs a Mac)

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
