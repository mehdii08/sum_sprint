import 'dart:convert';

/// Supported challenge types in Sum Sprint.
///
/// [challengeType] discriminates the challenge behavior:
/// - `'math'` → arithmetic questions (addition, subtraction, etc.)
/// - `'mind_timer'` → internal clock challenge (stop hidden timer at target)
enum ChallengeType {
  math('math'),
  mindTimer('mind_timer');

  final String value;
  const ChallengeType(this.value);

  static ChallengeType fromString(String s) {
    return ChallengeType.values.firstWhere(
      (e) => e.value == s,
      orElse: () => ChallengeType.math,
    );
  }
}

class ChallengeDefinition {
  // ── Common fields ────────────────────────────────────────────────
  final String id;
  final String name;
  final String description;
  final String operation; // e.g. '+' for math, 'mind_timer' for timer
  final int questionCount;

  /// Discriminator for challenge behavior. Defaults to `math`.
  final ChallengeType challengeType;

  // ── Math-specific fields (only meaningful when challengeType == math) ──
  final int minNumber;
  final int maxNumber;
  final int timePerQuestionSeconds;

  // ── Mind‑Timer–specific fields (only meaningful when challengeType == mindTimer) ──
  final double targetSeconds;  // e.g. 5.0 → user must stop at exactly 5 s
  final double rangeSeconds;   // e.g. 2.0 → max allowed deviation either side
  final int maxPoints;         // points for a perfect stop

  const ChallengeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.operation,
    this.challengeType = ChallengeType.math,
    this.questionCount = 10,
    // Math defaults
    this.minNumber = 1,
    this.maxNumber = 10,
    this.timePerQuestionSeconds = 5,
    // Mind‑Timer defaults
    this.targetSeconds = 5.0,
    this.rangeSeconds = 2.0,
    this.maxPoints = 1000,
  });

  bool get isMindTimer => challengeType == ChallengeType.mindTimer;
  bool get isMath => challengeType == ChallengeType.math;

  factory ChallengeDefinition.fromJson(Map<String, dynamic> json) {
    final type = (json['challengeType'] as String?) ??
        (json['operation'] == 'mind_timer' ? 'mind_timer' : 'math');
    return ChallengeDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      operation: json['operation'] as String? ?? '+',
      challengeType: ChallengeType.fromString(type),
      questionCount: json['questionCount'] as int? ?? 10,
      // Math fields
      minNumber: json['minNumber'] as int? ?? 1,
      maxNumber: json['maxNumber'] as int? ?? 10,
      timePerQuestionSeconds: json['timePerQuestionSeconds'] as int? ?? 5,
      // Mind‑Timer fields
      targetSeconds: (json['targetSeconds'] as num?)?.toDouble() ?? 5.0,
      rangeSeconds: (json['rangeSeconds'] as num?)?.toDouble() ?? 2.0,
      maxPoints: json['maxPoints'] as int? ?? 1000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'operation': operation,
      'challengeType': challengeType.value,
      'questionCount': questionCount,
      'minNumber': minNumber,
      'maxNumber': maxNumber,
      'timePerQuestionSeconds': timePerQuestionSeconds,
      'targetSeconds': targetSeconds,
      'rangeSeconds': rangeSeconds,
      'maxPoints': maxPoints,
    };
  }

  static List<ChallengeDefinition> listFromJson(String jsonString) {
    final List<dynamic> list = json.decode(jsonString) as List<dynamic>;
    return list
        .map((e) => ChallengeDefinition.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
