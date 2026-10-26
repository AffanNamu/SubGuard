import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:unimarkly/data/database/app_database.dart';
import 'package:unimarkly/data/repositories/booklet_repository.dart';
import 'package:unimarkly/data/repositories/course_repository.dart';
import 'package:unimarkly/data/repositories/score_repository.dart';
import 'package:unimarkly/data/repositories/student_repository.dart';
import 'package:unimarkly/domain/defaults.dart';
import 'package:unimarkly/domain/ids.dart';
import 'package:unimarkly/domain/models.dart';
import 'package:unimarkly/domain/ocr.dart';
import 'package:unimarkly/domain/scheme.dart';

/// What is stored when a booklet is confirmed, and that it is all still there after the app
/// is closed and opened again. The database is a real file, closed and reopened.
void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('unimarkly_records_');
    file = File(p.join(dir.path, 'app.sqlite'));
  });
  tearDown(() => dir.deleteSync(recursive: true));

  AppDatabase open() => AppDatabase(NativeDatabase(file));

  Future<({Course course, String studentId, String scanId, String partId})> seed(AppDatabase db, {GradingScheme? scheme}) async {
    final courses = CourseRepository(db);
    final course = Course(id: newId(), code: 'AGR 114', department: 'FWM', scheme: scheme ?? Defaults.nigerianScheme());
    await courses.save(course);
    await StudentRepository(db).addMany(course.id, const [NewStudent('FWM/24U/0538')]);
    final student = (await StudentRepository(db).getAll(course.id)).single;
    await db.customStatement("INSERT INTO upload_batch (id, updated_at, course_id, created_at) VALUES ('b1', '2026-10-01T10:00:00.000Z', '${course.id}', '2026-10-01T10:00:00.000Z')");
    await db.customStatement("INSERT INTO scan (id, updated_at, course_id, kind, photo_path, page_no, status, created_at, batch_id, content_hash) "
        "VALUES ('sc1', '2026-10-01T10:00:00.000Z', '${course.id}', 'booklet_cover', 'scans/a.jpg', 1, 'needs_review', '2026-10-01T10:00:00.000Z', 'b1', 'h1')");
    return (course: course, studentId: student.id, scanId: 'sc1', partId: course.scheme.examPart!.id);
  }

  const records = [
    ConfirmedMark(qNo: 1, mark: 1.0, status: 'suggestion', recognisedMark: '1.7', recognisedQuestion: '7.1', maxMark: 10, region: Region(0.78, 0.34, 0.98, 0.38), questionRegion: Region(0.64, 0.34, 0.78, 0.38)),
    ConfirmedMark(qNo: 2, mark: 1.0, edited: true, status: 'edited', recognisedMark: '141', recognisedQuestion: '2', maxMark: 10, region: Region(0.78, 0.39, 0.98, 0.43)),
    ConfirmedMark(qNo: 4, mark: 2.0, edited: true, status: 'edited', recognisedMark: '2.61', recognisedQuestion: '4'),
    ConfirmedMark(qNo: 5, mark: 5.5, status: 'accepted', recognisedMark: '5.5', recognisedQuestion: '5', maxMark: 10),
  ];

  test('the question-mark records, the calculated total and the written total are stored apart and survive closing and reopening the app', () async {
    var db = open();
    final s = await seed(db);
    await BookletRepository(db, ScoreRepository(db)).confirm(
      scanId: s.scanId,
      courseId: s.course.id,
      studentId: s.studentId,
      serialNo: '292011',
      marks: {for (final r in records) r.qNo: r.mark},
      editedMarks: {2, 4},
      examScore: 9.5,
      examPartId: s.partId,
      photoPath: 'scans/a.jpg',
      records: records,
      calculatedTotal: 9.5,
      writtenTotal: 10.5,
      maxTotal: 30,
      totalNotes: const ['Q3 on the paper has no mark and counts as zero.'],
    );
    await db.close();

    db = open(); // the app is opened again
    addTearDown(db.close);
    final b = (await BookletRepository(db, ScoreRepository(db)).forScan('sc1'))!;
    expect(b.confirmed, isTrue);
    expect(b.records.map((r) => (r.qNo, r.mark)), [(1, 1.0), (2, 1.0), (4, 2.0), (5, 5.5)]);
    expect(b.marks, {1: 1.0, 2: 1.0, 4: 2.0, 5: 5.5});

    // What was read is kept apart from what was confirmed, with the status and the place.
    final byQ = {for (final r in b.records) r.qNo: r};
    expect((byQ[1]!.recognisedMark, byQ[1]!.mark, byQ[1]!.status), ('1.7', 1.0, 'suggestion'));
    expect((byQ[2]!.recognisedMark, byQ[2]!.mark, byQ[2]!.status), ('141', 1.0, 'edited'));
    expect((byQ[4]!.recognisedMark, byQ[4]!.mark), ('2.61', 2.0));
    expect(byQ[1]!.recognisedQuestion, '7.1');
    expect(byQ[1]!.maxMark, 10);
    expect(byQ[1]!.region!.encode(), '0.7800,0.3400,0.9800,0.3800');
    expect(byQ[1]!.questionRegion!.encode(), '0.6400,0.3400,0.7800,0.3800');
    expect(byQ[4]!.region, isNull, reason: 'a record without a place stays without one');

    // The totals are separate things.
    expect(b.calculatedTotal, 9.5);
    expect(b.writtenTotal, 10.5);
    expect(b.maxTotal, 30);
    expect(b.totalNotes, ['Q3 on the paper has no mark and counts as zero.']);
    // And the grid has the calculated score, not the written one.
    expect((await ScoreRepository(db).cell(s.studentId, s.partId))!.value, 9.5);
  });

  test('a blank written total is stored as none, not as zero', () async {
    final db = open();
    addTearDown(db.close);
    final s = await seed(db);
    await BookletRepository(db, ScoreRepository(db)).confirm(
      scanId: s.scanId, courseId: s.course.id, studentId: s.studentId, serialNo: null,
      marks: {1: 4}, editedMarks: {1}, examScore: 4, examPartId: s.partId, photoPath: 'scans/a.jpg',
      records: const [ConfirmedMark(qNo: 1, mark: 4, status: 'entered')], calculatedTotal: 4, writtenTotal: null,
    );
    final b = (await BookletRepository(db, ScoreRepository(db)).forScan('sc1'))!;
    expect(b.writtenTotal, isNull);
    expect(b.calculatedTotal, 4);
    expect(b.maxTotal, isNull);
    expect(b.totalNotes, isEmpty);
  });

  test('a correction made later replaces the marks and the total; the earlier ones are not counted again', () async {
    var db = open();
    final s = await seed(db);
    var repo = BookletRepository(db, ScoreRepository(db));
    await repo.confirm(
      scanId: s.scanId, courseId: s.course.id, studentId: s.studentId, serialNo: null,
      marks: {1: 1, 4: 2}, editedMarks: {1, 4}, examScore: 3, examPartId: s.partId, photoPath: 'scans/a.jpg',
      records: const [ConfirmedMark(qNo: 1, mark: 1, status: 'entered'), ConfirmedMark(qNo: 4, mark: 2, status: 'entered')], calculatedTotal: 3,
    );
    await repo.reopen('sc1');
    await repo.confirm(
      scanId: s.scanId, courseId: s.course.id, studentId: s.studentId, serialNo: null,
      marks: {1: 1, 4: 3.5}, editedMarks: {4}, examScore: 4.5, examPartId: s.partId, photoPath: 'scans/a.jpg',
      records: const [ConfirmedMark(qNo: 1, mark: 1, status: 'entered'), ConfirmedMark(qNo: 4, mark: 3.5, status: 'edited')], calculatedTotal: 4.5,
    );
    await db.close();

    db = open();
    addTearDown(db.close);
    repo = BookletRepository(db, ScoreRepository(db));
    final b = (await repo.forScan('sc1'))!;
    expect(b.records.map((r) => (r.qNo, r.mark)), [(1, 1.0), (4, 3.5)]);
    expect(b.calculatedTotal, 4.5);
    expect((await ScoreRepository(db).cell(s.studentId, s.partId))!.value, 4.5);
    final live = await (db.select(db.questionMarks)..where((m) => m.deletedAt.isNull())).get();
    expect(live, hasLength(2), reason: 'the first confirmation\'s rows were replaced, not kept as well');
  });

  test('confirming with only the plain marks, as before records existed, still stores a record for each', () async {
    final db = open();
    addTearDown(db.close);
    final s = await seed(db);
    await BookletRepository(db, ScoreRepository(db)).confirm(
      scanId: s.scanId, courseId: s.course.id, studentId: s.studentId, serialNo: null,
      marks: {2: 6, 3: 2.5}, editedMarks: {3}, examScore: 8.5, examPartId: s.partId, photoPath: 'scans/a.jpg',
    );
    final b = (await BookletRepository(db, ScoreRepository(db)).forScan('sc1'))!;
    expect(b.records.map((r) => (r.qNo, r.mark, r.edited, r.status)), [(2, 6.0, false, 'entered'), (3, 2.5, true, 'edited')]);
    expect(b.calculatedTotal, 8.5, reason: 'the score that went to the grid is recorded as the calculated total');
  });

  test('a course keeps its question weights and its rule for unmarked questions after the app is reopened', () async {
    var db = open();
    final base = Defaults.nigerianScheme();
    final scheme = base.copyWith(
      unmarked: UnmarkedRule.ask,
      countRule: CountRule.bestN,
      countN: 2,
      questions: [
        QuestionSpec(id: newId(), qNo: 1, max: 10),
        QuestionSpec(id: newId(), qNo: 4, max: 20, weight: 2, compulsory: true),
        QuestionSpec(id: newId(), qNo: 5, max: 10, weight: 0.5),
      ],
    );
    final s = await seed(db, scheme: scheme);
    await db.close();

    db = open();
    addTearDown(db.close);
    final loaded = (await CourseRepository(db).get(s.course.id))!.scheme;
    expect(loaded.unmarked, UnmarkedRule.ask);
    expect(loaded.questions.map((q) => (q.qNo, q.max, q.weight, q.compulsory)), [(1, 10.0, 1.0, false), (4, 20.0, 2.0, true), (5, 10.0, 0.5, false)],
        reason: 'the question numbers are exactly the ones set: 1, 4, 5');
    expect(loaded.countRule, CountRule.bestN);
    expect(loaded.reachableExamScore, 50, reason: 'the best 2 of 10, 40 (20 x 2) and 5 are 40 and 10');
  });
}
