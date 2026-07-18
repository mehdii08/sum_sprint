import '../models/challenge_definition.dart';
import '../models/question.dart';
import '../models/result.dart';
import '../models/player_data.dart';
import 'tic_tac_toe_ai.dart';
import 'tic_tac_toe_scoring.dart';

/// Orchestrates a single Tic‑Tac‑Toe challenge session.
///
/// A challenge consists of [roundsPerChallenge] independent rounds against
/// the AI, each with an increasing difficulty ([roundDifficulties]).
/// The player is always [TicTacToeMark.player] (X) and moves first;
/// the AI is [TicTacToeMark.ai] (O).
///
/// The final challenge score is the average of the round scores
/// (see [TicTacToeScoring]).
class TicTacToeRunner {
  /// Number of rounds in a challenge. Round N uses [roundDifficulties][N-1].
  static const int roundsPerChallenge = 3;

  /// Difficulty progression across rounds: Easy → Medium → Hard.
  static const List<TicTacToeDifficulty> roundDifficulties = [
    TicTacToeDifficulty.easy,
    TicTacToeDifficulty.medium,
    TicTacToeDifficulty.hard,
  ];

  final TicTacToeAi _ai;

  TicTacToeRunner({TicTacToeAi? ai}) : _ai = ai ?? TicTacToeAi();

  ChallengeDefinition? _challengeDefinition;
  List<TicTacToeMark> _board = TicTacToeBoard.empty();
  final List<TicTacToeRoundResult> _results = [];

  /// 0-based index of the round currently being played.
  int _currentRoundIndex = 0;

  // ── Getters ──────────────────────────────────────────────────────

  ChallengeDefinition? get challengeDefinition => _challengeDefinition;
  List<TicTacToeMark> get board => _board;
  List<TicTacToeRoundResult> get results => List.unmodifiable(_results);

  /// 1-based number of the current round (1–3).
  int get currentRoundNumber => _currentRoundIndex + 1;

  /// Difficulty of the round currently being played.
  TicTacToeDifficulty get currentDifficulty =>
      roundDifficulties[_currentRoundIndex.clamp(0, roundsPerChallenge - 1)];

  bool get isFinished => _results.length >= roundsPerChallenge;

  int get roundsWon => _results.where((r) => r.isWin).length;
  int get roundsDrawn => _results.where((r) => r.isDraw).length;

  /// Final challenge score: average of round scores.
  int get finalScore => TicTacToeScoring.calculateFinalScore(_results);

  /// Sum of round scores so far (for the in-game running display).
  int get totalRoundScore =>
      _results.fold<int>(0, (sum, r) => sum + r.score);

  // ── Start challenge / round ──────────────────────────────────────

  void startChallenge(ChallengeDefinition challenge) {
    if (!challenge.isTicTacToe) {
      throw ArgumentError(
        'TicTacToeRunner requires a tic_tac_toe challenge, '
        'got type="${challenge.challengeType.value}".',
      );
    }
    _challengeDefinition = challenge;
    _results.clear();
    _currentRoundIndex = 0;
    _board = TicTacToeBoard.empty();
  }

  /// Reset the board for the current round.
  void startRound() {
    _board = TicTacToeBoard.empty();
  }

  // ── Moves ────────────────────────────────────────────────────────

  /// Whether the player can place a mark at [index].
  bool canPlaceAt(int index) {
    if (index < 0 || index >= TicTacToeBoard.cellCount) return false;
    return _board[index] == TicTacToeMark.none;
  }

  /// Place the player's mark at [index].
  void placePlayerMark(int index) {
    if (!canPlaceAt(index)) return;
    _board[index] = TicTacToeMark.player;
  }

  /// Let the AI choose and place its mark using the current round's
  /// difficulty. Returns the chosen cell index.
  int placeAiMark() {
    final move = _ai.chooseMove(_board, currentDifficulty);
    _board[move] = TicTacToeMark.ai;
    return move;
  }

  // ── Board state ──────────────────────────────────────────────────

  /// The mark that completed a line, or null if nobody won yet.
  TicTacToeMark? findWinner() => TicTacToeBoard.findWinner(_board);

  /// The winning line (3 cell indices), or null.
  List<int>? get winningLine => TicTacToeBoard.findWinningLine(_board);

  bool get isBoardFull => TicTacToeBoard.isFull(_board);

  // ── Round completion ─────────────────────────────────────────────

  /// Record the outcome of the current round and advance to the next.
  ///
  /// [remainingMs] is the time left on the round timer when it ended.
  /// Returns the [TicTacToeRoundResult] for this round.
  TicTacToeRoundResult recordRoundResult({
    required TicTacToeRoundOutcome outcome,
    required int remainingMs,
  }) {
    final c = _challengeDefinition;
    if (c == null) throw StateError('No challenge has been started');

    final timeLimitMs = c.timeLimitSeconds * 1000;
    final clampedRemaining = remainingMs.clamp(0, timeLimitMs);
    final score = TicTacToeScoring.calculateRoundScore(
      outcome: outcome,
      remainingMs: clampedRemaining,
      timeLimitMs: timeLimitMs,
      maxPoints: c.maxPoints,
    );

    final result = TicTacToeRoundResult(
      roundNumber: currentRoundNumber,
      difficulty: currentDifficulty,
      outcome: outcome,
      score: score,
      remainingMs: clampedRemaining,
      timeLimitMs: timeLimitMs,
    );
    _results.add(result);
    if (!isFinished) _currentRoundIndex++;
    return result;
  }

  // ── Final result ─────────────────────────────────────────────────

  /// Build the final [Result] for offline storage / competition submission.
  Result getFinalResult(PlayerData player) {
    final c = _challengeDefinition;
    if (c == null) throw StateError('No challenge has been started');

    final totalMs =
        _results.fold<int>(0, (sum, r) => sum + r.elapsedMs);

    return Result(
      challengeId: c.id,
      score: finalScore,
      correctCount: roundsWon,
      totalResponseTimeMs: totalMs,
      date: DateTime.now(),
      playerName: player.nickname,
      isTicTacToe: true,
      roundsWon: roundsWon,
      roundsDrawn: roundsDrawn,
      totalRounds: _results.length,
    );
  }
}
