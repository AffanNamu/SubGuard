import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../domain/models.dart';
import '../../domain/scheme.dart';
import '../../providers/providers.dart';
import '../setup/course_setup_screen.dart';
import 'course_screen.dart';

class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  Future<void> _create(BuildContext context) async {
    final id = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CourseSetupScreen()),
    );
    if (id != null && context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => CourseScreen(courseId: id)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(coursesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset(
                'assets/icon/logo.png',
                width: 34,
                height: 34,
                cacheWidth: 102,
                semanticLabel: 'UniMarkLy logo',
              ),
            ),
            const SizedBox(width: 12),
            const Text('UniMarkLy'),
          ],
        ),
      ),
      floatingActionButton: courses.valueOrNull?.isNotEmpty == true
          ? FloatingActionButton.extended(
              onPressed: () => _create(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New course'),
            )
          : null,
      body: courses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: 'The courses could not be loaded.',
          onRetry: () => ref.invalidate(coursesProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.menu_book_rounded,
              title: 'No courses yet',
              message:
                  'Create a course, add its class list, then type in the scores. UniMarkLy adds up the totals and grades for you.',
              actionLabel: 'Create your first course',
              onAction: () => _create(context),
            );
          }
          return ContentWidth(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 104),
              itemCount: list.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                if (i == list.length) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: InfoBanner(
                      message: 'Your courses and scores are saved on this phone and work with no internet.',
                      icon: Icons.phone_android_rounded,
                    ),
                  );
                }
                return _CourseCard(course: list[i]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _CourseCard extends ConsumerWidget {
  const _CourseCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final c = context.colors;
    final grid = ref.watch(gridProvider(course.id)).valueOrNull;
    final stats = grid?.stats;

    final meta = [
      if (course.session.isNotEmpty) course.session,
      if (course.semester.isNotEmpty) '${course.semester} semester',
    ].join(' · ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CourseScreen(courseId: course.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(course.title, style: text.titleLarge),
                        if (meta.isNotEmpty)
                          Text(meta, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'More for ${course.title}',
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (v) async {
                      if (v == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CourseSetupScreen(existing: course)),
                        );
                      } else if (v == 'bin') {
                        await ref.read(courseRepositoryProvider).softDelete(course.id);
                        if (context.mounted) {
                          showUndo(context, '${course.title} moved to the bin',
                              () => ref.read(courseRepositoryProvider).restore(course.id));
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Change marks and grades')),
                      PopupMenuItem(value: 'bin', child: Text('Move to the bin')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(schemeSummary(course.scheme),
                    style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
              ),
              if (stats != null) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: stats.students == 0 ? 0 : stats.progress,
                      minHeight: 8,
                      backgroundColor: scheme.outlineVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      _Stat(Icons.groups_rounded, '${stats.students} students', scheme.onSurfaceVariant),
                      _Stat(Icons.check_circle_rounded, '${stats.complete} complete', c.success),
                      if (stats.flagged > 0)
                        _Stat(Icons.flag_rounded, '${stats.flagged} to check', c.warning),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.label, this.color);

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 6),
          // Flexible, so a large text size wraps instead of overflowing.
          Flexible(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      );
}
