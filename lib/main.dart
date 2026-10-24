import 'package:drift_flutter/drift_flutter.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/database/app_database.dart';
import 'providers/providers.dart';
import 'services/scan/scan_files.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The database is the source of truth and opens before the first frame, so
  // the app works the same with no internet.
  final db = AppDatabase(driftDatabase(name: 'unimarkly'));
  final prefs = await SharedPreferences.getInstance();
  final documents = await getApplicationDocumentsDirectory();
  final scanFiles = ScanFiles(Directory(p.join(documents.path, 'scans')));

  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
      scanFilesProvider.overrideWithValue(scanFiles),
    ],
    child: const UniMarkLyApp(),
  ));
}
