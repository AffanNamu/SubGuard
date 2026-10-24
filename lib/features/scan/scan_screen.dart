import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/ui_kit.dart';
import '../../domain/scan.dart';
import '../../providers/providers.dart';
import '../export/export_screen.dart';
import 'review_screen.dart';
import 'scan_widgets.dart';
import 'upload_flow.dart';

/// Scan & Extract: add booklet photos, watch them being read, and move on to
/// review. Everything on this screen is a real state of the stored batch.
class ScanScreen extends ConsumerWidget {
  const ScanScreen({super.key, required this.batchId});

  final String batchId;

  /// 0 Upload, 1 Processing, 2 Review, 3 Save, 4 Export: where this batch is.
  static int stepFor(BatchCounts c) {
    if (c.images == 0 || (c.queued > 0 && c.processing == 0 && c.needsReview + c.confirmed == 0)) return 0;
    if (c.processing > 0 || c.queued > 0) return 1;
    if (c.needsReview > 0) return 2;
    if (c.confirmed > 0 && c.confirmed == c.images - c.failed) return 4;
    return 3;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batch = ref.watch(batchProvider(batchId));
    final scans = ref.watch(batchScansProvider(batchId)).valueOrNull ?? const <ScanItem>[];
    final processing = ref.watch(processingProvider);
    final text = Theme.of(context).textTheme;

    if (batch == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ref.watch(batchesProvider).isLoading
            ? const Center(child: CircularProgressIndicator())
            : const ErrorState(message: 'This upload could not be found. It may have been deleted.'),
      );
    }

    final counts = batch.counts;
    final step = stepFor(counts);
    final reading = processing.batchId == batchId;
    final scheme = Theme.of(context).colorScheme;

