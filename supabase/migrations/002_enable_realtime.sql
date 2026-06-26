-- Enable Supabase Realtime on the participants table
-- so the leaderboard can update live during active competitions.

alter publication supabase_realtime add table public.participants;
