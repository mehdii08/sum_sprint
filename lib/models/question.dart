class Question {
  final int num1;
  final int num2;
  final int correctAnswer;
  final List<int> options;

  const Question({
    required this.num1,
    required this.num2,
    required this.correctAnswer,
    required this.options,
  });
}

class QuestionResult {
  final bool isCorrect;
  final int responseTimeMs; // time taken to answer, 0 means timeout

  const QuestionResult({
    required this.isCorrect,
    required this.responseTimeMs,
  });

  Map<String, dynamic> toJson() => {
        'isCorrect': isCorrect,
        'responseTimeMs': responseTimeMs,
      };

  factory QuestionResult.fromJson(Map<String, dynamic> json) {
    return QuestionResult(
      isCorrect: json['isCorrect'] as bool,
      responseTimeMs: json['responseTimeMs'] as int,
    );
  }
}
