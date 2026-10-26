import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/ui_kit.dart';
import '../../domain/ocr.dart';
import '../../domain/recognition.dart';
import '../../providers/providers.dart';
import '../../services/recognition/orientation.dart';
import '../../services/vision/quality.dart';

/// How much a machine reading can be relied on, in words an examiner uses.
class FieldStateChip extends StatelessWidget {
  const FieldStateChip(this.state, {super.key, this.confirmed = false});

  final FieldState state;

  /// The examiner has confirmed the value; the machine's state no longer matters.
  final bool confirmed;

  static String labelOf(FieldState s) => switch (s) {
        FieldState.recognized => 'Read',
        FieldState.needsReview => 'Check this',
        FieldState.unreadable => 'Not readable',
        FieldState.failed => 'Reading failed',
      };

  @override
  Widget build(BuildContext context) {
    if (confirmed) return const StatusChip(kind: ChipKind.completed, label: 'Confirmed by you');
    return StatusChip(
      kind: switch (state) {
        FieldState.recognized => ChipKind.completed,
        FieldState.needsReview => ChipKind.needsReview,
        FieldState.unreadable => ChipKind.partial,
        FieldState.failed => ChipKind.failed,
      },
      label: labelOf(state),
    );
  }
}

/// What is wrong with the picture, and what to do about it. A photo that cannot
/// be read says to retake it; a recoverable fault says what it will cost.
class QualityNotice extends StatelessWidget {
  const QualityNotice(this.report, {super.key});

  final QualityReport report;

  @override
  Widget build(BuildContext context) {
    final issues = [for (final i in report.issues) if (i.severity != QualitySeverity.info) i]
      ..sort((a, b) => b.severity.index.compareTo(a.severity.index));
    if (issues.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final i in issues.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InfoBanner(
              message: '${i.message} ${i.advice}',
              kind: i.severity == QualitySeverity.blocking ? BannerKind.danger : BannerKind.warning,
              icon: Icons.photo_camera_back_outlined,
            ),
          ),
      ],
    );
  }
}

/// The readings a field could be, as buttons. Tapping one puts it in the field;
/// nothing is chosen for the examiner. Each says where it came from, because a
/// number taken from the class list is not the same as one read from the photo.
class CandidateChips extends StatelessWidget {
  const CandidateChips({super.key, required this.candidates, required this.onUse, this.max = 3});

  final List<FieldCandidate> candidates;
  final void Function(FieldCandidate) onUse;
  final int max;

  static String sourceLabel(FieldCandidate c) =>
      c.source.startsWith('class_list') ? 'from the class list' : 'read from the photo';

  @override
  Widget build(BuildContext context) {
    if (candidates.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final c in candidates.take(max))
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: 'Use ${c.text}, ${sourceLabel(c)}',
                  excludeSemantics: true,
                  child: ActionChip(label: Text(c.text), onPressed: () => onUse(c)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${sourceLabel(c)}${c.note == null ? '' : ' · ${c.note}'}',
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Every attempt that went into a field: who read it, on which picture, what
/// they saw and how sure they were. For the examiner who wants to know why.
class EvidenceTile extends StatelessWidget {
  const EvidenceTile(this.field, {super.key});

  final ExtractedField field;

  @override
  Widget build(BuildContext context) {
    if (field.attempts.isEmpty && field.warnings.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        dense: true,
        title: Text('How this was read', style: text.bodyMedium?.copyWith(color: muted)),
        children: [
          for (final a in field.attempts)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${a.reader} · ${a.variant.replaceAll('_', ' ')}: ${a.text == null || a.text!.isEmpty ? 'nothing read' : '"${a.text}"'}'
                  '${a.confidence == null ? '' : ' (${(a.confidence! * 100).round()}%)'}',
                  style: text.bodySmall?.copyWith(color: muted),
                ),
              ),
            ),
          for (final w in field.warnings)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(w, style: text.bodySmall?.copyWith(color: muted))),
            ),
        ],
      ),
    );
  }
}

