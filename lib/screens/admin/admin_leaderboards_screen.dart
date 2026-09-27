import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../models/custom_leaderboard.dart';

class AdminLeaderboardsScreen extends StatefulWidget {
  const AdminLeaderboardsScreen({super.key});

  @override
  State<AdminLeaderboardsScreen> createState() =>
      _AdminLeaderboardsScreenState();
}

class _AdminLeaderboardsScreenState extends State<AdminLeaderboardsScreen> {
  final _client = Supabase.instance.client;
  List<CustomLeaderboard> _leaderboards = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _client
          .from('custom_leaderboards')
          .select()
          .order('created_at', ascending: false);
      _leaderboards = (res as List)
          .map((e) => CustomLeaderboard.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = '$e';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(String id) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminDeleteLeaderboardTitle),
        content: Text(l10n.adminDeleteLeaderboardMsg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.adminCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.adminDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _client.from('custom_leaderboards').delete().eq('id', id);
      _load();
    } catch (e) {
      if (mounted) _showError('$e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).adminCustomLeaderboards),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFF1A237E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _leaderboards.isEmpty
                  ? const _EmptyView()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _leaderboards.length,
                        itemBuilder: (context, index) {
                          final lb = _leaderboards[index];
                          return _LeaderboardCard(
                            leaderboard: lb,
                            onEdit: () => _openForm(leaderboard: lb),
                            onDelete: () => _delete(lb.id),
                          );
                        },
                      ),
                    ),
    );
  }

  void _openForm({CustomLeaderboard? leaderboard}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _LeaderboardFormScreen(
          leaderboard: leaderboard,
          onSaved: _load,
        ),
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final CustomLeaderboard leaderboard;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LeaderboardCard({
    required this.leaderboard,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final isActive = leaderboard.isActive &&
        now.isAfter(leaderboard.startDate) &&
        now.isBefore(leaderboard.endDate);
    final hasEnded = now.isAfter(leaderboard.endDate);
    final l10n = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.teal.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.leaderboard, color: Colors.teal, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    leaderboard.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.shade50
                        : hasEnded
                            ? Colors.grey.shade100
                            : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isActive
                        ? l10n.adminActive
                        : hasEnded
                            ? l10n.adminEnded
                            : l10n.adminUpcoming,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? Colors.green.shade700
                          : hasEnded
                              ? Colors.grey.shade600
                              : Colors.orange.shade700,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Text(l10n.adminEdit)),
                    PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n.adminDelete, style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${_fmt(leaderboard.startDate)} — ${_fmt(leaderboard.endDate)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
            if (leaderboard.rewards != null &&
                leaderboard.rewards!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.emoji_events, size: 14, color: Colors.amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      leaderboard.rewards!,
                      style: TextStyle(
                          fontSize: 13, color: Colors.brown.shade600),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

class _LeaderboardFormScreen extends StatefulWidget {
  final CustomLeaderboard? leaderboard;
  final VoidCallback onSaved;

  const _LeaderboardFormScreen({this.leaderboard, required this.onSaved});

  @override
  State<_LeaderboardFormScreen> createState() => _LeaderboardFormScreenState();
}

class _LeaderboardFormScreenState extends State<_LeaderboardFormScreen> {
  final _client = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _rewardsCtrl = TextEditingController();
  DateTime _startDate = DateTime.now().toUtc();
  DateTime _endDate = DateTime.now().toUtc().add(const Duration(days: 7));
  bool _isActive = true;
  bool _saving = false;

  bool get _isEditing => widget.leaderboard != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final lb = widget.leaderboard!;
      _titleCtrl.text = lb.title;
      _rewardsCtrl.text = lb.rewards ?? '';
      _startDate = lb.startDate;
      _endDate = lb.endDate;
      _isActive = lb.isActive;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _rewardsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final data = {
      'title': _titleCtrl.text.trim(),
      'description': '',
      'start_date': _startDate.toUtc().toIso8601String(),
      'end_date': _endDate.toUtc().toIso8601String(),
      'rewards': _rewardsCtrl.text.trim(),
      'is_active': _isActive,
    };

    try {
      if (_isEditing) {
        await _client
            .from('custom_leaderboards')
            .update(data)
            .eq('id', widget.leaderboard!.id);
      } else {
        data['created_at'] = DateTime.now().toUtc().toIso8601String();
        await _client.from('custom_leaderboards').insert(data);
      }
      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).adminSaveFailed(e)),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.adminEditLeaderboard : l10n.adminNewLeaderboard),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: l10n.adminTitleLabel,
                  hintText: l10n.adminTitleHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.adminTitleRequired : null,
              ),
              const SizedBox(height: 20),
              Text(l10n.adminDateRange,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: l10n.adminStartDate,
                      date: _startDate,
                      onTap: () => _pickDate(true),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward, size: 20, color: Colors.grey),
                  ),
                  Expanded(
                    child: _DateButton(
                      label: l10n.adminEndDate,
                      date: _endDate,
                      onTap: () => _pickDate(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _rewardsCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.adminRewardsLabel,
                  hintText: l10n.adminRewardsHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.adminActive,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(l10n.adminActiveLeaderboardHint),
                value: _isActive,
                activeTrackColor: const Color(0xFF1A237E),
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isEditing ? l10n.adminUpdate : l10n.adminCreate,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Color(0xFF1A237E)),
                const SizedBox(width: 6),
                Text(
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: onRetry, child: Text(AppLocalizations.of(context).adminRetry)),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(l10n.adminNoLeaderboards,
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(l10n.adminTapToCreate,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
