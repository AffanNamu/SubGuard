import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/widgets/common.dart';
import '../../domain/models.dart';
import '../../providers/providers.dart';
import '../../services/export/export_service.dart';
import '../../services/export/result_table.dart';
import '../settings/header_settings_screen.dart';

/// Choose which columns are filled, pick a format, and share the files.
/// Several courses can be exported in one go: one file per course.
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key, required this.courseIds});

  final List<String> courseIds;

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  ExportPreset? _preset = ExportPreset.fullResult;
  ExportOptions? _options;
  ExportFormat _format = ExportFormat.docx;
  bool _busy = false;
  List<ExportedFile>? _done;
  String? _error;

  List<Course> _courses() {
    final all = ref.read(coursesProvider).valueOrNull ?? const <Course>[];
    return [for (final id in widget.courseIds) ...all.where((c) => c.id == id)];
  }

  ExportOptions _current(List<Course> courses) {
    return _options ??
        ExportOptions.preset(
          _preset ?? ExportPreset.fullResult,
          courses.map((c) => c.scheme),
          includeHeader: !ref.read(settingsProvider).header.isEmpty,
        );
  }

  void _applyPreset(ExportPreset p, List<Course> courses) {
    final old = _current(courses);
    setState(() {
      _preset = p;
      _options = ExportOptions.preset(
        p,
        courses.map((c) => c.scheme),
        serialOrder: old.serialOrder,
        includeHeader: old.includeHeader,
      );
      _done = null;
    });
  }

  void _custom(ExportOptions o) => setState(() {
        _options = o;
        _preset = null;
        _done = null;
      });

  Future<void> _export(List<Course> courses) async {
    setState(() {
      _busy = true;
      _error = null;
      _done = null;
    });
    try {
      final students = ref.read(studentRepositoryProvider);
      final scores = ref.read(scoreRepositoryProvider);
      final data = <CourseExportData>[
        for (final c in courses)
          CourseExportData(
            course: c,
            students: await students.getAll(c.id),
            scores: await scores.get(c.id),
          ),
      ];

      final dir = Directory('${(await getTemporaryDirectory()).path}/exports');
      if (dir.existsSync()) dir.deleteSync(recursive: true);

      final result = await const ExportService().exportCourses(
        courses: data,
        format: _format,
        options: _current(courses),
        directory: dir,
        header: ref.read(settingsProvider).header,
        label: _preset?.label,
      );

      if (!mounted) return;
      if (result.files.isEmpty) {
        setState(() {
          _busy = false;
          _error = 'The file could not be made. Please try again.';
        });
        return;
      }

      setState(() {
        _busy = false;
        _done = result.files;
        if (result.failures.isNotEmpty) {
          _error = 'These courses could not be exported: ${result.failures.keys.join(', ')}.';
        }
      });

      await Share.shareXFiles(
        [for (final f in result.files) XFile(f.path, mimeType: f.format.mimeType)],
        subject: courses.length == 1 ? courses.single.title : 'Results',
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'The export did not finish. Nothing was changed. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Export')),
      body: coursesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const ErrorState(message: 'The courses could not be loaded.'),
        data: (_) {
          final courses = _courses();
          if (courses.isEmpty) {
            return const EmptyState(
              icon: Icons.ios_share_rounded,
              title: 'Nothing to export',
              message: 'These courses are no longer available.',
            );
          }
          final options = _current(courses);
          return Column(
            children: [
              Expanded(
                child: ContentWidth(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Text(
                        courses.length == 1
                            ? courses.single.title
                            : '${courses.length} courses · one file for each',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SectionHeading('Layout'),
                      for (final p in ExportPreset.values)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _PresetCard(
                            preset: p,
                            selected: _preset == p,
                            onTap: () => _applyPreset(p, courses),
                          ),
                        ),
                      if (_preset == null)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: InfoBanner(message: 'Custom columns. Pick a layout above to start again.'),
                        ),
                      const SectionHeading('Columns'),
                      _ColumnChooser(courses: courses, options: options, onChanged: _custom),
                      const SectionHeading('Header'),
                      Card(
                        child: SwitchListTile(
                          title: const Text('Print the header'),
                          subtitle: Text(settings.header.isEmpty
                              ? 'No header set yet. Add your university, faculty and name in Settings.'
                              : settings.header.lines().join(' · ')),
                          value: options.includeHeader,
                          onChanged: (v) => _custom(options.copyWith(includeHeader: v)),
                        ),
                      ),
                      if (settings.header.isEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const HeaderSettingsScreen()),
                            ),
                            child: const Text('Set up the header'),
                          ),
                        ),
                      const SectionHeading('File type'),
                      SegmentedButton<ExportFormat>(
                        showSelectedIcon: false,
                        segments: [
                          for (final f in ExportFormat.values)
                            ButtonSegment(value: f, label: Text(f.label)),
                        ],
                        selected: {_format},
                        onSelectionChanged: (s) => setState(() {
                          _format = s.first;
                          _done = null;
                        }),
                      ),
                      const SectionHeading('Preview'),
                      _Preview(course: courses.first, options: options, header: settings.header),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        InfoBanner(message: _error!, kind: BannerKind.danger),
                      ],
                      if (_done != null) ...[
                        const SizedBox(height: 16),
                        InfoBanner(
                          message: _done!.length == 1
                              ? 'Ready: ${_done!.single.name}'
                              : 'Ready: ${_done!.length} files',
                          kind: BannerKind.success,
                          action: 'Share again',
                          onAction: () => Share.shareXFiles([
                            for (final f in _done!) XFile(f.path, mimeType: f.format.mimeType),
                          ]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              BottomActionBar(
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _export(courses),
                    icon: _busy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                        : const Icon(Icons.ios_share_rounded),
                    label: Text(_busy
                        ? 'Making the file…'
                        : courses.length == 1
                            ? 'Export as ${_format.label}'
                            : 'Export ${courses.length} files as ${_format.label}'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({required this.preset, required this.selected, required this.onTap});

  final ExportPreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 2 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    color: selected ? scheme.primary : scheme.outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(preset.label, style: Theme.of(context).textTheme.titleMedium),
                      Text(preset.description,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// For each column: filled, or left blank. Parts are matched by name, so one
/// choice covers every selected course that has a part with that name.
class _ColumnChooser extends StatelessWidget {
  const _ColumnChooser({required this.courses, required this.options, required this.onChanged});

  final List<Course> courses;
  final ExportOptions options;
  final ValueChanged<ExportOptions> onChanged;

  @override
  Widget build(BuildContext context) {
    final names = <String, String>{};
    for (final c in courses) {
      for (final p in c.scheme.parts) {
        names.putIfAbsent(ExportOptions.partKey(p.name), () => p.name);
      }
    }

    Widget row(String title, String on, String off, bool value, ValueChanged<bool>? change) => SwitchListTile(
          title: Text(title),
          subtitle: Text(value ? on : off),
          value: value,
          onChanged: change,
        );

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: DropdownButtonFormField<SerialOrder>(
              initialValue: options.serialOrder,
              key: ValueKey(options.serialOrder),
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'S/N numbering'),
              onChanged: (v) {
                if (v != null) onChanged(options.copyWith(serialOrder: v));
              },
              items: [
                for (final o in SerialOrder.values)
                  DropdownMenuItem(value: o, child: Text(o.label)),
              ],
            ),
          ),
          const Divider(),
          row('Registration No.', 'Always filled', 'Always filled', true, null),
          for (final e in names.entries) ...[
            const Divider(),
            row(
              e.value,
              'Filled in',
              'Left blank',
              options.partFilled[e.key] ?? true,
              (v) => onChanged(options.copyWith(partFilled: {...options.partFilled, e.key: v})),
            ),
          ],
          const Divider(),
          row(
            'Total',
            'Added up automatically',
            'Left blank',
            options.totalFilled,
            (v) => onChanged(options.copyWith(totalFilled: v)),
          ),
          const Divider(),
          row(
            'Grade',
            'Included, from the grade scale',
            'Left out',
            options.includeGrade,
            (v) => onChanged(options.copyWith(includeGrade: v)),
          ),
        ],
      ),
    );
  }
}

/// The first rows of the first course, so the choices can be checked before
/// anything is made.
class _Preview extends ConsumerWidget {
  const _Preview({required this.course, required this.options, required this.header});

  final Course course;
  final ExportOptions options;
  final ExportHeader header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grid = ref.watch(gridProvider(course.id)).valueOrNull;
    final scheme = Theme.of(context).colorScheme;
    if (grid == null) return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
    if (grid.rows.isEmpty) {
      return const InfoBanner(message: 'This course has no students yet, so the file will have only the headings.');
    }

    final scores = ref.watch(scoresProvider(course.id)).valueOrNull ?? const {};
    final table = ResultTableBuilder.build(
      course: course,
      students: [for (final r in grid.rows) r.student],
      scores: scores,
      options: options,
      header: header,
    );
    final shown = table.rows.take(4).toList();

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Text(table.title, style: Theme.of(context).textTheme.titleMedium),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: TableBorder.all(color: scheme.outlineVariant),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: scheme.surfaceContainerHighest),
                  children: [for (final c in table.columns) _cell(context, c.title, bold: true)],
                ),
                for (final r in shown)
                  TableRow(children: [for (final c in r) _cell(context, c.text)]),
              ],
            ),
          ),
          if (table.rows.length > shown.length)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Text('and ${table.rows.length - shown.length} more rows',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, String text, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          text.isEmpty ? ' ' : text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
        ),
      );
}
