import 'dart:math';
import '../models/question.dart';

class ScoreCalculator {
  /// Calculate score for a single question based on remaining time.
  /// Formula: 100 + (remainingTimeSeconds * 20), minimum 10 points if correct.
  static int calculateForQuestion(int remainingTimeMs, int totalTimePerQuestionMs) {
    if (remainingTimeMs <= 0) return 0;

    final double remainingSeconds = remainingTimeMs / 1000.0;
    final int score = 100 + (remainingSeconds * 20).round();
    return max(10, score);
  }

  /// Calculate total score from all question results.
  /// Adds 200 bonus if all questions are correct.
  static int calculateTotal(
    List<QuestionResult> results,
    int totalTimePerQuestionMs,
  ) {
    if (results.isEmpty) return 0;

    int totalScore = 0;
    for (final result in results) {
      if (result.isCorrect) {
        totalScore += calculateForQuestion(
          totalTimePerQuestionMs * 1000 - result.responseTimeMs,
          totalTimePerQuestionMs,
        );
      }
    }

    // Perfect bonus
    if (results.every((r) => r.isCorrect)) {
      totalScore += 200;
    }

    return totalScore;
  }
}
