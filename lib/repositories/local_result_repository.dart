import 'package:shared_preferences/shared_preferences.dart';
import '../models/result.dart';
import 'result_repository.dart';

class LocalResultRepository implements ResultRepository {
  static const String _keyPrefix = 'results_';
  static const int _maxResults = 20;

  String _storageKey(String challengeId) => '$_keyPrefix$challengeId';

  @override
  Future<List<Result>> getResultsForChallenge(String challengeId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey(challengeId));
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final list = Result.listFromJson(jsonString);
      // Sort newest first
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> saveResult(Result result) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _storageKey(result.challengeId);
    final existing = await getResultsForChallenge(result.challengeId);

    // Add new result and keep only the newest _maxResults
    existing.insert(0, result);
    if (existing.length > _maxResults) {
      existing.removeRange(_maxResults, existing.length);
    }

    await prefs.setString(key, Result.listToJson(existing));
  }

  @override
  Future<int> getHighScore(String challengeId) async {
    final results = await getResultsForChallenge(challengeId);
    if (results.isEmpty) return 0;
    return results.map((r) => r.score).reduce((a, b) => a > b ? a : b);
  }

  @override
  Future<void> clearHistory(String challengeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey(challengeId));
  }
}
