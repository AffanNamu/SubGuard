import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/score_keypad.dart';
import '../../data/repositories/score_repository.dart';
import '../../domain/flags.dart';
import '../../domain/scheme.dart';
import '../../domain/scoring.dart';
import '../../providers/providers.dart';

/// Opens the number pad for one cell of the grid. [studentIds] is the list the
/// user is working down, so "Save and next" moves to the same part for the
/// next student.
Future<void> showScoreEntry(
  BuildContext context, {
  required String courseId,
  required List<String> studentIds,
  required int startIndex,
  required String partId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ScoreEntrySheet(
      courseId: courseId,
      studentIds: studentIds,
      startIndex: startIndex,
      partId: partId,
    ),
  );
}

class ScoreEntrySheet extends ConsumerStatefulWidget {
  const ScoreEntrySheet({
    super.key,
    required this.courseId,
    required this.studentIds,
    required this.startIndex,
    required this.partId,
  });

  final String courseId;
  final List<String> studentIds;
  final int startIndex;
  final String partId;

  @override
  ConsumerState<ScoreEntrySheet> createState() => _ScoreEntrySheetState();
}

class _ScoreEntrySheetState extends ConsumerState<ScoreEntrySheet> {
  late int _index = widget.startIndex;
  String _text = '';
  bool _fresh = true; // the next key replaces what is shown
  bool _loaded = false;
  Future<void> Function()? _undo;

  GridRow? _row(GridData data) {
    final id = widget.studentIds[_index];
    for (final r in data.rows) {
      if (r.student.id == id) return r;
    }
    return null;
  }

  void _loadText(GridRow row) {
    final v = row.values[widget.partId];
    _text = v != null && v.hasValue ? formatNumber(v.value!) : '';
    _fresh = true;
  }

  void _key(String k) {
    setState(() {
      if (_fresh) {
        _text = '';
        _fresh = false;
      }
      if (_text.length >= 7) return;
      if (k == '.') {
        if (_text.contains('.')) return;
        _text = _text.isEmpty ? '0.' : '$_text.';
      } else if (k == '.5') {
        if (_text.contains('.')) return;
        _text = _text.isEmpty ? '0.5' : '$_text.5';
      } else {
        _text = _text == '0' ? k : '$_text$k';
      }
    });
  }

  void _backspace() {
    setState(() {
      _fresh = false;
      if (_text.isNotEmpty) _text = _text.substring(0, _text.length - 1);
    });
  }

  Future<void> _write(GridRow row, PartSpec part, ScoreWrite write) async {
    final repo = ref.read(scoreRepositoryProvider);
    final previous = row.values[part.id];
    await repo.set(widget.courseId, write);
    _undo = () => repo.set(
          widget.courseId,
          ScoreWrite(
            studentId: row.student.id,
            partId: part.id,
            value: previous?.value,
            status: previous?.status ?? ScoreStatus.missing,
          ),
        );
  }

  /// Saves what is typed. Returns false when the text is not a number.
  Future<bool> _save(GridRow row, PartSpec part) async {
    if (_text.trim().isEmpty) {
      await _write(row, part,
          ScoreWrite(studentId: row.student.id, partId: part.id, status: ScoreStatus.missing));
      return true;
    }
    final v = MarkParser.parse(_text);
    if (v == null) return false;
    await _write(row, part, ScoreWrite(studentId: row.student.id, partId: part.id, value: v));
    return true;
  }

