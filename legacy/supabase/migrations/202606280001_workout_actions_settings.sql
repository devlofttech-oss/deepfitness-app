alter table public.users
  add column if not exists notifications_enabled boolean not null default true,
  add column if not exists preferred_unit text not null default 'kg';

alter table public.users
  drop constraint if exists users_preferred_unit_check;

alter table public.users
  add constraint users_preferred_unit_check
  check (preferred_unit in ('kg', 'lb'));

alter table public.exercise_logs
  add column if not exists completed boolean not null default true;

create table if not exists public.exercise_notes (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id) on delete cascade,
  workout_exercise_id uuid references public.workout_exercises(id) on delete cascade,
  exercise_id uuid not null references public.exercises(id) on delete restrict,
  note text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists exercise_notes_member_workout_exercise_idx
  on public.exercise_notes (member_id, workout_exercise_id, exercise_id)
  where workout_exercise_id is not null;

alter table public.exercise_notes enable row level security;

drop policy if exists "members manage own exercise notes" on public.exercise_notes;
create policy "members manage own exercise notes"
on public.exercise_notes for all
using (member_id = auth.uid())
with check (member_id = auth.uid());

drop policy if exists "trainers read assigned exercise notes" on public.exercise_notes;
create policy "trainers read assigned exercise notes"
on public.exercise_notes for select
using (public.is_member_trainer(member_id));
