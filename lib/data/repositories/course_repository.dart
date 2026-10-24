import 'package:drift/drift.dart';

import '../../domain/ids.dart';
import '../../domain/models.dart';
import '../../domain/scheme.dart';
import '../../domain/scheme_codec.dart';
import '../database/app_database.dart';

/// Courses with their grading scheme (parts, exam questions, grade scale),
/// and saved scheme templates.
class CourseRepository {
  CourseRepository(this._db);

  final AppDatabase _db;

  DateTime get _now => DateTime.now().toUtc();

  Set<TableInfo> get _courseTables =>
      {_db.courses, _db.courseParts, _db.examQuestions, _db.gradeScales};

  // ---- reading ----

  Stream<List<Course>> watchAll() => _db
      .customSelect('SELECT 1', readsFrom: _courseTables)
      .watch()
      .asyncMap((_) => getAll());

  Stream<Course?> watch(String id) => _db
      .customSelect('SELECT 1', readsFrom: _courseTables)
      .watch()
      .asyncMap((_) => get(id));

  Future<List<Course>> getAll() async {
    final rows = await (_db.select(_db.courses)
          ..where((c) => c.deletedAt.isNull())
          ..orderBy([(c) => OrderingTerm.asc(c.code)]))
        .get();
    return _assemble(rows);
  }

  Future<Course?> get(String id) async {
    final row = await (_db.select(_db.courses)
          ..where((c) => c.id.equals(id) & c.deletedAt.isNull()))
        .getSingleOrNull();
    if (row == null) return null;
    return (await _assemble([row])).single;
  }

  Stream<List<Course>> watchDeleted() => _db
      .customSelect('SELECT 1', readsFrom: _courseTables)
      .watch()
      .asyncMap((_) async {
    final rows = await (_db.select(_db.courses)
          ..where((c) => c.deletedAt.isNotNull())
          ..orderBy([(c) => OrderingTerm.desc(c.deletedAt)]))
        .get();
    return _assemble(rows);
  });

  Future<List<Course>> _assemble(List<CourseRow> rows) async {
    if (rows.isEmpty) return const [];
    final ids = rows.map((r) => r.id).toList();

    final parts = await (_db.select(_db.courseParts)
          ..where((p) => p.courseId.isIn(ids) & p.deletedAt.isNull())
          ..orderBy([(p) => OrderingTerm.asc(p.sortOrder)]))
        .get();
    final questions = await (_db.select(_db.examQuestions)
          ..where((q) => q.courseId.isIn(ids) & q.deletedAt.isNull())
          ..orderBy([(q) => OrderingTerm.asc(q.qNo)]))
        .get();
    final bands = await (_db.select(_db.gradeScales)
          ..where((b) => b.courseId.isIn(ids) & b.deletedAt.isNull())
          ..orderBy([(b) => OrderingTerm.desc(b.minScore)]))
        .get();

    return [
      for (final r in rows)
        Course(
          id: r.id,
          code: r.code,
          department: r.department,
          session: r.session,
          semester: r.semester,
          scheme: GradingScheme(
            totalExpected: r.totalExpected,
            countRule: CountRule.fromDb(r.countRule),
            countN: r.countN,
            parts: [
              for (final p in parts.where((p) => p.courseId == r.id))
                PartSpec(
                  id: p.id,
                  name: p.name,
                  max: p.max,
                  min: p.min,
                  passMark: p.passMark,
                  step: p.step,
                  markedOutOf: p.markedOutOf,
                  countsFor: p.countsFor,
                  source: PartSource.fromDb(p.source),
                  sortOrder: p.sortOrder,
                )
            ],
            questions: [
              for (final q in questions.where((q) => q.courseId == r.id))
                QuestionSpec(
                    id: q.id, qNo: q.qNo, max: q.max, compulsory: q.compulsory)
            ],
            bands: [
              for (final b in bands.where((b) => b.courseId == r.id))
                GradeBand(
                  id: b.id,
                  minScore: b.minScore,
                  maxScore: b.maxScore,
                  letter: b.letter,
                  points: b.points,
                )
            ],
          ),
        ),
    ];
  }

  // ---- writing ----

  /// Creates a course, or saves changes to an existing one. Parts, questions
  /// and grade bands are matched by id: changed rows are updated, new rows
  /// inserted, and rows that were removed are soft-deleted.
  Future<void> save(Course course) => _db.transaction(() async {
        final now = _now;
        final scheme = course.scheme;

        await _db.into(_db.courses).insertOnConflictUpdate(CoursesCompanion(
              id: Value(course.id),
              code: Value(course.code.trim()),
              department: Value(course.department.trim()),
              session: Value(course.session.trim()),
              semester: Value(course.semester.trim()),
              totalExpected: Value(scheme.totalExpected),
              countRule: Value(scheme.countRule.dbValue),
              countN: Value(scheme.countN),
              updatedAt: Value(now),
              deletedAt: const Value(null),
            ));

        await _saveParts(course.id, scheme.parts, now);
        await _saveQuestions(course.id, scheme.questions, now);
        await _saveBands(course.id, scheme.bands, now);
      });

