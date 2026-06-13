# Sum Sprint – Flutter Offline Math Challenge Game Specification

## Project Setup
- Create a new Flutter project named `sum_sprint`.
- Minimum Android SDK 21, iOS 12.
- Dependencies in pubspec.yaml:
  - shared_preferences: ^2.2.2
  - provider: ^6.1.1
  - audioplayers: ^5.2.1 (optional, for sound)
  - google_fonts: ^6.1.0 (optional)
  - flutter_localizations (for multi-language support)
  - intl (for internationalization)
- Register assets in pubspec.yaml:
  flutter:
    assets:
      - assets/data/challenges.json
      - assets/sounds/   (if using sound)

## Architecture & Folder Structure
lib/
├── main.dart
├── models/
│   ├── challenge_definition.dart
│   ├── question.dart
│   ├── player_data.dart
│   └── result.dart
├── services/
│   ├── question_generator.dart
│   ├── score_calculator.dart
│   └── challenge_runner.dart
├── repositories/
│   ├── result_repository.dart          (abstract)
│   └── local_result_repository.dart    (shared_preferences)
├── providers/
│   ├── player_provider.dart
│   ├── challenge_provider.dart
│   └── result_provider.dart
├── screens/
│   ├── home_screen.dart
│   ├── challenge_list_screen.dart
│   ├── game_screen.dart
│   ├── result_screen.dart
│   └── history_screen.dart
├── widgets/
│   ├── answer_button.dart
│   ├── timer_bar.dart
│   └── score_display.dart
└── data/
    └── challenges.json

## Game Rules
- A challenge consists of exactly 10 questions.
- Each question shows two random numbers in boxes at the top.
- After a 0.5‑second delay, three answer boxes appear: one correct sum, two decoys.
- Decoys are ±1 to ±5 from the correct answer, distinct and not equal to the correct answer.
- A countdown timer bar starts when options appear. Time per question is defined by the challenge (e.g., 5 seconds easy, 3 seconds hard).
- Timer expires → fail (0 points), show "Time's Up" for 0.5s, then next question.
- Correct tap → points = 100 + (remaining time in seconds × 20), rounded. Minimum 10 points if correct but nearly out of time.
- Wrong tap → 0 points, red flash, next question after 0.5s.
- Total score = sum of per-question points + 200 bonus if all 10 correct.

## Data Models
- ChallengeDefinition: id (String), name (String), description (String), operation (String, "+" only for v1), minNumber (int), maxNumber (int), timePerQuestionSeconds (int), questionCount (int, default 10).
- Question: num1 (int), num2 (int), correctAnswer (int), options (List<int>, 3 shuffled).
- Result: challengeId (String), score (int), correctCount (int), totalResponseTimeMs (int), date (DateTime), playerName (String).
- PlayerData: nickname (String), uid (String, empty for now).

## Services (Pure Dart, No UI)
- QuestionGenerator: generate(ChallengeDefinition) → Question. Random numbers in range, compute correct, create two distinct decoys, shuffle options.
- ScoreCalculator: static calculateForQuestion(remainingTimeMs, totalTimePerQuestionMs) → int. static calculateTotal(List<QuestionResult>) → int (sum + perfect bonus). QuestionResult is a small class with isCorrect (bool), responseTimeMs (int).
- ChallengeRunner: Holds current question index, list of QuestionResult, start time. Methods: startChallenge(ChallengeDefinition), getCurrentQuestion(), answerSelected(int value) records result and advances, isFinished(), getFinalResult(PlayerData) → Result.

## Repositories
- ResultRepository (abstract): getResultsForChallenge(String id) → List<Result>, saveResult(Result), getHighScore(String id) → int.
- LocalResultRepository: Uses shared_preferences, key 'results_$challengeId', stores JSON list of results (max 20 per challenge).

