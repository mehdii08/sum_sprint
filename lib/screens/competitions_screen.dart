import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/competition.dart';
import '../providers/auth_provider.dart';
import '../providers/competition_provider.dart';
import '../l10n/app_localizations.dart';
import 'home_screen.dart';
import 'competition_detail_screen.dart';
import 'profile_screen.dart';

/// Lists all online competitions from Supabase, split into two tabs:
/// Live (upcoming + active) and Ended (finished).
class CompetitionsScreen extends StatefulWidget {
  const CompetitionsScreen({super.key});

  @override
  State<CompetitionsScreen> createState() => _CompetitionsScreenState();
}

class _CompetitionsScreenState extends State<CompetitionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final compProvider = context.read<CompetitionProvider>();
    Timer.run(() => compProvider.loadCompetitions());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Competition> _filter(List<Competition> all, {required bool live}) {
    return all.where((c) {
      final ended = c.effectiveStatus == CompetitionStatus.finished;
      return live ? !ended : ended;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final compProvider = context.watch<CompetitionProvider>();

    if (!auth.isLoggedIn) {
      final nav = Navigator.of(context);
      Timer.run(() {
        nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final liveList = _filter(compProvider.competitions, live: true);
    final endedList = _filter(compProvider.competitions, live: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Competitions'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FutureBuilder<Map<String, dynamic>?>(
              future: auth.getProfile(),
              builder: (context, snapshot) {
                final coins = snapshot.data?['coins'] ?? 0;
                return Chip(
                  avatar: const Icon(Icons.monetization_on, size: 18, color: Colors.amber),
                  label: Text(
                    '$coins coins',
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide.none,
                );
              },
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: const Color(0xFF1A237E),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.amber,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(text: 'Live (${liveList.length})'),
                Tab(text: 'Ended (${endedList.length})'),
              ],
            ),
          ),
        ),
      ),
      body: compProvider.isLoadingCompetitions
          ? const Center(child: CircularProgressIndicator())
          : compProvider.errorMessage != null && compProvider.competitions.isEmpty
              ? _ErrorView(
                  message: compProvider.errorMessage!,
                  onRetry: () => compProvider.loadCompetitions(),
                  retryLabel: l10n.retry,
                )
              : compProvider.competitions.isEmpty
                  ? const _EmptyView()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _CompetitionList(competitions: liveList),
                        _CompetitionList(competitions: endedList),
                      ],
                    ),
    );
  }
}

// ── List View ────────────────────────────────────────────────────

class _CompetitionList extends StatelessWidget {
  final List<Competition> competitions;
  const _CompetitionList({required this.competitions});

  @override
  Widget build(BuildContext context) {
    if (competitions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Nothing here yet',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<CompetitionProvider>().loadCompetitions(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: competitions.length,
        itemBuilder: (_, i) => _CompetitionCard(competition: competitions[i]),
      ),
    );
  }
}

// ── Error View ───────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String retryLabel;
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}

// ── Empty View ───────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No competitions available',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Check back soon for new events!',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                context.read<CompetitionProvider>().loadCompetitions(),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

// ── Competition Card ─────────────────────────────────────────────

class _CompetitionCard extends StatelessWidget {
  final Competition competition;
  const _CompetitionCard({required this.competition});

  Color _statusColor() {
    return switch (competition.status) {
      CompetitionStatus.active => Colors.green,
      CompetitionStatus.upcoming => Colors.orange,
      CompetitionStatus.finished => Colors.grey,
    };
  }

  String _statusLabel() {
    return switch (competition.status) {
      CompetitionStatus.active => 'LIVE',
      CompetitionStatus.upcoming => 'UPCOMING',
      CompetitionStatus.finished => 'FINISHED',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: competition.isJoinable ? 4 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CompetitionDetailScreen(competition: competition),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor().withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusLabel(),
                      style: TextStyle(
                        color: _statusColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(competition.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              if (competition.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(competition.description,
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _Chip(Icons.schedule, competition.timeRemaining, Colors.blue),
                  const SizedBox(width: 8),
                  _Chip(Icons.quiz, '${competition.challenges.length} challenges',
                      Colors.teal),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _Chip(Icons.monetization_on, '${competition.entryPoints} coins',
                      Colors.amber),
                  const SizedBox(width: 8),
                  _Chip(Icons.emoji_events, '${competition.prizePool} coins pool',
                      Colors.purple),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _Chip(Icons.workspace_premium,
                      '${competition.winnerCount} winners',
                      Colors.green),
                  const SizedBox(width: 8),
                  _Chip(Icons.pie_chart,
                      _formatShares(competition.winnerShares),
                      Colors.indigo),
                ],
              ),
              const SizedBox(height: 12),
              if (competition.status == CompetitionStatus.active)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progressValue(),
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.green),
                    minHeight: 6,
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CompetitionDetailScreen(competition: competition),
                      ),
                    );
                  },
                  icon: Icon(
                    competition.isJoinable
                        ? Icons.play_arrow
                        : competition.hasEnded
                            ? Icons.visibility
                            : Icons.schedule,
                  ),
                  label: Text(
                    competition.isJoinable
                        ? 'Join / Play'
                        : competition.hasEnded
                            ? 'View Results'
                            : 'Starts ${competition.timeRemaining}',
                    textAlign: TextAlign.center,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        competition.isJoinable ? const Color(0xFFFF6F00) : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatShares(List<double> shares) {
    if (shares.isEmpty) return '';
    final maxShow = shares.length > 3 ? 3 : shares.length;
    return shares.take(maxShow).map((s) => '${s.round()}%').join(' / ');
  }

  double _progressValue() {
    final now = DateTime.now().toUtc();
    final total = competition.endDate.difference(competition.startDate);
    final elapsed = now.difference(competition.startDate);
    if (total.inMilliseconds <= 0) return 1.0;
    return (elapsed.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
