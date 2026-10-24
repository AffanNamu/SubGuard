import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/ui_kit.dart';
import '../../domain/scan.dart';
import '../../providers/providers.dart';
import '../scan/scan_screen.dart';
import '../scan/scan_widgets.dart';
import 'home_actions.dart';

/// One upload in a list: thumbnail, name, "N images | M confirmed", status,
/// and a menu to open or delete it.
class BatchCard extends ConsumerWidget {
  const BatchCard({super.key, required this.batch});

  final BatchSummary batch;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await confirm(
      context,
      title: 'Delete this upload?',
      message:
          'The ${batch.counts.images} photos in ${batchName(batch)} are removed from the lists. Marks you already confirmed stay in the score grid.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final repo = ref.read(scanRepositoryProvider);
    await repo.softDeleteBatch(batch.id);
    if (!context.mounted) return;
    showUndo(context, 'Upload deleted', () => repo.restoreBatch(batch.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final cover = batch.coverPath;

    return GlowCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      semanticLabel: '${batchName(batch)}. ${batchLine(batch.counts)}. ${batch.status.label}',
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ScanScreen(batchId: batch.id))),
      child: LayoutBuilder(builder: (context, box) {
        final chipBeside = box.maxWidth >= 400;
        final chip = StatusChip.forBatch(batch.status);
        return Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 60,
                height: 60,
                child: cover == null
                    ? ColoredBox(
                        color: scheme.surfaceContainerHighest,
                        child: Icon(Icons.description_outlined, color: scheme.onSurfaceVariant),
                      )
                    : ScanImage(relativePath: cover, cacheWidth: 180),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(batchName(batch), maxLines: 2, overflow: TextOverflow.ellipsis, style: text.titleMedium),
                  const SizedBox(height: 2),
                  Text(batchLine(batch.counts),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  if (!chipBeside) ...[const SizedBox(height: 6), Align(alignment: Alignment.centerLeft, child: chip)],
                ],
              ),
            ),
            if (chipBeside) ...[const SizedBox(width: 8), chip],
            PopupMenuButton<String>(
              tooltip: 'More for ${batchName(batch)}',
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (v) {
                if (v == 'open') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ScanScreen(batchId: batch.id)));
                } else {
                  _delete(context, ref);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'open', child: Text('Open')),
                PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: context.colors.danger))),
              ],
            ),
          ],
        );
      }),
    );
  }
}
