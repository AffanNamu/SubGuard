import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/ui_kit.dart';
import '../../domain/models.dart';
import '../../domain/scan.dart';
import '../../providers/providers.dart';
import '../scan/review_screen.dart';
import '../scan/scan_widgets.dart';
import 'batch_card.dart';
import 'home_actions.dart';

/// The courses that have at least one upload, for the filter.
List<Course> coursesOf(List<BatchSummary> batches) {
  final seen = <String>{};
  return [
    for (final b in batches)
      if (seen.add(b.course.id)) b.course,
  ];
}

/// "All courses" or one course. Hidden when there is nothing to choose.
class CourseFilter extends StatelessWidget {
  const CourseFilter({
    super.key,
    required this.courses,
    required this.selected,
    required this.onChanged,
  });

  final List<Course> courses;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (courses.length < 2) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final value = courses.any((c) => c.id == selected) ? selected : null;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            value: value,
            isExpanded: true,
            isDense: true,
            itemHeight: 48,
            borderRadius: BorderRadius.circular(14),
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            items: [
              const DropdownMenuItem(value: null, child: Text('All courses')),
              for (final c in courses)
                DropdownMenuItem(
                  value: c.id,
                  child: Text(c.code, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

/// Every upload, newest first, with a course filter.
class BatchesScreen extends ConsumerStatefulWidget {
  const BatchesScreen({super.key});

  @override
  ConsumerState<BatchesScreen> createState() => _BatchesScreenState();
}

class _BatchesScreenState extends ConsumerState<BatchesScreen> {
  String? _course;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(batchesProvider);
    final all = async.valueOrNull ?? const <BatchSummary>[];
    final shown = [
      for (final b in all)
        if (_course == null || b.course.id == _course) b,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Recent batches')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: 'The uploads could not be loaded.',
          onRetry: () => ref.invalidate(batchesProvider),
        ),
        data: (_) => all.isEmpty
            ? const EmptyState(
                icon: Icons.photo_library_outlined,
                title: 'No uploads yet',
                message: 'Photos you upload appear here with their progress.',
              )
            : ContentWidth(
                maxWidth: 760,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CourseFilter(
                        courses: coursesOf(all),
                        selected: _course,
                        onChanged: (v) => setState(() => _course = v),
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final b in shown) ...[
                      BatchCard(batch: b),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

/// Booklets waiting for the examiner, oldest first, across every upload.
class ReviewQueueScreen extends ConsumerWidget {
  const ReviewQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reviewQueueProvider);
    final courses = {
      for (final c
          in ref.watch(coursesProvider).valueOrNull ?? const <Course>[])
        c.id: c,
    };
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Review results')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: 'The booklets could not be loaded.',
          onRetry: () => ref.invalidate(reviewQueueProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.task_alt_rounded,
              title: 'Nothing to review',
              message:
                  'Booklets that need checking will wait here. Upload photos to begin.',
            );
          }
          final queue = [for (final s in items) s.id];
          return ContentWidth(
            maxWidth: 760,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '${items.length} ${items.length == 1 ? 'booklet needs' : 'booklets need'} checking against the photo.',
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                for (final s in items) ...[
                  GlowCard(
                    padding: const EdgeInsets.all(12),
                    semanticLabel:
                        '${s.displayName}, ${courses[s.courseId]?.code ?? ''}. Need review',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ReviewScreen(scanId: s.id, queue: queue),
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 60,
                            height: 60,
                            child: ScanImage(
                              relativePath: s.relativePath,
                              cacheWidth: 180,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.titleMedium,
                              ),
                              Text(
                                '${courses[s.courseId]?.code ?? 'Course'} · ${shortDate(s.createdAt)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              // Why it is waiting, so the ones that need the
                              // most care can be seen at a glance.
                              Consumer(builder: (context, ref, _) {
                                final why = ref.watch(attentionProvider(s.id)).valueOrNull;
                                if (why == null) return const SizedBox.shrink();
                                return Text(
                                  why,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.bodySmall?.copyWith(color: context.colors.warning),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip.forScan(s.status),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
