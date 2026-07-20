import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/competition_provider.dart';
import '../platform/telegram_init.dart';
import '../l10n/app_localizations.dart';
import 'challenge_list_screen.dart';
import 'competitions_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'tg_home_screen.dart';
import 'admin/admin_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  bool _syncedFromSupabase = false;
  bool _isCheckingTelegram = false;

  @override
  void initState() {
    super.initState();
    _nicknameController.text = context.read<PlayerProvider>().nickname;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAuthFlow();
    });
  }

  Future<void> _startAuthFlow() async {
    if (!isTelegramAvailable) {
      if (mounted) setState(() {});
      return;
    }

    final auth = context.read<AuthProvider>();

    if (auth.isLoggedIn) {
      await _syncNicknameIfLoggedIn();
      if (mounted) setState(() {});
      return;
    }

    if (mounted) setState(() => _isCheckingTelegram = true);

    // Poll for initData (Telegram SDK might init late).
    var ready = false;
    for (var i = 0; i < 50; i++) {
      final d = getTelegramInitData();
      if (d != null && d.isNotEmpty) {
        ready = true;
        break;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!ready) {
      if (mounted) setState(() => _isCheckingTelegram = false);
      return;
    }

    final ok = await auth.signInWithTelegram();
    if (!mounted) return;

    if (ok) {
      final player = context.read<PlayerProvider>();
      player.setUid(auth.userId);

      final profile = await auth.getProfile();
      final name = profile?['nickname'] as String?;
      if (name != null && name.isNotEmpty && name != 'Player') {
        await player.setNickname(name);
        _nicknameController.text = name;
      }
      _syncedFromSupabase = true;
    }

    if (mounted) setState(() => _isCheckingTelegram = false);
  }

  Future<void> _navigateToLogin() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (result == true && mounted) {
      await _syncNicknameIfLoggedIn();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TgHomeScreen()),
      );
    }
  }

  Future<void> _syncNicknameIfLoggedIn() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;
    if (_syncedFromSupabase) return;

    final profile = await auth.getProfile();
    final supabaseNickname = profile?['nickname'] as String?;
    if (!mounted) return;
    if (supabaseNickname == null || supabaseNickname.isEmpty) return;

    _syncedFromSupabase = true;
    final player = context.read<PlayerProvider>();
    await player.setNickname(supabaseNickname);
    _nicknameController.text = player.nickname;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final player = context.watch<PlayerProvider>();
    final inTelegram = isTelegramAvailable;
    final isLoggedIn = auth.isLoggedIn;
    final displayNickname = player.nickname.isNotEmpty ? player.nickname : 'Player';

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A237E), Color(0xFF4A148C)],
              ),
            ),
          ),

          // Loading spinner while authenticating
          if (_isCheckingTelegram)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.connectingTelegram,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Main UI
          if (!_isCheckingTelegram)
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Telegram user banner
                    if (isLoggedIn && inTelegram)
                      _TelegramUserBanner(
                        auth: auth,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProfileScreen()),
                          );
                        },
                      ),

                    // Non-Telegram: logged in via email
                    if (isLoggedIn && !inTelegram)
                      _EmailUserBanner(
                        nickname: displayNickname,
                        email: auth.userEmail,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProfileScreen()),
                          );
                        },
                        onSignOut: () async {
                          final auth = context.read<AuthProvider>();
                          final player = context.read<PlayerProvider>();
                          await auth.signOut();
                          player.clearUid();
                          if (mounted) setState(() {});
                        },
                      ),

                    // Winner prize notifications
                    if (isLoggedIn)
                      _WinnerNotifications(),

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.calculate,
                          size: 72, color: Colors.white),
                    ),
                    const SizedBox(height: 24),

                    Text(l10n.appTitle,
                        style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    Text(l10n.appTagline,
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withAlpha(180))),
                    const SizedBox(height: 32),

                    // Welcome / nickname (logged in)
                    if (isLoggedIn)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person, color: Colors.white54, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Welcome, ${_nicknameController.text.isNotEmpty ? _nicknameController.text : 'Player'}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 40),

                    // Warm Up
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChallengeListScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6F00),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.fitness_center, size: 24),
                            const SizedBox(width: 12),
                            Text(l10n.warmUp,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Competitions (logged in) or Sign In prompt (not logged in)
                    if (isLoggedIn) ...[
                      SizedBox(
                        width: double.infinity, height: 56,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CompetitionsScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                                color: Colors.white54, width: 2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.emoji_events, size: 24,
                                  color: Colors.white),
                              const SizedBox(width: 12),
                              Text(l10n.competitions,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                      ),

                      // Admin button (only visible to admins)
                      if (auth.isAdmin) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity, height: 48,
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminDashboardScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.admin_panel_settings,
                                size: 20, color: Colors.white54),
                            label: Text(l10n.adminPanel,
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white54,
                                    fontWeight: FontWeight.w500)),
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ]
                    else
                      // NOT logged in → prominent Sign-In button
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity, height: 56,
                            child: ElevatedButton(
                              onPressed: _navigateToLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                elevation: 8,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.login, size: 24),
                                  const SizedBox(width: 12),
                                  Text(l10n.signInSignUp,
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Nickname field (offline warm-up)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(20),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextField(
                              controller: _nicknameController,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 16),
                              decoration: InputDecoration(
                                hintText: l10n.nicknameOfflineHint,
                                hintStyle:
                                    const TextStyle(color: Colors.white38),
                                icon: const Icon(Icons.person,
                                    color: Colors.white38, size: 20),
                                border: InputBorder.none,
                              ),
                              onChanged: (value) {
                                context
                                    .read<PlayerProvider>()
                                    .setNickname(value);
                              },
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

        ],
      ),
    );
  }
}

