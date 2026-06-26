import '../models/challenge_definition.dart';
import '../models/question.dart';
import '../models/result.dart';
import '../models/player_data.dart';
import 'mind_timer_scoring.dart';

/// Orchestrates a single Mind‑Timer challenge session.
///
/// Unlike [ChallengeRunner] (math), this runner doesn't pre‑generate
/// questions — each round is identical except the user's performance varies.
/// The "questions" are generated on‑demand as the user plays.
class MindTimerRunner {
  ChallengeDefinition? _challengeDefinition;
  final List<MindTimerResult> _results = [];
  int _currentIndex = 0;

  bool get isActive => _challengeDefinition != null && !isFinished;
  bool get isFinished =>
      _challengeDefinition != null &&
      _currentIndex >= _challengeDefinition!.questionCount;
  int get currentIndex => _currentIndex;
  int get totalQuestions => _challengeDefinition?.questionCount ?? 0;
  int get withinRangeCount =>
      _results.where((r) => r.isWithinRange).length;
  int get totalScore => MindTimerScoring.calculateTotal(_results);

  ChallengeDefinition? get challengeDefinition => _challengeDefinition;

  /// Start a new Mind‑Timer challenge.
  void startChallenge(ChallengeDefinition challenge) {
    if (!challenge.isMindTimer) {
      throw ArgumentError(
        'MindTimerRunner requires a mind_timer challenge, '
        'got type="${challenge.challengeType.value}".',
      );
    }
    _challengeDefinition = challenge;
    _results.clear();
    _currentIndex = 0;
  }

  /// Get the current question definition (target, range, maxPoints).
  MindTimerQuestion? getCurrentQuestion() {
    if (_challengeDefinition == null || isFinished) return null;
    final c = _challengeDefinition!;
    return MindTimerQuestion(
      targetSeconds: c.targetSeconds,
      rangeSeconds: c.rangeSeconds,
      maxPoints: c.maxPoints,
    );
  }

  /// Record the user's stop and advance to the next question.
  ///
  /// [actualSeconds] is the precise elapsed time when the user tapped Stop.
  /// Returns the [MindTimerResult] for this attempt.
  MindTimerResult recordStop(double actualSeconds) {
    final c = _challengeDefinition!;
    final result = MindTimerScoring.calculate(
      actualSeconds: actualSeconds,
      targetSeconds: c.targetSeconds,
      rangeSeconds: c.rangeSeconds,
      maxPoints: c.maxPoints,
    );
    _results.add(result);
    _currentIndex++;
    return result;
  }

  /// Build the final [Result] for offline storage / competition submission.
  Result getFinalResult(PlayerData player) {
    final c = _challengeDefinition;
    if (c == null) throw StateError('No challenge has been started');

    final totalMs = _results
        .fold<double>(0, (sum, r) => sum + r.actualSeconds) * 1000;
    final avgAccuracy = _results.isEmpty
        ? 0.0
        : _results.fold<double>(0, (sum, r) => sum + r.accuracy) /
            _results.length;

    return Result(
      challengeId: c.id,
      score: totalScore,
      correctCount: withinRangeCount,
      totalResponseTimeMs: totalMs.round(),
      date: DateTime.now(),
      playerName: player.nickname,
      withinRangeCount: withinRangeCount,
      averageAccuracy: avgAccuracy,
      isMindTimer: true,
    );
  }
}
