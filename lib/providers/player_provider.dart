import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_data.dart';

/// Manages player profile data: nickname and auth uid.
///
/// In offline mode, uid is empty and nickname is persisted in SharedPreferences.
/// When Supabase auth is active, uid is set to the Supabase user ID and
/// nickname is synced with the profiles table.
///
/// This provider remains unchanged for v1 offline mode compatibility.
class PlayerProvider extends ChangeNotifier {
  static const String _nicknameKey = 'player_nickname';

  final PlayerData _playerData = PlayerData();

  PlayerData get playerData => _playerData;
  String get nickname => _playerData.nickname;
  String get uid => _playerData.uid;
  bool get hasUid => _playerData.uid.isNotEmpty;

  PlayerProvider() {
    _loadNickname();
  }

  Future<void> _loadNickname() async {
    final prefs = await SharedPreferences.getInstance();
    _playerData.nickname = prefs.getString(_nicknameKey) ?? '';
    notifyListeners();
  }

  Future<void> setNickname(String nickname) async {
    _playerData.nickname = nickname.trim();
    final prefs = await SharedPreferences.getInstance();
    if (nickname.trim().isEmpty) {
      await prefs.remove(_nicknameKey);
    } else {
      await prefs.setString(_nicknameKey, _playerData.nickname);
    }
    notifyListeners();
  }

  /// Set the Supabase auth uid (called after login).
  void setUid(String uid) {
    _playerData.uid = uid;
    notifyListeners();
  }

  /// Clear auth data (called after logout).
  void clearUid() {
    _playerData.uid = '';
    notifyListeners();
  }
}
