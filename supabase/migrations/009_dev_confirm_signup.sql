-- Dev-only: confirm signup when client sends code 123456 + shared secret.
-- Gate client-side with SupabaseConfig.debugMode. Drop before production.

create or replace function public.dev_confirm_signup(
  p_email text,
  p_code text,
  p_secret text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_updated int;
begin
  if p_secret is distinct from 'sum-sprint-dev-otp' then
    raise exception 'Unauthorized';
  end if;

  if trim(coalesce(p_code, '')) is distinct from '123456' then
    return false;
  end if;

  update auth.users
  set email_confirmed_at = coalesce(email_confirmed_at, now())
  where lower(email) = lower(trim(p_email));

  get diagnostics v_updated = row_count;
  return v_updated > 0;
end;
$$;

revoke all on function public.dev_confirm_signup(text, text, text)
  from public;
grant execute on function public.dev_confirm_signup(text, text, text)
  to anon, authenticated;

comment on function public.dev_confirm_signup(text, text, text) is
  'DEV ONLY: confirm email when code is 123456. Remove before production.';
