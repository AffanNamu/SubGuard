import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/common.dart';
import '../../providers/providers.dart';

/// Deleted courses are kept here, with their class lists and scores, until
/// they are brought back.
class BinScreen extends ConsumerWidget {
  const BinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deleted = ref.watch(deletedCoursesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Bin')),
      body: deleted.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const ErrorState(message: 'The bin could not be loaded.'),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.delete_outline_rounded,
              title: 'The bin is empty',
              message: 'Courses you delete wait here, so you can bring them back with everything in them.',
            );
          }
          return ContentWidth(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = list[i];
                return Card(
                  child: ListTile(
                    minTileHeight: 72,
                    title: Text(c.title, style: Theme.of(context).textTheme.titleMedium),
                    subtitle: Text([
                      if (c.session.isNotEmpty) c.session,
                      if (c.semester.isNotEmpty) '${c.semester} semester',
                    ].join(' · ')),
                    trailing: FilledButton.tonal(
                      onPressed: () async {
                        await ref.read(courseRepositoryProvider).restore(c.id);
                        if (context.mounted) showMessage(context, '${c.title} is back in Courses');
                      },
                      child: const Text('Restore'),
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
