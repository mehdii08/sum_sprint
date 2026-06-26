# Mind Timer Challenge – Game Rules & Technical Reference

## Game Rules

1. User opens a Mind Timer challenge.
2. Screen shows a **target time** (e.g., "Stop at exactly 5.00 seconds") and a **Start** button.
3. User taps **Start**. A hidden timer begins. The screen shows a **Stop** button. **No visible timer is shown.**
4. User taps **Stop** when they think the target time has passed.
5. The app shows the actual time, points earned, and feedback.
6. This repeats for each question in the challenge.

## Points Formula

```
accuracy = 1.0 - (absoluteDifference / range)
points   = round(maxPoints × accuracy)
```

- If `absoluteDifference >= range` → points = 0
- Points are symmetric — being early or late by the same amount gives the same result.

### Examples (target = 5.00s, range = 2.00s, maxPoints = 1000)

| Actual | Difference | Accuracy | Points |
|--------|------------|----------|--------|
| 5.00   | 0.00       | 100%     | 1000   |
| 5.50   | 0.50       | 75%      | 750    |
| 6.00   | 1.00       | 50%      | 500    |
| 6.50   | 1.50       | 25%      | 250    |
| 7.00   | 2.00       | 0%       | 0      |
| 4.00   | 1.00       | 50%      | 500    |
| 3.00   | 2.00       | 0%       | 0      |

## Architecture

### Models

- **`ChallengeDefinition`** — Contains common fields (`id`, `name`, `challengeType`) plus Mind Timer-specific fields (`targetSeconds`, `rangeSeconds`, `maxPoints`). Discriminated by `challengeType == 'mind_timer'`.
- **`MindTimerQuestion`** — Per-round definition (target, range, maxPoints).
- **`MindTimerResult`** — Per-round outcome (actualSeconds, accuracy, points).
- **`Result`** — Final result with `isMindTimer`, `withinRangeCount`, `averageAccuracy`.

### Services

- **`MindTimerScoring`** — Pure function: `calculate(actual, target, range, maxPoints)` → `MindTimerResult`.
- **`MindTimerRunner`** — Orchestrates a session: tracks current round, records stops, computes final result.

### Providers

- **`MindTimerProvider`** — Manages game state: `ready → counting → showingResult → finished`. Uses a `Stopwatch` for precise timing. UI ticks at 50ms.

### Screens

- **`MindTimerGameScreen`** — Three visual states per round:
  1. **Ready**: target time display + pulsing Start button
  2. **Counting**: "Counting…" spinner + large Stop button (no visible timer!)
  3. **Result**: actual time, difference, points, accuracy bar, feedback word

### Where It Works

- **Offline Warm Up** — 3 presets in `assets/data/challenges.json` (easy/medium/hard)
- **Online Competitions** — Mind Timer challenges can be included in any competition via the admin panel
- **Admin Panel** — Create Mind Timer challenges with a type selector in the competition editor

## Bundled Presets

| ID | Target | Range | Max Points | Questions |
|----|--------|-------|------------|-----------|
| `mind_timer_easy` | 5.00s | 2.00s | 1000 | 5 |
| `mind_timer_medium` | 10.00s | 1.50s | 1000 | 5 |
| `mind_timer_hard` | 15.00s | 1.00s | 1000 | 5 |

## Adding New Mind Timer Challenges (Admin)

1. Navigate to Admin Panel → Competitions → Create/Edit
2. In the Challenges section, tap **+** to add a new challenge
3. Select **Mind Timer** from the type picker dialog
4. Fill in: Challenge Name, Target Seconds, Range Seconds, Max Points, Question Count
5. Save the competition

## Extensibility

To add a new challenge type in the future:
1. Add a new value to `ChallengeType` enum in `challenge_definition.dart`
2. Create a new runner service (like `MindTimerRunner`)
3. Create a new provider (like `MindTimerProvider`)
4. Create a new game screen (like `MindTimerGameScreen`)
5. Update `ChallengeListScreen`, `CompetitionDetailScreen`, and `ResultScreen` to branch on `challenge.challengeType`
6. Add type-specific JSON serialization in `ChallengeDefinition.fromJson`/`toJson`
