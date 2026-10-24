import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_shell.dart';
import 'features/incoming/incoming_controller.dart';
import 'providers/providers.dart';

class UniMarkLyApp extends ConsumerWidget {
  const UniMarkLyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(settingsProvider.select((s) => s.themeMode));
    return MaterialApp(
      title: 'UniMarkLy',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      builder: (context, child) => IncomingOverlay(child: child),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      home: const HomeShell(),
    );
  }
}
