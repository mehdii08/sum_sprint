import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/challenge_definition.dart';
import '../providers/challenge_provider.dart';
import '../providers/player_provider.dart';
import '../providers/result_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/answer_button.dart';
import '../widgets/timer_bar.dart';
import '../widgets/score_display.dart';
import 'result_screen.dart';

class GameScreen extends StatefulWidget {
  final ChallengeDefinition challenge;
  /// If non-null, the game is played in competition mode and results
  /// should be submitted to Supabase for this competition.
  final String? competitionId;

  const GameScreen({super.key, required this.challenge, this.competitionId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  late AnimationController _correctAnimController;
  late AnimationController _wrongAnimController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shakeAnimation;
  bool _started = false;

  @override
  void initState() {
    super.initState();

    _correctAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _wrongAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

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

  void _onStart() {
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

  void _triggerCorrectAnimation() {
    _correctAnimController.forward(from: 0);
  }

  void _triggerWrongAnimation() {
    _wrongAnimController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Before the challenge starts, show the "How to Play" instructions.
    if (!_started) {
      return _buildInstructionView(l10n);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitConfirmation(l10n);
        }
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
        body: Consumer<ChallengeProvider>(
          builder: (context, provider, _) {
            // Check for game finished — navigate via addPostFrameCallback
            // so the current frame completes before we replace the screen.
            if (provider.gameState == GameState.finished) {
              if (!_navigated) {
                _navigated = true;
                Timer.run(() => _navigateToResult(provider));
              }
              return const Center(child: CircularProgressIndicator());
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Top bar: question counter and score
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.quiz, size: 18),
                          label: Text(
                            '${provider.currentQuestionIndex + 1}/${provider.totalQuestions}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        ScoreDisplay(
                          score: 0,
                          correctCount: provider.correctCount,
                          totalQuestions: provider.totalQuestions,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Timer bar
                    TimerBar(progress: provider.timerProgress),
                    const SizedBox(height: 8),

                    // Time left text
                    Text(
                      '${(provider.timeLeftMs / 1000).toStringAsFixed(1)}s',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: provider.timerProgress < 0.33
                            ? Colors.red
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Number boxes
                    if (provider.currentQuestion != null) ...[
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          _correctAnimController,
                          _wrongAnimController,
                        ]),
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _correctAnimController.isAnimating
                                ? _scaleAnimation.value
                                : 1.0,
                            child: Transform.translate(
                              offset: Offset(
                                _wrongAnimController.isAnimating
                                    ? _shakeAnimation.value
                                    : 0,
                                0,
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _NumberBox(
                              number: provider.currentQuestion!.num1,
                              color: Colors.blue.shade100,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                '+',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _NumberBox(
                              number: provider.currentQuestion!.num2,
                              color: Colors.orange.shade100,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Answer buttons / Waiting / Time's Up
                    _buildAnswerArea(provider, l10n),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnswerArea(ChallengeProvider provider, AppLocalizations l10n) {
    switch (provider.gameState) {
      case GameState.waitingForOptions:
        return SizedBox(
          height: 100,
          child: Center(
            child: Text(
              l10n.getReady,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );

      case GameState.playing:
        if (provider.currentQuestion == null) {
          return const SizedBox.shrink();
        }
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
        return AnswerButton(
          value: value,
          onTap: () {
            provider.answerQuestion(value);
            final isCorrect = value == question.correctAnswer;
            if (isCorrect) {
              _triggerCorrectAnimation();
            } else {
              _triggerWrongAnimation();
            }
          },
          isDisabled: provider.gameState != GameState.playing,
        );
      }).toList(),
    );
  }

  Widget _buildResultFeedback(
      ChallengeProvider provider, AppLocalizations l10n) {
    final isTimeout = provider.lastAnswerTimeout;
    final isCorrect = provider.lastAnswerCorrect;

    Color bgColor;
    IconData icon;
    String text;

    if (isTimeout) {
      bgColor = Colors.orange.shade100;
      icon = Icons.timer_off;
      text = l10n.timeUp;
    } else if (isCorrect) {
      bgColor = Colors.green.shade100;
      icon = Icons.check_circle;
      text = l10n.correct;
    } else {
      bgColor = Colors.red.shade100;
      icon = Icons.cancel;
      text = l10n.wrong;
    }

    // Show correct answer if wrong (use stored answer from before advancing)
    final correctAnswer = provider.lastCorrectAnswer;

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: isCorrect ? Colors.green : Colors.red),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
            ),
          ),
          if (!isCorrect && correctAnswer != null && !isTimeout)
            Text(
              l10n.answerWas(correctAnswer),
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstructionView(AppLocalizations l10n) {
    final challenge = widget.challenge;
    return Scaffold(
      appBar: AppBar(
        title: Text(challenge.name),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Header icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6F00).withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calculate,
                  size: 40,
                  color: Color(0xFFFF6F00),
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
              // "How to Play" section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
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
                          l10n.challengeHowToPlay,
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
                      icon: Icons.looks_one,
                      text: l10n.challengeRuleAdd,
                    ),
                    const SizedBox(height: 12),
                    _InstructionRow(
                      icon: Icons.touch_app,
                      text: l10n.challengeRuleAnswer,
                    ),
                    const SizedBox(height: 12),
                    _InstructionRow(
                      icon: Icons.timer,
                      text: l10n.challengeRuleTimer(
                          challenge.timePerQuestionSeconds),
                    ),
                    const SizedBox(height: 12),
                    _InstructionRow(
                      icon: Icons.quiz,
                      text: l10n
                          .challengeRuleQuestions(challenge.questionCount),
                    ),
                    const SizedBox(height: 12),
                    _InstructionRow(
                      icon: Icons.star,
                      text: l10n.challengeRuleScore,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _onStart,
              icon: const Icon(Icons.play_arrow, size: 28),
              label: Text(
                l10n.challengeStart,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6F00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
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
              final provider = context.read<ChallengeProvider>();
              provider.reset();
              Navigator.pop(context);
            },
            child: Text(l10n.quit, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  bool _navigated = false;

  void _navigateToResult(ChallengeProvider provider) {
    debugPrint('[GameScreen] _navigateToResult — competitionId=${widget.competitionId}');
    final playerProvider = context.read<PlayerProvider>();
    final result = provider.finalizeResult(playerProvider.playerData);
    debugPrint('[GameScreen] _navigateToResult — score=${result.score} correct=${result.correctCount}');

    context.read<ResultProvider>().saveResult(result);

    if (!mounted) return;

    if (widget.competitionId != null) {
      // Competition mode: pop with result data so the parent detail screen
      // can push ResultScreen and reload state at the right time.
      Navigator.pop(context, {
        'result': result,
        'challenge': widget.challenge,
        'competitionId': widget.competitionId,
      });
    } else {
      // Offline warm-up mode: push ResultScreen directly (existing behaviour).
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

class _NumberBox extends StatelessWidget {
  final int number;
  final Color color;

  const _NumberBox({required this.number, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withAlpha(200),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(100),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          number.toString(),
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
      ),
    );
  }
}
