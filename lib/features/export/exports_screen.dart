import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/common.dart';
import '../../providers/providers.dart';
import 'export_screen.dart';

/// The Export tab: pick one or more courses, then choose the columns.
class ExportsScreen extends ConsumerStatefulWidget {
  const ExportsScreen({super.key});

  @override
  ConsumerState<ExportsScreen> createState() => _ExportsScreenState();
}

class _ExportsScreenState extends ConsumerState<ExportsScreen> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(coursesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Export')),
      body: courses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const ErrorState(message: 'The courses could not be loaded.'),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.ios_share_rounded,
              title: 'Nothing to export yet',
              message: 'Create a course and enter some scores. Then you can share them here as Word, Excel, PDF or CSV.',
            );
          }
          final selected = _selected.where((id) => list.any((c) => c.id == id)).toSet();
          return Column(
            children: [
              Expanded(
                child: ContentWidth(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Text(
                        'Choose the courses to export. You get one file for each course.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => setState(() {
                            if (selected.length == list.length) {
                              _selected.clear();
                            } else {
                              _selected
                                ..clear()
                                ..addAll(list.map((c) => c.id));
                            }
                          }),
                          child: Text(selected.length == list.length ? 'Clear selection' : 'Select all'),
                        ),
                      ),
                      for (final c in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: CheckboxListTile(
                              value: selected.contains(c.id),
                              onChanged: (v) => setState(() {
                                if (v == true) {
                                  _selected.add(c.id);
                                } else {
                                  _selected.remove(c.id);
                                }
                              }),
                              title: Text(c.title, style: Theme.of(context).textTheme.titleMedium),
                              subtitle: Text([
                                if (c.session.isNotEmpty) c.session,
                                if (c.semester.isNotEmpty) '${c.semester} semester',
                              ].join(' · ')),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              BottomActionBar(
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ExportScreen(
                                  courseIds: [for (final c in list) if (selected.contains(c.id)) c.id],
                                ),
                              ),
                            ),
                    child: Text(selected.isEmpty
                        ? 'Choose a course'
                        : selected.length == 1
                            ? 'Choose columns and export'
                            : 'Choose columns for ${selected.length} courses'),
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
