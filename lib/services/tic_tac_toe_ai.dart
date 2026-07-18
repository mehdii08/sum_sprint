import 'dart:math';
import '../models/question.dart';

/// Pure board utilities for 3x3 Tic‑Tac‑Toe.
///
/// The board is a flat list of 9 [TicTacToeMark]s, indexed row-major:
///
///   0 | 1 | 2
///   ──┼───┼──
///   3 | 4 | 5
///   ──┼───┼──
///   6 | 7 | 8
class TicTacToeBoard {
  TicTacToeBoard._();

  static const int cellCount = 9;

  /// All 8 possible winning lines (rows, columns, diagonals).
  static const List<List<int>> winningLines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
    [0, 4, 8], [2, 4, 6],            // diagonals
  ];

  /// Create a fresh empty board.
  static List<TicTacToeMark> empty() =>
      List.filled(cellCount, TicTacToeMark.none);

  /// Indices of all empty cells.
  static List<int> availableCells(List<TicTacToeMark> board) {
    final cells = <int>[];
    for (var i = 0; i < board.length; i++) {
      if (board[i] == TicTacToeMark.none) cells.add(i);
    }
    return cells;
  }

  /// Whether every cell is occupied.
  static bool isFull(List<TicTacToeMark> board) =>
      !board.contains(TicTacToeMark.none);

  /// The mark that owns a completed line, or null if nobody won yet.
  static TicTacToeMark? findWinner(List<TicTacToeMark> board) {
    for (final line in winningLines) {
      final mark = board[line[0]];
      if (mark != TicTacToeMark.none &&
          mark == board[line[1]] &&
          mark == board[line[2]]) {
        return mark;
      }
    }
    return null;
  }

  /// The completed line (3 cell indices), or null if nobody won yet.
  static List<int>? findWinningLine(List<TicTacToeMark> board) {
    for (final line in winningLines) {
      final mark = board[line[0]];
      if (mark != TicTacToeMark.none &&
          mark == board[line[1]] &&
          mark == board[line[2]]) {
        return line;
      }
    }
    return null;
  }
}

/// AI opponent for the Tic‑Tac‑Toe challenge.
///
/// Each [TicTacToeDifficulty] maps to a dedicated strategy so levels
/// can be tuned independently:
///
/// - **easy**   → plays a random empty cell.
/// - **medium** → takes an immediate win, otherwise blocks the player's
///                immediate win, otherwise plays randomly.
/// - **hard**   → plays the optimal minimax move, with a small
///                [hardSlipChance] of falling back to the medium
///                heuristic so winning stays possible.
class TicTacToeAi {
  final Random _random;

  TicTacToeAi({Random? random}) : _random = random ?? Random();

  /// Chance (0.0–1.0) that the hard AI plays a heuristic move instead of
  /// the optimal minimax move. Increase to make round 3 easier to beat.
  static const double hardSlipChance = 0.15;

  /// Pick the AI's next move for [board] at the given [difficulty].
  ///
  /// Returns the chosen cell index (0–8).
  /// Throws [StateError] if the board has no empty cell.
  int chooseMove(List<TicTacToeMark> board, TicTacToeDifficulty difficulty) {
    if (TicTacToeBoard.availableCells(board).isEmpty) {
      throw StateError('No available cells to play');
    }
    switch (difficulty) {
      case TicTacToeDifficulty.easy:
        return _easyMove(board);
      case TicTacToeDifficulty.medium:
        return _mediumMove(board);
      case TicTacToeDifficulty.hard:
        return _hardMove(board);
    }
  }

  // ── Easy: random ─────────────────────────────────────────────────

  int _easyMove(List<TicTacToeMark> board) {
    final cells = TicTacToeBoard.availableCells(board);
    return cells[_random.nextInt(cells.length)];
  }

  // ── Medium: win > block > random ─────────────────────────────────

  int _mediumMove(List<TicTacToeMark> board) {
    // 1. Win immediately if possible.
    final winMove = _findCompletingMove(board, TicTacToeMark.ai);
    if (winMove != null) return winMove;

    // 2. Block the player's immediate win.
    final blockMove = _findCompletingMove(board, TicTacToeMark.player);
    if (blockMove != null) return blockMove;

    // 3. Otherwise play randomly.
    return _easyMove(board);
  }

  /// Find a cell that completes a line for [mark], or null.
  int? _findCompletingMove(List<TicTacToeMark> board, TicTacToeMark mark) {
    for (final cell in TicTacToeBoard.availableCells(board)) {
      board[cell] = mark;
      final wins = TicTacToeBoard.findWinner(board) == mark;
      board[cell] = TicTacToeMark.none;
      if (wins) return cell;
    }
    return null;
  }

  // ── Hard: minimax with a small slip chance ───────────────────────

  int _hardMove(List<TicTacToeMark> board) {
    if (_random.nextDouble() < hardSlipChance) {
      return _mediumMove(board);
    }
    return _minimaxBestMove(board);
  }

  int _minimaxBestMove(List<TicTacToeMark> board) {
    var bestScore = -1000;
    var bestMoves = <int>[];

    for (final cell in TicTacToeBoard.availableCells(board)) {
      board[cell] = TicTacToeMark.ai;
      final score = _minimax(board, 0, false);
      board[cell] = TicTacToeMark.none;

      if (score > bestScore) {
        bestScore = score;
        bestMoves = [cell];
      } else if (score == bestScore) {
        bestMoves.add(cell);
      }
    }
    // Pick randomly among equally good moves for variety.
    return bestMoves[_random.nextInt(bestMoves.length)];
  }

  /// Classic minimax. The AI maximizes; the player minimizes.
  /// Depth is used to prefer faster wins and slower losses.
  int _minimax(List<TicTacToeMark> board, int depth, bool isMaximizing) {
    final winner = TicTacToeBoard.findWinner(board);
    if (winner == TicTacToeMark.ai) return 10 - depth;
    if (winner == TicTacToeMark.player) return depth - 10;
    if (TicTacToeBoard.isFull(board)) return 0;

    if (isMaximizing) {
      var best = -1000;
      for (final cell in TicTacToeBoard.availableCells(board)) {
        board[cell] = TicTacToeMark.ai;
        best = max(best, _minimax(board, depth + 1, false));
        board[cell] = TicTacToeMark.none;
      }
      return best;
    } else {
      var best = 1000;
      for (final cell in TicTacToeBoard.availableCells(board)) {
        board[cell] = TicTacToeMark.player;
        best = min(best, _minimax(board, depth + 1, true));
        board[cell] = TicTacToeMark.none;
      }
      return best;
    }
  }
}
