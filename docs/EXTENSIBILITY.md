# Sum Sprint – Extensibility Guide

This document explains how to extend the game with new challenge types, operations, and future server integration.

## Adding a New Operation (e.g., Subtraction)

### Step 1: Add a challenge definition
Add a new entry to `assets/data/challenges.json`:
```json
{
  "id": "easy_sub",
  "name": "Easy Subtraction",
  "description": "Numbers 1-20, subtract smaller from larger.",
  "operation": "-",
  "minNumber": 1,
  "maxNumber": 20,
  "timePerQuestionSeconds": 5,
  "questionCount": 10
}
```

### Step 2: Implement the operation
In `lib/services/question_generator.dart`, add a new case to the switch:
```dart
final int correctAnswer = switch (challenge.operation) {
  '+' => num1 + num2,
  '-' => (num1 - num2).abs(),  // Ensure positive result
  _ => throw UnimplementedError(...),
};
```

### Step 3: (Optional) Customize decoy generation
For some operations, the default ±1 to ±5 decoy generation may not be ideal. You can customize the decoy strategy per operation:
```dart
int generateDecoyOffset() => switch (challenge.operation) {
  '+' || '-' => (_random.nextInt(5) + 1) * (_random.nextBool() ? 1 : -1),
  '×'   => _random.nextInt(10) + 1,  // Wider range for multiplication
  _     => (_random.nextInt(5) + 1) * (_random.nextBool() ? 1 : -1),
};
```

### Step 4: (If needed) Customize scoring
The `ScoreCalculator` is operation-agnostic — points are based solely on time and correctness. If a future operation requires different scoring, you can:
- Add a scoring strategy interface
- Implement per-operation scoring classes
- Inject the strategy into `ChallengeRunner`

**The existing scoring formula works for all arithmetic operations without changes.**

## Adding a Completely New Challenge Type (e.g., Pattern Recognition)

1. **Define the operation**: Use a unique string in `challenge.operation` (e.g., `"pattern"`).
2. **Extend data model**: Add any new fields to `ChallengeDefinition` (e.g., `patternLength`).
3. **Implement generator**: Add a case to `QuestionGenerator` or create a new generator class and inject it via a factory/strategy pattern.
4. **Adjust UI**: If the new challenge type needs different visual presentation, extend `GameScreen` to branch on `challenge.operation`. The current game loop (timer, scoring, feedback) should remain the same.

## Adding Competitions (v2 Feature)

The architecture is designed for this:

### Server Integration
- **ResultRepository** is an abstract interface. Swap `LocalResultRepository` with `ApiResultRepository` that POSTs results to `/api/results` and GETs leaderboards from `/api/leaderboard`.
- **PlayerData.uid** will be populated from server authentication (Firebase Auth, OAuth, etc.).
- **ChallengeProvider** can fetch challenges from a server endpoint instead of bundled JSON by extending `loadChallenges()`.

### Competition Flow
1. Server creates a competition with a specific challenge + time window.
2. Players join the competition (assigns a competition ID).
3. Game loop runs identically — only the result submission changes (to a competition-specific endpoint).
4. Leaderboard is fetched from the server and displayed in a new `LeaderboardScreen`.

### Points Pool (Future)
A shared points pool where all players contribute and top performers win rewards. This would be server-side logic, transparent to the client.

## Adding New Languages

See [LOCALIZATION.md](./LOCALIZATION.md). Add a new `.arb` file to `lib/l10n/` and run `flutter gen-l10n`. No code changes needed in screens.

## Repository Pattern Benefits

```
                    ┌──────────────────┐
                    │  ResultProvider  │
                    └────────┬─────────┘
                             │ uses
                    ┌────────▼─────────┐
                    │ ResultRepository │  ← abstract interface
                    │  (abstract)      │
                    └────────┬─────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
     ┌────────▼──────┐ ┌────▼────────┐ ┌───▼──────────┐
     │ LocalResult   │ │ ApiResult   │ │ CacheResult  │
     │ Repository    │ │ Repository  │ │ Repository   │
     │ (v1 current)  │ │ (v2 server) │ │ (v2 offline) │
     └───────────────┘ └─────────────┘ └──────────────┘
```

The UI and provider code never knows which repository is in use — they only depend on the abstract interface. This makes swapping implementations trivial.
