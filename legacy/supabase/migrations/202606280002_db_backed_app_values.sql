alter table public.members
  add column if not exists age integer,
  add column if not exists water_goal_liters numeric(4, 2) not null default 3.00;

alter table public.members
  drop constraint if exists members_age_check;

alter table public.members
  add constraint members_age_check
  check (age is null or age between 1 and 120);

alter table public.workout_plans
  add column if not exists estimated_calories integer,
  add column if not exists level text;

alter table public.exercises
  add column if not exists default_sets integer not null default 3,
  add column if not exists default_reps text not null default '10-12';

create table if not exists public.water_logs (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id) on delete cascade,
  logged_date date not null,
  liters numeric(4, 2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (member_id, logged_date)
);

alter table public.water_logs enable row level security;

drop policy if exists "members manage own water logs" on public.water_logs;
create policy "members manage own water logs"
on public.water_logs for all
using (member_id = auth.uid())
with check (member_id = auth.uid());

drop policy if exists "trainers read assigned water logs" on public.water_logs;
create policy "trainers read assigned water logs"
on public.water_logs for select
using (public.is_member_trainer(member_id));
