-- Sum Sprint v2 – Initial Database Schema
-- Run this in the Supabase SQL Editor (https://app.supabase.com → SQL Editor)

-- ============================================
-- 1. Profiles table (extends auth.users)
-- ============================================
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  nickname text not null default 'Player',
  telegram_username text default null,
  points int default 500,
  login_code text default '1234',
  created_at timestamp with time zone default now()
);

-- Add telegram_username column if migrating from a schema without it.
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_name = 'profiles' and column_name = 'telegram_username'
  ) then
    alter table public.profiles add column telegram_username text default null;
  end if;
end $$;

-- Auto-create a profile row when a new user signs up.
-- The handle_new_user trigger fires on INSERT into auth.users.
-- Uses `on conflict do nothing` so it's safe to re-run.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, nickname, points, login_code)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'nickname', 'Player'), 500, '1234')
  on conflict (id) do nothing;
  return new;
end;
$$;

-- Drop trigger if exists, then create
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Note: User creation is handled by the Flutter app via Supabase SDK
-- (signUp / signInWithPassword). No raw auth table inserts — the SDK
-- handles identities, confirmations, and sessions properly.

-- ============================================
-- 2. Competitions table
-- ============================================
create table if not exists public.competitions (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text default '',
  start_date timestamptz not null,
  end_date timestamptz not null,
  challenges jsonb not null,
  entry_points int not null default 100,
  prize_pool int not null default 0,
  winner_count int not null default 3,
  winner_shares jsonb not null default '[50, 30, 20]',
  status text default 'upcoming' check (status in ('upcoming', 'active', 'finished')),
  created_at timestamptz default now()
);

-- ============================================
-- 4. Participants (users who joined a competition)
-- ============================================
create table if not exists public.participants (
  competition_id uuid references public.competitions on delete cascade,
  user_id uuid references public.profiles on delete cascade,
  total_score int default 0,
  completed_challenges int default 0,
  joined_at timestamptz default now(),
  primary key (competition_id, user_id)
);

-- ============================================
-- 5. Challenge results (individual challenge outcomes)
-- ============================================
create table if not exists public.challenge_results (
  id bigint generated always as identity primary key,
  competition_id uuid references public.competitions on delete cascade,
  user_id uuid references public.profiles on delete cascade,
  challenge_id text not null,
  score int not null,
  correct_count int not null,
  total_time_ms int not null,
  created_at timestamptz default now()
);

-- ============================================
-- 6. Indexes for performance
-- ============================================
create index if not exists idx_participants_competition
  on public.participants (competition_id);
create index if not exists idx_participants_score
  on public.participants (competition_id, total_score desc);
create index if not exists idx_challenge_results_competition
  on public.challenge_results (competition_id, user_id);

-- ============================================
-- 7. Row Level Security (RLS)
-- ============================================
alter table public.profiles enable row level security;
alter table public.competitions enable row level security;
alter table public.participants enable row level security;
alter table public.challenge_results enable row level security;

-- Profiles: users can read all profiles (for leaderboard nicknames),
-- but can only update/insert their own.
drop policy if exists "Users can read all profiles" on public.profiles;
create policy "Users can read all profiles"
  on public.profiles for select using (true);
drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
  on public.profiles for update using (auth.uid() = id);
drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
  on public.profiles for insert with check (auth.uid() = id);

-- Competitions: readable by anyone (authenticated).
drop policy if exists "Anyone can read competitions" on public.competitions;
create policy "Anyone can read competitions"
  on public.competitions for select using (true);

-- Participants: readable by anyone, insert/update only for own user.
drop policy if exists "Users can read participants" on public.participants;
create policy "Users can read participants"
  on public.participants for select using (true);
drop policy if exists "Users can insert own participation" on public.participants;
create policy "Users can insert own participation"
  on public.participants for insert with check (auth.uid() = user_id);
drop policy if exists "Users can update own participation" on public.participants;
create policy "Users can update own participation"
  on public.participants for update using (auth.uid() = user_id);

-- Challenge results: readable by anyone, insert only for own user.
drop policy if exists "Users can insert own challenge results" on public.challenge_results;
create policy "Users can insert own challenge results"
  on public.challenge_results for insert with check (auth.uid() = user_id);
drop policy if exists "Users can read all challenge results" on public.challenge_results;
create policy "Users can read all challenge results"
  on public.challenge_results for select using (true);

-- ============================================
-- 8. RPC Functions (called by the Flutter app)
-- ============================================

