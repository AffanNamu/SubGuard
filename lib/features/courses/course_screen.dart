import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../domain/scheme.dart';
import '../../providers/providers.dart';
import '../export/export_screen.dart';
import '../roster/roster_screen.dart';
import '../scores/score_grid_screen.dart';
import '../setup/course_setup_screen.dart';

/// One course at a glance: how far along it is, what needs attention, and
/// where to go next.
class CourseScreen extends ConsumerWidget {
  const CourseScreen({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grid = ref.watch(gridProvider(courseId));

    return grid.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: const ErrorState(message: 'This course could not be opened. It may have been moved to the bin.'),
      ),
      data: (data) => _Dashboard(data: data),
    );
  }
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard({required this.data});

  final GridData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = data.course;
    final stats = data.stats;
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

    void open(Widget page) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));

    final meta = [
      if (course.session.isNotEmpty) course.session,
      if (course.semester.isNotEmpty) '${course.semester} semester',
    ].join(' · ');
    final warnings = course.scheme.warnings();
    final attention = data.rows.where((r) => r.needsAttention).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(course.title),
        actions: [
          IconButton(
            tooltip: 'Course setup',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => open(CourseSetupScreen(existing: course)),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (v) async {
              if (v != 'bin') return;
              final ok = await confirm(
                context,
                title: 'Move ${course.title} to the bin?',
                message: 'Its class list and scores are kept, and you can bring it back from Settings.',
                confirmLabel: 'Move to bin',
                destructive: true,
              );
              if (!ok || !context.mounted) return;
              final repo = ref.read(courseRepositoryProvider);
              await repo.softDelete(course.id);
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            itemBuilder: (_) => const [PopupMenuItem(value: 'bin', child: Text('Move to the bin'))],
          ),
        ],
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            if (meta.isNotEmpty) Text(meta, style: muted),
            const SizedBox(height: 4),
            Text(schemeSummary(course.scheme), style: text.titleMedium),
            if (warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              InfoBanner(
                message: warnings.first.message,
                kind: BannerKind.warning,
                action: 'Review setup',
                onAction: () => open(CourseSetupScreen(existing: course)),
              ),
            ],
            const SizedBox(height: 16),
            if (stats.students == 0)
              InfoBanner(
                message: 'Start by adding the class list. Paste it, or import a CSV or Excel file.',
                icon: Icons.group_add_rounded,
                action: 'Add the class list',
                onAction: () => open(RosterScreen(courseId: course.id)),
              )
            else
              StatGrid(
                tiles: [
                  StatTile(
                    icon: Icons.groups_rounded,
                    color: c.tileBlue,
                    value: '${stats.students}',
                    label: 'Students',
                    onTap: () => open(RosterScreen(courseId: course.id)),
                  ),
                  StatTile(
                    icon: Icons.task_alt_rounded,
                    color: c.tileGreen,
                    value: '${stats.complete}',
                    label: 'Complete',
                    onTap: () => open(ScoreGridScreen(courseId: course.id)),
                  ),
                  StatTile(
                    icon: Icons.edit_note_rounded,
                    color: c.tilePurple,
                    value: '${stats.started + stats.notStarted}',
                    label: 'Still to enter',
                    onTap: () => open(ScoreGridScreen(courseId: course.id, initialFilter: GridFilter.incomplete)),
                  ),
                  StatTile(
                    icon: Icons.flag_rounded,
                    color: c.tileAmber,
                    value: '${stats.flagged}',
                    label: 'Need attention',
                    onTap: () => open(ScoreGridScreen(courseId: course.id, initialFilter: GridFilter.flagged)),
                  ),
                ],
              ),
            const SectionHeading('What would you like to do?'),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  NavTile(
                    icon: Icons.grid_on_rounded,
                    color: c.tileGreen,
                    title: 'Enter scores',
                    subtitle: 'Type marks. Totals and grades add up as you go.',
                    onTap: () => open(ScoreGridScreen(courseId: course.id)),
                  ),
                  const Divider(indent: 76),
                  NavTile(
                    icon: Icons.groups_rounded,
                    color: c.tileBlue,
                    title: 'Class list',
                    subtitle: stats.students == 0 ? 'No students yet' : '${stats.students} students',
                    onTap: () => open(RosterScreen(courseId: course.id)),
                  ),
                  const Divider(indent: 76),
                  NavTile(
                    icon: Icons.ios_share_rounded,
                    color: c.tilePurple,
                    title: 'Export',
                    subtitle: 'Word, Excel, PDF or CSV',
                    onTap: () => open(ExportScreen(courseIds: [course.id])),
                  ),
                  const Divider(indent: 76),
                  NavTile(
                    icon: Icons.tune_rounded,
                    color: c.tileAmber,
                    title: 'Marks and grades',
                    subtitle: 'Parts, exam paper and grade scale',
                    onTap: () => open(CourseSetupScreen(existing: course)),
                  ),
                ],
              ),
            ),
            if (attention.isNotEmpty) ...[
              SectionHeading(
                'Needs attention',
                trailing: TextButton(
                  onPressed: () => open(ScoreGridScreen(courseId: course.id, initialFilter: GridFilter.flagged)),
                  child: const Text('See all'),
                ),
              ),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < attention.take(5).length; i++) ...[
                      if (i > 0) const Divider(),
                      ListTile(
                        minTileHeight: 64,
                        onTap: () => open(ScoreGridScreen(
                          courseId: course.id,
                          initialFilter: GridFilter.flagged,
                        )),
                        leading: Icon(Icons.flag_rounded, color: c.warning),
                        title: Text(attention[i].student.regNo),
                        subtitle: Text(attention[i].flags.firstWhere((f) => f.needsAttention).message),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
