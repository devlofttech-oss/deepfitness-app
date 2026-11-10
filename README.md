# Deep Fitness

Flutter gym app for members, with Firebase as the backend. Android, iOS and a
Flutter Web dashboard for staff, from one codebase.

The source of truth for scope is `pdfs/Deep-Fitness-Developer-Guide.pdf`.
Only the modules it names belong in this repository.

## Architecture

There is no custom API server. The app reads and writes Firestore directly and
the security rules are the access control; a small set of Cloud Functions
covers the work a client cannot be trusted to do.

```
lib/
  main.dart          # bootstrap, Firebase init, theme, router
  app/               # router.dart, theme.dart, colors.dart
  core/
    models/          # shared models with Firestore converters
    repositories/    # base repository, pagination, typed failures
    services/        # auth, messaging
    widgets/         # shared buttons, cards, empty and error states
  features/          # auth, home, splash
  admin/             # Flutter Web dashboard (module 08)
functions/           # Cloud Functions
firestore.rules      # the access control
storage.rules
firestore.indexes.json
legacy/              # Supabase-era screens, kept as reference only
```

Every write goes through a repository, so model mapping and validation sit in
one place. Widgets never touch `FirebaseFirestore.instance`.

## Module status

| # | Module | State |
|---|--------|-------|
| 01 | Authentication & member profile | Built |
| 02 | Workout plans | Not started |
| 03 | Workout reports | Not started |
| 04 | Events | Not started |
| 05 | Group classes & booking | Not started |
| 06 | Notifications | Functions only; no app surface |
| 07 | iOS platform setup | Not started |
| 08 | Admin dashboard | Not started |

`legacy/` holds the screens from the previous Supabase build. They are
excluded from analysis and are reference material for the modules above, not
shipping code.

## Setup

1. Install the Flutter SDK and run `flutter doctor` until it is clean.
2. `flutter pub get`
3. Install the FlutterFire CLI and run `flutterfire configure` to generate
   `lib/firebase_options.dart`.
4. Place `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   in their platform folders.
5. `firebase emulators:start` for local work.
6. Deploy rules with `firebase deploy --only firestore:rules,storage`.

## Verification

```bash
flutter analyze
flutter test
```