-- Join a competition: deduct points and insert participant row atomically.
create or replace function public.join_competition(
  p_competition_id uuid,
  p_user_id uuid,
  p_entry_points int
) returns void as $$
begin
  -- Check user has enough points
  if (select points from public.profiles where id = p_user_id) < p_entry_points then
    raise exception 'Insufficient points to join this competition.';
  end if;

  -- Check competition is joinable
  if (select status from public.competitions where id = p_competition_id) = 'finished' then
    raise exception 'This competition has already ended.';
  end if;

  -- Check not already joined
  if exists (
    select 1 from public.participants
    where competition_id = p_competition_id and user_id = p_user_id
  ) then
    raise exception 'Already joined this competition.';
  end if;

  -- Deduct points from user
  update public.profiles
  set points = points - p_entry_points
  where id = p_user_id;

  -- Insert participant
  insert into public.participants (competition_id, user_id)
  values (p_competition_id, p_user_id);
end;
$$ language plpgsql security definer;

-- Update participant score: accumulates score and increments completed count.
create or replace function public.update_participant_score(
  p_competition_id uuid,
  p_user_id uuid,
  p_score int
) returns void as $$
begin
  update public.participants
  set
    total_score = total_score + p_score,
    completed_challenges = completed_challenges + 1
  where competition_id = p_competition_id and user_id = p_user_id;
end;
$$ language plpgsql security definer;

-- Distribute prizes to winners when a competition ends.
-- Idempotent: only distributes once (checks prizes_distributed flag).
-- Adds the calculated prize points to each winner's profile.
create or replace function public.distribute_prizes(p_competition_id uuid)
returns jsonb as $$
declare
  comp record;
  winners cursor for
    select p.user_id, p.total_score,
           row_number() over (order by p.total_score desc) as rank
    from public.participants p
    where p.competition_id = p_competition_id
      and p.completed_challenges > 0
    order by p.total_score desc;
  winner record;
  share_idx int;
  prize int;
  results jsonb := '[]'::jsonb;
begin
  -- Load competition
  select * into comp
  from public.competitions
  where id = p_competition_id;

  if comp is null then
    raise exception 'Competition not found';
  end if;

  -- Check if already distributed
  if (comp.prize_pool is null or comp.prize_pool = 0) then
    return '{"distributed": false, "reason": "no prize pool"}'::jsonb;
  end if;

  -- Mark as finished if not already
  update public.competitions
  set status = 'finished'
  where id = p_competition_id and status != 'finished';

  -- Distribute to top N winners
  share_idx := 0;
  for winner in winners loop
    exit when share_idx >= coalesce(comp.winner_count, 3);
    exit when share_idx >= coalesce(jsonb_array_length(comp.winner_shares), 0);

    prize := comp.prize_pool
             * ((comp.winner_shares->>share_idx)::decimal / 100.0);

    -- Add prize points to winner's profile
    update public.profiles
    set points = points + prize
    where id = winner.user_id;

    results := results || jsonb_build_array(
      jsonb_build_object(
        'user_id', winner.user_id,
        'rank', winner.rank,
        'prize', prize
      )
    );

    share_idx := share_idx + 1;
  end loop;

  return jsonb_build_object(
    'distributed', true,
    'winners', results,
    'prize_pool', comp.prize_pool
  );
end;
$$ language plpgsql security definer;

-- Get leaderboard with prize info for finished competitions.
-- Returns rank, score, nickname, telegram username, and the prize each winner received.
create or replace function public.get_final_leaderboard(p_competition_id uuid)
returns table(
  user_id uuid,
  nickname text,
  telegram_username text,
  total_score int,
  completed_challenges int,
  rank bigint,
  prize int
) as $$
begin
  return query
  select
    p.user_id,
    profiles.nickname,
    profiles.telegram_username,
    p.total_score,
    p.completed_challenges,
    row_number() over (order by p.total_score desc) as rank,
    case
      when comp.status = 'finished'
           and row_number() over (order by p.total_score desc) <= comp.winner_count
           and jsonb_array_length(comp.winner_shares) >=
               row_number() over (order by p.total_score desc)
      then
        (comp.prize_pool
         * ((comp.winner_shares->>
             (row_number() over (order by p.total_score desc) - 1)::int)::decimal
            / 100.0))::int
      else 0
    end as prize
  from public.participants p
  join public.profiles on profiles.id = p.user_id
  cross join public.competitions comp
  where p.competition_id = p_competition_id
    and comp.id = p_competition_id
    and p.completed_challenges > 0
  order by p.total_score desc;
end;
$$ language plpgsql security definer;
