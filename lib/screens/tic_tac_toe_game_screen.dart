import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/challenge_definition.dart';
import '../models/question.dart';
import '../providers/player_provider.dart';
import '../providers/result_provider.dart';
import '../providers/tic_tac_toe_provider.dart';
import '../services/challenge_entry.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/balance_bar_chips.dart';
import 'result_screen.dart';

const _tttCyan = Color(0xFF22D3EE);
const _tttPink = Color(0xFFEC4899);

class TicTacToeGameScreen extends StatefulWidget {
  final ChallengeDefinition challenge;

  const TicTacToeGameScreen({super.key, required this.challenge});

  @override
  State<TicTacToeGameScreen> createState() => _TicTacToeGameScreenState();
}

class _TicTacToeGameScreenState extends State<TicTacToeGameScreen> {
  bool _navigated = false;
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    Timer.run(() => context.read<TicTacToeProvider>().startChallenge(widget.challenge));
  }

  Future<void> _onStart(TicTacToeProvider provider) async {
    if (_paying) return;
    setState(() => _paying = true);
    final paid = await payChallengeEntry(context, widget.challenge);
    if (!mounted) return;
    setState(() => _paying = false);
    if (!paid) return;
    provider.startPlaying();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _showExitConfirmation(l10n);
      },
      child: Container(
        decoration: const BoxDecoration(gradient: kBgGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(widget.challenge.name,
                style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold)),
            backgroundColor: kSurfaceDark,
            foregroundColor: kTextPrimary,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kTextPrimary.withAlpha(10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.close_rounded, color: kTextPrimary, size: 20),
              ),
              onPressed: () => _showExitConfirmation(l10n),
            ),
            actions: const [
              BalanceBarChips(),
            ],
          ),
          body: Consumer<TicTacToeProvider>(
            builder: (context, provider, _) {
              if (provider.state == TicTacToeState.finished) {
                if (!_navigated) {
                  _navigated = true;
                  Timer.run(() => _navigateToResult(provider));
                }
                return const Center(child: CircularProgressIndicator(color: kAccentPurple));
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
              if (provider.state != TicTacToeState.intro) return const SizedBox.shrink();
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _paying ? null : () => _onStart(provider),
                      icon: _paying
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : Icon(
                              widget.challenge.isFree
                                  ? Icons.play_arrow_rounded
                                  : Icons.monetization_on_rounded,
                              size: 26,
                            ),
                      label: Text(
                        widget.challenge.isFree
                            ? l10n.startGame.toUpperCase()
                            : l10n.startWithCost(widget.challenge.entryCoins).toUpperCase(),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _tttCyan,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: _tttCyan.withAlpha(120),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 0,
                        shadowColor: _tttCyan,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildIntroView(TicTacToeProvider provider, AppLocalizations l10n) {
    final challenge = widget.challenge;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kSurfaceDark,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _tttCyan.withAlpha(30), width: 0.8),
              boxShadow: [BoxShadow(color: _tttCyan.withAlpha(12), blurRadius: 16)],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _tttCyan.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(l10n.ticTacToeIntroBadge.toUpperCase(),
                      style: const TextStyle(color: _tttCyan, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 200,
                  height: 200,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.0),
                    itemCount: 9,
                    itemBuilder: (context, index) {
                      String? mark;
                      if ([0, 4, 8].contains(index)) mark = 'X';
                      if ([2, 6].contains(index)) mark = 'O';
                      return _PreviewCell(mark: mark, index: index);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.ticTacToeIntroTitle,
              style: const TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(l10n.ticTacToeIntroSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kTextSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoPill(icon: Icons.groups_rounded, text: l10n.pillPlayers(2), color: _tttCyan),
              _InfoPill(icon: Icons.emoji_events_rounded, text: l10n.pillBestOf(3), color: _tttPink),
              _InfoPill(icon: Icons.timer_rounded, text: l10n.pillSecondsPerRound(challenge.timeLimitSeconds), color: kAccentGold),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(l10n.ticTacToeRounds, l10n.ticTacToeRoundsValue, Icons.repeat_rounded),
          const SizedBox(height: 8),
          _buildInfoRow(l10n.ticTacToeTimePerRound, '${challenge.timeLimitSeconds}s', Icons.timer_rounded),
          const SizedBox(height: 8),
          _buildInfoRow(l10n.ticTacToeMaxPoints, '${challenge.maxPoints}', Icons.star_rounded),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kSurfaceDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _tttCyan.withAlpha(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_tttCyan, Color(0xFF3B82F6)]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.info_outline_rounded, color: kTextPrimary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(l10n.ticTacToeHowToPlay,
                      style: const TextStyle(color: kTextPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 16),
                _InstructionRow(icon: Icons.touch_app_rounded, text: l10n.ticTacToeRule1),
                const SizedBox(height: 10),
                _InstructionRow(icon: Icons.smart_toy_rounded, text: l10n.ticTacToeRule2),
                const SizedBox(height: 10),
                _InstructionRow(icon: Icons.trending_up_rounded, text: l10n.ticTacToeRule3),
                const SizedBox(height: 10),
                _InstructionRow(icon: Icons.timer_rounded, text: l10n.ticTacToeRule4(challenge.timeLimitSeconds)),
                const SizedBox(height: 10),
                _InstructionRow(icon: Icons.functions_rounded, text: l10n.ticTacToeRule5),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kSurfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kTextPrimary.withAlpha(10)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: kAccentPurple),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGameView(TicTacToeProvider provider, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildGameHeader(provider, l10n),
          const SizedBox(height: 16),
          _buildTurnIndicator(provider, l10n),
          const SizedBox(height: 16),
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

  Widget _buildGameHeader(TicTacToeProvider provider, AppLocalizations l10n) {
    final difficultyColor = switch (provider.currentDifficulty) {
      TicTacToeDifficulty.easy => Colors.greenAccent,
      TicTacToeDifficulty.medium => kAccentGold,
      TicTacToeDifficulty.hard => Colors.redAccent,
    };

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.ticTacToeRound(provider.currentRoundNumber, provider.totalRounds),
                style: const TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: difficultyColor.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: difficultyColor.withAlpha(50)),
              ),
              child: Text(_difficultyLabel(provider.currentDifficulty, l10n),
                  style: TextStyle(color: difficultyColor, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kAccentGold.withAlpha(15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kAccentGold.withAlpha(40)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: kAccentGold, size: 16),
                  const SizedBox(width: 4),
                  Text('${provider.totalRoundScore}',
                      style: const TextStyle(color: kAccentGold, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 5,
          decoration: BoxDecoration(
            color: kTextPrimary.withAlpha(8),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: provider.timerProgress,
            child: Container(
              decoration: BoxDecoration(
                color: provider.timerProgress > 0.33
                    ? _tttCyan
                    : provider.timerProgress > 0.15
                        ? kAccentGold
                        : Colors.redAccent,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [BoxShadow(color: provider.timerProgress > 0.33
                    ? _tttCyan : provider.timerProgress > 0.15 ? kAccentGold : Colors.redAccent, blurRadius: 4)],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(l10n.ticTacToeTimeRemaining(provider.remainingSeconds),
              style: TextStyle(color: provider.timerProgress < 0.33 ? Colors.redAccent : kTextSecondary,
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  String _difficultyLabel(TicTacToeDifficulty difficulty, AppLocalizations l10n) {
    return switch (difficulty) {
      TicTacToeDifficulty.easy => l10n.ticTacToeDifficultyEasy,
      TicTacToeDifficulty.medium => l10n.ticTacToeDifficultyMedium,
      TicTacToeDifficulty.hard => l10n.ticTacToeDifficultyHard,
    };
  }

  Widget _buildTurnIndicator(TicTacToeProvider provider, AppLocalizations l10n) {
    if (provider.isAiThinking) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: kAccentGold.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kAccentGold.withAlpha(30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: kAccentGold.withAlpha(180)),
            ),
            const SizedBox(width: 10),
            Text(l10n.ticTacToeAiThinking,
                style: TextStyle(color: kAccentGold.withAlpha(200), fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    if (provider.isPlayerTurn) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _tttCyan.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _tttCyan.withAlpha(40)),
          boxShadow: [BoxShadow(color: _tttCyan.withAlpha(15), blurRadius: 10)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close_rounded, color: _tttCyan, size: 20),
            const SizedBox(width: 8),
            Text(l10n.ticTacToeYourTurnShort.toUpperCase(), style: const TextStyle(color: _tttCyan, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildBoard(TicTacToeProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSize = constraints.maxWidth < constraints.maxHeight ? constraints.maxWidth : constraints.maxHeight;
        final boardSize = (maxSize - 16).clamp(200.0, 400.0);

        return Container(
          width: boardSize + 24,
          height: boardSize + 24,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kSurfaceDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _tttCyan.withAlpha(30), width: 1.2),
            boxShadow: [BoxShadow(color: _tttCyan.withAlpha(10), blurRadius: 20)],
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              return _TicTacToeCellWidget(
                mark: provider.board[index],
                size: (boardSize - 16) / 3,
                isWinningCell: provider.winningLine?.contains(index) ?? false,
                isWin: provider.lastRoundResult?.isWin ?? false,
                isLastAiMove: provider.lastAiMoveIndex == index && provider.board[index] == TicTacToeMark.ai,
                enabled: provider.isPlayerTurn,
                onTap: () => provider.tapCell(index),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRoundResultOverlay(TicTacToeProvider provider, AppLocalizations l10n) {
    final result = provider.lastRoundResult;
    if (result == null) return const SizedBox.shrink();

    final IconData icon;
    final Color color;
    final String title;
    switch (result.outcome) {
      case TicTacToeRoundOutcome.win:
        icon = Icons.emoji_events_rounded; color = Colors.greenAccent; title = l10n.ticTacToeYouWin;
      case TicTacToeRoundOutcome.loss:
        icon = Icons.sentiment_dissatisfied_rounded; color = Colors.redAccent; title = l10n.ticTacToeYouLose;
      case TicTacToeRoundOutcome.draw:
        icon = Icons.handshake_rounded; color = kAccentGold; title = l10n.ticTacToeDraw;
      case TicTacToeRoundOutcome.timeout:
        icon = Icons.timer_off_rounded; color = Colors.redAccent; title = l10n.ticTacToeTimeUp;
    }

    final isLastRound = result.roundNumber >= provider.totalRounds;

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: kSurfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withAlpha(50), width: 1.5),
        boxShadow: [BoxShadow(color: color.withAlpha(20), blurRadius: 24)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [color.withAlpha(40), Colors.transparent]),
              border: Border.all(color: color.withAlpha(60), width: 2),
            ),
            child: Icon(icon, size: 36, color: color),
          ),
          const SizedBox(height: 14),
          Text(title, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(result.isWin ? l10n.ticTacToeRoundPoints(result.score) : l10n.ticTacToeNoPoints,
              style: TextStyle(color: result.isWin ? Colors.greenAccent : kTextSecondary, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(isLastRound ? l10n.ticTacToeAllRoundsDone : l10n.ticTacToeNextRound,
              style: const TextStyle(color: kTextMuted, fontSize: 12)),
        ],
      ),
    );
  }

  void _showExitConfirmation(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceDark,
        title: Text(l10n.quitGame, style: const TextStyle(color: kTextPrimary)),
        content: Text(l10n.quitGameConfirm, style: const TextStyle(color: kTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.keepPlaying, style: const TextStyle(color: _tttCyan)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TicTacToeProvider>().reset();
              Navigator.pop(context);
            },
            child: Text(l10n.quit, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _navigateToResult(TicTacToeProvider provider) {
    final playerProvider = context.read<PlayerProvider>();
    final result = provider.finalizeResult(playerProvider.playerData);
    context.read<ResultProvider>().saveResult(result);
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ResultScreen(result: result, challenge: widget.challenge)),
    );
  }
}

class _TicTacToeCellWidget extends StatelessWidget {
  final TicTacToeMark mark;
  final double size;
  final bool isWinningCell;
  final bool isWin;
  final bool isLastAiMove;
  final bool enabled;
  final VoidCallback onTap;

  const _TicTacToeCellWidget({
    required this.mark, required this.size, required this.isWinningCell,
    required this.isWin, required this.isLastAiMove, required this.enabled, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = mark == TicTacToeMark.none;
    final winColor = isWin ? Colors.greenAccent : Colors.redAccent;
    final xColor = _tttCyan;
    final oColor = _tttPink;

    return GestureDetector(
      onTap: isEmpty && enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isWinningCell
              ? winColor.withAlpha(25)
              : isEmpty
                  ? kTextPrimary.withAlpha(6)
                  : kSurfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isWinningCell
                ? winColor
                : isLastAiMove
                    ? oColor.withAlpha(150)
                    : kTextPrimary.withAlpha(12),
            width: isWinningCell ? 2.5 : 1.2,
          ),
          boxShadow: isWinningCell ? [BoxShadow(color: winColor.withAlpha(30), blurRadius: 12)] : null,
        ),
        child: Center(
          child: mark == TicTacToeMark.none
              ? (isEmpty && enabled
                  ? Icon(Icons.add_rounded, color: kTextMuted.withAlpha(40), size: (size * 0.35).clamp(20.0, 40.0))
                  : const SizedBox.shrink())
              : AnimatedScale(
                  scale: 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: mark == TicTacToeMark.player
                      ? Icon(Icons.close_rounded, size: (size * 0.55).clamp(28.0, 64.0), color: xColor)
                      : Container(
                          width: (size * 0.45).clamp(24.0, 52.0),
                          height: (size * 0.45).clamp(24.0, 52.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: oColor, width: 3.5),
                          ),
                        ),
                ),
        ),
      ),
    );
  }
}

class _PreviewCell extends StatelessWidget {
  final String? mark;
  final int index;
  const _PreviewCell({this.mark, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: mark != null ? kTextPrimary.withAlpha(8) : kTextPrimary.withAlpha(4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kTextPrimary.withAlpha(10)),
      ),
      child: Center(
        child: mark == 'X'
            ? const Icon(Icons.close_rounded, color: _tttCyan, size: 32)
            : mark == 'O'
                ? Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _tttPink, width: 3),
                    ),
                  )
                : null,
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoPill({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: kSurfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
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
        Icon(icon, size: 18, color: _tttCyan),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(color: kTextSecondary, fontSize: 14, height: 1.4))),
      ],
    );
  }
}
