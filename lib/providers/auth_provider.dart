import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../platform/telegram_init.dart';
import '../config/supabase_config.dart';

/// Manages authentication via Telegram Mini App.
class AuthProvider extends ChangeNotifier {
  final SupabaseClient _client;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isAdmin = false;
  Map<String, dynamic>? _cachedProfile;

  AuthProvider({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client {
    _client.auth.onAuthStateChange.listen((_) => notifyListeners());
  }

  // ── State getters ──────────────────────────────────────────────

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get userId => currentUser?.id ?? '';
  bool get isAdmin => _isAdmin;

  String get telegramFirstName => isTelegramUser ? tgFirstName : '';
  String get telegramLastName => isTelegramUser ? tgLastName : '';
  String get telegramUsername => isTelegramUser ? tgUsername : '';
  String get telegramPhotoUrl => isTelegramUser ? tgPhotoUrl : '';

  bool get isTelegramUser {
    final email = userEmail;
    return email.endsWith('@sumsprint.internal');
  }

  String get displayName {
    final nick = _cachedProfile?['nickname'] as String?;
    if (nick != null && nick.isNotEmpty) return nick;
    if (telegramFirstName.isNotEmpty) return telegramFirstName;
    final email = currentUser?.email;
    if (email != null && email.isNotEmpty && !isTelegramUser) {
      return email.split('@').first;
    }
    return 'Player';
  }

  String get telegramFullName {
    if (telegramFirstName.isEmpty) return '';
    if (telegramLastName.isEmpty) return telegramFirstName;
    return '$telegramFirstName $telegramLastName';
  }

  // ── Auth ───────────────────────────────────────────────────────

  Future<bool> signInWithTelegram() async {
    if (!isTelegramAvailable) return false;

    final initData = getTelegramInitData();
    if (initData == null || initData.isEmpty) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fnUrl = '${SupabaseConfig.url}/functions/v1/telegram-auth';

      final map = await postToEdgeFunction(
        url: fnUrl,
        anonKey: SupabaseConfig.anonKey,
        body: {'initData': initData},
      );

      if (map == null || map.containsKey('error')) {
        _errorMessage = map?['error'] as String? ?? 'Server did not respond.';
        _isLoading = false; notifyListeners(); return false;
      }

      final email = map['email'] as String?;
      final password = map['password'] as String?;
      if (email == null || password == null) {
        _isLoading = false; notifyListeners(); return false;
      }

      await _client.auth.signInWithPassword(email: email, password: password);

      if (_client.auth.currentUser == null) {
        _isLoading = false; notifyListeners(); return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      debugPrint('[Auth] AuthException: ${e.message}');
      _isLoading = false; notifyListeners(); return false;
    } catch (e) {
      debugPrint('[Auth] $e');
      _isLoading = false; notifyListeners(); return false;
    }
  }

  // ── Email / password auth (non-Telegram) ──────────────────────

  /// Sign up a new user with email + password. Also creates a profiles row.
  /// Returns true if sign-up + sign-in succeeded, false otherwise.
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String nickname,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Step 1 — create the user
      await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'nickname': nickname},
      );

      // If email confirmation is ON, signUp won't auto-sign-in.
      // Try sign-in explicitly.
      if (_client.auth.currentUser == null) {
        try {
          await _client.auth.signInWithPassword(
            email: email.trim(),
            password: password,
          );
        } catch (_) {
          // sign-up created the user but sign-in failed (likely email
          // confirmation required). Show a helpful message.
          _errorMessage = _emailConfirmMessage;
          _isLoading = false; notifyListeners(); return false;
        }
      }

      if (_client.auth.currentUser == null) {
        _errorMessage = _emailConfirmMessage;
        _isLoading = false; notifyListeners(); return false;
      }

      // Ensure profiles row exists
      await _ensureProfile(nickname);

      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _friendly(e.message);
      _isLoading = false; notifyListeners(); return false;
    } catch (e) {
      debugPrint('[Auth] signUp error: $e');
      _errorMessage = 'Connection error. Please try again.';
      _isLoading = false; notifyListeners(); return false;
    }
  }

  /// Sign in with email + password.
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (_client.auth.currentUser == null) {
        _errorMessage = 'Sign in failed. Check your credentials.';
        _isLoading = false; notifyListeners(); return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _friendly(e.message);
      _isLoading = false; notifyListeners(); return false;
    } catch (e) {
      debugPrint('[Auth] signIn error: $e');
      _errorMessage = 'Connection error. Please try again.';
      _isLoading = false; notifyListeners(); return false;
    }
  }

  // ── Session & profile ──────────────────────────────────────────

  Future<void> signOut() async {
    await _client.auth.signOut();
    _isAdmin = false;
    _cachedProfile = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final uid = currentUser?.id;
      if (uid == null) return null;
      final r = await _client.from('profiles').select().eq('id', uid).maybeSingle();
      if (r != null) {
        final profile = Map<String, dynamic>.from(r as Map);
        _isAdmin = profile['is_admin'] == true;
        _cachedProfile = profile;
        notifyListeners();
        return profile;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> setNickname(String nickname) async {
    try {
      final uid = currentUser?.id;
      if (uid == null) return;
      await _client.from('profiles').update({'nickname': nickname}).eq('id', uid);
      if (_cachedProfile != null) {
        _cachedProfile = {..._cachedProfile!, 'nickname': nickname};
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _ensureProfile(String nickname) async {
    try {
      final uid = currentUser?.id;
      if (uid == null) return;
      await _client.from('profiles').upsert({
        'id': uid,
        'nickname': nickname,
        'coins': 500,
      }, onConflict: 'id');
    } catch (_) {}
  }

  String get userEmail => currentUser?.email ?? '';

  void clearError() { _errorMessage = null; notifyListeners(); }

  // ── Helpers ──────────────────────────────────────────────────────

  static String _friendly(String raw) {
    final l = raw.toLowerCase();
    if (l.contains('invalid login') || l.contains('invalid email')) {
      return 'Invalid email or password.';
    }
    if (l.contains('already registered') || l.contains('already exists')) {
      return 'An account with this email already exists.';
    }
    if (l.contains('rate') || l.contains('too many')) {
      return 'Too many attempts. Please wait a moment.';
    }
    if (l.contains('network') || l.contains('connection') || l.contains('timeout')) {
      return 'Connection error. Check your internet.';
    }
    return raw;
  }

  static const _emailConfirmMessage =
      'Account created! If email confirmation is enabled in Supabase, '
      'check your inbox for a confirmation link, then sign in. '
      'Tip: disable email confirmation in Supabase → Authentication → Settings '
      'for easier local testing.';
}
