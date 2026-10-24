
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/widgets/common.dart';
import '../../core/widgets/ui_kit.dart';
import '../../services/incoming/incoming_file.dart';
import '../../services/incoming/saved_documents.dart';
import '../home/home_actions.dart';
import 'incoming_controller.dart';
import 'incoming_file_screen.dart';

/// Documents kept in UniMarkLy with "Save a copy": open, share or delete.
class SavedDocumentsScreen extends ConsumerStatefulWidget {
  const SavedDocumentsScreen({super.key});

  @override
  ConsumerState<SavedDocumentsScreen> createState() => _SavedDocumentsScreenState();
}

class _SavedDocumentsScreenState extends ConsumerState<SavedDocumentsScreen> {
  late Future<List<SavedDocument>> _docs = ref.read(savedDocumentsProvider).list();

  void _reload() => setState(() => _docs = ref.read(savedDocumentsProvider).list());

  Future<void> _delete(SavedDocument d) async {
    final ok = await confirm(
      context,
      title: 'Delete this saved file?',
      message: '${d.name} is removed from UniMarkLy. The original, where it came from, is not touched.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(savedDocumentsProvider).delete(d);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Saved documents')),
      body: FutureBuilder<List<SavedDocument>>(
        future: _docs,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ErrorState(message: 'The saved documents could not be listed.', onRetry: _reload);
          }
          final docs = snap.data ?? const [];
          if (docs.isEmpty) {
            return const EmptyState(
              icon: Icons.folder_open_rounded,
              title: 'Nothing saved yet',
              message: 'When another app opens a document with UniMarkLy, "Save a copy" keeps it here.',
            );
          }
          return ContentWidth(
            maxWidth: 760,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                for (final d in docs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlowCard(
                      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => IncomingFileScreen(
                              deleteOnClose: false,
                              file: IncomingFile(id: d.path, path: d.path, name: d.name, size: d.size),
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.titleMedium),
                                Text('Saved ${shortDate(d.saved)}',
                                    style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'More for ${d.name}',
                            onSelected: (v) {
                              if (v == 'share') Share.shareXFiles([XFile(d.path, name: d.name)]);
                              if (v == 'delete') _delete(d);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'share', child: Text('Open in another app')),
                              PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
