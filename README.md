# Deep Fitness

Premium Flutter gym management and fitness tracking app.

## Supabase setup

1. Create a Supabase project.
2. Open the Supabase SQL editor.
3. Run `supabase/schema.sql`.
4. Run the SQL in `supabase/migrations/202606120001_production_auth.sql`.
5. Deploy `supabase/functions/create-member` with `SUPABASE_SERVICE_ROLE_KEY` set as a function secret.
6. Create trainer accounts in Supabase Auth or another admin-only process with user metadata `{ "role": "trainer", "name": "Trainer Name" }`.

Members can create their own account from the app. Trainers use the separate trainer login screen.

Run the app with Supabase enabled:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Without those dart defines, the app uses the configured project in `SupabaseConfig`.

## Verification

```bash
flutter analyze
flutter test
```
