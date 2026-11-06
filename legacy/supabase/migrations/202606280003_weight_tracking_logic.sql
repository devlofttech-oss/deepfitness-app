alter table public.exercises
  add column if not exists tracks_weight boolean not null default true;

alter table public.workout_exercises
  add column if not exists target_weight_kg numeric(7, 2) not null default 0;
