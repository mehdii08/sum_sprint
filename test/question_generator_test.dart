import 'package:flutter_test/flutter_test.dart';
import 'package:sum_sprint/models/challenge_definition.dart';
import 'package:sum_sprint/services/question_generator.dart';

void main() {
  group('QuestionGenerator', () {
    final generator = QuestionGenerator();

    test('generates question with correct answer for addition', () {
      const challenge = ChallengeDefinition(
        id: 'test',
        name: 'Test',
        description: '',
        operation: '+',
        minNumber: 1,
        maxNumber: 10,
        timePerQuestionSeconds: 5,
        questionCount: 10,
      );

      final question = generator.generate(challenge);

      // Check num1 and num2 are in range
      expect(question.num1, greaterThanOrEqualTo(1));
      expect(question.num1, lessThanOrEqualTo(10));
      expect(question.num2, greaterThanOrEqualTo(1));
      expect(question.num2, lessThanOrEqualTo(10));

      // Check correct answer
      expect(question.correctAnswer, equals(question.num1 + question.num2));

      // Check options
      expect(question.options.length, equals(3));
      expect(question.options, contains(question.correctAnswer));

      // All options should be distinct
      expect(question.options.toSet().length, equals(3));

      // Decoys should be within ±5 of correct answer and not equal to correct
      for (final option in question.options) {
        if (option != question.correctAnswer) {
          expect(
            (option - question.correctAnswer).abs(),
            lessThanOrEqualTo(5),
          );
          expect(option, isNot(equals(question.correctAnswer)));
        }
      }
    });

    test('generates distinct questions across multiple calls', () {
      const challenge = ChallengeDefinition(
        id: 'test',
        name: 'Test',
        description: '',
        operation: '+',
        minNumber: 1,
        maxNumber: 10,
        timePerQuestionSeconds: 5,
        questionCount: 10,
      );

      final questions = List.generate(10, (_) => generator.generate(challenge));

      // Check all have valid options
      for (final q in questions) {
        expect(q.options.length, equals(3));
        expect(q.options.toSet().length, equals(3));
      }
    });

    test('unsupported operation throws UnimplementedError', () {
      const challenge = ChallengeDefinition(
        id: 'test',
        name: 'Test',
        description: '',
        operation: '-',
        minNumber: 1,
        maxNumber: 10,
        timePerQuestionSeconds: 5,
        questionCount: 10,
      );

      expect(
        () => generator.generate(challenge),
        throwsUnimplementedError,
      );
    });

    test('handles minNumber equals maxNumber', () {
      const challenge = ChallengeDefinition(
        id: 'test',
        name: 'Test',
        description: '',
        operation: '+',
        minNumber: 5,
        maxNumber: 5,
        timePerQuestionSeconds: 5,
        questionCount: 10,
      );

      final question = generator.generate(challenge);
      expect(question.num1, equals(5));
      expect(question.num2, equals(5));
      expect(question.correctAnswer, equals(10));
      expect(question.options, contains(10));
    });
  });
}
