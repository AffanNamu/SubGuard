import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/data/database/app_database.dart';
import 'package:unimarkly/data/repositories/course_repository.dart';
import 'package:unimarkly/data/repositories/score_repository.dart';
import 'package:unimarkly/data/repositories/student_repository.dart';

import '../generated/schema.dart';

/// Migrations are tested against an old copy of the data: the schema dumped
/// at each released version lives in `drift_schemas/`, a database is built at
/// that version, filled with rows, then opened by the current code.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('the current code creates exactly the schema that was dumped for its version', () async {
    final connection = await verifier.startAt(latestSchemaVersion);
    final db = AppDatabase(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, latestSchemaVersion);
  });

  test('a version 1 database upgrades to the latest and keeps its data', () async {
    final schema = await verifier.schemaAt(1);

    // An "old copy of the data": written with plain SQL at schema v1.
    final raw = schema.rawDatabase;
    raw.execute("INSERT INTO course (id, updated_at, code, department, session, semester, total_expected, count_rule) "
        "VALUES ('c1', '2026-09-01T10:00:00.000Z', 'AGR 114', 'FWM', '2024/2025', 'First', 100, 'all')");
    raw.execute("INSERT INTO course_part (id, updated_at, course_id, name, max, min, step, source, sort_order) "
        "VALUES ('p1', '2026-09-01T10:00:00.000Z', 'c1', 'Exam', 70, 0, 0.5, 'scanned', 0)");
    raw.execute("INSERT INTO student (id, updated_at, course_id, reg_no, name, on_class_list, position) "
        "VALUES ('s1', '2026-09-01T10:00:00.000Z', 'c1', 'FWM/24U/0538', 'Ada', 1, 0)");
    raw.execute("INSERT INTO part_score (id, updated_at, course_id, student_id, part_id, value, status, source) "
        "VALUES ('x1', '2026-09-01T10:00:00.000Z', 'c1', 's1', 'p1', 9.5, 'entered', 'typed')");
    // Soft-deleted rows must come through the upgrade still deleted.
    raw.execute("INSERT INTO student (id, updated_at, deleted_at, course_id, reg_no, on_class_list, position) "
        "VALUES ('s2', '2026-09-01T10:00:00.000Z', '2026-09-02T10:00:00.000Z', 'c1', 'FWM/24U/0539', 1, 1)");

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, latestSchemaVersion);

    final course = (await CourseRepository(db).get('c1'))!;
    expect(course.title, '(FWM) AGR 114');
    expect(course.scheme.parts.single.name, 'Exam');

    final students = await StudentRepository(db).getAll('c1');
    expect(students.map((s) => s.regNo), ['FWM/24U/0538']);

    final scores = await ScoreRepository(db).get('c1');
    expect(scores['s1']!['p1']!.value, 9.5);
  });

  test('version 2 adds batches and the intake columns without touching old scans', () async {
    final schema = await verifier.schemaAt(1);
    final raw = schema.rawDatabase;
    raw.execute("INSERT INTO course (id, updated_at, code) VALUES ('c1', '2026-09-01T10:00:00.000Z', 'AGR 114')");
    // A scan written by version 1 of the app, before batches existed.
    raw.execute("INSERT INTO scan (id, updated_at, course_id, kind, photo_path, page_no, status, created_at) "
        "VALUES ('sc1', '2026-09-01T10:00:00.000Z', 'c1', 'booklet_cover', 'old/photo.jpg', 1, 'scanned', '2026-09-01T10:00:00.000Z')");

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 2);

    final old = await (db.select(db.scans)..where((s) => s.id.equals('sc1'))).getSingle();
    expect(old.photoPath, 'old/photo.jpg');
    expect(old.batchId, isNull, reason: 'a scan from before batches belongs to no batch');
    expect(old.contentHash, isNull);

    // New rows can use the new columns.
    await db.into(db.batches).insert(BatchesCompanion.insert(courseId: 'c1', id: const Value('b1')));
    await db.into(db.scans).insert(ScansCompanion.insert(
          courseId: 'c1',
          kind: 'booklet_cover',
          id: const Value('sc2'),
          batchId: const Value('b1'),
          originalName: const Value('IMG_001.jpg'),
          contentHash: const Value('abc'),
          width: const Value(3000),
          height: const Value(4000),
        ));
    final fresh = await (db.select(db.scans)..where((s) => s.id.equals('sc2'))).getSingle();
    expect(fresh.batchId, 'b1');
    expect(fresh.originalName, 'IMG_001.jpg');
  });

  test('version 3 adds recognition runs and field reviews and leaves every earlier row as it was', () async {
    final schema = await verifier.schemaAt(2);
    final raw = schema.rawDatabase;
    raw.execute("INSERT INTO course (id, updated_at, code) VALUES ('c1', '2026-09-01T10:00:00.000Z', 'AGR 114')");
    raw.execute("INSERT INTO student (id, updated_at, course_id, reg_no, on_class_list, position) "
        "VALUES ('s1', '2026-09-01T10:00:00.000Z', 'c1', 'FWM/24U/0538', 1, 0)");
    raw.execute("INSERT INTO upload_batch (id, updated_at, course_id, created_at) VALUES ('b1', '2026-09-01T10:00:00.000Z', 'c1', '2026-09-01T10:00:00.000Z')");
    raw.execute("INSERT INTO scan (id, updated_at, course_id, kind, photo_path, page_no, status, created_at, batch_id, content_hash) "
        "VALUES ('sc1', '2026-09-01T10:00:00.000Z', 'c1', 'booklet_cover', 'scans/a.jpg', 1, 'confirmed', '2026-09-01T10:00:00.000Z', 'b1', 'h1')");
    // A booklet confirmed by version 2 of the app, with its stored reading and marks.
    raw.execute("INSERT INTO booklet (id, updated_at, course_id, student_id, scan_id, serial_no, read_json, status, confirmed_at) "
        "VALUES ('bk1', '2026-09-01T10:00:00.000Z', 'c1', 's1', 'sc1', '292011', '{\"engine\":\"old\",\"reading\":{\"serialNo\":\"292011\"}}', 'confirmed', '2026-09-01T11:00:00.000Z')");
    raw.execute("INSERT INTO question_mark (id, updated_at, booklet_id, q_no, mark, edited) "
        "VALUES ('m1', '2026-09-01T10:00:00.000Z', 'bk1', 1, 5.5, 1)");
    raw.execute("INSERT INTO correction (id, updated_at, crop_path, field, read_value, confirmed_value, region) "
        "VALUES ('k1', '2026-09-01T10:00:00.000Z', 'scans/a.jpg', 'serial_no', '292017', '292011', '0.6,0.06,0.74,0.1')");

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 3);

    // Everything written by version 2 is still there, unchanged.
    final booklet = await (db.select(db.booklets)..where((b) => b.id.equals('bk1'))).getSingle();
    expect(booklet.status, 'confirmed');
    expect(booklet.serialNo, '292011');
    expect(booklet.readJson, contains('"engine":"old"'));
    expect((await (db.select(db.questionMarks)).getSingle()).mark, 5.5);
    expect((await (db.select(db.corrections)).getSingle()).readValue, '292017');
    expect((await db.select(db.scans).getSingle()).contentHash, 'h1');

    // The new tables exist, are empty, and take rows.
    expect(await db.select(db.recognitionRuns).get(), isEmpty);
    expect(await db.select(db.fieldReviews).get(), isEmpty);
    await db.into(db.recognitionRuns).insert(RecognitionRunsCompanion.insert(scanId: 'sc1', pipelineVersion: '1.0.0', resultJson: '{}', id: const Value('r1')));
    await db.into(db.fieldReviews).insert(FieldReviewsCompanion.insert(
          scanId: 'sc1',
          fieldKey: 'mark_row_1',
          kind: 'mark',
          decision: 'edited',
          reviewedAt: DateTime.utc(2026, 10, 1),
          machineValue: const Value('5..5'),
          finalValue: const Value('5.5'),
        ));
    expect((await db.select(db.fieldReviews).getSingle()).finalValue, '5.5');
  });
}
