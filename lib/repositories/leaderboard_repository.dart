import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/custom_leaderboard.dart';

class LeaderboardRepository {
  final SupabaseClient _client;

  LeaderboardRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  void _log(String msg) => debugPrint('[LeaderboardRepo] $msg');

  String? get currentUserId => _client.auth.currentUser?.id;

  // ── Custom leaderboards (tabs) ─────────────────────────────────

  Future<List<CustomLeaderboard>> getActiveCustomLeaderboards() async {
    _log('getActiveCustomLeaderboards');
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final response = await _client
          .from('custom_leaderboards')
          .select()
          .eq('is_active', true)
          .lte('start_date', now)
          .gte('end_date', now)
          .order('created_at', ascending: true);

      final list = response as List<dynamic>;
      _log('getActiveCustomLeaderboards — ${list.length} active');
      return list
          .map((e) => CustomLeaderboard.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _log('getActiveCustomLeaderboards ERROR: $e');
      return [];
    }
  }

  // ── Global leaderboard (all-time total score) ──────────────────

  Future<List<LeaderboardRanking>> getGlobalRankings({
    required int offset,
    required int limit,
  }) async {
    _log('getGlobalRankings — offset=$offset limit=$limit');
    try {
      final response = await _client
          .from('profiles')
          .select('id, nickname, telegram_username, total_score')
          .order('total_score', ascending: false)
          .range(offset, offset + limit - 1);

      final list = response as List<dynamic>;
      _log('getGlobalRankings — got ${list.length} rows');

      return list.asMap().entries.map((e) {
        final json = e.value as Map<String, dynamic>;
        return LeaderboardRanking(
          userId: json['id'] as String? ?? '',
          nickname: json['nickname'] as String? ?? 'Unknown',
          telegramUsername: json['telegram_username'] as String?,
          avatarUrl: json['avatar_url'] as String?,
          totalScore: json['total_score'] as int? ?? 0,
          rank: offset + e.key + 1,
        );
      }).toList();
    } catch (e) {
      _log('getGlobalRankings ERROR: $e');
      return [];
    }
  }

  Future<int> getUserGlobalRank(String userId) async {
    _log('getUserGlobalRank — userId=$userId');
    try {
      final myScoreResp = await _client
          .from('profiles')
          .select('total_score')
          .eq('id', userId)
          .maybeSingle();

      if (myScoreResp == null) return 0;
      final myScore = myScoreResp['total_score'] as int? ?? 0;

      final countResp = await _client
          .from('profiles')
          .select('id')
          .gt('total_score', myScore);

      final count = (countResp as List).length;
      _log('getUserGlobalRank — rank=${count + 1}');
      return count + 1;
    } catch (e) {
      _log('getUserGlobalRank ERROR: $e');
      return 0;
    }
  }

  Future<LeaderboardRanking?> getUserGlobalEntry(String userId) async {
    _log('getUserGlobalEntry — userId=$userId');
    try {
      final myResp = await _client
          .from('profiles')
          .select('id, nickname, telegram_username, total_score')
          .eq('id', userId)
          .maybeSingle();

      if (myResp == null) return null;
      final json = myResp;
      final rank = await getUserGlobalRank(userId);

      return LeaderboardRanking(
        userId: json['id'] as String? ?? '',
        nickname: json['nickname'] as String? ?? 'Unknown',
        telegramUsername: json['telegram_username'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        totalScore: json['total_score'] as int? ?? 0,
        rank: rank,
      );
    } catch (e) {
      _log('getUserGlobalEntry ERROR: $e');
      return null;
    }
  }

  // ── Custom leaderboard rankings ────────────────────────────────

  Future<List<LeaderboardRanking>> getCustomLeaderboardRankings({
    required String leaderboardId,
    required int offset,
    required int limit,
  }) async {
    _log('getCustomLeaderboardRankings — id=$leaderboardId offset=$offset limit=$limit');
    try {
      final lb = await _client
          .from('custom_leaderboards')
          .select('start_date, end_date')
          .eq('id', leaderboardId)
          .maybeSingle();

      if (lb == null) return [];
      final startDate = lb['start_date'] as String;
      final endDate = lb['end_date'] as String;

      final response = await _client
          .from('challenge_results')
          .select('user_id, score, profiles!inner(nickname, telegram_username)')
          .gte('created_at', startDate)
          .lte('created_at', endDate);

      final list = response as List<dynamic>;

      final Map<String, int> scoresByUser = {};
      final Map<String, Map<String, dynamic>> profilesByUser = {};
      for (final row in list) {
        final r = row as Map<String, dynamic>;
        final uid = r['user_id'] as String;
        scoresByUser[uid] = (scoresByUser[uid] ?? 0) + ((r['score'] as int?) ?? 0);
        if (!profilesByUser.containsKey(uid) && r['profiles'] != null) {
          profilesByUser[uid] = r['profiles'] as Map<String, dynamic>;
        }
      }

      final sorted = scoresByUser.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final paginated = sorted.skip(offset).take(limit).toList();

      return paginated.asMap().entries.map((e) {
        final uid = e.value.key;
        final profile = profilesByUser[uid] ?? {};
        return LeaderboardRanking(
          userId: uid,
          nickname: profile['nickname'] as String? ?? 'Unknown',
          telegramUsername: profile['telegram_username'] as String?,
          avatarUrl: profile['avatar_url'] as String?,
          totalScore: e.value.value,
          rank: offset + e.key + 1,
        );
      }).toList();
    } catch (e) {
      _log('getCustomLeaderboardRankings ERROR: $e');
      return [];
    }
  }

  Future<LeaderboardRanking?> getUserCustomLeaderboardEntry({
    required String userId,
    required String leaderboardId,
  }) async {
    _log('getUserCustomLeaderboardEntry — userId=$userId lb=$leaderboardId');
    try {
      final lb = await _client
          .from('custom_leaderboards')
          .select('start_date, end_date')
          .eq('id', leaderboardId)
          .maybeSingle();

      if (lb == null) return null;
      final startDate = lb['start_date'] as String;
      final endDate = lb['end_date'] as String;

      final response = await _client
          .from('challenge_results')
          .select('user_id, score, profiles!inner(nickname, telegram_username)')
          .gte('created_at', startDate)
          .lte('created_at', endDate);

      final list = response as List<dynamic>;

      final Map<String, int> scoresByUser = {};
      final Map<String, Map<String, dynamic>> profilesByUser = {};
      for (final row in list) {
        final r = row as Map<String, dynamic>;
        final uid = r['user_id'] as String;
        scoresByUser[uid] = (scoresByUser[uid] ?? 0) + ((r['score'] as int?) ?? 0);
        if (!profilesByUser.containsKey(uid) && r['profiles'] != null) {
          profilesByUser[uid] = r['profiles'] as Map<String, dynamic>;
        }
      }

      final sorted = scoresByUser.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final userScore = scoresByUser[userId];
      if (userScore == null) return null;

      final rank = sorted.indexWhere((e) => e.key == userId) + 1;
      final profile = profilesByUser[userId] ?? {};

      return LeaderboardRanking(
        userId: userId,
        nickname: profile['nickname'] as String? ?? 'Unknown',
        telegramUsername: profile['telegram_username'] as String?,
        avatarUrl: profile['avatar_url'] as String?,
        totalScore: userScore,
        rank: rank,
      );
    } catch (e) {
      _log('getUserCustomLeaderboardEntry ERROR: $e');
      return null;
    }
  }
}
