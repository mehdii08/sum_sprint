import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../config/supabase_config.dart';
import '../config/app_version.dart';
import 'admin/admin_dashboard_screen.dart';
import '../utils/clear_app_cache.dart';

/// Profile screen — shows Telegram info, nickname editing, and coins balance.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nicknameCtrl = TextEditingController();
  bool _editingNickname = false;

  @override
  void initState() {
    super.initState();
    _nicknameCtrl.text = context.read<PlayerProvider>().nickname;
  }

  void _confirmClearCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cache & Reload'),
        content: const Text(
          'This will remove all cached app files and reload '
          'the latest version. Your account data stays on the server.\n\n'
          'Use this if the app looks outdated or broken.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              clearAppCacheAndReload();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear & Reload'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final player = context.watch<PlayerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: const Color(0xFF1A237E),
              backgroundImage: auth.telegramPhotoUrl.isNotEmpty
                  ? NetworkImage(auth.telegramPhotoUrl)
                  : null,
              child: auth.telegramPhotoUrl.isEmpty
                  ? Text(
                      player.nickname.isNotEmpty
                          ? player.nickname[0].toUpperCase()
                          : auth.telegramFirstName.isNotEmpty
                              ? auth.telegramFirstName[0].toUpperCase()
                              : '?',
                      style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              auth.telegramFullName.isNotEmpty
                  ? auth.telegramFullName
                  : player.nickname.isNotEmpty
                      ? player.nickname
                      : 'Player',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          if (auth.telegramUsername.isNotEmpty)
            Center(
              child: Text(
                '@${auth.telegramUsername}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ),

          const SizedBox(height: 28),

          // Telegram account
          _sectionHeader('Telegram Account', Icons.telegram),
          ListTile(
            title: Text(auth.telegramFullName.isNotEmpty
                ? auth.telegramFullName
                : 'Unknown'),
            subtitle: const Text('Automatically signed in via Telegram'),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF0088CC),
              child: Text('📡', style: TextStyle(fontSize: 18)),
            ),
          ),

          const Divider(height: 32),

          // Nickname
          _sectionHeader('Display Name', Icons.person),
          if (_editingNickname)
            _editRow(
              controller: _nicknameCtrl,
              hint: 'New nickname',
              onSave: () async {
                final n = _nicknameCtrl.text.trim();
                if (n.isEmpty) return;
                await auth.setNickname(n);
                await player.setNickname(n);
                if (mounted) setState(() => _editingNickname = false);
              },
              onCancel: () {
                _nicknameCtrl.text = player.nickname;
                setState(() => _editingNickname = false);
              },
            )
          else
            _infoTile(
              title: player.nickname.isNotEmpty ? player.nickname : 'Not set',
              subtitle: 'Shown on leaderboards',
              action: 'Edit',
              onAction: () => setState(() => _editingNickname = true),
            ),

          const Divider(height: 32),

          // Coins
          _sectionHeader('Coins', Icons.monetization_on),
          FutureBuilder<Map<String, dynamic>?>(
            future: auth.getProfile(),
            builder: (_, snap) {
              final coins = snap.data?['coins'] ?? 0;
              return ListTile(
                title: Text('$coins coins'),
                subtitle: const Text('Spend to join competitions. Earn by winning.'),
                leading: const Icon(Icons.monetization_on, color: Colors.amber, size: 28),
              );
            },
          ),

          if (auth.errorMessage != null)
            _banner(auth.errorMessage!, Colors.red.shade50, Colors.red),

          // Clear Web Cache — only shown on web platform (PWA)
          if (kIsWeb) ...[
            const Divider(height: 32),
            _sectionHeader('App Update', Icons.system_update),
            ListTile(
              title: const Text('Clear Cache & Reload'),
              subtitle: const Text('Clears cached app files and reloads the latest version'),
              leading: const Icon(Icons.cached, color: Colors.orange),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _confirmClearCache(context),
            ),
          ],

          // Admin panel — visible to Telegram admin users, or in debug mode
          if (SupabaseConfig.adminUsernames.contains(auth.telegramUsername) ||
              (kDebugMode && SupabaseConfig.debugMode && auth.isLoggedIn)) ...[
            const Divider(height: 32),
            _sectionHeader('Admin', Icons.admin_panel_settings),
            ListTile(
              title: const Text('Admin Panel'),
              subtitle: const Text('Manage users, competitions, and more'),
              leading: const Icon(Icons.admin_panel_settings, color: Colors.deepPurple),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                );
              },
            ),
          ],

          // App version at the bottom
          const SizedBox(height: 24),
          Center(
            child: Text(
              AppVersion.display,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Text(title,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _infoTile({
    required String title,
    required String subtitle,
    String? action,
    VoidCallback? onAction,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: action != null
          ? TextButton(onPressed: onAction, child: Text(action))
          : null,
    );
  }

  Widget _editRow({
    required TextEditingController controller,
    required String hint,
    required VoidCallback onSave,
    required VoidCallback onCancel,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: onSave),
          IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: onCancel),
        ],
      ),
    );
  }

  Widget _banner(String msg, Color bg, Color fg) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(msg, style: TextStyle(color: fg)),
    );
  }
}
