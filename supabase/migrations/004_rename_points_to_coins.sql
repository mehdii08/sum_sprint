-- Rename user balance from "points" to "coins" to disambiguate
-- from challenge/leaderboard "points".
-- Run this in the Supabase SQL Editor.

-- 1. Rename the column
alter table public.profiles rename column points to coins;

-- 2. Update handle_new_user trigger
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, nickname, coins, telegram_id, login_code)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data ->> 'nickname',
      new.raw_user_meta_data ->> 'first_name',
      'Player'
    ),
    500,
    (new.raw_user_meta_data ->> 'telegram_id')::bigint,
    '1234'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

-- 3. Update join_competition function (deduct coins)
create or replace function public.join_competition(
  p_competition_id uuid,
  p_user_id uuid,
  p_entry_points int
) returns void as $$
begin
  -- Check user has enough coins
  if (select coins from public.profiles where id = p_user_id) < p_entry_points then
    raise exception 'Insufficient coins to join this competition.';
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

  -- Deduct coins from user
  update public.profiles
  set coins = coins - p_entry_points
  where id = p_user_id;

  -- Insert participant
  insert into public.participants (competition_id, user_id)
  values (p_competition_id, p_user_id);
end;
$$ language plpgsql security definer;

-- 4. Update distribute_prizes (add coins to winners, not points)
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

    -- Add prize coins to winner's profile
    update public.profiles
    set coins = coins + prize
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
