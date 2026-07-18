import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/result.dart';
import '../models/challenge_definition.dart';
import '../providers/result_provider.dart';
import '../providers/challenge_provider.dart';
import '../providers/mind_timer_provider.dart';
import '../providers/pair_hunt_provider.dart';
import '../providers/competition_provider.dart';
import '../l10n/app_localizations.dart';
import 'game_screen.dart';
import 'mind_timer_game_screen.dart';
import 'pair_hunt_game_screen.dart';
import 'home_screen.dart';

class ResultScreen extends StatefulWidget {
  final Result result;
  final ChallengeDefinition challenge;
  final String? competitionId;

  const ResultScreen({
    super.key,
    required this.result,
    required this.challenge,
    this.competitionId,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _submitting = false;
  bool _submitted = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    if (widget.competitionId != null) {
      _submitToCompetition();
    }
  }

  Future<void> _submitToCompetition() async {
    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final cp = context.read<CompetitionProvider>();
      await cp
          .submitChallengeResult(widget.result)
          .timeout(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _submitting = false;
          _submitted = true;
        });
      }
    } catch (e) {
      debugPrint('_submitToCompetition error: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _submitting = false;
          _submitError = l10n.scoreSavedLocally;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isCompetition = widget.competitionId != null;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A237E), Color(0xFF4A148C)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.result.isPairHunt
                            ? (widget.result.pairsFound >= widget.result.totalPairs
                                ? Icons.emoji_events
                                : Icons.grid_view)
                            : widget.result.correctCount == widget.challenge.questionCount
                                ? Icons.emoji_events
                                : Icons.workspace_premium,
                        size: 72,
                        color: widget.result.isPairHunt
                            ? (widget.result.pairsFound >= widget.result.totalPairs
                                ? Colors.amber
                                : Colors.white70)
                            : widget.result.correctCount == widget.challenge.questionCount
                                ? Colors.amber
                                : Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(l10n.challengeComplete,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 32),

                    // Submission status
                    if (_submitting)
                      _statusBanner(Icons.cloud_upload, l10n.submittingScore, Colors.white70, Colors.white.withAlpha(30)),
                    if (_submitted)
                      _statusBanner(Icons.cloud_done, l10n.scoreSubmitted, Colors.green, Colors.green.shade400.withAlpha(50)),
                    if (_submitError != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_off, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_submitError!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                            TextButton(onPressed: _submitToCompetition, child: Text(l10n.retry, style: const TextStyle(fontSize: 12))),
                          ],
                        ),
                      ),

                    // Score card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: Column(
                        children: [
                          Text(l10n.finalScore, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text('${widget.result.score}',
                              style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Color(0xFFFF6F00))),
                          const SizedBox(height: 4),
                          Text(l10n.points, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                          const Divider(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: widget.result.isPairHunt
                                ? [
                                    _StatItem(icon: Icons.grid_view, color: Colors.green,
                                        value: '${widget.result.pairsFound}/${widget.result.totalPairs}', label: l10n.pairHuntPairsFoundStat),
                                    _StatItem(icon: Icons.warning_amber, color: Colors.orange,
                                        value: '${widget.result.mismatchCount}', label: l10n.pairHuntMismatchStat),
                                    _StatItem(icon: Icons.timer, color: Colors.purple,
                                        value: '${(widget.result.totalResponseTimeMs / 1000).toStringAsFixed(1)}s', label: l10n.pairHuntTimeTakenStat),
                                  ]
                                : widget.result.isMindTimer
                                    ? [
                                        _StatItem(icon: Icons.check_circle, color: Colors.green,
                                            value: '${widget.result.withinRangeCount}/${widget.challenge.questionCount}', label: l10n.withinRangeStat),
                                        _StatItem(icon: Icons.speed, color: Colors.blue,
                                            value: '${(widget.result.averageAccuracy * 100).toStringAsFixed(0)}%', label: l10n.avgAccuracyStat),
                                        _StatItem(icon: Icons.timer, color: Colors.purple,
                                            value: '${(widget.result.totalResponseTimeMs / 1000).toStringAsFixed(1)}s', label: l10n.totalTimeStat),
                                      ]
                                    : [
                                        _StatItem(icon: Icons.check_circle, color: Colors.green,
                                            value: '${widget.result.correctCount}/${widget.challenge.questionCount}', label: l10n.correctStat),
                                        _StatItem(icon: Icons.timer, color: Colors.blue,
                                            value: widget.result.averageTimeSeconds.toStringAsFixed(1), label: l10n.avgTimeStat),
                                        _StatItem(icon: Icons.speed, color: Colors.purple,
                                            value: '${(widget.result.totalResponseTimeMs / 1000).toStringAsFixed(1)}s', label: l10n.totalTimeStat),
                                      ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // High score badge (offline only)
                    if (!isCompetition)
                      FutureBuilder<int>(
                        future: context.read<ResultProvider>().getHighScore(widget.challenge.id),
                        builder: (ctx, snap) {
                          final hs = snap.data ?? 0;
                          if (widget.result.score >= hs && widget.result.score > 0) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(color: Colors.amber.shade400, borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(l10n.newHighScore, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    const SizedBox(height: 40),

                    // Play Again (offline mode only — competition challenges are one-shot)
                    if (!isCompetition) ...[
                      SizedBox(
                        width: double.infinity, height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (widget.challenge.isPairHunt) {
                              context.read<PairHuntProvider>().reset();
                              Navigator.pushReplacement(context,
                                  MaterialPageRoute(builder: (_) => PairHuntGameScreen(challenge: widget.challenge, competitionId: widget.competitionId)));
                            } else if (widget.challenge.isMindTimer) {
                              context.read<MindTimerProvider>().reset();
                              Navigator.pushReplacement(context,
                                  MaterialPageRoute(builder: (_) => MindTimerGameScreen(challenge: widget.challenge, competitionId: widget.competitionId)));
                            } else {
                              context.read<ChallengeProvider>().reset();
                              Navigator.pushReplacement(context,
                                  MaterialPageRoute(builder: (_) => GameScreen(challenge: widget.challenge, competitionId: widget.competitionId)));
                            }
                          },
                          icon: const Icon(Icons.replay),
                          label: Text(l10n.playAgain, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6F00), foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Home / Back
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<ChallengeProvider>().reset();
                          context.read<MindTimerProvider>().reset();
                          context.read<PairHuntProvider>().reset();
                          if (isCompetition) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushAndRemoveUntil(context,
                                MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
                          }
                        },
                        icon: Icon(isCompetition ? Icons.arrow_back : Icons.home),
                        label: Text(isCompetition ? l10n.backToCompetition : l10n.home,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBanner(IconData icon, String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon; final Color color; final String value; final String label;
  const _StatItem({required this.icon, required this.color, required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: color, size: 28), const SizedBox(height: 8),
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
    ]);
  }
}
