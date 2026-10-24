import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/domain/recognition.dart';
import 'package:unimarkly/domain/scheme.dart';
import 'package:unimarkly/services/recognition/validation.dart';

/// Checking marks against the rules. A check is a message; it never changes a
/// mark, and a written total that disagrees with the marks keeps both numbers.
void main() {
  const exam = PartSpec(id: 'exam', name: 'Exam', max: 70, step: 0.5, source: PartSource.scanned);
  final scheme = GradingScheme(
    countRule: CountRule.all,
    parts: const [exam],
    questions: [for (var q = 1; q <= 6; q++) QuestionSpec(id: 'q$q', qNo: q, max: 20)],
  );
  final validator = SchemeExaminationValidator(scheme);

  List<String> codes(List<ValidationFinding> f) => [for (final x in f) x.code];

  group('marks against the scheme', () {
    test('a clean booklet has no findings', () {
      expect(validator.validate(const ExamSnapshot(marks: {1: 1.0, 2: 1.0, 4: 2.0, 5: 5.5}, writtenTotal: 9.5)), isEmpty);
    });

    test('a mark above the question maximum is a danger and names the question', () {
      final f = validator.validate(const ExamSnapshot(marks: {1: 25}));
      expect(codes(f), contains('mark_above_max'));
      expect(f.firstWhere((x) => x.code == 'mark_above_max').severity, FindingSeverity.danger);
      expect(f.first.message, 'Q1: 25 is above the question maximum of 20.');
    });

    test('a mark that is not a multiple of the step is a warning', () {
      final f = validator.validate(const ExamSnapshot(marks: {3: 4.3}));
      expect(codes(f), ['mark_off_step']);
      expect(f.single.severity, FindingSeverity.warning);
    });

    test('marks adding up to more than the part maximum is a danger', () {
      final f = validator.validate(const ExamSnapshot(marks: {1: 20, 2: 20, 3: 20, 4: 20}));
      expect(codes(f), contains('exam_above_max'));
      expect(f.firstWhere((x) => x.code == 'exam_above_max').message, contains('above the Exam maximum of 70'));
    });
  });

  group('a written total that disagrees with the marks', () {
    test('handwritten sum 38 against a written total of 36: both are kept and the difference is reported', () {
      final marks = {1: 10.0, 2: 8.0, 3: 20.0}; // adds to 38
      final f = validator.validate(ExamSnapshot(marks: marks, writtenTotal: 36));
      expect(codes(f), ['total_mismatch']);
      final msg = f.single.message;
      expect(msg, contains('wrote 36'));
      expect(msg, contains('add up to 38'));
      // The validator reports; it does not hand back a corrected set of marks.
      expect(marks, {1: 10.0, 2: 8.0, 3: 20.0});
      expect(f.single.fields, ['total_written']);
    });

    test('a total that agrees raises nothing', () {
      expect(validator.validate(const ExamSnapshot(marks: {1: 10, 2: 8}, writtenTotal: 18)), isEmpty);
    });

    test('no total written raises nothing', () {
      expect(validator.validate(const ExamSnapshot(marks: {1: 10})), isEmpty);
    });
  });

  group('the questions-answered line', () {
    test('marks for a question not on the line are reported', () {
      final f = validator.validate(const ExamSnapshot(marks: {1: 5, 3: 5}, answeredLine: '4, 5, 1, 2'));
      expect(codes(f), ['answered_mismatch']);
      expect(f.single.message, contains('Q1, Q3'));
    });

    test('marks for every listed question are fine', () {
      expect(validator.validate(const ExamSnapshot(marks: {1: 5, 2: 5, 4: 5}, answeredLine: '4, 5, 1, 2')), isEmpty);
    });
  });

  group('what a machine read', () {
    ExtractedField row(int i, {String? value, String? question, FieldState state = FieldState.needsReview}) => ExtractedField(
          key: 'mark_row_$i',
          kind: FieldKind.mark,
          state: state,
          value: value,
          question: question,
        );

    ExtractedField total(String? value) => ExtractedField(key: 'total_written', kind: FieldKind.mark, state: FieldState.needsReview, value: value);

    test('rows with a clean question and mark become a snapshot', () {
      final s = ReadingChecks.snapshotOf([row(1, value: '1.0', question: '1'), row(2, value: '5.5', question: '5')]);
      expect(s.complete, isTrue);
      expect(s.snapshot.marks, {1: 1.0, 5: 5.5});
      expect(s.findings, isEmpty);
    });

    test('a mark with an unreadable character is not used and is reported', () {
      final s = ReadingChecks.snapshotOf([row(1, value: '1?0', question: '1')]);
      expect(s.complete, isFalse);
      expect(s.snapshot.marks, isEmpty);
      expect(codes(s.findings), ['mark_unclear']);
    });

    test('a mark whose question number is unknown is not assigned to any question', () {
      final s = ReadingChecks.snapshotOf([row(1, value: '2.0', question: null)]);
      expect(s.complete, isFalse);
      expect(codes(s.findings), ['question_unclear']);
    });

    test('two rows claiming the same question are both set aside', () {
      final s = ReadingChecks.snapshotOf([row(1, value: '2.0', question: '3'), row(2, value: '4.0', question: '3')]);
      expect(codes(s.findings), ['duplicate_question']);
      expect(s.snapshot.marks, isEmpty);
      expect(s.findings.single.fields, ['mark_row_1', 'mark_row_2']);
    });

    test('an unreadable row makes the sum incomplete, so the written total is not compared', () {
      final fields = [
        row(1, value: '10', question: '1'),
        row(2, state: FieldState.unreadable),
        total('36'),
      ];
      final f = ReadingChecks.validate(fields, validator);
      expect(codes(f), isNot(contains('total_mismatch')), reason: 'a sum with a missing row proves nothing about the total');
    });

    test('a complete reading with a different written total reports the mismatch', () {
      final fields = [
        row(1, value: '10', question: '1'),
        row(2, value: '8', question: '2'),
        row(3, value: '20', question: '3'),
        total('36'),
      ];
      final f = ReadingChecks.validate(fields, validator);
      expect(codes(f), ['total_mismatch']);
    });
  });
}
