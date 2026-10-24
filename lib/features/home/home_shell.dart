import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../courses/courses_screen.dart';
import '../export/exports_screen.dart';
import '../settings/settings_screen.dart';
import 'home_actions.dart';
import 'home_screen.dart';

/// Home, Courses, Exports and Settings, with the upload action raised in the
/// middle of the bar so adding photos is always one tap away.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  HomeTab _tab = HomeTab.home;

  @override
  void initState() {
    super.initState();
    // Photos left unread when the app was closed carry on being read.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(processingProvider.notifier).resumeAll();
    });
  }

  void _open(HomeTab tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(onOpenTab: _open),
      const CoursesScreen(),
      const ExportsScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab.index, children: pages),
      bottomNavigationBar: _BottomBar(
        selected: _tab,
        onSelect: _open,
        onUpload: () => startUpload(context, ref),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.selected, required this.onSelect, required this.onUpload});

  final HomeTab selected;
  final ValueChanged<HomeTab> onSelect;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    Widget item(HomeTab tab, IconData icon, IconData activeIcon, String label) {
      final on = selected == tab;
      final color = on ? scheme.primary : scheme.onSurfaceVariant;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          label: label,
          excludeSemantics: true,
          child: InkResponse(
            onTap: () => onSelect(tab),
            highlightShape: BoxShape.rectangle,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(on ? activeIcon : icon, color: color, size: 26),
                  const SizedBox(height: 2),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: color, fontWeight: on ? FontWeight.w800 : FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: scheme.surfaceContainer,
      shape: Border(top: BorderSide(color: scheme.outline.withValues(alpha: 0.35))),
      child: SafeArea(
        top: false,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Row(
              children: [
                item(HomeTab.home, Icons.home_outlined, Icons.home_rounded, 'Home'),
                item(HomeTab.courses, Icons.menu_book_outlined, Icons.menu_book_rounded, 'Courses'),
                // The raised button sits over this gap.
                const Expanded(child: SizedBox(height: 64)),
                item(HomeTab.exports, Icons.ios_share_outlined, Icons.ios_share_rounded, 'Exports'),
                item(HomeTab.settings, Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
              ],
            ),
            Positioned(
              top: -22,
              child: Semantics(
                button: true,
                label: 'Add exam images',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: onUpload,
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: Brand.limeGradient,
                      ),
                      border: Border.all(color: scheme.surfaceContainer, width: 4),
                      boxShadow: [BoxShadow(color: Brand.lime.withValues(alpha: dark ? 0.45 : 0.35), blurRadius: 18, offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Icons.add_a_photo_rounded, size: 28, color: Color(0xFF0A1A05)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