// ── Telegram user banner ──────────────────────────────────────────

class _TelegramUserBanner extends StatelessWidget {
  final AuthProvider auth;
  final VoidCallback? onTap;
  const _TelegramUserBanner({required this.auth, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(30)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white24,
            backgroundImage: auth.telegramPhotoUrl.isNotEmpty
                ? NetworkImage(auth.telegramPhotoUrl)
                : null,
            child: auth.telegramPhotoUrl.isEmpty
                ? Text(
                    auth.telegramFirstName.isNotEmpty
                        ? auth.telegramFirstName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.telegramFullName.isNotEmpty
                      ? auth.telegramFullName
                      : 'Telegram User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (auth.telegramUsername.isNotEmpty)
                  Text(
                    '@${auth.telegramUsername}',
                    style: TextStyle(
                      color: Colors.white.withAlpha(150),
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ── Email user banner (non-Telegram, logged in) ─────────────────

class _EmailUserBanner extends StatelessWidget {
  final String nickname;
  final String email;
  final VoidCallback? onTap;
  final VoidCallback? onSignOut;
  const _EmailUserBanner({
    required this.nickname,
    required this.email,
    this.onTap,
    this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green.withAlpha(25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.withAlpha(70)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.green.shade700,
              child: Text(
                nickname[0].toUpperCase(),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nickname,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.white.withAlpha(150),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (onSignOut != null)
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white54, size: 20),
                onPressed: onSignOut,
                tooltip: 'Sign out',
              ),
          ],
        ),
      ),
    );
  }
}

// ── Winner prize notification cards ─────────────────────────────

class _WinnerNotifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final compProvider = context.watch<CompetitionProvider>();
    final notifications = compProvider.winnerNotifications;
    if (notifications.isEmpty) return const SizedBox.shrink();

    final medals = <int, String>{1: '🥇', 2: '🥈', 3: '🥉'};

    return Column(
      children: [
        for (var i = 0; i < notifications.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade200, Colors.orange.shade100],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withAlpha(60),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  medals[notifications[i].rank] ?? '🏆',
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You placed #${notifications[i].rank} in',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        notifications[i].competitionName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+${notifications[i].prize} 🪙',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const Text(
                      'added to balance',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => compProvider.dismissWinnerNotification(i),
                  child: const Icon(Icons.close, size: 18, color: Colors.black38),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
