import 'dart:convert';

class ChallengeDefinition {
  final String id;
  final String name;
  final String description;
  final String operation;
  final int minNumber;
  final int maxNumber;
  final int timePerQuestionSeconds;
  final int questionCount;

  const ChallengeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.operation,
    required this.minNumber,
    required this.maxNumber,
    required this.timePerQuestionSeconds,
    this.questionCount = 10,
  });

  factory ChallengeDefinition.fromJson(Map<String, dynamic> json) {
    return ChallengeDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      operation: json['operation'] as String,
      minNumber: json['minNumber'] as int,
      maxNumber: json['maxNumber'] as int,
      timePerQuestionSeconds: json['timePerQuestionSeconds'] as int,
      questionCount: json['questionCount'] as int? ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'operation': operation,
      'minNumber': minNumber,
      'maxNumber': maxNumber,
      'timePerQuestionSeconds': timePerQuestionSeconds,
      'questionCount': questionCount,
    };
  }

  static List<ChallengeDefinition> listFromJson(String jsonString) {
    final List<dynamic> list = json.decode(jsonString) as List<dynamic>;
    return list
        .map((e) => ChallengeDefinition.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
