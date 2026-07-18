/// A math question with two numbers, a correct answer, and shuffled options.
class Question {
  final int num1;
  final int num2;
  final int correctAnswer;
  final List<int> options;

  const Question({
    required this.num1,
    required this.num2,
    required this.correctAnswer,
    required this.options,
  });
}

/// Per-question result for math challenges.
class QuestionResult {
  final bool isCorrect;
  final int responseTimeMs; // time taken to answer, 0 means timeout

  const QuestionResult({
    required this.isCorrect,
    required this.responseTimeMs,
  });

  Map<String, dynamic> toJson() => {
        'isCorrect': isCorrect,
        'responseTimeMs': responseTimeMs,
      };

  factory QuestionResult.fromJson(Map<String, dynamic> json) {
    return QuestionResult(
      isCorrect: json['isCorrect'] as bool,
      responseTimeMs: json['responseTimeMs'] as int,
    );
  }
}

// ── Mind Timer models ─────────────────────────────────────────────

/// A single Mind‑Timer question: user must stop a hidden timer
/// as close to [targetSeconds] as possible.
class MindTimerQuestion {
  /// The exact target time in seconds (e.g. 5.00).
  final double targetSeconds;

  /// The max allowed deviation either side of the target.
  /// If the user stops further than this, score = 0.
  final double rangeSeconds;

  /// Maximum points awarded for a perfect stop.
  final int maxPoints;

  const MindTimerQuestion({
    required this.targetSeconds,
    required this.rangeSeconds,
    required this.maxPoints,
  });
}

/// Per‑question result for a Mind‑Timer challenge.
class MindTimerResult {
  /// The actual elapsed time in seconds when the user stopped.
  final double actualSeconds;

  /// Whether the stop was within the valid range.
  bool get isWithinRange => absoluteDifference < rangeSeconds;

  /// Absolute difference between actual and target (always ≥ 0).
  final double absoluteDifference;

  /// Points earned for this question (0 if outside range).
  final int points;

  /// Accuracy ratio: 0.0–1.0 (0 if outside range).
  final double accuracy;

  final double rangeSeconds;

  const MindTimerResult({
    required this.actualSeconds,
    required this.absoluteDifference,
    required this.points,
    required this.accuracy,
    required this.rangeSeconds,
  });
}

// ── Pair Hunt models ──────────────────────────────────────────────

/// A single block in the Pair Hunt grid.
class PairHuntBlock {
  /// The emoji displayed on this block.
  final String emoji;

  /// Index of this block in the grid (0-based).
  final int index;

  /// Whether this block is currently face-up (revealed).
  bool isRevealed;

  /// Whether this block has been permanently matched.
  bool isMatched;

  PairHuntBlock({
    required this.emoji,
    required this.index,
    this.isRevealed = false,
    this.isMatched = false,
  });
}

/// The outcome of a Pair Hunt game.
class PairHuntGameResult {
  final int score;
  final int pairsFound;
  final int totalPairs;
  final int mismatchCount;
  final double timeTakenSeconds;
  final double timeLimitSeconds;

  bool get allPairsFound => pairsFound >= totalPairs;

  const PairHuntGameResult({
    required this.score,
    required this.pairsFound,
    required this.totalPairs,
    required this.mismatchCount,
    required this.timeTakenSeconds,
    required this.timeLimitSeconds,
  });
}

// ── Tic Tac Toe models ────────────────────────────────────────────

/// The mark in a single Tic‑Tac‑Toe cell.
enum TicTacToeMark { none, player, ai }

/// AI difficulty for a Tic‑Tac‑Toe round.
///
/// Rounds progress: round 1 = easy, round 2 = medium, round 3 = hard.
enum TicTacToeDifficulty {
  easy('easy'),
  medium('medium'),
  hard('hard');

  final String value;
  const TicTacToeDifficulty(this.value);
}

/// How a single Tic‑Tac‑Toe round ended.
enum TicTacToeRoundOutcome {
  win,     // player got three in a row
  loss,    // AI got three in a row
  draw,    // board full, nobody won
  timeout, // round timer ran out (counted as a draw, 0 points)
}

/// Per‑round result of a Tic‑Tac‑Toe challenge.
class TicTacToeRoundResult {
  /// 1-based round number (1–3).
  final int roundNumber;

  /// Difficulty the AI played at during this round.
  final TicTacToeDifficulty difficulty;

  /// How the round ended.
  final TicTacToeRoundOutcome outcome;

  /// Points earned for this round (0 unless the player won).
  final int score;

  /// Time remaining when the round ended, in milliseconds.
  final int remainingMs;

  /// The configured round time limit, in milliseconds.
  final int timeLimitMs;

  bool get isWin => outcome == TicTacToeRoundOutcome.win;
  bool get isDraw =>
      outcome == TicTacToeRoundOutcome.draw ||
      outcome == TicTacToeRoundOutcome.timeout;

  /// Time actually spent in this round, in milliseconds.
  int get elapsedMs => timeLimitMs - remainingMs;

  const TicTacToeRoundResult({
    required this.roundNumber,
    required this.difficulty,
    required this.outcome,
    required this.score,
    required this.remainingMs,
    required this.timeLimitMs,
  });
}
