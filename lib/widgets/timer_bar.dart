import 'package:flutter/material.dart';

class TimerBar extends StatelessWidget {
  final double progress; // 0.0 (empty/time up) to 1.0 (full time)
  final double height;

  const TimerBar({
    super.key,
    required this.progress,
    this.height = 8.0,
  });

  Color _getColor() {
    if (progress > 0.66) {
      return Colors.green;
    } else if (progress > 0.33) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        color: Colors.grey.shade300,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(_getColor()),
          minHeight: height,
        ),
      ),
    );
  }
}
