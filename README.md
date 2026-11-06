# Deep Fitness

Premium Flutter gym management and fitness tracking app.

The technical specification is `guide/Deep-Fitness-Developer-Guide.pdf`. It is
the source of truth; `CHECKLIST.md` tracks the work against it.

## Current scope

The diet/nutrition member tab and trainer diet-assignment entry points are
temporarily hidden. The underlying diet data model and implementation files
remain in the codebase so the feature can be restored later.

## Backend

Firebase: Cloud Firestore, Firebase Authentication, Cloud Storage, Cloud
Functions (TypeScript) and Cloud Messaging. There is no custom API server — the
app reads and writes Firestore directly, and `firestore.rules` is the access
control. The app previously ran on Supabase; that schema is kept, unused, in
`legacy/supabase/` only until the live data has been moved across.

## Theming

The app is dark-only. `AppTheme.dark` is the single theme, `MaterialApp` pins
`themeMode` to dark so the OS appearance setting cannot flip it, and the Android
launch theme/background matches the `#121212` canvas. There is no light palette
and no dark-mode toggle in settings — colours should come from `AppColors`
rather than being hardcoded per screen.

## Firebase setup

1. Create two Firebase projects: `deepfitness-dev` and `deepfitness-prod`.
   Flavors select between them at build time; never point a debug build at
   production data.
2. Install the FlutterFire CLI and generate the options:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=deepfitness-dev
   ```

   This overwrites `lib/firebase_options.dart`, which is currently a
   dart-define-driven placeholder.
3. Place `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   in their platform folders. Neither is committed.
4. In `ios/Runner/Info.plist`, replace `REVERSED_CLIENT_ID` with the value of
   that key from `GoogleService-Info.plist` — phone sign-in's reCAPTCHA
   fallback returns through that URL scheme.
5. Enable Phone and Email/Password sign-in in the Firebase console. Upload the
   APNs key for iOS push and enable the push capability in Xcode.
6. Install and deploy the functions:

   ```bash
   cd functions && npm install && npm run build
   firebase deploy --only functions
   ```

7. Deploy rules and indexes. Deploy rules *before* any client that depends on
   them:

   ```bash
   firebase deploy --only firestore:rules,firestore:indexes,storage
   ```

8. Give the first admin their claim by calling `setUserRole` from an account
   that already has the `admin` claim, or by setting the claim once with the
   Admin SDK.
9. Scheduled functions require the Blaze plan. Set a budget alert on the
   project at setup.

### Flavors

Two Firebase projects, chosen at build time. Dev is the default, so forgetting
the flag is harmless:

```bash
flutter run --flavor dev --dart-define=FLAVOR=dev
```

```bash
flutter build appbundle --flavor prod --dart-define=FLAVOR=prod
```

A debug build pointed at prod throws on startup rather than writing test data
into the live gym's records. Pass `--dart-define=ALLOW_PROD_DEBUG=true` if you
genuinely need one. The dev build installs alongside prod with its own
application id and its own launcher name.

### Local development

```bash
firebase emulators:start
flutter run --dart-define=USE_EMULATOR=true
```

On the Android emulator the host is reachable at `10.0.2.2`, so add
`--dart-define=EMULATOR_HOST=10.0.2.2`.

### Running against a project without flutterfire configure

```bash
flutter run \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=deepfitness-dev \
  --dart-define=FIREBASE_STORAGE_BUCKET=deepfitness-dev.appspot.com
```

## Admin dashboard

The dashboard is the same Dart codebase built for web, sharing the models and
repositories with the app. It lives in `lib/admin/` and is served at `/admin`.

It is admin-only by custom claim. The route guard hides it, and
`firestore.rules` plus the `setUserRole` / `sendAnnouncement` callables enforce
it — hiding it in the UI alone would leave every query reachable with a token
and the SDK.

```bash
flutter build web --release
firebase deploy --only hosting
```

The first admin has to be made by hand: set the `role` claim to `admin` once
with the Admin SDK, after which `setUserRole` can promote anyone else from the
dashboard.

## Verification

```bash
flutter analyze
flutter test
```

```bash
cd functions && npm run build
```
