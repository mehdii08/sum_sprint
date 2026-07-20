import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'admin_competitions_screen.dart';
import 'admin_leaderboards_screen.dart';
import 'admin_challenges_screen.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';

/// Admin dashboard — shortcuts to management pages.
///
/// Access is restricted to users with `is_admin = true` in their profile.
/// The button to reach this screen is only shown to admins on the home screen,
/// but this double-check prevents deep-link access.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();

    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.adminAccessDenied),
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(l10n.adminAccessDeniedMsg,
                  style: const TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminDashboard),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Card(
            icon: Icons.calculate_rounded,
            title: 'Challenges',
            subtitle: 'Manage challenges shown on the home screen',
            color: const Color(0xFF1A237E),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminChallengesScreen()),
            ),
          ),
          _Card(
            icon: Icons.emoji_events,
            title: l10n.adminCompetitions,
            subtitle: l10n.adminCompetitionsSubtitle,
            color: Colors.amber,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminCompetitionsScreen()),
            ),
          ),
          _Card(
            icon: Icons.leaderboard,
            title: 'Custom Leaderboards',
            subtitle: 'Manage time-based leaderboards with date ranges and rewards',
            color: Colors.teal,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminLeaderboardsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _Card({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(30),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
