import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/score_keypad.dart';
import '../../data/repositories/score_repository.dart';
import '../../data/repositories/student_repository.dart';
import '../../domain/flags.dart';
import '../../domain/models.dart';
import '../../domain/reg_no.dart';
import '../../domain/scheme.dart';
import '../../domain/scoring.dart';
import '../../providers/providers.dart';

Future<void> showQuickEntry(BuildContext context, String courseId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => QuickEntrySheet(courseId: courseId),
    );

/// Type a registration number, then its mark. The number is repaired to the
/// standard form, checked against DEPT/YYU/NNNN and against the class list,
/// and close matches are offered when it is not found. Meant for working down
/// a pile of sheets without scrolling the grid.
class QuickEntrySheet extends ConsumerStatefulWidget {
  const QuickEntrySheet({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<QuickEntrySheet> createState() => _QuickEntrySheetState();
}

class _QuickEntrySheetState extends ConsumerState<QuickEntrySheet> {
  final _reg = TextEditingController();
  final _focus = FocusNode();
  String? _partId;
  Student? _picked; // a suggestion the user chose
  bool _addAsExtra = false;
  String _value = '';
  bool _fresh = true;
  String? _lastSaved;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _reg.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _key(String k) => setState(() {
        if (_fresh) {
          _value = '';
          _fresh = false;
        }
        if (_value.length >= 7) return;
        if (k == '.' || k == '.5') {
          if (_value.contains('.')) return;
          _value = _value.isEmpty ? '0$k' : '$_value$k';
        } else {
          _value = _value == '0' ? k : '$_value$k';
        }
      });

  void _backspace() => setState(() {
        _fresh = false;
        if (_value.isNotEmpty) _value = _value.substring(0, _value.length - 1);
      });

  Future<void> _save(GridData data, PartSpec part, Student? match) async {
    final v = MarkParser.parse(_value);
    if (v == null) return;

    var student = match;
    if (student == null) {
      // Not on the class list: add as an extra student, flagged.
      final repo = ref.read(studentRepositoryProvider);
      await repo.addMany(widget.courseId, [NewStudent(_reg.text)], onClassList: false);
      final key = RegNo.key(_reg.text);
      student = (await repo.getAll(widget.courseId))
          .where((s) => RegNo.key(s.regNo) == key)
          .firstOrNull;
      if (student == null) return;
    }

    await ref.read(scoreRepositoryProvider).set(
          widget.courseId,
          ScoreWrite(studentId: student.id, partId: part.id, value: v),
        );

    if (!mounted) return;
    setState(() {
      _lastSaved = '${part.name} ${formatNumber(v)} saved for ${student!.regNo}';
      _reg.clear();
      _value = '';
      _fresh = true;
      _picked = null;
      _addAsExtra = false;
    });
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final grid = ref.watch(gridProvider(widget.courseId)).valueOrNull;
    if (grid == null) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));

    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final c = context.colors;
    final parts = grid.scheme.parts;
    final part = parts.firstWhere((p) => p.id == _partId, orElse: () => parts.first);

    final result = RegNo.normalise(_reg.text);
    final byKey = {for (final r in grid.rows) RegNo.key(r.student.regNo): r.student};
    final exact = byKey[result.canonical];
    final match = _picked ?? exact;
    final suggestions = (exact == null && result.canonical.length >= 6)
        ? RegNo.nearest(result.canonical, byKey.keys)
        : const <RegNoSuggestion>[];

    final typed = MarkParser.parse(_value);
    final markFlags = typed == null ? const <ScoreFlag>[] : FlagChecker.cellFlags(part, typed);
    final markProblem = markFlags.where((f) => f.needsAttention).toList();
    final existing = match == null ? null : grid.rows.firstWhere((r) => r.student.id == match.id).values[part.id];

    final ready = result.canonical.isNotEmpty && (match != null || _addAsExtra);
    final showKeypad = ready && !_focus.hasFocus;
    final canSave = ready && typed != null;

    Widget identity() {
      if (result.canonical.isEmpty) {
        return Text('Type the registration number from the sheet.',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant));
      }
      if (match != null) {
        return InfoBanner(
          message: '${match.regNo}${(match.name ?? '').isEmpty ? '' : ' · ${match.name}'}'
              '${result.wasCorrected && _picked == null ? '\n${result.corrections.join('. ')}.' : ''}'
              '${existing?.hasValue == true ? '\nAlready has ${part.name} ${formatNumber(existing!.value!)}. Saving replaces it.' : ''}',
          kind: existing?.hasValue == true ? BannerKind.warning : BannerKind.success,
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoBanner(
            message: result.isValid
                ? '${result.canonical} is not on the class list.'
                : '${result.canonical} does not look like DEPT/YYU/NNNN and is not on the class list.',
            kind: BannerKind.warning,
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Did you mean', style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            for (final s in suggestions)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _picked = byKey[s.regNo];
                    _focus.unfocus();
                  }),
                  child: Text(s.regNo),
                ),
              ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Add as an extra student'),
            subtitle: const Text('Flagged as not on the class list.'),
            value: _addAsExtra,
            onChanged: (v) => setState(() {
              _addAsExtra = v;
              if (v) _focus.unfocus();
            }),
          ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ContentWidth(
          maxWidth: 480,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Enter by number', style: text.titleLarge),
              const SizedBox(height: 12),
              if (parts.length > 1)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in parts)
                      ChoiceChip(
                        label: Text(p.name),
                        selected: p.id == part.id,
                        onSelected: (_) => setState(() {
                          _partId = p.id;
                          _fresh = true;
                        }),
                      ),
                  ],
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _reg,
                focusNode: _focus,
                autofocus: true,
                autocorrect: false,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {
                  _picked = null;
                  _addAsExtra = false;
                }),
                onSubmitted: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Registration number',
                  hintText: 'FWM/24U/0538',
                ),
              ),
              const SizedBox(height: 10),
              identity(),
              if (showKeypad) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: markProblem.isNotEmpty ? c.danger : scheme.primary, width: 2),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${part.name} · out of ${formatNumber(part.max)}', style: text.titleMedium),
                      ),
                      Text(_value.isEmpty ? '—' : _value,
                          style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                if (markProblem.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  InfoBanner(message: markProblem.first.message, kind: BannerKind.danger),
                ],
                const SizedBox(height: 8),
                ScoreKeypad(
                  onKey: _key,
                  onBackspace: _backspace,
                  showHalfKey: part.step < 1,
                  showDecimalKey: part.step < 1,
                ),
              ] else if (ready) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => setState(_focus.unfocus),
                  child: const Text('Enter the mark'),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: canSave ? () => _save(grid, part, match) : null,
                child: const Text('Save and enter the next'),
              ),
              if (_lastSaved != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: c.success, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_lastSaved!, style: text.bodyMedium)),
                    ],
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
