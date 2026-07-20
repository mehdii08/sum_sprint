/// A custom leaderboard created by the admin.
///
/// Unlike competitions (which require joining), custom leaderboards
/// automatically include all users whose game results fall within
/// the date range. They appear as tabs on the leaderboard screen.
class CustomLeaderboard {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String? rewards;
  final bool isActive;
  final DateTime createdAt;

  const CustomLeaderboard({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.rewards,
    required this.isActive,
    required this.createdAt,
  });

  bool get isCurrentlyActive {
    final now = DateTime.now().toUtc();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }

  factory CustomLeaderboard.fromJson(Map<String, dynamic> json) {
    return CustomLeaderboard(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      rewards: json['rewards'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// A leaderboard ranking entry with score and profile info.
class LeaderboardRanking {
  final String userId;
  final String nickname;
  final String? telegramUsername;
  final String? avatarUrl;
  final int totalScore;
  final int rank;

  const LeaderboardRanking({
    required this.userId,
    required this.nickname,
    this.telegramUsername,
    this.avatarUrl,
    required this.totalScore,
    required this.rank,
  });

  factory LeaderboardRanking.fromJson(Map<String, dynamic> json, int index, int offset) {
    final profiles = json['profiles'] as Map<String, dynamic>?;
    return LeaderboardRanking(
      userId: json['user_id'] as String? ?? '',
      nickname: profiles?['nickname'] as String? ?? json['nickname'] as String? ?? 'Unknown',
      telegramUsername: profiles?['telegram_username'] as String? ?? json['telegram_username'] as String?,
      avatarUrl: profiles?['avatar_url'] as String?,
      totalScore: json['total_score'] as int? ?? 0,
      rank: offset + index + 1,
    );
  }
}
