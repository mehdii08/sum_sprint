import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/challenge_definition.dart';
import '../../widgets/admin_shared.dart';

class AdminChallengesScreen extends StatefulWidget {
  const AdminChallengesScreen({super.key});

  @override
  State<AdminChallengesScreen> createState() => _AdminChallengesScreenState();
}

class _AdminChallengesScreenState extends State<AdminChallengesScreen> {
  final _client = Supabase.instance.client;
  List<ChallengeDefinition> _challenges = [];
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
          .from('challenges')
          .select()
          .order('display_order', ascending: true);
      _challenges = (res as List)
          .map((e) =>
              ChallengeDefinition.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = '$e';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Challenge'),
        content: const Text(
            'Are you sure you want to delete this challenge?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _client.from('challenges').delete().eq('id', id);
      _load();
    } catch (e) {
      if (mounted) _showError('$e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  String _typeLabel(ChallengeType t) {
    return switch (t) {
      ChallengeType.math => 'Math',
      ChallengeType.mindTimer => 'Mind Timer',
      ChallengeType.pairHunt => 'Pair Hunt',
      ChallengeType.ticTacToe => 'Tic-Tac-Toe',
    };
  }

  Color _typeColor(ChallengeType t) {
    return switch (t) {
      ChallengeType.math => Colors.orange,
      ChallengeType.mindTimer => Colors.indigo,
      ChallengeType.pairHunt => Colors.purple,
      ChallengeType.ticTacToe => Colors.teal,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Challenges'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create',
            onPressed: () async {
              final created =
                  await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const _ChallengeForm(challenge: null),
                ),
              );
              if (created != null) {
                try {
                  await _client.from('challenges').insert(created);
                  _load();
                } catch (e) {
                  _showError('$e');
                }
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _load,
                          child: const Text('Retry')),
                    ],
                  ),
                )
              : _challenges.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calculate_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No challenges yet',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey)),
                          SizedBox(height: 4),
                          Text('Tap + to create your first one',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _challenges.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex--;
                            final item =
                                _challenges.removeAt(oldIndex);
                            _challenges.insert(newIndex, item);
                          });
                          _updateOrder();
                        },
                        itemBuilder: (context, index) {
                          final c = _challenges[index];
                          final type = c.challengeType;
                          return Card(
                            key: ValueKey(c.id),
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                            child: ListTile(
                              leading: ReorderableDragStartListener(
                                index: index,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _typeColor(type)
                                        .withAlpha(30),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    switch (type) {
                                      ChallengeType.math =>
                                        Icons.calculate_rounded,
                                      ChallengeType.mindTimer =>
                                        Icons.timer,
                                      ChallengeType.pairHunt =>
                                        Icons.grid_view_rounded,
                                      ChallengeType.ticTacToe =>
                                        Icons.grid_3x3,
                                    },
                                    color: _typeColor(type),
                                    size: 22,
                                  ),
                                ),
                              ),
                              title: Text(c.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  '${_typeLabel(type)}  •  ${c.isFree ? 'Free' : '${c.entryCoins} coins'}'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (action) async {
                                  if (action == 'edit') {
                                    final updated =
                                        await Navigator.push<
                                            Map<String, dynamic>>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => _ChallengeForm(
                                            challenge: c),
                                      ),
                                    );
                                    if (updated != null) {
                                      try {
                                        await _client
                                            .from('challenges')
                                            .update(updated)
                                            .eq('id', c.id);
                                        _load();
                                      } catch (e) {
                                        _showError('$e');
                                      }
                                    }
                                  } else if (action == 'delete') {
                                    _delete(c.id);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit')),
                                  PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete',
                                          style: TextStyle(
                                              color: Colors.red))),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Future<void> _updateOrder() async {
    try {
      for (var i = 0; i < _challenges.length; i++) {
        await _client
            .from('challenges')
            .update({'display_order': i})
            .eq('id', _challenges[i].id);
      }
    } catch (_) {}
  }
}

// ── Create / Edit form ──────────────────────────────────────────

class _ChallengeForm extends StatefulWidget {
  final ChallengeDefinition? challenge;
  const _ChallengeForm({required this.challenge});

  @override
  State<_ChallengeForm> createState() => _ChallengeFormState();
}

