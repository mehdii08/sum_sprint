import 'dart:math';
import '../models/question.dart';

/// Pure scoring functions for the Pair‑Hunt challenge.
///
/// Formula:
///   basePoints      = pairsFound × pointsPerPair
///   timeBonus       = (timeRemaining / totalTime) × maxTimeBonus
///   mismatchPenalty = mismatches × penaltyPerMismatch
///   totalPoints     = max(0, basePoints + timeBonus - mismatchPenalty)
class PairHuntScoring {
  /// Calculate the final score for a Pair Hunt game.
  static PairHuntGameResult calculate({
    required int pairsFound,
    required int totalPairs,
    required int mismatchCount,
    required double timeTakenSeconds,
    required double timeLimitSeconds,
    required int pointsPerPair,
    required int maxTimeBonus,
    required int penaltyPerMismatch,
  }) {
    final basePoints = pairsFound * pointsPerPair;

    // If timer ran out, remaining time is 0 → no time bonus.
    final timeRemaining = max(0.0, timeLimitSeconds - timeTakenSeconds);
    final timeBonusRatio = timeLimitSeconds > 0
        ? timeRemaining / timeLimitSeconds
        : 0.0;
    final timeBonus = (timeBonusRatio * maxTimeBonus).round();

    final mismatchPenalty = mismatchCount * penaltyPerMismatch;
    final totalScore = max(0, basePoints + timeBonus - mismatchPenalty);

    return PairHuntGameResult(
      score: totalScore,
      pairsFound: pairsFound,
      totalPairs: totalPairs,
      mismatchCount: mismatchCount,
      timeTakenSeconds: timeTakenSeconds,
      timeLimitSeconds: timeLimitSeconds,
    );
  }
}
