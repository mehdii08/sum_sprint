import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/result.dart';
import '../providers/result_provider.dart';
import '../l10n/app_localizations.dart';

class HistoryScreen extends StatelessWidget {
  final String challengeId;
  final String challengeName;

  const HistoryScreen({
    super.key,
    required this.challengeId,
    required this.challengeName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyTitle(challengeName)),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showClearConfirmation(context, l10n),
            tooltip: l10n.clearHistory,
          ),
        ],
      ),
      body: FutureBuilder<List<Result>>(
        future: context
            .read<ResultProvider>()
            .getResultsForChallenge(challengeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final results = snapshot.data ?? [];

          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noGamesPlayed,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.noGamesPlayedHint,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return _HistoryCard(
                result: result,
                index: index,
                isBest: index == 0 &&
                    result.score ==
                        results
                            .map((r) => r.score)
                            .reduce((a, b) => a > b ? a : b),
                l10n: l10n,
              );
            },
          );
        },
      ),
    );
  }

  void _showClearConfirmation(
      BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clearHistory),
        content: Text(l10n.clearHistoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<ResultProvider>()
                  .clearHistory(challengeId);
            },
            child: Text(l10n.clear, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Result result;
  final int index;
  final bool isBest;
  final AppLocalizations l10n;

  const _HistoryCard({
    required this.result,
    required this.index,
    required this.l10n,
    this.isBest = false,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inHours < 1) return l10n.minAgo(diff.inMinutes);
    if (diff.inDays < 1) return l10n.hourAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.dayAgo(diff.inDays);
    return l10n.dateFormat(date.day, date.month, date.year);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isBest ? 4 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank / Best badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isBest ? Colors.amber.shade100 : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isBest
                    ? const Icon(Icons.emoji_events,
                        color: Colors.amber, size: 24)
                    : Text(
                        '#${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // Stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${result.score} pts',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: result.correctCount == 10
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.correctOutOf(result.correctCount),
                          style: TextStyle(
                            fontSize: 12,
                            color: result.correctCount == 10
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(result.date),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),

            // Average time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${result.averageTimeSeconds.toStringAsFixed(1)}s',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  l10n.avg,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
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
