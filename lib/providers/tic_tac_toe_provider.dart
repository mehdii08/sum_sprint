import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/challenge_definition.dart';
import '../models/question.dart';
import '../models/result.dart';
import '../models/player_data.dart';
import '../services/tic_tac_toe_runner.dart';

/// States for the Tic‑Tac‑Toe game screen.
enum TicTacToeState {
  intro,              // showing intro + Start button
  playerTurn,         // waiting for the player to tap a cell
  aiThinking,         // AI "thinking" delay before its move
  showingRoundResult, // round ended, showing the round result overlay
  finished,           // all rounds done
}

class TicTacToeProvider extends ChangeNotifier {
  final TicTacToeRunner _runner = TicTacToeRunner();
  final Random _random = Random();

  /// Round timer tick interval.
  static const int _tickIntervalMs = 100;

  /// AI "thinking" delay range (min + random extra), for a natural feel.
  static const int _aiThinkMinMs = 400;
  static const int _aiThinkExtraMs = 400;

  /// How long the round result overlay stays before the next round.
  static const int _roundResultDurationMs = 2200;

  TicTacToeState _state = TicTacToeState.intro;
  int _remainingMs = 0;
  int _timeLimitMs = 0;
  TicTacToeRoundResult? _lastRoundResult;
  List<int>? _winningLine;
  int? _lastAiMoveIndex;
  Result? _finalResult;

  // Timers
  Timer? _tickTimer;
  Timer? _aiTimer;
  Timer? _roundEndTimer;

  // ── Getters ──────────────────────────────────────────────────────

  TicTacToeState get state => _state;
  int get remainingMs => _remainingMs;
  int get remainingSeconds => (_remainingMs / 1000).ceil();
  int get timeLimitMs => _timeLimitMs;
  List<TicTacToeMark> get board => _runner.board;
  int get currentRoundNumber => _runner.currentRoundNumber;
  int get totalRounds => TicTacToeRunner.roundsPerChallenge;
  TicTacToeDifficulty get currentDifficulty => _runner.currentDifficulty;
  List<TicTacToeRoundResult> get roundResults => _runner.results;
  TicTacToeRoundResult? get lastRoundResult => _lastRoundResult;
  List<int>? get winningLine => _winningLine;
  int? get lastAiMoveIndex => _lastAiMoveIndex;
  int get totalRoundScore => _runner.totalRoundScore;
  int get finalScore => _runner.finalScore;
  Result? get finalResult => _finalResult;
  ChallengeDefinition? get currentChallenge => _runner.challengeDefinition;
  bool get isPlayerTurn => _state == TicTacToeState.playerTurn;
  bool get isAiThinking => _state == TicTacToeState.aiThinking;

  double get timerProgress {
    if (_timeLimitMs == 0) return 1.0;
    return _remainingMs / _timeLimitMs;
  }

  // ── Start challenge ──────────────────────────────────────────────

  void startChallenge(ChallengeDefinition challenge) {
    if (!challenge.isTicTacToe) return;
    _cancelTimers();
    _runner.startChallenge(challenge);
    _timeLimitMs = challenge.timeLimitSeconds * 1000;
    _remainingMs = _timeLimitMs;
    _lastRoundResult = null;
    _winningLine = null;
    _lastAiMoveIndex = null;
    _finalResult = null;
    _state = TicTacToeState.intro;
    notifyListeners();
  }

  // ── Start gameplay ───────────────────────────────────────────────

  void startPlaying() {
    if (_state != TicTacToeState.intro) return;
    _startRound();
  }

  void _startRound() {
    _runner.startRound();
    _remainingMs = _timeLimitMs;
    _winningLine = null;
    _lastAiMoveIndex = null;
    _lastRoundResult = null;
    _state = TicTacToeState.playerTurn;

    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(
      const Duration(milliseconds: _tickIntervalMs),
      (_) {
        _remainingMs -= _tickIntervalMs;
        if (_remainingMs <= 0) {
          _remainingMs = 0;
          _handleTimeout();
          return;
        }
        notifyListeners();
      },
    );

    notifyListeners();
  }

  // ── Player move ──────────────────────────────────────────────────

  void tapCell(int index) {
    if (_state != TicTacToeState.playerTurn) return;
    if (!_runner.canPlaceAt(index)) return;

    _runner.placePlayerMark(index);
    notifyListeners();

    // Did the player just win, or fill the board?
    if (_runner.findWinner() == TicTacToeMark.player) {
      _endRound(TicTacToeRoundOutcome.win);
      return;
    }
    if (_runner.isBoardFull) {
      _endRound(TicTacToeRoundOutcome.draw);
      return;
    }

    // Hand over to the AI after a short "thinking" delay.
    _state = TicTacToeState.aiThinking;
    notifyListeners();

    final thinkMs = _aiThinkMinMs + _random.nextInt(_aiThinkExtraMs);
    _aiTimer = Timer(Duration(milliseconds: thinkMs), _performAiMove);
  }

  // ── AI move ──────────────────────────────────────────────────────

  void _performAiMove() {
    if (_state != TicTacToeState.aiThinking) return;

    _lastAiMoveIndex = _runner.placeAiMark();
    notifyListeners();

    if (_runner.findWinner() == TicTacToeMark.ai) {
      _endRound(TicTacToeRoundOutcome.loss);
      return;
    }
    if (_runner.isBoardFull) {
      _endRound(TicTacToeRoundOutcome.draw);
      return;
    }

    _state = TicTacToeState.playerTurn;
    notifyListeners();
  }

  // ── Round end ────────────────────────────────────────────────────

  void _handleTimeout() {
    if (_state != TicTacToeState.playerTurn &&
        _state != TicTacToeState.aiThinking) {
      return;
    }
    _endRound(TicTacToeRoundOutcome.timeout);
  }

  void _endRound(TicTacToeRoundOutcome outcome) {
    _tickTimer?.cancel();
    _aiTimer?.cancel();

    _lastRoundResult = _runner.recordRoundResult(
      outcome: outcome,
      remainingMs: _remainingMs,
    );
    _winningLine = outcome == TicTacToeRoundOutcome.win ||
            outcome == TicTacToeRoundOutcome.loss
        ? _runner.winningLine
        : null;
    _state = TicTacToeState.showingRoundResult;
    notifyListeners();

    _roundEndTimer = Timer(
      const Duration(milliseconds: _roundResultDurationMs),
      () {
        if (_state != TicTacToeState.showingRoundResult) return;
        if (_runner.isFinished) {
          _state = TicTacToeState.finished;
          notifyListeners();
        } else {
          _startRound();
        }
      },
    );
  }

  // ── Finalize ─────────────────────────────────────────────────────

  Result finalizeResult(PlayerData player) {
    _finalResult = _runner.getFinalResult(player);
    return _finalResult!;
  }

  // ── Reset ────────────────────────────────────────────────────────

  void reset() {
    _cancelTimers();
    _state = TicTacToeState.intro;
    _remainingMs = 0;
    _timeLimitMs = 0;
    _lastRoundResult = null;
    _winningLine = null;
    _lastAiMoveIndex = null;
    _finalResult = null;
    notifyListeners();
  }

  void _cancelTimers() {
    _tickTimer?.cancel();
    _aiTimer?.cancel();
    _roundEndTimer?.cancel();
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}
