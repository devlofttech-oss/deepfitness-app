alter table public.members
  add column if not exists gender text not null default 'male';

alter table public.members
  drop constraint if exists members_gender_check;

alter table public.members
  add constraint members_gender_check
  check (gender in ('male', 'female', 'other'));
