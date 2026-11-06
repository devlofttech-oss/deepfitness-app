alter table public.exercises
  add column if not exists source_id text,
  add column if not exists equipment text,
  add column if not exists level text,
  add column if not exists category text,
  add column if not exists force text,
  add column if not exists mechanic text,
  add column if not exists primary_muscles text[] not null default '{}',
  add column if not exists secondary_muscles text[] not null default '{}',
  add column if not exists instructions text[] not null default '{}',
  add column if not exists image_urls text[] not null default '{}',
  add column if not exists source_name text,
  add column if not exists source_license text,
  add column if not exists imported_at timestamptz;

create unique index if not exists exercises_source_id_unique_idx
  on public.exercises (source_id)
  where source_id is not null;