class _ChallengeFormState extends State<_ChallengeForm> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final List<AdminChallengeField> _challengeFields = [];

  late final TextEditingController _nameCtrl, _descCtrl;

  bool get _isEditing => widget.challenge != null;

  @override
  void initState() {
    super.initState();
    final c = widget.challenge;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _descCtrl = TextEditingController(text: c?.description ?? '');

    if (c != null) {
      _challengeFields.add(AdminChallengeField.fromChallenge(c));
    }
    if (_challengeFields.isEmpty) {
      _challengeFields.add(AdminChallengeField(type: 'math'));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final fc = _challengeFields.first;
    final isMindTimer = fc.type == 'mind_timer';
    final isPairHunt = fc.type == 'pair_hunt';
    final isTicTacToe = fc.type == 'tic_tac_toe';

    Navigator.pop(context, {
      'id': _isEditing ? widget.challenge!.id : fc.id,
      'name': fc.name.isNotEmpty ? fc.name : _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'operation': isMindTimer
          ? 'mind_timer'
          : isPairHunt
              ? 'pair_hunt'
              : isTicTacToe
                  ? 'tic_tac_toe'
                  : '+',
      'challengeType': fc.type,
      'questionCount': isPairHunt
          ? 0
          : isTicTacToe
              ? 3
              : fc.qCount,
      if (isMindTimer) ...{
        'targetSeconds': fc.targetSeconds,
        'rangeSeconds': fc.rangeSeconds,
        'maxPoints': fc.maxPoints,
      } else if (isPairHunt) ...{
        'blockCount': fc.blockCount,
        'timeLimitSeconds': fc.timeLimitSeconds,
        'pointsPerPair': fc.pointsPerPair,
        'maxTimeBonus': fc.maxTimeBonus,
        'penaltyPerMismatch': fc.penaltyPerMismatch,
      } else if (isTicTacToe) ...{
        'timeLimitSeconds': fc.timeLimitSeconds,
        'maxPoints': fc.maxPoints,
      } else ...{
        'minNumber': fc.min,
        'maxNumber': fc.max,
        'timePerQuestionSeconds': fc.time,
      },
      'entryCoins': fc.entryCoins,
      'is_active': true,
    });
  }

  Future<void> _showTypePicker() async {
    final type = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Challenge Type'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'math'),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calculate, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Math',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Addition, subtraction, etc.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'mind_timer'),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.timer, color: Colors.indigo),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mind Timer',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Stop the hidden timer at the right moment',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'pair_hunt'),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.grid_view, color: Colors.purple),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pair Hunt',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Memory card matching game',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'tic_tac_toe'),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.grid_3x3, color: Colors.teal),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tic-Tac-Toe',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('3 rounds vs AI (Easy → Medium → Hard)',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (type != null) {
      setState(() {
        _challengeFields.clear();
        _challengeFields.add(AdminChallengeField(type: type));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fc = _challengeFields.first;
    final isMindTimer = fc.type == 'mind_timer';
    final isPairHunt = fc.type == 'pair_hunt';
    final isTicTacToe = fc.type == 'tic_tac_toe';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Challenge' : 'New Challenge'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Cancel',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _onSave,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            AdminNumericField(
              label: 'Entry Coins (0 = free)',
              icon: Icons.monetization_on_outlined,
              value: fc.entryCoins,
              step: 1,
              min: 0,
              max: 10000,
              onChanged: (v) => setState(() => fc.entryCoins = v),
            ),

            const SizedBox(height: 24),

            Text(
              'Challenge Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _showTypePicker,
              icon: Icon(
                isTicTacToe
                    ? Icons.grid_3x3
                    : isPairHunt
                        ? Icons.grid_view
                        : isMindTimer
                            ? Icons.timer
                            : Icons.calculate,
                color: isTicTacToe
                    ? Colors.teal
                    : isPairHunt
                        ? Colors.purple
                        : isMindTimer
                            ? Colors.indigo
                            : Colors.orange,
              ),
              label: Text(
                isTicTacToe
                    ? 'Tic‑Tac‑Toe'
                    : isPairHunt
                        ? 'Pair Hunt'
                        : isMindTimer
                            ? 'Mind Timer'
                            : 'Math',
                style: TextStyle(
                  color: isTicTacToe
                      ? Colors.teal
                      : isPairHunt
                          ? Colors.purple
                          : isMindTimer
                              ? Colors.indigo
                              : Colors.orange,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                side: BorderSide(
                  color: isTicTacToe
                      ? Colors.teal.withAlpha(80)
                      : isPairHunt
                          ? Colors.purple.withAlpha(80)
                          : isMindTimer
                              ? Colors.indigo.withAlpha(80)
                              : Colors.orange.withAlpha(80),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Type-specific fields
            if (isTicTacToe) ...[
              Row(
                children: [
                  Expanded(
                    child: AdminNumericField(
                      label: 'Time / Round (s)',
                      icon: Icons.timer,
                      value: fc.timeLimitSeconds,
                      step: 5,
                      min: 5,
                      max: 300,
                      compact: true,
                      onChanged: (v) =>
                          setState(() => fc.timeLimitSeconds = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AdminNumericField(
                      label: 'Max Points',
                      value: fc.maxPoints,
                      step: 100,
                      min: 100,
                      max: 10000,
                      compact: true,
                      onChanged: (v) =>
                          setState(() => fc.maxPoints = v),
                    ),
                  ),
                ],
              ),
            ] else if (isPairHunt) ...[
              Row(
                children: [
                  Expanded(
                    child: AdminNumericField(
                      label: 'Blocks (even)',
                      icon: Icons.grid_on,
                      value: fc.blockCount,
                      step: 4,
                      min: 4,
                      max: 20,
                      compact: true,
                      onChanged: (v) {
                        final rounded = ((v + 2) ~/ 4) * 4;
                        setState(() =>
                            fc.blockCount = rounded.clamp(4, 20));
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AdminNumericField(
                      label: 'Time Limit (s)',
                      value: fc.timeLimitSeconds,
                      step: 15,
                      min: 15,
                      max: 600,
                      compact: true,
                      onChanged: (v) =>
                          setState(() => fc.timeLimitSeconds = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AdminNumericField(
                      label: 'Pts per Pair',
                      value: fc.pointsPerPair,
                      step: 50,
                      min: 10,
                      max: 1000,
                      compact: true,
                      onChanged: (v) =>
                          setState(() => fc.pointsPerPair = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AdminNumericField(
                      label: 'Max Bonus',
                      value: fc.maxTimeBonus,
                      step: 100,
                      min: 0,
                      max: 5000,
                      compact: true,
                      onChanged: (v) =>
                          setState(() => fc.maxTimeBonus = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AdminNumericField(
                label: 'Penalty / Mismatch',
                icon: Icons.warning_amber,
                value: fc.penaltyPerMismatch,
                step: 5,
                min: 0,
                max: 500,
                compact: true,
                onChanged: (v) =>
                    setState(() => fc.penaltyPerMismatch = v),
              ),
            ] else if (isMindTimer) ...[
              Row(
                children: [
                  Expanded(
                    child: AdminNumericDoubleField(
                      label: 'Target (s)',
                      value: fc.targetSeconds,
                      step: 1.0,
                      min: 1.0,
                      max: 120.0,
                      compact: true,
                      decimals: 1,
                      onChanged: (v) =>
                          setState(() => fc.targetSeconds = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AdminNumericDoubleField(
                      label: 'Range (±s)',
                      value: fc.rangeSeconds,
                      step: 0.5,
                      min: 0.5,
                      max: 60.0,
                      compact: true,
                      decimals: 1,
                      onChanged: (v) =>
                          setState(() => fc.rangeSeconds = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AdminNumericField(
                      label: 'Max Points',
                      value: fc.maxPoints,
                      step: 100,
                      min: 100,
                      max: 10000,
                      compact: true,
                      onChanged: (v) =>
                          setState(() => fc.maxPoints = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AdminNumericField(
                      label: 'Questions',
                      value: fc.qCount,
                      step: 1,
                      min: 1,
                      max: 100,
                      compact: true,
                      onChanged: (v) =>
                          setState(() => fc.qCount = v),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: AdminNumericField(
                      label: 'Min Number',
                      value: fc.min,
                      step: 10,
                      min: 1,
                      max: 999,
                      compact: true,
                      onChanged: (v) =>
                          setState(() => fc.min = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AdminNumericField(
                      label: 'Max Number',
                      value: fc.max,
                      step: 10,
                      min: 1,
                      max: 9999,
                      compact: true,
                      onChanged: (v) =>
                          setState(() => fc.max = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AdminNumericField(
                      label: 'Time / Q (s)',
                      value: fc.time,
                      step: 1,
                      min: 1,
                      max: 300,
                      compact: true,
                      onChanged: (v) =>
                          setState(() => fc.time = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AdminNumericField(
                      label: 'Questions',
                      value: fc.qCount,
                      step: 1,
                      min: 1,
                      max: 100,
                      compact: true,
                      onChanged: (v) =>
                          setState(() => fc.qCount = v),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
