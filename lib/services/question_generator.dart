import 'dart:math';
import '../models/challenge_definition.dart';
import '../models/question.dart';

/// Generates questions based on a [ChallengeDefinition].
///
/// Uses a switch on `challenge.operation` to compute the correct answer.
/// **Future:** new operations (e.g. subtraction, multiplication, pattern recognition)
/// can be added here by implementing a new case in the switch.
class QuestionGenerator {
  final Random _random;

  QuestionGenerator({Random? random}) : _random = random ?? Random();

  Question generate(ChallengeDefinition challenge) {
    final int num1 = challenge.minNumber +
        _random.nextInt(challenge.maxNumber - challenge.minNumber + 1);
    final int num2 = challenge.minNumber +
        _random.nextInt(challenge.maxNumber - challenge.minNumber + 1);

    // Compute correct answer based on operation.
    // Future: new operations can be added here.
    final int correctAnswer = switch (challenge.operation) {
      '+' => num1 + num2,
      // TODO: add '-', '×', pattern recognition, etc.
      _ => throw UnimplementedError(
          'Operation "${challenge.operation}" is not yet supported.',
        ),
    };

    // Generate two distinct decoys, ±1 to ±5 from correct answer, distinct and > 0
    final Set<int> decoySet = {};
    int attempts = 0;
    while (decoySet.length < 2 && attempts < 50) {
      final int offset =
          (_random.nextInt(5) + 1) * (_random.nextBool() ? 1 : -1);
      final int decoy = correctAnswer + offset;
      if (decoy != correctAnswer && decoy > 0) {
        decoySet.add(decoy);
      }
      attempts++;
    }

    // Fallback if we couldn't generate enough decoys
    while (decoySet.length < 2) {
      final int fallback = correctAnswer + decoySet.length + 1;
      decoySet.add(fallback);
    }

    final List<int> options = [correctAnswer, ...decoySet];
    options.shuffle(_random);

    return Question(
      num1: num1,
      num2: num2,
      correctAnswer: correctAnswer,
      options: options,
    );
  }
}