    Future<void> add(UploadSource source) => runUpload(context, ref, source, batchId: batchId);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ContentWidth(
                maxWidth: 760,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Row(
                      children: [
                        IconButton.outlined(
                          tooltip: 'Back',
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Scan & Extract', style: text.headlineSmall),
                              Text(
                                '${batch.course.title} · ${batch.course.semester.isEmpty ? batch.course.session : batch.course.semester}',
                                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        IconButton.outlined(
                          tooltip: 'How this works',
                          onPressed: () => _showHelp(context),
                          icon: const Icon(Icons.help_outline_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Steps(current: step),
                    const SizedBox(height: 16),

                    // ---- 1. Upload ----
                    GlowCard(
                      tint: context.colors.tileGreen,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GradientIcon(icon: Icons.image_rounded, color: context.colors.tileGreen),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Upload Exam Images', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                                    Text('Take photos or select several images of exam booklets.',
                                        style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              GradientButton(
                                  label: 'Take Photo', icon: Icons.photo_camera_rounded, onPressed: () => add(UploadSource.camera), height: 52),
                              PillButton(label: 'Choose Images', icon: Icons.photo_library_rounded, onPressed: () => add(UploadSource.gallery)),
                              PillButton(label: 'Upload Many', icon: Icons.upload_file_rounded, onPressed: () => add(UploadSource.files)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('JPG or PNG, up to 10 MB each. PDF is not supported yet.',
                              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                          if (scans.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 168,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                clipBehavior: Clip.none,
                                itemCount: scans.length + 1,
                                separatorBuilder: (_, __) => const SizedBox(width: 14),
                                itemBuilder: (context, i) {
                                  if (i == scans.length) {
                                    return _AddMore(onTap: () => add(UploadSource.gallery));
                                  }
                                  final s = scans[i];
                                  final removable = s.status != ScanStatus.confirmed && s.status != ScanStatus.processing;
                                  return ScanThumb(
                                    scan: s,
                                    onTap: s.status == ScanStatus.needsReview || s.status == ScanStatus.confirmed
                                        ? () => _openReview(context, s.id, scans)
                                        : null,
                                    onRemove: removable ? () => _remove(context, ref, s) : null,
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ---- 2. Processing ----
                    GlowCard(
                      tint: Brand.purple,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const GradientIcon(icon: Icons.settings_rounded, color: Brand.purple),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Processing Images', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                                    Text(
                                      _processingHint(counts, reading, ref.read(ocrEngineProvider).name == 'none'),
                                      style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _ProgressRow(counts: counts, batchId: batchId, reading: reading, processing: processing),
                          if (scans.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [for (final s in scans) _ScanStatusTile(scan: s)],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            BottomActionBar(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.chevron_left_rounded),
                      label: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _nextButton(context, ref, batch, scans, reading),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nextButton(BuildContext context, WidgetRef ref, BatchSummary batch, List<ScanItem> scans, bool reading) {
    final c = batch.counts;
    if (c.needsReview > 0) {
      return GradientButton(
        label: 'Next: Review Results',
        trailing: Icons.arrow_forward_rounded,
        expand: true,
        onPressed: () {
          final first = scans.firstWhere((s) => s.status == ScanStatus.needsReview);
          _openReview(context, first.id, scans);
        },
      );
    }
    if (c.queued > 0 && !reading) {
      return GradientButton(
        label: c.queued == 1 ? 'Read 1 photo' : 'Read ${c.queued} photos',
        icon: Icons.play_arrow_rounded,
        expand: true,
        onPressed: () => ref.read(processingProvider.notifier).start(batch.id),
      );
    }
    if (c.images > 0 && c.confirmed == c.images - c.failed && c.confirmed > 0) {
      return GradientButton(
        label: 'Next: Export',
        trailing: Icons.arrow_forward_rounded,
        expand: true,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ExportScreen(courseIds: [batch.course.id])),
        ),
      );
    }
    return GradientButton(
      label: reading ? 'Reading…' : 'Add photos to begin',
      expand: true,
      onPressed: null,
    );
  }

  String _processingHint(BatchCounts c, bool reading, bool noReader) {
    if (c.images == 0) return 'Add photos above to begin.';
    if (reading) return 'Finding the printed labels and the booklet number in each photo.';
    if (c.queued > 0) return '${c.queued} ${c.queued == 1 ? 'photo is' : 'photos are'} waiting to be read.';
    if (noReader) {
      return 'Automatic reading is not available on this device. Enter each booklet from its photo.';
    }
    if (c.needsReview > 0) {
      return 'Reading finished. ${c.needsReview} ${c.needsReview == 1 ? 'booklet is' : 'booklets are'} waiting for you to check.';
    }
    if (c.failed > 0) return '${c.failed} ${c.failed == 1 ? 'photo' : 'photos'} could not be used.';
    return 'Everything in this upload is confirmed.';
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, ScanItem s) async {
    final repo = ref.read(scanRepositoryProvider);
    await repo.remove(s.id);
    if (context.mounted) showUndo(context, '${s.displayName} removed', () => repo.restore(s.id));
  }

  void _openReview(BuildContext context, String scanId, List<ScanItem> all) {
    final queue = [for (final s in all) if (s.status == ScanStatus.needsReview) s.id];
    if (!queue.contains(scanId)) queue.insert(0, scanId);
    Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(scanId: scanId, queue: queue)));
  }

  void _showHelp(BuildContext context) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('How Scan & Extract works'),
          content: const SingleChildScrollView(
            child: Text(
              '1. Add photos of the booklet covers.\n\n'
              '2. UniMarkLy finds the printed labels and the booklet number in each photo. It does not yet read '
              'handwriting, so the exam number and the marks are not filled in for you.\n\n'
              '3. Review: each photo is shown next to the fields. Type the exam number and the marks you see. '
              'The exam number is matched against your class list.\n\n'
              '4. Confirm. The exam score goes into the score grid, ready to export.\n\n'
              'Nothing counts as a result until you confirm it, and the original photos are never changed.',
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it'))],
        ),
      );
}

class _Steps extends StatelessWidget {
  const _Steps({required this.current});

  final int current;

  static const _labels = ['Upload Images', 'Processing', 'Review & Edit', 'Save Records', 'Export'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Step ${current + 1} of 5: ${_labels[current]}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _labels.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Container(height: 2, color: i == 0 ? Colors.transparent : (i <= current ? scheme.primary : scheme.outlineVariant))),
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i <= current ? scheme.primary : Colors.transparent,
                          border: Border.all(color: i <= current ? scheme.primary : scheme.outline),
                        ),
                        child: i < current
                            ? Icon(Icons.check_rounded, size: 20, color: scheme.onPrimary)
                            : Text('${i + 1}',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: i == current ? scheme.onPrimary : scheme.onSurfaceVariant)),
                      ),
                      Expanded(
                          child: Container(
                              height: 2,
                              color: i == _labels.length - 1 ? Colors.transparent : (i < current ? scheme.primary : scheme.outlineVariant))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _labels[i],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: i == current ? scheme.primary : scheme.onSurfaceVariant,
                          fontWeight: i == current ? FontWeight.w700 : FontWeight.w400,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddMore extends StatelessWidget {
  const _AddMore({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Add more photos',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 104,
          height: 128,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outline),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline_rounded, size: 34, color: scheme.primary),
              const SizedBox(height: 6),
              Text('Add More', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressRow extends ConsumerWidget {
  const _ProgressRow({required this.counts, required this.batchId, required this.reading, required this.processing});

  final BatchCounts counts;
  final String batchId;
  final bool reading;
  final ProcessingState processing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    // Real progress: photos that are no longer waiting or being read.
    final finished = counts.images - counts.queued - counts.processing;
    final value = counts.images == 0 ? 0.0 : finished / counts.images;
    final pct = (value * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: value, minHeight: 10, backgroundColor: scheme.outlineVariant),
              ),
            ),
            if (reading) ...[
              const SizedBox(width: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(48, 44)),
                onPressed: processing.paused ? null : () => ref.read(processingProvider.notifier).pause(),
                icon: const Icon(Icons.pause_rounded),
                label: Text(processing.paused ? 'Pausing…' : 'Pause'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text('$finished / ${counts.images} completed ($pct%)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
      ],
    );
  }
}

class _ScanStatusTile extends StatelessWidget {
  const _ScanStatusTile({required this.scan});

  final ScanItem scan;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 240),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(scan.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          StatusChip.forScan(scan.status),
          if (scan.status == ScanStatus.failed && scan.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(scan.errorMessage!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.danger)),
            ),
        ],
      ),
    );
  }
}
