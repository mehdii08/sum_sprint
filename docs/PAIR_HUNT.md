# Pair Hunt Challenge – Game Rules & Technical Reference

## Game Rules

1. User opens a Pair Hunt challenge.
2. An intro screen shows the challenge name, number of pairs to find, and time limit. There is a **Start** button.
3. User taps **Start**. The timer begins counting down. All blocks appear face-down in a grid (rows of 4).
4. User taps a block. It flips to reveal its emoji.
5. User taps a second block. It flips to reveal its emoji.
6. If the two emojis **match**: Both blocks stay face-up (green border) and become inactive. A brief success animation plays.
7. If the two emojis do **NOT** match: Both blocks stay visible for 1 second. Then both flip back face-down.
8. User continues until all pairs are found **OR** the timer runs out.

## Grid Layout

- Blocks are arranged in **rows of 4**. Grid fits on one screen — no scrolling required.
- Block counts: 4 (1 row), 8 (2 rows), 12 (3 rows), 16 (4 rows), 20 (5 rows).
- Emojis are randomly selected from a pool of **65 distinct emojis** across 5 categories.
- For each game, N unique emojis are picked (N = block count / 2), and each assigned to 2 random blocks.

## Points Formula

```
basePoints      = pairsFound × pointsPerPair
timeBonus       = (timeRemaining / totalTime) × maxTimeBonus
mismatchPenalty = mismatches × penaltyPerMismatch
totalPoints     = max(0, basePoints + timeBonus - mismatchPenalty)
```

### Example

12 blocks = 6 pairs, time limit 60 seconds, pointsPerPair=100, maxTimeBonus=500, penaltyPerMismatch=25.

User finds all 6 pairs in 40 seconds (20 remaining), with 3 mismatches:
- basePoints = 6 × 100 = **600**
- timeBonus = (20/60) × 500 = **166**
- mismatchPenalty = 3 × 25 = **75**
- **totalPoints = 691**

If timer runs out: timeBonus = 0, but pairs found still earn basePoints minus penalties.

### Default Values (configurable per challenge)

| Parameter | Default |
|-----------|---------|
| pointsPerPair | 100 |
| maxTimeBonus | 500 |
| penaltyPerMismatch | 25 |

## Architecture

### Models (`lib/models/`)

- **`ChallengeDefinition`** — Discriminated by `challengeType == 'pair_hunt'`. Fields: `blockCount`, `timeLimitSeconds`, `pointsPerPair`, `maxTimeBonus`, `penaltyPerMismatch`.
- **`PairHuntBlock`** (`question.dart`) — Per-block data: emoji, isRevealed, isMatched.
- **`PairHuntGameResult`** (`question.dart`) — Per-game outcome: score, pairsFound, totalPairs, mismatchCount, timeTaken.
- **`Result`** — Extended with `isPairHunt`, `pairsFound`, `totalPairs`, `mismatchCount`.

### Services (`lib/services/`)

- **`PairHuntScoring`** — Pure function implementing the points formula.
- **`PairHuntRunner`** — Orchestrates a session: grid generation (emoji pool + randomization), block interaction (flip, match, mismatch), final result creation.

### Provider (`lib/providers/`)

- **`PairHuntProvider`** — Manages game state: `intro → playing → showingMismatch → finished`. Uses a countdown timer (1-second ticks) and a mismatch reset timer (1-second delay). Tracks revealed indices, matched indices, lock state.

### Screen (`lib/screens/`)

- **`PairHuntGameScreen`** — Three visual states:
  1. **Intro**: Challenge info, rules, Start button
  2. **Playing**: Timer bar + progress + grid of face-down blocks with flip animations
  3. **Finished**: Navigates to `ResultScreen`

## Bundled Presets

| ID | Blocks | Pairs | Time Limit | Difficulty |
|----|--------|-------|------------|------------|
| `pair_hunt_easy` | 8 | 4 | 90s | Easy |
| `pair_hunt_medium` | 12 | 6 | 60s | Medium |
| `pair_hunt_hard` | 20 | 10 | 90s | Hard |

All presets use: pointsPerPair=100, maxTimeBonus=500, penaltyPerMismatch=25.

## Where It Works

- **Offline Warm Up** — 3 presets in `assets/data/challenges.json`
- **Online Competitions** — Pair Hunt challenges can be included in any competition via the admin panel
- **Admin Panel** — Create Pair Hunt challenges with the type picker dialog

## Admin Panel Fields

When creating a Pair Hunt challenge in the admin panel:

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| Challenge Name | String | — | Required |
| Block Count | Dropdown | 12 | Step of 4: 4, 8, 12, 16, 20 |
| Time Limit | Integer | 60s | In seconds, step of 15 |
| Points Per Pair | Integer | 100 | Step of 50 |
| Max Time Bonus | Integer | 500 | Step of 100 |
| Penalty Per Mismatch | Integer | 25 | Step of 5 |

## Emoji Pool

65 emojis across 5 categories:
- **Animals** (15): 🐶🐱🐼🐨🦊🐸🐵🦁🐯🐮🐷🐰🐻🐔🐧
- **Food** (15): 🍎🍕🍔🌮🍩🍪🍓🍌🥑🍇🍉🍋🍒🥝🧁
- **Objects** (15): ⚽🎸🚀💡🔑🎩📱💎⌚🎁🚗✈️🏠🎵🔔
- **Faces** (10): 😀😂😍😎🤩😱🥳😴🤔😇
- **Nature** (10): 🌈⭐🔥🌊🌺🍀🌙☀️❄️🌸

## Extensibility

Follows the same pattern as Mind Timer and Math challenges:
1. Added `pair_hunt` to `ChallengeType` enum in `challenge_definition.dart`
2. Added JSON serialization for all new fields
3. Created runner (`PairHuntRunner`), provider (`PairHuntProvider`), and screen (`PairHuntGameScreen`)
4. Updated `ChallengeListScreen`, `CompetitionDetailScreen`, `AdminCompetitionsScreen`, and `ResultScreen` to branch on `isPairHunt`
5. Extended `Result` model with Pair Hunt-specific fields
6. Registered `PairHuntProvider` in `main.dart`
