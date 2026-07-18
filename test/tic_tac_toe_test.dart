import 'package:flutter_test/flutter_test.dart';
import 'package:sum_sprint/models/challenge_definition.dart';
import 'package:sum_sprint/models/player_data.dart';
import 'package:sum_sprint/models/question.dart';
import 'package:sum_sprint/services/tic_tac_toe_ai.dart';
import 'package:sum_sprint/services/tic_tac_toe_runner.dart';
import 'package:sum_sprint/services/tic_tac_toe_scoring.dart';

ChallengeDefinition _ticTacToeChallenge({
  int timeLimitSeconds = 30,
  int maxPoints = 1000,
}) {
  return ChallengeDefinition(
    id: 'ttt_test',
    name: 'Tic Tac Toe Test',
    description: '',
    operation: 'tic_tac_toe',
    challengeType: ChallengeType.ticTacToe,
    timeLimitSeconds: timeLimitSeconds,
    maxPoints: maxPoints,
    questionCount: 3,
  );
}

List<TicTacToeMark> _board(String cells) {
  // 'X' = player, 'O' = ai, '.' = empty — 9 chars, row-major.
  return cells.split('').map((c) {
    switch (c) {
      case 'X':
        return TicTacToeMark.player;
      case 'O':
        return TicTacToeMark.ai;
      default:
        return TicTacToeMark.none;
    }
  }).toList();
}

