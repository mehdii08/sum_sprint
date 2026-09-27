import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/custom_leaderboard.dart';
import '../repositories/leaderboard_repository.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

// ── Leaderboard Screen ──────────────────────────────────────────

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  final LeaderboardRepository _repository = LeaderboardRepository();
  List<CustomLeaderboard> _customLeaderboards = [];
  bool _isLoadingTabs = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadTabs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTabs() async {
    _isLoadingTabs = true;
    if (mounted) setState(() {});
    try {
      _customLeaderboards = await _repository.getActiveCustomLeaderboards();
    } catch (e) {
      _customLeaderboards = [];
    }
    final tabCount = 1 + _customLeaderboards.length;
    _tabController.dispose();
    _tabController = TabController(length: tabCount, vsync: this);
    if (mounted) setState(() => _isLoadingTabs = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingTabs) {
      return Container(
        decoration: const BoxDecoration(gradient: kBgGradient),
        child: const Center(child: CircularProgressIndicator(color: kAccentPurple)),
      );
    }

    return Container(
      decoration: const BoxDecoration(gradient: kBgGradient),
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: kSurfaceDark,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kTextPrimary.withAlpha(10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kTextPrimary.withAlpha(15)),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: kTextPrimary, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            centerTitle: true,
            title: Text(AppLocalizations.of(context).leaderboardTitle.toUpperCase(),
                style: const TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2.0)),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: kAccentGold.withAlpha(60)),
                    boxShadow: [BoxShadow(color: kAccentGold.withAlpha(20), blurRadius: 8)],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.emoji_events_rounded, color: kAccentGold, size: 20),
                    onPressed: () {},
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: kTextPrimary.withAlpha(6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kTextPrimary.withAlpha(10)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(colors: [kAccentPurple, Color(0xFF6D28D9)]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: kAccentPurple.withAlpha(50), blurRadius: 8)],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: kTextPrimary,
                    unselectedLabelColor: kTextMuted,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    padding: const EdgeInsets.all(4),
                    splashFactory: NoSplash.splashFactory,
                    tabs: [
                      Tab(text: AppLocalizations.of(context).leaderboardGlobal),
                      for (final lb in _customLeaderboards) Tab(text: lb.title),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            const _GlobalLeaderboardTab(),
            for (final lb in _customLeaderboards)
              _CustomLeaderboardTab(leaderboard: lb),
          ],
        ),
      ),
    );
  }
}

// ── Global leaderboard tab ──────────────────────────────────────

class _GlobalLeaderboardTab extends StatefulWidget {
  const _GlobalLeaderboardTab();
  @override
  State<_GlobalLeaderboardTab> createState() => _GlobalLeaderboardTabState();
}

class _GlobalLeaderboardTabState extends State<_GlobalLeaderboardTab> with SingleTickerProviderStateMixin {
  final LeaderboardRepository _repository = LeaderboardRepository();
  final ScrollController _scrollController = ScrollController();
  List<LeaderboardRanking> _rankings = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _nextOffset = 0;
  LeaderboardRanking? _myEntry;
  bool _isLoadingMyEntry = true;
  static const _pageSize = 50;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadFirstPage();
    _loadMyEntry();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadFirstPage() async {
    if (_isLoading) return;
    _isLoading = true;
    if (mounted) setState(() {});
    _rankings = await _repository.getGlobalRankings(offset: 0, limit: _pageSize);
    _nextOffset = _rankings.length;
    _hasMore = _rankings.length >= _pageSize;
    _isLoading = false;
    if (mounted) { setState(() {}); _fadeCtrl.forward(); }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    _isLoading = true;
    if (mounted) setState(() {});
    final more = await _repository.getGlobalRankings(offset: _nextOffset, limit: _pageSize);
    _rankings.addAll(more);
    _nextOffset += more.length;
    _hasMore = more.length >= _pageSize;
    _isLoading = false;
    if (mounted) setState(() {});
  }

