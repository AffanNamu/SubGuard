import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/domain/defaults.dart';
import 'package:unimarkly/domain/scheme.dart';
import 'package:unimarkly/domain/scoring.dart';

PartSpec part(GradingScheme s, String name) =>
    s.parts.firstWhere((p) => p.name == name);

void main() {
  final scheme = Defaults.nigerianScheme();
  final exam = part(scheme, 'Exam');
  final attendance = part(scheme, 'Attendance');
  final assignment = part(scheme, 'Assignment');
  final testPart = part(scheme, 'Test');

  Map<String, PartValue> values(Map<PartSpec, double> m) =>
      {for (final e in m.entries) e.key.id: PartValue(value: e.value)};

  group('totals', () {
    test('adds up every filled part', () {
      final r = ScoreCalculator.compute(
        scheme,
        values({exam: 55.5, attendance: 8, assignment: 7.5, testPart: 9}),
      );
      expect(r.total, 80);
      expect(r.complete, isTrue);
      expect(r.grade?.letter, 'A');
    });

    test('is null when nothing is filled', () {
      final r = ScoreCalculator.compute(scheme, {});
      expect(r.total, isNull);
      expect(r.complete, isFalse);
      expect(r.grade, isNull);
    });

    test('sums only the filled parts and withholds the grade', () {
      final r = ScoreCalculator.compute(scheme, values({exam: 40}));
      expect(r.total, 40);
      expect(r.complete, isFalse);
      expect(r.grade, isNull);
    });

    test('absent counts as filled, with no marks', () {
      final r = ScoreCalculator.compute(scheme, {
        exam.id: const PartValue(value: 30),
        attendance.id: const PartValue.absent(),
        assignment.id: const PartValue(value: 5),
        testPart.id: const PartValue(value: 5),
      });
      expect(r.total, 40);
      expect(r.complete, isTrue);
      expect(r.grade?.letter, 'E');
    });

    test('scales a part marked out of one number that counts for another', () {
      final custom = const GradingScheme(
        totalExpected: 100,
        parts: [
          PartSpec(id: 'e', name: 'Exam', max: 70, source: PartSource.scanned),
          PartSpec(
              id: 't', name: 'Test', max: 20, markedOutOf: 20, countsFor: 30),
        ],
      );
      final r = ScoreCalculator.compute(custom, {
        'e': const PartValue(value: 50),
        't': const PartValue(value: 10),
      });
      expect(r.total, 65); // 50 + 10/20*30
      expect(custom.partsTotal, 100);
    });

    test('does not drift on scaled halves', () {
      final custom = const GradingScheme(parts: [
        PartSpec(id: 'a', name: 'A', max: 3, markedOutOf: 3, countsFor: 10),
        PartSpec(id: 'b', name: 'B', max: 3, markedOutOf: 3, countsFor: 10),
      ]);
      final r = ScoreCalculator.compute(custom, {
        'a': const PartValue(value: 1),
        'b': const PartValue(value: 2),
      });
      expect(r.total, 10);
    });
  });

  group('grades', () {
    final bands = Defaults.nigerianGradeScale();
    String? g(double t) => ScoreCalculator.gradeFor(bands, t)?.letter;

    test('boundaries of the Nigerian scale', () {
      expect(g(100), 'A');
      expect(g(70), 'A');
      expect(g(69), 'B');
      expect(g(60), 'B');
      expect(g(59), 'C');
      expect(g(50), 'C');
      expect(g(49), 'D');
      expect(g(45), 'D');
      expect(g(44), 'E');
      expect(g(40), 'E');
      expect(g(39), 'F');
      expect(g(0), 'F');
    });

    test('half marks between ranges fall into the lower band', () {
      expect(g(69.5), 'B');
      expect(g(59.5), 'C');
      expect(g(39.5), 'F');
    });

    test('a total above the top band has no grade', () {
      expect(g(100.5), isNull);
    });

    test('a negative total has no grade', () {
      expect(g(-1), isNull);
    });

    test('works with an edited scale', () {
      final custom = [
        const GradeBand(id: '1', minScore: 50, maxScore: 100, letter: 'P', points: 1),
        const GradeBand(id: '2', minScore: 0, maxScore: 49, letter: 'F', points: 0),
      ];
      expect(ScoreCalculator.gradeFor(custom, 50)?.letter, 'P');
      expect(ScoreCalculator.gradeFor(custom, 49.5)?.letter, 'F');
    });

    test('empty scale gives no grade', () {
      expect(ScoreCalculator.gradeFor(const [], 50), isNull);
    });
  });

  group('exam score from question marks', () {
    GradingScheme withRule(CountRule rule, {int? n, List<int> compulsory = const []}) =>
        GradingScheme(
          countRule: rule,
          countN: n,
          questions: [
            for (var i = 1; i <= 6; i++)
              QuestionSpec(id: 'q$i', qNo: i, max: 15, compulsory: compulsory.contains(i)),
          ],
        );

    test('the brief sample: 1.0 + 1.0 + 2.0 + 5.5 = 9.5', () {
      final s = withRule(CountRule.all);
      expect(
        ScoreCalculator.examScoreFromQuestions(s, {1: 1.0, 2: 1.0, 4: 2.0, 5: 5.5}),
        9.5,
      );
    });

    test('best N of M counts only the best answers', () {
      final s = withRule(CountRule.bestN, n: 2);
      expect(
        ScoreCalculator.examScoreFromQuestions(s, {1: 1.0, 2: 1.0, 4: 2.0, 5: 5.5}),
        7.5,
      );
    });

    test('compulsory questions always count, plus best N of the rest', () {
      final s = withRule(CountRule.compulsoryPlusBestN, n: 1, compulsory: [1]);
      expect(
        ScoreCalculator.examScoreFromQuestions(s, {1: 1.0, 2: 1.0, 4: 2.0, 5: 5.5}),
        6.5, // 1 (compulsory) + 5.5
      );
    });

    test('N larger than the answers given counts them all', () {
      final s = withRule(CountRule.bestN, n: 10);
      expect(ScoreCalculator.examScoreFromQuestions(s, {1: 4, 2: 5}), 9);
    });

    test('no marks gives zero', () {
      expect(ScoreCalculator.examScoreFromQuestions(withRule(CountRule.all), {}), 0);
    });
  });

  group('display', () {
    test('decimals follow the step', () {
      expect(ScoreCalculator.decimalsForStep(1), 0);
      expect(ScoreCalculator.decimalsForStep(0.5), 1);
      expect(ScoreCalculator.decimalsForStep(0.25), 2);
    });

    test('attendance shows as a whole number', () {
      expect(ScoreCalculator.formatPartMark(attendance, 4), '4');
    });

    test('typed parts show the decimals their step needs', () {
      expect(ScoreCalculator.formatPartMark(assignment, 4), '4.0');
      expect(ScoreCalculator.formatPartMark(assignment, 4.5), '4.5');
    });

    test('exam shows as the examiner wrote it', () {
      expect(ScoreCalculator.formatPartMark(exam, 9.5), '9.5');
      expect(ScoreCalculator.formatPartMark(exam, 10), '10');
    });

    test('step check', () {
      expect(ScoreCalculator.isOnStep(5.5, 0.5), isTrue);
      expect(ScoreCalculator.isOnStep(5.25, 0.5), isFalse);
      expect(ScoreCalculator.isOnStep(5.25, 0.25), isTrue);
      expect(ScoreCalculator.isOnStep(7.3, 1), isFalse);
    });
  });

  group('MarkParser', () {
    test('plain, decimal and raised-dot marks', () {
      expect(MarkParser.parse('5'), 5);
      expect(MarkParser.parse('5.5'), 5.5);
      expect(MarkParser.parse('5·5'), 5.5);
      expect(MarkParser.parse('5,5'), 5.5);
      expect(MarkParser.parse(' 12 '), 12);
      expect(MarkParser.parse('.5'), 0.5);
    });

    test('rejects text and empty input', () {
      expect(MarkParser.parse(''), isNull);
      expect(MarkParser.parse(null), isNull);
      expect(MarkParser.parse('abc'), isNull);
      expect(MarkParser.parse('5.5.5'), isNull);
      expect(MarkParser.parse('-3'), isNull);
    });

    test('recognises absent', () {
      expect(MarkParser.isAbsentText('ABS'), isTrue);
      expect(MarkParser.isAbsentText('absent'), isTrue);
      expect(MarkParser.isAbsentText('5'), isFalse);
    });
  });
}
