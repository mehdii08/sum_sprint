import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/challenge_provider.dart';
import '../providers/tg_home_provider.dart';
import '../models/challenge_definition.dart';
import '../models/custom_leaderboard.dart';
import '../repositories/leaderboard_repository.dart';
import 'game_screen.dart';
import 'mind_timer_game_screen.dart';
import 'pair_hunt_game_screen.dart';
import 'tic_tac_toe_game_screen.dart';
import 'leaderboard_screen.dart';
import 'admin/admin_dashboard_screen.dart';

// ── Theme ───────────────────────────────────────────────────────

const _bgDark = Color(0xFF0D0F16);
const _surfaceDark = Color(0xFF151823);
const _accentPurple = Color(0xFF8B5CF6);
const _accentCyan = Color(0xFF22D3EE);
const _accentGold = Color(0xFFF59E0B);
const _textPrimary = Colors.white;
const _textSecondary = Color(0xFF9CA3AF);
const _textMuted = Color(0xFF6B7280);

class TgHomeScreen extends StatefulWidget {
  const TgHomeScreen({super.key});

  @override
  State<TgHomeScreen> createState() => _TgHomeScreenState();
}

class _TgHomeScreenState extends State<TgHomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().getProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TgHomeProvider>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _bgDark,
      body: _HomeTab(),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tgHome = context.watch<TgHomeProvider>();
    final challengeProvider = context.watch<ChallengeProvider>();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1030), Color(0xFF0D0F16)],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [_accentPurple.withAlpha(30), Colors.transparent],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                _ProfileHeader(
                  name: auth.displayName,
                  username: auth.telegramUsername.isNotEmpty ? '@${auth.telegramUsername}' : null,
                  photoUrl: auth.telegramPhotoUrl,
                  score: tgHome.totalScore,
                  isAdmin: auth.isAdmin,
                  onAdminTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
                  },
                ),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: challengeProvider.isLoadingChallenges
                        ? const Center(child: CircularProgressIndicator(color: _accentPurple))
                        : challengeProvider.loadError != null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(challengeProvider.loadError!,
                                      style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 200),
                                itemCount: challengeProvider.challenges.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == 0) return const _SectionTitle();
                                  final challenge = challengeProvider.challenges[index - 1];
                                  return _PremiumChallengeCard(challenge: challenge, index: index - 1);
                                },
                              ),
                  ),
                ),
                const _FloatingLeaderboardPanel(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Title ───────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_accentPurple, Color(0xFF6D28D9)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.sports_esports_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          const Text('CHALLENGES', style: TextStyle(color: _accentPurple, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}

// ── Profile Header ──────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String? username;
  final String photoUrl;
  final int score;
  final bool isAdmin;
  final VoidCallback? onAdminTap;

  const _ProfileHeader({
    required this.name,
    this.username,
    required this.photoUrl,
    required this.score,
    required this.isAdmin,
    this.onAdminTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _accentPurple.withAlpha(80), width: 2),
              boxShadow: [BoxShadow(color: _accentPurple.withAlpha(40), blurRadius: 12)],
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: _surfaceDark,
              backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
              child: photoUrl.isEmpty
                  ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 20))
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isNotEmpty ? name : 'Player',
                    style: const TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
                if (username != null)
                  Text(username!, style: const TextStyle(color: _accentCyan, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _accentGold.withAlpha(15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _accentGold.withAlpha(60)),
              boxShadow: [BoxShadow(color: _accentGold.withAlpha(20), blurRadius: 8)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: _accentGold, size: 18),
                const SizedBox(width: 6),
                Text('$score', style: const TextStyle(color: _accentGold, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_rounded, color: _accentCyan, size: 22),
              onPressed: onAdminTap,
              tooltip: 'Admin Panel',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Premium Challenge Card ──────────────────────────────────────

class _PremiumChallengeCard extends StatefulWidget {
  final ChallengeDefinition challenge;
  final int index;

  const _PremiumChallengeCard({required this.challenge, required this.index});

  @override
  State<_PremiumChallengeCard> createState() => _PremiumChallengeCardState();
}

class _PremiumChallengeCardState extends State<_PremiumChallengeCard> with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _slideAnim;
  late final Animation<double> _scaleAnim;
  bool _pressed = false;

  static const _accentColors = [
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF14B8A6),
    Color(0xFFEF4444),
    Color(0xFF6366F1),
    Color(0xFFEC4899),
  ];

  Color get _accent => _accentColors[widget.index % _accentColors.length];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _slideAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(_slideAnim);
    Future.delayed(Duration(milliseconds: 80 + widget.index * 60), () {
      if (mounted) _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  IconData get _icon {
    if (widget.challenge.isMindTimer) return Icons.timer_rounded;
    if (widget.challenge.isPairHunt) return Icons.grid_view_rounded;
    if (widget.challenge.isTicTacToe) return Icons.grid_3x3_rounded;
    return Icons.calculate_rounded;
  }

  String get _difficultyLabel {
    if (widget.challenge.isMindTimer) return 'Timing';
    if (widget.challenge.isPairHunt) return 'Memory';
    if (widget.challenge.isTicTacToe) return 'Strategy';
    return 'Math Speed';
  }

  Color get _difficultyColor {
    if (widget.challenge.isTicTacToe) return Colors.orange;
    if (widget.challenge.isPairHunt) return Colors.green;
    return _accentCyan;
  }

  void _navigateToGame() {
    final route = switch (widget.challenge.challengeType) {
      ChallengeType.mindTimer => MaterialPageRoute(builder: (_) => MindTimerGameScreen(challenge: widget.challenge)),
      ChallengeType.pairHunt => MaterialPageRoute(builder: (_) => PairHuntGameScreen(challenge: widget.challenge)),
      ChallengeType.ticTacToe => MaterialPageRoute(builder: (_) => TicTacToeGameScreen(challenge: widget.challenge)),
      ChallengeType.math => MaterialPageRoute(builder: (_) => GameScreen(challenge: widget.challenge)),
    };
    Navigator.push(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnim,
      builder: (context, child) => Transform.scale(scale: _scaleAnim.value, child: child),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) { setState(() => _pressed = false); _navigateToGame(); },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: _pressed ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, glow, child) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withAlpha(glow < 0.5 ? 10 : 30),
                      blurRadius: glow < 0.5 ? 12 : 24,
                      spreadRadius: glow < 0.5 ? 0 : 2,
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_surfaceDark, _accent.withAlpha(8)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _accent.withAlpha(40), width: 0.8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [_accent, _accent.withAlpha(180)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: _accent.withAlpha(50), blurRadius: 8)],
                              ),
                              child: Icon(_icon, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.challenge.name,
                                      style: const TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(_difficultyLabel, style: TextStyle(color: _difficultyColor, fontSize: 12, fontWeight: FontWeight.w600)),
                                      Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 8),
                                        width: 3, height: 3,
                                        decoration: const BoxDecoration(color: _textMuted, shape: BoxShape.circle),
                                      ),
                                      const Text('Solo', style: TextStyle(color: _textSecondary, fontSize: 12)),
                                      Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 8),
                                        width: 3, height: 3,
                                        decoration: const BoxDecoration(color: _textMuted, shape: BoxShape.circle),
                                      ),
                                      Text(
                                        widget.challenge.isTicTacToe
                                            ? '3 Rounds'
                                            : widget.challenge.isPairHunt
                                                ? '6 Pairs'
                                                : widget.challenge.isMindTimer
                                                    ? '${widget.challenge.questionCount} Stops'
                                                    : '${widget.challenge.questionCount} Qs',
                                        style: const TextStyle(color: _textSecondary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _difficultyColor.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _difficultyColor.withAlpha(60)),
                                  ),
                                  child: Text(
                                    widget.challenge.isTicTacToe
                                        ? 'Hard'
                                        : widget.challenge.isPairHunt
                                            ? 'Medium'
                                            : 'Easy',
                                    style: TextStyle(color: _difficultyColor, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _MiniStat(icon: Icons.star_rounded, value: '${widget.challenge.maxPoints}', color: _accentGold),
                            const SizedBox(width: 16),
                            _MiniStat(
                              icon: Icons.timer_rounded,
                              value: widget.challenge.isMindTimer
                                  ? '${widget.challenge.targetSeconds}s'
                                  : '${widget.challenge.timeLimitSeconds}s',
                              color: _textSecondary,
                            ),
                            const Spacer(),
                            SizedBox(
                              height: 34,
                              child: ElevatedButton.icon(
                                onPressed: _navigateToGame,
                                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                                label: const Text('PLAY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _accent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  shape: const StadiumBorder(),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _MiniStat({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── Floating Leaderboard Panel ──────────────────────────────────

class _FloatingLeaderboardPanel extends StatefulWidget {
  const _FloatingLeaderboardPanel();

  @override
  State<_FloatingLeaderboardPanel> createState() => _FloatingLeaderboardPanelState();
}

class _FloatingLeaderboardPanelState extends State<_FloatingLeaderboardPanel> with SingleTickerProviderStateMixin {
  final LeaderboardRepository _repo = LeaderboardRepository();
  List<LeaderboardRanking> _topThree = [];
  LeaderboardRanking? _myEntry;
  bool _loaded = false;

  late final AnimationController _panelAnimCtrl;
  late final Animation<double> _panelAnim;

  @override
  void initState() {
    super.initState();
    _panelAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _panelAnim = CurvedAnimation(parent: _panelAnimCtrl, curve: Curves.easeOutCubic);
    _loadData();
  }

  @override
  void dispose() {
    _panelAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final top = await _repo.getGlobalRankings(offset: 0, limit: 3);
    final auth = context.read<AuthProvider>();
    if (auth.userId.isNotEmpty) {
      _myEntry = await _repo.getUserGlobalEntry(auth.userId);
    }
    if (mounted) {
      setState(() { _topThree = top; _loaded = true; });
      _panelAnimCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _panelAnim,
      axisAlignment: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: _surfaceDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: _accentPurple.withAlpha(40))),
          boxShadow: [BoxShadow(color: _accentPurple.withAlpha(15), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 32, height: 4, decoration: BoxDecoration(color: _textMuted.withAlpha(80), borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: _accentGold, size: 20),
                    const SizedBox(width: 8),
                    const Text('LEADERBOARD', style: TextStyle(color: _textPrimary, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const _FullLeaderboardView()));
                      },
                      child: const Row(
                        children: [
                          Text('VIEW FULL', style: TextStyle(color: _accentCyan, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                          Icon(Icons.arrow_forward_ios_rounded, color: _accentCyan, size: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_loaded)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _topThree.length > 1
                            ? _PodiumCircle(rank: 2, name: _topThree[1].nickname, color: const Color(0xFF94A3B8), label: '2nd')
                            : const SizedBox.shrink(),
                      ),
                      Expanded(
                        child: _topThree.isNotEmpty
                            ? _PodiumCircle(rank: 1, name: _topThree.first.nickname, color: _accentGold, label: '1st', large: true)
                            : const SizedBox.shrink(),
                      ),
                      Expanded(
                        child: _topThree.length > 2
                            ? _PodiumCircle(rank: 3, name: _topThree[2].nickname, color: const Color(0xFFCD7F32), label: '3rd')
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _accentPurple)),
                  ),
                ),
              if (_myEntry != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _accentPurple.withAlpha(10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _accentPurple.withAlpha(30)),
                  ),
                  child: Row(
                    children: [
                      const Text('YOUR RANK', style: TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
                      const Spacer(),
                      Text('#${_myEntry!.rank}', style: const TextStyle(color: _accentCyan, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _PodiumCircle extends StatelessWidget {
  final int rank;
  final String name;
  final Color color;
  final String label;
  final bool large;

  const _PodiumCircle({required this.rank, required this.name, required this.color, required this.label, this.large = false});

  @override
  Widget build(BuildContext context) {
    final size = large ? 56.0 : 46.0;
    final medals = <int, String>{1: '🥇', 2: '🥈', 3: '🥉'};

    return Column(
      children: [
        Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
            boxShadow: [BoxShadow(color: color.withAlpha(40), blurRadius: 10)],
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withAlpha(40), color.withAlpha(10)]),
          ),
          child: Center(child: Text(medals[rank] ?? '#$rank', style: TextStyle(fontSize: large ? 24 : 20))),
        ),
        const SizedBox(height: 6),
        Text(name, style: const TextStyle(color: _textPrimary, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ── Full Leaderboard wrapper (pushed from floating panel) ──────

class _FullLeaderboardView extends StatelessWidget {
  const _FullLeaderboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: const LeaderboardScreen(),
    );
  }
}
