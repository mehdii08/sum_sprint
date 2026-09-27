import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/result.dart';
import '../models/challenge_definition.dart';
import '../l10n/app_localizations.dart';
import '../providers/result_provider.dart';
import '../providers/challenge_provider.dart';
import '../providers/mind_timer_provider.dart';
import '../providers/pair_hunt_provider.dart';
import '../providers/tic_tac_toe_provider.dart';
import '../providers/tg_home_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/balance_bar_chips.dart';
import 'game_screen.dart';
import 'mind_timer_game_screen.dart';
import 'pair_hunt_game_screen.dart';
import 'tic_tac_toe_game_screen.dart';
import 'home_screen.dart';

class ResultScreen extends StatefulWidget {
  final Result result;
  final ChallengeDefinition challenge;

  const ResultScreen({
    super.key,
    required this.result,
    required this.challenge,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final Animation<double> _enterAnim;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _enterAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic);
    _enterCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TgHomeProvider>().loadProfile();
    });
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      child: Container(
        decoration: const BoxDecoration(gradient: kBgGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(l10n.resultTitle,
                style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold)),
            actions: const [
              BalanceBarChips(),
            ],
          ),
          body: SafeArea(
            top: false,
            child: FadeTransition(
              opacity: _enterAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    _TrophyHeader(result: widget.result, challenge: widget.challenge),
                    const SizedBox(height: 24),
                    Text(l10n.challengeComplete.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: kTextPrimary, fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    _GradeBadge(result: widget.result),
                    const SizedBox(height: 24),
                    _ScoreCard(result: widget.result),
                    const SizedBox(height: 20),
                    _StatsRow(result: widget.result, challenge: widget.challenge),
                    const SizedBox(height: 20),
                    FutureBuilder<int>(
                      future: context.read<ResultProvider>().getHighScore(widget.challenge.id),
                      builder: (ctx, snap) {
                        final hs = snap.data ?? 0;
                        if (widget.result.score >= hs && widget.result.score > 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [kAccentGold, Color(0xFFD97706)]),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: kAccentGold.withAlpha(40), blurRadius: 16)],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🎉', style: TextStyle(fontSize: 20)),
                                  const SizedBox(width: 8),
                                  Text(l10n.resultNewPersonalBest.toUpperCase(),
                                      style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.8)),
                                ],
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    _PrimaryButton(
                      label: l10n.playAgain.toUpperCase(),
                      icon: Icons.replay_rounded,
                      color: kAccentPurple,
                      onPressed: () {
                        if (widget.challenge.isTicTacToe) {
                          context.read<TicTacToeProvider>().reset();
                          Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (_) => TicTacToeGameScreen(challenge: widget.challenge)));
                        } else if (widget.challenge.isPairHunt) {
                          context.read<PairHuntProvider>().reset();
                          Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (_) => PairHuntGameScreen(challenge: widget.challenge)));
                        } else if (widget.challenge.isMindTimer) {
                          context.read<MindTimerProvider>().reset();
                          Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (_) => MindTimerGameScreen(challenge: widget.challenge)));
                        } else {
                          context.read<ChallengeProvider>().reset();
                          Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (_) => GameScreen(challenge: widget.challenge)));
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _SecondaryButton(
                      label: l10n.resultGoToHub.toUpperCase(),
                      icon: Icons.home_rounded,
                      onPressed: () {
                        context.read<ChallengeProvider>().reset();
                        context.read<MindTimerProvider>().reset();
                        context.read<PairHuntProvider>().reset();
                        context.read<TicTacToeProvider>().reset();
                        context.read<TgHomeProvider>().loadProfile();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (_) => false,
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrophyHeader extends StatelessWidget {
  final Result result;
  final ChallengeDefinition challenge;
  const _TrophyHeader({required this.result, required this.challenge});

  @override
  Widget build(BuildContext context) {
    final isPerfect = result.isTicTacToe
        ? result.roundsWon >= result.totalRounds && result.totalRounds > 0
        : result.isPairHunt
            ? result.pairsFound >= result.totalPairs
            : result.correctCount == challenge.questionCount;

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [isPerfect ? kAccentGold.withAlpha(80) : kAccentPurple.withAlpha(60), Colors.transparent],
        ),
        border: Border.all(color: isPerfect ? kAccentGold.withAlpha(80) : kAccentPurple.withAlpha(50), width: 2),
      ),
      child: Center(
        child: Icon(
          isPerfect ? Icons.emoji_events_rounded : Icons.workspace_premium_rounded,
          size: 48,
          color: isPerfect ? kAccentGold : kAccentPurple,
        ),
      ),
    );
  }
}

class _GradeBadge extends StatelessWidget {
  final Result result;
  const _GradeBadge({required this.result});

