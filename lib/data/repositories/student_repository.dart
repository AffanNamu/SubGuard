import 'package:drift/drift.dart';

import '../../domain/ids.dart';
import '../../domain/models.dart';
import '../../domain/reg_no.dart';
import '../database/app_database.dart';

/// One line to add to a class list.
class NewStudent {
  const NewStudent(this.regNo, {this.name});
  final String regNo;
  final String? name;
}

class AddStudentsResult {
  const AddStudentsResult({
    required this.added,
    required this.duplicates,
    required this.empty,
    required this.invalidPattern,
    required this.corrected,
  });

  final int added;

  /// Skipped because the number is already in the course, or repeated in the
  /// same file.
  final int duplicates;

  /// Skipped because the number was blank.
  final int empty;

  /// Added, but the number does not match DEPT/YYU/NNNN and will be flagged.
  final int invalidPattern;

  /// Added after the normaliser repaired the number (for example 244 -> 24U).
  final int corrected;
}

class StudentRepository {
  StudentRepository(this._db);

  final AppDatabase _db;

  DateTime get _now => DateTime.now().toUtc();

  Student _map(StudentRow r) => Student(
        id: r.id,
        courseId: r.courseId,
        regNo: r.regNo,
        name: r.name,
        onClassList: r.onClassList,
        position: r.position,
      );

  Stream<List<Student>> watch(String courseId) => (_db.select(_db.students)
        ..where((s) => s.courseId.equals(courseId) & s.deletedAt.isNull())
        ..orderBy([
          (s) => OrderingTerm.asc(s.position),
          (s) => OrderingTerm.asc(s.regNo),
        ]))
      .watch()
      .map((rows) => rows.map(_map).toList());

  Future<List<Student>> getAll(String courseId) async {
    final rows = await (_db.select(_db.students)
          ..where((s) => s.courseId.equals(courseId) & s.deletedAt.isNull())
          ..orderBy([(s) => OrderingTerm.asc(s.position)]))
        .get();
    return rows.map(_map).toList();
  }

  Future<int> _nextPosition(String courseId) async {
    final maxCol = _db.students.position.max();
    final row = await (_db.selectOnly(_db.students)
          ..addColumns([maxCol])
          ..where(_db.students.courseId.equals(courseId)))
        .getSingle();
    return (row.read(maxCol) ?? -1) + 1;
  }

  /// Adds students in order. Numbers are stored in their normalised form.
  /// Blank lines and repeats (inside the list, or already in the course) are
  /// skipped and counted. Numbers that do not match the pattern are still
  /// added, because flags guide and never block.
  Future<AddStudentsResult> addMany(
    String courseId,
    List<NewStudent> rows, {
    bool onClassList = true,
  }) =>
      _db.transaction(() async {
        final existing = (await getAll(courseId)).map((s) => RegNo.key(s.regNo)).toSet();
        var position = await _nextPosition(courseId);
        var added = 0, duplicates = 0, empty = 0, invalid = 0, corrected = 0;
        final now = _now;

        for (final row in rows) {
          final reg = RegNo.normalise(row.regNo);
          if (reg.canonical.isEmpty) {
            empty++;
            continue;
          }
          if (!existing.add(reg.canonical)) {
            duplicates++;
            continue;
          }
          if (!reg.isValid) invalid++;
          if (reg.wasCorrected) corrected++;

          final name = row.name?.trim();
          await _db.into(_db.students).insert(StudentsCompanion.insert(
                courseId: courseId,
                regNo: reg.canonical,
                name: Value(name == null || name.isEmpty ? null : name),
                onClassList: Value(onClassList),
                position: Value(position++),
                id: Value(newId()),
                updatedAt: Value(now),
              ));
          added++;
        }

        return AddStudentsResult(
          added: added,
          duplicates: duplicates,
          empty: empty,
          invalidPattern: invalid,
          corrected: corrected,
        );
      });

  Future<void> update(Student s) async {
    final reg = RegNo.normalise(s.regNo);
    final name = s.name?.trim();
    await (_db.update(_db.students)..where((t) => t.id.equals(s.id))).write(
      StudentsCompanion(
        regNo: Value(reg.canonical),
        name: Value(name == null || name.isEmpty ? null : name),
        onClassList: Value(s.onClassList),
        updatedAt: Value(_now),
      ),
    );
  }

  Future<void> softDelete(String id) async {
    final now = _now;
    await (_db.update(_db.students)..where((t) => t.id.equals(id))).write(
        StudentsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
  }

  Future<void> restore(String id) async {
    await (_db.update(_db.students)..where((t) => t.id.equals(id))).write(
        StudentsCompanion(deletedAt: const Value(null), updatedAt: Value(_now)));
  }

  Stream<List<Student>> watchDeleted(String courseId) => (_db.select(_db.students)
        ..where((s) => s.courseId.equals(courseId) & s.deletedAt.isNotNull())
        ..orderBy([(s) => OrderingTerm.desc(s.deletedAt)]))
      .watch()
      .map((rows) => rows.map(_map).toList());
}
