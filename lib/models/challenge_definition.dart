import 'dart:convert';

/// Supported challenge types in Sum Sprint.
///
/// [challengeType] discriminates the challenge behavior:
/// - `'math'` → arithmetic questions (addition, subtraction, etc.)
/// - `'mind_timer'` → internal clock challenge (stop hidden timer at target)
/// - `'pair_hunt'` → memory card matching game (find emoji pairs)
enum ChallengeType {
  math('math'),
  mindTimer('mind_timer'),
  pairHunt('pair_hunt');

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

  // ── Pair‑Hunt–specific fields (only meaningful when challengeType == pairHunt) ──
  final int blockCount;          // total number of blocks, always even (4, 8, 12, 16, 20)
  final int timeLimitSeconds;    // total time limit for the whole game
  final int pointsPerPair;       // base points per matched pair (default 100)
  final int maxTimeBonus;        // max bonus for finishing early (default 500)
  final int penaltyPerMismatch;  // penalty for each wrong attempt (default 25)

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
    // Pair‑Hunt defaults
    this.blockCount = 12,
    this.timeLimitSeconds = 60,
    this.pointsPerPair = 100,
    this.maxTimeBonus = 500,
    this.penaltyPerMismatch = 25,
  });

  bool get isMindTimer => challengeType == ChallengeType.mindTimer;
  bool get isMath => challengeType == ChallengeType.math;
  bool get isPairHunt => challengeType == ChallengeType.pairHunt;

  /// Number of pairs in a Pair Hunt challenge (blocks / 2).
  int get pairCount => blockCount ~/ 2;

  factory ChallengeDefinition.fromJson(Map<String, dynamic> json) {
    final op = json['operation'] as String?;
    final type = (json['challengeType'] as String?) ??
        (op == 'mind_timer' ? 'mind_timer' : op == 'pair_hunt' ? 'pair_hunt' : 'math');
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
      // Pair‑Hunt fields
      blockCount: json['blockCount'] as int? ?? 12,
      timeLimitSeconds: json['timeLimitSeconds'] as int? ?? 60,
      pointsPerPair: json['pointsPerPair'] as int? ?? 100,
      maxTimeBonus: json['maxTimeBonus'] as int? ?? 500,
      penaltyPerMismatch: json['penaltyPerMismatch'] as int? ?? 25,
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
      'blockCount': blockCount,
      'timeLimitSeconds': timeLimitSeconds,
      'pointsPerPair': pointsPerPair,
      'maxTimeBonus': maxTimeBonus,
      'penaltyPerMismatch': penaltyPerMismatch,
    };
  }

  static List<ChallengeDefinition> listFromJson(String jsonString) {
    final List<dynamic> list = json.decode(jsonString) as List<dynamic>;
    return list
        .map((e) => ChallengeDefinition.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
