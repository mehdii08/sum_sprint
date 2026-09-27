import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/challenge_definition.dart';
import '../providers/challenge_provider.dart';
import '../providers/player_provider.dart';
import '../providers/result_provider.dart';
import '../services/challenge_entry.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/balance_bar_chips.dart';
import 'result_screen.dart';

class GameScreen extends StatefulWidget {
  final ChallengeDefinition challenge;

  const GameScreen({super.key, required this.challenge});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late AnimationController _correctAnimController;
  late AnimationController _wrongAnimController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shakeAnimation;
  bool _started = false;
  bool _paying = false;

  @override
  void initState() {
    super.initState();

    _correctAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _wrongAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1),
    ]).animate(_correctAnimController);

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10, end: 0), weight: 1),
    ]).animate(_wrongAnimController);
  }

  Future<void> _onStart() async {
    if (_paying) return;
    setState(() => _paying = true);
    final paid = await payChallengeEntry(context, widget.challenge);
    if (!mounted) return;
    setState(() => _paying = false);
    if (!paid) return;

    setState(() => _started = true);
    final cp = context.read<ChallengeProvider>();
    cp.startChallenge(widget.challenge);
  }

  @override
  void dispose() {
    _correctAnimController.dispose();
    _wrongAnimController.dispose();
    super.dispose();
  }

  void _triggerCorrectAnimation() => _correctAnimController.forward(from: 0);
  void _triggerWrongAnimation() => _wrongAnimController.forward(from: 0);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (!_started) {
      return _buildInstructionView(l10n);
    }

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
            actions: [
              const BalanceBarChips(padding: EdgeInsets.only(right: 8)),
            ],
          ),
          body: Consumer<ChallengeProvider>(
            builder: (context, provider, _) {
              if (provider.gameState == GameState.finished) {
                if (!_navigated) {
                  _navigated = true;
                  Timer.run(() => _navigateToResult(provider));
                }
                return const Center(child: CircularProgressIndicator(color: kAccentPurple));
              }
              return _buildGameplay(provider, l10n);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGameplay(ChallengeProvider provider, AppLocalizations l10n) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProgressDots(provider),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.roundProgress(provider.currentQuestionIndex + 1, provider.totalQuestions),
                    style: const TextStyle(color: kTextSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: kAccentPurple, size: 16),
                    const SizedBox(width: 4),
                    Text('${provider.correctCount}/${provider.totalQuestions}',
                        style: const TextStyle(color: kAccentPurple, fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCircularTimer(provider),
            const SizedBox(height: 24),
            if (provider.currentQuestion != null) ...[
              AnimatedBuilder(
                animation: Listenable.merge([_correctAnimController, _wrongAnimController]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _correctAnimController.isAnimating ? _scaleAnimation.value : 1.0,
                    child: Transform.translate(
                      offset: Offset(_wrongAnimController.isAnimating ? _shakeAnimation.value : 0, 0),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  children: [
                    _GlassNumberBox(number: provider.currentQuestion!.num1, color: kAccentCyan),
                    const SizedBox(height: 12),
                    const Text('+', style: TextStyle(color: kAccentPurple, fontSize: 28, fontWeight: FontWeight.w300)),
                    const SizedBox(height: 12),
                    _GlassNumberBox(number: provider.currentQuestion!.num2, color: kAccentGold),
                  ],
                ),
              ),
            ],
            const Spacer(),
            _buildAnswerArea(provider, l10n),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDots(ChallengeProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(provider.totalQuestions, (i) {
        final isPast = i < provider.currentQuestionIndex;
        final isCurrent = i == provider.currentQuestionIndex;
        return Container(
          width: isCurrent ? 32 : 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: isCurrent
                ? kAccentPurple
                : isPast
                    ? kAccentPurple.withAlpha(100)
                    : kTextMuted.withAlpha(60),
            boxShadow: isCurrent ? [BoxShadow(color: kAccentPurple.withAlpha(80), blurRadius: 6)] : null,
          ),
        );
      }),
    );
  }

  Widget _buildCircularTimer(ChallengeProvider provider) {
    final progress = provider.timerProgress;
    final color = progress > 0.5 ? kAccentPurple : progress > 0.25 ? kAccentGold : Colors.redAccent;
    final seconds = (provider.timeLeftMs / 1000).toStringAsFixed(1);

    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 5,
              backgroundColor: kTextPrimary.withAlpha(10),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text(seconds, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildAnswerArea(ChallengeProvider provider, AppLocalizations l10n) {
    switch (provider.gameState) {
      case GameState.waitingForOptions:
        return Container(
          height: 100,
          decoration: BoxDecoration(
            color: kAccentPurple.withAlpha(10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kAccentPurple.withAlpha(20)),
          ),
          child: Center(
            child: Text(l10n.getReady,
                style: const TextStyle(color: kTextSecondary, fontSize: 20, fontWeight: FontWeight.w500)),
          ),
        );

      case GameState.playing:
        if (provider.currentQuestion == null) return const SizedBox.shrink();
        return _buildAnswerButtons(provider);

      case GameState.showingResult:
        return _buildResultFeedback(provider, l10n);

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAnswerButtons(ChallengeProvider provider) {
    final question = provider.currentQuestion!;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: question.options.map((value) {
        return GestureDetector(
          onTap: provider.gameState != GameState.playing
              ? null
              : () {
                  provider.answerQuestion(value);
                  if (value == question.correctAnswer) {
                    _triggerCorrectAnimation();
                  } else {
                    _triggerWrongAnimation();
                  }
                },
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: provider.gameState != GameState.playing ? 0.7 : 1.0),
            duration: const Duration(milliseconds: 200),
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: kSurfaceDark,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: kAccentPurple.withAlpha(50), width: 1.5),
                boxShadow: [BoxShadow(color: kAccentPurple.withAlpha(15), blurRadius: 12)],
              ),
              child: Center(
                child: Text(value.toString(),
                    style: const TextStyle(color: kTextPrimary, fontSize: 32, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResultFeedback(ChallengeProvider provider, AppLocalizations l10n) {
    final isTimeout = provider.lastAnswerTimeout;
    final isCorrect = provider.lastAnswerCorrect;
    final correctAnswer = provider.lastCorrectAnswer;

    Color glowColor;
    IconData icon;
    String text;

    if (isTimeout) {
      glowColor = kAccentGold;
      icon = Icons.timer_off_rounded;
      text = l10n.timeUp;
    } else if (isCorrect) {
      glowColor = Colors.greenAccent;
      icon = Icons.check_circle_rounded;
      text = l10n.correct;
    } else {
      glowColor = Colors.redAccent;
      icon = Icons.cancel_rounded;
      text = l10n.wrong;
    }

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: glowColor.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: glowColor.withAlpha(50)),
        boxShadow: [BoxShadow(color: glowColor.withAlpha(15), blurRadius: 16)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: glowColor),
          const SizedBox(height: 4),
          Text(text,
              style: TextStyle(color: glowColor, fontSize: 20, fontWeight: FontWeight.bold)),
          if (!isCorrect && correctAnswer != null && !isTimeout)
            Text(l10n.answerWas(correctAnswer),
                style: TextStyle(color: glowColor.withAlpha(180), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildInstructionView(AppLocalizations l10n) {
    final challenge = widget.challenge;
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
          backgroundColor: kSurfaceDark,
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
          title: Text(challenge.name,
              style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: const [
            BalanceBarChips(),
          ],
        ),
        body: SingleChildScrollView(
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
                  border: Border.all(color: kAccentPurple.withAlpha(30), width: 0.8),
                  boxShadow: [BoxShadow(color: kAccentPurple.withAlpha(12), blurRadius: 16)],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: kAccentPurple.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                          '${l10n.roundShort(1, challenge.questionCount)}  •  ${challenge.maxPoints} ${l10n.pointsShort.toUpperCase()}',
                          style: TextStyle(color: kAccentPurple, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _GlassNumberBox(number: 47, color: kAccentCyan),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text('+', style: TextStyle(color: kAccentPurple, fontSize: 32, fontWeight: FontWeight.w300)),
                        ),
                        _GlassNumberBox(number: 28, color: kAccentGold),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kAccentPurple.withAlpha(40), width: 5),
                      ),
                      child: const Center(
                        child: Text('5.0', style: TextStyle(color: kAccentPurple, fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (_) {
                        return Container(
                          width: 70,
                          height: 70,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: kSurfaceDark,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: kAccentPurple.withAlpha(40), width: 1.5),
                          ),
                          child: const Center(
                            child: Text('?', style: TextStyle(color: kTextMuted, fontSize: 26, fontWeight: FontWeight.bold)),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(l10n.mathIntroTitle,
                  style: const TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(l10n.mathIntroSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kTextSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _InfoPill(icon: Icons.bolt_rounded, text: l10n.pillRounds(challenge.questionCount)),
                  _InfoPill(icon: Icons.timer_rounded, text: l10n.pillSecondsEach(challenge.timePerQuestionSeconds)),
                  _InfoPill(icon: Icons.star_rounded, text: l10n.pillMaxPoints(challenge.maxPoints)),
                ],
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _paying ? null : _onStart,
                    icon: _paying
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: kTextPrimary),
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
                      backgroundColor: kAccentPurple,
                      foregroundColor: kTextPrimary,
                      disabledBackgroundColor: kAccentPurple.withAlpha(120),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                      shadowColor: kAccentPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(l10n.personalBestNone.toUpperCase(),
                    style: const TextStyle(color: kTextMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
              ],
            ),
          ),
        ),
      ),
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
            child: Text(l10n.keepPlaying, style: const TextStyle(color: kAccentPurple)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final provider = context.read<ChallengeProvider>();
              provider.reset();
              Navigator.pop(context);
            },
            child: Text(l10n.quit, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  bool _navigated = false;

  void _navigateToResult(ChallengeProvider provider) {
    final playerProvider = context.read<PlayerProvider>();
    final result = provider.finalizeResult(playerProvider.playerData);
    context.read<ResultProvider>().saveResult(result);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(result: result, challenge: widget.challenge),
      ),
    );
  }
}

class _GlassNumberBox extends StatelessWidget {
  final int number;
  final Color color;
  const _GlassNumberBox({required this.number, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withAlpha(40), width: 2),
        boxShadow: [BoxShadow(color: color.withAlpha(15), blurRadius: 12)],
      ),
      child: Center(
        child: Text(number.toString(),
            style: TextStyle(color: color, fontSize: 36, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: kSurfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kAccentPurple.withAlpha(30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kAccentPurple, size: 16),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: kAccentCyan, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
