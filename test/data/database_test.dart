
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/data/database/app_database.dart';
import 'package:unimarkly/data/repositories/course_repository.dart';
import 'package:unimarkly/data/repositories/score_repository.dart';
import 'package:unimarkly/data/repositories/student_repository.dart';
import 'package:unimarkly/domain/defaults.dart';
import 'package:unimarkly/domain/ids.dart';
import 'package:unimarkly/domain/models.dart';
import 'package:unimarkly/domain/scheme.dart';
import 'package:unimarkly/domain/scheme_codec.dart';
import 'package:unimarkly/domain/scoring.dart';

void main() {
  late AppDatabase db;
  late CourseRepository courses;
  late StudentRepository students;
  late ScoreRepository scores;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    courses = CourseRepository(db);
    students = StudentRepository(db);
    scores = ScoreRepository(db);
  });

  tearDown(() => db.close());

  Course newCourse({String code = 'AGR 114'}) =>
      Course(id: newId(), code: code, department: 'FWM', scheme: Defaults.nigerianScheme());

  group('schema', () {
    const tables = [
      'course', 'course_part', 'exam_question', 'grade_scale', 'scheme_template',
      'student', 'upload_batch', 'scan', 'booklet', 'question_mark', 'row_read', 'part_score',
      'correction', 'recognition_run', 'field_review', 'review_draft', 'account', 'sync_state',
    ];

    test('has the fourteen tables from the brief, plus upload_batch, recognition_run, field_review and review_draft', () async {
      final rows = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
          .get();
      expect(rows.map((r) => r.read<String>('name')).toSet(), tables.toSet());
    });

    test('every table has a text id primary key, updated_at and deleted_at', () async {
      for (final table in tables) {
        final info = await db.customSelect('PRAGMA table_info($table)').get();
        final byName = {for (final r in info) r.read<String>('name'): r};
        expect(byName.keys, containsAll(['id', 'updated_at', 'deleted_at']), reason: table);
        expect(byName['id']!.read<int>('pk'), 1, reason: '$table.id is the primary key');
        expect(byName['id']!.read<String>('type').toUpperCase(), 'TEXT', reason: table);
        expect(byName['deleted_at']!.read<int>('notnull'), 0, reason: '$table.deleted_at is nullable');
        expect(byName['updated_at']!.read<int>('notnull'), 1, reason: table);
      }
    });

    test('column names match the data model in the brief', () async {
      Future<Set<String>> cols(String t) async => (await db.customSelect('PRAGMA table_info($t)').get())
          .map((r) => r.read<String>('name'))
          .toSet();

      expect(await cols('course'), containsAll(['code', 'department', 'session', 'semester', 'total_expected', 'count_rule', 'count_n']));
      expect(await cols('course_part'), containsAll(['course_id', 'name', 'max', 'min', 'pass_mark', 'step', 'marked_out_of', 'counts_for', 'source', 'sort_order']));
      expect(await cols('exam_question'), containsAll(['course_id', 'q_no', 'max', 'compulsory']));
      expect(await cols('grade_scale'), containsAll(['course_id', 'min_score', 'max_score', 'letter', 'points']));
      expect(await cols('scheme_template'), containsAll(['name', 'json']));
      expect(await cols('student'), containsAll(['course_id', 'reg_no', 'name']));
      expect(await cols('scan'), containsAll(['course_id', 'kind', 'photo_path', 'page_no', 'status', 'created_at', 'batch_id', 'original_name', 'content_hash', 'width', 'height', 'error_message']));
      expect(await cols('upload_batch'), containsAll(['course_id', 'title']));
      expect(await cols('booklet'), containsAll(['course_id', 'student_id', 'scan_id', 'serial_no', 'read_json', 'status', 'confirmed_at']));
      expect(await cols('question_mark'), containsAll(['booklet_id', 'q_no', 'mark', 'confidence', 'edited']));
      expect(await cols('row_read'), containsAll(['scan_id', 'row_no', 'raw_id', 'raw_value', 'student_id', 'part_id', 'value', 'confidence', 'status']));
      expect(await cols('part_score'), containsAll(['course_id', 'student_id', 'part_id', 'value', 'status', 'source']));
      expect(await cols('correction'), containsAll(['crop_path', 'field', 'read_value', 'confirmed_value', 'region']));
      expect(await cols('account'), containsAll(['user_id', 'email', 'plan', 'plan_valid_until']));
      expect(await cols('sync_state'), containsAll(['table_name', 'last_pull_at', 'last_push_at']));
    });

    test('rows get a UUID id and an updated_at by default', () async {
      final id = await db.into(db.schemeTemplates).insert(
            SchemeTemplatesCompanion.insert(name: 'x', json: '{}'),
          );
      expect(id, isNonZero);
      final row = await db.select(db.schemeTemplates).getSingle();
      expect(row.id, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
      expect(row.updatedAt.isUtc, isTrue);
      expect(row.deletedAt, isNull);
    });
  });

  group('CourseRepository', () {
    test('saves and loads a course with the 70 + 30 default', () async {
      final c = newCourse();
      await courses.save(c);
      final loaded = (await courses.get(c.id))!;
      expect(loaded.code, 'AGR 114');
      expect(loaded.title, '(FWM) AGR 114');
      expect(loaded.scheme.parts.map((p) => p.name), ['Exam', 'Attendance', 'Assignment', 'Test']);
      expect(loaded.scheme.partsTotal, 100);
      expect(loaded.scheme.parts.first.source, PartSource.scanned);
      expect(loaded.scheme.bands.length, 6);
    });

    test('lists courses by code and leaves out deleted ones', () async {
      final a = newCourse(code: 'BIO 201');
      final b = newCourse(code: 'AGR 114');
      await courses.save(a);
      await courses.save(b);
      expect((await courses.getAll()).map((c) => c.code), ['AGR 114', 'BIO 201']);

      await courses.softDelete(a.id);
      expect((await courses.getAll()).map((c) => c.code), ['AGR 114']);
      expect(await courses.get(a.id), isNull);
    });

    test('delete goes to the bin and restore brings everything back', () async {
      final c = newCourse();
      await courses.save(c);
      await students.addMany(c.id, [const NewStudent('FWM/24U/0538')]);
      await courses.softDelete(c.id);

      final row = await (db.select(db.courses)..where((t) => t.id.equals(c.id))).getSingle();
      expect(row.deletedAt, isNotNull);
      expect((await courses.watchDeleted().first).single.id, c.id);

      await courses.restore(c.id);
      expect((await courses.get(c.id))!.id, c.id);
      expect(await students.getAll(c.id), hasLength(1));
    });

    test('editing changes parts in place, adds new ones, soft-deletes removed ones', () async {
      final c = newCourse();
      await courses.save(c);
      final exam = c.scheme.parts[0];
      final test = c.scheme.parts[3];

      final edited = c.copyWith(
        scheme: c.scheme.copyWith(
          totalExpected: 100,
          parts: [
            exam.copyWith(max: 60, passMark: 30),
            ...c.scheme.parts.sublist(1, 3),
            PartSpec(id: newId(), name: 'Practical', max: 10, step: 1),
          ],
        ),
      );
      await courses.save(edited);

      final loaded = (await courses.get(c.id))!;
      expect(loaded.scheme.parts.map((p) => p.name), ['Exam', 'Attendance', 'Assignment', 'Practical']);
      expect(loaded.scheme.parts.first.id, exam.id, reason: 'same part, same id');
      expect(loaded.scheme.parts.first.max, 60);
      expect(loaded.scheme.parts.first.passMark, 30);

      final removed = await (db.select(db.courseParts)..where((p) => p.id.equals(test.id))).getSingle();
      expect(removed.deletedAt, isNotNull, reason: 'removed parts are soft-deleted, never erased');
    });

    test('updated_at moves forward on every save', () async {
      final c = newCourse();
      await courses.save(c);
      final first = (await db.select(db.courses).getSingle()).updatedAt;
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await courses.save(c.copyWith(semester: 'First'));
      final second = (await db.select(db.courses).getSingle()).updatedAt;
      expect(second.isAfter(first), isTrue);
    });

    test('keeps exam questions and a counting rule', () async {
      final c = newCourse();
      final withQuestions = c.copyWith(
        scheme: c.scheme.copyWith(
          countRule: CountRule.compulsoryPlusBestN,
          countN: 3,
          questions: [
            for (var i = 1; i <= 5; i++) QuestionSpec(id: newId(), qNo: i, max: 14, compulsory: i == 1),
          ],
        ),
      );
      await courses.save(withQuestions);
      final loaded = (await courses.get(c.id))!.scheme;
      expect(loaded.countRule, CountRule.compulsoryPlusBestN);
      expect(loaded.countN, 3);
      expect(loaded.questions.map((q) => q.qNo), [1, 2, 3, 4, 5]);
      expect(loaded.questions.first.compulsory, isTrue);
    });

    test('saves and reloads templates, and deleting hides them', () async {
      await courses.saveTemplate('Second semester', Defaults.nigerianScheme());
      final list = await courses.watchTemplates().first;
      expect(list.single.name, 'Second semester');
      expect(list.single.scheme.partsTotal, 100);

      final copy = SchemeCodec.freshCopy(list.single.scheme);
      expect(copy.parts.first.id, isNot(list.single.scheme.parts.first.id));

      await courses.deleteTemplate(list.single.id);
      expect(await courses.watchTemplates().first, isEmpty);
    });
  });

  group('StudentRepository', () {
    late Course course;
    setUp(() async {
      course = newCourse();
      await courses.save(course);
    });

    test('stores numbers normalised, keeps order, and skips repeats', () async {
      final r = await students.addMany(course.id, const [
        NewStudent('fwm/24u/0538', name: 'Ada'),
        NewStudent('FWM 244 0540'),
        NewStudent('FWM/24U/0538'),
        NewStudent(''),
        NewStudent('what is this'),
      ]);
      expect(r.added, 3);
      expect(r.duplicates, 1);
      expect(r.empty, 1);
      expect(r.invalidPattern, 1);
      expect(r.corrected, 1);

      final all = await students.getAll(course.id);
      expect(all.map((s) => s.regNo), ['FWM/24U/0538', 'FWM/24U/0540', 'WHAT/IS/THIS']);
      expect(all.map((s) => s.position), [0, 1, 2]);
      expect(all.first.name, 'Ada');
    });

    test('a second import skips numbers already in the course', () async {
      await students.addMany(course.id, const [NewStudent('FWM/24U/0538')]);
      final r = await students.addMany(course.id, const [
        NewStudent('FWM/24U/0538'),
        NewStudent('FWM/24U/0539'),
      ]);
      expect(r.added, 1);
      expect(r.duplicates, 1);
      expect((await students.getAll(course.id)).last.position, 1);
    });

    test('the same number can be in two different courses', () async {
      final other = newCourse(code: 'BIO 201');
      await courses.save(other);
      await students.addMany(course.id, const [NewStudent('FWM/24U/0538')]);
      final r = await students.addMany(other.id, const [NewStudent('FWM/24U/0538')]);
      expect(r.added, 1);
    });

    test('soft delete and restore', () async {
      await students.addMany(course.id, const [NewStudent('FWM/24U/0538')]);
      final s = (await students.getAll(course.id)).single;
      await students.softDelete(s.id);
      expect(await students.getAll(course.id), isEmpty);
      expect((await students.watchDeleted(course.id).first).single.id, s.id);
      await students.restore(s.id);
      expect(await students.getAll(course.id), hasLength(1));
    });

    test('update re-normalises the number', () async {
      await students.addMany(course.id, const [NewStudent('FWM/24U/0538')]);
      final s = (await students.getAll(course.id)).single;
      await students.update(s.copyWith(regNo: 'fwm/244/0541', name: ' Bola '));
      final u = (await students.getAll(course.id)).single;
      expect(u.regNo, 'FWM/24U/0541');
      expect(u.name, 'Bola');
    });

    test('added by hand and flagged as not on the class list', () async {
      await students.addMany(course.id, const [NewStudent('FWM/24U/0999')], onClassList: false);
      expect((await students.getAll(course.id)).single.onClassList, isFalse);
    });
  });

  group('ScoreRepository', () {
    late Course course;
    late Student student;
    late PartSpec exam;

    setUp(() async {
      course = newCourse();
      await courses.save(course);
      await students.addMany(course.id, const [NewStudent('FWM/24U/0538')]);
      student = (await students.getAll(course.id)).single;
      exam = course.scheme.parts.first;
    });

    Future<int> rowCount() async => (await db.select(db.partScores).get()).length;

    test('stores a mark and reads it back', () async {
      await scores.set(course.id, ScoreWrite(studentId: student.id, partId: exam.id, value: 9.5));
      final map = await scores.get(course.id);
      expect(map[student.id]![exam.id]!.value, 9.5);
      expect(map[student.id]![exam.id]!.hasValue, isTrue);
    });

    test('rewriting a cell updates the same row', () async {
      for (final v in [5.0, 6.0, 7.5]) {
        await scores.set(course.id, ScoreWrite(studentId: student.id, partId: exam.id, value: v));
      }
      expect(await rowCount(), 1);
      expect((await scores.get(course.id))[student.id]![exam.id]!.value, 7.5);
    });

    test('absent has no value', () async {
      await scores.set(course.id,
          ScoreWrite(studentId: student.id, partId: exam.id, status: ScoreStatus.absent));
      final v = (await scores.get(course.id))[student.id]![exam.id]!;
      expect(v.isAbsent, isTrue);
      expect(v.value, isNull);
    });

    test('clearing a cell soft-deletes it, and typing again reuses the row', () async {
      await scores.set(course.id, ScoreWrite(studentId: student.id, partId: exam.id, value: 5));
      await scores.set(course.id,
          ScoreWrite(studentId: student.id, partId: exam.id, status: ScoreStatus.missing));
      expect(await scores.get(course.id), isEmpty);
      expect(await rowCount(), 1);
      expect((await db.select(db.partScores).getSingle()).deletedAt, isNotNull);

      await scores.set(course.id, ScoreWrite(studentId: student.id, partId: exam.id, value: 8));
      expect(await rowCount(), 1);
      expect((await scores.get(course.id))[student.id]![exam.id]!.value, 8);
      expect((await db.select(db.partScores).getSingle()).deletedAt, isNull);
    });

    test('clearing an empty cell does nothing', () async {
      await scores.set(course.id,
          ScoreWrite(studentId: student.id, partId: exam.id, status: ScoreStatus.missing));
      expect(await rowCount(), 0);
    });

    test('setMany writes in one go', () async {
      await scores.setMany(course.id, [
        for (final p in course.scheme.parts)
          ScoreWrite(studentId: student.id, partId: p.id, value: 4, source: 'imported'),
      ]);
      final map = (await scores.get(course.id))[student.id]!;
      expect(map.length, 4);
      expect((await db.select(db.partScores).get()).every((r) => r.source == 'imported'), isTrue);
    });

    test('the watch stream emits when a cell changes', () async {
      final emissions = <ScoreMap>[];
      final sub = scores.watch(course.id).listen(emissions.add);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await scores.set(course.id, ScoreWrite(studentId: student.id, partId: exam.id, value: 3));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await sub.cancel();
      expect(emissions.last[student.id]![exam.id]!.value, 3);
    });
  });
}
