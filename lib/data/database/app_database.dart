import 'package:drift/drift.dart';

import '../../domain/ids.dart';
import 'migrations.dart';
import 'tables.dart';

part 'app_database.g.dart';

const int latestSchemaVersion = 1;

@DriftDatabase(tables: [
  Courses,
  CourseParts,
  ExamQuestions,
  GradeScales,
  SchemeTemplates,
  Students,
  Scans,
  Booklets,
  QuestionMarks,
  RowReads,
  PartScores,
  Corrections,
  Accounts,
  SyncStates,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => latestSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) => runMigrations(m, from, to),
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
