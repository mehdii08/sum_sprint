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
