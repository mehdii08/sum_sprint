-- Entry fee (coins) per challenge. 0 = free.
alter table public.challenges
  add column if not exists "entryCoins" integer not null default 0
  check ("entryCoins" >= 0);

comment on column public.challenges."entryCoins" is
  'Coins required to start this challenge. 0 means free.';

-- Atomically charge entry fee and return remaining coins.
create or replace function public.pay_challenge_entry(p_challenge_id text)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_cost integer;
  v_remaining integer;
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  select coalesce("entryCoins", 0)
  into v_cost
  from public.challenges
  where id = p_challenge_id
    and coalesce(is_active, true) = true;

  if v_cost is null then
    raise exception 'Challenge not found';
  end if;

  if v_cost = 0 then
    select coalesce(coins, 0) into v_remaining
    from public.profiles
    where id = v_uid;
    return coalesce(v_remaining, 0);
  end if;

  update public.profiles
  set coins = coins - v_cost
  where id = v_uid
    and coalesce(coins, 0) >= v_cost
  returning coins into v_remaining;

  if v_remaining is null then
    raise exception 'Insufficient coins';
  end if;

  return v_remaining;
end;
$$;

revoke all on function public.pay_challenge_entry(text) from public, anon;
grant execute on function public.pay_challenge_entry(text) to authenticated;
