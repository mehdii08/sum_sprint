import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/challenge_provider.dart';
import '../providers/result_provider.dart';
import '../models/challenge_definition.dart';
import '../l10n/app_localizations.dart';
import 'game_screen.dart';
import 'mind_timer_game_screen.dart';
import 'pair_hunt_game_screen.dart';
import 'tic_tac_toe_game_screen.dart';
import 'history_screen.dart';

class ChallengeListScreen extends StatelessWidget {
  const ChallengeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.warmUpChallenges),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Consumer<ChallengeProvider>(
        builder: (context, challengeProvider, _) {
          if (challengeProvider.isLoadingChallenges) {
            return const Center(child: CircularProgressIndicator());
          }
          if (challengeProvider.loadError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(challengeProvider.loadError!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => challengeProvider.loadChallenges(),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }
          if (challengeProvider.challenges.isEmpty) {
            return Center(child: Text(l10n.noChallenges));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: challengeProvider.challenges.length,
            itemBuilder: (context, index) {
              final challenge = challengeProvider.challenges[index];
              return _ChallengeCard(challenge: challenge, l10n: l10n);
            },
          );
        },
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final ChallengeDefinition challenge;
  final AppLocalizations l10n;

  const _ChallengeCard({required this.challenge, required this.l10n});

  Color _getDifficultyColor() {
    if (challenge.isTicTacToe) {
      return Colors.teal;
    }
    if (challenge.isPairHunt) {
      switch (challenge.id) {
        case 'pair_hunt_easy':
          return Colors.purple;
        case 'pair_hunt_medium':
          return Colors.deepPurple;
        case 'pair_hunt_hard':
          return Colors.indigo;
        default:
          return Colors.purple;
      }
    }
    if (challenge.isMindTimer) {
      switch (challenge.id) {
        case 'mind_timer_easy':
          return Colors.teal;
        case 'mind_timer_medium':
          return Colors.blue;
        case 'mind_timer_hard':
          return Colors.deepPurple;
        default:
          return Colors.indigo;
      }
    }
    switch (challenge.id) {
      case 'easy_add':
        return Colors.green;
      case 'medium_add':
        return Colors.orange;
      case 'hard_mix':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getDifficultyIcon() {
    if (challenge.isTicTacToe) return Icons.grid_3x3;
    if (challenge.isPairHunt) return Icons.grid_view;
    if (challenge.isMindTimer) return Icons.timer;
    return Icons.calculate;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor().withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getDifficultyIcon(),
                    color: _getDifficultyColor(),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        challenge.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Best Score
            FutureBuilder<int>(
              future:
                  context.read<ResultProvider>().getHighScore(challenge.id),
              builder: (context, snapshot) {
                final highScore = snapshot.data ?? 0;
                return Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 18,
                      color: highScore > 0
                          ? Colors.amber
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      highScore > 0
                          ? '${l10n.best}: ${l10n.bestScore(highScore)}'
                          : l10n.bestScoreNone,
                      style: TextStyle(
                        fontSize: 13,
                        color: highScore > 0
                            ? Colors.amber.shade800
                            : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            // Buttons row
            Row(
              children: [
                // History button
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HistoryScreen(
                          challengeId: challenge.id,
                          challengeName: challenge.name,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history, size: 18),
                  label: Text(l10n.history),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Play button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) {
                            if (challenge.isTicTacToe) {
                              return TicTacToeGameScreen(challenge: challenge);
                            }
                            if (challenge.isPairHunt) {
                              return PairHuntGameScreen(challenge: challenge);
                            }
                            if (challenge.isMindTimer) {
                              return MindTimerGameScreen(challenge: challenge);
                            }
                            return GameScreen(challenge: challenge);
                          },
                        ),
                      );
                    },
                    icon: Icon(challenge.isTicTacToe
                        ? Icons.grid_3x3
                        : challenge.isPairHunt
                            ? Icons.grid_view
                            : challenge.isMindTimer
                                ? Icons.timer
                                : Icons.play_arrow),
                    label: Text(
                      l10n.play,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6F00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
