import 'package:flutter/foundation.dart';
import '../models/result.dart';
import '../repositories/local_result_repository.dart';

class ResultProvider extends ChangeNotifier {
  final LocalResultRepository _repository = LocalResultRepository();
  final Map<String, List<Result>> _resultsCache = {};
  final Map<String, int> _highScoreCache = {};

  Future<List<Result>> getResultsForChallenge(String challengeId) async {
    if (_resultsCache.containsKey(challengeId)) {
      return _resultsCache[challengeId]!;
    }
    final results = await _repository.getResultsForChallenge(challengeId);
    _resultsCache[challengeId] = results;
    return results;
  }

  Future<int> getHighScore(String challengeId) async {
    if (_highScoreCache.containsKey(challengeId)) {
      return _highScoreCache[challengeId]!;
    }
    final highScore = await _repository.getHighScore(challengeId);
    _highScoreCache[challengeId] = highScore;
    return highScore;
  }

  Future<void> saveResult(Result result) async {
    await _repository.saveResult(result);

    // Update cache
    final existing = _resultsCache[result.challengeId] ?? [];
    existing.insert(0, result);
    _resultsCache[result.challengeId] = existing;

    // Update high score
    final currentHigh = _highScoreCache[result.challengeId] ?? 0;
    if (result.score > currentHigh) {
      _highScoreCache[result.challengeId] = result.score;
    }

    notifyListeners();
  }

  Future<void> clearHistory(String challengeId) async {
    await _repository.clearHistory(challengeId);
    _resultsCache.remove(challengeId);
    _highScoreCache.remove(challengeId);
    notifyListeners();
  }

  bool isNewHighScore(Result result, int previousHighScore) {
    return result.score > previousHighScore;
  }
}
