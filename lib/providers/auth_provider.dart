import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../platform/telegram_init.dart';
import '../config/supabase_config.dart';

/// Result of starting an email sign-up.
enum EmailSignUpResult {
  /// Session ready — can enter the app.
  success,

  /// Account created; user must enter the email verification code.
  needsVerification,

  /// Sign-up failed (see [AuthProvider.errorMessage]).
  failure,
}

/// Manages authentication via Telegram Mini App / email.
class AuthProvider extends ChangeNotifier {
  final SupabaseClient _client;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isAdmin = false;
  Map<String, dynamic>? _cachedProfile;
  String? _pendingSignupEmail;
  String? _pendingSignupNickname;
  String? _pendingSignupPassword;

  AuthProvider({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client {
    _client.auth.onAuthStateChange.listen((_) => notifyListeners());
  }

  // ── State getters ──────────────────────────────────────────────

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  bool get isLoading => _isLoading;
  /// Localization key (or raw server message); render with `AppLocalizations.tr`.
  String? get errorMessage => _errorMessage;
  String get userId => currentUser?.id ?? '';
  bool get isAdmin => _isAdmin;
  String? get pendingSignupEmail => _pendingSignupEmail;

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
        _errorMessage = map?['error'] as String? ?? 'errServerNoResponse';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final email = map['email'] as String?;
      final password = map['password'] as String?;
      if (email == null || password == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _client.auth.signInWithPassword(email: email, password: password);

      if (_client.auth.currentUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      debugPrint('[Auth] AuthException: ${e.message}');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[Auth] $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Email / password auth (non-Telegram) ──────────────────────

  /// Sign up with email + password.
  ///
  /// When email confirmation is required, returns
  /// [EmailSignUpResult.needsVerification] so the UI can collect the code.
  Future<EmailSignUpResult> signUpWithEmail({
    required String email,
    required String password,
    required String nickname,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _pendingSignupEmail = null;
    _pendingSignupNickname = null;
    _pendingSignupPassword = null;
    notifyListeners();

    final trimmed = email.trim();

    try {
      await _client.auth.signUp(
        email: trimmed,
        password: password,
        data: {'nickname': nickname},
      );

      if (_client.auth.currentUser == null) {
        _pendingSignupEmail = trimmed;
        _pendingSignupNickname = nickname;
        _pendingSignupPassword = password;
        _isLoading = false;
        notifyListeners();
        return EmailSignUpResult.needsVerification;
      }

      await _ensureProfile(nickname);
      _isLoading = false;
      notifyListeners();
      return EmailSignUpResult.success;
    } on AuthException catch (e) {
      _errorMessage = _friendly(e.message);
      _isLoading = false;
      notifyListeners();
      return EmailSignUpResult.failure;
    } catch (e) {
      debugPrint('[Auth] signUp error: $e');
      _errorMessage = 'errConnectionRetry';
      _isLoading = false;
      notifyListeners();
      return EmailSignUpResult.failure;
    }
  }

  /// Confirms signup with the code emailed to the user.
  ///
  /// In debug builds, code [SupabaseConfig.devOtpCode] bypasses email via
  /// the `dev-confirm-signup` edge function, then signs in with the pending
  /// password from sign-up.
  Future<bool> verifySignupCode({
    required String email,
    required String code,
    String? nickname,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final trimmedEmail = email.trim();
    final trimmedCode = code.trim();

    try {
      if (SupabaseConfig.debugMode &&
          trimmedCode == SupabaseConfig.devOtpCode) {
        final ok = await _confirmViaDevOtp(trimmedEmail);
        if (!ok) {
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        await _client.auth.verifyOTP(
          email: trimmedEmail,
          token: trimmedCode,
          type: OtpType.signup,
        );
      }

      if (_client.auth.currentUser == null) {
        _errorMessage = 'errInvalidCodeRetry';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final nick = nickname ??
          _pendingSignupNickname ??
          trimmedEmail.split('@').first;
      await _ensureProfile(nick);
      _pendingSignupEmail = null;
      _pendingSignupNickname = null;
      _pendingSignupPassword = null;

      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _friendly(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[Auth] verifySignupCode error: $e');
      _errorMessage = 'errVerifyCodeFailed';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _confirmViaDevOtp(String email) async {
    final password = _pendingSignupPassword;
    if (password == null || password.isEmpty) {
      _errorMessage = 'errDevOtpNeedsPassword';
      return false;
    }

    var confirmed = false;
    try {
      final ok = await _client.rpc('dev_confirm_signup', params: {
        'p_email': email,
        'p_code': SupabaseConfig.devOtpCode,
        'p_secret': SupabaseConfig.devOtpSecret,
      });
      confirmed = ok == true;
    } catch (e) {
      debugPrint('[Auth] dev_confirm_signup RPC: $e');
    }

    if (!confirmed) {
      final map = await postToEdgeFunction(
        url: '${SupabaseConfig.url}/functions/v1/dev-confirm-signup',
        anonKey: SupabaseConfig.anonKey,
        body: {'email': email, 'code': SupabaseConfig.devOtpCode},
        extraHeaders: {'x-dev-otp-secret': SupabaseConfig.devOtpSecret},
      );
      confirmed = map != null && map['ok'] == true;
      if (!confirmed) {
        _errorMessage = map?['error'] as String? ?? 'errDevConfirmFailed';
        return false;
      }
    }

    await _client.auth.signInWithPassword(email: email, password: password);
    return _client.auth.currentUser != null;
  }

  /// Resends the signup confirmation email / code.
  Future<bool> resendSignupCode(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email.trim(),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _friendly(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[Auth] resendSignupCode error: $e');
      _errorMessage = 'errResendFailed';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearPendingSignup() {
    _pendingSignupEmail = null;
    _pendingSignupNickname = null;
    _pendingSignupPassword = null;
    notifyListeners();
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
        _errorMessage = 'errSignInFailed';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _friendly(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[Auth] signIn error: $e');
      _errorMessage = 'errConnectionRetry';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Session & profile ──────────────────────────────────────────

  Future<void> signOut() async {
    await _client.auth.signOut();
    _isAdmin = false;
    _cachedProfile = null;
    _pendingSignupEmail = null;
    _pendingSignupNickname = null;
    _pendingSignupPassword = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final uid = currentUser?.id;
      if (uid == null) return null;
      final r =
          await _client.from('profiles').select().eq('id', uid).maybeSingle();
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
      await _client
          .from('profiles')
          .update({'nickname': nickname}).eq('id', uid);
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Helpers ──────────────────────────────────────────────────────

  static String _friendly(String raw) {
    final l = raw.toLowerCase();
    if (l.contains('invalid login') || l.contains('invalid email')) {
      return 'errInvalidCredentials';
    }
    if (l.contains('already registered') || l.contains('already exists')) {
      return 'errEmailExists';
    }
    if (l.contains('token') || l.contains('otp') || l.contains('expired')) {
      return 'errInvalidCodeRequestNew';
    }
    if (l.contains('rate') || l.contains('too many')) {
      return 'errTooManyAttempts';
    }
    if (l.contains('network') ||
        l.contains('connection') ||
        l.contains('timeout')) {
      return 'errNoInternet';
    }
    return raw;
  }
}
