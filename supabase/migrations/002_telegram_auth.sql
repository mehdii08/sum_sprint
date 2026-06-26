-- Sum Sprint – Telegram Mini App Auth
-- Adds telegram_id to profiles for Telegram-to-Supabase user linking.

-- 1. Add telegram_id column to profiles
alter table public.profiles
  add column if not exists telegram_id bigint;

-- 2. Unique index for fast lookup (only non-null values)
create unique index if not exists idx_profiles_telegram_id
  on public.profiles (telegram_id)
  where telegram_id is not null;

-- 3. Update handle_new_user to also capture telegram_id from metadata
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, nickname, points, telegram_id, login_code)
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

-- 4. Add RLS policy so users can read their own telegram_id
drop policy if exists "Users can read own telegram_id" on public.profiles;
-- (already covered by "Users can read all profiles" — no extra policy needed)