  String _grade() {
    if (result.isTicTacToe) {
      if (result.roundsWon == 3) return 'S';
      if (result.roundsWon == 2) return 'A';
      if (result.roundsWon == 1) return 'B';
      return 'C';
    }
    final ratio = result.correctCount / (result.totalRounds > 0 ? result.totalRounds : challenge?.questionCount ?? 10);
    if (ratio >= 1.0) return 'S';
    if (ratio >= 0.8) return 'A';
    if (ratio >= 0.6) return 'B';
    if (ratio >= 0.4) return 'C';
    return 'D';
  }

  ChallengeDefinition? get challenge => null;

  @override
  Widget build(BuildContext context) {
    final grade = _grade();
    final color = grade == 'S' || grade == 'A'
        ? kAccentGold
        : grade == 'B'
            ? kAccentCyan
            : kTextMuted;

    return Text(AppLocalizations.of(context).resultGrade(grade).toUpperCase(),
        style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2.0));
  }
}

class _ScoreCard extends StatefulWidget {
  final Result result;
  const _ScoreCard({required this.result});

  @override
  State<_ScoreCard> createState() => _ScoreCardState();
}

class _ScoreCardState extends State<_ScoreCard> with SingleTickerProviderStateMixin {
  late final AnimationController _countCtrl;
  late final Animation<int> _countAnim;

  @override
  void initState() {
    super.initState();
    _countCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _countAnim = IntTween(begin: 0, end: widget.result.score).animate(
      CurvedAnimation(parent: _countCtrl, curve: Curves.easeOut),
    );
    _countCtrl.forward();
  }

  @override
  void dispose() {
    _countCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kAccentGold.withAlpha(15), kAccentGold.withAlpha(5)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kAccentGold.withAlpha(40), width: 0.8),
        boxShadow: [BoxShadow(color: kAccentGold.withAlpha(12), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Text(AppLocalizations.of(context).resultTotalPoints.toUpperCase(),
              style: const TextStyle(color: kTextSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _countAnim,
            builder: (context, child) {
              return Text('+${_countAnim.value}',
                  style: const TextStyle(color: kAccentGold, fontSize: 56, fontWeight: FontWeight.w900));
            },
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Result result;
  final ChallengeDefinition challenge;
  const _StatsRow({required this.result, required this.challenge});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalSeconds =
        l10n.secondsShort((result.totalResponseTimeMs / 1000).toStringAsFixed(1));
    return Row(
      children: result.isTicTacToe
          ? [
              _StatCard(icon: Icons.emoji_events_rounded, color: Colors.greenAccent,
                  value: '${result.roundsWon}/${result.totalRounds}', label: l10n.ticTacToeWinsStat),
              _StatCard(icon: Icons.handshake_rounded, color: kAccentGold,
                  value: '${result.roundsDrawn}', label: l10n.ticTacToeDrawsStat),
              _StatCard(icon: Icons.timer_rounded, color: kAccentPurple,
                  value: totalSeconds, label: l10n.statTime),
            ]
          : result.isPairHunt
              ? [
                  _StatCard(icon: Icons.grid_view_rounded, color: Colors.greenAccent,
                      value: '${result.pairsFound}/${result.totalPairs}', label: l10n.pairHuntPairsFoundStat),
                  _StatCard(icon: Icons.warning_amber_rounded, color: kAccentGold,
                      value: '${result.mismatchCount}', label: l10n.pairHuntMismatchStat),
                  _StatCard(icon: Icons.timer_rounded, color: kAccentPurple,
                      value: totalSeconds, label: l10n.statTime),
                ]
              : result.isMindTimer
                  ? [
                      _StatCard(icon: Icons.check_circle_rounded, color: Colors.greenAccent,
                          value: '${result.withinRangeCount}/${challenge.questionCount}', label: l10n.statOnRange),
                      _StatCard(icon: Icons.speed_rounded, color: kAccentCyan,
                          value: '${(result.averageAccuracy * 100).toStringAsFixed(0)}%', label: l10n.statAccuracy),
                      _StatCard(icon: Icons.timer_rounded, color: kAccentPurple,
                          value: totalSeconds, label: l10n.statTime),
                    ]
                  : [
                      _StatCard(icon: Icons.check_circle_rounded, color: Colors.greenAccent,
                          value: '${result.correctCount}/${challenge.questionCount}', label: l10n.correctStat),
                      _StatCard(icon: Icons.timer_rounded, color: kAccentCyan,
                          value: result.averageTimeSeconds.toStringAsFixed(1), label: l10n.statAvgTime),
                      _StatCard(icon: Icons.speed_rounded, color: kAccentPurple,
                          value: totalSeconds, label: l10n.statTotal),
                    ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _StatCard({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: kSurfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(20)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(color: kTextMuted, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  const _PrimaryButton({required this.label, required this.icon, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: kTextPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const _SecondaryButton({required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
        style: OutlinedButton.styleFrom(
          foregroundColor: kTextPrimary,
          side: BorderSide(color: kTextPrimary.withAlpha(30)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
