import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/challenge_definition.dart';
import '../models/question.dart';
import '../providers/player_provider.dart';
import '../providers/result_provider.dart';
import '../providers/tic_tac_toe_provider.dart';
import '../l10n/app_localizations.dart';
import 'result_screen.dart';

/// Game screen for Tic‑Tac‑Toe challenges.
///
/// Visual states:
///   1. **Intro** – challenge info + Start button
///   2. **Playing** – 3x3 board, round/difficulty header, countdown timer
///   3. **Round result** – overlay banner between rounds
///   4. **Finished** – navigates to ResultScreen
class TicTacToeGameScreen extends StatefulWidget {
  final ChallengeDefinition challenge;
  final String? competitionId;

  const TicTacToeGameScreen({
    super.key,
    required this.challenge,
    this.competitionId,
  });

  @override
  State<TicTacToeGameScreen> createState() => _TicTacToeGameScreenState();
}

class _TicTacToeGameScreenState extends State<TicTacToeGameScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    Timer.run(() {
      context.read<TicTacToeProvider>().startChallenge(widget.challenge);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _showExitConfirmation(l10n);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.challenge.name),
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showExitConfirmation(l10n),
          ),
        ),
        body: Consumer<TicTacToeProvider>(
          builder: (context, provider, _) {
            if (provider.state == TicTacToeState.finished) {
              if (!_navigated) {
                _navigated = true;
                Timer.run(() => _navigateToResult(provider));
              }
              return const Center(child: CircularProgressIndicator());
            }

            return SafeArea(
              child: provider.state == TicTacToeState.intro
                  ? _buildIntroView(provider, l10n)
                  : _buildGameView(provider, l10n),
            );
          },
        ),
        bottomNavigationBar: Consumer<TicTacToeProvider>(
          builder: (context, provider, _) {
            if (provider.state != TicTacToeState.intro) {
              return const SizedBox.shrink();
            }
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => provider.startPlaying(),
                    icon: const Icon(Icons.play_arrow, size: 28),
                    label: Text(
                      l10n.ticTacToeStart,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Intro view ───────────────────────────────────────────────────

  Widget _buildIntroView(TicTacToeProvider provider, AppLocalizations l10n) {
    final challenge = widget.challenge;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Header icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.teal.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.grid_3x3,
              size: 40,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 16),
          // Challenge title
          Text(
            challenge.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            challenge.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 28),
          // Game info cards
          _buildInfoRow(
            icon: Icons.repeat,
            label: l10n.ticTacToeRounds,
            value: l10n.ticTacToeRoundsValue,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.timer,
            label: l10n.ticTacToeTimePerRound,
            value: '${challenge.timeLimitSeconds}s',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.star,
            label: l10n.ticTacToeMaxPoints,
            value: '${challenge.maxPoints}',
          ),
          const SizedBox(height: 28),
          // "How to Play" section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFF1A237E), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      l10n.ticTacToeHowToPlay,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InstructionRow(
                  icon: Icons.touch_app,
                  text: l10n.ticTacToeRule1,
                ),
                const SizedBox(height: 12),
                _InstructionRow(
                  icon: Icons.smart_toy,
                  text: l10n.ticTacToeRule2,
                ),
                const SizedBox(height: 12),
                _InstructionRow(
                  icon: Icons.trending_up,
                  text: l10n.ticTacToeRule3,
                ),
                const SizedBox(height: 12),
                _InstructionRow(
                  icon: Icons.timer,
                  text: l10n.ticTacToeRule4(challenge.timeLimitSeconds),
                ),
                const SizedBox(height: 12),
                _InstructionRow(
                  icon: Icons.functions,
                  text: l10n.ticTacToeRule5,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: const Color(0xFF1A237E)),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
        ],
      ),
    );
  }

  // ── Game view ────────────────────────────────────────────────────

  Widget _buildGameView(TicTacToeProvider provider, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildTimerBar(provider, l10n),
          const SizedBox(height: 12),
          _buildRoundHeader(provider, l10n),
          const SizedBox(height: 8),
          // Turn indicator
          Text(
            provider.isAiThinking
                ? l10n.ticTacToeAiThinking
                : provider.isPlayerTurn
                    ? l10n.ticTacToeYourTurn
                    : ' ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: provider.isAiThinking
                  ? Colors.orange.shade700
                  : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          // Board
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(child: _buildBoard(provider)),
                if (provider.state == TicTacToeState.showingRoundResult)
                  _buildRoundResultOverlay(provider, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundHeader(TicTacToeProvider provider, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Round indicator
        Text(
          l10n.ticTacToeRound(provider.currentRoundNumber, provider.totalRounds),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        // Difficulty chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _difficultyColor(provider.currentDifficulty).withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _difficultyLabel(provider.currentDifficulty, l10n),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _difficultyColor(provider.currentDifficulty),
            ),
          ),
        ),
        // Running score
        Row(
          children: [
            const Icon(Icons.star, size: 18, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              '${provider.totalRoundScore}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6F00),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _difficultyColor(TicTacToeDifficulty difficulty) {
    switch (difficulty) {
      case TicTacToeDifficulty.easy:
        return Colors.green;
      case TicTacToeDifficulty.medium:
        return Colors.orange;
      case TicTacToeDifficulty.hard:
        return Colors.red;
    }
  }

  String _difficultyLabel(
      TicTacToeDifficulty difficulty, AppLocalizations l10n) {
    switch (difficulty) {
      case TicTacToeDifficulty.easy:
        return l10n.ticTacToeDifficultyEasy;
      case TicTacToeDifficulty.medium:
        return l10n.ticTacToeDifficultyMedium;
      case TicTacToeDifficulty.hard:
        return l10n.ticTacToeDifficultyHard;
    }
  }

  Widget _buildTimerBar(TicTacToeProvider provider, AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: provider.timerProgress,
            child: Container(
              decoration: BoxDecoration(
                color: provider.timerProgress > 0.33
                    ? Colors.green
                    : provider.timerProgress > 0.15
                        ? Colors.orange
                        : Colors.red,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.ticTacToeTimeRemaining(provider.remainingSeconds),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: provider.timerProgress < 0.33
                  ? Colors.red
                  : Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBoard(TicTacToeProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSize = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final boardSize = (maxSize - 16).clamp(200.0, 400.0);

        return SizedBox(
          width: boardSize,
          height: boardSize,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              return _TicTacToeCellWidget(
                mark: provider.board[index],
                size: (boardSize - 16) / 3,
                isWinningCell:
                    provider.winningLine?.contains(index) ?? false,
                isWin: provider.lastRoundResult?.isWin ?? false,
                isLastAiMove: provider.lastAiMoveIndex == index &&
                    provider.board[index] == TicTacToeMark.ai,
                enabled: provider.isPlayerTurn,
                onTap: () => provider.tapCell(index),
              );
            },
          ),
        );
      },
    );
  }

  // ── Round result overlay ─────────────────────────────────────────

  Widget _buildRoundResultOverlay(
      TicTacToeProvider provider, AppLocalizations l10n) {
    final result = provider.lastRoundResult;
    if (result == null) return const SizedBox.shrink();

    final IconData icon;
    final Color color;
    final String title;
    switch (result.outcome) {
      case TicTacToeRoundOutcome.win:
        icon = Icons.emoji_events;
        color = Colors.green;
        title = l10n.ticTacToeYouWin;
      case TicTacToeRoundOutcome.loss:
        icon = Icons.sentiment_dissatisfied;
        color = Colors.red;
        title = l10n.ticTacToeYouLose;
      case TicTacToeRoundOutcome.draw:
        icon = Icons.handshake;
        color = Colors.orange;
        title = l10n.ticTacToeDraw;
      case TicTacToeRoundOutcome.timeout:
        icon = Icons.timer_off;
        color = Colors.orange;
        title = l10n.ticTacToeTimeUp;
    }

    final isLastRound = result.roundNumber >= provider.totalRounds;

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.isWin
                ? l10n.ticTacToeRoundPoints(result.score)
                : l10n.ticTacToeNoPoints,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: result.isWin ? Colors.green : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isLastRound ? l10n.ticTacToeAllRoundsDone : l10n.ticTacToeNextRound,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Exit confirmation ────────────────────────────────────────────

  void _showExitConfirmation(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.quitGame),
        content: Text(l10n.quitGameConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.keepPlaying),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TicTacToeProvider>().reset();
              Navigator.pop(context);
            },
            child: Text(l10n.quit, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── Navigation ───────────────────────────────────────────────────

  void _navigateToResult(TicTacToeProvider provider) {
    final playerProvider = context.read<PlayerProvider>();
    final result = provider.finalizeResult(playerProvider.playerData);

    context.read<ResultProvider>().saveResult(result);

    if (!mounted) return;

    if (widget.competitionId != null) {
      Navigator.pop(context, {
        'result': result,
        'challenge': widget.challenge,
        'competitionId': widget.competitionId,
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            result: result,
            challenge: widget.challenge,
          ),
        ),
      );
    }
  }
}

// ── Cell widget ────────────────────────────────────────────────────

class _TicTacToeCellWidget extends StatelessWidget {
  final TicTacToeMark mark;
  final double size;
  final bool isWinningCell;
  final bool isWin;
  final bool isLastAiMove;
  final bool enabled;
  final VoidCallback onTap;

  const _TicTacToeCellWidget({
    required this.mark,
    required this.size,
    required this.isWinningCell,
    required this.isWin,
    required this.isLastAiMove,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = mark == TicTacToeMark.none;
    final highlightColor = isWin ? Colors.green : Colors.red;

    return GestureDetector(
      onTap: isEmpty && enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isWinningCell
              ? highlightColor.withAlpha(40)
              : isEmpty
                  ? Colors.grey.shade50
                  : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isWinningCell
                ? highlightColor
                : isLastAiMove
                    ? Colors.orange.shade300
                    : Colors.grey.shade300,
            width: isWinningCell ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: mark == TicTacToeMark.none
              ? const SizedBox.shrink()
              : AnimatedScale(
                  scale: 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    mark == TicTacToeMark.player
                        ? Icons.close
                        : Icons.circle_outlined,
                    size: (size * 0.55).clamp(28.0, 64.0),
                    color: mark == TicTacToeMark.player
                        ? const Color(0xFF1A237E)
                        : const Color(0xFFFF6F00),
                  ),
                ),
        ),
      ),
    );
  }
}

class _InstructionRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InstructionRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1A237E)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF1A237E),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
