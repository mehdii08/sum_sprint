import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/challenge_definition.dart';
import '../providers/player_provider.dart';
import '../providers/result_provider.dart';
import '../providers/mind_timer_provider.dart';
import '../services/mind_timer_scoring.dart';
import '../l10n/app_localizations.dart';
import 'result_screen.dart';

/// Game screen for Mind‑Timer challenges.
///
/// Three states per round:
///   1. **Ready** – target time + "Start" button
///   2. **Counting** – hidden timer + "Stop" button, no visible timer
///   3. **Result** – actual time, points, accuracy feedback
class MindTimerGameScreen extends StatefulWidget {
  final ChallengeDefinition challenge;
  final String? competitionId;

  const MindTimerGameScreen({
    super.key,
    required this.challenge,
    this.competitionId,
  });

  @override
  State<MindTimerGameScreen> createState() => _MindTimerGameScreenState();
}

class _MindTimerGameScreenState extends State<MindTimerGameScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 1),
    ]).animate(_pulseController);
    _pulseController.repeat();

    Timer.run(() {
      context.read<MindTimerProvider>().startChallenge(widget.challenge);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
        body: Consumer<MindTimerProvider>(
          builder: (context, provider, _) {
            // Navigate on finished
            if (provider.state == MindTimerState.finished) {
              if (!_navigated) {
                _navigated = true;
                Timer.run(() => _navigateToResult(provider));
              }
              return const Center(child: CircularProgressIndicator());
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Question counter
                    _buildHeader(provider, l10n),
                    const Spacer(flex: 1),
                    // Main content area
                    _buildContentArea(provider, l10n),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(MindTimerProvider provider, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Chip(
          avatar: const Icon(Icons.timer, size: 18),
          label: Text(
            '${provider.questionIndex}/${provider.totalQuestions}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        // Running score (points so far)
        Text(
          '${provider.state != MindTimerState.ready ? _totalSoFar(provider) : 0} pts',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.orange.shade800,
          ),
        ),
      ],
    );
  }

  int _totalSoFar(MindTimerProvider provider) {
    return provider.finalResult?.score ?? provider.runningScore;
  }

  Widget _buildContentArea(MindTimerProvider provider, AppLocalizations l10n) {
    switch (provider.state) {
      case MindTimerState.ready:
        return _buildReadyState(provider, l10n);
      case MindTimerState.counting:
        return _buildCountingState(provider, l10n);
      case MindTimerState.showingResult:
        return _buildResultState(provider, l10n);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Ready state: target + Start button ──────────────────────────

  Widget _buildReadyState(MindTimerProvider provider, AppLocalizations l10n) {
    final question = provider.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.mindTimerReadyPrompt,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        // Target time display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A237E).withAlpha(20),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF1A237E).withAlpha(60),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                l10n.stopAtExactly,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                '${question.targetSeconds.toStringAsFixed(2)}s',
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        // Start button — large & tappable (Telegram Mini App)
        SizedBox(
          width: 160,
          height: 160,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: child,
              );
            },
            child: ElevatedButton(
              onPressed: () => provider.startCounting(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6F00),
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                elevation: 8,
                padding: EdgeInsets.zero,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow, size: 48),
                  const SizedBox(height: 4),
                  Text(
                    l10n.mindTimerStart,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Counting state: no visible timer, just Stop button ──────────

  Widget _buildCountingState(MindTimerProvider provider, AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // "Counting…" indicator — subtle, no numbers
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.mindTimerCounting,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.mindTimerCountingHint,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        // Stop button — large & tappable
        SizedBox(
          width: 140,
          height: 140,
          child: ElevatedButton(
            onPressed: () => provider.stopCounting(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              elevation: 8,
              padding: EdgeInsets.zero,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stop, size: 44),
                const SizedBox(height: 4),
                Text(
                  l10n.mindTimerStop,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Result state: actual time + points + feedback ───────────────

  Widget _buildResultState(MindTimerProvider provider, AppLocalizations l10n) {
    final result = provider.lastResult;
    if (result == null) return const SizedBox.shrink();

    final label = MindTimerScoring.feedbackLabel(result.accuracy);
    final diff = result.absoluteDifference;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Actual time display
        Text(
          '${result.actualSeconds.toStringAsFixed(2)}s',
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 8),

        // Difference indicator
        Text(
          diff < 0.01 ? l10n.mindTimerPerfect : l10n.mindTimerOffBy(diff.toStringAsFixed(2)),
          style: TextStyle(
            fontSize: 16,
            color: diff < 0.01 ? Colors.green : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),

        // Points earned
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _feedbackColor(result.accuracy).withAlpha(30),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                '+${result.points}',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: _feedbackColor(result.accuracy),
                ),
              ),
              Text(
                l10n.mindTimerPoints,
                style: TextStyle(
                  fontSize: 14,
                  color: _feedbackColor(result.accuracy).withAlpha(180),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Feedback label
        Text(
          _labelText(label, l10n),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _feedbackColor(result.accuracy),
          ),
        ),

        const SizedBox(height: 12),

        // Accuracy bar
        _buildAccuracyBar(result.accuracy),
      ],
    );
  }

  Widget _buildAccuracyBar(double accuracy) {
    return Container(
      height: 8,
      width: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: accuracy.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: _feedbackColor(accuracy),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Color _feedbackColor(double accuracy) {
    if (accuracy >= 0.80) return Colors.green;
    if (accuracy >= 0.60) return Colors.lightGreen;
    if (accuracy >= 0.40) return Colors.amber;
    if (accuracy >= 0.20) return Colors.orange;
    if (accuracy > 0.0) return Colors.deepOrange;
    return Colors.red;
  }

  String _labelText(String label, AppLocalizations l10n) {
    return switch (label) {
      'perfect' => l10n.mindTimerPerfect,
      'amazing' => l10n.mindTimerAmazing,
      'great' => l10n.mindTimerGreat,
      'close' => l10n.mindTimerClose,
      'almost' => l10n.mindTimerAlmost,
      'far' => l10n.mindTimerWayOff,
      'miss' => l10n.mindTimerOutsideRange,
      _ => '',
    };
  }

  // ── Exit confirmation ───────────────────────────────────────────

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
              context.read<MindTimerProvider>().reset();
              Navigator.pop(context);
            },
            child: Text(l10n.quit, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── Navigation ──────────────────────────────────────────────────

  void _navigateToResult(MindTimerProvider provider) {
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
