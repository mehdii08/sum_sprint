import 'dart:math';
import '../models/question.dart';

/// Pure scoring functions for the Mind‑Timer challenge.
///
/// Formula (from spec):
///   accuracy = 1.0 - (absoluteDifference / range)
///   points   = round(maxPoints × accuracy)
///
/// Outside the range → 0 points.
class MindTimerScoring {
  /// Calculate the score for a single Mind‑Timer stop.
  static MindTimerResult calculate({
    required double actualSeconds,
    required double targetSeconds,
    required double rangeSeconds,
    required int maxPoints,
  }) {
    final absoluteDifference = (actualSeconds - targetSeconds).abs();

    // Outside the valid range → 0 points
    if (absoluteDifference >= rangeSeconds - 0.0001) {
      return MindTimerResult(
        actualSeconds: actualSeconds,
        absoluteDifference: absoluteDifference,
        points: 0,
        accuracy: 0.0,
        rangeSeconds: rangeSeconds,
      );
    }

    final accuracy = 1.0 - (absoluteDifference / rangeSeconds);
    final points = (maxPoints * accuracy).round();

    return MindTimerResult(
      actualSeconds: actualSeconds,
      absoluteDifference: absoluteDifference,
      points: max(0, min(maxPoints, points)),
      accuracy: accuracy.clamp(0.0, 1.0),
      rangeSeconds: rangeSeconds,
    );
  }

  /// Compute the total score from a list of per‑question results.
  static int calculateTotal(List<MindTimerResult> results) {
    return results.fold(0, (sum, r) => sum + r.points);
  }

  /// Human‑readable feedback label based on accuracy.
  static String feedbackLabel(double accuracy) {
    if (accuracy >= 0.95) return 'perfect';
    if (accuracy >= 0.80) return 'amazing';
    if (accuracy >= 0.60) return 'great';
    if (accuracy >= 0.40) return 'close';
    if (accuracy >= 0.20) return 'almost';
    if (accuracy > 0.0) return 'far';
    return 'miss';
  }
}
