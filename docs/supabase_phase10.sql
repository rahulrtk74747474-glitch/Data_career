-- Optional DataQuest v1.0 cloud continuity schema.
-- Run this in a Supabase project only if cloud save/leaderboard are desired.

create table if not exists public.dataquest_saves (
  user_id uuid primary key references auth.users(id) on delete cascade,
  payload jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.dataquest_saves enable row level security;

create policy "users read own DataQuest save"
on public.dataquest_saves for select
to authenticated
using (auth.uid() = user_id);

create policy "users insert own DataQuest save"
on public.dataquest_saves for insert
to authenticated
with check (auth.uid() = user_id);

create policy "users update own DataQuest save"
on public.dataquest_saves for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create table if not exists public.dataquest_leaderboard (
  user_id uuid primary key references auth.users(id) on delete cascade,
  alias text not null check (alias ~ '^[A-Za-z0-9_]{3,20}$'),
  readiness_score integer not null check (readiness_score between 0 and 100),
  graduated boolean not null default false,
  updated_at timestamptz not null default now()
);

alter table public.dataquest_leaderboard enable row level security;

create policy "authenticated users read alias leaderboard"
on public.dataquest_leaderboard for select
to authenticated
using (true);

create policy "users insert own leaderboard row"
on public.dataquest_leaderboard for insert
to authenticated
with check (auth.uid() = user_id);

create policy "users update own leaderboard row"
on public.dataquest_leaderboard for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
