import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/competition.dart';
import '../models/challenge_definition.dart';
import '../models/result.dart';
import '../providers/auth_provider.dart';
import '../providers/competition_provider.dart';
import 'game_screen.dart';
import 'result_screen.dart';

/// Detail view for a single competition.
///
/// Shows competition info, challenge list, leaderboard tab,
/// and a join/play button. Runs challenges in competition mode
/// (results are submitted to Supabase).
class CompetitionDetailScreen extends StatefulWidget {
  final Competition competition;

  const CompetitionDetailScreen({super.key, required this.competition});

  @override
  State<CompetitionDetailScreen> createState() =>
      _CompetitionDetailScreenState();
}

class _CompetitionDetailScreenState extends State<CompetitionDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasJoined = false;
  bool _isJoining = false;
  int? _myScore;
  int? _myFinalRank;
  int? _myPrize;
  Set<String> _completedChallengeIds = {};
  bool _isInitialLoading = true;
  bool _isRefreshing = false;
  String? _loadError;

  // Live leaderboard via Supabase Realtime
  RealtimeChannel? _leaderboardChannel;
  List<LeaderboardEntry> _liveEntries = [];
  bool _isLiveLoading = false;
  int _lastLeaderboardTab = 0; // track tab switches

  // Periodic timer for updating time-remaining display
  late Timer _tickTimer;
  DateTime _now = DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now().toUtc());
    });
    Timer.run(() {
      _loadState();
    });
  }

  /// Live-updating time remaining based on [_now] (ticks every second).
  String get _liveTimeRemaining {
    final comp = widget.competition;
    if (comp.hasEnded) return 'Finished';
    if (!comp.hasStarted) {
      final diff = comp.startDate.difference(_now);
      if (diff.inDays > 0) return _formatDuration(diff, prefix: 'Starts in ');
      if (diff.inHours > 0) return _formatDuration(diff, prefix: 'Starts in ');
      if (diff.inMinutes > 1) return _formatDuration(diff, prefix: 'Starts in ');
      return 'Starting soon';
    }
    final diff = comp.endDate.difference(_now);
    if (diff.isNegative || diff.inMinutes < 1) return 'Ending soon';
    return _formatDuration(diff, suffix: ' left');
  }

  static String _formatDuration(Duration d, {String prefix = '', String suffix = ''}) {
    final parts = <String>[];
    if (d.inDays > 0) parts.add('${d.inDays}d');
    if (d.inHours.remainder(24) > 0) parts.add('${d.inHours.remainder(24)}h');
    if (d.inMinutes.remainder(60) > 0) parts.add('${d.inMinutes.remainder(60)}m');
    if (parts.isEmpty && d.inSeconds > 0) parts.add('${d.inSeconds}s');
    return '$prefix${parts.join(' ')}$suffix';
  }

  void _onTabChanged() {
    final currentIndex = _tabController.index;
    // Only act when switching TO the leaderboard tab
    if (currentIndex == 1 && _lastLeaderboardTab == 0) {
      _startLiveLeaderboard();
    }
    _lastLeaderboardTab = currentIndex;
  }

  /// Subscribe to realtime changes on the participants table for this competition.
  /// When a participant's score changes, the leaderboard is re-fetched.
  void _startLiveLeaderboard() {
    final comp = widget.competition;
    if (comp.hasEnded) return; // no need for live updates on finished comps

    _loadLiveLeaderboard();
    _subscribeToRealtime();
  }

  Future<void> _loadLiveLeaderboard() async {
    setState(() => _isLiveLoading = true);
    try {
      final entries = await context
          .read<CompetitionProvider>()
          .getLeaderboard(widget.competition.id, forceRefresh: true);
      if (mounted) {
        setState(() {
          _liveEntries = entries;
          _isLiveLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLiveLoading = false);
      }
    }
  }

  void _subscribeToRealtime() {
    if (_leaderboardChannel != null) return; // already subscribed

    final client = Supabase.instance.client;
    _leaderboardChannel = client.channel('leaderboard_${widget.competition.id}');

    _leaderboardChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'participants',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'competition_id',
        value: widget.competition.id,
      ),
      callback: (payload) {
        debugPrint('[Realtime] participants change: ${payload.eventType}');
        if (mounted) _loadLiveLeaderboard();
      },
    ).subscribe((status, _) {
      debugPrint('[Realtime] leaderboard channel status: $status');
    });
  }

  void _unsubscribeRealtime() {
    _leaderboardChannel?.unsubscribe();
    _leaderboardChannel = null;
  }

  Future<void> _loadState({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _isRefreshing = true;
        _loadError = null;
      });
    }

    final compProvider = context.read<CompetitionProvider>();
    await compProvider.selectCompetition(widget.competition);

    try {
      final joined = await compProvider.hasJoinedCompetition(widget.competition.id);
      final hasEnded = widget.competition.hasEnded;

      if (mounted) {
        setState(() => _hasJoined = joined);
        if (joined) {
          final futures = <Future<Object?>>[
            compProvider.getMyParticipation(widget.competition.id),
            compProvider.getCompletedChallengeIds(widget.competition.id),
          ];
          if (hasEnded) {
            futures.add(compProvider.getMyFinalResult(widget.competition.id));
          }
          final results = await Future.wait(futures);
          if (mounted) {
            final participation = results[0] as Participant?;
            final completedIds = results[1] as Set<String>;
            setState(() {
              if (participation != null) _myScore = participation.totalScore;
              _completedChallengeIds = completedIds;
            });
            if (hasEnded && results.length > 2 && results[2] != null) {
              final (rank, prize) = results[2] as (int, int);
              setState(() {
                _myFinalRank = rank;
                _myPrize = prize;
              });
            }
          }
        }
      }
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _isRefreshing = false;
          _loadError = null;
        });
      }
    } catch (e) {
      debugPrint('_loadState error: $e');
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _isRefreshing = false;
          _loadError = 'Failed to load data. Check your connection.';
        });
      }
    }
  }

  Future<void> _joinCompetition() async {
    setState(() => _isJoining = true);
    try {
      await context
          .read<CompetitionProvider>()
          .joinCompetition(widget.competition.id);
      if (mounted) {
        setState(() {
          _hasJoined = true;
          _isJoining = false;
        });
        await context.read<AuthProvider>().getProfile();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isJoining = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context
                    .read<CompetitionProvider>()
                    .errorMessage ??
                'Failed to join'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startChallenge(ChallengeDefinition challenge) {
    if (widget.competition.hasEnded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This competition has ended.'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    if (!widget.competition.hasStarted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('This competition hasn\'t started yet. $_liveTimeRemaining.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          challenge: challenge,
          competitionId: widget.competition.id,
        ),
      ),
    ).then((gameResult) {
      // gameResult is null if the user quit early, otherwise it's
      // {result, challenge, competitionId} from GameScreen.onGameFinished
      if (gameResult is Map<String, dynamic> && mounted) {
        final result = gameResult['result'] as Result;
        final challenge = gameResult['challenge'] as ChallengeDefinition;
        final competitionId = gameResult['competitionId'] as String?;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              result: result,
              challenge: challenge,
              competitionId: competitionId,
            ),
          ),
        ).then((_) {
          // ResultScreen was dismissed — reload state to show "Played" badges
          _loadState(isRefresh: true);
        });
      } else if (gameResult == null && mounted) {
        // User quit the game — still refresh in case something changed
        _loadState(isRefresh: true);
      }
    });
  }

  String _formatShares(List<double> shares) {
    if (shares.isEmpty) return '';
    final maxShow = shares.length > 3 ? 3 : shares.length;
    final parts = shares.take(maxShow).map((s) => '${s.round()}%');
    if (shares.length > 3) parts.followedBy(['…']);
    return parts.join(' / ');
  }

  @override
  void dispose() {
    _tickTimer.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _unsubscribeRealtime();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comp = widget.competition;

    return Scaffold(
      appBar: AppBar(
        title: Text(comp.name),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.quiz), text: 'Challenges'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Leaderboard'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1A237E).withAlpha(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatBadge(
                      icon: Icons.monetization_on, label: 'Entry',
                      value: '${comp.entryPoints} 🪙', color: Colors.amber,
                    ),
                    _StatBadge(
                      icon: Icons.emoji_events, label: 'Prize Pool',
                      value: '${comp.prizePool} 🪙', color: Colors.purple,
                    ),
                    _StatBadge(
                      icon: Icons.people, label: 'Winners',
                      value: '${comp.winnerCount}  •  ${_formatShares(comp.winnerShares)}',
                      color: Colors.green,
                    ),
                    if (_hasJoined && _myScore != null)
                      _StatBadge(
                        icon: Icons.score, label: 'Your Score',
                        value: '$_myScore', color: Colors.orange,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _liveTimeRemaining,
                  style: TextStyle(
                    fontSize: 14, color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Competition-ended banner (replaces join/play UI entirely)
          if (comp.hasEnded && !_isInitialLoading)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _hasJoined
                  ? Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.emoji_events, color: Colors.grey, size: 20),
                            const SizedBox(width: 8),
                            const Text('Competition Ended',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                          ],
                        ),
                        if (_myFinalRank != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _myFinalRank == 1
                                ? '🏆 You placed 1st!'
                                : 'You placed #$_myFinalRank',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _myFinalRank! <= 3
                                  ? Colors.amber.shade800
                                  : Colors.grey.shade700,
                            ),
                          ),
                          if (_myPrize != null && _myPrize! > 0) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '+$_myPrize coins won!',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, color: Colors.grey, size: 18),
                        SizedBox(width: 8),
                        Text('This competition has ended.',
                            style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
            ),
          // Not started yet — show countdown
          if (!comp.hasStarted && !comp.hasEnded)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.schedule, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Coming soon — $_liveTimeRemaining',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

          // Active competition: join button or "you're in" banner
          if (comp.hasStarted && !comp.hasEnded && comp.isJoinable && !_hasJoined)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isJoining ? null : _joinCompetition,
                  icon: _isJoining
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.how_to_reg),
                  label: Text(
                    _isJoining ? 'Joining...'
                        : 'Join Competition (${comp.entryPoints} coins)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6F00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          if (_hasJoined && comp.hasStarted && !comp.hasEnded && comp.isJoinable)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text("You're in! Play challenges below.",
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChallengesTab(),
                _buildLeaderboardTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesTab() {
    // Initial load — show a centered spinner so no stale state is ever visible.
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Fetch error — show error message with a retry button.
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_loadError!,
                  style: const TextStyle(color: Colors.grey, fontSize: 15),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  _loadState(isRefresh: true);
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Inline refresh banner — shown when reloading after a challenge,
        // so the user sees that data is updating but existing cards stay put.
        if (_isRefreshing)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue.shade50,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('Refreshing...',
                    style: TextStyle(fontSize: 13, color: Colors.blue)),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.competition.challenges.length,
            itemBuilder: (context, index) {
              final challenge = widget.competition.challenges[index];
              final isPlayed = _completedChallengeIds.contains(challenge.id);
              final isEnded = widget.competition.hasEnded;
              final isNotStarted = !widget.competition.hasStarted;
              final canPlay = _hasJoined && !isPlayed && !isEnded && !isNotStarted;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isPlayed ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isPlayed ? Icons.check_circle : Icons.calculate,
                      color: isPlayed ? Colors.green : const Color(0xFFFF6F00),
                      size: 24,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          challenge.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPlayed ? Colors.grey.shade600 : null,
                          ),
                        ),
                      ),
                      if (isPlayed)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Played',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    challenge.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isPlayed ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  trailing: isPlayed
                      ? ElevatedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Played'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.grey.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: canPlay ? () => _startChallenge(challenge) : null,
                          icon: Icon(
                            isEnded ? Icons.lock : Icons.play_arrow,
                            size: 18,
                          ),
                          label: Text(
                            isEnded ? 'Ended'
                                : isNotStarted ? 'Not started'
                                : _hasJoined ? 'Play'
                                : 'Join first',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasJoined && !isEnded && !isNotStarted
                                ? const Color(0xFFFF6F00)
                                : Colors.grey,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTab() {
    final isEnded = widget.competition.hasEnded;

    // ── Ended competitions: use the prize-aware final leaderboard ──
    if (isEnded) {
      return Consumer<CompetitionProvider>(
        builder: (context, compProvider, _) {
          final entries = compProvider.cachedLeaderboard(widget.competition.id);
          if (compProvider.isLoadingLeaderboard && entries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!compProvider.isLoadingLeaderboard && entries.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => compProvider
                  .getLeaderboard(widget.competition.id, forceRefresh: true),
              child: ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events, size: 64,
                            color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('No one participated',
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                        const Text('Check back for the next competition!',
                            style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          final topThree = entries
              .where((e) => e.rank <= 3 && e.completedChallenges > 0)
              .toList();
          final myUserId = context.read<AuthProvider>().userId;
          return Column(
            children: [
              if (compProvider.isLoadingLeaderboard)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => compProvider
                      .getLeaderboard(widget.competition.id, forceRefresh: true),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (topThree.isNotEmpty) _buildPodium(topThree),
                      ...entries.map((entry) =>
                          _buildLeaderboardRow(entry,
                              myUserId: myUserId, showPrize: true)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    // ── Live competitions: reactive stream via Supabase Realtime ──
    if (_isLiveLoading && _liveEntries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isLiveLoading && _liveEntries.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadLiveLeaderboard,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.leaderboard, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No participants yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const Text('Be the first to join and play!',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final myUserId = context.read<AuthProvider>().userId;
    return Column(
      children: [
        // Live indicator
        if (_leaderboardChannel != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            color: Colors.green.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Live',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        // Loading overlay for subsequent fetches
        if (_isLiveLoading && _liveEntries.isNotEmpty)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadLiveLeaderboard,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _liveEntries.length,
              itemBuilder: (context, index) =>
                  _buildLeaderboardRow(_liveEntries[index],
                      myUserId: myUserId, showPrize: false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardRow(LeaderboardEntry entry, {
    required String? myUserId,
    required bool showPrize,
  }) {
    final isMe = entry.userId == myUserId;
    final displayPrize = showPrize && entry.prize > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.amber.shade50
            : entry.rank <= 3 && showPrize
                ? Colors.amber.shade50.withAlpha(80)
                : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isMe
            ? Border.all(color: Colors.amber, width: 2)
            : entry.rank <= 3 && showPrize
                ? Border.all(color: Colors.amber.shade200, width: 1)
                : null,
      ),
      child: ListTile(
        leading: _RankBadge(rank: entry.rank),
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry.nickname,
                style: TextStyle(
                  fontWeight: isMe || entry.rank <= 3
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
            if (isMe)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('YOU',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            if (entry.telegramUsername != null &&
                entry.telegramUsername!.isNotEmpty) ...[
              Text(
                '@${entry.telegramUsername}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              '${entry.completedChallenges} challenges${displayPrize ? '  •  +${entry.prize} coins won' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: displayPrize ? Colors.amber.shade900 : null,
                fontWeight: displayPrize ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
        trailing: Text(
          '${entry.totalScore} pts',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF6F00),
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> topThree) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.amber.shade100, Colors.orange.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('🏆 Final Podium',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd place
              if (topThree.length > 1) _podiumSpot(topThree[1], 2, 56),
              const SizedBox(width: 12),
              // 1st place
              _podiumSpot(topThree[0], 1, 70),
              const SizedBox(width: 12),
              // 3rd place
              if (topThree.length > 2) _podiumSpot(topThree[2], 3, 48),
            ],
          ),
        ],
      ),
    );
  }

  Widget _podiumSpot(LeaderboardEntry entry, int place, double size) {
    final medals = {1: '🥇', 2: '🥈', 3: '🥉'};
    return Column(
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: Colors.white,
          child: Text(
            entry.nickname.isNotEmpty ? entry.nickname[0].toUpperCase() : '?',
            style: TextStyle(
              fontSize: size / 2.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A237E),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(medals[place]!, style: const TextStyle(fontSize: 22)),
        Text(entry.nickname,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        if (entry.telegramUsername != null &&
            entry.telegramUsername!.isNotEmpty)
          Text('@${entry.telegramUsername}',
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.w500)),
        Text('${entry.totalScore} pts',
            style: const TextStyle(fontSize: 12, color: Color(0xFFFF6F00))),
        if (entry.prize > 0)
          Text('+${entry.prize}',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900)),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatBadge({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});
  @override
  Widget build(BuildContext context) {
    Color bgColor;
    IconData icon;
    switch (rank) {
      case 1: bgColor = Colors.amber; icon = Icons.emoji_events;
      case 2: bgColor = Colors.grey.shade400; icon = Icons.emoji_events;
      case 3: bgColor = Colors.brown.shade300; icon = Icons.emoji_events;
      default:
        return CircleAvatar(
          radius: 16, backgroundColor: Colors.grey.shade100,
          child: Text('$rank', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, fontSize: 13)),
        );
    }
    return CircleAvatar(radius: 16, backgroundColor: bgColor, child: Icon(icon, color: Colors.white, size: 18));
  }
}
