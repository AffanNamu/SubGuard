import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../domain/flags.dart';
import '../../domain/scheme.dart';
import '../../domain/scoring.dart';
import '../../providers/providers.dart';
import '../export/export_screen.dart';
import '../roster/import_screen.dart';
import '../roster/roster_screen.dart';
import 'quick_entry_sheet.dart';
import 'score_entry_sheet.dart';

enum GridFilter {
  all('All'),
  incomplete('Still to enter'),
  flagged('Need attention');

  const GridFilter(this.label);
  final String label;
}

/// Every student with their marks, total and grade. Tap a mark to type it;
/// the total and grade update as soon as it is saved.
class ScoreGridScreen extends ConsumerStatefulWidget {
  const ScoreGridScreen({super.key, required this.courseId, this.initialFilter = GridFilter.all});

  final String courseId;
  final GridFilter initialFilter;

  @override
  ConsumerState<ScoreGridScreen> createState() => _ScoreGridScreenState();
}

class _ScoreGridScreenState extends ConsumerState<ScoreGridScreen> {
  late GridFilter _filter = widget.initialFilter;
  String _query = '';
  bool _searching = false;

  List<GridRow> _visible(GridData data) {
    final q = _query.trim().toLowerCase();
    return data.rows.where((r) {
      final matchesFilter = switch (_filter) {
        GridFilter.all => true,
        GridFilter.incomplete => !r.result.complete,
        GridFilter.flagged => r.needsAttention,
      };
      if (!matchesFilter) return false;
      if (q.isEmpty) return true;
      return r.student.regNo.toLowerCase().contains(q) ||
          (r.student.name ?? '').toLowerCase().contains(q);
    }).toList();
  }

  void _edit(List<GridRow> rows, int index, PartSpec part) => showScoreEntry(
        context,
        courseId: widget.courseId,
        studentIds: [for (final r in rows) r.student.id],
        startIndex: index,
        partId: part.id,
      );

  @override
  Widget build(BuildContext context) {
    final grid = ref.watch(gridProvider(widget.courseId));

    return grid.when(
      loading: () => Scaffold(appBar: AppBar(title: const Text('Scores')), body: const Center(child: CircularProgressIndicator())),
      error: (_, __) => Scaffold(appBar: AppBar(title: const Text('Scores')), body: const ErrorState(message: 'The scores could not be loaded.')),
      data: (data) => _build(context, data),
    );
  }

  Widget _build(BuildContext context, GridData data) {
    final rows = _visible(data);
    final stats = data.stats;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Search by number or name',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              )
            : Text('Scores · ${data.course.code}'),
        actions: [
          IconButton(
            tooltip: _searching ? 'Close search' : 'Search',
            icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _query = '';
            }),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (v) {
              final nav = Navigator.of(context);
              switch (v) {
                case 'import':
                  nav.push(MaterialPageRoute(
                      builder: (_) => ImportScreen(courseId: widget.courseId, mode: ImportMode.scores)));
                case 'export':
                  nav.push(MaterialPageRoute(builder: (_) => ExportScreen(courseIds: [widget.courseId])));
                case 'class':
                  nav.push(MaterialPageRoute(builder: (_) => RosterScreen(courseId: widget.courseId)));
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'import', child: Text('Import marks from a file')),
              PopupMenuItem(value: 'export', child: Text('Export')),
              PopupMenuItem(value: 'class', child: Text('Class list')),
            ],
          ),
        ],
      ),
      floatingActionButton: stats.students == 0
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showQuickEntry(context, widget.courseId),
              icon: const Icon(Icons.keyboard_alt_rounded),
              label: const Text('Enter by number'),
            ),
      body: stats.students == 0
          ? EmptyState(
              icon: Icons.grid_on_rounded,
              title: 'No students yet',
              message: 'Add the class list first, then come back here to type in the scores.',
              actionLabel: 'Add the class list',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RosterScreen(courseId: widget.courseId)),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 48,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final f in GridFilter.values)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text('${f.label} (${_count(data, f)})'),
                                  selected: _filter == f,
                                  onSelected: (_) => setState(() => _filter = f),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: stats.progress,
                          minHeight: 8,
                          backgroundColor: scheme.outlineVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${stats.cellsEntered} of ${stats.cellsTotal} marks entered · ${stats.complete} of ${stats.students} students complete',
                        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: rows.isEmpty
                      ? EmptyState(
                          icon: _filter == GridFilter.flagged ? Icons.verified_rounded : Icons.search_off_rounded,
                          title: _filter == GridFilter.flagged ? 'Nothing needs attention' : 'No students here',
                          message: _filter == GridFilter.flagged
                              ? 'Every mark is inside the limits you set.'
                              : 'No student matches this filter or search.',
                          actionLabel: _filter == GridFilter.all && _query.isEmpty ? null : 'Show everyone',
                          onAction: () => setState(() {
                            _filter = GridFilter.all;
                            _query = '';
                            _searching = false;
                          }),
                        )
                      : LayoutBuilder(
                          builder: (context, box) => box.maxWidth >= 720
                              ? _TableView(data: data, rows: rows, width: box.maxWidth, onEdit: _edit)
                              : _CardList(data: data, rows: rows, onEdit: _edit),
                        ),
                ),
              ],
            ),
    );
  }

  int _count(GridData d, GridFilter f) => switch (f) {
        GridFilter.all => d.rows.length,
        GridFilter.incomplete => d.rows.where((r) => !r.result.complete).length,
        GridFilter.flagged => d.rows.where((r) => r.needsAttention).length,
      };
}

