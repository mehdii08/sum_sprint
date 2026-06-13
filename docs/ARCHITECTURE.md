# Sum Sprint – Architecture

## Overview

Sum Sprint follows a **layered architecture** with clear separation of concerns:

```
┌────────────────────────────────────────────┐
│  Screens (UI)                              │
│  home_screen, game_screen, result_screen...│
├────────────────────────────────────────────┤
│  State Management (Provider)               │
│  player_provider, challenge_provider,      │
│  result_provider                           │
├────────────────────────────────────────────┤
│  Services (Pure Dart, Business Logic)      │
│  question_generator, score_calculator,     │
│  challenge_runner                          │
├────────────────────────────────────────────┤
│  Repositories (Data Access)                │
│  result_repository (abstract),             │
│  local_result_repository (SharedPrefs)     │
├────────────────────────────────────────────┤
│  Models (Data)                             │
│  challenge_definition, question, result,   │
│  player_data                               │
└────────────────────────────────────────────┘
```

## Layer Details

### Models (`lib/models/`)
Plain Dart data classes with `fromJson`/`toJson` serialization.
- **ChallengeDefinition**: Describes a challenge (operation, number range, time per question).
- **Question**: A single question with its answer options.
- **QuestionResult**: Per-question outcome (correct/wrong + response time).
- **Result**: Final challenge result (score, correct count, total time, date).
- **PlayerData**: Player profile (nickname, uid placeholder for future auth).

### Services (`lib/services/`)
Pure Dart logic with **no Flutter/UI dependencies**.

- **QuestionGenerator**: Generates questions based on a `ChallengeDefinition`. Uses a `switch` on `challenge.operation` for extensibility (currently only `+` is implemented; new operations can be added as new cases).
- **ScoreCalculator**: Static methods for computing per-question scores (`100 + remainingTimeSeconds * 20`, minimum 10) and total scores (sum + 200 perfect bonus).
- **ChallengeRunner**: Orchestrates a single challenge session — holds the question list, tracks current index, records results, and produces a final `Result`.

### Repositories (`lib/repositories/`)
Data access layer with an **abstract interface** for future server swap.

- **ResultRepository** (abstract): Defines `getResultsForChallenge`, `saveResult`, `getHighScore`, `clearHistory`.
- **LocalResultRepository**: Implements the interface using `SharedPreferences`. Stores up to 20 results per challenge as a JSON list. This can be swapped for `ApiResultRepository` later without changing any UI code.

### State Management (`lib/providers/`)
Uses the **Provider** package for reactive state management.

- **PlayerProvider**: Loads/saves the player nickname from SharedPreferences.
- **ChallengeProvider**: Loads challenges from bundled JSON, runs the game loop timer (50ms ticks), exposes timer progress, current question, and game state (idle → waitingForOptions → playing → showingResult → finished). Manages animations triggers and navigation.
- **ResultProvider**: Caches and exposes history and high scores via the repository layer.

### Screens (`lib/screens/`)
Flutter widgets that compose the UI. They consume providers via `Consumer<T>` or `context.watch<T>()` and use `AppLocalizations` for all user-facing strings.

- **HomeScreen**: Title, nickname input, "Warm Up" and "Competitions" buttons.
- **ChallengeListScreen**: Lists available challenges with best scores and play/history actions.
- **GameScreen**: Core game loop UI — number boxes, timer bar, answer buttons, animations.
- **ResultScreen**: Displays final score, stats, high-score badge, play-again/home buttons.
- **HistoryScreen**: Lists past results for a challenge with per-card stats and clear action.

### Widgets (`lib/widgets/`)
Reusable UI components: `AnswerButton`, `TimerBar`, `ScoreDisplay`.

## Game Loop Flow

1. User selects a challenge → `ChallengeProvider.startChallenge()`
2. `ChallengeRunner` pre-generates all 10 questions
3. For each question:
   - State: `waitingForOptions` (0.5s) → shows "Get ready..."
   - State: `playing` → shows answer buttons, starts countdown timer
   - User taps option (correct/wrong) OR timer expires (timeout)
   - State: `showingResult` (0.5s) → shows feedback (correct/wrong/time's up)
   - Advance to next question or finish
4. Game finished → `ChallengeRunner.getFinalResult()` → navigate to ResultScreen
5. ResultScreen saves result via `ResultProvider` → `LocalResultRepository`

## Localization

All user-facing strings are defined in `lib/l10n/app_en.arb` and accessed via `AppLocalizations.of(context)`. The generated code provides type-safe getters. Adding a new language only requires a new `.arb` file — no screen code changes.

## Key Design Decisions

### Repository Pattern
The `ResultRepository` abstract class allows swapping local storage (SharedPreferences) for a server API in the future without modifying any UI or provider code. This is essential for the planned v2 competitions feature.

### Operation Extensibility
The `QuestionGenerator` uses a `switch` on `challenge.operation`. Currently only `+` is supported. To add subtraction:
1. Add a challenge with `"operation": "-"` to challenges.json
2. Add a `'-' => num1 - num2` case to the switch
3. Optionally adjust decoy generation logic

The scoring and game loop are operation-agnostic.

### Platform Agnostic
All game logic lives in pure Dart services. The UI layer only handles rendering and input. This means the core could be reused for web, desktop, or even a server-side simulation.
