# Legacy Supabase backend

The app ran on Supabase before the migration to Firebase described in
`guide/Deep-Fitness-Developer-Guide.pdf`. Nothing in this folder is built,
deployed or referenced by the app any more.

It is kept for one reason: the live member data still sits in the Supabase
project, and this schema is what it has to be read out of. Delete the folder
once that data has been moved into Firestore and the Supabase project has been
shut down.

- `supabase/schema.sql` — the Postgres schema the live data uses
- `supabase/migrations/` — how that schema was reached
- `supabase/functions/create-member` — superseded by the `createMember`
  callable in `functions/src/members.ts`
- `supabase/seed_alex_demo.sql` — demo data