  Future<void> _saveParts(String courseId, List<PartSpec> parts, DateTime now) async {
    final keep = <String>{};
    for (var i = 0; i < parts.length; i++) {
      final p = parts[i];
      keep.add(p.id);
      await _db.into(_db.courseParts).insertOnConflictUpdate(CoursePartsCompanion(
            id: Value(p.id),
            courseId: Value(courseId),
            name: Value(p.name.trim()),
            max: Value(p.max),
            min: Value(p.min),
            passMark: Value(p.passMark),
            step: Value(p.step),
            markedOutOf: Value(p.markedOutOf),
            countsFor: Value(p.countsFor),
            source: Value(p.source.dbValue),
            sortOrder: Value(i),
            updatedAt: Value(now),
            deletedAt: const Value(null),
          ));
    }
    await (_db.update(_db.courseParts)
          ..where((t) =>
              t.courseId.equals(courseId) &
              t.deletedAt.isNull() &
              t.id.isNotIn(keep)))
        .write(CoursePartsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
  }

  Future<void> _saveQuestions(
      String courseId, List<QuestionSpec> questions, DateTime now) async {
    final keep = <String>{};
    for (final q in questions) {
      keep.add(q.id);
      await _db
          .into(_db.examQuestions)
          .insertOnConflictUpdate(ExamQuestionsCompanion(
            id: Value(q.id),
            courseId: Value(courseId),
            qNo: Value(q.qNo),
            max: Value(q.max),
            compulsory: Value(q.compulsory),
            updatedAt: Value(now),
            deletedAt: const Value(null),
          ));
    }
    await (_db.update(_db.examQuestions)
          ..where((t) =>
              t.courseId.equals(courseId) &
              t.deletedAt.isNull() &
              t.id.isNotIn(keep)))
        .write(ExamQuestionsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
  }

  Future<void> _saveBands(String courseId, List<GradeBand> bands, DateTime now) async {
    final keep = <String>{};
    for (final b in bands) {
      keep.add(b.id);
      await _db.into(_db.gradeScales).insertOnConflictUpdate(GradeScalesCompanion(
            id: Value(b.id),
            courseId: Value(courseId),
            minScore: Value(b.minScore),
            maxScore: Value(b.maxScore),
            letter: Value(b.letter.trim()),
            points: Value(b.points),
            updatedAt: Value(now),
            deletedAt: const Value(null),
          ));
    }
    await (_db.update(_db.gradeScales)
          ..where((t) =>
              t.courseId.equals(courseId) &
              t.deletedAt.isNull() &
              t.id.isNotIn(keep)))
        .write(GradeScalesCompanion(deletedAt: Value(now), updatedAt: Value(now)));
  }

  /// Moves a course to the bin. Its students and scores stay in place, so
  /// [restore] brings everything back.
  Future<void> softDelete(String id) async {
    final now = _now;
    await (_db.update(_db.courses)..where((c) => c.id.equals(id))).write(
        CoursesCompanion(deletedAt: Value(now), updatedAt: Value(now)));
  }

  Future<void> restore(String id) async {
    await (_db.update(_db.courses)..where((c) => c.id.equals(id))).write(
        CoursesCompanion(deletedAt: const Value(null), updatedAt: Value(_now)));
  }

  // ---- templates ----

  Stream<List<SchemeTemplate>> watchTemplates() => (_db.select(_db.schemeTemplates)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.name)]))
      .watch()
      .map((rows) => [
            for (final r in rows)
              SchemeTemplate(
                id: r.id,
                name: r.name,
                scheme: SchemeCodec.decode(r.json),
              )
          ]);

  Future<void> saveTemplate(String name, GradingScheme scheme, {String? id}) async {
    await _db.into(_db.schemeTemplates).insertOnConflictUpdate(
          SchemeTemplatesCompanion(
            id: Value(id ?? newId()),
            name: Value(name.trim()),
            json: Value(SchemeCodec.encode(scheme)),
            updatedAt: Value(_now),
            deletedAt: const Value(null),
          ),
        );
  }

  Future<void> deleteTemplate(String id) async {
    final now = _now;
    await (_db.update(_db.schemeTemplates)..where((t) => t.id.equals(id))).write(
        SchemeTemplatesCompanion(deletedAt: Value(now), updatedAt: Value(now)));
  }
}
