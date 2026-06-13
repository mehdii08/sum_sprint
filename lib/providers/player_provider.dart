import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_data.dart';

class PlayerProvider extends ChangeNotifier {
  static const String _nicknameKey = 'player_nickname';

  final PlayerData _playerData = PlayerData();

  PlayerData get playerData => _playerData;
  String get nickname => _playerData.nickname;

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
}
