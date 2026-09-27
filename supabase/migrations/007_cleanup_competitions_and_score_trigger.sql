-- Cleanup leftover competition RPCs/tables and harden score trigger.

-- 1) Drop unused competition SECURITY DEFINER RPCs (callable by anon).
drop function if exists public.join_competition(uuid, uuid, integer);
drop function if exists public.update_participant_score(uuid, uuid, integer);
drop function if exists public.distribute_prizes(uuid);
drop function if exists public.get_final_leaderboard(uuid);

-- 2) Drop competition tables (app no longer uses them).
alter table if exists public.challenge_results
  drop column if exists competition_id;

drop table if exists public.participants;
drop table if exists public.competitions;

-- 3) Recalculate total_score on INSERT/UPDATE/DELETE of challenge_results.
create or replace function public.update_total_score()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_user_id uuid;
begin
  v_user_id := coalesce(new.user_id, old.user_id);
  if v_user_id is null then
    return coalesce(new, old);
  end if;

  update public.profiles
  set total_score = (
    select coalesce(sum(score), 0)
    from public.challenge_results
    where user_id = v_user_id
  )
  where id = v_user_id;

  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_update_total_score on public.challenge_results;
create trigger trg_update_total_score
  after insert or update or delete on public.challenge_results
  for each row
  execute function public.update_total_score();

-- 4) handle_new_user is trigger-only — revoke RPC execute + set search_path.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
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

revoke all on function public.handle_new_user() from public, anon, authenticated;

-- 5) Revoke leftover helper if present.
do $$
begin
  if exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'rls_auto_enable'
  ) then
    execute 'revoke all on function public.rls_auto_enable() from public, anon, authenticated';
  end if;
end $$;