  Future<void> _saveAndNext(GridData data, GridRow row, PartSpec part) async {
    if (!await _save(row, part)) return;
    if (!mounted) return;
    if (_index + 1 >= widget.studentIds.length) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _index++;
      _loaded = false;
    });
  }

  Future<void> _absent(GridRow row, PartSpec part) async {
    await _write(row, part,
        ScoreWrite(studentId: row.student.id, partId: part.id, status: ScoreStatus.absent));
    if (!mounted) return;
    if (_index + 1 >= widget.studentIds.length) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _index++;
      _loaded = false;
    });
  }

  void _move(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= widget.studentIds.length) return;
    setState(() {
      _index = next;
      _loaded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final grid = ref.watch(gridProvider(widget.courseId)).valueOrNull;
    if (grid == null) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    final row = _row(grid);
    final part = grid.scheme.partById(widget.partId);
    if (row == null || part == null) {
      return const SizedBox(height: 200, child: Center(child: Text('This student is no longer in the list.')));
    }
    if (!_loaded) {
      _loadText(row);
      _loaded = true;
    }

    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final c = context.colors;

    final typed = MarkParser.parse(_text);
    final invalid = _text.isNotEmpty && typed == null;
    final cellFlags = typed == null ? const <ScoreFlag>[] : FlagChecker.cellFlags(part, typed);
    final problem = cellFlags.where((f) => f.needsAttention).toList();
    final hasNext = _index + 1 < widget.studentIds.length;
    final fractional = part.step < 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ContentWidth(
        maxWidth: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous student',
                  onPressed: _index > 0 ? () => _move(-1) : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                  iconSize: 32,
                  constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(row.student.regNo, style: text.titleMedium, textAlign: TextAlign.center),
                      if ((row.student.name ?? '').isNotEmpty)
                        Text(row.student.name!,
                            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                            textAlign: TextAlign.center),
                      Text('${_index + 1} of ${widget.studentIds.length}',
                          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Next student',
                  onPressed: hasNext ? () => _move(1) : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                  iconSize: 32,
                  constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: invalid || problem.isNotEmpty ? c.danger : scheme.primary,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(part.name, style: text.titleMedium),
                        Text(
                          'Out of ${formatNumber(part.max)} · step ${formatNumber(part.step)}',
                          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    liveRegion: true,
                    label: _text.isEmpty ? 'No mark entered' : 'Mark $_text',
                    child: Text(
                      _text.isEmpty ? '—' : _text,
                      style: text.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _text.isEmpty ? scheme.outline : scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // A minimum, not a fixed height: a long message wraps to two lines.
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: invalid
                  ? const InfoBanner(message: 'That is not a number.', kind: BannerKind.danger)
                  : problem.isNotEmpty
                      ? InfoBanner(message: problem.first.message, kind: BannerKind.danger)
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _summaryLine(row, part),
                            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
            ),
            ScoreKeypad(
              onKey: _key,
              onBackspace: _backspace,
              showHalfKey: fractional,
              showDecimalKey: fractional,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _absent(row, part),
                    child: const Text('Absent'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _text = '';
                      _fresh = false;
                    }),
                    child: const Text('Clear'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (_undo != null) ...[
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        await _undo!();
                        setState(() {
                          _undo = null;
                          _loaded = false;
                        });
                      },
                      icon: const Icon(Icons.undo_rounded),
                      label: const Text('Undo'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: invalid
                        ? null
                        : () async {
                            if (hasNext) {
                              await _saveAndNext(grid, row, part);
                            } else if (await _save(row, part) && context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                    child: Text(hasNext ? 'Save and next' : 'Save'),
                  ),
                ),
              ],
            ),
            if (hasNext)
              TextButton(
                onPressed: invalid
                    ? null
                    : () async {
                        if (await _save(row, part) && context.mounted) Navigator.pop(context);
                      },
                child: const Text('Save and close'),
              ),
          ],
        ),
      ),
    );
  }

  /// "Total so far 42 of 100" under the display.
  String _summaryLine(GridRow row, PartSpec part) {
    final total = row.result.total;
    final grid = ref.read(gridProvider(widget.courseId)).valueOrNull;
    final of = grid == null ? '' : ' of ${formatNumber(grid.scheme.totalExpected)}';
    if (total == null) return 'No marks entered for this student yet';
    return 'Total so far ${ScoreCalculator.formatTotal(total)}$of'
        '${row.result.grade != null ? ' · Grade ${row.result.grade!.letter}' : ''}';
  }
}
