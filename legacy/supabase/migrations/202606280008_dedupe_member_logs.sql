with ranked_logs as (
  select
    id,
    row_number() over (
      partition by member_id, workout_exercise_id, set_number
      order by logged_at desc, id desc
    ) as row_number
  from public.exercise_logs
  where workout_exercise_id is not null
)
delete from public.exercise_logs logs
using ranked_logs ranked
where logs.id = ranked.id
  and ranked.row_number > 1;

create unique index if not exists exercise_logs_member_workout_set_unique_idx
  on public.exercise_logs (member_id, workout_exercise_id, set_number)
  where workout_exercise_id is not null;

with ranked_completions as (
  select
    id,
    row_number() over (
      partition by member_id, workout_plan_id, workout_day_id, completed_date
      order by completed_at desc, id desc
    ) as row_number
  from public.workout_completions
)
delete from public.workout_completions completions
using ranked_completions ranked
where completions.id = ranked.id
  and ranked.row_number > 1;

with ranked_diet_logs as (
  select
    id,
    row_number() over (
      partition by member_id, diet_meal_id, logged_date
      order by updated_at desc, id desc
    ) as row_number
  from public.diet_logs
)
delete from public.diet_logs logs
using ranked_diet_logs ranked
where logs.id = ranked.id
  and ranked.row_number > 1;
