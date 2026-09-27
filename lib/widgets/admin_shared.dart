import 'package:flutter/material.dart';
import '../../models/challenge_definition.dart';

// ── Numeric +/- widget ───────────────────────────────────────────

class AdminNumericField extends StatelessWidget {
  final String label;
  final IconData? icon;
  final int value;
  final int step;
  final int min;
  final int max;
  final bool compact;
  final ValueChanged<int> onChanged;

  const AdminNumericField({
    required this.label,
    this.icon,
    required this.value,
    required this.step,
    this.min = 0,
    this.max = 999999,
    this.compact = false,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final minusEnabled = value - step >= min;
    final plusEnabled = value + step <= max;

    return Container(
      padding: compact
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 18 : 22, color: const Color(0xFF1A237E)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: compact ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A237E),
                  ),
                ),
              ],
            ),
          ),
          _AdminStepButton(
            icon: Icons.remove,
            enabled: minusEnabled,
            compact: compact,
            onTap: minusEnabled
                ? () => onChanged((value - step).clamp(min, max))
                : null,
          ),
          SizedBox(width: compact ? 4 : 8),
          _AdminStepButton(
            icon: Icons.add,
            enabled: plusEnabled,
            compact: compact,
            onTap: plusEnabled
                ? () => onChanged((value + step).clamp(min, max))
                : null,
          ),
        ],
      ),
    );
  }
}

class _AdminStepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final bool compact;
  final VoidCallback? onTap;

  const _AdminStepButton({
    required this.icon,
    required this.enabled,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 32.0 : 40.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? const Color(0xFF1A237E)
              : Colors.grey.shade300,
        ),
        child: Icon(
          icon,
          size: compact ? 18 : 22,
          color: enabled ? Colors.white : Colors.grey.shade500,
        ),
      ),
    );
  }
}

// ── Double numeric +/- widget ─────────────────────────────────────

class AdminNumericDoubleField extends StatelessWidget {
  final String label;
  final double value;
  final double step;
  final double min;
  final double max;
  final bool compact;
  final int decimals;
  final ValueChanged<double> onChanged;

  const AdminNumericDoubleField({
    required this.label,
    required this.value,
    required this.step,
    this.min = 0.0,
    this.max = double.infinity,
    this.compact = false,
    this.decimals = 1,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final minusEnabled = value - step >= min;
    final plusEnabled = value + step <= max;

    return Container(
      padding: compact
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.toStringAsFixed(decimals),
                  style: TextStyle(
                    fontSize: compact ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A237E),
                  ),
                ),
              ],
            ),
          ),
          _AdminStepButton(
            icon: Icons.remove,
            enabled: minusEnabled,
            compact: compact,
            onTap: minusEnabled
                ? () {
                    final newVal = (value - step).clamp(min, max);
                    onChanged(double.parse(newVal.toStringAsFixed(decimals)));
                  }
                : null,
          ),
          SizedBox(width: compact ? 4 : 8),
          _AdminStepButton(
            icon: Icons.add,
            enabled: plusEnabled,
            compact: compact,
            onTap: plusEnabled
                ? () {
                    final newVal = (value + step).clamp(min, max);
                    onChanged(double.parse(newVal.toStringAsFixed(decimals)));
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

// ── Challenge field data ─────────────────────────────────────────

int _challengeIdCounter = 0;

class AdminChallengeField {
  final String id;
  String name = '';
  String type; // 'math', 'mind_timer', 'pair_hunt', or 'tic_tac_toe'

  int min = 1;
  int max = 10;
  int time = 5;

  double targetSeconds = 5.0;
  double rangeSeconds = 2.0;
  int maxPoints = 1000;

  int blockCount = 12;
  int timeLimitSeconds = 60;
  int pointsPerPair = 100;
  int maxTimeBonus = 500;
  int penaltyPerMismatch = 25;
  int entryCoins = 0;

  int qCount = 10;

  AdminChallengeField({this.type = 'math'}) : id = _generateId() {
    if (type == 'mind_timer') {
      qCount = 5;
      maxPoints = 1000;
    }
    if (type == 'pair_hunt') {
      qCount = 0;
    }
    if (type == 'tic_tac_toe') {
      qCount = 3;
      timeLimitSeconds = 30;
      maxPoints = 1000;
    }
  }

  AdminChallengeField.fromChallenge(ChallengeDefinition ch)
      : id = ch.id,
        name = ch.name,
        type = ch.isTicTacToe
            ? 'tic_tac_toe'
            : ch.isPairHunt
                ? 'pair_hunt'
                : ch.isMindTimer
                    ? 'mind_timer'
                    : 'math',
        min = ch.minNumber,
        max = ch.maxNumber,
        time = ch.timePerQuestionSeconds,
        targetSeconds = ch.targetSeconds,
        rangeSeconds = ch.rangeSeconds,
        maxPoints = ch.maxPoints,
        blockCount = ch.blockCount,
        timeLimitSeconds = ch.timeLimitSeconds,
        pointsPerPair = ch.pointsPerPair,
        maxTimeBonus = ch.maxTimeBonus,
        penaltyPerMismatch = ch.penaltyPerMismatch,
        entryCoins = ch.entryCoins,
        qCount = ch.questionCount;

  static String _generateId() {
    _challengeIdCounter++;
    final ts = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    return 'ch_${ts}_$_challengeIdCounter';
  }
}
