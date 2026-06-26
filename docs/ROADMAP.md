# Sum Sprint – Roadmap

## v1.0 – Offline Warm-Up (Current)

### ✅ Implemented
- **3 addition challenges**: Easy (1-10, 5s), Medium (5-20, 4s), Hard (10-50, 3s)
- **Full game loop**: 10 questions per challenge, countdown timer, scoring
- **Scoring system**: `100 + remainingTimeSeconds × 20` per question + 200 perfect bonus
- **Local history**: Last 20 results per challenge saved via SharedPreferences
- **High scores**: Best score tracking per challenge
- **Player profile**: Nickname persistence
- **Animations**: Correct (scale pulse), Wrong (horizontal shake), timer bar color lerp
- **Multi-language foundation**: ARB-based localization (English only)
- **Extensible architecture**: Abstract repository, operation switch, clean layer separation

### Architecture Highlights
- Layered: Models → Services → Repositories → Providers → Screens
- Repository abstraction for future server swap
- Operation-agnostic game loop (scoring works for any arithmetic operation)
- Pure Dart services (no Flutter dependency in business logic)
- Provider-based state management

## v2.0 – Competitions & Online Play (🔄 In Progress)

### ✅ Implemented (v2-alpha)
- **Supabase Auth**: Email/password sign-up and sign-in (`AuthProvider`)
- **Competitions list**: Fetched from Supabase `public.competitions` table
- **Competition detail**: Tabbed view (Challenges / Leaderboard)
- **Join system**: Points-based entry via `join_competition` RPC
- **Competition game mode**: Same `GameScreen`, results submitted to Supabase
- **Leaderboard**: Real-time rankings from `public.participants`
- **Points pool**: Users start with 500 points, competitions pool from entries
- **SupabaseResultRepository**: Online result storage (runs alongside offline)
- **SupabaseCompetitionRepository**: Competition-specific CRUD operations
- **Offline mode preserved**: Warm Up uses `LocalResultRepository` unchanged

### ✅ Recently Added (v2)
- **Mind Timer challenge type**: Stop a hidden timer as close to a target as possible
- **3 bundled Mind Timer presets**: Easy (5s/2s range), Medium (10s/1.5s range), Hard (15s/1s range)
- **Admin panel**: Challenge type selector (Math / Mind Timer) when creating/editing competitions
- **Admin RLS**: `is_admin` column on profiles, admin-only insert/update/delete on competitions
- **Scoring formula**: `points = round(maxPoints × (1 - |diff|/range))`, 0 outside range

### 🔜 Planned (v2-beta)
- Competitions fetched from server API instead of hardcoded JSON (challenges.json still works offline)
- Prize distribution on competition end
- OTP and social login (Google, Apple)
- Push notifications
- More challenge types: Subtraction, multiplication, division

### Technical Changes
| Component | v1 (Current) | v2 (Current) |
|-----------|-------------|-------------|
| Auth | None | Supabase Auth (email/password) |
| Data storage | SharedPreferences | SharedPreferences + Supabase |
| Repository | LocalResultRepository | LocalResultRepository + SupabaseCompetitionRepository |
| Challenges | Bundled JSON | Bundled JSON (offline) + server JSON (competitions) |
| Navigation | Simple push | Push routes (no auth guards yet) |
| PlayerData.uid | Empty string | Server-assigned user ID |
| Navigation | Simple push | GoRouter with auth guards |

## v3.0 – Social & Advanced (Future)

- **Friend challenges**: Challenge friends to beat your score
- **Daily challenges**: Curated daily puzzles
- **Achievement system**: Badges for streaks, speed, accuracy
- **Custom challenges**: User-created challenge configs
- **Offline competition mode**: Download competition data, play offline, sync results when online
- **Accessibility**: Screen reader support, high contrast mode
- **Sound effects**: Correct/wrong/tick sounds (audioplayers already in dependencies)

## Timeline

| Phase | Target | Key Deliverables |
|-------|--------|-----------------|
| v1.0 | Current | Playable offline game, 3 challenges, local history |
| v1.1 | Next | Sound effects, more challenges, UI polish |
| v2.0 | TBD | Server backend, user auth, live competitions |
| v3.0 | TBD | Social features, daily challenges, custom configs |
