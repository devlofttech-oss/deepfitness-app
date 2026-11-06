with mappings as (
  select *
  from (values
    ('seed-barbell-squat', 'free-exercise-db:Barbell_Squat'),
    ('seed-seated-cable-row', 'free-exercise-db:Seated_Cable_Rows'),
    ('seed-skipping-rope', 'free-exercise-db:Rope_Jumping')
  ) as mapped(seed_source_id, free_source_id)
),
resolved as (
  select seed.id as seed_exercise_id, free.id as free_exercise_id
  from mappings
  join public.exercises seed on seed.source_id = mappings.seed_source_id
  join public.exercises free on free.source_id = mappings.free_source_id
)
update public.workout_exercises workout_exercise
set exercise_id = resolved.free_exercise_id
from resolved
where workout_exercise.exercise_id = resolved.seed_exercise_id;

with mappings as (
  select *
  from (values
    ('seed-barbell-squat', 'free-exercise-db:Barbell_Squat'),
    ('seed-seated-cable-row', 'free-exercise-db:Seated_Cable_Rows'),
    ('seed-skipping-rope', 'free-exercise-db:Rope_Jumping')
  ) as mapped(seed_source_id, free_source_id)
),
resolved as (
  select seed.id as seed_exercise_id, free.id as free_exercise_id
  from mappings
  join public.exercises seed on seed.source_id = mappings.seed_source_id
  join public.exercises free on free.source_id = mappings.free_source_id
)
update public.exercise_logs exercise_log
set exercise_id = resolved.free_exercise_id
from resolved
where exercise_log.exercise_id = resolved.seed_exercise_id;

with mappings as (
  select *
  from (values
    ('seed-barbell-squat', 'free-exercise-db:Barbell_Squat'),
    ('seed-seated-cable-row', 'free-exercise-db:Seated_Cable_Rows'),
    ('seed-skipping-rope', 'free-exercise-db:Rope_Jumping')
  ) as mapped(seed_source_id, free_source_id)
),
resolved as (
  select seed.id as seed_exercise_id, free.id as free_exercise_id
  from mappings
  join public.exercises seed on seed.source_id = mappings.seed_source_id
  join public.exercises free on free.source_id = mappings.free_source_id
)
update public.exercise_notes exercise_note
set exercise_id = resolved.free_exercise_id
from resolved
where exercise_note.exercise_id = resolved.seed_exercise_id;

delete from public.exercises
where source_id in (
  'seed-barbell-squat',
  'seed-seated-cable-row',
  'seed-skipping-rope'
);
