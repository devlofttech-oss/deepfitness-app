create extension if not exists "pgcrypto";

create type public.user_role as enum ('member', 'trainer');

create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  email text not null unique,
  notifications_enabled boolean not null default true,
  preferred_unit text not null default 'kg' check (preferred_unit in ('kg', 'lb')),
  role public.user_role not null,
  created_at timestamptz not null default now()
);

create table public.trainers (
  id uuid primary key references public.users(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now()
);

create table public.members (
  id uuid primary key references public.users(id) on delete cascade,
  trainer_id uuid references public.trainers(id) on delete restrict,
  goal text,
  age integer check (age between 1 and 120),
  height_cm numeric(5, 2),
  water_goal_liters numeric(4, 2) not null default 3.00,
  created_at timestamptz not null default now()
);

create table public.exercises (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  muscle_group text not null,
  default_sets integer not null default 3,
  default_reps text not null default '10-12',
  tracks_weight boolean not null default true,
  rest_seconds integer not null default 60,
  created_by uuid references public.trainers(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.workout_plans (
  id uuid primary key default gen_random_uuid(),
  trainer_id uuid not null references public.trainers(id) on delete cascade,
  member_id uuid not null references public.members(id) on delete cascade,
  name text not null,
  focus text,
  estimated_calories integer,
  level text,
  created_at timestamptz not null default now()
);

create table public.workout_days (
  id uuid primary key default gen_random_uuid(),
  workout_plan_id uuid not null references public.workout_plans(id) on delete cascade,
  scheduled_date date not null,
  title text not null,
  duration_minutes integer,
  created_at timestamptz not null default now()
);

create table public.workout_exercises (
  id uuid primary key default gen_random_uuid(),
  workout_day_id uuid not null references public.workout_days(id) on delete cascade,
  exercise_id uuid not null references public.exercises(id) on delete restrict,
  sort_order integer not null default 0,
  sets integer not null,
  reps text not null,
  target_weight_kg numeric(7, 2) not null default 0,
  rest_seconds integer not null default 60,
  trainer_notes text,
  created_at timestamptz not null default now()
);

create table public.exercise_logs (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id) on delete cascade,
  workout_exercise_id uuid references public.workout_exercises(id) on delete set null,
  exercise_id uuid not null references public.exercises(id) on delete restrict,
  set_number integer not null,
  weight numeric(7, 2) not null,
  reps integer not null,
  completed boolean not null default true,
  logged_at timestamptz not null default now()
);

create unique index exercise_logs_member_workout_set_unique_idx
  on public.exercise_logs (member_id, workout_exercise_id, set_number);

create table public.exercise_notes (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id) on delete cascade,
  workout_exercise_id uuid references public.workout_exercises(id) on delete cascade,
  exercise_id uuid not null references public.exercises(id) on delete restrict,
  note text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index exercise_notes_member_workout_exercise_idx
  on public.exercise_notes (member_id, workout_exercise_id, exercise_id)
  where workout_exercise_id is not null;

create table public.water_logs (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id) on delete cascade,
  logged_date date not null,
  liters numeric(4, 2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (member_id, logged_date)
);

create table public.diet_plans (
  id uuid primary key default gen_random_uuid(),
  trainer_id uuid not null references public.trainers(id) on delete cascade,
  member_id uuid not null references public.members(id) on delete cascade,
  name text not null,
  daily_calories integer not null,
  protein_g integer,
  carbs_g integer,
  fats_g integer,
  created_at timestamptz not null default now()
);

create table public.diet_meals (
  id uuid primary key default gen_random_uuid(),
  diet_plan_id uuid not null references public.diet_plans(id) on delete cascade,
  name text not null,
  meal_time time,
  description text,
  calories integer not null,
  sort_order integer not null default 0
);

create table public.measurements (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id) on delete cascade,
  trainer_id uuid references public.trainers(id) on delete set null,
  weight numeric(7, 2),
  body_fat numeric(5, 2),
  notes text,
  measured_at timestamptz not null default now()
);

create or replace function public.current_user_role()
returns public.user_role
language sql
stable
security definer
set search_path = public
as $$
  select role from public.users where id = auth.uid()
$$;

create or replace function public.is_member_self(member_uuid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth.uid() = member_uuid
$$;

create or replace function public.is_member_trainer(member_uuid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.members m
    where m.id = member_uuid
      and m.trainer_id = auth.uid()
  )
$$;

alter table public.users enable row level security;
alter table public.trainers enable row level security;
alter table public.members enable row level security;
alter table public.exercises enable row level security;
alter table public.workout_plans enable row level security;
alter table public.workout_days enable row level security;
alter table public.workout_exercises enable row level security;
alter table public.exercise_logs enable row level security;
alter table public.exercise_notes enable row level security;
alter table public.water_logs enable row level security;
alter table public.diet_plans enable row level security;
alter table public.diet_meals enable row level security;
alter table public.measurements enable row level security;

create policy "users read own profile"
on public.users for select
using (id = auth.uid());

create policy "trainers read own row"
on public.trainers for select
using (id = auth.uid());

create policy "members read own or trainer assigned"
on public.members for select
using (public.is_member_self(id) or public.is_member_trainer(id));

create policy "trainers update assigned member profile"
on public.members for update
using (public.is_member_trainer(id))
with check (public.is_member_trainer(id));

create policy "authenticated read exercises"
on public.exercises for select
to authenticated
using (true);

create policy "trainers manage exercises"
on public.exercises for all
using (public.current_user_role() = 'trainer')
with check (public.current_user_role() = 'trainer');

create policy "members and trainers read assigned workout plans"
on public.workout_plans for select
using (public.is_member_self(member_id) or trainer_id = auth.uid());

create policy "trainers manage assigned workout plans"
on public.workout_plans for all
using (trainer_id = auth.uid())
with check (trainer_id = auth.uid());

create policy "read assigned workout days"
on public.workout_days for select
using (
  exists (
    select 1 from public.workout_plans wp
    where wp.id = workout_plan_id
      and (public.is_member_self(wp.member_id) or wp.trainer_id = auth.uid())
  )
);

create policy "trainers manage workout days"
on public.workout_days for all
using (
  exists (
    select 1 from public.workout_plans wp
    where wp.id = workout_plan_id and wp.trainer_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.workout_plans wp
    where wp.id = workout_plan_id and wp.trainer_id = auth.uid()
  )
);

create policy "read assigned workout exercises"
on public.workout_exercises for select
using (
  exists (
    select 1
    from public.workout_days wd
    join public.workout_plans wp on wp.id = wd.workout_plan_id
    where wd.id = workout_day_id
      and (public.is_member_self(wp.member_id) or wp.trainer_id = auth.uid())
  )
);

create policy "trainers manage workout exercises"
on public.workout_exercises for all
using (
  exists (
    select 1
    from public.workout_days wd
    join public.workout_plans wp on wp.id = wd.workout_plan_id
    where wd.id = workout_day_id and wp.trainer_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.workout_days wd
    join public.workout_plans wp on wp.id = wd.workout_plan_id
    where wd.id = workout_day_id and wp.trainer_id = auth.uid()
  )
);

create policy "members insert own exercise logs"
on public.exercise_logs for insert
with check (member_id = auth.uid());

create policy "members read own logs and trainers read assigned logs"
on public.exercise_logs for select
using (public.is_member_self(member_id) or public.is_member_trainer(member_id));

create policy "members update own logs"
on public.exercise_logs for update
using (member_id = auth.uid())
with check (member_id = auth.uid());

create policy "members manage own exercise notes"
on public.exercise_notes for all
using (member_id = auth.uid())
with check (member_id = auth.uid());

create policy "trainers read assigned exercise notes"
on public.exercise_notes for select
using (public.is_member_trainer(member_id));

create policy "members manage own water logs"
on public.water_logs for all
using (member_id = auth.uid())
with check (member_id = auth.uid());

create policy "trainers read assigned water logs"
on public.water_logs for select
using (public.is_member_trainer(member_id));

create policy "read assigned diet plans"
on public.diet_plans for select
using (public.is_member_self(member_id) or trainer_id = auth.uid());

create policy "trainers manage assigned diet plans"
on public.diet_plans for all
using (trainer_id = auth.uid())
with check (trainer_id = auth.uid());

create policy "read assigned diet meals"
on public.diet_meals for select
using (
  exists (
    select 1 from public.diet_plans dp
    where dp.id = diet_plan_id
      and (public.is_member_self(dp.member_id) or dp.trainer_id = auth.uid())
  )
);

create policy "trainers manage diet meals"
on public.diet_meals for all
using (
  exists (
    select 1 from public.diet_plans dp
    where dp.id = diet_plan_id and dp.trainer_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.diet_plans dp
    where dp.id = diet_plan_id and dp.trainer_id = auth.uid()
  )
);

create policy "read assigned measurements"
on public.measurements for select
using (public.is_member_self(member_id) or public.is_member_trainer(member_id));

create policy "trainers insert assigned measurements"
on public.measurements for insert
with check (public.is_member_trainer(member_id));

create policy "trainers update assigned measurements"
on public.measurements for update
using (public.is_member_trainer(member_id))
with check (public.is_member_trainer(member_id));
