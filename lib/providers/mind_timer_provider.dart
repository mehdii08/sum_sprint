import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/challenge_definition.dart';
import '../models/question.dart';
import '../models/result.dart';
import '../models/player_data.dart';
import '../services/mind_timer_runner.dart';

/// States for the Mind‑Timer game screen.
enum MindTimerState {
  ready,      // showing target + Start button
  counting,   // hidden timer is running, Stop button visible
  showingResult, // showing actual time + points + feedback
  finished,   // all questions done
}

class MindTimerProvider extends ChangeNotifier {
  final MindTimerRunner _runner = MindTimerRunner();

  MindTimerState _state = MindTimerState.ready;
  MindTimerResult? _lastResult;
  Result? _finalResult;
  int _questionIndex = 0; // 1‑based for display
  int _totalQuestions = 0;

  // Precision timer
  Stopwatch _stopwatch = Stopwatch();
  Timer? _displayTick; // updates UI every 50ms while counting (only for internal use, not shown)

  // ── Getters ──────────────────────────────────────────────────────

  MindTimerState get state => _state;
  MindTimerResult? get lastResult => _lastResult;
  Result? get finalResult => _finalResult;
  int get questionIndex => _questionIndex;
  int get totalQuestions => _totalQuestions;
  int get runningScore => _runner.totalScore;
  ChallengeDefinition? get currentChallenge => _runner.challengeDefinition;
  MindTimerQuestion? get currentQuestion => _runner.getCurrentQuestion();

  double get elapsedSeconds => _stopwatch.elapsedMilliseconds / 1000.0;

  // ── Start challenge ──────────────────────────────────────────────

  void startChallenge(ChallengeDefinition challenge) {
    if (!challenge.isMindTimer) return;
    _runner.startChallenge(challenge);
    _totalQuestions = challenge.questionCount;
    _state = MindTimerState.ready;
    _lastResult = null;
    _finalResult = null;
    _questionIndex = 1;
    _beginRound();
  }

  void _beginRound() {
    _state = MindTimerState.ready;
    _lastResult = null;
    _stopwatch = Stopwatch();
    _displayTick?.cancel();
    notifyListeners();
  }

  // ── Start counting ───────────────────────────────────────────────

  void startCounting() {
    if (_state != MindTimerState.ready) return;

    _state = MindTimerState.counting;
    _stopwatch.start();

    // Tick for internal updates (not shown to user, but keeps the
    // provider alive so the app bar can show elapsed if needed)
    _displayTick = Timer.periodic(const Duration(milliseconds: 50), (_) {
      notifyListeners();
    });

    notifyListeners();
  }

  // ── Stop counting ────────────────────────────────────────────────

  void stopCounting() {
    if (_state != MindTimerState.counting) return;

    _stopwatch.stop();
    _displayTick?.cancel();

    final actualSeconds = _stopwatch.elapsedMilliseconds / 1000.0;
    _lastResult = _runner.recordStop(actualSeconds);

    _state = MindTimerState.showingResult;
    notifyListeners();

    // Auto‑advance after 2.5 seconds so the user can read feedback
    Timer(const Duration(milliseconds: 2500), () {
      if (!_runner.isFinished) {
        _questionIndex++;
        _beginRound();
      } else {
        _state = MindTimerState.finished;
        notifyListeners();
      }
    });
  }

  // ── Finalize ─────────────────────────────────────────────────────

  Result finalizeResult(PlayerData player) {
    _finalResult = _runner.getFinalResult(player);
    return _finalResult!;
  }

  // ── Reset ────────────────────────────────────────────────────────

  void reset() {
    _displayTick?.cancel();
    _stopwatch.stop();
    _state = MindTimerState.ready;
    _lastResult = null;
    _finalResult = null;
    _questionIndex = 0;
    _totalQuestions = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _displayTick?.cancel();
    _stopwatch.stop();
    super.dispose();
  }
}
