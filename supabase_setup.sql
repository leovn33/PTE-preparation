-- PTE Compass: run this once in Supabase's SQL Editor (Project > SQL Editor > New query)
-- Creates the profiles table plus three RPC functions the app calls.
-- The table itself has Row Level Security enabled with NO policies, so it is
-- completely unreachable via the public REST API or the anon key directly —
-- the only way in is through these three SECURITY DEFINER functions, which
-- check the PIN (or, for save/read, the unguessable profile id) themselves.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  pin_hash text not null,
  state jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists profiles_name_key on public.profiles (lower(name));

alter table public.profiles enable row level security;

-- Look up (or create) a profile by name+PIN.
-- Returns one row: id (null if the name exists but the PIN doesn't match), state, is_new.
create or replace function public.login_profile(p_name text, p_pin text)
returns table(id uuid, state jsonb, is_new boolean)
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.profiles;
begin
  select * into r from public.profiles where lower(profiles.name) = lower(p_name);

  if not found then
    insert into public.profiles(name, pin_hash, state)
    values (p_name, crypt(p_pin, gen_salt('bf')), '{}'::jsonb)
    returning * into r;
    return query select r.id, r.state, true;
    return;
  end if;

  if r.pin_hash = crypt(p_pin, r.pin_hash) then
    return query select r.id, r.state, false;
  else
    return query select null::uuid, null::jsonb, false;
  end if;
end;
$$;

-- Fetch the saved state for a profile id (returns null if the id doesn't exist).
create or replace function public.get_state(p_id uuid)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select state from public.profiles where id = p_id;
$$;

-- Overwrite the saved state for a profile id. Returns true if a row was updated.
create or replace function public.save_state(p_id uuid, p_state jsonb)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
begin
  update public.profiles set state = p_state, updated_at = now() where id = p_id;
  get diagnostics v_count = row_count;
  return v_count > 0;
end;
$$;

grant execute on function public.login_profile(text, text) to anon;
grant execute on function public.get_state(uuid) to anon;
grant execute on function public.save_state(uuid, jsonb) to anon;
