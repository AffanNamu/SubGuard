import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/ui_kit.dart';
import '../../domain/scan.dart';
import '../../providers/providers.dart';
import '../scan/upload_flow.dart';
import 'batch_card.dart';
import 'batches_screen.dart';
import 'home_actions.dart';

/// The places the home screen can send the examiner to in the bottom bar.
enum HomeTab { home, courses, exports, settings }

/// Home: welcome, the one thing to do next, shortcuts, real numbers counted
/// from stored uploads, and the latest uploads.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.onOpenTab});

  final ValueChanged<HomeTab> onOpenTab;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _shown = 4;
  String? _course;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final stats = ref.watch(scanStatsProvider);
    final batchesAsync = ref.watch(batchesProvider);
    final all = batchesAsync.valueOrNull ?? const <BatchSummary>[];
    final filtered = [
      for (final b in all)
        if (_course == null || b.course.id == _course) b,
    ];
    final examiner = ref.watch(settingsProvider.select((s) => s.header.examiner)).trim();

    void openReview() => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewQueueScreen()));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ContentWidth(
          maxWidth: 760,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _Header(
                needReview: stats.needReview,
                initials: initialsOf(examiner),
                onBell: openReview,
                onAvatar: () => widget.onOpenTab(HomeTab.settings),
              ),
              const SizedBox(height: 16),
              _Hero(name: examiner),
              const SizedBox(height: 16),
              TileRow(children: [
                HomeTile(
                  icon: Icons.document_scanner_rounded,
                  color: c.tileBlue,
                  title: 'Scan & Extract',
                  subtitle: 'Add booklet photos and read them',
                  onTap: () => startUpload(context, ref),
                ),
                HomeTile(
                  icon: Icons.fact_check_rounded,
                  color: c.tileGreen,
                  title: 'Review Results',
                  subtitle: stats.needReview == 0 ? 'Nothing waiting' : 'Check booklets against photos',
                  badge: stats.needReview,
                  onTap: openReview,
                ),
              ]),
              const SizedBox(height: 12),
              TileRow(children: [
                HomeTile(
                  icon: Icons.ios_share_rounded,
                  color: c.tilePurple,
                  title: 'Export File',
                  subtitle: 'Word, Excel, PDF or CSV',
                  onTap: () => widget.onOpenTab(HomeTab.exports),
                ),
                HomeTile(
                  icon: Icons.menu_book_rounded,
                  color: c.tileAmber,
                  title: 'Manage Courses',
                  subtitle: 'Classes, schemes and scores',
                  onTap: () => widget.onOpenTab(HomeTab.courses),
                ),
              ]),
              const SizedBox(height: 22),
              Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              _StatsGrid(stats: stats),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(child: Text('Recent Batches', style: Theme.of(context).textTheme.titleLarge)),
                  if (all.length > _shown)
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BatchesScreen())),
                      child: const Text('View All'),
                    ),
                ],
              ),
              if (all.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: CourseFilter(
                      courses: coursesOf(all),
                      selected: _course,
                      onChanged: (v) => setState(() => _course = v),
                    ),
                  ),
                ),
              if (batchesAsync.hasError)
                ErrorState(message: 'The uploads could not be loaded.', onRetry: () => ref.invalidate(batchesProvider))
              else if (all.isEmpty && !batchesAsync.isLoading)
                const _NoBatches()
              else
                for (final b in filtered.take(_shown)) ...[BatchCard(batch: b), const SizedBox(height: 10)],
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.needReview, required this.initials, required this.onBell, required this.onAvatar});

  final int needReview;
  final String initials;
  final VoidCallback onBell;
  final VoidCallback onAvatar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Image.asset('assets/icon/logo.png', width: 40, height: 40, cacheWidth: 120, semanticLabel: 'UniMarkLy logo'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text('UniMarkLy',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        ),
        IconButton(
          tooltip: needReview == 0 ? 'Review queue' : 'Review queue, $needReview waiting',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: onBell,
          icon: Badge(
            isLabelVisible: needReview > 0,
            backgroundColor: context.colors.danger,
            smallSize: 10,
            child: const Icon(Icons.notifications_none_rounded, size: 28),
          ),
        ),
        Semantics(
          button: true,
          label: 'Settings',
          excludeSemantics: true,
          child: InkResponse(
            onTap: onAvatar,
            radius: 28,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: Brand.limeGradient),
                border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
              ),
              child: initials.isEmpty
                  ? const Icon(Icons.person_rounded, color: Color(0xFF0A1A05))
                  : Text(initials, style: text.titleMedium?.copyWith(color: const Color(0xFF0A1A05), fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ],
    );
  }
}

class _Hero extends ConsumerWidget {
  const _Hero({required this.name});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final c = context.colors;
    final big = MediaQuery.textScalerOf(context).scale(1) > 1.3;

