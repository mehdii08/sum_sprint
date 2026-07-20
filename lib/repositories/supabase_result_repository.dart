import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/result.dart';
import 'result_repository.dart';

/// Online result repository using Supabase.
///
/// Stores results in the `challenge_results` table and fetches history
/// from Supabase. Local caching is handled by [ResultProvider].
///
/// Note: Offline warm-up mode still uses [LocalResultRepository].
/// This repository is used for competition results submitted online.
class SupabaseResultRepository implements ResultRepository {
  final SupabaseClient _client;

  SupabaseResultRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<List<Result>> getResultsForChallenge(String challengeId) async {
    try {
      final response = await _client
          .from('challenge_results')
          .select()
          .eq('challenge_id', challengeId)
          .order('created_at', ascending: false)
          .limit(20);

      return (response as List<dynamic>)
          .map((e) => Result.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Failed to fetch results: $e');
      return [];
    }
  }

  @override
  Future<void> saveResult(Result result) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('challenge_results').insert({
        'user_id': userId,
        'challenge_id': result.challengeId,
        'score': result.score,
        'correct_count': result.correctCount,
        'total_time_ms': result.totalResponseTimeMs,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Failed to save result online: $e');
    }
  }

  /// Save a result specifically for a competition.
  Future<void> saveCompetitionResult({
    required String competitionId,
    required Result result,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      // Insert the challenge result
      await _client.from('challenge_results').insert({
        'competition_id': competitionId,
        'user_id': userId,
        'challenge_id': result.challengeId,
        'score': result.score,
        'correct_count': result.correctCount,
        'total_time_ms': result.totalResponseTimeMs,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Update participant's total score and completed count
      await _client
          .from('participants')
          .select('total_score, completed_challenges')
          .eq('competition_id', competitionId)
          .eq('user_id', userId)
          .single();

      // Use RPC to atomically update participant score
      await _client.rpc('update_participant_score', params: {
        'p_competition_id': competitionId,
        'p_user_id': userId,
        'p_score': result.score,
      });
    } catch (e) {
      debugPrint('Failed to save competition result: $e');
      rethrow;
    }
  }

  @override
  Future<int> getHighScore(String challengeId) async {
    try {
      final response = await _client
          .from('challenge_results')
          .select('score')
          .eq('challenge_id', challengeId)
          .order('score', ascending: false)
          .limit(1);

      final list = List<Map<String, dynamic>>.from(response);
      if (list.isEmpty) return 0;
      return list.first['score'] as int;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<void> clearHistory(String challengeId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client
          .from('challenge_results')
          .delete()
          .eq('user_id', userId)
          .eq('challenge_id', challengeId);
    } catch (e) {
      debugPrint('Failed to clear history: $e');
    }
  }
}
