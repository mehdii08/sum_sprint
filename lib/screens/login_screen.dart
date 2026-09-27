import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../providers/tg_home_provider.dart';
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
  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();
  bool _obscurePass = true;

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
    final ok = await auth.signUpWithEmail(
      email: _emailCtrl.text,
      password: _passCtrl.text,
      nickname: _nickCtrl.text.trim().isNotEmpty
          ? _nickCtrl.text.trim()
          : _emailCtrl.text.split('@').first,
    );
    if (!mounted) return;
    if (ok) _onSuccess();
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

    // After logout the login screen is root — go straight home.
    // From splash, pop so splash can enter home.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sum Sprint'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1A237E),
            child: TabBar(
              controller: _tabCtrl,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(text: 'Sign In'),
                Tab(text: 'Sign Up'),
              ],
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
    );
  }

  Widget _form({required bool isSignUp}) {
    final auth = context.watch<AuthProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: isSignUp ? _signUpFormKey : _signInFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E).withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calculate,
                  size: 56, color: Color(0xFF1A237E)),
            ),
            const SizedBox(height: 24),
            Text(
              isSignUp ? 'Create Account' : 'Welcome Back',
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSignUp
                  ? 'Sign up to join competitions and track your scores.'
                  : 'Sign in to continue where you left off.',
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: isSignUp ? TextInputAction.next : TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscurePass,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outlined),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscurePass ? Icons.visibility_off : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscurePass = !_obscurePass),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Password is required';
                if (isSignUp && v.length < 6) return 'At least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            if (isSignUp)
              TextFormField(
                controller: _nickCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nickname (optional)',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                  hintText: 'How others see you on leaderboards',
                ),
              ),
            if (isSignUp) const SizedBox(height: 16),
            if (auth.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(auth.errorMessage!,
                          style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: auth.isLoading
                    ? null
                    : (isSignUp ? _signUp : _signIn),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: auth.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isSignUp ? 'Create Account' : 'Sign In',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
