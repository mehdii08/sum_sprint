import '../models/question.dart';

/// Pure scoring functions for the Tic‑Tac‑Toe challenge.
///
/// Per round:
///   - Player wins  → score scales with remaining time:
///       roundScore = round(maxPoints × remainingMs / timeLimitMs),
///       floored at [minWinRatio] × maxPoints so any win earns points.
///   - Loss / draw / timeout → 0 points.
///
/// Final challenge score = average of all round scores, so the
/// configured `maxPoints` is also the maximum total challenge score.
class TicTacToeScoring {
  /// A win always earns at least this fraction of `maxPoints`.
  static const double minWinRatio = 0.1;

  /// Calculate the score for a single round.
  static int calculateRoundScore({
    required TicTacToeRoundOutcome outcome,
    required int remainingMs,
    required int timeLimitMs,
    required int maxPoints,
  }) {
    if (outcome != TicTacToeRoundOutcome.win) return 0;
    if (timeLimitMs <= 0) return maxPoints;

    final ratio = (remainingMs / timeLimitMs).clamp(0.0, 1.0);
    final score = (maxPoints * ratio).round();
    final minScore = (maxPoints * minWinRatio).round();
    return score < minScore ? minScore : score;
  }

  /// Final challenge score: average of all round scores.
  static int calculateFinalScore(List<TicTacToeRoundResult> results) {
    if (results.isEmpty) return 0;
    final total = results.fold<int>(0, (sum, r) => sum + r.score);
    return (total / results.length).round();
  }
}
