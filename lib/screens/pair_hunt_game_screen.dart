import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/challenge_definition.dart';
import '../models/question.dart';
import '../providers/player_provider.dart';
import '../providers/result_provider.dart';
import '../providers/pair_hunt_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';

const _phAmber = Color(0xFFFF9800);
const _phGold = Color(0xFFFFB300);
const _phCyan = Color(0xFF00E5FF);
const _phBrown = Color(0xFF1A1410);
const _phCharcoal = Color(0xFF1E1E24);

class PairHuntGameScreen extends StatefulWidget {
  final ChallengeDefinition challenge;

  const PairHuntGameScreen({super.key, required this.challenge});

  @override
  State<PairHuntGameScreen> createState() => _PairHuntGameScreenState();
}

class _PairHuntGameScreenState extends State<PairHuntGameScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    Timer.run(() => context.read<PairHuntProvider>().startChallenge(widget.challenge));
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_phBrown, Color(0xFF0D0F16)],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(widget.challenge.name,
                style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold)),
            backgroundColor: _phCharcoal,
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
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _phAmber.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _phAmber.withAlpha(50)),
                    boxShadow: [BoxShadow(color: _phAmber.withAlpha(15), blurRadius: 8)],
                  ),
                  child: const Text('MEMORY',
                      style: TextStyle(color: _phAmber, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                ),
              ),
            ],
          ),
          body: Consumer<PairHuntProvider>(
            builder: (context, provider, _) {
              if (provider.state == PairHuntState.finished) {
                if (!_navigated) {
                  _navigated = true;
                  Timer.run(() => _navigateToResult(provider));
                }
                return const Center(child: CircularProgressIndicator(color: _phAmber));
              }
              return SafeArea(
                child: provider.state == PairHuntState.intro
                    ? _buildIntroView(provider, l10n)
                    : _buildGameView(provider, l10n),
              );
            },
          ),
          bottomNavigationBar: Consumer<PairHuntProvider>(
            builder: (context, provider, _) {
              if (provider.state != PairHuntState.intro) return const SizedBox.shrink();
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => provider.startPlaying(),
                      icon: const Icon(Icons.play_arrow_rounded, size: 26),
                      label: const Text('START GAME',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _phAmber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 0,
                        shadowColor: _phAmber,
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

  Widget _buildIntroView(PairHuntProvider provider, AppLocalizations l10n) {
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
              color: _phCharcoal,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _phAmber.withAlpha(30), width: 0.8),
              boxShadow: [BoxShadow(color: _phAmber.withAlpha(12), blurRadius: 16)],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _phAmber.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Flip cards. Find matching pairs. Clear the board.',
                      style: TextStyle(color: _phAmber, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 240,
                  height: 180,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.0),
                    itemCount: 8,
                    itemBuilder: (context, index) {
                      final flipped = index == 2;
                      final matched = index == 6;
                      String? emoji;
                      if (flipped && index == 2) emoji = '🔥';
                      if (matched && index == 6) emoji = '⚡';
                      return Container(
                        decoration: BoxDecoration(
                          color: matched
                              ? _phCyan.withAlpha(20)
                              : flipped
                                  ? _phCharcoal
                                  : _phCharcoal,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: matched ? _phCyan.withAlpha(80) : flipped ? _phAmber.withAlpha(60) : kTextPrimary.withAlpha(10),
                            width: matched ? 2 : 1,
                          ),
                          boxShadow: matched
                              ? [BoxShadow(color: _phCyan.withAlpha(20), blurRadius: 8)]
                              : flipped
                                  ? [BoxShadow(color: _phAmber.withAlpha(20), blurRadius: 8)]
                                  : null,
                        ),
                        child: Center(
                          child: emoji != null
                              ? Text(emoji, style: const TextStyle(fontSize: 24))
                              : Icon(Icons.help_outline_rounded, color: kTextMuted.withAlpha(60), size: 22),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Match the pairs. Beat the clock.',
              style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Flip cards to find matching pairs.\nClear all pairs before time runs out!',
              textAlign: TextAlign.center, style: TextStyle(color: kTextSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          Wrap(spacing: 10, runSpacing: 10, children: [
            _InfoPill(icon: Icons.grid_view_rounded, text: '${challenge.blockCount} Blocks', color: _phAmber),
            _InfoPill(icon: Icons.timer_rounded, text: '${challenge.timeLimitSeconds}s', color: _phCyan),
            _InfoPill(icon: Icons.star_rounded, text: '${challenge.maxPoints} Max', color: _phGold),
          ]),
          const SizedBox(height: 16),
          _buildInfoRow(l10n.pairHuntPairs, '${challenge.pairCount} ${l10n.pairHuntPairsLabel}', Icons.grid_view_rounded),
          const SizedBox(height: 8),
          _buildInfoRow(l10n.pairHuntTimeLimit, l10n.pairHuntTimeLimitValue(challenge.timeLimitSeconds), Icons.timer_rounded),
          const SizedBox(height: 8),
          _buildInfoRow(l10n.pairHuntBlocks, '${challenge.blockCount}', Icons.extension_rounded),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _phCharcoal,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _phAmber.withAlpha(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_phAmber, Color(0xFFE65100)]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.info_outline_rounded, color: kTextPrimary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(l10n.pairHuntHowToPlay,
                      style: const TextStyle(color: kTextPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 16),
                _InstructionRow(icon: Icons.touch_app_rounded, text: l10n.pairHuntRule1),
                const SizedBox(height: 10),
                _InstructionRow(icon: Icons.swap_horiz_rounded, text: l10n.pairHuntRule2),
                const SizedBox(height: 10),
                _InstructionRow(icon: Icons.emoji_emotions_rounded, text: l10n.pairHuntRule3),
                const SizedBox(height: 10),
                _InstructionRow(icon: Icons.timer_rounded, text: l10n.pairHuntRule4(challenge.timeLimitSeconds)),
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
        color: _phCharcoal,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kTextPrimary.withAlpha(10)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _phAmber),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGameView(PairHuntProvider provider, AppLocalizations l10n) {
    final blockCount = widget.challenge.blockCount;
    final rows = blockCount ~/ 4;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          _buildGameHeader(provider, l10n),
          const SizedBox(height: 10),
          _buildMismatchFeedback(provider),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight;
                final availableWidth = constraints.maxWidth;
                final maxBlockWidth = availableWidth / 4;
                final maxBlockHeight = availableHeight / rows;
                final blockSize = (maxBlockWidth < maxBlockHeight ? maxBlockWidth : maxBlockHeight) - 10;

                final clampedSize = blockSize.clamp(40.0, 110.0);
                final totalGridWidth = (clampedSize * 4) + (8 * 3);
                final totalGridHeight = (clampedSize * rows) + (8 * (rows - 1));

                return Center(
                  child: Container(
                    width: totalGridWidth + 16,
                    height: totalGridHeight + 16,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _phCharcoal,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _phAmber.withAlpha(25), width: 1),
                      boxShadow: [BoxShadow(color: _phAmber.withAlpha(8), blurRadius: 16)],
                    ),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: blockCount,
                      itemBuilder: (context, index) {
                        return _PairHuntBlockWidget(
                          block: provider.blocks[index],
                          size: clampedSize,
                          isShowingMismatch: provider.isShowingMismatch && provider.revealedIndices.contains(index),
                          onTap: () => provider.tapBlock(index),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameHeader(PairHuntProvider provider, AppLocalizations l10n) {
    return Column(
      children: [
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
                    ? _phAmber
                    : provider.timerProgress > 0.15
                        ? Colors.orangeAccent
                        : Colors.redAccent,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [BoxShadow(
                    color: provider.timerProgress > 0.33 ? _phAmber : Colors.redAccent,
                    blurRadius: 4)],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _phAmber.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _phAmber.withAlpha(30)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.grid_view_rounded, color: _phAmber, size: 16),
                  const SizedBox(width: 6),
                  Text(l10n.pairHuntProgress(provider.pairsFound, provider.totalPairs),
                      style: const TextStyle(color: _phAmber, fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: provider.timerProgress < 0.33 ? Colors.redAccent.withAlpha(20) : kTextPrimary.withAlpha(8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: provider.timerProgress < 0.33 ? Colors.redAccent.withAlpha(50) : kTextPrimary.withAlpha(15)),
              ),
              child: Text(
                l10n.pairHuntTimeRemaining(provider.timeRemainingSeconds),
                style: TextStyle(
                  color: provider.timerProgress < 0.33 ? Colors.redAccent : kTextSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.redAccent.withAlpha(10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withAlpha(20)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 14),
                  const SizedBox(width: 4),
                  Text('${provider.mismatchCount}',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMismatchFeedback(PairHuntProvider provider) {
    return AnimatedOpacity(
      opacity: provider.isShowingMismatch ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Colors.redAccent, Color(0xFFE53935)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.redAccent.withAlpha(40), blurRadius: 8)],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close_rounded, color: kTextPrimary, size: 18),
            SizedBox(width: 8),
            Text('NO MATCH — TRY AGAIN',
                style: TextStyle(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmation(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _phCharcoal,
        title: Text(l10n.quitGame, style: const TextStyle(color: kTextPrimary)),
        content: Text(l10n.quitGameConfirm, style: const TextStyle(color: kTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.keepPlaying, style: const TextStyle(color: _phAmber)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<PairHuntProvider>().reset();
              Navigator.pop(context);
            },
            child: Text(l10n.quit, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _navigateToResult(PairHuntProvider provider) {
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

class _PairHuntBlockWidget extends StatefulWidget {
  final PairHuntBlock block;
  final double size;
  final bool isShowingMismatch;
  final VoidCallback onTap;

  const _PairHuntBlockWidget({
    required this.block, required this.size, required this.isShowingMismatch, required this.onTap,
  });

  @override
  State<_PairHuntBlockWidget> createState() => _PairHuntBlockWidgetState();
}

class _PairHuntBlockWidgetState extends State<_PairHuntBlockWidget> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _wasRevealed = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _wasRevealed = widget.block.isRevealed;
  }

  @override
  void didUpdateWidget(covariant _PairHuntBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.block.isRevealed != _wasRevealed) {
      _wasRevealed = widget.block.isRevealed;
      if (widget.block.isRevealed) {
        _flipController.forward(from: 0);
      } else {
        _flipController.reverse(from: 1.0);
      }
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFaceUp = widget.block.isRevealed || widget.block.isMatched;
    final isMatched = widget.block.isMatched;

    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final showFront = _flipAnimation.value >= 0.5;
        final scaleX = (_flipAnimation.value - 0.5).abs() * 2;

        final borderColor = isMatched
            ? _phCyan
            : showFront
                ? _phAmber.withAlpha(120)
                : kTextPrimary.withAlpha(15);

        final bgColor = isMatched
            ? _phCyan.withAlpha(15)
            : showFront
                ? _phCharcoal
                : _phCharcoal;

        return Transform.scale(
          scaleX: scaleX,
          scaleY: 1.0,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: isFaceUp ? null : widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: isMatched ? 2.5 : 1.2),
                boxShadow: isMatched
                    ? [BoxShadow(color: _phCyan.withAlpha(30), blurRadius: 10)]
                    : showFront
                        ? [BoxShadow(color: _phAmber.withAlpha(20), blurRadius: 8)]
                        : [BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 3, offset: const Offset(0, 2))],
                gradient: !showFront && !isMatched
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_phCharcoal, Color(0xFF252530)],
                      )
                    : null,
              ),
              child: Center(
                child: showFront
                    ? Text(
                        widget.block.emoji,
                        style: TextStyle(fontSize: (widget.size * 0.45).clamp(18.0, 48.0)),
                      )
                    : Icon(Icons.help_outline_rounded,
                        size: (widget.size * 0.32).clamp(16.0, 36.0),
                        color: kTextMuted.withAlpha(80)),
              ),
            ),
          ),
        );
      },
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
        color: _phCharcoal,
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
        Icon(icon, size: 18, color: _phAmber),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(color: kTextSecondary, fontSize: 14, height: 1.4))),
      ],
    );
  }
}
