import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/challenge_definition.dart';
import '../providers/player_provider.dart';
import '../providers/result_provider.dart';
import '../providers/mind_timer_provider.dart';
import '../services/challenge_entry.dart';
import '../services/mind_timer_scoring.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/balance_bar_chips.dart';
import 'result_screen.dart';

const _mtEmerald = Color(0xFF00C853);
const _mtEmeraldLight = Color(0xFF00E676);
const _mtBg = Color(0xFF08090B);
const _mtSurface = Color(0xFF111418);

class MindTimerGameScreen extends StatefulWidget {
  final ChallengeDefinition challenge;

  const MindTimerGameScreen({super.key, required this.challenge});

  @override
  State<MindTimerGameScreen> createState() => _MindTimerGameScreenState();
}

class _MindTimerGameScreenState extends State<MindTimerGameScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _ringController;
  late Animation<double> _ringAnimation;
  bool _navigated = false;
  bool _entryPaid = false;
  bool _paying = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 1),
    ]).animate(_pulseController);
    _pulseController.repeat();

    _ringController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _ringAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeInOut),
    );
    _ringController.repeat(reverse: true);

    Timer.run(() => context.read<MindTimerProvider>().startChallenge(widget.challenge));
  }

  Future<void> _onStartRound(MindTimerProvider provider) async {
    // Charge once on the first round only.
    if (!_entryPaid) {
      if (_paying) return;
      setState(() => _paying = true);
      final paid = await payChallengeEntry(context, widget.challenge);
      if (!mounted) return;
      setState(() => _paying = false);
      if (!paid) return;
      _entryPaid = true;
    }
    provider.startCounting();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ringController.dispose();
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
      child: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [_mtBg, Color(0xFF0D1117)],
        )),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(widget.challenge.name,
                style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold)),
            backgroundColor: _mtSurface,
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
          body: Consumer<MindTimerProvider>(
            builder: (context, provider, _) {
              if (provider.state == MindTimerState.finished) {
                if (!_navigated) {
                  _navigated = true;
                  Timer.run(() => _navigateToResult(provider));
                }
                return const Center(child: CircularProgressIndicator(color: _mtEmerald));
              }
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildHeader(provider, l10n),
                      const Spacer(flex: 1),
                      _buildContentArea(provider, l10n),
                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(MindTimerProvider provider, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _mtEmerald.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _mtEmerald.withAlpha(30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_rounded, color: _mtEmeraldLight, size: 16),
              const SizedBox(width: 6),
              Text('ROUND ${provider.questionIndex}/${provider.totalQuestions}',
                  style: const TextStyle(color: _mtEmeraldLight, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: kAccentGold.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kAccentGold.withAlpha(30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: kAccentGold, size: 16),
              const SizedBox(width: 4),
              Text('${_totalSoFar(provider)}',
                  style: const TextStyle(color: kAccentGold, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  int _totalSoFar(MindTimerProvider provider) {
    return provider.finalResult?.score ?? provider.runningScore;
  }

  Widget _buildContentArea(MindTimerProvider provider, AppLocalizations l10n) {
    return switch (provider.state) {
      MindTimerState.ready => _buildReadyState(provider, l10n),
      MindTimerState.counting => _buildCountingState(provider, l10n),
      MindTimerState.showingResult => _buildResultState(provider, l10n),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildReadyState(MindTimerProvider provider, AppLocalizations l10n) {
    final question = provider.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('SEE TARGET', style: TextStyle(color: kTextMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 2.0)),
        const SizedBox(height: 16),
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [_mtEmerald.withAlpha(30), Colors.transparent]),
            border: Border.all(color: _mtEmerald.withAlpha(50), width: 2),
            boxShadow: [BoxShadow(color: _mtEmerald.withAlpha(20), blurRadius: 32)],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(question.targetSeconds.toStringAsFixed(1),
                  style: const TextStyle(color: _mtEmeraldLight, fontSize: 56, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text('s', style: TextStyle(color: _mtEmeraldLight, fontSize: 20, fontWeight: FontWeight.w300)),
            ],
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _ringAnimation,
                builder: (context, child) {
                  return Container(
                    width: 160 * _ringAnimation.value,
                    height: 160 * _ringAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _mtEmerald.withAlpha(40), width: 1.5),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(scale: _pulseAnimation.value, child: child);
                },
                child: GestureDetector(
                  onTap: _paying ? null : () => _onStartRound(provider),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(colors: [_mtEmerald, Color(0xFF009624)]),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: _mtEmerald.withAlpha(60), blurRadius: 24, spreadRadius: 4),
                        BoxShadow(color: _mtEmerald.withAlpha(30), blurRadius: 48),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_paying)
                          const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2, color: kTextPrimary),
                          )
                        else
                          Icon(
                            (!_entryPaid && !widget.challenge.isFree)
                                ? Icons.monetization_on_rounded
                                : Icons.play_arrow_rounded,
                            color: kTextPrimary,
                            size: 44,
                          ),
                        const SizedBox(height: 2),
                        Text(
                          (!_entryPaid && !widget.challenge.isFree)
                              ? 'START · ${widget.challenge.entryCoins}'
                              : 'START',
                          style: const TextStyle(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('TIMER HIDES WHEN YOU TAP',
            style: TextStyle(color: kTextMuted, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildCountingState(MindTimerProvider provider, AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('COUNTING...', style: TextStyle(color: kTextMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 2.0)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: _mtEmerald.withAlpha(12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _mtEmerald.withAlpha(25)),
          ),
          child: const Column(
            children: [
              Text('Count in your mind.', style: TextStyle(color: kTextSecondary, fontSize: 15)),
              SizedBox(height: 4),
              Text('Stop when you feel the time.', style: TextStyle(color: kTextMuted, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 48),
        GestureDetector(
          onTap: () => provider.stopCounting(),
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: const RadialGradient(colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.redAccent.withAlpha(60), blurRadius: 24, spreadRadius: 4),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.stop_rounded, color: kTextPrimary, size: 44),
                SizedBox(height: 2),
                Text('STOP', style: TextStyle(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultState(MindTimerProvider provider, AppLocalizations l10n) {
    final result = provider.lastResult;
    if (result == null) return const SizedBox.shrink();

    final label = MindTimerScoring.feedbackLabel(result.accuracy);
    final diff = result.absoluteDifference;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('${result.actualSeconds.toStringAsFixed(2)}s',
            style: const TextStyle(color: kTextPrimary, fontSize: 56, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(diff < 0.01 ? l10n.mindTimerPerfect : l10n.mindTimerOffBy(diff.toStringAsFixed(2)),
            style: TextStyle(
              color: diff < 0.01 ? _mtEmeraldLight : kTextSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            )),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: _feedbackColor(result.accuracy).withAlpha(20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _feedbackColor(result.accuracy).withAlpha(50)),
            boxShadow: [BoxShadow(color: _feedbackColor(result.accuracy).withAlpha(15), blurRadius: 16)],
          ),
          child: Column(
            children: [
              Text('+${result.points}',
                  style: TextStyle(color: _feedbackColor(result.accuracy), fontSize: 42, fontWeight: FontWeight.w900)),
              Text(l10n.mindTimerPoints,
                  style: TextStyle(color: _feedbackColor(result.accuracy).withAlpha(180), fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(_labelText(label, l10n),
            style: TextStyle(color: _feedbackColor(result.accuracy), fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildAccuracyBar(result.accuracy),
      ],
    );
  }

  Widget _buildAccuracyBar(double accuracy) {
    return Container(
      height: 6,
      width: 220,
      decoration: BoxDecoration(
        color: kTextPrimary.withAlpha(8),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: accuracy.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: _feedbackColor(accuracy),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [BoxShadow(color: _feedbackColor(accuracy).withAlpha(60), blurRadius: 6)],
          ),
        ),
      ),
    );
  }

  Color _feedbackColor(double accuracy) {
    if (accuracy >= 0.80) return _mtEmeraldLight;
    if (accuracy >= 0.60) return Colors.lightGreenAccent;
    if (accuracy >= 0.40) return Colors.amber;
    if (accuracy >= 0.20) return Colors.orangeAccent;
    if (accuracy > 0.0) return Colors.deepOrangeAccent;
    return Colors.redAccent;
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

  void _showExitConfirmation(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _mtSurface,
        title: Text(l10n.quitGame, style: const TextStyle(color: kTextPrimary)),
        content: Text(l10n.quitGameConfirm, style: const TextStyle(color: kTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.keepPlaying, style: const TextStyle(color: _mtEmeraldLight)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MindTimerProvider>().reset();
              Navigator.pop(context);
            },
            child: Text(l10n.quit, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _navigateToResult(MindTimerProvider provider) {
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