  Future<void> _loadMyEntry() async {
    _isLoadingMyEntry = true;
    if (mounted) setState(() {});
    final auth = context.read<AuthProvider>();
    final userId = auth.userId;
    if (userId.isNotEmpty) _myEntry = await _repository.getUserGlobalEntry(userId);
    _isLoadingMyEntry = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_rankings.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator(color: kAccentPurple));
    }
    if (_rankings.isEmpty && !_isLoading) {
      return const _LeaderboardEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: _buildList(),
    );
  }

  Widget _buildList() {
    return Stack(
      children: [
        RefreshIndicator(
          color: kAccentPurple,
          onRefresh: () async {
            _rankings = [];
            _nextOffset = 0;
            _hasMore = true;
            await _loadFirstPage();
            await _loadMyEntry();
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: _PodiumView(rankings: _rankings)),
              SliverToBoxAdapter(child: const SizedBox(height: 8)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= _rankings.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator(color: kAccentPurple)),
                        );
                      }
                      return _PremiumRankingTile(entry: _rankings[index], delayMs: index * 40);
                    },
                    childCount: _rankings.length + (_isLoading ? 1 : 0),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
        if (_myEntry != null && !_isLoadingMyEntry)
          Positioned(
            left: 12, right: 12, bottom: 12,
            child: _StickyUserCard(entry: _myEntry!),
          ),
      ],
    );
  }
}

// ── Custom leaderboard tab ──────────────────────────────────────

class _CustomLeaderboardTab extends StatefulWidget {
  final CustomLeaderboard leaderboard;
  const _CustomLeaderboardTab({required this.leaderboard});
  @override
  State<_CustomLeaderboardTab> createState() => _CustomLeaderboardTabState();
}

class _CustomLeaderboardTabState extends State<_CustomLeaderboardTab> with SingleTickerProviderStateMixin {
  final LeaderboardRepository _repository = LeaderboardRepository();
  final ScrollController _scrollController = ScrollController();
  List<LeaderboardRanking> _rankings = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _nextOffset = 0;
  LeaderboardRanking? _myEntry;
  bool _isLoadingMyEntry = true;
  static const _pageSize = 50;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadFirstPage();
    _loadMyEntry();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadFirstPage() async {
    if (_isLoading) return;
    _isLoading = true;
    if (mounted) setState(() {});
    _rankings = await _repository.getCustomLeaderboardRankings(
        leaderboardId: widget.leaderboard.id, offset: 0, limit: _pageSize);
    _nextOffset = _rankings.length;
    _hasMore = _rankings.length >= _pageSize;
    _isLoading = false;
    if (mounted) { setState(() {}); _fadeCtrl.forward(); }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    _isLoading = true;
    if (mounted) setState(() {});
    final more = await _repository.getCustomLeaderboardRankings(
        leaderboardId: widget.leaderboard.id, offset: _nextOffset, limit: _pageSize);
    _rankings.addAll(more);
    _nextOffset += more.length;
    _hasMore = more.length >= _pageSize;
    _isLoading = false;
    if (mounted) setState(() {});
  }

