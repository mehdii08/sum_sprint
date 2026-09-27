import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../providers/tg_home_provider.dart';
import '../config/app_version.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'admin/admin_dashboard_screen.dart';
import '../utils/clear_app_cache.dart';
import 'login_screen.dart';

/// Profile screen — account info, nickname editing, and coins balance.
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
    final tgHome = context.read<TgHomeProvider>();
    final player = context.read<PlayerProvider>();
    _nicknameCtrl.text =
        tgHome.nickname != 'Player' ? tgHome.nickname : player.nickname;
  }

  void _confirmClearCache(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceDark,
        title: Text(l10n.profileClearCacheTitle,
            style: const TextStyle(color: kTextPrimary)),
        content: Text(
          l10n.profileClearCacheMessage,
          style: const TextStyle(color: kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: const TextStyle(color: kTextMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              clearAppCacheAndReload();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccentGold,
              foregroundColor: kTextPrimary,
            ),
            child: Text(l10n.profileClearAndReload),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceDark,
        title: Text(l10n.profileLogoutTitle,
            style: const TextStyle(color: kTextPrimary)),
        content: Text(
          l10n.profileLogoutMessage,
          style: const TextStyle(color: kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: const TextStyle(color: kTextMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = context.read<AuthProvider>();
              final player = context.read<PlayerProvider>();
              await auth.signOut();
              player.clearUid();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.profileLogout),
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
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final player = context.watch<PlayerProvider>();
    final tgHome = context.watch<TgHomeProvider>();
    final displayName = tgHome.nickname != 'Player'
        ? tgHome.nickname
        : auth.displayName;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: kBgDark,
      body: Container(
        decoration: const BoxDecoration(gradient: kBgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: kTextPrimary),
                    ),
                    Expanded(
                      child: Text(
                        l10n.profileTitle,
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: kAccentPurple.withAlpha(80), width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: kAccentPurple.withAlpha(40),
                                blurRadius: 16),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: kSurfaceDark,
                          backgroundImage: auth.telegramPhotoUrl.isNotEmpty
                              ? NetworkImage(auth.telegramPhotoUrl)
                              : null,
                          child: auth.telegramPhotoUrl.isEmpty
                              ? Text(
                                  initial,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    color: kTextPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                        ),
                      ),
                    ),
                    if (auth.isTelegramUser &&
                        auth.telegramUsername.isNotEmpty)
                      Center(
                        child: Text(
                          '@${auth.telegramUsername}',
                          style: const TextStyle(
                              fontSize: 14,
                              color: kAccentCyan,
                              fontWeight: FontWeight.w500),
                        ),
                      )
                    else if (!auth.isTelegramUser &&
                        auth.userEmail.isNotEmpty)
                      Center(
                        child: Text(
                          auth.userEmail,
                          style: const TextStyle(
                              fontSize: 14, color: kTextSecondary),
                        ),
                      ),

                    const SizedBox(height: 28),

                    if (auth.isTelegramUser)
                      _sectionCard(
                        title: l10n.profileTelegramAccount,
                        icon: Icons.send_rounded,
                        child: _rowTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF0088CC),
                            child: Icon(Icons.send_rounded,
                                color: Colors.white, size: 18),
                          ),
                          title: auth.telegramFullName.isNotEmpty
                              ? auth.telegramFullName
                              : l10n.profileTelegramUser,
                          subtitle: l10n.profileSignedInViaTelegram,
                        ),
                      )
                    else
                      _sectionCard(
                        title: l10n.profileAccount,
                        icon: Icons.email_outlined,
                        child: _rowTile(
                          leading: const CircleAvatar(
                            backgroundColor: kAccentPurple,
                            child: Icon(Icons.email_outlined,
                                color: Colors.white, size: 20),
                          ),
                          title: auth.userEmail.isNotEmpty
                              ? auth.userEmail
                              : l10n.profileSignedIn,
                          subtitle: l10n.profileSignedInWithEmail,
                        ),
                      ),

                    const SizedBox(height: 14),

                    _sectionCard(
                      title: l10n.profileDisplayName,
                      icon: Icons.person_outline_rounded,
                      child: _editingNickname
                          ? _editRow(
                              controller: _nicknameCtrl,
                              hint: l10n.profileNewNickname,
                              onSave: () async {
                                final n = _nicknameCtrl.text.trim();
                                if (n.isEmpty) return;
                                final tgHomeProvider =
                                    context.read<TgHomeProvider>();
                                await auth.setNickname(n);
                                await player.setNickname(n);
                                tgHomeProvider.updateNickname(n);
                                if (mounted) {
                                  setState(() => _editingNickname = false);
                                }
                              },
                              onCancel: () {
                                _nicknameCtrl.text = tgHome.nickname != 'Player'
                                    ? tgHome.nickname
                                    : player.nickname;
                                setState(() => _editingNickname = false);
                              },
                            )
                          : _rowTile(
                              title: displayName,
                              subtitle: l10n.profileShownOnLeaderboards,
                              trailing: TextButton(
                                onPressed: () =>
                                    setState(() => _editingNickname = true),
                                child: Text(l10n.profileEdit,
                                    style: const TextStyle(color: kAccentCyan)),
                              ),
                            ),
                    ),

                    const SizedBox(height: 14),

                    _sectionCard(
                      title: l10n.profileCoins,
                      icon: Icons.monetization_on_outlined,
                      child: _rowTile(
                        leading: const Icon(Icons.monetization_on,
                            color: kAccentGold, size: 28),
                        title: l10n.coinsAmount(tgHome.coins),
                        subtitle: l10n.profileCoinsHint,
                      ),
                    ),

                    if (auth.errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withAlpha(20),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.redAccent.withAlpha(40)),
                        ),
                        child: Text(l10n.tr(auth.errorMessage!),
                            style: const TextStyle(color: Colors.redAccent)),
                      ),
                    ],

                    if (kIsWeb) ...[
                      const SizedBox(height: 14),
                      _sectionCard(
                        title: l10n.profileAppUpdate,
                        icon: Icons.system_update_rounded,
                        child: InkWell(
                          onTap: () => _confirmClearCache(context),
                          borderRadius: BorderRadius.circular(12),
                          child: _rowTile(
                            leading: const Icon(Icons.cached_rounded,
                                color: kAccentGold),
                            title: l10n.profileClearCacheTitle,
                            subtitle: l10n.profileClearCacheSubtitle,
                            trailing: const Icon(Icons.chevron_right_rounded,
                                color: kTextMuted),
                          ),
                        ),
                      ),
                    ],

                    if (auth.isAdmin) ...[
                      const SizedBox(height: 14),
                      _sectionCard(
                        title: l10n.profileAdmin,
                        icon: Icons.admin_panel_settings_rounded,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const AdminDashboardScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: _rowTile(
                            leading: const Icon(
                                Icons.admin_panel_settings_rounded,
                                color: kAccentPurple),
                            title: l10n.adminPanel,
                            subtitle: l10n.profileAdminSubtitle,
                            trailing: const Icon(Icons.chevron_right_rounded,
                                color: kTextMuted),
                          ),
                        ),
                      ),
                    ],

                    if (!auth.isTelegramUser) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmLogout(context),
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          label: Text(
                            l10n.profileLogout,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: BorderSide(
                                color: Colors.redAccent.withAlpha(80)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),
                    const Center(
                      child: Text(
                        AppVersion.display,
                        style: TextStyle(
                          fontSize: 12,
                          color: kTextMuted,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kTextPrimary.withAlpha(8)),
        boxShadow: [
          BoxShadow(color: kAccentPurple.withAlpha(8), blurRadius: 16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: kAccentPurple),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kAccentPurple,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _rowTile({
    Widget? leading,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Row(
      children: [
        if (leading != null) ...[
          leading,
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(color: kTextSecondary, fontSize: 12)),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _editRow({
    required TextEditingController controller,
    required String hint,
    required VoidCallback onSave,
    required VoidCallback onCancel,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: kTextPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: kTextMuted),
              filled: true,
              fillColor: kBgDark,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kAccentPurple.withAlpha(40)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kTextPrimary.withAlpha(20)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kAccentPurple),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.check_rounded, color: Colors.greenAccent),
          onPressed: onSave,
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
          onPressed: onCancel,
        ),
      ],
    );
  }
}
