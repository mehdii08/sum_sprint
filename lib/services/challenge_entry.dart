import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/challenge_definition.dart';
import '../providers/tg_home_provider.dart';
import '../theme/app_theme.dart';

/// Charges [challenge.entryCoins] (0 = free). Returns true if play may begin.
Future<bool> payChallengeEntry(
  BuildContext context,
  ChallengeDefinition challenge,
) async {
  if (challenge.isFree) return true;

  final tgHome = context.read<TgHomeProvider>();
  final cost = challenge.entryCoins;

  if (tgHome.coins < cost) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Need $cost coins (you have ${tgHome.coins})'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
    return false;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: kSurfaceDark,
      title: const Text('Start challenge?', style: TextStyle(color: kTextPrimary)),
      content: Text(
        'This costs $cost coins. You have ${tgHome.coins}.',
        style: const TextStyle(color: kTextSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: kAccentPurple,
            foregroundColor: Colors.white,
          ),
          child: Text('Pay $cost'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;

  final remaining = await tgHome.payChallengeEntry(challenge.id);
  if (!context.mounted) return false;

  if (remaining == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tgHome.errorMessage ?? 'Could not start challenge'),
        backgroundColor: Colors.red.shade700,
      ),
    );
    return false;
  }

  return true;
}
