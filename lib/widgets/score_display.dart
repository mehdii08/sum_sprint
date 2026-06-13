import 'package:flutter/material.dart';

class ScoreDisplay extends StatelessWidget {
  final int score;
  final int correctCount;
  final int totalQuestions;

  const ScoreDisplay({
    super.key,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Chip(
          avatar: const Icon(Icons.star, size: 18, color: Colors.amber),
          label: Text(
            '$score',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          backgroundColor: Colors.amber.shade50,
        ),
        const SizedBox(width: 16),
        Chip(
          avatar: const Icon(Icons.check_circle, size: 18, color: Colors.green),
          label: Text(
            '$correctCount/$totalQuestions',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          backgroundColor: Colors.green.shade50,
        ),
      ],
    );
  }
}
