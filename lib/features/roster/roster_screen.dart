import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../data/repositories/student_repository.dart';
import '../../domain/models.dart';
import '../../providers/providers.dart';
import 'import_screen.dart';
import 'student_sheet.dart';

/// The class list for one course.
class RosterScreen extends ConsumerStatefulWidget {
  const RosterScreen({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends ConsumerState<RosterScreen> {
  String _query = '';

  void _import(ImportMode mode) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ImportScreen(courseId: widget.courseId, mode: mode)),
      );

  Future<void> _add(List<Student> all) async {
    final edit = await showStudentSheet(context, others: all);
    if (edit == null || !mounted) return;
    final result = await ref
        .read(studentRepositoryProvider)
        .addMany(widget.courseId, [NewStudent(edit.regNo, name: edit.name)]);
    if (!mounted) return;
    if (result.duplicates > 0) showMessage(context, 'That number is already on the class list.');
  }

  Future<void> _edit(Student s, List<Student> all) async {
    final edit = await showStudentSheet(context, existing: s, others: all);
    if (edit == null) return;
    await ref
        .read(studentRepositoryProvider)
        .update(s.copyWith(regNo: edit.regNo, name: edit.name ?? ''));
  }

  Future<void> _delete(Student s) async {
    final repo = ref.read(studentRepositoryProvider);
    await repo.softDelete(s.id);
    if (mounted) showUndo(context, '${s.regNo} removed', () => repo.restore(s.id));
  }

  @override
  Widget build(BuildContext context) {
    final grid = ref.watch(gridProvider(widget.courseId));
    final deleted = ref.watch(deletedStudentsProvider(widget.courseId)).valueOrNull ?? const [];

    return grid.when(
      loading: () => Scaffold(appBar: AppBar(title: const Text('Class list')), body: const Center(child: CircularProgressIndicator())),
      error: (_, __) => Scaffold(appBar: AppBar(title: const Text('Class list')), body: const ErrorState(message: 'The class list could not be loaded.')),
      data: (data) {
        final all = data.rows.map((r) => r.student).toList();
        final q = _query.trim().toLowerCase();
        final rows = q.isEmpty
            ? data.rows
            : data.rows
                .where((r) =>
                    r.student.regNo.toLowerCase().contains(q) ||
                    (r.student.name ?? '').toLowerCase().contains(q))
                .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text('Class list · ${data.course.code}'),
            actions: [
              if (all.isNotEmpty)
                IconButton(
                  tooltip: 'Import more students',
                  icon: const Icon(Icons.upload_file_rounded),
                  onPressed: () => _import(ImportMode.classList),
                ),
            ],
          ),
          floatingActionButton: all.isEmpty
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _add(all),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Add student'),
                ),
          body: all.isEmpty
              ? EmptyState(
                  icon: Icons.groups_rounded,
                  title: 'No students yet',
                  message: 'Import the class list from a CSV or Excel file, paste it from a document, or add students one at a time.',
                  actionLabel: 'Import or paste a list',
                  onAction: () => _import(ImportMode.classList),
                  secondaryLabel: 'Add one student',
                  onSecondary: () => _add(all),
                )
              : ContentWidth(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: TextField(
                          onChanged: (v) => setState(() => _query = v),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search_rounded),
                            hintText: 'Search by number or name',
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            q.isEmpty ? '${all.length} students' : '${rows.length} of ${all.length} students',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                      Expanded(
                        child: rows.isEmpty
                            ? const EmptyState(
                                icon: Icons.search_off_rounded,
                                title: 'No match',
                                message: 'No student matches that search.',
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
                                itemCount: rows.length + (deleted.isEmpty ? 0 : 1),
                                itemBuilder: (context, i) {
                                  if (i == rows.length) {
                                    return _DeletedFooter(
                                      deleted: deleted,
                                      onRestore: (s) => ref.read(studentRepositoryProvider).restore(s.id),
                                    );
                                  }
                                  final row = rows[i];
                                  return _StudentTile(
                                    row: row,
                                    index: row.student.position + 1,
                                    onTap: () => _edit(row.student, all),
                                    onDelete: () => _delete(row.student),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.row, required this.index, required this.onTap, required this.onDelete});

  final GridRow row;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final s = row.student;
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final flags = row.flags.where((f) => f.partId == null && f.needsAttention).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(s.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(color: c.dangerContainer, borderRadius: BorderRadius.circular(16)),
          child: Icon(Icons.delete_outline_rounded, color: c.danger),
        ),
        onDismissed: (_) => onDelete(),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text('$index', style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.regNo, style: text.titleMedium),
                        if ((s.name ?? '').isNotEmpty)
                          Text(s.name!, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                        for (final f in flags)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.flag_rounded, size: 16, color: c.warning),
                                const SizedBox(width: 6),
                                Expanded(child: Text(f.message, style: text.bodySmall?.copyWith(color: c.warning))),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit_outlined, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeletedFooter extends StatelessWidget {
  const _DeletedFooter({required this.deleted, required this.onRestore});

  final List<Student> deleted;
  final void Function(Student) onRestore;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Center(
          child: TextButton.icon(
            icon: const Icon(Icons.restore_from_trash_rounded),
            label: Text('Removed students (${deleted.length})'),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (ctx) => SafeArea(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Text('Removed students', style: Theme.of(ctx).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    for (final s in deleted)
                      ListTile(
                        title: Text(s.regNo),
                        subtitle: (s.name ?? '').isEmpty ? null : Text(s.name!),
                        trailing: TextButton(
                          onPressed: () {
                            onRestore(s);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Restore'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
