alter table public.diet_plans
  add column if not exists scheduled_date date not null default current_date;

create index if not exists diet_plans_member_scheduled_date_idx
  on public.diet_plans (member_id, scheduled_date, created_at desc);

create index if not exists workout_days_scheduled_date_idx
  on public.workout_days (scheduled_date, created_at desc);
