import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_version.dart';
import '../platform/telegram_init.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../providers/tg_home_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'home_screen.dart';

/// App startup splash — branding, then auth (Telegram if available, else email).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _ctrl.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _continue();
    });
  }

  Future<void> _continue() async {
    final auth = context.read<AuthProvider>();
    final player = context.read<PlayerProvider>();
    final tgHome = context.read<TgHomeProvider>();

    if (auth.isLoggedIn) {
      await _enterHome(auth: auth, player: player, tgHome: tgHome);
      return;
    }

    if (isTelegramAvailable) {
      final ok = await _tryTelegramSignIn(auth);
      if (!mounted) return;
      if (ok) {
        await _enterHome(auth: auth, player: player, tgHome: tgHome);
        return;
      }
    }

    await _goToLogin();
  }

  Future<bool> _tryTelegramSignIn(AuthProvider auth) async {
    for (var i = 0; i < 60; i++) {
      final d = getTelegramInitData();
      if (d != null && d.isNotEmpty) {
        return auth.signInWithTelegram();
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return false;
  }

  Future<void> _goToLogin() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (!mounted) return;

    if (result == true) {
      final auth = context.read<AuthProvider>();
      final player = context.read<PlayerProvider>();
      final tgHome = context.read<TgHomeProvider>();
      await _enterHome(auth: auth, player: player, tgHome: tgHome);
    } else {
      await _goToLogin();
    }
  }

  Future<void> _enterHome({
    required AuthProvider auth,
    required PlayerProvider player,
    required TgHomeProvider tgHome,
  }) async {
    player.setUid(auth.userId);
    await tgHome.loadProfile();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: Container(
        decoration: const BoxDecoration(gradient: kBgGradient),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              left: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [kAccentPurple.withAlpha(40), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [kAccentCyan.withAlpha(20), Colors.transparent],
                  ),
                ),
              ),
            ),
            Center(
              child: FadeTransition(
                opacity: _fadeIn,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [kAccentPurple, Color(0xFF6D28D9)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: kAccentPurple.withAlpha(50),
                              blurRadius: 28,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.calculate_rounded,
                          size: 64,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Sum Sprint',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: kTextPrimary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Fast math, real competitions',
                        style: TextStyle(
                          fontSize: 15,
                          color: kTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 40),
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: kAccentPurple,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        AppVersion.display,
                        style: TextStyle(
                          fontSize: 12,
                          color: kTextMuted,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
