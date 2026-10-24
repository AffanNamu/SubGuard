import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/ocr.dart';
import '../../domain/scan.dart';
import '../../providers/providers.dart';

/// The stored photo, decoded at the size it is shown, so a batch of hundreds
/// never holds hundreds of full-size images in memory.
class ScanImage extends ConsumerWidget {
  const ScanImage({
    super.key,
    required this.relativePath,
    this.fit = BoxFit.cover,
    this.cacheWidth = 360,
    this.alignment = Alignment.center,
  });

  final String relativePath;
  final BoxFit fit;
  final int cacheWidth;
  final Alignment alignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.watch(scanFilesProvider).resolve(relativePath);
    return Image.file(
      file,
      fit: fit,
      alignment: alignment,
      cacheWidth: cacheWidth,
      gaplessPlayback: true,
      errorBuilder: (context, error, stack) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        alignment: Alignment.center,
        child: Icon(Icons.broken_image_outlined, color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}

/// Shows one [region] of a stored photo, filling the width given, so the
/// examiner sees just the exam number or just the marks column beside the
/// field they are filling in. The photo itself is never cut or changed.
class RegionView extends ConsumerWidget {
  const RegionView({
    super.key,
    required this.relativePath,
    required this.region,
    required this.photoWidth,
    required this.photoHeight,
    this.maxHeight = 220,
    this.onTap,
  });

  final String relativePath;
  final Region region;
  final int photoWidth;
  final int photoHeight;
  final double maxHeight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.watch(scanFilesProvider).resolve(relativePath);
    return LayoutBuilder(builder: (context, box) {
      final regionAspect = (region.width * photoWidth) / (region.height * photoHeight);
      var w = box.maxWidth;
      var h = w / regionAspect;
      if (h > maxHeight) {
        h = maxHeight;
        w = h * regionAspect;
      }
      // The whole photo is scaled so that the region fills (w, h).
      final fullW = w / region.width;
      final fullH = h / region.height;
      final decode = (fullW.clamp(200, 2400)).round();
      return Center(
        child: GestureDetector(
          onTap: onTap,
          child: Semantics(
            label: 'Part of the photo. Tap to see the whole photo.',
            image: true,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: w,
                height: h,
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: fullW,
                  maxWidth: fullW,
                  minHeight: fullH,
                  maxHeight: fullH,
                  child: Transform.translate(
                    offset: Offset(-region.left * fullW, -region.top * fullH),
                    child: Image.file(file, width: fullW, height: fullH, fit: BoxFit.fill, cacheWidth: decode),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// A thumbnail with its status in the corner, and a remove button when it can
/// still be removed.
class ScanThumb extends StatelessWidget {
  const ScanThumb({super.key, required this.scan, this.onTap, this.onRemove, this.selected = false});

  final ScanItem scan;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = context.colors;
    final (badgeColor, badgeIcon) = switch (scan.status) {
      ScanStatus.confirmed => (c.success, Icons.check_rounded),
      ScanStatus.needsReview => (c.warning, Icons.priority_high_rounded),
      ScanStatus.failed => (c.danger, Icons.close_rounded),
      ScanStatus.processing => (c.info, Icons.sync_rounded),
      ScanStatus.queued => (scheme.outline, Icons.hourglass_empty_rounded),
    };
    return Semantics(
      button: onTap != null,
      label: '${scan.displayName}, ${StatusLabel.of(scan.status)}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 104,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 104,
                    height: 128,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? scheme.primary : scheme.outlineVariant,
                        width: selected ? 2.5 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Consumer(builder: (context, ref, _) => ScanImage(relativePath: scan.relativePath, cacheWidth: 260)),
                    ),
                  ),
                  Positioned(
                    right: -6,
                    bottom: -6,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 2),
                      ),
                      child: scan.status == ScanStatus.processing
                          ? const Padding(
                              padding: EdgeInsets.all(5),
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : Icon(badgeIcon, size: 16, color: Colors.white),
                    ),
                  ),
                  if (onRemove != null)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Semantics(
                        button: true,
                        label: 'Remove ${scan.displayName}',
                        child: GestureDetector(
                          onTap: onRemove,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                              border: Border.all(color: scheme.outline),
                            ),
                            child: const Icon(Icons.close_rounded, size: 16),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(scan.displayName,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Plain-words names for statuses, for screen readers and messages.
class StatusLabel {
  const StatusLabel._();

  static String of(ScanStatus s) => switch (s) {
        ScanStatus.queued => 'waiting to be read',
        ScanStatus.processing => 'being read',
        ScanStatus.needsReview => 'needs review',
        ScanStatus.confirmed => 'confirmed',
        ScanStatus.failed => 'could not be used',
      };
}
