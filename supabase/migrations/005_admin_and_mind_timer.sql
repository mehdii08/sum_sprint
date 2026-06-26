-- Migration 005: Admin support + Mind Timer schema prep
-- Adds is_admin column, admin RLS policies, and ensures profiles tracks the new fields.

-- ============================================
-- 1. Add is_admin to profiles
-- ============================================
alter table public.profiles
  add column if not exists is_admin boolean default false;

-- ============================================
-- 2. Admin-only RLS policies for competitions
-- ============================================
drop policy if exists "Admins can insert competitions" on public.competitions;
create policy "Admins can insert competitions"
  on public.competitions for insert
  with check (exists (select 1 from public.profiles where id = auth.uid() and is_admin = true));

drop policy if exists "Admins can update competitions" on public.competitions;
create policy "Admins can update competitions"
  on public.competitions for update
  using (exists (select 1 from public.profiles where id = auth.uid() and is_admin = true));

drop policy if exists "Admins can delete competitions" on public.competitions;
create policy "Admins can delete competitions"
  on public.competitions for delete
  using (exists (select 1 from public.profiles where id = auth.uid() and is_admin = true));

-- ============================================
-- 3. Mind Timer metadata on challenge_results
-- ============================================
alter table public.challenge_results
  add column if not exists accuracy double precision,
  add column if not exists is_mind_timer boolean default false;
