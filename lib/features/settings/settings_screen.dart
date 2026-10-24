import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../providers/providers.dart';
import 'bin_screen.dart';
import 'defaults_screen.dart';
import 'header_settings_screen.dart';
import 'templates_screen.dart';

/// Settings as one calm column: a few groups, each row with a plain-words
/// description, each opening its own full-width page. No side panels and no
/// tiny controls, so it reads the same on a small phone.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final info = ref.watch(packageInfoProvider).valueOrNull;
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    void open(Widget page) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            const SectionHeading('Look', padding: EdgeInsets.fromLTRB(4, 4, 4, 8)),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconBadge(icon: Icons.palette_rounded, color: c.tilePurple),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Appearance', style: text.titleMedium),
                              Text('Light, dark, or follow the phone',
                                  style: text.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                              value: ThemeMode.system,
                              icon: Icon(Icons.brightness_auto_rounded),
                              label: Text('Auto')),
                          ButtonSegment(
                              value: ThemeMode.light,
                              icon: Icon(Icons.light_mode_rounded),
                              label: Text('Light')),
                          ButtonSegment(
                              value: ThemeMode.dark,
                              icon: Icon(Icons.dark_mode_rounded),
                              label: Text('Dark')),
                        ],
                        selected: {settings.themeMode},
                        onSelectionChanged: (s) => ref
                            .read(settingsProvider.notifier)
                            .update((v) => v.copyWith(themeMode: s.first)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SectionHeading('Results'),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  NavTile(
                    icon: Icons.article_rounded,
                    color: c.tileBlue,
                    title: 'Document header',
                    subtitle: settings.header.isEmpty
                        ? 'University, faculty and examiner for exports'
                        : settings.header.lines().first,
                    onTap: () => open(const HeaderSettingsScreen()),
                  ),
                  const Divider(indent: 76),
                  NavTile(
                    icon: Icons.event_note_rounded,
                    color: c.tileGreen,
                    title: 'New course defaults',
                    subtitle: [
                      if (settings.defaultSession.isNotEmpty) settings.defaultSession,
                      if (settings.defaultSemester.isNotEmpty) settings.defaultSemester,
                    ].join(' · ').ifEmpty('Session and semester'),
                    onTap: () => open(const DefaultsScreen()),
                  ),
                  const Divider(indent: 76),
                  NavTile(
                    icon: Icons.bookmarks_rounded,
                    color: c.tileAmber,
                    title: 'Saved templates',
                    subtitle: 'Marks and grades you reuse',
                    onTap: () => open(const TemplatesScreen()),
                  ),
                ],
              ),
            ),
            const SectionHeading('Your data'),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  NavTile(
                    icon: Icons.delete_outline_rounded,
                    color: c.danger,
                    title: 'Bin',
                    subtitle: 'Bring back deleted courses',
                    onTap: () => open(const BinScreen()),
                  ),
                  const Divider(indent: 76),
                  const NavTile(
                    icon: Icons.phone_android_rounded,
                    color: Brand.blue,
                    title: 'Stored on this phone',
                    subtitle: 'Courses, students and scores work offline and stay on this phone.',
                  ),
                ],
              ),
            ),
            const SectionHeading('About'),
            Card(
              child: NavTile(
                icon: Icons.info_outline_rounded,
                color: c.info,
                title: 'UniMarkLy',
                subtitle: info == null ? 'Exam scores, added up for you' : 'Version ${info.version} (${info.buildNumber})',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
