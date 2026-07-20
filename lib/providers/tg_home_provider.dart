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
  String? get errorMessage => _errorMessage;

  int get totalScore => _profile?['total_score'] as int? ?? 0;
  int get coins => _profile?['coins'] as int? ?? 0;
  String get nickname => _profile?['nickname'] as String? ?? 'Player';

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
      _errorMessage = 'Failed to load profile';
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
