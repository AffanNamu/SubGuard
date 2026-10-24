import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/common.dart';
import '../../domain/scheme.dart';
import '../../providers/providers.dart';

/// Saved sets of marks and grades. The Nigerian default is built in and
/// always available, so it is not listed here.
class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesProvider);
    final repo = ref.read(courseRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved templates')),
      body: templates.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const ErrorState(message: 'The templates could not be loaded.'),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.bookmarks_rounded,
              title: 'No saved templates',
              message:
                  'When you set up a course, switch on "Save as a template" on the last step. Next semester you can start from it in two taps.',
            );
          }
          return ContentWidth(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final t = list[i];
                return Card(
                  child: ListTile(
                    minTileHeight: 72,
                    title: Text(t.name, style: Theme.of(context).textTheme.titleMedium),
                    subtitle: Text(schemeSummary(t.scheme)),
                    trailing: IconButton(
                      tooltip: 'Delete ${t.name}',
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () async {
                        await repo.deleteTemplate(t.id);
                        if (context.mounted) {
                          showUndo(context, '"${t.name}" deleted',
                              () => repo.saveTemplate(t.name, t.scheme, id: t.id));
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
