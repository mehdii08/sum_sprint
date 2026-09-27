import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminDeleteChallengeTitle),
        content: Text(l10n.adminDeleteChallengeMsg),
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

  String _typeLabel(ChallengeType t, AppLocalizations l10n) {
    return switch (t) {
      ChallengeType.math => l10n.adminTypeMath,
      ChallengeType.mindTimer => l10n.adminTypeMindTimer,
      ChallengeType.pairHunt => l10n.adminTypePairHunt,
      ChallengeType.ticTacToe => l10n.adminTypeTicTacToe,
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminManageChallenges),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.adminCreate,
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
                          child: Text(l10n.adminRetry)),
                    ],
                  ),
                )
              : _challenges.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calculate_outlined,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(l10n.adminNoChallenges,
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(l10n.adminTapToCreate,
                              style: const TextStyle(
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
                                  '${_typeLabel(type, l10n)}  •  ${c.isFree ? l10n.free : l10n.coinsAmount(c.entryCoins)}'),
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
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                      value: 'edit',
                                      child: Text(l10n.adminEdit)),
                                  PopupMenuItem(
                                      value: 'delete',
                                      child: Text(l10n.adminDelete,
                                          style: const TextStyle(
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

  late final TextEditingController _nameCtrl, _descCtrl, _entryCoinsCtrl;

  bool get _isEditing => widget.challenge != null;

  @override
  void initState() {
    super.initState();
    final c = widget.challenge;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _descCtrl = TextEditingController(text: c?.description ?? '');
    _entryCoinsCtrl =
        TextEditingController(text: '${c?.entryCoins ?? 0}');

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
    _entryCoinsCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final fc = _challengeFields.first;
    fc.entryCoins = int.tryParse(_entryCoinsCtrl.text.trim()) ?? 0;
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
    final l10n = AppLocalizations.of(context);
    final type = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.adminSelectType),
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
                    Text(l10n.adminTypeMath,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(l10n.adminTypeMathDesc,
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
                    Text(l10n.adminTypeMindTimer,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(l10n.adminTypeMindTimerDesc,
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
                    Text(l10n.adminTypePairHunt,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(l10n.adminTypePairHuntDesc,
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
                    Text(l10n.adminTypeTicTacToe,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(l10n.adminTypeTicTacToeDesc,
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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.adminEditChallenge : l10n.adminNewChallenge),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
          tooltip: l10n.adminCancel,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _onSave,
            tooltip: l10n.adminSave,
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
              decoration: InputDecoration(
                labelText: l10n.adminNameLabel,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.adminNameIsRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: InputDecoration(
                labelText: l10n.adminDescriptionLabel,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _entryCoinsCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.adminEntryCoinsFree,
                prefixIcon: const Icon(Icons.monetization_on_outlined),
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l10n.adminNameRequired;
                }
                final n = int.tryParse(v.trim());
                if (n == null || n < 0) return l10n.adminNameRequired;
                return null;
              },
            ),

            const SizedBox(height: 24),

            Text(
              l10n.adminChallengeType,
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
                    ? l10n.adminTypeTicTacToe
                    : isPairHunt
                        ? l10n.adminTypePairHunt
                        : isMindTimer
                            ? l10n.adminTypeMindTimer
                            : l10n.adminTypeMath,
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
                      label: l10n.adminTimePerRound,
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
                      label: l10n.adminMaxPoints,
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
                      label: l10n.adminBlocksEven,
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
                      label: l10n.adminTimeLimitS,
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
                      label: l10n.adminPointsPerPair,
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
                      label: l10n.adminMaxTimeBonus,
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
                label: l10n.adminPenaltyPerMismatch,
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
                      label: l10n.adminTargetS,
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
                      label: l10n.adminRangeS,
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
                      label: l10n.adminMaxPoints,
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
                      label: l10n.adminQuestions,
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
                      label: l10n.adminMinNumber,
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
                      label: l10n.adminMaxNumber,
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
                      label: l10n.adminTimePerQuestion,
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
                      label: l10n.adminQuestions,
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
