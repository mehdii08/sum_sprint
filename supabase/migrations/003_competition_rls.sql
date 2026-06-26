-- Allow authenticated users to manage competitions.
-- The admin panel in the Flutter app handles authorization.

-- INSERT
drop policy if exists "Authenticated users can insert competitions" on public.competitions;
create policy "Authenticated users can insert competitions"
  on public.competitions for insert
  with check (auth.role() = 'authenticated');

-- UPDATE
drop policy if exists "Authenticated users can update competitions" on public.competitions;
create policy "Authenticated users can update competitions"
  on public.competitions for update
  using (auth.role() = 'authenticated');

-- DELETE
drop policy if exists "Authenticated users can delete competitions" on public.competitions;
create policy "Authenticated users can delete competitions"
  on public.competitions for delete
  using (auth.role() = 'authenticated');
