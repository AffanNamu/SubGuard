import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/data/database/app_database.dart';
import 'package:unimarkly/data/database/migrations.dart';
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

  test('version 1 data survives opening with the current code', () async {
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

  test('every schema version up to the latest has a migration step', () {
    for (var v = 2; v <= latestSchemaVersion; v++) {
      expect(migrations.containsKey(v), isTrue, reason: 'missing migration for v$v');
    }
  });
}
