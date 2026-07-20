import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../platform/telegram_init.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../providers/tg_home_provider.dart';
import 'tg_home_screen.dart';
import 'login_screen.dart';

class TgSplashScreen extends StatefulWidget {
  const TgSplashScreen({super.key});

  @override
  State<TgSplashScreen> createState() => _TgSplashScreenState();
}

class _TgSplashScreenState extends State<TgSplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    final auth = context.read<AuthProvider>();
    final player = context.read<PlayerProvider>();
    final tgHome = context.read<TgHomeProvider>();

    if (auth.isLoggedIn) {
      player.setUid(auth.userId);
      await tgHome.loadProfile();
      if (!mounted) return;
      _navigateToHome();
      return;
    }

    var ready = false;
    for (var i = 0; i < 60; i++) {
      final d = getTelegramInitData();
      if (d != null && d.isNotEmpty) {
        ready = true;
        break;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!ready) {
      if (mounted) _navigateToLogin();
      return;
    }

    final ok = await auth.signInWithTelegram();
    if (!mounted) return;

    if (ok) {
      player.setUid(auth.userId);
      await tgHome.loadProfile();
      if (!mounted) return;
      _navigateToHome();
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TgHomeScreen()),
    );
  }

  Future<void> _navigateToLogin() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (result == true && mounted) {
      final player = context.read<PlayerProvider>();
      final tgHome = context.read<TgHomeProvider>();
      await tgHome.loadProfile();
      if (!mounted) return;
      player.setUid(context.read<AuthProvider>().userId);
      _navigateToHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: _SplashBody(),
    );
  }
}

class _SplashBody extends StatelessWidget {
  const _SplashBody();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF4A148C)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calculate, size: 72, color: Colors.white),
            ),
            const SizedBox(height: 32),
            const Text(
              'Sum Sprint',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
