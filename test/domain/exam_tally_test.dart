import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/domain/defaults.dart';
import 'package:unimarkly/domain/exam_tally.dart';
import 'package:unimarkly/domain/ids.dart';
import 'package:unimarkly/domain/mark_rules.dart';
import 'package:unimarkly/domain/mark_sheet.dart';
import 'package:unimarkly/domain/ocr.dart';
import 'package:unimarkly/domain/recognition.dart';
import 'package:unimarkly/domain/row_suggestions.dart';
import 'package:unimarkly/domain/scheme.dart';
import 'package:unimarkly/domain/scheme_codec.dart';

/// The arithmetic and the records, as deterministic unit tests: no photograph and no
/// recogniser are involved, so these prove the scoring rules and nothing else. Whether the
/// right values reach them from a photograph is tested against the real photograph in
/// test/recognition/question_marks_real_test.dart.
void main() {
  GradingScheme scheme({
    List<QuestionSpec> questions = const [],
    CountRule rule = CountRule.all,
    int? countN,
    UnmarkedRule unmarked = UnmarkedRule.zero,
    double step = 0.5,
  }) {
    final base = Defaults.nigerianScheme();
    return base.copyWith(
      questions: questions,
      countRule: rule,
      countN: countN,
      unmarked: unmarked,
      parts: [for (final p in base.parts) p.isExamLike ? p.copyWith(step: step) : p],
    );
  }

  QuestionSpec q(int n, {double max = 10, bool compulsory = false, double weight = 1}) =>
      QuestionSpec(id: newId(), qNo: n, max: max, compulsory: compulsory, weight: weight);

  ExamTally tally(GradingScheme s, Map<int, double> marks) => ExamTally.compute(s, [for (final e in marks.entries) TallyMark(e.key, e.value)]);

  group('the total is the sum of the confirmed marks', () {
    test('four questions with nonconsecutive numbers, Q1 Q2 Q4 Q5: 1.0 + 1.0 + 2.0 + 5.5 = 9.5', () {
      final t = tally(scheme(), {1: 1.0, 2: 1.0, 4: 2.0, 5: 5.5});
      expect(t.calculated, 9.5);
      expect(t.counted.keys, [1, 2, 4, 5]);
      expect(t.unmarked, isEmpty, reason: 'with no question list nothing is missing; Q3 is not invented');
      expect(t.duplicates, isEmpty);
    });

    test('with a question list, the question that has no mark is reported and adds nothing', () {
      final s = scheme(questions: [for (var i = 1; i <= 5; i++) q(i)]);
      final t = tally(s, {1: 1.0, 2: 1.0, 4: 2.0, 5: 5.5});
      expect(t.calculated, 9.5);
      expect(t.unmarked, [3]);
      expect(t.assumptions.join(' '), contains('Q3'));
      expect(t.assumptions.join(' '), anyOf(contains('count as zero'), contains('counts as zero')));
    });

    test('a paper with fewer than ten questions, and one with more, with numbers that are not in order', () {
      expect(tally(scheme(), {1: 4, 2: 6}).calculated, 10);
      final many = {for (var i = 1; i <= 25; i++) i: 2.0};
      expect(tally(scheme(), many).calculated, 50);
      // Numbers far apart: nothing between them is made up.
      final t = tally(scheme(), {3: 1.5, 47: 2.5, 120: 3});
      expect(t.calculated, 7);
      expect(t.counted.keys, [3, 47, 120]);
    });

    test('nothing confirmed gives no total, not zero', () {
      expect(tally(scheme(), const {}).calculated, isNull);
    });

    test('a mark of zero is a mark: it is counted and the total is 0, not "none"', () {
      final t = tally(scheme(), {1: 0});
      expect(t.calculated, 0);
    });

    test('decimal marks add exactly (no 8.499999)', () {
      expect(tally(scheme(), {1: 4, 2: 4.5}).calculated, 8.5);
      expect(tally(scheme(step: 0.25), {1: 0.25, 2: 0.5, 3: 12.25}).calculated, 13);
    });

    test('a question number given twice is counted once and reported', () {
      final t = ExamTally.compute(scheme(), const [TallyMark(4, 2), TallyMark(4, 5.5), TallyMark(1, 1)]);
      expect(t.calculated, 3, reason: 'the first mark for Q4 counts, the second does not add on');
      expect(t.duplicates, [4]);
    });
  });

  group('counting rules', () {
    test('best N: the best three of four count and the other is reported as left out', () {
      final s = scheme(rule: CountRule.bestN, countN: 3, questions: [for (var i = 1; i <= 4; i++) q(i)]);
      final t = tally(s, {1: 8, 2: 3, 3: 9, 4: 6});
      expect(t.calculated, 23);
      expect(t.counted.keys.toSet(), {1, 3, 4});
      expect(t.leftOut, {2: 3.0});
      expect(t.assumptions.join(' '), contains('Q2'));
    });

    test('best N with fewer answered than N: what was answered counts', () {
      final s = scheme(rule: CountRule.bestN, countN: 4);
      expect(tally(s, {1: 8, 2: 3}).calculated, 11);
    });

    test('compulsory plus best N: compulsory questions always count, then the best of the rest', () {
      final s = scheme(rule: CountRule.compulsoryPlusBestN, countN: 1, questions: [q(1, compulsory: true), q(2), q(3), q(4)]);
      final t = tally(s, {1: 2, 2: 9, 3: 7, 4: 1});
      expect(t.calculated, 11, reason: 'Q1 (compulsory) 2 + the best optional, Q2 9');
      expect(t.leftOut.keys.toSet(), {3, 4});
    });

    test('an optional question the candidate left out does not hold a slot or add a mark', () {
      final s = scheme(rule: CountRule.compulsoryPlusBestN, countN: 2, questions: [q(1, compulsory: true), q(2), q(3), q(4)]);
      final t = tally(s, {1: 5, 3: 6});
      expect(t.calculated, 11);
      expect(t.unmarked, [2, 4]);
    });

    test('ties in best N are settled by question number, the same way every time', () {
      final s = scheme(rule: CountRule.bestN, countN: 1);
      final t = tally(s, {5: 4, 2: 4, 9: 4});
      expect(t.counted.keys, [2]);
    });

    test('a weight multiplies the mark: Q2 counts double', () {
      final s = scheme(questions: [q(1), q(2, weight: 2), q(3)]);
      final t = tally(s, {1: 3, 2: 4, 3: 1});
      expect(t.calculated, 12);
      expect(t.sumOfMarks, 8, reason: 'the marks as written, before weights');
      expect(t.assumptions.join(' '), contains('Q2'));
    });

    test('weights decide which marks are best in best N', () {
      final s = scheme(rule: CountRule.bestN, countN: 1, questions: [q(1), q(2, weight: 3)]);
      final t = tally(s, {1: 7, 2: 3});
      expect(t.calculated, 9);
      expect(t.counted.keys, [2]);
    });

    test('the most the questions can add follows the rule and the weights', () {
      expect(scheme(questions: [q(1), q(2, weight: 2)]).reachableExamScore, 30);
      expect(scheme(rule: CountRule.bestN, countN: 1, questions: [q(1, max: 10), q(2, max: 5, weight: 3)]).reachableExamScore, 15);
      expect(tally(scheme(questions: [q(1), q(2)]), {1: 1}).maxPossible, 20);
      expect(tally(scheme(), {1: 1}).maxPossible, isNull, reason: 'no question list, no maximum is claimed');
    });

    test('a counting rule with no N says so and counts everything', () {
      final s = scheme(rule: CountRule.bestN);
      final t = tally(s, {1: 1, 2: 2});
      expect(t.calculated, 3);
      expect(t.assumptions.join(' '), contains('no number is set'));
    });
  });

  group('the written total and the calculated total stay apart', () {
    test('a blank written total does not stop the total being calculated', () {
      final t = tally(scheme(), {1: 1, 2: 1, 4: 2, 5: 5.5});
      final c = TotalComparison.of(calculated: t.calculated, written: null);
      expect(t.calculated, 9.5);
      expect(c.agreement, TotalAgreement.notComparable);
    });

    test('a written total that matches', () {
      expect(TotalComparison.of(calculated: 9.5, written: 9.5).agreement, TotalAgreement.agree);
    });

    test('a written total that disagrees is a discrepancy with its size, and neither value changes', () {
      final c = TotalComparison.of(calculated: 9.5, written: 10.5);
      expect(c.agreement, TotalAgreement.disagree);
      expect(c.difference, 1.0);
      expect(TotalComparison.of(calculated: 9.5, written: 9).difference, -0.5);
    });

    test('nothing calculated yet, nothing to compare', () {
      expect(TotalComparison.of(calculated: null, written: 9).agreement, TotalAgreement.notComparable);
    });
  });

  group('plausibility: what can be offered as a mark or a question number', () {
    final rules = MarkRules.forScheme(scheme(), qNo: null); // exam part: max 70, step 0.5

    test('the digit strings a recogniser makes of "1.0" are not marks', () {
      for (final raw in ['147', '141', '140', '180', '187']) {
        final p = rules.check(raw);
        expect(p.plausible, isFalse, reason: raw);
        expect(p.why, Why.aboveMaximum, reason: raw);
        expect(p.reason, contains('above the most this can be (70)'));
      }
    });

    test('a decimal that is not on the mark step is not offered, and is not rounded into one', () {
      final p = rules.check('2.61');
      expect(p.plausible, isFalse);
      expect(p.why, Why.offStep);
      expect(p.value, isNull, reason: 'no value is made out of it');
    });

    test('whole and half marks, and zero, are plausible; a partial reading is not', () {
      for (final ok in ['0', '1.0', '1', '5.5', '12.5', '70']) {
        expect(rules.check(ok).plausible, isTrue, reason: ok);
      }
      for (final no in ['', '1?0', '.5', '5.', '1.2.3', '-1', '1..0']) {
        expect(rules.check(no).plausible, isFalse, reason: no);
      }
    });

    test('a question own maximum is used when it has one', () {
      final s = scheme(questions: [q(1, max: 5), q(2, max: 20)]);
      expect(MarkRules.forScheme(s, qNo: 1).check('7').plausible, isFalse);
      expect(MarkRules.forScheme(s, qNo: 2).check('7').plausible, isTrue);
      expect(MarkRules.forScheme(s, qNo: 9).check('7').plausible, isTrue, reason: 'not on the list: judged against the exam maximum');
    });

    test('marks in whole numbers only, when the step is 1', () {
      final whole = MarkRules.forScheme(scheme(step: 1));
      expect(whole.check('3').plausible, isTrue);
      expect(whole.check('3.5').plausible, isFalse);
    });

    test('question numbers are whole numbers from 1 to the limit the examiner set', () {
      const r = QuestionRules(highest: 12);
      for (final ok in ['1', '4', '12']) {
        expect(r.check(ok).plausible, isTrue, reason: ok);
      }
      expect(r.check('0').why, Why.belowOne);
      expect(r.check('13').why, Why.aboveLimit);
      expect(r.check('100').why, Why.aboveLimit);
      expect(r.check('1.5').plausible, isFalse);
      expect(r.check('?').plausible, isFalse);
      expect(const QuestionRules(highest: 150).check('100').plausible, isTrue, reason: 'the limit is a setting');
    });
  });

  group('suggestions for a row: one list for the question number, another for the mark', () {
    ExtractedField mark(int i, {String? raw, List<String> candidates = const []}) => ExtractedField(
          key: 'mark_row_$i',
          kind: FieldKind.mark,
          state: FieldState.needsReview,
          value: raw,
          candidates: [for (final (k, c) in candidates.indexed) FieldCandidate(c, 0.9 - k * 0.1, source: 'unimarkly-digits/red_ink')],
          attempts: [ReadAttempt(reader: 'unimarkly-digits', readerVersion: '1', variant: 'red_ink', text: raw)],
        );
    ExtractedField question(int i, {String? raw, List<String> candidates = const []}) => ExtractedField(
          key: 'question_row_$i',
          kind: FieldKind.questionNumber,
          state: FieldState.needsReview,
          value: candidates.isEmpty ? null : candidates.first,
          candidates: [for (final (k, c) in candidates.indexed) FieldCandidate(c, 0.9 - k * 0.1, source: 'digit_net/label')],
          attempts: [ReadAttempt(reader: 'unimarkly-digits', readerVersion: '1', variant: 'red_ink', text: raw)],
        );

    RowSuggestions of(ExtractedField m, ExtractedField? qf, {GradingScheme? s}) => RowSuggestions.of(
          index: 1,
          mark: m,
          question: qf,
          marksFor: (n) => MarkRules.forScheme(s ?? scheme(), qNo: n),
          questionRules: const QuestionRules(highest: 60),
        );

    test('implausible readings are left out of the alternatives and kept as evidence with the reason', () {
      final r = of(mark(1, raw: '147', candidates: ['147', '187', '140']), question(1, raw: '7.1', candidates: ['1']));
      expect(r.markAlternatives, isEmpty);
      expect(r.markReadable, isFalse);
      expect(r.markLeftOut.map((o) => o.text), containsAll(['147', '187', '140']));
      expect(r.rawMark, '147', reason: 'the raw reading is kept exactly as read');
      expect(r.questionAlternatives.map((c) => c.text), ['1']);
    });

    test('question alternatives and mark alternatives never mix: a mark is not offered as a question and the reverse', () {
      final r = of(mark(2, raw: '1.0', candidates: ['1.0', '9.0']), question(2, raw: '2', candidates: ['2', '7']));
      expect(r.markAlternatives.map((c) => c.text), ['1.0', '9.0']);
      expect(r.questionAlternatives.map((c) => c.text), ['2', '7']);
      // Decimals cannot be question numbers; the question cell's alternatives are whole numbers only.
      final strange = of(mark(2, raw: '1.0', candidates: ['1.0']), question(2, raw: '1.5', candidates: ['1.5', '3']));
      expect(strange.questionAlternatives.map((c) => c.text), ['3']);
      expect(strange.questionLeftOut.map((o) => o.text), ['1.5']);
    });

    test('a row whose question number cannot be read is "unclear", and the mark is not used to guess it', () {
      final r = of(mark(5, raw: '2.0', candidates: ['2.0']), question(5, raw: '?'));
      expect(r.questionReadable, isFalse);
      expect(r.questionAlternatives, isEmpty);
      expect(r.markAlternatives.map((c) => c.text), ['2.0']);
    });

    test('the same reading twice is one alternative', () {
      final r = of(mark(1, raw: '5.5', candidates: ['5.5', '5.5', '3.5']), question(1, raw: '5', candidates: ['5', '5']));
      expect(r.markAlternatives.map((c) => c.text), ['5.5', '3.5']);
      expect(r.questionAlternatives.map((c) => c.text), ['5']);
    });
  });

  group('the records of a review', () {
    ExtractedField markField(int i, List<String> alts, {String? raw}) => ExtractedField(
          key: 'mark_row_$i',
          kind: FieldKind.mark,
          state: FieldState.needsReview,
          value: raw ?? (alts.isEmpty ? null : alts.first),
          candidates: [for (final (k, c) in alts.indexed) FieldCandidate(c, 0.9 - k * 0.1)],
          attempts: [ReadAttempt(reader: 'r', readerVersion: '1', variant: 'v', text: raw ?? (alts.isEmpty ? null : alts.first))],
          region: Region(0.78, 0.3 + i * 0.05, 0.98, 0.34 + i * 0.05),
        );
    ExtractedField questionField(int i, String? text) => ExtractedField(
          key: 'question_row_$i',
          kind: FieldKind.questionNumber,
          state: FieldState.needsReview,
          value: text,
          candidates: [if (text != null) FieldCandidate(text, 0.9)],
          attempts: [ReadAttempt(reader: 'r', readerVersion: '1', variant: 'v', text: text)],
        );

    MarkSheet sheetOf(Map<int, (String?, List<String>)> rows, {GradingScheme? s}) {
      final fields = <ExtractedField>[];
      for (final e in rows.entries) {
        fields.add(markField(e.key, e.value.$2));
        fields.add(questionField(e.key, e.value.$1));
      }
      return MarkSheet.fromRows(RowSuggestions.allOf(
        fields,
        marksFor: (n) => MarkRules.forScheme(s ?? scheme(), qNo: n),
        questionRules: const QuestionRules(highest: 60),
      ));
    }

    test('the records are exactly the rows found: four rows, four records, nothing else', () {
      final sheet = sheetOf({1: ('1', ['1.0']), 2: ('2', ['1.0']), 3: ('4', ['2.0']), 4: ('5', ['5.5'])});
      expect(sheet.records, hasLength(4));
      expect(sheet.records.map((r) => r.key), ['mark_row_1', 'mark_row_2', 'mark_row_3', 'mark_row_4']);
      expect(sheet.records.every((r) => !r.manual), isTrue);
    });

    test('suggestions are not values: nothing is confirmed, so there is no total, until the examiner confirms', () {
      final sheet = sheetOf({1: ('1', ['1.0']), 2: ('2', ['1.0'])});
      expect(sheet.confirmedMarks, isEmpty);
      expect(sheet.tally(scheme()).calculated, isNull);
      expect(sheet.records.every((r) => !r.hasQuestion && !r.hasMark), isTrue);
      expect(sheet.problems(scheme()).where((p) => p.blocks), hasLength(4), reason: 'two rows x (question and mark) still to confirm');
    });

    test('confirming both fields of each row gives 9.5 for Q1 Q2 Q4 Q5, and each change moves the total at once', () {
      var sheet = sheetOf({1: ('1', ['1.0']), 2: ('2', ['1.0']), 3: ('4', ['2.0']), 4: ('5', ['5.5'])});
      final values = {1: (1, 1.0), 2: (2, 1.0), 3: (4, 2.0), 4: (5, 5.5)};
      for (final e in values.entries) {
        sheet = sheet.setQuestion('mark_row_${e.key}', e.value.$1).setMark('mark_row_${e.key}', e.value.$2);
      }
      expect(sheet.tally(scheme()).calculated, 9.5);
      // The examiner corrects Q4: 2.0 becomes 3.0.
      sheet = sheet.setMark('mark_row_3', 3.0);
      expect(sheet.tally(scheme()).calculated, 10.5);
      // Takes Q2 out of the total (it is not a mark).
      sheet = sheet.dismiss('mark_row_2');
      expect(sheet.tally(scheme()).calculated, 9.5);
      // Puts it back.
      sheet = sheet.restore('mark_row_2');
      expect(sheet.tally(scheme()).calculated, 10.5);
      // Clears a mark: that row no longer counts, and is something still to decide.
      sheet = sheet.setMark('mark_row_4', null);
      expect(sheet.tally(scheme()).calculated, 5);
      expect(sheet.problems(scheme()).where((p) => p.blocks).map((p) => p.issue), [RecordIssue.markMissing]);
    });

    test('two candidate readings for one mark: choosing one, then the other, replaces it. Only one value counts', () {
      var sheet = sheetOf({1: ('1', ['1.0', '9.0'])});
      sheet = sheet.setQuestion('mark_row_1', 1).setMark('mark_row_1', 1.0);
      expect(sheet.tally(scheme()).calculated, 1);
      sheet = sheet.setMark('mark_row_1', 9.0);
      expect(sheet.tally(scheme()).calculated, 9, reason: 'replaced, not 10');
      expect(sheet.confirmedMarks, hasLength(1));
    });

    test('a question number that could not be read stays unconfirmed, blocks, and its mark is not counted under a guessed number', () {
      var sheet = sheetOf({1: (null, ['2.0']), 2: ('1', ['1.0'])});
      sheet = sheet.setMark('mark_row_1', 2.0).setQuestion('mark_row_2', 1).setMark('mark_row_2', 1.0);
      expect(sheet.records.first.suggestions!.questionReadable, isFalse);
      expect(sheet.tally(scheme()).calculated, 1, reason: 'row 1 has a mark but no question number: it is not counted until the examiner says which question it is');
      final problems = sheet.problems(scheme());
      expect(problems.where((p) => p.blocks).map((p) => p.issue), [RecordIssue.questionMissing]);
      sheet = sheet.setQuestion('mark_row_1', 4);
      expect(sheet.tally(scheme()).calculated, 3);
      expect(sheet.problems(scheme()).where((p) => p.blocks), isEmpty);
    });

    test('two rows with the same question number block confirming and count once', () {
      var sheet = sheetOf({1: ('4', ['2.0']), 2: ('4', ['5.5'])});
      sheet = sheet.setQuestion('mark_row_1', 4).setMark('mark_row_1', 2).setQuestion('mark_row_2', 4).setMark('mark_row_2', 5.5);
      expect(sheet.tally(scheme()).duplicates, [4]);
      expect(sheet.tally(scheme()).calculated, 2);
      expect(sheet.problems(scheme()).where((p) => p.issue == RecordIssue.duplicateQuestion && p.blocks), hasLength(2));
    });

    test('a question the examiner adds is a record of its own; the machine rows are untouched', () {
      var sheet = sheetOf({1: ('1', ['1.0'])});
      sheet = sheet.addManual(qNo: 7).setMark('manual-1', 3.5);
      expect(sheet.records, hasLength(2));
      expect(sheet.byKey('manual-1')!.manual, isTrue);
      expect(sheet.tally(scheme()).calculated, 3.5);
      sheet = sheet.addManual(qNo: 8);
      expect(sheet.byKey('manual-2')!.qNo, 8);
      sheet = sheet.remove('manual-1');
      expect(sheet.records.map((r) => r.key), ['mark_row_1', 'manual-2']);
      sheet = sheet.remove('mark_row_1');
      expect(sheet.byKey('mark_row_1'), isNotNull, reason: 'a machine row is dismissed, never removed');
    });

    test('a mark above the question maximum or off the step is flagged, not changed', () {
      final s = scheme(questions: [q(1, max: 5)]);
      var sheet = sheetOf({1: ('1', const [])}, s: s).setQuestion('mark_row_1', 1).setMark('mark_row_1', 7.25);
      final flags = sheet.problems(s).where((p) => !p.blocks).map((p) => p.issue).toList();
      expect(flags, contains(RecordIssue.aboveMaximum));
      expect(sheet.byKey('mark_row_1')!.mark, 7.25, reason: 'what the examiner confirmed is kept as typed');
    });

    test('a question that is not on the course list is flagged as a warning only', () {
      final s = scheme(questions: [q(1), q(2)]);
      final sheet = sheetOf({1: ('9', ['3.0'])}, s: s).setQuestion('mark_row_1', 9).setMark('mark_row_1', 3);
      expect(sheet.problems(s).where((p) => p.issue == RecordIssue.notOnPaper && !p.blocks), hasLength(1));
      expect(sheet.tally(s).calculated, 3);
    });

    test('under "ask me about each one", an unmarked question on the list is something to resolve; under "zero" it is not', () {
      final ask = scheme(questions: [q(1), q(2), q(3)], unmarked: UnmarkedRule.ask);
      final zero = scheme(questions: [q(1), q(2), q(3)]);
      final sheet = sheetOf({1: ('1', ['1.0'])}).setQuestion('mark_row_1', 1).setMark('mark_row_1', 1);
      expect(sheet.problems(ask).where((p) => p.issue == RecordIssue.unmarkedQuestion && p.blocks).length, 2);
      expect(sheet.problems(zero).where((p) => p.issue == RecordIssue.unmarkedQuestion), isEmpty);
      // Giving Q2 a mark of 0 resolves it.
      final withZero = sheet.addManual(qNo: 2, mark: 0).addManual(qNo: 3, mark: 0);
      expect(withZero.problems(ask).where((p) => p.blocks), isEmpty);
      expect(withZero.tally(ask).calculated, 1);
    });
  });

  group('templates and the stored scheme keep weights and the unmarked rule', () {
    test('survive being saved as a template and used for a new course', () {
      // Round trip through the same codec the templates table uses.
      final original = scheme(questions: [q(1, weight: 2), q(2)], unmarked: UnmarkedRule.ask);
      final json = SchemeCodec.freshCopy(original);
      expect(json.unmarked, UnmarkedRule.ask);
      expect(json.questions.first.weight, 2);
      expect(json.questions.last.weight, 1);
    });
  });
}
