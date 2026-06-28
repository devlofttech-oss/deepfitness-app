begin;

create extension if not exists "pgcrypto";

do $$
declare
  trainer_uuid uuid := '67e34f20-5596-47d7-a2ab-737818058fc6';
  alex_uuid uuid := '0b086674-8b2e-41e9-87b2-3ca30ba54d32';
  old_member_uuid uuid := '8b2b17cd-bf19-4465-a43d-7a9e51eadf58';
  workout_plan_uuid uuid := gen_random_uuid();
  workout_day_uuid uuid := gen_random_uuid();
  diet_plan_uuid uuid := gen_random_uuid();
  squat_uuid uuid := gen_random_uuid();
  row_uuid uuid := gen_random_uuid();
  skipping_uuid uuid := gen_random_uuid();
begin
  delete from auth.identities where user_id = old_member_uuid;
  delete from auth.users where id = old_member_uuid;

  update auth.users
  set
    email = 'trainer@deepfitness.app',
    phone = null,
    encrypted_password = crypt('DeepFit@123', gen_salt('bf')),
    email_confirmed_at = coalesce(email_confirmed_at, now()),
    raw_user_meta_data = jsonb_build_object('name', 'Coach Maya', 'role', 'trainer'),
    updated_at = now()
  where id = trainer_uuid;

  update auth.identities
  set
    identity_data = jsonb_build_object(
      'sub', trainer_uuid::text,
      'email', 'trainer@deepfitness.app',
      'email_verified', true,
      'phone_verified', false
    ),
    updated_at = now()
  where user_id = trainer_uuid and provider = 'email';

  update auth.users
  set
    email = 'alex@deepfitness.app',
    phone = null,
    encrypted_password = crypt('DeepFit@123', gen_salt('bf')),
    email_confirmed_at = coalesce(email_confirmed_at, now()),
    raw_user_meta_data = jsonb_build_object(
      'name', 'Alex',
      'role', 'member',
      'trainer_id', trainer_uuid::text,
      'goal', 'Build strength and improve conditioning',
      'age', 28,
      'height_cm', 178
    ),
    updated_at = now()
  where id = alex_uuid;

  update auth.identities
  set
    identity_data = jsonb_build_object(
      'sub', alex_uuid::text,
      'email', 'alex@deepfitness.app',
      'email_verified', true,
      'phone_verified', false
    ),
    updated_at = now()
  where user_id = alex_uuid and provider = 'email';

  delete from public.exercise_notes;
  delete from public.exercise_logs;
  delete from public.water_logs;
  delete from public.measurements;
  delete from public.diet_plans;
  delete from public.workout_plans;
  delete from public.exercises;
  delete from public.members where id <> alex_uuid;

  insert into public.users (id, name, email, phone, role)
  values
    (trainer_uuid, 'Coach Maya', 'trainer@deepfitness.app', null, 'trainer'),
    (alex_uuid, 'Alex', 'alex@deepfitness.app', null, 'member')
  on conflict (id) do update set
    name = excluded.name,
    email = excluded.email,
    phone = excluded.phone,
    role = excluded.role;

  insert into public.trainers (id, name)
  values (trainer_uuid, 'Coach Maya')
  on conflict (id) do update set name = excluded.name;

  insert into public.members (id, trainer_id, goal, age, height_cm, water_goal_liters)
  values (
    alex_uuid,
    trainer_uuid,
    'Build strength and improve conditioning',
    28,
    178,
    3.00
  )
  on conflict (id) do update set
    trainer_id = excluded.trainer_id,
    goal = excluded.goal,
    age = excluded.age,
    height_cm = excluded.height_cm,
    water_goal_liters = excluded.water_goal_liters;

  insert into public.measurements (member_id, trainer_id, weight, notes)
  values (alex_uuid, trainer_uuid, 76.5, 'Starting measurement for Alex');

  insert into public.exercises (
    id,
    source_id,
    name,
    description,
    muscle_group,
    default_sets,
    default_reps,
    tracks_weight,
    rest_seconds,
    equipment,
    level,
    category,
    instructions,
    image_urls
  )
  values
    (
      squat_uuid,
      'seed-barbell-squat',
      'Barbell Back Squat',
      'Compound lower-body strength exercise using a barbell.',
      'Legs',
      3,
      '10',
      true,
      90,
      'Barbell',
      'Intermediate',
      'Strength',
      array[
        'Set the bar across your upper back and brace your core.',
        'Squat until thighs are near parallel, then drive through your heels.'
      ],
      array[
        'https://iqhrhxxvhtokqltqkqoz.supabase.co/storage/v1/object/public/exercise-images/free-exercise-db/exercises/Barbell_Squat/0.jpg',
        'https://iqhrhxxvhtokqltqkqoz.supabase.co/storage/v1/object/public/exercise-images/free-exercise-db/exercises/Barbell_Squat/1.jpg'
      ]
    ),
    (
      row_uuid,
      'seed-seated-cable-row',
      'Seated Cable Row',
      'Weighted pulling exercise for back and posture.',
      'Back',
      3,
      '12',
      true,
      75,
      'Cable',
      'Beginner',
      'Strength',
      array[
        'Sit tall with a neutral spine.',
        'Pull the handle toward your torso and squeeze your shoulder blades.'
      ],
      array[
        'https://iqhrhxxvhtokqltqkqoz.supabase.co/storage/v1/object/public/exercise-images/free-exercise-db/exercises/Seated_Cable_Rows/0.jpg',
        'https://iqhrhxxvhtokqltqkqoz.supabase.co/storage/v1/object/public/exercise-images/free-exercise-db/exercises/Seated_Cable_Rows/1.jpg'
      ]
    ),
    (
      skipping_uuid,
      'seed-skipping-rope',
      'Skipping Rope',
      'Conditioning exercise that tracks reps or time, not external weight.',
      'Cardio',
      3,
      '60',
      false,
      45,
      'Jump Rope',
      'Beginner',
      'Cardio',
      array[
        'Keep elbows close and rotate the rope with your wrists.',
        'Land softly and keep a steady rhythm.'
      ],
      array[
        'https://iqhrhxxvhtokqltqkqoz.supabase.co/storage/v1/object/public/exercise-images/free-exercise-db/exercises/Rope_Jumping/0.jpg',
        'https://iqhrhxxvhtokqltqkqoz.supabase.co/storage/v1/object/public/exercise-images/free-exercise-db/exercises/Rope_Jumping/1.jpg'
      ]
    );

  insert into public.workout_plans (
    id,
    trainer_id,
    member_id,
    name,
    focus,
    estimated_calories,
    level
  )
  values (
    workout_plan_uuid,
    trainer_uuid,
    alex_uuid,
    'Alex Strength & Conditioning',
    'Lower-body strength, back strength, and cardio conditioning',
    420,
    'Intermediate'
  );

  insert into public.workout_days (
    id,
    workout_plan_id,
    scheduled_date,
    title,
    duration_minutes
  )
  values (
    workout_day_uuid,
    workout_plan_uuid,
    current_date,
    'Strength & Conditioning Day',
    48
  );

  insert into public.workout_exercises (
    workout_day_id,
    exercise_id,
    sort_order,
    sets,
    reps,
    target_weight_kg,
    rest_seconds,
    trainer_notes
  )
  values
    (
      workout_day_uuid,
      squat_uuid,
      1,
      3,
      '10',
      60,
      90,
      'Keep the reps controlled. Stop if form breaks.'
    ),
    (
      workout_day_uuid,
      row_uuid,
      2,
      3,
      '12',
      35,
      75,
      'Pause briefly at the torso on every rep.'
    ),
    (
      workout_day_uuid,
      skipping_uuid,
      3,
      3,
      '60',
      0,
      45,
      'This exercise does not use external weight.'
    );

  insert into public.diet_plans (
    id,
    trainer_id,
    member_id,
    name,
    daily_calories,
    protein_g,
    carbs_g,
    fats_g
  )
  values (
    diet_plan_uuid,
    trainer_uuid,
    alex_uuid,
    'Alex Balanced Strength Diet',
    2300,
    145,
    260,
    70
  );

  insert into public.diet_meals (
    diet_plan_id,
    name,
    meal_time,
    description,
    calories,
    sort_order
  )
  values
    (
      diet_plan_uuid,
      'Breakfast',
      '08:00',
      'Oats, banana, milk, and two boiled eggs.',
      520,
      1
    ),
    (
      diet_plan_uuid,
      'Lunch',
      '13:00',
      'Rice, grilled chicken, dal, and mixed vegetables.',
      780,
      2
    ),
    (
      diet_plan_uuid,
      'Evening Snack',
      '17:00',
      'Greek yogurt, fruit, and a handful of nuts.',
      360,
      3
    ),
    (
      diet_plan_uuid,
      'Dinner',
      '20:30',
      'Paneer or fish, roti, salad, and curd.',
      640,
      4
    );
end $$;

commit;
