alter table public.users
  add column if not exists phone text unique,
  add column if not exists avatar_url text;

alter table public.users
  alter column email drop not null;

alter table public.members
  alter column trainer_id drop not null;

create unique index if not exists users_email_unique_idx
  on public.users (email)
  where email is not null;

create unique index if not exists exercise_logs_member_workout_set_idx
  on public.exercise_logs (member_id, workout_exercise_id, set_number)
  where workout_exercise_id is not null;

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  profile_name text;
  profile_role public.user_role;
  trainer_uuid uuid;
begin
  profile_name := coalesce(
    nullif(new.raw_user_meta_data ->> 'name', ''),
    split_part(coalesce(new.email, new.phone, 'Deep Fitness User'), '@', 1)
  );
  profile_role := coalesce(
    nullif(new.raw_user_meta_data ->> 'role', '')::public.user_role,
    'member'::public.user_role
  );

  insert into public.users (id, name, email, phone, role)
  values (new.id, profile_name, new.email, new.phone, profile_role)
  on conflict (id) do update set
    name = excluded.name,
    email = excluded.email,
    phone = excluded.phone,
    role = excluded.role;

  if profile_role = 'trainer' then
    insert into public.trainers (id, name)
    values (new.id, profile_name)
    on conflict (id) do update set name = excluded.name;
  else
    trainer_uuid := nullif(new.raw_user_meta_data ->> 'trainer_id', '')::uuid;
    insert into public.members (id, trainer_id, goal, height_cm)
    values (
      new.id,
      trainer_uuid,
      new.raw_user_meta_data ->> 'goal',
      nullif(new.raw_user_meta_data ->> 'height_cm', '')::numeric
    )
    on conflict (id) do update set
      trainer_id = excluded.trainer_id,
      goal = excluded.goal,
      height_cm = excluded.height_cm;
  end if;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_deepfitness on auth.users;

create trigger on_auth_user_created_deepfitness
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

drop policy if exists "trainers read assigned user profiles" on public.users;
create policy "trainers read assigned user profiles"
on public.users for select
using (
  id = auth.uid()
  or exists (
    select 1 from public.members m
    where m.id = users.id
      and m.trainer_id = auth.uid()
  )
);

drop policy if exists "users update own avatar" on public.users;
create policy "users update own avatar"
on public.users for update
using (id = auth.uid())
with check (id = auth.uid());
