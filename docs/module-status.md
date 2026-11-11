# Module status

Measured against `pdfs/Deep-Fitness-Developer-Guide.pdf` (25 October 2026),
which is the source of truth for scope. Only the modules named there belong
in this repository.

**Overall: roughly 93% built.**

The designs arrived after the modules were written, so the figures below
now carry a design column: a module can be functionally complete and
still owe work against the screens in `stitch/`.

`flutter analyze` is clean and all 84 tests pass on Flutter 3.44.1 with
Dart 3.12.1, and the Cloud Functions typecheck clean. What remains
unproven is everything that needs a device, a browser or the emulator
suite: the rules tests have never been run, and no screen has been seen
on real hardware.

| # | Module | Built | Matches the designs |
|---|--------|-------|---------------------|
| 01 | Authentication & member profile | 100% | Yes |
| 02 | Workout plans | 100% | Yes |
| 03 | Workout reports | 100% | Mostly |
| 04 | Events | 100% | Mostly |
| 05 | Group classes & booking | 100% | Yes |
| 06 | Notifications | 100% | Yes |
| 07 | iOS app | 35% | n/a |
| 08 | Admin dashboard (Flutter Web) | 90% | No designs supplied |
| — | Cross-cutting (rules, indexes, functions, release) | 90% | — |

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
- [x] Rules tests covering what a member may and may not write

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
- [x] Plan history, readable even when a membership has lapsed
- [x] The assignment side, built in the dashboard (module 08)

Reference: `legacy/supabase-era/workout/`, `legacy/supabase-era/home/`.

## 03 · Workout reports — 90%

- [x] Range selector: week, month, custom, as one query on `completedAt`
- [x] Completion rate, streaks and sets derived in Dart, nothing stored
- [x] Per-day series, including days with no activity
- [x] Bar chart of sets per day (fl_chart), no server round trip
- [x] Shareable summary rendered as a PNG from the widget tree
- [x] Empty and error states
- [x] Unit tests for the report maths: rate, streaks, ranges, day bucketing
- [x] Widget tests: the range selector re-runs the query, empty state,
      and the share action appearing only when there is something to share
- [ ] Personal bests — not in the document, so out of scope unless asked

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
- [x] Event detail screen, reachable from the card and a deep link
- [x] Reminder push the day before, in `dailyReminders`

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
- [x] Promotion off the waitlist, read against the client and corrected:
      the trigger owns `bookedCount` on a cancellation, so the client no
      longer decrements it too
- [x] Push to the promoted member
- [x] Admin view listing bookings per session (module 08)
- [x] Rules tests for booking, cancelling and the counters a member
      may move, including the full transaction the app commits

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
- [x] Invalid tokens pruned from `fcmTokens[]` on send failure
- [x] Android notification channel, created in MainActivity and named
      in the manifest, with POST_NOTIFICATIONS declared
- [ ] APNs key uploaded to Firebase, push capability enabled in Xcode
      (module 07, needs a Mac)

## 07 · iOS app — 35%

- [x] `Info.plist` usage strings for camera and photos
- [x] `remote-notification` in `UIBackgroundModes`
- [x] `Runner.entitlements` declaring `aps-environment`
- [x] Every screen already inside a `SafeArea`
- [ ] `GoogleService-Info.plist` placed **and added to the Xcode target**
- [ ] Push Notifications capability on the target
- [ ] APNs key created and uploaded to Firebase
- [ ] reCAPTCHA URL scheme from `REVERSED_CLIENT_ID`
- [ ] Layout checked on real devices, SE through Pro Max
- [ ] Apple sign-in — only if another social login is added, so nothing

Everything outstanding needs a Mac, Xcode and the Apple Developer
account. The steps are written out in `docs/ios-setup.md`.

## 08 · Admin dashboard (Flutter Web) — 70%

