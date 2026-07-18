// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/competition.dart';
import '../../models/challenge_definition.dart';
import '../../l10n/app_localizations.dart';

/// Admin competitions management — list, create, update, delete.
class AdminCompetitionsScreen extends StatefulWidget {
  const AdminCompetitionsScreen({super.key});

  @override
  State<AdminCompetitionsScreen> createState() => _AdminCompetitionsScreenState();
}

class _AdminCompetitionsScreenState extends State<AdminCompetitionsScreen> {
  final _client = Supabase.instance.client;
  List<Competition> _competitions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _client.from('competitions').select().order('start_date', ascending: false);
      _competitions = (res as List)
          .map((e) => Competition.fromJson(e as Map<String, dynamic>))
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
        title: Text(l10n.adminDeleteCompetitionTitle),
        content: Text(l10n.adminDeleteCompetitionMsg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.adminCancel)),
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
      await _client.from('competitions').delete().eq('id', id);
      _load();
    } catch (e) {
      if (mounted) _showError('$e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminManageCompetitions),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.adminCreate,
            onPressed: () async {
              final created = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(
                  builder: (_) => const _CompetitionForm(competition: null),
                ),
              );
              if (created != null) {
                try {
                  await _client.from('competitions').insert(created);
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
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: Text(l10n.adminRetry)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _competitions.length,
                    itemBuilder: (_, i) {
                      final c = _competitions[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${c.status.value}  •  ${c.timeRemaining}'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) async {
                              if (action == 'edit') {
                                final updated = await Navigator.push<Map<String, dynamic>>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => _CompetitionForm(competition: c),
                                  ),
                                );
                                if (updated != null) {
                                  try {
                                    await _client.from('competitions').update(updated).eq('id', c.id);
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
                              PopupMenuItem(value: 'edit', child: ListTile(leading: const Icon(Icons.edit), title: Text(l10n.adminEdit))),
                              PopupMenuItem(value: 'delete', child: ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: Text(l10n.adminDelete, style: const TextStyle(color: Colors.red)))),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// ── Create / Edit form ──────────────────────────────────────────

class _CompetitionForm extends StatefulWidget {
  final Competition? competition;
  const _CompetitionForm({required this.competition});

  @override
  State<_CompetitionForm> createState() => _CompetitionFormState();
}

class _CompetitionFormState extends State<_CompetitionForm> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  late final TextEditingController _name, _desc;
  late String _status;
  late DateTime _start, _end;

  // Numeric fields — changed by +/- buttons, no keyboard needed
  late int _entryCoins;   // default 100, step 100
  late int _prizePool;    // default 100, step 100
  late int _winnerCount;  // default 1, step 1
  late List<int> _shares; // one per winner, default 10, step 10

  // Challenge fields
  final List<_ChallengeField> _challenges = [];

  @override
  void initState() {
    super.initState();
    final c = widget.competition;
    _name = TextEditingController(text: c?.name ?? '');
    _desc = TextEditingController(text: c?.description ?? '');
    _entryCoins = c?.entryPoints ?? 100;
    _prizePool = c?.prizePool ?? 100;
    _winnerCount = c?.winnerCount ?? 1;
    _shares = c != null
        ? c.winnerShares.map((e) => e.round()).toList()
        : [100];
    _status = c?.status.value ?? 'active';
    _start = c?.startDate ?? DateTime.now();
    _end = c?.endDate ?? DateTime.now().add(const Duration(minutes: 15));

    // Ensure shares list matches winner count
    _syncSharesLength();

    if (c != null) {
      for (final ch in c.challenges) {
        _challenges.add(_ChallengeField.fromChallenge(ch));
      }
    }
    if (_challenges.isEmpty) {
      _challenges.add(_ChallengeField());
    }
  }

  void _syncSharesLength() {
    while (_shares.length < _winnerCount) {
      _shares.add(100);
    }
    if (_shares.length > _winnerCount) {
      _shares = _shares.sublist(0, _winnerCount);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final initialDate = isStart ? _start : _end;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null || !mounted) return;

    final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) { _start = combined; } else { _end = combined; }
    });
  }

  String _fmtDateTime(DateTime dt) {
    final d = dt.toLocal();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${pad(d.month)}-${pad(d.day)} ${pad(d.hour)}:${pad(d.minute)}';
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    final challenges = _challenges.map((fc) {
      final isMindTimer = fc.type == 'mind_timer';
      final isPairHunt = fc.type == 'pair_hunt';
      final isTicTacToe = fc.type == 'tic_tac_toe';
      return {
        'id': fc.id,
        'name': fc.name,
        'description': fc.name,
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
      };
    }).toList();
    Navigator.pop(context, {
      'name': _name.text.trim(),
      'description': _desc.text.trim(),
      'start_date': _start.toUtc().toIso8601String(),
      'end_date': _end.toUtc().toIso8601String(),
      'challenges': challenges,
      'entry_points': _entryCoins,
      'prize_pool': _prizePool,
      'winner_count': _winnerCount,
      'winner_shares': _shares,
      'status': _status,
    });
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.competition != null;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? l10n.adminEditCompetition : l10n.adminNewCompetition),
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
            // ── Name & Description (keyboard kept) ────────────────
            TextFormField(
              controller: _name,
              decoration: InputDecoration(
                labelText: l10n.adminNameLabel,
                border: const OutlineInputBorder(),
              ),
              validator: (v) => v!.trim().isEmpty ? l10n.adminNameRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              decoration: InputDecoration(
                labelText: l10n.adminDescriptionLabel,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 20),

            // ── Entry Coins ───────────────────────────────────────
            _NumericField(
              label: l10n.adminEntryCoins,
              icon: Icons.monetization_on,
              value: _entryCoins,
              step: 100,
              onChanged: (v) => setState(() => _entryCoins = v),
            ),
            const SizedBox(height: 12),

            // ── Prize Pool ────────────────────────────────────────
            _NumericField(
              label: l10n.adminPrizePool,
              icon: Icons.emoji_events,
              value: _prizePool,
              step: 100,
              onChanged: (v) => setState(() => _prizePool = v),
            ),
            const SizedBox(height: 12),

            // ── Winners ───────────────────────────────────────────
            _NumericField(
              label: l10n.adminWinners,
              icon: Icons.workspace_premium,
              value: _winnerCount,
              step: 1,
              min: 1,
              max: 20,
              onChanged: (v) {
                setState(() {
                  _winnerCount = v;
                  _syncSharesLength();
                });
              },
            ),
            const SizedBox(height: 12),

            // ── Dynamic Winner Shares ─────────────────────────────
            if (_shares.isNotEmpty) ...[
              Text(
                l10n.adminWinnerShares,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(_shares.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _NumericField(
                    label: '  #${i + 1} share (%)',
                    icon: Icons.pie_chart,
                    value: _shares[i],
                    step: 10,
                    min: 0,
                    max: 100,
                    onChanged: (v) => setState(() => _shares[i] = v),
                  ),
                );
              }),
            ],

            const SizedBox(height: 12),

            // ── Status ────────────────────────────────────────────
            DropdownButtonFormField<String>(
              value: _status,
              decoration: InputDecoration(
                labelText: l10n.adminStatus,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'upcoming', child: Text(l10n.adminUpcoming)),
                DropdownMenuItem(value: 'active', child: Text(l10n.adminActive)),
                DropdownMenuItem(value: 'finished', child: Text(l10n.adminFinished)),
              ],
              onChanged: (v) { if (v != null) setState(() => _status = v); },
            ),

            const SizedBox(height: 16),

            // ── Start / End DateTime ──────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDateTime(true),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text('Start: ${_fmtDateTime(_start)}',
                        style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDateTime(false),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text('End: ${_fmtDateTime(_end)}',
                        style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Challenge editor ──────────────────────────────────
            Row(
              children: [
                Text(
                  l10n.adminChallenges,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addChallengeWithTypePicker(),
                  tooltip: l10n.adminAddChallenge,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ..._challenges.asMap().entries.map((e) {
              final i = e.key;
              final fc = e.value;
              final isMindTimer = fc.type == 'mind_timer';
              final isPairHunt = fc.type == 'pair_hunt';
              final isTicTacToe = fc.type == 'tic_tac_toe';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isTicTacToe
                                  ? Colors.teal.withAlpha(25)
                                  : isPairHunt
                                      ? Colors.purple.withAlpha(25)
                                      : isMindTimer
                                          ? Colors.indigo.withAlpha(25)
                                          : Colors.orange.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isTicTacToe
                                  ? l10n.adminTypeTicTacToe
                                  : isPairHunt
                                      ? l10n.adminTypePairHunt
                                      : isMindTimer
                                          ? l10n.adminTypeMindTimer
                                          : l10n.adminTypeMath,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isTicTacToe
                                    ? Colors.teal
                                    : isPairHunt
                                        ? Colors.purple
                                        : isMindTimer
                                            ? Colors.indigo
                                            : Colors.orange,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (_challenges.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red, size: 20),
                              onPressed: () =>
                                  setState(() => _challenges.removeAt(i)),
                              tooltip: l10n.adminRemoveChallenge,
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Auto-generated unique ID — read-only
                      Row(
                        children: [
                          const Icon(Icons.tag, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              fc.id,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: fc.name,
                        decoration: InputDecoration(
                          labelText: l10n.adminChallengeName,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) => fc.name = v,
                      ),
                      const SizedBox(height: 10),
                      // Type-specific fields
                      if (isTicTacToe) ...[
                        // Time per round & Max Points
                        Row(
                          children: [
                            Expanded(
                              child: _NumericField(
                                label: l10n.adminTimePerRound,
                                icon: Icons.timer,
                                value: fc.timeLimitSeconds,
                                step: 5,
                                min: 5,
                                max: 300,
                                compact: true,
                                onChanged: (v) => setState(() => fc.timeLimitSeconds = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _NumericField(
                                label: l10n.adminMaxPoints,
                                value: fc.maxPoints,
                                step: 100,
                                min: 100,
                                max: 10000,
                                compact: true,
                                onChanged: (v) => setState(() => fc.maxPoints = v),
                              ),
                            ),
                          ],
                        ),
                      ] else if (isPairHunt) ...[
                        // Block Count dropdown
                        Row(
                          children: [
                            Expanded(
                              child: _NumericField(
                                label: l10n.adminBlockCount,
                                icon: Icons.grid_on,
                                value: fc.blockCount,
                                step: 4,
                                min: 4,
                                max: 20,
                                compact: true,
                                onChanged: (v) {
                                  // Round to nearest even (4, 8, 12, 16, 20)
                                  final rounded = ((v + 2) ~/ 4) * 4;
                                  setState(() => fc.blockCount = rounded.clamp(4, 20));
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _NumericField(
                                label: l10n.adminTimeS,
                                value: fc.timeLimitSeconds,
                                step: 15,
                                min: 15,
                                max: 600,
                                compact: true,
                                onChanged: (v) => setState(() => fc.timeLimitSeconds = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Points Per Pair & Max Time Bonus
                        Row(
                          children: [
                            Expanded(
                              child: _NumericField(
                                label: l10n.adminPointsPerPair,
                                value: fc.pointsPerPair,
                                step: 50,
                                min: 10,
                                max: 1000,
                                compact: true,
                                onChanged: (v) => setState(() => fc.pointsPerPair = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _NumericField(
                                label: l10n.adminMaxTimeBonus,
                                value: fc.maxTimeBonus,
                                step: 100,
                                min: 0,
                                max: 5000,
                                compact: true,
                                onChanged: (v) => setState(() => fc.maxTimeBonus = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Penalty Per Mismatch
                        _NumericField(
                          label: l10n.adminPenaltyPerMismatch,
                          icon: Icons.warning_amber,
                          value: fc.penaltyPerMismatch,
                          step: 5,
                          min: 0,
                          max: 500,
                          compact: true,
                          onChanged: (v) => setState(() => fc.penaltyPerMismatch = v),
                        ),
                      ] else if (isMindTimer) ...[
                        // Target Seconds, Range Seconds, Max Points
                        Row(
                          children: [
                            Expanded(
                              child: _NumericDoubleField(
                                label: l10n.adminTargetS,
                                value: fc.targetSeconds,
                                step: 1.0,
                                min: 1.0,
                                max: 120.0,
                                compact: true,
                                decimals: 1,
                                onChanged: (v) => setState(() => fc.targetSeconds = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _NumericDoubleField(
                                label: l10n.adminRangeS,
                                value: fc.rangeSeconds,
                                step: 0.5,
                                min: 0.5,
                                max: 60.0,
                                compact: true,
                                decimals: 1,
                                onChanged: (v) => setState(() => fc.rangeSeconds = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _NumericField(
                                label: l10n.adminMaxPoints,
                                value: fc.maxPoints,
                                step: 100,
                                min: 100,
                                max: 10000,
                                compact: true,
                                onChanged: (v) => setState(() => fc.maxPoints = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _NumericField(
                                label: l10n.adminQuestions,
                                value: fc.qCount,
                                step: 1,
                                min: 1,
                                max: 100,
                                compact: true,
                                onChanged: (v) => setState(() => fc.qCount = v),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Math: Min & Max
                        Row(
                          children: [
                            Expanded(
                              child: _NumericField(
                                label: l10n.adminMin,
                                value: fc.min,
                                step: 10,
                                min: 1,
                                max: 999,
                                compact: true,
                                onChanged: (v) => setState(() => fc.min = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _NumericField(
                                label: l10n.adminMax,
                                value: fc.max,
                                step: 10,
                                min: 1,
                                max: 9999,
                                compact: true,
                                onChanged: (v) => setState(() => fc.max = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Time & Questions
                        Row(
                          children: [
                            Expanded(
                              child: _NumericField(
                                label: l10n.adminTimeS,
                                value: fc.time,
                                step: 1,
                                min: 1,
                                max: 300,
                                compact: true,
                                onChanged: (v) => setState(() => fc.time = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _NumericField(
                                label: l10n.adminQuestions,
                                value: fc.qCount,
                                step: 1,
                                min: 1,
                                max: 100,
                                compact: true,
                                onChanged: (v) => setState(() => fc.qCount = v),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 80), // bottom padding for comfortable scroll
          ],
        ),
      ),
    );
  }

  // ── Type picker dialog ──────────────────────────────────────────
  Future<void> _addChallengeWithTypePicker() async {
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
                    Text(l10n.adminTypeMath, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(l10n.adminTypeMathDesc,
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (type != null) {
      setState(() => _challenges.add(_ChallengeField(type: type)));
    }
  }
}

// ── Numeric +/- widget ───────────────────────────────────────────

class _NumericField extends StatelessWidget {
  final String label;
  final IconData? icon;
  final int value;
  final int step;
  final int min;
  final int max;
  final bool compact;
  final ValueChanged<int> onChanged;

  const _NumericField({
    required this.label,
    this.icon,
    required this.value,
    required this.step,
    this.min = 0,
    this.max = 999999,
    this.compact = false,
    required this.onChanged,
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
          // Minus button
          _StepButton(
            icon: Icons.remove,
            enabled: minusEnabled,
            compact: compact,
            onTap: minusEnabled
                ? () => onChanged((value - step).clamp(min, max))
                : null,
          ),
          SizedBox(width: compact ? 4 : 8),
          // Plus button
          _StepButton(
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

class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final bool compact;
  final VoidCallback? onTap;

  const _StepButton({
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

// ── Challenge field data ─────────────────────────────────────────

int _challengeIdCounter = 0;

class _ChallengeField {
  final String id;
  String name = '';
  String type; // 'math', 'mind_timer', 'pair_hunt', or 'tic_tac_toe'

  // Math fields
  int min = 1;
  int max = 10;
  int time = 5;

  // Mind Timer fields
  double targetSeconds = 5.0;
  double rangeSeconds = 2.0;
  int maxPoints = 1000;

  // Pair Hunt fields
  int blockCount = 12;
  int timeLimitSeconds = 60;
  int pointsPerPair = 100;
  int maxTimeBonus = 500;
  int penaltyPerMismatch = 25;

  // Tic Tac Toe reuses timeLimitSeconds (per round) + maxPoints (per round)

  // Common
  int qCount = 10;

  _ChallengeField({this.type = 'math'}) : id = _generateId() {
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

  _ChallengeField.fromChallenge(ChallengeDefinition ch)
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
        qCount = ch.questionCount;

  static String _generateId() {
    _challengeIdCounter++;
    final ts = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    return 'ch_${ts}_$_challengeIdCounter';
  }
}

// ── Double numeric +/- widget ─────────────────────────────────────

class _NumericDoubleField extends StatelessWidget {
  final String label;
  final double value;
  final double step;
  final double min;
  final double max;
  final bool compact;
  final int decimals;
  final ValueChanged<double> onChanged;

  const _NumericDoubleField({
    required this.label,
    required this.value,
    required this.step,
    this.min = 0.0,
    this.max = double.infinity,
    this.compact = false,
    this.decimals = 1,
    required this.onChanged,
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
          _StepButton(
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
          _StepButton(
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
