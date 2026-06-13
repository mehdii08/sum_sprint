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

## v2.0 – Competitions & Online Play (Planned)

### Features
- **User accounts**: Login via email, Google, or Apple
- **Live competitions**: Timed events with leaderboards
- **Server leaderboard**: Global and per-challenge rankings
- **ApiResultRepository**: Swaps local storage for REST API
- **Points pool**: Community-driven reward system
- **Push notifications**: Competition reminders, leaderboard updates
- **More challenge types**: Subtraction, multiplication, division, pattern recognition
- **Multi-language support**: Add French, Spanish, German, etc. via new .arb files

### Technical Changes
| Component | v1 (Current) | v2 (Planned) |
|-----------|-------------|-------------|
| Auth | None | Firebase Auth / OAuth |
| Data storage | SharedPreferences | Server API + local cache |
| Repository | LocalResultRepository | ApiResultRepository |
| Challenges | Bundled JSON | Server-fetched + bundled fallback |
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