void main() {
  group('TicTacToeBoard', () {
    test('detects a row winner and its line', () {
      final board = _board('XXX'
          'OO.'
          '...');
      expect(TicTacToeBoard.findWinner(board), TicTacToeMark.player);
      expect(TicTacToeBoard.findWinningLine(board), [0, 1, 2]);
    });

    test('detects a diagonal winner', () {
      final board = _board('O.X'
          '.OX'
          'X.O');
      expect(TicTacToeBoard.findWinner(board), TicTacToeMark.ai);
      expect(TicTacToeBoard.findWinningLine(board), [0, 4, 8]);
    });

    test('reports no winner and full board on a draw', () {
      final board = _board('XOX'
          'XOO'
          'OXX');
      expect(TicTacToeBoard.findWinner(board), isNull);
      expect(TicTacToeBoard.isFull(board), isTrue);
    });

    test('availableCells returns only empty indices', () {
      final board = _board('X.O'
          '...'
          '..X');
      expect(TicTacToeBoard.availableCells(board), [1, 3, 4, 5, 6, 7]);
    });
  });

  group('TicTacToeAi', () {
    final ai = TicTacToeAi();

    test('easy plays a valid empty cell', () {
      final board = _board('XO.'
          '.X.'
          '..O');
      for (var i = 0; i < 50; i++) {
        final move = ai.chooseMove(board, TicTacToeDifficulty.easy);
        expect(board[move], TicTacToeMark.none);
      }
    });

    test('medium takes an immediate win', () {
      final board = _board('OO.'
          'XX.'
          '...');
      // AI (O) can win at index 2.
      final move = ai.chooseMove(board, TicTacToeDifficulty.medium);
      expect(move, 2);
    });

    test('medium blocks the player\'s immediate win', () {
      final board = _board('XX.'
          'O..'
          '...');
      // Player (X) threatens index 2 — AI must block.
      final move = ai.chooseMove(board, TicTacToeDifficulty.medium);
      expect(move, 2);
    });

    test('medium prefers winning over blocking', () {
      final board = _board('XX.'
          'OO.'
          '...');
      // AI can win at 5 even though player threatens at 2.
      final move = ai.chooseMove(board, TicTacToeDifficulty.medium);
      expect(move, 5);
    });

    test('hard always takes an immediate win (minimax and slip agree)', () {
      final board = _board('OO.'
          'XX.'
          '...');
      for (var i = 0; i < 50; i++) {
        expect(ai.chooseMove(board, TicTacToeDifficulty.hard), 2);
      }
    });

    test('hard always blocks an immediate loss', () {
      final board = _board('X..'
          '.X.'
          'O..');
      // Player threatens 8 (diagonal 0-4-8); both minimax and the
      // medium fallback must block it.
      for (var i = 0; i < 50; i++) {
        expect(ai.chooseMove(board, TicTacToeDifficulty.hard), 8);
      }
    });

    test('throws when the board is full', () {
      final board = _board('XOX'
          'XOO'
          'OXX');
      expect(
        () => ai.chooseMove(board, TicTacToeDifficulty.easy),
        throwsStateError,
      );
    });
  });

  group('TicTacToeScoring', () {
    test('loss, draw and timeout score 0', () {
      for (final outcome in [
        TicTacToeRoundOutcome.loss,
        TicTacToeRoundOutcome.draw,
        TicTacToeRoundOutcome.timeout,
      ]) {
        expect(
          TicTacToeScoring.calculateRoundScore(
            outcome: outcome,
            remainingMs: 30000,
            timeLimitMs: 30000,
            maxPoints: 1000,
          ),
          0,
        );
      }
    });

    test('win score scales with remaining time', () {
      int score(int remainingMs) => TicTacToeScoring.calculateRoundScore(
            outcome: TicTacToeRoundOutcome.win,
            remainingMs: remainingMs,
            timeLimitMs: 30000,
            maxPoints: 1000,
          );

      expect(score(30000), 1000); // instant win → max
      expect(score(15000), 500); // half time → half points
      expect(score(0), 100); // slowest win → floored at 10%
      expect(score(3000), 100); // exactly at the floor
      expect(score(24000), 800);
    });

    test('final score is the average of round scores', () {
      const results = [
        TicTacToeRoundResult(
          roundNumber: 1,
          difficulty: TicTacToeDifficulty.easy,
          outcome: TicTacToeRoundOutcome.win,
          score: 900,
          remainingMs: 27000,
          timeLimitMs: 30000,
        ),
        TicTacToeRoundResult(
          roundNumber: 2,
          difficulty: TicTacToeDifficulty.medium,
          outcome: TicTacToeRoundOutcome.draw,
          score: 0,
          remainingMs: 0,
          timeLimitMs: 30000,
        ),
        TicTacToeRoundResult(
          roundNumber: 3,
          difficulty: TicTacToeDifficulty.hard,
          outcome: TicTacToeRoundOutcome.win,
          score: 300,
          remainingMs: 9000,
          timeLimitMs: 30000,
        ),
      ];
      expect(TicTacToeScoring.calculateFinalScore(results), 400);
      expect(TicTacToeScoring.calculateFinalScore([]), 0);
    });
  });

  group('TicTacToeRunner', () {
    test('rejects non tic_tac_toe challenges', () {
      final runner = TicTacToeRunner();
      const mathChallenge = ChallengeDefinition(
        id: 'math',
        name: 'Math',
        description: '',
        operation: '+',
      );
      expect(
        () => runner.startChallenge(mathChallenge),
        throwsArgumentError,
      );
    });

    test('difficulty progresses easy → medium → hard across rounds', () {
      final runner = TicTacToeRunner();
      runner.startChallenge(_ticTacToeChallenge());

      expect(runner.currentRoundNumber, 1);
      expect(runner.currentDifficulty, TicTacToeDifficulty.easy);

      runner.recordRoundResult(
          outcome: TicTacToeRoundOutcome.draw, remainingMs: 0);
      expect(runner.currentRoundNumber, 2);
      expect(runner.currentDifficulty, TicTacToeDifficulty.medium);

      runner.recordRoundResult(
          outcome: TicTacToeRoundOutcome.loss, remainingMs: 5000);
      expect(runner.currentRoundNumber, 3);
      expect(runner.currentDifficulty, TicTacToeDifficulty.hard);

      expect(runner.isFinished, isFalse);
      runner.recordRoundResult(
          outcome: TicTacToeRoundOutcome.win, remainingMs: 15000);
      expect(runner.isFinished, isTrue);
    });

    test('player and AI moves update the board', () {
      final runner = TicTacToeRunner();
      runner.startChallenge(_ticTacToeChallenge());
      runner.startRound();

      expect(runner.canPlaceAt(4), isTrue);
      runner.placePlayerMark(4);
      expect(runner.board[4], TicTacToeMark.player);
      expect(runner.canPlaceAt(4), isFalse);

      final aiMove = runner.placeAiMark();
      expect(runner.board[aiMove], TicTacToeMark.ai);
      expect(aiMove, isNot(4));
    });

    test('builds the final Result with averaged score and stats', () {
      final runner = TicTacToeRunner();
      runner.startChallenge(_ticTacToeChallenge());

      runner.recordRoundResult(
          outcome: TicTacToeRoundOutcome.win, remainingMs: 30000); // 1000
      runner.recordRoundResult(
          outcome: TicTacToeRoundOutcome.draw, remainingMs: 0); // 0
      runner.recordRoundResult(
          outcome: TicTacToeRoundOutcome.win, remainingMs: 15000); // 500

      expect(runner.finalScore, 500);
      expect(runner.roundsWon, 2);
      expect(runner.roundsDrawn, 1);

      final result = runner.getFinalResult(PlayerData(nickname: 'Tester'));
      expect(result.isTicTacToe, isTrue);
      expect(result.score, 500);
      expect(result.correctCount, 2);
      expect(result.roundsWon, 2);
      expect(result.roundsDrawn, 1);
      expect(result.totalRounds, 3);
      expect(result.playerName, 'Tester');
      // Elapsed: 0 + 30000 + 15000 = 45000 ms.
      expect(result.totalResponseTimeMs, 45000);
    });
  });
}
