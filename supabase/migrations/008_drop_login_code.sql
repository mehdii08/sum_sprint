-- Remove unused login_code stub from profiles.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, nickname, coins, telegram_id)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data ->> 'nickname',
      new.raw_user_meta_data ->> 'first_name',
      'Player'
    ),
    500,
    (new.raw_user_meta_data ->> 'telegram_id')::bigint
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

revoke all on function public.handle_new_user() from public, anon, authenticated;

alter table public.profiles drop column if exists login_code;
