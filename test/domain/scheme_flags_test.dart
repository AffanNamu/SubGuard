import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/domain/defaults.dart';
import 'package:unimarkly/domain/flags.dart';
import 'package:unimarkly/domain/scheme.dart';
import 'package:unimarkly/domain/scheme_codec.dart';
import 'package:unimarkly/domain/scoring.dart';

void main() {
  group('default scheme', () {
    final s = Defaults.nigerianScheme();

    test('is Exam 70 plus 30 for the other parts', () {
      expect(s.partsTotal, 100);
      expect(s.totalExpected, 100);
      expect(s.parts.map((p) => p.name), ['Exam', 'Attendance', 'Assignment', 'Test']);
      expect(s.parts.first.max, 70);
      expect(s.warnings(), isEmpty);
      expect(schemeSummary(s),
          'Exam 70 + Attendance 10 + Assignment 10 + Test 10 = 100');
    });

    test('grade scale matches the commonly used Nigerian scale', () {
      expect(s.bands.map((b) => '${b.letter}${b.minScore.toInt()}-${b.maxScore.toInt()}:${b.points.toInt()}'),
          ['A70-100:5', 'B60-69:4', 'C50-59:3', 'D45-49:2', 'E40-44:1', 'F0-39:0']);
    });

    test('every call gives fresh ids', () {
      final other = Defaults.nigerianScheme();
      expect(other.parts.first.id, isNot(s.parts.first.id));
    });
  });

  group('warnings', () {
    test('parts that do not add up warn but do not change anything', () {
      final s = Defaults.nigerianScheme();
      final changed = s.copyWith(parts: [
        for (final p in s.parts) p.name == 'Test' ? p.copyWith(max: 5) : p,
      ]);
      final w = changed.warnings();
      expect(w.map((e) => e.kind), contains(SchemeWarningKind.partsDoNotAddUp));
      expect(w.first.message, contains('95'));
      expect(changed.parts.last.max, 5);
    });

    test('four questions of 15 cannot make 70', () {
      final s = Defaults.nigerianScheme().copyWith(questions: [
        for (var i = 1; i <= 4; i++) QuestionSpec(id: 'q$i', qNo: i, max: 15),
      ]);
      expect(s.reachableExamScore, 60);
      expect(s.warnings().map((e) => e.kind),
          contains(SchemeWarningKind.questionsCannotReachExamMax));
    });

    test('best 4 of 6 questions of 15 cannot make 70 either', () {
      final s = Defaults.nigerianScheme().copyWith(
        countRule: CountRule.bestN,
        countN: 4,
        questions: [for (var i = 1; i <= 6; i++) QuestionSpec(id: 'q$i', qNo: i, max: 15)],
      );
      expect(s.reachableExamScore, 60);
    });

    test('compulsory plus best N is counted', () {
      final s = Defaults.nigerianScheme().copyWith(
        countRule: CountRule.compulsoryPlusBestN,
        countN: 2,
        questions: [
          const QuestionSpec(id: 'a', qNo: 1, max: 30, compulsory: true),
          const QuestionSpec(id: 'b', qNo: 2, max: 20),
          const QuestionSpec(id: 'c', qNo: 3, max: 20),
          const QuestionSpec(id: 'd', qNo: 4, max: 10),
        ],
      );
      expect(s.reachableExamScore, 70);
      expect(s.warnings(), isEmpty);
    });

    test('questions that can reach the maximum raise no warning', () {
      final s = Defaults.nigerianScheme().copyWith(questions: [
        for (var i = 1; i <= 5; i++) QuestionSpec(id: 'q$i', qNo: i, max: 14),
      ]);
      expect(s.warnings(), isEmpty);
    });

    test('minimum above maximum, bad step and duplicate names', () {
      final s = const GradingScheme(totalExpected: 20, parts: [
        PartSpec(id: 'a', name: 'Test', max: 10, min: 12),
        PartSpec(id: 'b', name: 'test', max: 10, step: 0),
      ]);
      final kinds = s.warnings().map((e) => e.kind);
      expect(kinds, containsAll([
        SchemeWarningKind.badPartLimits,
        SchemeWarningKind.duplicatePartName,
      ]));
    });

    test('overlapping grade bands', () {
      final s = Defaults.nigerianScheme().copyWith(bands: [
        const GradeBand(id: '1', minScore: 50, maxScore: 100, letter: 'P', points: 1),
        const GradeBand(id: '2', minScore: 0, maxScore: 55, letter: 'F', points: 0),
      ]);
      expect(s.warnings().map((e) => e.kind), contains(SchemeWarningKind.gradeScaleOverlap));
    });
  });

  group('template codec', () {
    test('round-trips everything but ids', () {
      final original = Defaults.nigerianScheme().copyWith(
        countRule: CountRule.bestN,
        countN: 3,
        questions: [const QuestionSpec(id: 'x', qNo: 1, max: 20, compulsory: true)],
        parts: [
          const PartSpec(
            id: 'p',
            name: 'Quiz 2',
            max: 20,
            min: 1,
            passMark: 8,
            step: 0.25,
            markedOutOf: 20,
            countsFor: 10,
            source: PartSource.imported,
          ),
        ],
      );
      final copy = SchemeCodec.freshCopy(original);
      final p = copy.parts.single;
      expect(p.name, 'Quiz 2');
      expect(p.max, 20);
      expect(p.min, 1);
      expect(p.passMark, 8);
      expect(p.step, 0.25);
      expect(p.markedOutOf, 20);
      expect(p.countsFor, 10);
      expect(p.source, PartSource.imported);
      expect(copy.countRule, CountRule.bestN);
      expect(copy.countN, 3);
      expect(copy.questions.single.compulsory, isTrue);
      expect(copy.bands.length, 6);
      expect(p.id, isNot('p'));
    });
  });

  group('flags', () {
    final scheme = Defaults.nigerianScheme();
    final exam = scheme.parts[0];
    final attendance = scheme.parts[1];

    Map<String, List<ScoreFlag>> run(
      List<FlagInput> students,
      Map<String, Map<String, PartValue>> scores, [
      GradingScheme? s,
    ]) =>
        FlagChecker.check(scheme: s ?? scheme, students: students, scores: scores);

    Set<FlagKind> kinds(List<ScoreFlag>? f) => (f ?? []).map((e) => e.kind).toSet();

    const ok = FlagInput(studentId: 's1', regNo: 'FWM/24U/0538', onClassList: true);

    test('a clean student has no flags', () {
      final r = run([ok], {
        's1': {exam.id: const PartValue(value: 50), attendance.id: const PartValue(value: 9)},
      });
      expect(r, isEmpty);
    });

    test('mark above the maximum, from the scheme', () {
      final r = run([ok], {'s1': {exam.id: const PartValue(value: 71)}});
      expect(kinds(r['s1']), contains(FlagKind.aboveMax));
      expect(r['s1']!.first.partId, exam.id);
      expect(r['s1']!.first.message, contains('maximum of 70'));
    });

    test('limits follow an edited scheme and are never hard-coded', () {
      final edited = scheme.copyWith(parts: [
        exam.copyWith(max: 60),
        ...scheme.parts.skip(1),
      ]);
      final scores = {'s1': {exam.id: const PartValue(value: 65)}};
      expect(kinds(run([ok], scores)['s1']), isNot(contains(FlagKind.aboveMax)));
      expect(kinds(run([ok], scores, edited)['s1']), contains(FlagKind.aboveMax));
    });

    test('mark below the minimum', () {
      final edited = scheme.copyWith(parts: [
        exam.copyWith(min: 5),
        ...scheme.parts.skip(1),
      ]);
      final r = run([ok], {'s1': {exam.id: const PartValue(value: 3)}}, edited);
      expect(kinds(r['s1']), contains(FlagKind.belowMin));
    });

    test('mark off the step', () {
      final r = run([ok], {'s1': {attendance.id: const PartValue(value: 7.5)}});
      expect(kinds(r['s1']), contains(FlagKind.offStep));
    });

    test('below the pass mark is info, not attention', () {
      final edited = scheme.copyWith(parts: [
        exam.copyWith(passMark: 35),
        ...scheme.parts.skip(1),
      ]);
      final r = run([ok], {'s1': {exam.id: const PartValue(value: 20)}}, edited);
      final f = r['s1']!.single;
      expect(f.kind, FlagKind.belowPass);
      expect(f.needsAttention, isFalse);
    });

    test('total above the maximum comes from the scheme', () {
      final loose = scheme.copyWith(parts: [
        for (final p in scheme.parts) p.copyWith(max: 100, countsFor: 100),
      ]);
      final r = run([ok], {
        's1': {
          for (final p in loose.parts) p.id: const PartValue(value: 40),
        },
      }, loose);
      expect(kinds(r['s1']), contains(FlagKind.totalAboveMax));
    });

    test('duplicates are found even when written differently', () {
      final r = run([
        ok,
        const FlagInput(studentId: 's2', regNo: 'fwm/244/0538', onClassList: true),
      ], {});
      expect(kinds(r['s1']), contains(FlagKind.duplicateRegNo));
      expect(kinds(r['s2']), contains(FlagKind.duplicateRegNo));
    });

    test('invalid pattern and not on the class list', () {
      final r = run([
        const FlagInput(studentId: 's3', regNo: 'NOPE', onClassList: false),
      ], {});
      expect(kinds(r['s3']), {FlagKind.invalidRegNo, FlagKind.notOnClassList});
    });

    test('absent and empty cells raise nothing', () {
      final r = run([ok], {'s1': {exam.id: const PartValue.absent()}});
      expect(r, isEmpty);
    });
  });
}
