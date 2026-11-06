create unique index if not exists exercise_logs_member_workout_set_unique_idx
  on public.exercise_logs (member_id, workout_exercise_id, set_number);

update public.exercises
set image_urls = case source_id
  when 'seed-barbell-squat' then array[
    'https://placehold.co/900x600/f6c90e/111111.png?text=Barbell+Back+Squat',
    'https://placehold.co/900x600/111111/f6c90e.png?text=Squat+Form'
  ]
  when 'seed-seated-cable-row' then array[
    'https://placehold.co/900x600/f6c90e/111111.png?text=Seated+Cable+Row',
    'https://placehold.co/900x600/111111/f6c90e.png?text=Cable+Row+Form'
  ]
  when 'seed-skipping-rope' then array[
    'https://placehold.co/900x600/f6c90e/111111.png?text=Skipping+Rope',
    'https://placehold.co/900x600/111111/f6c90e.png?text=Cardio+Rhythm'
  ]
  else image_urls
end
where source_id in (
  'seed-barbell-squat',
  'seed-seated-cable-row',
  'seed-skipping-rope'
);
