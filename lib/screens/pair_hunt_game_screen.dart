import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/challenge_definition.dart';
import '../models/question.dart';
import '../providers/player_provider.dart';
import '../providers/result_provider.dart';
import '../providers/pair_hunt_provider.dart';
import '../l10n/app_localizations.dart';
import 'result_screen.dart';

/// Game screen for Pair‑Hunt challenges.
///
/// Three visual states:
///   1. **Intro** – challenge info + Start button
///   2. **Playing** – grid of face-down blocks + countdown timer
///   3. **Finished** – navigates to ResultScreen
class PairHuntGameScreen extends StatefulWidget {
  final ChallengeDefinition challenge;
  final String? competitionId;

  const PairHuntGameScreen({
    super.key,
    required this.challenge,
    this.competitionId,
  });

  @override
  State<PairHuntGameScreen> createState() => _PairHuntGameScreenState();
}

class _PairHuntGameScreenState extends State<PairHuntGameScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    Timer.run(() {
      context.read<PairHuntProvider>().startChallenge(widget.challenge);
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
        body: Consumer<PairHuntProvider>(
          builder: (context, provider, _) {
            if (provider.state == PairHuntState.finished) {
              if (!_navigated) {
                _navigated = true;
                Timer.run(() => _navigateToResult(provider));
              }
              return const Center(child: CircularProgressIndicator());
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
            if (provider.state != PairHuntState.intro) {
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
                      l10n.pairHuntStart,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
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

  Widget _buildIntroView(PairHuntProvider provider, AppLocalizations l10n) {
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
              color: Colors.purple.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.grid_view,
              size: 40,
              color: Colors.purple,
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
            icon: Icons.grid_on,
            label: l10n.pairHuntPairs,
            value: '${challenge.pairCount} ${l10n.pairHuntPairsLabel}',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.timer,
            label: l10n.pairHuntTimeLimit,
            value: l10n.pairHuntTimeLimitValue(challenge.timeLimitSeconds),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.extension,
            label: l10n.pairHuntBlocks,
            value: '${challenge.blockCount}',
          ),
          const SizedBox(height: 28),
          // "How to Play" section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
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
                      l10n.pairHuntHowToPlay,
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
                  text: l10n.pairHuntRule1,
                ),
                const SizedBox(height: 12),
                _InstructionRow(
                  icon: Icons.swap_horiz,
                  text: l10n.pairHuntRule2,
                ),
                const SizedBox(height: 12),
                _InstructionRow(
                  icon: Icons.emoji_emotions,
                  text: l10n.pairHuntRule3,
                ),
                const SizedBox(height: 12),
                _InstructionRow(
                  icon: Icons.timer,
                  text: l10n.pairHuntRule4(challenge.timeLimitSeconds),
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

  Widget _buildGameView(PairHuntProvider provider, AppLocalizations l10n) {
    final blockCount = widget.challenge.blockCount;
    final rows = blockCount ~/ 4;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          // Top bar: timer + progress
          _buildTimerBar(provider, l10n),
          const SizedBox(height: 8),
          // Progress: "3/6 pairs"
          Text(
            l10n.pairHuntProgress(provider.pairsFound, provider.totalPairs),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          // Grid (centered)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate grid dimensions to fit on screen.
                final availableHeight = constraints.maxHeight;
                final availableWidth = constraints.maxWidth;
                final maxBlockWidth = availableWidth / 4;
                final maxBlockHeight = availableHeight / rows;
                // Use the smaller dimension to keep blocks square with spacing.
                final blockSize = (maxBlockWidth < maxBlockHeight
                        ? maxBlockWidth
                        : maxBlockHeight) -
                    12; // subtract for spacing

                final clampedSize = blockSize.clamp(40.0, 120.0);
                final totalGridWidth =
                    (clampedSize * 4) + (8 * 3); // 4 columns, 3 gaps
                final totalGridHeight =
                    (clampedSize * rows) + (8 * (rows - 1));

                return Center(
                  child: SizedBox(
                    width: totalGridWidth,
                    height: totalGridHeight,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
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
                          isShowingMismatch: provider.isShowingMismatch &&
                              provider.revealedIndices.contains(index),
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

  Widget _buildTimerBar(PairHuntProvider provider, AppLocalizations l10n) {
    return Column(
      children: [
        // Timer bar
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
        // Time remaining
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.pairHuntTimeRemaining(
                provider.timeRemainingSeconds,
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: provider.timerProgress < 0.33
                    ? Colors.red
                    : Colors.grey.shade700,
              ),
            ),
            Text(
              '${provider.mismatchCount} ${l10n.pairHuntMismatches}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ],
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
              context.read<PairHuntProvider>().reset();
              Navigator.pop(context);
            },
            child: Text(l10n.quit, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── Navigation ───────────────────────────────────────────────────

  void _navigateToResult(PairHuntProvider provider) {
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

// ── Block widget ───────────────────────────────────────────────────

class _PairHuntBlockWidget extends StatefulWidget {
  final PairHuntBlock block;
  final double size;
  final bool isShowingMismatch;
  final VoidCallback onTap;

  const _PairHuntBlockWidget({
    required this.block,
    required this.size,
    required this.isShowingMismatch,
    required this.onTap,
  });

  @override
  State<_PairHuntBlockWidget> createState() => _PairHuntBlockWidgetState();
}

class _PairHuntBlockWidgetState extends State<_PairHuntBlockWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  bool _wasRevealed = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
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
        // Perspective flip: show back when animation < 0.5, front when >= 0.5
        final showFront = _flipAnimation.value >= 0.5;
        final scaleX = (_flipAnimation.value - 0.5).abs() * 2; // 1 → 0 → 1

        return Transform.scale(
          scaleX: scaleX,
          scaleY: 1.0,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: isFaceUp ? null : widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                color: showFront
                    ? (isMatched
                        ? Colors.green.shade100
                        : Colors.white)
                    : const Color(0xFF1A237E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isMatched
                      ? Colors.green
                      : showFront
                          ? Colors.grey.shade300
                          : const Color(0xFF1A237E).withAlpha(100),
                  width: isMatched ? 2.5 : 1.5,
                ),
                boxShadow: isMatched
                    ? [
                        BoxShadow(
                          color: Colors.green.withAlpha(60),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Center(
                child: showFront
                    ? Text(
                        widget.block.emoji,
                        style: TextStyle(
                          fontSize: (widget.size * 0.45).clamp(18.0, 48.0),
                        ),
                      )
                    : Icon(
                        Icons.help_outline,
                        size: (widget.size * 0.35).clamp(16.0, 40.0),
                        color: Colors.white70,
                      ),
              ),
            ),
          ),
        );
      },
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
