import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/common.dart';
import '../../data/repositories/score_repository.dart';
import '../../data/repositories/student_repository.dart';
import '../../domain/models.dart';
import '../../domain/reg_no.dart';
import '../../domain/scheme.dart';
import '../../domain/scoring.dart';
import '../../providers/providers.dart';
import '../../services/import/import_planner.dart';
import '../../services/import/table_reader.dart';

enum ImportMode { classList, scores }

/// Reads a CSV file, an Excel sheet or pasted text, lets the user confirm
/// which column is which, shows what will happen, and only then writes.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key, required this.courseId, required this.mode});

  final String courseId;
  final ImportMode mode;

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  RawTable? _table;
  String? _sourceName;
  bool _hasHeader = false;
  int? _regCol;
  int? _nameCol;
  final Map<String, int?> _partCols = {};
  bool _addUnmatched = false;
  bool _busy = false;
  final _paste = TextEditingController();

  bool get _isClassList => widget.mode == ImportMode.classList;

  @override
  void dispose() {
    _paste.dispose();
    super.dispose();
  }

  // ---- step 1: get a table ----

  Future<void> _pickFile() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv', 'tsv', 'txt', 'xlsx'],
        withData: true,
      );
      final file = picked?.files.singleOrNull;
      if (file == null) return;
      final bytes = file.bytes;
      if (bytes == null) {
        _fail('That file could not be read. Try saving it again, or paste the list instead.');
        return;
      }
      _load(TableReader.fromFile(file.name, bytes), file.name);
    } on FormatException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail('That file could not be read. Check that it is a CSV or Excel (.xlsx) file, or paste the list instead.');
    }
  }

  void _usePaste() {
    final table = TableReader.fromPaste(_paste.text);
    _load(table, 'Pasted list');
  }

  void _load(RawTable table, String name) {
    if (table.isEmpty) {
      _fail('Nothing was found in that file. Check that it has the registration numbers in it.');
      return;
    }
    final scheme = ref.read(courseProvider(widget.courseId)).valueOrNull?.scheme;
    final guess = ImportPlanner.guess(table, parts: _isClassList ? const [] : (scheme?.parts ?? const []));
    setState(() {
      _table = table;
      _sourceName = name;
      _hasHeader = guess.hasHeader;
      _regCol = guess.regNoColumn;
      _nameCol = guess.nameColumn;
      _partCols
        ..clear()
        ..addAll({for (final e in guess.partColumns.entries) e.key: e.value});
    });
  }

  void _fail(String message) {
    if (mounted) showMessage(context, message);
  }

  // ---- step 3: write ----

  Future<void> _commitClassList(List<NewStudent> rows) async {
    setState(() => _busy = true);
    try {
      final result = await ref.read(studentRepositoryProvider).addMany(widget.courseId, rows);
      if (!mounted) return;
      final bits = <String>[
        '${result.added} added',
        if (result.duplicates > 0) '${result.duplicates} already there',
        if (result.invalidPattern > 0) '${result.invalidPattern} to check',
      ];
      Navigator.pop(context);
      showMessage(context, bits.join(' · '));
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _fail('The import could not be saved. Nothing was changed. Please try again.');
      }
    }
  }

  Future<void> _commitScores(ScoreImportPlan plan) async {
    setState(() => _busy = true);
    try {
      final writes = [...plan.writes];
      var extra = 0;
      if (_addUnmatched && plan.unmatched.isNotEmpty) {
        final studentRepo = ref.read(studentRepositoryProvider);
        await studentRepo.addMany(
          widget.courseId,
          [for (final u in plan.unmatched) NewStudent(u.regNo)],
          onClassList: false,
        );
        final byKey = {
          for (final s in await studentRepo.getAll(widget.courseId)) RegNo.key(s.regNo): s,
        };
        for (final u in plan.unmatched) {
          final s = byKey[u.regNo];
          if (s == null) continue;
          extra++;
          for (final e in u.values.entries) {
            writes.add(ScoreWrite(
              studentId: s.id,
              partId: e.key,
              value: e.value.value,
              status: e.value.isAbsent ? ScoreStatus.absent : ScoreStatus.entered,
              source: 'imported',
            ));
          }
        }
      }
      await ref.read(scoreRepositoryProvider).setMany(widget.courseId, writes);
      if (!mounted) return;
      Navigator.pop(context);
      showMessage(
        context,
        '${plan.matchedStudents + extra} students updated · ${writes.length} marks imported',
      );
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _fail('The import could not be saved. Nothing was changed. Please try again.');
      }
    }
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    final title = _isClassList ? 'Import class list' : 'Import scores';
    final table = _table;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (table != null)
            TextButton(
              onPressed: _busy ? null : () => setState(() => _table = null),
              child: const Text('Start over'),
            ),
        ],
      ),
      body: ContentWidth(
        child: table == null ? _sourceStep() : _mapStep(table),
      ),
    );
  }

  Widget _sourceStep() {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    final scheme = ref.watch(courseProvider(widget.courseId)).valueOrNull?.scheme;
    final partNames = scheme?.parts.where((p) => !p.isExamLike).map((p) => p.name).toList() ?? const <String>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        Text(
          _isClassList
              ? 'Add the students from a file or a document. Registration numbers are tidied up as they come in, for example 244 becomes 24U.'
              : 'Bring in ${partNames.isEmpty ? 'marks' : partNames.join(', ')} from a spreadsheet. Students are matched by registration number.',
          style: muted,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.folder_open_rounded),
          label: const Text('Choose a CSV or Excel file'),
        ),
        const SectionHeading('Or paste'),
        Text(
          _isClassList
              ? 'Copy the numbers from Word, Excel or a message and paste them here. One student per line. A name after the number is fine.'
              : 'Copy the rows from a spreadsheet, with the registration number and the marks, and paste them here.',
          style: muted,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _paste,
          minLines: 6,
          maxLines: 12,
          keyboardType: TextInputType.multiline,
          autocorrect: false,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: _isClassList
                ? 'FWM/24U/0538\nFWM/24U/0539\nFST/25U/244/5772'
                : 'FWM/24U/0538\t4\t3.5\t5',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _paste.text.trim().isEmpty ? null : _usePaste,
          icon: const Icon(Icons.content_paste_go_rounded),
          label: const Text('Use this list'),
        ),
      ],
    );
  }

  Widget _mapStep(RawTable table) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    final course = ref.watch(courseProvider(widget.courseId)).valueOrNull;
    final students = ref.watch(studentsProvider(widget.courseId)).valueOrNull ?? const <Student>[];

    final regCol = _regCol;
    final parts = (course?.scheme.parts ?? const <PartSpec>[]);

    // What would happen, shown before anything is written.
    Widget summary = const SizedBox.shrink();
    VoidCallback? commit;
    if (regCol != null && course != null) {
      if (_isClassList) {
        final rows = ImportPlanner.classList(
          table,
          regNoColumn: regCol,
          nameColumn: _nameCol,
          hasHeader: _hasHeader,
        );
        summary = _classListSummary(rows, students);
        final ready = rows.any((r) => r.regNo.trim().isNotEmpty);
        commit = ready ? () => _commitClassList(rows) : null;
      } else {
        final cols = {
          for (final e in _partCols.entries)
            if (e.value != null) e.key: e.value!,
        };
        final plan = ImportPlanner.scores(
          table,
          regNoColumn: regCol,
          partColumns: cols,
          hasHeader: _hasHeader,
          scheme: course.scheme,
          students: students,
        );
        summary = _scoresSummary(plan);
        final ready = plan.writes.isNotEmpty || (_addUnmatched && plan.unmatched.isNotEmpty);
        commit = ready ? () => _commitScores(plan) : null;
      }
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              Text('${_sourceName ?? 'File'} · ${table.rowCount} rows', style: muted),
              const SizedBox(height: 10),
              _Preview(table: table, hasHeader: _hasHeader),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('The first row is a heading'),
                value: _hasHeader,
                onChanged: (v) => setState(() => _hasHeader = v),
              ),
              const SectionHeading('Which column is which?'),
              _ColumnPicker(
                label: 'Registration number',
                table: table,
                hasHeader: _hasHeader,
                value: _regCol,
                required: true,
                onChanged: (v) => setState(() => _regCol = v),
              ),
              if (_isClassList) ...[
                const SizedBox(height: 12),
                _ColumnPicker(
                  label: 'Name (optional)',
                  table: table,
                  hasHeader: _hasHeader,
                  value: _nameCol,
                  onChanged: (v) => setState(() => _nameCol = v),
                ),
              ] else
                for (final p in parts)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _ColumnPicker(
                      label: '${p.name} marks',
                      table: table,
                      hasHeader: _hasHeader,
                      value: _partCols[p.id],
                      onChanged: (v) => setState(() => _partCols[p.id] = v),
                    ),
                  ),
              const SectionHeading('What will happen'),
              if (regCol == null)
                const InfoBanner(
                  message: 'Choose the column that holds the registration numbers.',
                  kind: BannerKind.warning,
                )
              else
                summary,
            ],
          ),
        ),
        BottomActionBar(
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : commit,
              child: _busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text(_isClassList ? 'Add to class list' : 'Import marks'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _classListSummary(List<NewStudent> rows, List<Student> existing) {
    final have = existing.map((s) => RegNo.key(s.regNo)).toSet();
    final seen = <String>{};
    var add = 0, dup = 0, blank = 0, invalid = 0, fixed = 0;
    for (final r in rows) {
      final n = RegNo.normalise(r.regNo);
      if (n.canonical.isEmpty) {
        blank++;
      } else if (have.contains(n.canonical) || !seen.add(n.canonical)) {
        dup++;
      } else {
        add++;
        if (!n.isValid) invalid++;
        if (n.wasCorrected) fixed++;
      }
    }
    return Column(
      children: [
        InfoBanner(
          message: '$add students will be added.',
          kind: add > 0 ? BannerKind.success : BannerKind.warning,
        ),
        if (dup > 0) ...[
          const SizedBox(height: 8),
          InfoBanner(message: '$dup skipped because the number is already on the list or repeated in the file.'),
        ],
        if (fixed > 0) ...[
          const SizedBox(height: 8),
          InfoBanner(message: '$fixed numbers were tidied up, for example 244 read as 24U.'),
        ],
        if (invalid > 0) ...[
          const SizedBox(height: 8),
          InfoBanner(
            message: '$invalid do not look like DEPT/YYU/NNNN. They will be added and flagged so you can check them.',
            kind: BannerKind.warning,
          ),
        ],
        if (blank > 0) ...[
          const SizedBox(height: 8),
          InfoBanner(message: '$blank empty rows ignored.'),
        ],
      ],
    );
  }

  Widget _scoresSummary(ScoreImportPlan plan) {
    final text = Theme.of(context).textTheme;
    final cellsExisting = ref.watch(scoresProvider(widget.courseId)).valueOrNull ?? const {};
    var overwrite = 0;
    for (final w in plan.writes) {
      if (cellsExisting[w.studentId]?[w.partId]?.isFilled ?? false) overwrite++;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoBanner(
          message: plan.writes.isEmpty
              ? 'No marks to import yet. Check that the columns are matched to the parts.'
              : '${plan.writes.length} marks for ${plan.matchedStudents} students will be imported.',
          kind: plan.writes.isEmpty ? BannerKind.warning : BannerKind.success,
        ),
        if (overwrite > 0) ...[
          const SizedBox(height: 8),
          InfoBanner(
            message: '$overwrite of these replace marks that are already entered.',
            kind: BannerKind.warning,
          ),
        ],
        if (plan.absentCells > 0) ...[
          const SizedBox(height: 8),
          InfoBanner(message: '${plan.absentCells} marked absent.'),
        ],
        if (plan.repeatedRows > 0) ...[
          const SizedBox(height: 8),
          InfoBanner(message: '${plan.repeatedRows} repeated rows skipped. The first one for each student is used.'),
        ],
        if (plan.unreadable.isNotEmpty) ...[
          const SizedBox(height: 8),
          InfoBanner(
            message:
                '${plan.unreadable.length} cells are not marks and were skipped, for example "${plan.unreadable.first.text}" on row ${plan.unreadable.first.row}.',
            kind: BannerKind.warning,
          ),
        ],
        if (plan.unmatched.isNotEmpty) ...[
          const SizedBox(height: 8),
          InfoBanner(
            message: '${plan.unmatched.length} numbers are not on the class list.',
            kind: BannerKind.warning,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (final u in plan.unmatched.take(5))
                  ListTile(
                    dense: true,
                    title: Text(u.regNo.isEmpty ? u.rawRegNo : u.regNo),
                    subtitle: u.suggestions.isEmpty
                        ? const Text('No close match on the class list')
                        : Text('Did you mean ${u.suggestions.map((s) => s.regNo).join(' or ')}?'),
                  ),
                if (plan.unmatched.length > 5)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('and ${plan.unmatched.length - 5} more', style: text.bodyMedium),
                  ),
                SwitchListTile(
                  title: const Text('Add them as extra students'),
                  subtitle: const Text('They are flagged as not on the class list. Otherwise they are skipped.'),
                  value: _addUnmatched,
                  onChanged: (v) => setState(() => _addUnmatched = v),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// The first few rows, so the user can see what was read.
class _Preview extends StatelessWidget {
  const _Preview({required this.table, required this.hasHeader});

  final RawTable table;
  final bool hasHeader;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = table.rows.take(5).toList();
    final cols = table.columnCount.clamp(0, 8);
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: [
            for (var r = 0; r < rows.length; r++)
              TableRow(
                children: [
                  for (var c = 0; c < cols; c++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Text(
                        rows[r][c],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: hasHeader && r == 0 ? FontWeight.w700 : FontWeight.w400,
                            ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ColumnPicker extends StatelessWidget {
  const _ColumnPicker({
    required this.label,
    required this.table,
    required this.hasHeader,
    required this.value,
    required this.onChanged,
    this.required = false,
  });

  final String label;
  final RawTable table;
  final bool hasHeader;
  final int? value;
  final bool required;
  final ValueChanged<int?> onChanged;

  String _name(int c) {
    final letter = String.fromCharCode(65 + (c % 26));
    final head = hasHeader ? table.cell(0, c) : '';
    final sample = table.cell(hasHeader ? 1 : 0, c);
    final shown = head.isNotEmpty ? head : sample;
    return shown.isEmpty ? 'Column $letter' : 'Column $letter · $shown';
  }

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<int?>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          if (!required) const DropdownMenuItem<int?>(value: null, child: Text('None')),
          for (var c = 0; c < table.columnCount; c++)
            DropdownMenuItem<int?>(
              value: c,
              child: Text(_name(c), overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: onChanged,
      );
}
