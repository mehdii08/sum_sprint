import '../models/result.dart';

abstract class ResultRepository {
  Future<List<Result>> getResultsForChallenge(String challengeId);
  Future<void> saveResult(Result result);
  Future<int> getHighScore(String challengeId);
  Future<void> clearHistory(String challengeId);
}
