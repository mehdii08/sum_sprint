import '../models/challenge_definition.dart';
import '../models/question.dart';
import '../models/result.dart';
import '../models/player_data.dart';
import 'question_generator.dart';
import 'score_calculator.dart';

class ChallengeRunner {
  final QuestionGenerator _generator = QuestionGenerator();
  
  ChallengeDefinition? _challengeDefinition;
  final List<Question> _questions = [];
  final List<QuestionResult> _results = [];
  int _currentIndex = 0;

  bool get isActive => _challengeDefinition != null && !isFinished;
  bool get isFinished => _challengeDefinition != null && _currentIndex >= _challengeDefinition!.questionCount;
  int get currentIndex => _currentIndex;
  int get totalQuestions => _challengeDefinition?.questionCount ?? 0;
  int get correctCount => _results.where((r) => r.isCorrect).length;

  ChallengeDefinition? get challengeDefinition => _challengeDefinition;

  void startChallenge(ChallengeDefinition challenge) {
    _challengeDefinition = challenge;
    _questions.clear();
    _results.clear();
    _currentIndex = 0;

    // Pre-generate all questions
    for (int i = 0; i < challenge.questionCount; i++) {
      _questions.add(_generator.generate(challenge));
    }

  }

  Question? getCurrentQuestion() {
    if (_currentIndex >= _questions.length) return null;
    return _questions[_currentIndex];
  }

  /// Records the answer and advances to next question.
  /// [selectedValue] is the value the user tapped.
  /// [elapsedMs] is time since question was presented.
  /// Returns whether the answer was correct.
  bool answerSelected(int selectedValue, int elapsedMs) {
    final question = getCurrentQuestion();
    if (question == null) return false;

    final isCorrect = selectedValue == question.correctAnswer;
    final clampedElapsedMs = elapsedMs.clamp(
      0,
      _challengeDefinition!.timePerQuestionSeconds * 1000,
    );

    _results.add(QuestionResult(
      isCorrect: isCorrect,
      responseTimeMs: clampedElapsedMs,
    ));

    _currentIndex++;
    return isCorrect;
  }

  /// Records a timeout (no answer selected).
  void recordTimeout() {
    final question = getCurrentQuestion();
    if (question == null) return;

    _results.add(QuestionResult(
      isCorrect: false,
      responseTimeMs: _challengeDefinition!.timePerQuestionSeconds * 1000,
    ));

    _currentIndex++;
  }

  Result getFinalResult(PlayerData player) {
    if (_challengeDefinition == null) {
      throw StateError('No challenge has been started');
    }

    final totalScore = ScoreCalculator.calculateTotal(
      _results,
      _challengeDefinition!.timePerQuestionSeconds,
    );

    final totalResponseTimeMs =
        _results.fold<int>(0, (sum, r) => sum + r.responseTimeMs);

    return Result(
      challengeId: _challengeDefinition!.id,
      score: totalScore,
      correctCount: correctCount,
      totalResponseTimeMs: totalResponseTimeMs,
      date: DateTime.now(),
      playerName: player.nickname,
    );
  }
}
