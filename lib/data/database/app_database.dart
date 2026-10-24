import 'package:drift/drift.dart';

import '../../domain/ids.dart';
import 'schema_versions.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// Version 1: the original fourteen tables.
/// Version 2: batches, and the intake columns on scans.
/// Version 3: recognition runs and field reviews (the examiner's decisions).
///
/// To change the schema:
///  1. Edit `tables.dart` and bump this number.
///  2. Run `tool/generate_schema.sh`. It dumps the new version to `drift_schemas/`
///     and regenerates `schema_versions.dart` and the test helpers.
///  3. Add the `fromNToN+1` step below. Never edit an older step: phones in the
///     field have already run it.
///  4. Add a test in `test/data/migration_test.dart` that opens the old version
///     with data in it and checks the data survives.
const int latestSchemaVersion = 3;

@DriftDatabase(tables: [
  Courses,
  CourseParts,
  ExamQuestions,
  GradeScales,
  SchemeTemplates,
  Students,
  Batches,
  Scans,
  Booklets,
  QuestionMarks,
  RowReads,
  PartScores,
  Corrections,
  RecognitionRuns,
  FieldReviews,
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
        onUpgrade: stepByStep(
          from1To2: (m, schema) async {
            await m.createTable(schema.uploadBatch);
            await m.addColumn(schema.scan, schema.scan.batchId);
            await m.addColumn(schema.scan, schema.scan.originalName);
            await m.addColumn(schema.scan, schema.scan.contentHash);
            await m.addColumn(schema.scan, schema.scan.width);
            await m.addColumn(schema.scan, schema.scan.height);
            await m.addColumn(schema.scan, schema.scan.errorMessage);
            await m.addColumn(schema.correction, schema.correction.region);
            await m.createIndex(schema.scanBatch);
            await m.createIndex(schema.scanHash);
            await m.createIndex(schema.uploadBatchCourse);
          },
          from2To3: (m, schema) async {
            // Two new tables; no existing table or row is touched.
            await m.createTable(schema.recognitionRun);
            await m.createTable(schema.fieldReview);
            await m.createIndex(schema.recognitionRunScan);
            await m.createIndex(schema.fieldReviewScan);
          },
        ),
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
