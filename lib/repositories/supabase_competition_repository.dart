import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/competition.dart';
import '../models/result.dart';

/// Repository for Supabase competition operations.
///
/// **Logging:** every Supabase call logs its query and result via [debugPrint].
/// Check `flutter run` console output to trace all network interactions.
class SupabaseCompetitionRepository {
  final SupabaseClient _client;

  SupabaseCompetitionRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  void _log(String msg) => debugPrint('[Supabase] $msg');

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<Competition>> getCompetitions() async {
    _log('getCompetitions — SELECT * FROM competitions ORDER BY start_date DESC');
    try {
      final response = await _client
          .from('competitions')
          .select()
          .order('start_date', ascending: false);
      _log('getCompetitions — got ${(response as List).length} rows');
      return (response as List)
          .map((e) => Competition.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _log('getCompetitions ERROR: $e');
      return [];
    }
  }

  Future<Competition?> getCompetition(String competitionId) async {
    _log('getCompetition — SELECT * FROM competitions WHERE id=$competitionId');
    try {
      final response = await _client
          .from('competitions')
          .select()
          .eq('id', competitionId)
          .maybeSingle();
      _log('getCompetition — result: ${response != null ? "found" : "null"}');
      return response != null
          ? Competition.fromJson(response)
          : null;
    } catch (e) {
      _log('getCompetition ERROR: $e');
      return null;
    }
  }

  Future<bool> hasJoined(String competitionId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      _log('hasJoined — no current user');
      return false;
    }
    _log('hasJoined — SELECT FROM participants WHERE comp=$competitionId user=$userId');
    try {
      final response = await _client
          .from('participants')
          .select('competition_id')
          .eq('competition_id', competitionId)
          .eq('user_id', userId)
          .maybeSingle();
      _log('hasJoined — ${response != null ? "YES" : "NO"}');
      return response != null;
    } catch (e) {
      _log('hasJoined ERROR: $e');
      return false;
    }
  }

  Future<void> joinCompetition(String competitionId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    _log('joinCompetition — calling join_competition RPC');
    final competition = await getCompetition(competitionId);
    if (competition == null) throw Exception('Competition not found');

    await _client.rpc('join_competition', params: {
      'p_competition_id': competitionId,
      'p_user_id': userId,
      'p_entry_points': competition.entryPoints,
    });
    _log('joinCompetition — done');
  }

  Future<Participant?> getMyParticipation(String competitionId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    _log('getMyParticipation — SELECT FROM participants WHERE comp=$competitionId user=$userId');
    try {
      final response = await _client
          .from('participants')
          .select()
          .eq('competition_id', competitionId)
          .eq('user_id', userId)
          .maybeSingle();
      _log('getMyParticipation — ${response != null ? "found" : "null"}');
      return response != null
          ? Participant.fromJson(response)
          : null;
    } catch (e) {
      _log('getMyParticipation ERROR: $e');
      return null;
    }
  }

  Future<List<LeaderboardEntry>> getLeaderboard(
    String competitionId, {int limit = 20}) async {
    _log('getLeaderboard — SELECT FROM participants + profiles WHERE comp=$competitionId');
    try {
      final response = await _client
          .from('participants')
          .select('user_id, total_score, completed_challenges, profiles!inner(nickname, telegram_username)')
          .eq('competition_id', competitionId)
          .order('total_score', ascending: false)
          .limit(limit);

      _log('getLeaderboard — got ${(response as List).length} rows');
      final entries = (response as List<dynamic>);
      return entries.asMap().entries.map((e) {
        final json = e.value as Map<String, dynamic>;
        final profiles = json['profiles'] as Map<String, dynamic>?;
        return LeaderboardEntry(
          userId: json['user_id'] as String,
          nickname: profiles?['nickname'] as String? ?? 'Unknown',
          telegramUsername: profiles?['telegram_username'] as String?,
          totalScore: json['total_score'] as int? ?? 0,
          completedChallenges: json['completed_challenges'] as int? ?? 0,
          rank: e.key + 1,
        );
      }).toList();
    } catch (e) {
      _log('getLeaderboard ERROR: $e');
      return [];
    }
  }