## State Management (Provider)
- PlayerProvider: Loads/saves nickname from SharedPreferences, exposes PlayerData.
- ChallengeProvider: Loads challenges from bundled JSON, holds current ChallengeRunner, exposes current question, timer progress (0.0-1.0), final result. Methods: selectChallenge(ChallengeDefinition), startChallenge(), answerQuestion(int). Timer logic: provider stores timeLeftMs; UI ticks with Timer.periodic and calls updateTime(deltaMs).
- ResultProvider: Uses LocalResultRepository to provide history list and high score per challenge.

## Screen Flow & UI
- HomeScreen: Title "Sum Sprint", nickname TextField (saves on change), "Warm Up" button → ChallengeListScreen, "Competitions" button → placeholder dialog ("Coming Soon").
- ChallengeListScreen: AppBar with title "Warm Up Challenges", ListView of cards: name, description, best score, play button. Each card has a history icon → HistoryScreen.
- GameScreen: AppBar with challenge name, question counter (e.g., "3/10"). Two number boxes with "+" between, 0.5s delay then three answer buttons fade in. LinearProgressIndicator as timer bar (color lerps green→yellow→red). Buttons disabled after tap until next question. Correct tap: green, scale pulse. Wrong tap: red, shake. Timer expiry overlay "Time's Up" for 0.5s. After last question, navigate to ResultScreen.
- ResultScreen: "Challenge Complete!", final score, correct count, average time, new high-score badge if applicable. Buttons: "Play Again" (restart same challenge), "Home".
- HistoryScreen: AppBar with challenge name, list of last 20 results (date, score, correct count), clear history button with confirmation dialog.

## Animations & Sound (Optional)
- Correct: green background, scale bounce (AnimationController, scale 1.0→1.2→1.0).
- Wrong: red background, horizontal shake (AnimationController, offset sine).
- Timer bar color: lerp Colors.green to Colors.red based on progress.
- Sounds (if using): correct beep, wrong buzz, tick warning in last 2 seconds.

## Bundled Challenges (assets/data/challenges.json)
[
  {
    "id": "easy_add",
    "name": "Easy Addition",
    "description": "Numbers 1-10, 5 seconds per question.",
    "operation": "+",
    "minNumber": 1,
    "maxNumber": 10,
    "timePerQuestionSeconds": 5,
    "questionCount": 10
  },
  {
    "id": "medium_add",
    "name": "Medium Addition",
    "description": "Numbers 5-20, 4 seconds per question.",
    "operation": "+",
    "minNumber": 5,
    "maxNumber": 20,
    "timePerQuestionSeconds": 4,
    "questionCount": 10
  },
  {
    "id": "hard_mix",
    "name": "Hard Mix",
    "description": "Numbers 10-50, 3 seconds per question.",
    "operation": "+",
    "minNumber": 10,
    "maxNumber": 50,
    "timePerQuestionSeconds": 3,
    "questionCount": 10
  }
]

## Build & Export
- Web: flutter build web → deploy to itch.io / Firebase Hosting.
- Android: flutter build apk --release.
- iOS: flutter build ios (needs macOS).
- Register assets in pubspec.yaml before build.

## Scalability Notes (Future, Do Not Implement Now)
- ResultRepository interface allows swapping to ApiResultRepository.
- PlayerData.uid for server auth.
- Challenge definitions can be fetched from server using same JSON structure.
- ChallengeRunner and scoring are platform-agnostic.

## Multi-Language Support
- All user-facing strings are extracted into ARB files (currently only English).
- Uses Flutter's flutter_localizations + intl with code generation (flutter gen-l10n).
- To add a new language: add a new .arb file to lib/l10n/ and re-run flutter gen-l10n.

## Challenge Extensibility
- ChallengeDefinition.operation field drives the question generator via a switch statement.
- New operations (subtraction, multiplication, etc.) can be added by implementing new cases in QuestionGenerator.
- The core game loop (timer, scoring, feedback) is operation-agnostic.
