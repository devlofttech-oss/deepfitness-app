create table if not exists public.workout_completions (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id) on delete cascade,
  workout_plan_id uuid not null references public.workout_plans(id) on delete cascade,
  workout_day_id uuid references public.workout_days(id) on delete cascade,
  completed_date date not null default current_date,
  completed_at timestamptz not null default now(),
  unique (member_id, workout_plan_id, workout_day_id, completed_date)
);

create table if not exists public.diet_logs (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id) on delete cascade,
  diet_plan_id uuid not null references public.diet_plans(id) on delete cascade,
  diet_meal_id uuid not null references public.diet_meals(id) on delete cascade,
  logged_date date not null default current_date,
  consumed boolean not null default true,
  consumed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (member_id, diet_meal_id, logged_date)
);

alter table public.workout_completions enable row level security;
alter table public.diet_logs enable row level security;

create policy "members manage own workout completions"
on public.workout_completions for all
using (member_id = auth.uid())
with check (member_id = auth.uid());

create policy "trainers read assigned workout completions"
on public.workout_completions for select
using (public.is_member_trainer(member_id));

create policy "members manage own diet logs"
on public.diet_logs for all
using (member_id = auth.uid())
with check (member_id = auth.uid());

create policy "trainers read assigned diet logs"
on public.diet_logs for select
using (public.is_member_trainer(member_id));

with completed_workouts as (
  select
    wp.member_id,
    wp.id as workout_plan_id,
    wd.id as workout_day_id,
    current_date as completed_date,
    max(el.logged_at) as completed_at
  from public.workout_plans wp
  join public.workout_days wd on wd.workout_plan_id = wp.id
  join public.workout_exercises wx on wx.workout_day_id = wd.id
  left join public.exercise_logs el
    on el.member_id = wp.member_id
    and el.workout_exercise_id = wx.id
    and el.completed = true
  group by wp.member_id, wp.id, wd.id
  having count(el.id) >= sum(wx.sets)
)
insert into public.workout_completions (
  member_id,
  workout_plan_id,
  workout_day_id,
  completed_date,
  completed_at
)
select
  member_id,
  workout_plan_id,
  workout_day_id,
  completed_date,
  coalesce(completed_at, now())
from completed_workouts
on conflict (member_id, workout_plan_id, workout_day_id, completed_date)
do update set completed_at = excluded.completed_at;