typedef EditCell = void Function(List<GridRow> rows, int index, PartSpec part);

// ---------------------------------------------------------------------------
// Phone layout: one card per student.
// ---------------------------------------------------------------------------

class _CardList extends StatelessWidget {
  const _CardList({required this.data, required this.rows, required this.onEdit});

  final GridData data;
  final List<GridRow> rows;
  final EditCell onEdit;

  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
        itemCount: rows.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _StudentCard(
            data: data,
            row: rows[i],
            onEdit: (part) => onEdit(rows, i, part),
          ),
        ),
      );
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.data, required this.row, required this.onEdit});

  final GridData data;
  final GridRow row;
  final void Function(PartSpec) onEdit;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final c = context.colors;
    final attention = row.flags.where((f) => f.needsAttention).toList();

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: attention.isEmpty ? scheme.outlineVariant : c.warning, width: attention.isEmpty ? 1 : 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${row.student.position + 1}. ${row.student.regNo}', style: text.titleMedium),
                      if ((row.student.name ?? '').isNotEmpty)
                        Text(row.student.name!, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                _TotalBadge(row: row, max: data.scheme.totalExpected),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in data.scheme.parts)
                  _CellChip(part: p, value: row.values[p.id], flags: row.flagsFor(p.id), onTap: () => onEdit(p)),
              ],
            ),
            for (final f in attention)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.flag_rounded, size: 18, color: f.severity == FlagSeverity.error ? c.danger : c.warning),
                    const SizedBox(width: 6),
                    Expanded(child: Text(f.message, style: text.bodyMedium)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TotalBadge extends StatelessWidget {
  const _TotalBadge({required this.row, required this.max});

  final GridRow row;
  final double max;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final c = context.colors;
    final total = row.result.total;
    final over = total != null && total > max + 1e-9;
    final grade = row.result.grade?.letter;

    return Semantics(
      label: total == null
          ? 'No total yet'
          : 'Total ${ScoreCalculator.formatTotal(total)}${grade == null ? '' : ', grade $grade'}',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minWidth: 72),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: over ? c.dangerContainer : scheme.primaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              total == null ? '—' : ScoreCalculator.formatTotal(total),
              style: text.titleLarge?.copyWith(color: over ? c.danger : scheme.onPrimaryContainer),
            ),
            Text(
              grade == null ? 'Total' : 'Grade $grade',
              style: text.bodySmall?.copyWith(color: over ? c.danger : scheme.onPrimaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}

/// One mark. Empty cells say "Tap" so it is clear they can be filled; flagged
/// cells are outlined in red.
class _CellChip extends StatelessWidget {
  const _CellChip({required this.part, required this.value, required this.flags, required this.onTap});

  final PartSpec part;
  final PartValue? value;
  final List<ScoreFlag> flags;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final c = context.colors;

    final bad = flags.any((f) => f.severity == FlagSeverity.error);
    final warn = flags.any((f) => f.severity == FlagSeverity.warning);
    final belowPass = flags.any((f) => f.kind == FlagKind.belowPass);
    final v = value;

    final String shown;
    if (v == null || (!v.hasValue && !v.isAbsent)) {
      shown = '—';
    } else if (v.isAbsent) {
      shown = 'ABS';
    } else {
      shown = ScoreCalculator.formatPartMark(part, v.value!);
    }
    final empty = shown == '—';

    final Color border = bad ? c.danger : warn ? c.warning : scheme.outlineVariant;
    final Color fill = bad
        ? c.dangerContainer
        : warn
            ? c.warningContainer
            : empty
                ? Colors.transparent
                : scheme.surfaceContainerHigh;
    final Color valueColor = bad ? c.danger : belowPass ? c.warning : empty ? scheme.outline : scheme.onSurface;

    return Semantics(
      button: true,
      label: '${part.name}: ${empty ? 'not entered' : shown}${flags.where((f) => f.needsAttention).map((f) => '. ${f.message}').join()}. Tap to edit.',
      excludeSemantics: true,
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: bad || warn ? 1.5 : 1),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 76, minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(part.name, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(shown, style: text.titleLarge?.copyWith(color: valueColor)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wide layout: a real table, for tablets and landscape.
// ---------------------------------------------------------------------------

class _TableView extends StatelessWidget {
  const _TableView({required this.data, required this.rows, required this.width, required this.onEdit});

  final GridData data;
  final List<GridRow> rows;
  final double width;
  final EditCell onEdit;

  static const double _serial = 56;
  static const double _reg = 210;
  static const double _part = 96;
  static const double _total = 88;
  static const double _grade = 72;

  @override
  Widget build(BuildContext context) {
    final parts = data.scheme.parts;
    final needed = _serial + _reg + parts.length * _part + _total + _grade + 32;
    final tableWidth = math.max(width, needed);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final c = context.colors;

    Widget head(String label, double w, {bool left = false}) => SizedBox(
          width: w,
          child: Text(label,
              textAlign: left ? TextAlign.left : TextAlign.center,
              style: text.labelLarge?.copyWith(fontSize: 14)),
        );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: tableWidth,
        child: Column(
          children: [
            Container(
              color: scheme.surfaceContainerHigh,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  head('S/N', _serial),
                  head('Registration No.', _reg, left: true),
                  for (final p in parts) head(p.name, _part),
                  head('Total', _total),
                  head('Grade', _grade),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 104),
                itemCount: rows.length,
                itemBuilder: (context, i) {
                  final row = rows[i];
                  final total = row.result.total;
                  final over = row.flags.any((f) => f.kind == FlagKind.totalAboveMax);
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
                      color: row.needsAttention ? c.warningContainer.withValues(alpha: 0.35) : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(width: _serial, child: Text('${row.student.position + 1}', textAlign: TextAlign.center)),
                        SizedBox(
                          width: _reg,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(row.student.regNo, style: text.titleMedium),
                              if ((row.student.name ?? '').isNotEmpty)
                                Text(row.student.name!, style: text.bodySmall, overflow: TextOverflow.ellipsis),
                              for (final f in row.rowFlags.where((f) => f.needsAttention))
                                Text(f.message, style: text.bodySmall?.copyWith(color: c.warning)),
                            ],
                          ),
                        ),
                        for (final p in parts)
                          SizedBox(
                            width: _part,
                            child: Center(
                              child: _CellChip(
                                part: p,
                                value: row.values[p.id],
                                flags: row.flagsFor(p.id),
                                onTap: () => onEdit(rows, i, p),
                              ),
                            ),
                          ),
                        SizedBox(
                          width: _total,
                          child: Text(
                            total == null ? '—' : ScoreCalculator.formatTotal(total),
                            textAlign: TextAlign.center,
                            style: text.titleMedium?.copyWith(color: over ? c.danger : null),
                          ),
                        ),
                        SizedBox(
                          width: _grade,
                          child: Text(row.result.grade?.letter ?? '', textAlign: TextAlign.center, style: text.titleMedium),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
