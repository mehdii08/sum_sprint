import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/challenge_definition.dart';
import '../models/question.dart';
import '../models/result.dart';
import '../models/player_data.dart';
import '../services/pair_hunt_runner.dart';

/// States for the Pair‑Hunt game screen.
enum PairHuntState {
  intro,         // showing intro + Start button
  playing,       // active gameplay
  showingMismatch, // two blocks revealed, mismatched, holding for 1s
  finished,      // all pairs found or timer ran out
}

class PairHuntProvider extends ChangeNotifier {
  final PairHuntRunner _runner = PairHuntRunner();

  PairHuntState _state = PairHuntState.intro;
  int _timeRemainingSeconds = 0;
  int _totalTimeSeconds = 0;
  int _pairsFound = 0;
  int _mismatchCount = 0;
  int _totalPairs = 0;
  List<int> _revealedIndices = [];
  Set<int> _matchedIndices = {};
  bool _isLocked = false;
  PairHuntGameResult? _gameResult;
  Result? _finalResult;

  // Timers
  Timer? _gameTimer;
  Timer? _mismatchTimer;
  Stopwatch _stopwatch = Stopwatch();

  // ── Getters ──────────────────────────────────────────────────────

  PairHuntState get state => _state;
  int get timeRemainingSeconds => _timeRemainingSeconds;
  int get totalTimeSeconds => _totalTimeSeconds;
  int get pairsFound => _pairsFound;
  int get mismatchCount => _mismatchCount;
  int get totalPairs => _totalPairs;
  List<int> get revealedIndices => _revealedIndices;
  Set<int> get matchedIndices => _matchedIndices;
  bool get isLocked => _isLocked;
  PairHuntGameResult? get gameResult => _gameResult;
  Result? get finalResult => _finalResult;
  ChallengeDefinition? get currentChallenge => _runner.challengeDefinition;
  List<PairHuntBlock> get blocks => _runner.blocks;
  bool get isShowingMismatch => _state == PairHuntState.showingMismatch;

  double get timerProgress {
    if (_totalTimeSeconds == 0) return 1.0;
    return _timeRemainingSeconds / _totalTimeSeconds;
  }

  // ── Start challenge ──────────────────────────────────────────────

  void startChallenge(ChallengeDefinition challenge) {
    if (!challenge.isPairHunt) return;
    _runner.startGame(challenge);
    _totalTimeSeconds = challenge.timeLimitSeconds;
    _timeRemainingSeconds = challenge.timeLimitSeconds;
    _totalPairs = challenge.pairCount;
    _pairsFound = 0;
    _mismatchCount = 0;
    _revealedIndices = [];
    _matchedIndices = {};
    _isLocked = false;
    _gameResult = null;
    _finalResult = null;
    _state = PairHuntState.intro;
    notifyListeners();
  }

  // ── Start gameplay ───────────────────────────────────────────────

  void startPlaying() {
    if (_state != PairHuntState.intro) return;

    _state = PairHuntState.playing;
    _stopwatch = Stopwatch();
    _stopwatch.start();

    // Countdown timer, ticking every second.
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _timeRemainingSeconds--;
      if (_timeRemainingSeconds <= 0) {
        _timeRemainingSeconds = 0;
        _handleTimeout();
      }
      notifyListeners();
    });

    notifyListeners();
  }

  // ── Block tap ────────────────────────────────────────────────────

  void tapBlock(int index) {
    if (_state != PairHuntState.playing) return;
    if (_isLocked) return;
    if (!_runner.canFlip(index)) return;

    // Flip the block.
    _runner.flipBlock(index);
    _revealedIndices = _runner.revealedIndices;
    notifyListeners();

    // Check if two blocks are now revealed.
    if (_revealedIndices.length == 2) {
      final isMatch = _runner.checkMatch();
      if (isMatch == true) {
        _handleMatch();
      } else if (isMatch == false) {
        _handleMismatch();
      }
    }
  }

  void _handleMatch() {
    _isLocked = true;
    _runner.markMatch();
    _pairsFound = _runner.pairsFound;
    _revealedIndices = [];
    _matchedIndices = _blocksToMatchSet(_runner.blocks);
    _isLocked = false;
    notifyListeners();

    // Check if all pairs found.
    if (_runner.isFinished) {
      _finishGame();
    }
  }

  void _handleMismatch() {
    _isLocked = true;
    _state = PairHuntState.showingMismatch;
    notifyListeners();

    // After 1 second, flip blocks back.
    _mismatchTimer = Timer(const Duration(milliseconds: 1000), () {
      if (_state != PairHuntState.showingMismatch) return;
      _runner.resetMismatch();
      _mismatchCount = _runner.mismatchCount;
      _revealedIndices = [];
      _state = PairHuntState.playing;
      _isLocked = false;
      notifyListeners();
    });
  }

  void _handleTimeout() {
    _gameTimer?.cancel();
    _stopwatch.stop();
    _runner.endByTimeout();
    _finishGame();
  }

  void _finishGame() {
    _gameTimer?.cancel();
    _mismatchTimer?.cancel();
    _stopwatch.stop();

    final timeTaken = _stopwatch.elapsedMilliseconds / 1000.0;
    final clampedTime = timeTaken.clamp(0.0, _totalTimeSeconds.toDouble());
    _gameResult = _runner.getFinalGameResult(clampedTime);
    _state = PairHuntState.finished;
    notifyListeners();
  }

  Set<int> _blocksToMatchSet(List<PairHuntBlock> blocks) {
    return blocks.where((b) => b.isMatched).map((b) => b.index).toSet();
  }

  // ── Finalize ─────────────────────────────────────────────────────

  Result finalizeResult(PlayerData player) {
    if (_gameResult == null) {
      _finishGame();
    }
    _finalResult = _runner.getFinalResult(
      player,
      _gameResult?.timeTakenSeconds ?? _totalTimeSeconds.toDouble(),
    );
    return _finalResult!;
  }

  // ── Reset ────────────────────────────────────────────────────────

  void reset() {
    _gameTimer?.cancel();
    _mismatchTimer?.cancel();
    _stopwatch.stop();
    _state = PairHuntState.intro;
    _timeRemainingSeconds = 0;
    _totalTimeSeconds = 0;
    _pairsFound = 0;
    _mismatchCount = 0;
    _totalPairs = 0;
    _revealedIndices = [];
    _matchedIndices = {};
    _isLocked = false;
    _gameResult = null;
    _finalResult = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _mismatchTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }
}