  /// Returns the set of challenge IDs that the current user has already
  /// completed for this competition.
  Future<Set<String>> getCompletedChallengeIds(String competitionId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      _log('getCompletedChallengeIds — no current user');
      return {};
    }
    _log('getCompletedChallengeIds — SELECT challenge_id FROM challenge_results WHERE comp=$competitionId user=$userId');
    try {
      final response = await _client
          .from('challenge_results')
          .select('challenge_id')
          .eq('competition_id', competitionId)
          .eq('user_id', userId);
      _log('getCompletedChallengeIds — got ${(response as List).length} rows');
      return (response as List)
          .map((e) => (e as Map<String, dynamic>)['challenge_id'] as String)
          .toSet();
    } catch (e) {
      _log('getCompletedChallengeIds ERROR: $e');
      return {};
    }
  }

  /// Distribute prizes for a finished competition and mark it as finished.
  /// Idempotent — safe to call multiple times.
  /// Returns the winners list from the RPC response, or null on failure.
  Future<List<Map<String, dynamic>>?> finalizeCompetition(String competitionId) async {
    _log('finalizeCompetition — calling distribute_prizes RPC');
    try {
      final response = await _client.rpc('distribute_prizes', params: {
        'p_competition_id': competitionId,
      });

      final json = response as Map<String, dynamic>?;
      if (json?['distributed'] == true && json?['winners'] != null) {
        final winners =
            (json!['winners'] as List).cast<Map<String, dynamic>>();
        _log('finalizeCompetition — distributed to ${winners.length} winners');
        return winners;
      }
      _log('finalizeCompetition — already distributed or no winners');
      return [];
    } catch (e) {
      _log('finalizeCompetition ERROR: $e');
      return null;
    }
  }

  /// Get the final leaderboard with prize info for a finished competition.
  Future<List<LeaderboardEntry>> getFinalLeaderboard(
    String competitionId, {int limit = 20}) async {
    _log('getFinalLeaderboard — calling get_final_leaderboard RPC');
    try {
      final response = await _client.rpc('get_final_leaderboard', params: {
        'p_competition_id': competitionId,
      });

      final entries = (response as List<dynamic>);
      _log('getFinalLeaderboard — got ${entries.length} rows');
      return entries.map((e) {
        final json = e as Map<String, dynamic>;
        return LeaderboardEntry(
          userId: json['user_id'] as String,
          nickname: json['nickname'] as String? ?? 'Unknown',
          telegramUsername: json['telegram_username'] as String?,
          totalScore: json['total_score'] as int? ?? 0,
          completedChallenges: json['completed_challenges'] as int? ?? 0,
          rank: (json['rank'] as num).toInt(),
          prize: json['prize'] as int? ?? 0,
        );
      }).toList();
    } catch (e) {
      _log('getFinalLeaderboard ERROR: $e');
      return [];
    }
  }

  /// Submit a completed challenge result for a competition.
  /// Does NOT throw — logs errors and returns normally.
  Future<void> submitChallengeResult({
    required String competitionId,
    required Result result,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      _log('submitChallengeResult SKIP — no current user');
      return;
    }

    _log('submitChallengeResult — INSERT into challenge_results comp=$competitionId score=${result.score}');
    try {
      await _client.from('challenge_results').insert({
        'competition_id': competitionId,
        'user_id': userId,
        'challenge_id': result.challengeId,
        'score': result.score,
        'correct_count': result.correctCount,
        'total_time_ms': result.totalResponseTimeMs,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        if (result.isMindTimer) ...{
          'accuracy': result.averageAccuracy,
          'is_mind_timer': true,
        },
      });
      _log('submitChallengeResult — INSERT ok');
    } catch (e) {
      _log('submitChallengeResult INSERT ERROR: $e');
      // Continue — the RPC may still work below
    }

    // Try updating participant score — this only works if user joined.
    // It's ok if it fails (user hasn't joined yet or table issue).
    _log('submitChallengeResult — calling update_participant_score RPC');
    try {
      await _client.rpc('update_participant_score', params: {
        'p_competition_id': competitionId,
        'p_user_id': userId,
        'p_score': result.score,
      });
      _log('submitChallengeResult — RPC ok');
    } catch (e) {
      _log('submitChallengeResult RPC ERROR (may be expected): $e');
    }
  }
}
