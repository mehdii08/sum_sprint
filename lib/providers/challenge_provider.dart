import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/challenge_definition.dart';
import '../models/question.dart';
import '../models/result.dart';
import '../models/player_data.dart';
import '../services/challenge_runner.dart';

enum GameState {
  idle,
  waitingForOptions, // 0.5s delay before options appear
  playing,           // options visible, timer running
  showingResult,     // showing correct/wrong/timeout visual feedback
  finished,          // all questions done
}

class ChallengeProvider extends ChangeNotifier {
  final ChallengeRunner _runner = ChallengeRunner();
  List<ChallengeDefinition> _challenges = [];
  GameState _gameState = GameState.idle;
  int _timeLeftMs = 0;
  int _totalTimePerQuestionMs = 0;
  bool _lastAnswerCorrect = false;
  bool _lastAnswerTimeout = false;
  int? _lastCorrectAnswer;
  Question? _displayQuestion; // cached question for display (not affected by advancement)
  int _displayQuestionIndex = 0; // 0-based index, lags behind runner during feedback
  Timer? _gameTimer;
  Timer? _delayTimer;
  bool _isLoadingChallenges = false;
  String? _loadError;
  Result? _finalResult;

  // Getters
  List<ChallengeDefinition> get challenges => _challenges;
  GameState get gameState => _gameState;
  ChallengeDefinition? get currentChallenge => _runner.challengeDefinition;
  Question? get currentQuestion => _displayQuestion;
  int get currentQuestionIndex => _displayQuestionIndex;
  int get totalQuestions => _runner.totalQuestions;
  int get timeLeftMs => _timeLeftMs;
  int get correctCount => _runner.correctCount;
  bool get lastAnswerCorrect => _lastAnswerCorrect;
  bool get lastAnswerTimeout => _lastAnswerTimeout;
  int? get lastCorrectAnswer => _lastCorrectAnswer;
  Result? get finalResult => _finalResult;
  bool get isLoadingChallenges => _isLoadingChallenges;
  String? get loadError => _loadError;
  double get timerProgress {
    if (_totalTimePerQuestionMs == 0) return 1.0;
    return _timeLeftMs / (_totalTimePerQuestionMs * 1000);
  }

  ChallengeProvider() {
    loadChallenges();
  }

  Future<void> loadChallenges() async {
    _isLoadingChallenges = true;
    _loadError = null;
    notifyListeners();

    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/challenges.json');
      _challenges = ChallengeDefinition.listFromJson(jsonString);
    } catch (e) {
      _loadError = 'Failed to load challenges: $e';
    }

    _isLoadingChallenges = false;
    notifyListeners();
  }

  void startChallenge(ChallengeDefinition challenge) {
    _runner.startChallenge(challenge);
    _finalResult = null;
    _totalTimePerQuestionMs = challenge.timePerQuestionSeconds * 1000;
    _beginQuestion();
  }

  void _beginQuestion() {
    _gameTimer?.cancel();
    _delayTimer?.cancel();

    // Cache the display question now, before any advancement
    _displayQuestion = _runner.getCurrentQuestion();
    _displayQuestionIndex = _runner.currentIndex;

    _gameState = GameState.waitingForOptions;
    _timeLeftMs = _totalTimePerQuestionMs;
    notifyListeners();

    // 0.5 second delay before options appear
    _delayTimer = Timer(const Duration(milliseconds: 500), () {
      _gameState = GameState.playing;
      _timeLeftMs = _totalTimePerQuestionMs;
      notifyListeners();

      // Start countdown timer, ticking every 50ms for smooth animation
      _gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        _timeLeftMs -= 50;
        if (_timeLeftMs <= 0) {
          _timeLeftMs = 0;
          _handleTimeout();
        }
        notifyListeners();
      });
    });
  }

  void _handleTimeout() {
    _gameTimer?.cancel();
    _lastCorrectAnswer = _displayQuestion?.correctAnswer;
    _lastAnswerCorrect = false;
    _lastAnswerTimeout = true;
    _runner.recordTimeout();
    _gameState = GameState.showingResult;
    notifyListeners();

    _delayTimer = Timer(const Duration(milliseconds: 500), () {
      _advanceOrFinish();
    });
  }

  void answerQuestion(int selectedValue) {
    if (_gameState != GameState.playing) return;

    _gameTimer?.cancel();

    // Capture correct answer before advancing to next question
    _lastCorrectAnswer = _displayQuestion?.correctAnswer;

    final elapsedMs = _totalTimePerQuestionMs - _timeLeftMs;
    final isCorrect = _runner.answerSelected(selectedValue, elapsedMs);

    _lastAnswerCorrect = isCorrect;
    _lastAnswerTimeout = false;
    _gameState = GameState.showingResult;
    notifyListeners();

    _delayTimer = Timer(const Duration(milliseconds: 500), () {
      _advanceOrFinish();
    });
  }

  void _advanceOrFinish() {
    if (_runner.isFinished) {
      _gameState = GameState.finished;
      notifyListeners();
    } else {
      _beginQuestion();
    }
  }

  Result finalizeResult(PlayerData player) {
    _finalResult = _runner.getFinalResult(player);
    return _finalResult!;
  }

  void reset() {
    _gameTimer?.cancel();
    _delayTimer?.cancel();
    _gameState = GameState.idle;
    _timeLeftMs = 0;
    _totalTimePerQuestionMs = 0;
    _lastAnswerCorrect = false;
    _lastAnswerTimeout = false;
    _lastCorrectAnswer = null;
    _displayQuestion = null;
    _displayQuestionIndex = 0;
    _finalResult = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _delayTimer?.cancel();
    super.dispose();
  }
}
