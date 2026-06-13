import 'package:flutter/material.dart';

class AnswerButton extends StatelessWidget {
  final int value;
  final VoidCallback? onTap;
  final bool isDisabled;
  final Color? backgroundColor;

  const AnswerButton({
    super.key,
    required this.value,
    this.onTap,
    this.isDisabled = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.blue.shade600,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (backgroundColor ?? Colors.blue.shade600).withAlpha(100),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