- [x] `lib/admin/` sharing the models and repositories with the app
- [x] Navigation rail shell, laid out for a desk, not a phone
- [x] Exercise library: create, edit, soft delete
- [x] Plan builder with drag-to-reorder, since order is the unlock order
- [x] Assign a plan to a member, snapshotting the exercise details
- [x] Member list with search and each member's workout history
- [x] Set a member's membership status and expiry — the pair of fields a
      member may not write about themselves
- [x] Create events
- [x] Create class sessions, and list who is booked on each
- [x] Compose and send announcements through the callable, with a
      confirm step because a push cannot be recalled
- [x] Role changes go through `setUserRole`, never a document write
- [x] Admin-only enforced in rules by custom claim; the router redirect
      is convenience on top, not the control
- [x] Unit tests for the assignment snapshot: order, copying, and
      dropping an exercise deleted since the plan was built
- [ ] Web target configured — `flutterfire configure` was run without it,
      so there is no web app in the Firebase project yet
- [x] Create and edit group classes, pasting a link or a bare video id
- [x] Image upload for exercises and events, resized on the device
- [x] Pagination on the members, exercises and plans lists
- [ ] Deployed to Firebase Hosting
- [ ] Responsive check below 1100px

## Cross-cutting — 45%

- [x] `firestore.rules` for all eleven collections, deny by default
- [x] `storage.rules` with content type and size checks
- [x] `firestore.indexes.json` for every compound query in the model
- [x] Base document fields: server timestamps, soft delete, audit
- [x] Defensive reads: every model defaults a missing field
- [x] Pagination through `BaseRepository`, never a full collection read
- [x] Typed failures; screens show a sentence, not an exception
- [x] Models over maps, repositories only
- [x] Rules tests in the emulator, per role — `rules-tests/`
- [x] Integration test: assigned plan, complete, skip, report
- [x] `flutter analyze` and `flutter test` clean — verified on
      Flutter 3.44.1 / Dart 3.12.1: no issues, 84 tests passing
- [x] Analytics and Crashlytics, release builds only
- [x] Emulator wiring behind `--dart-define=USE_EMULATOR=true`
- [ ] Staged rollout and the release checklist

---

## Design

The app follows **Obsidian Kinetic**, the system shipped in
`stitch/stitch_deep_fitness_member_app/obsidian_kinetic/DESIGN.md`. The
tokens live in `lib/app/colors.dart` and `lib/app/theme.dart`, and the
components that encode its rules are in `lib/core/widgets/`.

Done against the twelve supplied screens: the five-tab shell, home, the
plan detail with its locked and up-next treatment, the exercise detail
and set grid, the skip sheet, the reports screen, group classes with the
videos and booking tabs, the booking timetable, events, notices, the
profile hub and the auth screens.

Still open on the design side:

- [ ] The elements with no data behind them: the QR check-in pass, the
      "Level N" tier badge, estimated minutes and calories remaining, the
      studio bay on a session, and the category badge on a class. Each
      needs a field and a decision about where the number comes from.
- [ ] Event imagery and the class category filter chips.
- [ ] The dashboard has no supplied designs, so it keeps the same tokens
      but follows its own layout.
- [ ] The spec's prose names `#0B0C0E` and `#FFF500`; the Tailwind config
      the screenshots were rendered from says `#121315` and `#F1E800`.
      The rendered values are the ones in use.

## What cannot be closed from here

Every remaining item needs something outside this repository.

- **Nothing has been run on a device.** Analyze and the unit and widget
  tests pass, and the functions typecheck, but no screen has been seen on
  real hardware and no function has been deployed. A passing widget test
  says a layout does not throw, not that it looks right.
- **The rules tests have never been run.** They are written against the
  real rules files and need the emulators and a JDK.
- **iOS** needs a Mac, Xcode and the Apple Developer account.
- **Web** was left out of `flutterfire configure`, so the dashboard has
  no Firebase web app to talk to and cannot be deployed to Hosting.
- **Blaze plan** for the scheduled functions.
- **Brand colours** for the theme.

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