    return GlowCard(
      tint: c.tileBlue,
      padding: const EdgeInsets.all(18),
      radius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Welcome back,' : 'Welcome back, ${name.split(RegExp(r'\s+')).first},',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text('Start Scanning\nExam Scripts',
                        style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.12)),
                    const SizedBox(height: 6),
                    Text('Upload booklet photos, check every mark against the photo, then export.',
                        style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              if (!big) ...[
                const SizedBox(width: 8),
                const ExcludeSemantics(child: SizedBox(width: 96, height: 120, child: CustomPaint(painter: HeroArtPainter()))),
              ],
            ],
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: 'Upload Exam Images',
            icon: Icons.cloud_upload_rounded,
            trailing: Icons.arrow_forward_rounded,
            expand: true,
            onPressed: () => startUpload(context, ref),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (context, box) {
            final stacked = box.maxWidth < 440;
            Widget pill(String label, IconData icon, UploadSource source) => PillButton(
                  label: label,
                  icon: icon,
                  stacked: stacked,
                  onPressed: () => startUpload(context, ref, source: source),
                );
            return Row(
              children: [
                Expanded(child: pill('Take Photo', Icons.photo_camera_outlined, UploadSource.camera)),
                const SizedBox(width: 8),
                Expanded(child: pill('Choose Images', Icons.photo_library_outlined, UploadSource.gallery)),
                const SizedBox(width: 8),
                Expanded(child: pill('Upload Many', Icons.upload_file_rounded, UploadSource.files)),
              ],
            );
          }),
        ],
      ),
    );
  }
}

/// A booklet being scanned: a tilted page with ruled lines, a lime frame and a
/// scan line. Drawn, not a photo, so no student's work is on the home screen.
class HeroArtPainter extends CustomPainter {
  const HeroArtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.save();
    canvas.translate(w * 0.5, h * 0.52);
    canvas.rotate(-8 * math.pi / 180);

    final page = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w * 0.78, height: h * 0.86), const Radius.circular(8));
    canvas.drawShadow(Path()..addRRect(page), Colors.black, 8, true);
    canvas.drawRRect(page, Paint()..color = const Color(0xFFF4F6FB));

    final ink = Paint()
      ..color = const Color(0xFF9AA7C4)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final left = -w * 0.3, right = w * 0.3;
    for (var i = 0; i < 6; i++) {
      final y = -h * 0.3 + i * h * 0.11;
      canvas.drawLine(Offset(left, y), Offset(i.isEven ? right : right - w * 0.18, y), ink);
    }
    // A mark in red, as an examiner writes.
    final red = Paint()
      ..color = const Color(0xFFE5484D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.1, h * 0.22)
        ..lineTo(w * 0.17, h * 0.29)
        ..lineTo(w * 0.28, h * 0.15),
      red,
    );
    canvas.restore();

    // Scan frame corners.
    final frame = Paint()
      ..color = Brand.lime
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final r = Rect.fromLTWH(w * 0.02, h * 0.04, w * 0.96, h * 0.92);
    final k = w * 0.2;
    for (final (corner, dx, dy) in [
      (r.topLeft, 1.0, 1.0),
      (r.topRight, -1.0, 1.0),
      (r.bottomLeft, 1.0, -1.0),
      (r.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(corner.dx + dx * k, corner.dy)
          ..lineTo(corner.dx, corner.dy)
          ..lineTo(corner.dx, corner.dy + dy * k),
        frame,
      );
    }
    // The scan line.
    final y = h * 0.5;
    canvas.drawLine(
      Offset(w * 0.0, y),
      Offset(w * 1.0, y),
      Paint()
        ..color = Brand.lime
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final ScanStats stats;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cards = [
      _StatCard(icon: Icons.folder_copy_rounded, color: c.tileBlue, value: stats.batches, label: 'Batches Scanned'),
      _StatCard(icon: Icons.groups_rounded, color: c.tilePurple, value: stats.records, label: 'Students Extracted'),
      _StatCard(icon: Icons.check_circle_rounded, color: c.tileGreen, value: stats.confirmed, label: 'Completed'),
      _StatCard(icon: Icons.warning_amber_rounded, color: c.tileAmber, value: stats.needReview, label: 'Need Review'),
    ];
    return LayoutBuilder(builder: (context, box) {
      final four = box.maxWidth >= 560 && MediaQuery.textScalerOf(context).scale(1) <= 1.2;
      if (four) {
        return TileRow(gap: 10, children: cards);
      }
      return Column(
        children: [
          TileRow(gap: 10, children: cards.sublist(0, 2)),
          const SizedBox(height: 10),
          TileRow(gap: 10, children: cards.sublist(2)),
        ],
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.color, required this.value, required this.label});

  final IconData icon;
  final Color color;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return GlowCard(
      tint: color,
      padding: const EdgeInsets.all(14),
      semanticLabel: '$label: $value',
      child: Row(
        children: [
          GradientIcon(icon: icon, color: color, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value', style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                Text(label, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, fontSize: 13.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoBatches extends ConsumerWidget {
  const _NoBatches();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return GlowCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(Icons.photo_library_outlined, size: 36, color: scheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No uploads yet', style: text.titleMedium),
                const SizedBox(height: 2),
                Text('Tap Upload Exam Images to add your first booklets. Photos stay on this phone.',
                    style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
