-- Extensions
create extension if not exists pgcrypto;

-- Profiles table mirrors auth.users and stores public fields
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique,
  created_at timestamptz not null default now()
);

-- Insert a profile row for every new auth user
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email) values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Todos table
create table if not exists public.todos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  completed boolean not null default false,
  inserted_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Keep updated_at fresh
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists todos_set_updated_at on public.todos;
create trigger todos_set_updated_at
  before update on public.todos
  for each row execute function public.set_updated_at();

-- Row Level Security
alter table public.profiles enable row level security;
alter table public.todos enable row level security;

-- Profiles policies: users can see and update their own profile
drop policy if exists profiles_self_select on public.profiles;
create policy profiles_self_select on public.profiles
  for select using (auth.uid() = id);

drop policy if exists profiles_self_update on public.profiles;
create policy profiles_self_update on public.profiles
  for update using (auth.uid() = id);

-- Todos policies: CRUD only own rows
drop policy if exists todos_select_own on public.todos;
create policy todos_select_own on public.todos
  for select using (auth.uid() = user_id);

drop policy if exists todos_insert_own on public.todos;
create policy todos_insert_own on public.todos
  for insert with check (auth.uid() = user_id);

drop policy if exists todos_update_own on public.todos;
create policy todos_update_own on public.todos
  for update using (auth.uid() = user_id);

drop policy if exists todos_delete_own on public.todos;
create policy todos_delete_own on public.todos
  for delete using (auth.uid() = user_id);

-- Realtime
-- Ensure Realtime is enabled on the schema/table via Supabase dashboard or CLI

