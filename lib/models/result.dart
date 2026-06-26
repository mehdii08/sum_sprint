import 'dart:convert';

class Result {
  final String challengeId;
  final int score;
  final int correctCount;
  final int totalResponseTimeMs;
  final DateTime date;
  final String playerName;

  // ── Mind‑Timer–specific fields ───────────────────────────────────
  /// Number of questions where the user stopped within the valid range.
  final int withinRangeCount;

  /// Average accuracy across all questions (0.0–1.0), or 0 if no questions.
  final double averageAccuracy;

  /// Whether this result is for a Mind‑Timer challenge.
  final bool isMindTimer;

  Result({
    required this.challengeId,
    required this.score,
    required this.correctCount,
    required this.totalResponseTimeMs,
    required this.date,
    this.playerName = '',
    this.withinRangeCount = 0,
    this.averageAccuracy = 0.0,
    this.isMindTimer = false,
  });

  factory Result.fromJson(Map<String, dynamic> json) {
    return Result(
      challengeId: json['challengeId'] as String,
      score: json['score'] as int,
      correctCount: json['correctCount'] as int,
      totalResponseTimeMs: json['totalResponseTimeMs'] as int,
      date: DateTime.parse(json['date'] as String),
      playerName: json['playerName'] as String? ?? '',
      withinRangeCount: json['withinRangeCount'] as int? ?? 0,
      averageAccuracy: (json['averageAccuracy'] as num?)?.toDouble() ?? 0.0,
      isMindTimer: json['isMindTimer'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'challengeId': challengeId,
        'score': score,
        'correctCount': correctCount,
        'totalResponseTimeMs': totalResponseTimeMs,
        'date': date.toIso8601String(),
        'playerName': playerName,
        'withinRangeCount': withinRangeCount,
        'averageAccuracy': averageAccuracy,
        'isMindTimer': isMindTimer,
      };

  double get averageTimeSeconds =>
      correctCount > 0 ? (totalResponseTimeMs / correctCount) / 1000.0 : 0.0;

  static List<Result> listFromJson(String jsonString) {
    final List<dynamic> list = json.decode(jsonString) as List<dynamic>;
    return list
        .map((e) => Result.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<Result> results) {
    return json.encode(results.map((r) => r.toJson()).toList());
  }
}
