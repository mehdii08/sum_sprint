import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TgHomeProvider extends ChangeNotifier {
  final SupabaseClient _client;

  bool _isLoadingProfile = false;
  Map<String, dynamic>? _profile;
  String? _errorMessage;

  TgHomeProvider({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  bool get isLoadingProfile => _isLoadingProfile;
  Map<String, dynamic>? get profile => _profile;
  /// Localization key; render with `AppLocalizations.tr`.
  String? get errorMessage => _errorMessage;

  int get totalScore => _profile?['total_score'] as int? ?? 0;
  int get coins => _profile?['coins'] as int? ?? 0;
  String get nickname {
    final nick = _profile?['nickname'] as String?;
    if (nick != null && nick.isNotEmpty) return nick;
    return 'Player';
  }

  void updateNickname(String nickname) {
    if (_profile == null) return;
    _profile = {..._profile!, 'nickname': nickname};
    notifyListeners();
  }

  void updateCoins(int coins) {
    if (_profile == null) {
      _profile = {'coins': coins};
    } else {
      _profile = {..._profile!, 'coins': coins};
    }
    notifyListeners();
  }

  /// Pays challenge entry (0 = free). Returns remaining coins, or null on failure.
  Future<int?> payChallengeEntry(String challengeId) async {
    try {
      final remaining = await _client.rpc(
        'pay_challenge_entry',
        params: {'p_challenge_id': challengeId},
      );
      final coinsLeft = (remaining as num?)?.toInt() ?? coins;
      updateCoins(coinsLeft);
      return coinsLeft;
    } catch (e) {
      _errorMessage = e.toString().contains('Insufficient coins')
          ? 'errNotEnoughCoins'
          : 'errStartChallengeFailed';
      debugPrint('[TgHome] payChallengeEntry error: $e');
      notifyListeners();
      return null;
    }
  }

  Future<void> loadProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    _isLoadingProfile = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resp = await _client
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();

      if (resp != null) {
        _profile = Map<String, dynamic>.from(resp as Map);
      }
    } catch (e) {
      _errorMessage = 'errLoadProfileFailed';
      debugPrint('[TgHome] loadProfile error: $e');
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
