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

  const GameScreen({super.key, required this.challenge});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  late AnimationController _correctAnimController;
  late AnimationController _wrongAnimController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shakeAnimation;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChallengeProvider>().startChallenge(widget.challenge);
    });
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
            // Check for game finished
            if (provider.gameState == GameState.finished && !_navigated) {
              _navigated = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _navigateToResult(provider);
              });
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.gameState == GameState.finished) {
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
    if (_navigated) {
      // Safety check: already navigating
      return;
    }

    final playerProvider = context.read<PlayerProvider>();
    final result = provider.finalizeResult(playerProvider.playerData);

    context.read<ResultProvider>().saveResult(result);

    // Use pushReplacement after microtask to avoid build-during-build
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