/// The whole photo, zoomable, with [highlight] (a field's place on it) outlined
/// and brought into view. The photo itself is never changed.
class PhotoViewerScreen extends ConsumerStatefulWidget {
  const PhotoViewerScreen({
    super.key,
    required this.relativePath,
    required this.title,
    this.highlight,
    this.photoWidth,
    this.photoHeight,
    this.label,
    this.turnedQuarters = 0,
  });

  final String relativePath;
  final String title;

  /// Where the outlined part is on the photo, in the photo's own fractions
  /// (whatever [turnedQuarters] is).
  final Region? highlight;
  final int? photoWidth;
  final int? photoHeight;

  /// Show the photo turned clockwise by this many quarter-turns, so a booklet
  /// that was photographed sideways or upside down is shown upright. The file is
  /// never changed.
  final int turnedQuarters;

  /// What the outlined part is ("Mark, row 2").
  final String? label;

  @override
  ConsumerState<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends ConsumerState<PhotoViewerScreen> {
  final _controller = TransformationController();
  bool _placed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Zooms so the highlighted part fills about two thirds of the screen.
  void _placeOn(Region r, Size view, Size shown) {
    if (_placed) return;
    _placed = true;
    final scale = (0.66 / math.max(r.width, r.height)).clamp(1.0, 8.0);
    final dx = (view.width - shown.width) / 2, dy = (view.height - shown.height) / 2;
    final cx = dx + r.centerX * shown.width, cy = dy + r.centerY * shown.height;
    // Move the region's centre to the middle of the screen, then magnify about it.
    final m = Matrix4.identity()
      ..translateByDouble(view.width / 2, view.height / 2, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-cx, -cy, 0, 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.value = m;
    });
  }

  @override
  Widget build(BuildContext context) {
    final file = ref.watch(scanFilesProvider).resolve(widget.relativePath);
    final w = widget.photoWidth, h = widget.photoHeight;
    final turns = widget.turnedQuarters % 4;
    final photoAspect = (w != null && h != null && h > 0) ? w / h : null;
    // Turned a quarter either way, the shown picture is as wide as the photo is high.
    final aspect = photoAspect == null ? null : (turns.isOdd ? 1 / photoAspect : photoAspect);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Back to the whole photo',
            icon: const Icon(Icons.zoom_out_map_rounded),
            onPressed: () => _controller.value = Matrix4.identity(),
          ),
        ],
      ),
      body: LayoutBuilder(builder: (context, box) {
        final view = Size(box.maxWidth, box.maxHeight);
        // The photo is shown to fit (contain), centred; work out its size.
        Size shown = view;
        if (aspect != null) {
          shown = view.width / view.height > aspect ? Size(view.height * aspect, view.height) : Size(view.width, view.width / aspect);
        }
        final hl = widget.highlight == null ? null : PageOrientation.turn(widget.highlight!, turns);
        if (hl != null && aspect != null) _placeOn(hl, view, shown);
        return Stack(
          children: [
            InteractiveViewer(
              transformationController: _controller,
              minScale: 1,
              maxScale: 10,
              child: SizedBox(
                width: view.width,
                height: view.height,
                child: Center(
                  child: SizedBox(
                    width: shown.width,
                    height: shown.height,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (turns == 0)
                          Image.file(file, fit: BoxFit.fill, cacheWidth: 2400, gaplessPlayback: true)
                        else
                          RotatedBox(quarterTurns: turns, child: Image.file(file, fit: BoxFit.fill, cacheWidth: 2400, gaplessPlayback: true)),
                        if (hl != null)
                          Positioned(
                            left: hl.left * shown.width,
                            top: hl.top * shown.height,
                            width: hl.width * shown.width,
                            height: hl.height * shown.height,
                            child: IgnorePointer(
                              child: Semantics(
                                label: widget.label == null ? 'Highlighted part of the photo' : 'Highlighted: ${widget.label}',
                                child: Container(
                                  decoration: BoxDecoration(border: Border.all(color: Brand.lime, width: 2), borderRadius: BorderRadius.circular(4)),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (widget.label != null && hl != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
                  child: Text('Outlined: ${widget.label}. Pinch to zoom.', style: const TextStyle(color: Colors.white)),
                ),
              ),
          ],
        );
      }),
    );
  }

}
