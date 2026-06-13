import 'dart:convert';

class Result {
  final String challengeId;
  final int score;
  final int correctCount;
  final int totalResponseTimeMs;
  final DateTime date;
  final String playerName;

  Result({
    required this.challengeId,
    required this.score,
    required this.correctCount,
    required this.totalResponseTimeMs,
    required this.date,
    this.playerName = '',
  });

  factory Result.fromJson(Map<String, dynamic> json) {
    return Result(
      challengeId: json['challengeId'] as String,
      score: json['score'] as int,
      correctCount: json['correctCount'] as int,
      totalResponseTimeMs: json['totalResponseTimeMs'] as int,
      date: DateTime.parse(json['date'] as String),
      playerName: json['playerName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'challengeId': challengeId,
        'score': score,
        'correctCount': correctCount,
        'totalResponseTimeMs': totalResponseTimeMs,
        'date': date.toIso8601String(),
        'playerName': playerName,
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