  Future<void> _loadMyEntry() async {
    _isLoadingMyEntry = true;
    if (mounted) setState(() {});
    final auth = context.read<AuthProvider>();
    final userId = auth.userId;
    if (userId.isNotEmpty) {
      _myEntry = await _repository.getUserCustomLeaderboardEntry(
          userId: userId, leaderboardId: widget.leaderboard.id);
    }
    _isLoadingMyEntry = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_rankings.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator(color: kAccentPurple));
    }
    if (_rankings.isEmpty && !_isLoading) {
      return const _LeaderboardEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: _buildList(),
    );
  }

  Widget _buildList() {
    final lb = widget.leaderboard;
    final hasEnded = DateTime.now().toUtc().isAfter(lb.endDate);
    final diff = lb.endDate.difference(DateTime.now().toUtc());

    return Stack(
      children: [
        RefreshIndicator(
          color: kAccentPurple,
          onRefresh: () async {
            _rankings = [];
            _nextOffset = 0;
            _hasMore = true;
            await _loadFirstPage();
            await _loadMyEntry();
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              if (!hasEnded)
                SliverToBoxAdapter(
                  child: _EventCard(
                    title: lb.title,
                    rewards: lb.rewards,
                    timeLeft: _formatDuration(diff),
                  ),
                ),
              SliverToBoxAdapter(child: _PodiumView(rankings: _rankings)),
              SliverToBoxAdapter(child: const SizedBox(height: 8)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= _rankings.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator(color: kAccentPurple)),
                        );
                      }
                      return _PremiumRankingTile(entry: _rankings[index], delayMs: index * 40);
                    },
                    childCount: _rankings.length + (_isLoading ? 1 : 0),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
        if (_myEntry != null && !_isLoadingMyEntry)
          Positioned(
            left: 12, right: 12, bottom: 12,
            child: _StickyUserCard(entry: _myEntry!),
          ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final l10n = AppLocalizations.of(context);
    if (d.isNegative) return l10n.leaderboardEnded;
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    final parts = <String>[];
    if (days > 0) parts.add(l10n.durationDays(days));
    if (hours > 0) parts.add(l10n.durationHours(hours));
    parts.add(l10n.durationMinutes(mins));
    return parts.join(' ');
  }
}

// ── Event / Season Card ─────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final String title;
  final String? rewards;
  final String timeLeft;
  const _EventCard({required this.title, this.rewards, required this.timeLeft});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kAccentGold.withAlpha(20), kAccentGold.withAlpha(5)],
          ),
          border: Border.all(color: kAccentGold.withAlpha(40), width: 0.8),
          boxShadow: [BoxShadow(color: kAccentGold.withAlpha(12), blurRadius: 16)],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: kSurfaceDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kAccentGold.withAlpha(40)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_rounded, color: kAccentGold, size: 14),
                        const SizedBox(width: 6),
                        Text(timeLeft, style: const TextStyle(color: kAccentGold, fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kAccentGold.withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kAccentGold.withAlpha(30)),
                    ),
                    child: Text(l10n.leaderboardActive.toUpperCase(),
                        style: const TextStyle(color: kAccentGold, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(title, style: const TextStyle(color: kTextPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(l10n.leaderboardRewardsHint,
                  style: TextStyle(color: kAccentGold.withAlpha(180), fontSize: 13)),
              if (rewards != null && rewards!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(60),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(rewards!,
                      style: const TextStyle(color: kTextSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Podium ──────────────────────────────────────────────────────

class _PodiumView extends StatelessWidget {
  final List<LeaderboardRanking> rankings;
  const _PodiumView({required this.rankings});

  @override
  Widget build(BuildContext context) {
    if (rankings.isEmpty) return const SizedBox.shrink();

    final first = rankings.isNotEmpty ? rankings[0] : null;
    final second = rankings.length > 1 ? rankings[1] : null;
    final third = rankings.length > 2 ? rankings[2] : null;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        return Transform.translate(offset: Offset(0, (1 - val) * 30), child: Opacity(opacity: val, child: child));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: second != null ? _PodiumCard(entry: second, rank: 2, height: 140) : const SizedBox.shrink()),
            const SizedBox(width: 10),
            Expanded(child: first != null ? _PodiumCard(entry: first, rank: 1, height: 170, isGold: true) : const SizedBox.shrink()),
            const SizedBox(width: 10),
            Expanded(child: third != null ? _PodiumCard(entry: third, rank: 3, height: 120) : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final LeaderboardRanking entry;
  final int rank;
  final double height;
  final bool isGold;
  const _PodiumCard({required this.entry, required this.rank, required this.height, this.isGold = false});

  @override
  Widget build(BuildContext context) {
    final color = rank == 1 ? kAccentGold : rank == 2 ? const Color(0xFF94A3B8) : const Color(0xFFCD7F32);
    final medals = <int, String>{1: '🥇', 2: '🥈', 3: '🥉'};

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isGold)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Icon(Icons.auto_awesome, color: kAccentGold.withAlpha(180), size: 16),
          ),
        CircleAvatar(
          radius: isGold ? 28 : 22,
          backgroundColor: color.withAlpha(30),
          backgroundImage: entry.avatarUrl != null && entry.avatarUrl!.isNotEmpty ? NetworkImage(entry.avatarUrl!) : null,
          child: entry.avatarUrl == null || entry.avatarUrl!.isEmpty
              ? Text(medals[rank]!, style: TextStyle(fontSize: isGold ? 26 : 20))
              : null,
        ),
        const SizedBox(height: 6),
        Text(entry.nickname,
            style: TextStyle(color: kTextPrimary, fontSize: isGold ? 13 : 11, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text('${entry.totalScore}',
            style: TextStyle(color: color, fontSize: isGold ? 14 : 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withAlpha(40), color.withAlpha(8)],
            ),
            border: Border(top: BorderSide(color: color.withAlpha(60), width: 2)),
          ),
          child: Center(
            child: Text('#$rank', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }
}

// ── Premium Ranking Tile ────────────────────────────────────────

class _PremiumRankingTile extends StatefulWidget {
  final LeaderboardRanking entry;
  final int delayMs;
  const _PremiumRankingTile({required this.entry, required this.delayMs});

  @override
  State<_PremiumRankingTile> createState() => _PremiumRankingTileState();
}

class _PremiumRankingTileState extends State<_PremiumRankingTile> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final isTop3 = entry.rank <= 3;
    final color = entry.rank == 1
        ? kAccentGold
        : entry.rank == 2
            ? const Color(0xFF94A3B8)
            : entry.rank == 3
                ? const Color(0xFFCD7F32)
                : kAccentPurple;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Opacity(opacity: _anim.value, child: child),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: kCardGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isTop3 ? color.withAlpha(50) : kTextPrimary.withAlpha(8), width: isTop3 ? 1.2 : 0.6),
              boxShadow: isTop3
                  ? [BoxShadow(color: color.withAlpha(10), blurRadius: 10)]
                  : null,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text('#${entry.rank}',
                      style: TextStyle(
                        color: isTop3 ? color : kTextMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withAlpha(25),
                  backgroundImage: entry.avatarUrl != null && entry.avatarUrl!.isNotEmpty ? NetworkImage(entry.avatarUrl!) : null,
                  child: entry.avatarUrl == null || entry.avatarUrl!.isEmpty
                      ? Text(entry.nickname.isNotEmpty ? entry.nickname[0].toUpperCase() : '?',
                          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.nickname,
                          style: TextStyle(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      if (entry.telegramUsername != null && entry.telegramUsername!.isNotEmpty)
                        Text('@${entry.telegramUsername}',
                            style: TextStyle(color: kTextMuted, fontSize: 11)),
                    ],
                  ),
                ),
                Text('${entry.totalScore}',
                    style: TextStyle(color: isTop3 ? color : kTextPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(width: 4),
                Text(AppLocalizations.of(context).pointsShort.toUpperCase(),
                    style: const TextStyle(color: kTextMuted, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sticky User Card ────────────────────────────────────────────

class _StickyUserCard extends StatelessWidget {
  final LeaderboardRanking entry;
  const _StickyUserCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isTop3 = entry.rank <= 3;
    final color = isTop3 ? kAccentGold : kAccentPurple;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kSurfaceDark, color.withAlpha(15)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withAlpha(50), width: 1.2),
          boxShadow: [
            BoxShadow(color: color.withAlpha(15), blurRadius: 16),
            BoxShadow(color: Colors.black.withAlpha(80), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withAlpha(40)),
              ),
              child: Center(
                child: Text('#${entry.rank}',
                    style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withAlpha(20),
              backgroundImage: entry.avatarUrl != null && entry.avatarUrl!.isNotEmpty ? NetworkImage(entry.avatarUrl!) : null,
              child: entry.avatarUrl == null || entry.avatarUrl!.isEmpty
                  ? Text(entry.nickname.isNotEmpty ? entry.nickname[0].toUpperCase() : '?',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.nickname, style: const TextStyle(color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                  if (entry.telegramUsername != null && entry.telegramUsername!.isNotEmpty)
                    Text('@${entry.telegramUsername}', style: const TextStyle(color: kTextMuted, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${entry.totalScore}',
                    style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
                Text(AppLocalizations.of(context).points.toUpperCase(),
                    style: const TextStyle(color: kTextMuted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ─────────────────────────────────────────────────

class _LeaderboardEmptyState extends StatelessWidget {
  const _LeaderboardEmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [kAccentPurple.withAlpha(30), Colors.transparent]),
                border: Border.all(color: kAccentPurple.withAlpha(40), width: 2),
              ),
              child: const Icon(Icons.emoji_events_rounded, color: kAccentGold, size: 48),
            ),
            const SizedBox(height: 24),
            Text(l10n.leaderboardEmptyTitle,
                style: const TextStyle(color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(l10n.leaderboardEmptyMessage,
                style: TextStyle(color: kTextSecondary, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentPurple,
                  foregroundColor: kTextPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(l10n.leaderboardPlayNow,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
