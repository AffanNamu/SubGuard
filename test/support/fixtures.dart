import 'package:unimarkly/data/repositories/score_repository.dart';
import 'package:unimarkly/domain/defaults.dart';
import 'package:unimarkly/domain/models.dart';
import 'package:unimarkly/domain/scoring.dart';

/// A small AGR 114 course with the default 70 + 10 + 10 + 10 scheme.
class Fixture {
  Fixture({int extraStudents = 0}) {
    course = Course(
      id: 'course-1',
      code: 'AGR 114',
      department: 'FWM',
      session: '2024/2025',
      semester: 'Second',
      scheme: Defaults.nigerianScheme(),
    );
    exam = course.scheme.parts[0];
    attendance = course.scheme.parts[1];
    assignment = course.scheme.parts[2];
    test = course.scheme.parts[3];

    students = [
      const Student(id: 's1', courseId: 'course-1', regNo: 'FWM/24U/0538', position: 0),
      const Student(id: 's2', courseId: 'course-1', regNo: 'FST/25U/244/5772', position: 1),
      const Student(id: 's3', courseId: 'course-1', regNo: 'FWM/24U/0101', position: 2),
      const Student(id: 's4', courseId: 'course-1', regNo: 'ASR/25U/224/0937', position: 3),
      for (var i = 0; i < extraStudents; i++)
        Student(
          id: 'x$i',
          courseId: 'course-1',
          regNo: 'FWM/24U/${(1000 + i).toString().padLeft(4, '0')}',
          position: 4 + i,
        ),
    ];

    scores = {
      // The brief's sample booklet: 1.0 + 1.0 + 2.0 + 5.5 = 9.5.
      's1': {
        exam.id: const PartValue(value: 9.5),
        attendance.id: const PartValue(value: 4),
        assignment.id: const PartValue(value: 3.5),
        test.id: const PartValue(value: 5),
      },
      's2': {
        exam.id: const PartValue(value: 58),
        attendance.id: const PartValue(value: 9),
        assignment.id: const PartValue(value: 8),
        test.id: const PartValue(value: 9.5),
      },
      // Exam only; the rest not entered yet.
      's3': {exam.id: const PartValue(value: 10)},
      // Absent from the exam.
      's4': {
        exam.id: const PartValue.absent(),
        attendance.id: const PartValue(value: 2),
        assignment.id: const PartValue(value: 1),
        test.id: const PartValue(value: 0),
      },
      for (var i = 0; i < extraStudents; i++)
        'x$i': {
          exam.id: PartValue(value: (i % 70).toDouble()),
          attendance.id: PartValue(value: (i % 11).toDouble()),
          assignment.id: PartValue(value: (i % 10) + 0.5),
          test.id: PartValue(value: (i % 10).toDouble()),
        },
    };
  }

  late final Course course;
  late final dynamic exam, attendance, assignment, test;
  late final List<Student> students;
  late final ScoreMap scores;
}
