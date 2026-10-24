import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/data/database/app_database.dart';
import 'package:unimarkly/data/repositories/course_repository.dart';
import 'package:unimarkly/data/repositories/score_repository.dart';
import 'package:unimarkly/data/repositories/student_repository.dart';
import 'package:unimarkly/domain/defaults.dart';
import 'package:unimarkly/domain/ids.dart';
import 'package:unimarkly/domain/models.dart';

void main() {
  test('writes finish while streams are listening, and the streams catch up', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final courses = CourseRepository(db);
    final students = StudentRepository(db);
    final scores = ScoreRepository(db);

    final course = Course(id: newId(), code: 'AGR 114', scheme: Defaults.nigerianScheme());

    final courseEmits = <int>[];
    final studentEmits = <int>[];
    final scoreEmits = <int>[];
    final subs = [
      courses.watchAll().listen((l) => courseEmits.add(l.length)),
      courses.watch(course.id).listen((_) {}),
      students.watch(course.id).listen((l) => studentEmits.add(l.length)),
      scores.watch(course.id).listen((m) => scoreEmits.add(m.length)),
    ];

    await courses.save(course).timeout(const Duration(seconds: 10));
    final result = await students
        .addMany(course.id, const [NewStudent('FWM/24U/0538'), NewStudent('FWM/24U/0539')])
        .timeout(const Duration(seconds: 10));
    expect(result.added, 2);

    final s = (await students.getAll(course.id)).first;
    await scores
        .set(course.id, ScoreWrite(studentId: s.id, partId: course.scheme.parts.first.id, value: 5))
        .timeout(const Duration(seconds: 10));

    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(courseEmits.last, 1);
    expect(studentEmits.last, 2);
    expect(scoreEmits.last, 1);

    for (final sub in subs) {
      await sub.cancel();
    }
  });
}
