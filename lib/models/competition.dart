import 'challenge_definition.dart';

/// Represents an online competition fetched from Supabase.
class Competition {
  final String id;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final List<ChallengeDefinition> challenges;
  final int entryPoints;
  final int prizePool;
  final int winnerCount;
  final List<double> winnerShares;
  final CompetitionStatus status;
  final DateTime createdAt;

  const Competition({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.challenges,
    required this.entryPoints,
    required this.prizePool,
    required this.winnerCount,
    required this.winnerShares,
    required this.status,
    required this.createdAt,
  });

  factory Competition.fromJson(Map<String, dynamic> json) {
    final challengesJson = json['challenges'] as List<dynamic>;
    final challenges = challengesJson
        .map((e) => ChallengeDefinition.fromJson(e as Map<String, dynamic>))
        .toList();

    final sharesJson = json['winner_shares'] as List<dynamic>;
    final shares = sharesJson.map((e) => (e as num).toDouble()).toList();

    return Competition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      challenges: challenges,
      entryPoints: json['entry_points'] as int,
      prizePool: json['prize_pool'] as int,
      winnerCount: json['winner_count'] as int,
      winnerShares: shares,
      status: CompetitionStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Whether the start date has passed.
  bool get hasStarted => DateTime.now().toUtc().isAfter(startDate);

  /// Whether the end date has passed (regardless of DB status).
  bool get hasEnded => DateTime.now().toUtc().isAfter(endDate);

  /// Whether the competition is currently joinable.
  ///
  /// Must have started, must not have ended, and the DB status
  /// must not be 'finished'.
  bool get isJoinable =>
      hasStarted &&
      !hasEnded &&
      status != CompetitionStatus.finished;

  /// Whether the competition is currently active for playing.
  bool get isActive => hasStarted && !hasEnded && status == CompetitionStatus.active;

  /// Effective status — uses the actual date, not just the DB column.
  CompetitionStatus get effectiveStatus {
    if (status == CompetitionStatus.finished) return CompetitionStatus.finished;
    if (hasEnded) return CompetitionStatus.finished;
    if (!hasStarted) return CompetitionStatus.upcoming;
    return status;
  }

  /// Human-readable remaining time until the competition starts or ends.
  String get timeRemaining {
    final now = DateTime.now().toUtc();
    if (hasEnded) return 'Finished';
    if (!hasStarted) {
      final diff = startDate.difference(now);
      if (diff.inDays > 0) return _formatDuration(diff, prefix: 'Starts in ');
      if (diff.inHours > 0) return _formatDuration(diff, prefix: 'Starts in ');
      if (diff.inMinutes > 1) return _formatDuration(diff, prefix: 'Starts in ');
      return 'Starting soon';
    }
    // Competition is live — show remaining time
    final diff = endDate.difference(now);
    if (diff.isNegative || diff.inMinutes < 1) return 'Ending soon';
    return _formatDuration(diff, suffix: ' left');
  }

  static String _formatDuration(Duration d, {String prefix = '', String suffix = ''}) {
    final parts = <String>[];
    if (d.inDays > 0) parts.add('${d.inDays}d');
    if (d.inHours % 24 > 0) parts.add('${d.inHours % 24}h');
    if (d.inMinutes % 60 > 0) parts.add('${d.inMinutes % 60}m');
    return '$prefix${parts.join(' ')}$suffix';
  }
}

enum CompetitionStatus {
  upcoming('upcoming'),
  active('active'),
  finished('finished');

  final String value;
  const CompetitionStatus(this.value);

  static CompetitionStatus fromString(String s) {
    return CompetitionStatus.values.firstWhere(
      (e) => e.value == s,
      orElse: () => CompetitionStatus.upcoming,
    );
  }
}

/// Represents a participant in a competition (joined user).
class Participant {
  final String competitionId;
  final String userId;
  final int totalScore;
  final int completedChallenges;
  final DateTime joinedAt;

  const Participant({
    required this.competitionId,
    required this.userId,
    required this.totalScore,
    required this.completedChallenges,
    required this.joinedAt,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      competitionId: json['competition_id'] as String,
      userId: json['user_id'] as String,
      totalScore: json['total_score'] as int? ?? 0,
      completedChallenges: json['completed_challenges'] as int? ?? 0,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }
}

/// A leaderboard entry combining participant data with profile info.
class LeaderboardEntry {
  final String userId;
  final String nickname;
  final String? telegramUsername;
  final int totalScore;
  final int completedChallenges;
  final int rank;
  final int prize;

  const LeaderboardEntry({
    required this.userId,
    required this.nickname,
    this.telegramUsername,
    required this.totalScore,
    required this.completedChallenges,
    required this.rank,
    this.prize = 0,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'] as Map<String, dynamic>?;
    return LeaderboardEntry(
      userId: json['user_id'] as String,
      nickname: profiles?['nickname'] as String? ?? json['nickname'] as String? ?? 'Unknown',
      telegramUsername: profiles?['telegram_username'] as String? ?? json['telegram_username'] as String?,
      totalScore: json['total_score'] as int? ?? 0,
      completedChallenges: json['completed_challenges'] as int? ?? 0,
      rank: (json['rank'] as int?) ?? 0,
      prize: json['prize'] as int? ?? 0,
    );
  }
}
