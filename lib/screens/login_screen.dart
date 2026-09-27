import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/supabase_config.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../providers/tg_home_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

/// Email / password login and sign-up screen.
///
/// Used as an alternative auth path when the app is running
/// outside the Telegram Mini App (local dev, desktop, etc.).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nickCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();
  bool _obscurePass = true;
  bool _awaitingCode = false;
  String? _pendingEmail;
  String? _pendingNickname;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nickCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_signInFormKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithEmail(
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );
    if (!mounted) return;
    if (ok) _onSuccess();
  }

  Future<void> _signUp() async {
    if (!_signUpFormKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final nickname = _nickCtrl.text.trim().isNotEmpty
        ? _nickCtrl.text.trim()
        : _emailCtrl.text.split('@').first;
    final result = await auth.signUpWithEmail(
      email: _emailCtrl.text,
      password: _passCtrl.text,
      nickname: nickname,
    );
    if (!mounted) return;

    switch (result) {
      case EmailSignUpResult.success:
        _onSuccess();
      case EmailSignUpResult.needsVerification:
        setState(() {
          _awaitingCode = true;
          _pendingEmail = _emailCtrl.text.trim();
          _pendingNickname = nickname;
          _codeCtrl.clear();
        });
      case EmailSignUpResult.failure:
        break;
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeCtrl.text.trim();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the code from your email')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.verifySignupCode(
      email: _pendingEmail ?? _emailCtrl.text,
      code: code,
      nickname: _pendingNickname,
    );
    if (!mounted) return;
    if (ok) _onSuccess();
  }

  Future<void> _resendCode() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.resendSignupCode(_pendingEmail ?? _emailCtrl.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Code resent. Check your inbox.'
            : (auth.errorMessage ?? 'Could not resend')),
      ),
    );
  }

  void _onSuccess() {
    final auth = context.read<AuthProvider>();
    final player = context.read<PlayerProvider>();
    player.setUid(auth.userId);

    auth.getProfile().then((profile) {
      if (!mounted) return;
      final name = profile?['nickname'] as String?;
      if (name != null && name.isNotEmpty && name != 'Player') {
        player.setNickname(name);
      }
    });

    if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    } else {
      context.read<TgHomeProvider>().loadProfile();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: kTextMuted, size: 20),
      suffixIcon: suffixIcon,
      labelStyle: const TextStyle(color: kTextSecondary),
      hintStyle: const TextStyle(color: kTextMuted),
      filled: true,
      fillColor: kTextPrimary.withAlpha(6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: kTextPrimary.withAlpha(12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: kTextPrimary.withAlpha(12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kAccentPurple, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.redAccent.withAlpha(160)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback? onPressed,
    required bool loading,
  }) {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null
              ? null
              : const LinearGradient(
                  colors: [kAccentPurple, Color(0xFF6D28D9)],
                ),
          color: onPressed == null ? kSurfaceDark : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: onPressed == null
              ? null
              : [
                  BoxShadow(
                    color: kAccentPurple.withAlpha(50),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: kTextPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kTextPrimary,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.redAccent.shade100, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.redAccent.shade100, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_awaitingCode) {
      return _buildCodeScreen();
    }

    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: kBgDark,
      body: Container(
        decoration: const BoxDecoration(gradient: kBgGradient),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [kAccentPurple.withAlpha(35), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: -90,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [kAccentCyan.withAlpha(18), Colors.transparent],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        if (canPop)
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: kTextPrimary.withAlpha(10),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: kTextPrimary.withAlpha(15)),
                              ),
                              child: const Icon(Icons.arrow_back_rounded,
                                  color: kTextPrimary, size: 20),
                            ),
                          )
                        else
                          const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'SUM SPRINT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: kTextPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: kTextPrimary.withAlpha(6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kTextPrimary.withAlpha(10)),
                      ),
                      child: TabBar(
                        controller: _tabCtrl,
                        indicator: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [kAccentPurple, Color(0xFF6D28D9)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: kAccentPurple.withAlpha(50),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: kTextPrimary,
                        unselectedLabelColor: kTextSecondary,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'Sign In'),
                          Tab(text: 'Sign Up'),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _form(isSignUp: false),
                        _form(isSignUp: true),
                      ],
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

  Widget _buildCodeScreen() {
    final auth = context.watch<AuthProvider>();
    final email = _pendingEmail ?? '';

    return Scaffold(
      backgroundColor: kBgDark,
      body: Container(
        decoration: const BoxDecoration(gradient: kBgGradient),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              left: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [kAccentCyan.withAlpha(28), Colors.transparent],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            auth.clearPendingSignup();
                            auth.clearError();
                            setState(() => _awaitingCode = false);
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: kTextPrimary.withAlpha(10),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: kTextPrimary.withAlpha(15)),
                            ),
                            child: const Icon(Icons.arrow_back_rounded,
                                color: kTextPrimary, size: 20),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'VERIFY EMAIL',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: kTextPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: kSurfaceDark,
                                border: Border.all(
                                    color: kAccentPurple.withAlpha(80),
                                    width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: kAccentPurple.withAlpha(40),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.mark_email_read_outlined,
                                size: 40,
                                color: kAccentPurple,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Check your email',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: kTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We sent a verification code to\n$email',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: kTextSecondary,
                            ),
                          ),
                          if (SupabaseConfig.debugMode) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: kAccentGold.withAlpha(20),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: kAccentGold.withAlpha(50)),
                              ),
                              child: Text(
                                'Dev: use ${SupabaseConfig.devOtpCode}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: kAccentGold,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          TextField(
                            controller: _codeCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 8,
                              color: kTextPrimary,
                            ),
                            cursorColor: kAccentPurple,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(8),
                            ],
                            decoration: _fieldDecoration(
                              label: 'Verification code',
                              icon: Icons.pin_outlined,
                              hint: '••••••',
                            ).copyWith(
                              prefixIcon: null,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 18),
                            ),
                            onSubmitted: (_) => _verifyCode(),
                          ),
                          if (auth.errorMessage != null) ...[
                            const SizedBox(height: 12),
                            _errorBanner(auth.errorMessage!),
                          ],
                          const SizedBox(height: 20),
                          _primaryButton(
                            label: 'Verify & continue',
                            onPressed: auth.isLoading ? null : _verifyCode,
                            loading: auth.isLoading,
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: auth.isLoading ? null : _resendCode,
                            child: const Text(
                              'Resend code',
                              style: TextStyle(color: kAccentCyan),
                            ),
                          ),
                        ],
                      ),
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

  Widget _form({required bool isSignUp}) {
    final auth = context.watch<AuthProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Form(
        key: isSignUp ? _signUpFormKey : _signInFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kSurfaceDark,
                  border: Border.all(
                      color: kAccentPurple.withAlpha(80), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: kAccentPurple.withAlpha(40),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.calculate_rounded,
                  size: 40,
                  color: kAccentPurple,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              isSignUp ? 'Create Account' : 'Welcome Back',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSignUp
                  ? 'Sign up, then enter the code we email you.'
                  : 'Sign in to continue where you left off.',
              style: const TextStyle(fontSize: 14, color: kTextSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: kSurfaceDark,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kTextPrimary.withAlpha(8)),
                boxShadow: [
                  BoxShadow(
                    color: kAccentPurple.withAlpha(8),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: isSignUp
                        ? TextInputAction.next
                        : TextInputAction.done,
                    style: const TextStyle(color: kTextPrimary),
                    cursorColor: kAccentPurple,
                    decoration: _fieldDecoration(
                      label: 'Email',
                      icon: Icons.email_outlined,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!v.contains('@') || !v.contains('.')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscurePass,
                    style: const TextStyle(color: kTextPrimary),
                    cursorColor: kAccentPurple,
                    decoration: _fieldDecoration(
                      label: 'Password',
                      icon: Icons.lock_outlined,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePass
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: kTextMuted,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Password is required';
                      }
                      if (isSignUp && v.length < 6) {
                        return 'At least 6 characters';
                      }
                      return null;
                    },
                  ),
                  if (isSignUp) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nickCtrl,
                      style: const TextStyle(color: kTextPrimary),
                      cursorColor: kAccentPurple,
                      decoration: _fieldDecoration(
                        label: 'Nickname (optional)',
                        icon: Icons.person_outline,
                        hint: 'How others see you on leaderboards',
                      ),
                    ),
                  ],
                  if (auth.errorMessage != null) ...[
                    const SizedBox(height: 14),
                    _errorBanner(auth.errorMessage!),
                  ],
                  const SizedBox(height: 18),
                  _primaryButton(
                    label: isSignUp ? 'Create Account' : 'Sign In',
                    onPressed: auth.isLoading
                        ? null
                        : (isSignUp ? _signUp : _signIn),
                    loading: auth.isLoading,
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
