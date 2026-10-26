import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/core/widgets/score_keypad.dart';
import 'package:unimarkly/core/widgets/ui_kit.dart';
import 'package:unimarkly/data/repositories/booklet_repository.dart';
import 'package:unimarkly/data/repositories/recognition_repository.dart';
import 'package:unimarkly/domain/defaults.dart';
import 'package:unimarkly/domain/ids.dart';
import 'package:unimarkly/domain/models.dart';
import 'package:unimarkly/domain/ocr.dart';
import 'package:unimarkly/domain/recognition.dart';
import 'package:unimarkly/domain/scan.dart';
import 'package:unimarkly/domain/scheme.dart';
import 'package:unimarkly/features/home/batch_card.dart';
import 'package:unimarkly/features/scan/scan_widgets.dart';
import 'package:unimarkly/services/reader/booklet_extractor.dart';
import 'package:unimarkly/services/recognition/interfaces.dart';

import 'harness.dart';

/// The marks of a booklet as records in the review screen: which questions appear (only
/// those found or added), how the total follows the confirmed marks, and what is stored.
/// The recognition output seeded here stands in for a photograph's reading; the recognition
/// itself is tested on the real photograph in test/recognition/question_marks_real_test.dart.
void main() {
  final h = AppHarness();
  const tall = Size(390, 3600);

  late Course course;
  late String scanId;

  GradingScheme scheme({List<QuestionSpec> questions = const [], CountRule rule = CountRule.all, int? countN, UnmarkedRule unmarked = UnmarkedRule.zero}) =>
      Defaults.nigerianScheme().copyWith(questions: questions, countRule: rule, countN: countN, unmarked: unmarked);

  QuestionSpec q(int n, {double max = 10, double weight = 1}) => QuestionSpec(id: newId(), qNo: n, max: max, weight: weight);

  /// A pair of rows' fields as the pipeline produces them: the mark cell and the question cell, apart.
  List<ExtractedField> row(int index, {String? question, List<String> marks = const [], String? rawMark}) => [
        ExtractedField(
          key: 'mark_row_$index',
          kind: FieldKind.mark,
          state: FieldState.needsReview,
          value: rawMark ?? (marks.isEmpty ? null : marks.first),
          candidates: [for (final (k, m) in marks.indexed) FieldCandidate(m, 0.9 - k * 0.1, source: 'unimarkly-digits/red_ink')],
          attempts: [ReadAttempt(reader: 'unimarkly-digits', readerVersion: '1', variant: 'red_ink', text: rawMark ?? (marks.isEmpty ? null : marks.first))],
          region: Region(0.78, 0.30 + index * 0.04, 0.98, 0.33 + index * 0.04),
        ),
        ExtractedField(
          key: 'question_row_$index',
          kind: FieldKind.questionNumber,
          state: FieldState.needsReview,
          value: question,
          candidates: [if (question != null) FieldCandidate(question, 0.95, source: 'digit_net/label')],
          attempts: [ReadAttempt(reader: 'unimarkly-digits', readerVersion: '1', variant: 'red_ink', text: question)],
          region: Region(0.64, 0.30 + index * 0.04, 0.78, 0.33 + index * 0.04),
        ),
      ];

  Future<void> seed({GradingScheme? sch, List<ExtractedField> fields = const [], ScanStatus status = ScanStatus.needsReview}) async {
    course = await h.createCourse(code: 'AGR 114', regNos: ['FWM/24U/0538', 'FWM/24U/0539'], scheme: sch);
    await h.seedBatch(course, states: [status]);
    final batch = (await h.scans.batches()).first;
    final item = (await h.scans.scansOf(batch.id)).single;
    scanId = item.id;
    if (fields.isNotEmpty) {
      const layout = BookletReading(marksRegion: Region(0.78, 0.33, 0.98, 0.6), totalRegion: Region(0.78, 0.82, 0.96, 0.87));
      await BookletRepository(h.db, h.scores).saveReading(scanId: item.id, courseId: course.id, document: const OcrDocument(engine: 'test', lines: []), reading: layout);
      await RecognitionRepository(h.db).saveRun(
        item.id,
        RecognitionResult(
          fields: [
            ...fields,
            const ExtractedField(key: 'total_written', kind: FieldKind.mark, state: FieldState.recognized, warnings: ['The Total box appears to be blank.']),
          ],
          quality: null,
          findings: const [],
          layout: layout,
          models: const [],
          timingsMs: const {'decode': 1},
          printed: const OcrDocument(engine: 'test', lines: []),
        ),
      );
    }
  }

  Future<void> openReview(WidgetTester tester) async {
    await h.tapText(tester, 'Home');
    await h.tapText(tester, 'Review Results');
    await tester.tap(find.byType(GlowCard).first);
    await h.settle(tester);
  }

  Future<void> pad(WidgetTester tester, List<String> keys) async {
    for (final k in keys) {
      await tester.tap(find.descendant(of: find.byType(ScoreKeypad), matching: find.text(k)));
      await tester.pump();
    }
    await tester.tap(find.text('Save'));
    await h.settle(tester);
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final f = find.byKey(ValueKey(key));
    await h.reveal(tester, f);
    await tester.tap(f);
    await h.settle(tester);
  }

  Future<String?> total(WidgetTester tester) async {
    await h.reveal(tester, find.byKey(const ValueKey('calculated-total')));
    return tester.widget<Text>(find.byKey(const ValueKey('calculated-total'))).data;
  }

  Future<void> addQuestion(WidgetTester tester, int number) async {
    await h.reveal(tester, find.text('Add a question'));
    await tester.tap(find.text('Add a question'));
    await h.settle(tester);
    await pad(tester, [for (final d in '$number'.split('')) d]);
  }

  Future<void> typeExam(WidgetTester tester) async {
    final f = find.widgetWithText(TextField, 'Registration number');
    await h.reveal(tester, f);
    await tester.enterText(f, 'FWM/24U/0538');
    await h.settle(tester);
  }

  testWidgets('four questions numbered 1, 2, 4 and 5 are four records: no Q3 is made up, and the total is their sum', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () => seed(fields: [
          ...row(1, question: '1', marks: ['1.0']),
          ...row(2, question: '2', marks: ['1.0']),
          ...row(3, question: '4', marks: ['2.0']),
          ...row(4, question: '5', marks: ['5.5']),
        ]));
    await openReview(tester);
    for (final i in [1, 2, 3, 4]) {
      await tapKey(tester, 'both-mark_row_$i');
    }
    expect(await total(tester), '9.5');
    expect(find.text('Q3'), findsNothing);
    expect(find.byKey(const ValueKey('record-mark_row_5')), findsNothing);
    // Q3 is not on the course's list either (there is no list): nothing says it is missing.
    expect(find.byKey(const ValueKey('unmarked-3')), findsNothing);
    await h.stop(tester);
  });

  testWidgets('an examination with twelve questions shows twelve records, not a fixed list, and adds them up', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () => seed(fields: [for (var i = 1; i <= 12; i++) ...row(i, question: '$i', marks: ['${i % 3 + 1}.0'])]));
    await openReview(tester);
    for (var i = 1; i <= 12; i++) {
      await tapKey(tester, 'both-mark_row_$i');
    }
    // marks: i % 3 + 1 for i = 1..12 -> 2,3,1,2,3,1,2,3,1,2,3,1 = 24
    expect(await total(tester), '24');
    expect(find.byKey(const ValueKey('record-mark_row_12')), findsOneWidget);
    expect(find.byKey(const ValueKey('record-mark_row_13')), findsNothing);
    await typeExam(tester);
    await h.reveal(tester, find.text('Confirm & next'));
    await tester.tap(find.text('Confirm & next'));
    await h.settle(tester);
    final stored = await tester.runAsync(() => h.db.select(h.db.questionMarks).get());
    expect(stored, hasLength(12), reason: 'twelve records stored, one per question found');
    await h.stop(tester);
  });

  testWidgets('a course with no question list and nothing found invents no questions: it says so and waits for the examiner', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () => seed());
    await openReview(tester);
    await h.reveal(tester, find.text('Add a question'));
    expect(find.text('No rows were found on the photo. Add each question and its mark from the photo.'), findsOneWidget);
    for (var n = 1; n <= 6; n++) {
      expect(find.text('Q-$n'), findsNothing);
      expect(find.byKey(ValueKey('unmarked-$n')), findsNothing);
    }
    expect(await total(tester), '—');
    await h.stop(tester);
  });

  testWidgets('the question numbers accepted go up to a limit the examiner sets (60 until changed), not to a made-up list', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () => seed());
    await openReview(tester);
    await addQuestion(tester, 61);
    expect(find.textContaining('Question numbers go from 1 to 60'), findsOneWidget);
    expect(find.byKey(const ValueKey('record-manual-1')), findsNothing);
    await addQuestion(tester, 47); // far from 1, and fine
    expect(find.byKey(const ValueKey('record-manual-1')), findsOneWidget);
    expect(find.text('Q47'), findsWidgets);
    await h.stop(tester);
  });

  testWidgets('with the limit raised in Settings, a higher question number is accepted', (tester) async {
    await h.start(tester, size: tall, tab: null, prefsValues: {'max_question_number': 150}, seed: () => seed());
    await openReview(tester);
    await addQuestion(tester, 120);
    expect(find.byKey(const ValueKey('record-manual-1')), findsOneWidget);
    expect(find.text('Q120'), findsWidgets);
    await h.stop(tester);
  });

  testWidgets('a question already on a row cannot be added again', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () => seed(fields: row(1, question: '4', marks: ['2.0'])));
    await openReview(tester);
    await tapKey(tester, 'both-mark_row_1');
    await addQuestion(tester, 4);
    expect(find.textContaining('Q4 is already on a row below'), findsOneWidget);
    await h.stop(tester);
  });

  testWidgets('a question number that could not be read is asked for, and the mark is not counted until it is given', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () => seed(fields: [...row(1, question: null, marks: ['3.0']), ...row(2, question: '2', marks: ['1.0'])]));
    await openReview(tester);
    await tapKey(tester, 'sm-mark_row_1-3.0');
    await tapKey(tester, 'both-mark_row_2');
    await h.reveal(tester, find.byKey(const ValueKey('record-mark_row_1')));
    expect(find.text('Unable to read this question number confidently. Please check the photograph and enter it.'), findsOneWidget);
    expect(await total(tester), '1', reason: 'the 3.0 waits for its question number');
    await typeExam(tester);
    await h.reveal(tester, find.text('Confirm & next'));
    expect(tester.widget<InkWell>(find.ancestor(of: find.text('Confirm & next'), matching: find.byType(InkWell)).first).onTap, isNull);
    await tapKey(tester, 'q-mark_row_1');
    await pad(tester, ['4']);
    expect(await total(tester), '4');
    expect(tester.widget<InkWell>(find.ancestor(of: find.text('Confirm & next'), matching: find.byType(InkWell)).first).onTap, isNotNull);
    await h.stop(tester);
  });

  testWidgets('two candidate readings for one mark: choosing one and then the other replaces it; only one value counts', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () => seed(fields: row(1, question: '1', marks: ['1.0', '9.0'])));
    await openReview(tester);
    await tapKey(tester, 'sq-mark_row_1-1');
    await tapKey(tester, 'sm-mark_row_1-1.0');
    expect(await total(tester), '1');
    // The suggestions are gone once the mark is confirmed; the examiner changes it by typing.
    expect(find.byKey(const ValueKey('sm-mark_row_1-9.0')), findsNothing);
    await tapKey(tester, 'm-mark_row_1');
    await pad(tester, ['9']);
    expect(await total(tester), '9', reason: 'replaced, not added to');
    await h.stop(tester);
  });

  testWidgets('correcting a mark updates the total at once; clearing it takes the row out of the total', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () => seed(fields: [...row(1, question: '1', marks: ['4.0']), ...row(2, question: '2', marks: ['2.5'])]));
    await openReview(tester);
    await tapKey(tester, 'both-mark_row_1');
    await tapKey(tester, 'both-mark_row_2');
    expect(await total(tester), '6.5');
    await tapKey(tester, 'm-mark_row_1');
    await pad(tester, ['5']);
    expect(await total(tester), '7.5');
    await tapKey(tester, 'm-mark_row_2');
    await tester.tap(find.text('Clear'));
    await h.settle(tester);
    expect(await total(tester), '5');
    expect(find.byKey(const ValueKey('unresolved')), findsOneWidget, reason: 'the cleared mark is something still to decide');
    await h.stop(tester);
  });

  testWidgets('a blank written total does not stop the total; a matching one says so; a different one is flagged and neither changes', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () => seed(fields: row(1, question: '1', marks: ['9.5'])));
    await openReview(tester);
    await tapKey(tester, 'both-mark_row_1');
    expect(await total(tester), '9.5');
    expect(find.textContaining('A blank Total box is normal'), findsOneWidget);

    Future<void> writeTotal(List<String> keys) async {
      await tapKey(tester, 'written-total');
      await pad(tester, keys);
    }

    await writeTotal(['9', '.5']);
    expect(find.text('The written total matches the calculated total.'), findsOneWidget);
    await writeTotal(['1', '0', '.5']);
    expect(find.byKey(const ValueKey('total-mismatch')), findsOneWidget);
    expect(find.textContaining('The examiner wrote 10.5, but the confirmed marks add up to 9.5 (1 more). Neither has been changed.'), findsOneWidget);
    expect(await total(tester), '9.5', reason: 'the calculated total is not pulled toward the written one');

    // Confirm with the disagreement: both numbers are stored.
    await typeExam(tester);
    await h.reveal(tester, find.text('Confirm & next'));
    await tester.tap(find.text('Confirm & next'));
    await h.settle(tester);
    final b = await tester.runAsync(() => BookletRepository(h.db, h.scores).forScan(scanId));
    expect(b!.calculatedTotal, 9.5);
    expect(b.writtenTotal, 10.5);
    await h.stop(tester);
  });

  testWidgets('a question on the course list with no mark is listed as not marked and counts as zero; it is never filled in', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () => seed(
          sch: scheme(questions: [for (var i = 1; i <= 5; i++) q(i)]),
          fields: [...row(1, question: '1', marks: ['1.0']), ...row(2, question: '2', marks: ['1.0']), ...row(3, question: '4', marks: ['2.0']), ...row(4, question: '5', marks: ['5.5'])],
        ));
    await openReview(tester);
    for (final i in [1, 2, 3, 4]) {
      await tapKey(tester, 'both-mark_row_$i');
    }
    await h.reveal(tester, find.byKey(const ValueKey('unmarked-3')));
    expect(find.text('On this paper and not marked. They count as zero. Tap one to add its mark:'), findsOneWidget);
    expect(find.byKey(const ValueKey('unmarked-1')), findsNothing);
    expect(await total(tester), '9.5');
    expect(find.textContaining('Q3 on the paper has no mark and counts as zero'), findsOneWidget);
    // Nothing needs the examiner: Confirm waits only for the exam number.
    await typeExam(tester);
    await h.reveal(tester, find.text('Confirm & next'));
    expect(tester.widget<InkWell>(find.ancestor(of: find.text('Confirm & next'), matching: find.byType(InkWell)).first).onTap, isNotNull);
    await h.stop(tester);
  });

  testWidgets('when the course asks about each unmarked question, Confirm waits until Q3 is given a mark (0 is a mark)', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () => seed(
          sch: scheme(questions: [q(1), q(2), q(3)], unmarked: UnmarkedRule.ask),
          fields: [...row(1, question: '1', marks: ['1.0']), ...row(2, question: '2', marks: ['2.0'])],
        ));
    await openReview(tester);
    await tapKey(tester, 'both-mark_row_1');
    await tapKey(tester, 'both-mark_row_2');
    await typeExam(tester);
    await h.reveal(tester, find.text('Q3 has no mark. Add it (enter 0 if no marks were given).'));
    expect(find.text('Q3 has no mark. Add it (enter 0 if no marks were given).'), findsWidgets);
    await tapKey(tester, 'unmarked-3');
    expect(find.byKey(const ValueKey('record-manual-1')), findsOneWidget);
    await tapKey(tester, 'm-manual-1');
    await pad(tester, ['0']);
    expect(await total(tester), '3');
    await h.reveal(tester, find.text('Confirm & next'));
    expect(tester.widget<InkWell>(find.ancestor(of: find.text('Confirm & next'), matching: find.byType(InkWell)).first).onTap, isNotNull);
    await h.stop(tester);
  });

  testWidgets('best 2 of the questions: the lowest mark is left out of the total and said so, and changing it changes what counts', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () => seed(
          sch: scheme(questions: [q(1), q(2), q(3)], rule: CountRule.bestN, countN: 2),
          fields: [...row(1, question: '1', marks: ['5.0']), ...row(2, question: '2', marks: ['9.0']), ...row(3, question: '3', marks: ['7.0'])],
        ));
    await openReview(tester);
    for (final i in [1, 2, 3]) {
      await tapKey(tester, 'both-mark_row_$i');
    }
    expect(await total(tester), '16');
    expect(find.textContaining('Q1 is not counted: best n of the questions'), findsOneWidget);
    await tapKey(tester, 'm-mark_row_1');
    await pad(tester, ['1', '0']);
    expect(await total(tester), '19', reason: 'Q1 is now among the best two and Q3 is left out');
    expect(find.textContaining('Q3 is not counted'), findsOneWidget);
    await h.stop(tester);
  });

  testWidgets('an optional (weighted) question counts as its mark times its weight, and the total says so', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () => seed(
          sch: scheme(questions: [q(1), q(2, weight: 2)]),
          fields: [...row(1, question: '1', marks: ['3.0']), ...row(2, question: '2', marks: ['4.0'])],
        ));
    await openReview(tester);
    await tapKey(tester, 'both-mark_row_1');
    await tapKey(tester, 'both-mark_row_2');
    expect(await total(tester), '11');
    expect(find.textContaining('Q2 counts 2 times its mark'), findsOneWidget);
    await h.stop(tester);
  });

  testWidgets('a confirmed booklet shows its records and totals; editing it again brings the confirmed marks back and the total follows', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () async {
      await seed(
        fields: [...row(1, question: '1', marks: ['1.0']), ...row(2, question: '4', marks: ['2.0'])],
        status: ScanStatus.confirmed,
      );
      final student = (await h.students.getAll(course.id)).firstWhere((s) => s.regNo == 'FWM/24U/0538');
      await BookletRepository(h.db, h.scores).confirm(
        scanId: scanId,
        courseId: course.id,
        studentId: student.id,
        serialNo: null,
        marks: const {1: 1.0, 4: 2.0},
        editedMarks: const {},
        examScore: 3,
        examPartId: course.scheme.examPart!.id,
        photoPath: 'x',
        records: [
          ConfirmedMark(qNo: 1, mark: 1.0, status: 'accepted', recognisedMark: '1.0', recognisedQuestion: '1', region: row(1, marks: ['1.0'])[0].region),
          ConfirmedMark(qNo: 4, mark: 2.0, status: 'accepted', recognisedMark: '2.0', recognisedQuestion: '4', region: row(2, marks: ['2.0'])[0].region),
        ],
        calculatedTotal: 3,
        writtenTotal: 3,
      );
    });
    await h.tapText(tester, 'Home');
    await h.reveal(tester, find.byType(BatchCard));
    await tester.tap(find.byType(BatchCard).first);
    await h.settle(tester);
    await tester.tap(find.byType(ScanThumb).first);
    await h.settle(tester);

    // Locked: the confirmed values, no suggestions to take.
    await h.reveal(tester, find.byKey(const ValueKey('record-mark_row_1')));
    expect(find.text('Q1'), findsWidgets);
    expect(find.text('Q4'), findsWidgets);
    expect(find.textContaining('Suggested'), findsNothing);
    expect(await total(tester), '3');
    expect(find.text('The written total matches the calculated total.'), findsOneWidget);

    // Edit it again: the confirmed marks are there, the total follows a change, and confirming stores it.
    await tester.tap(find.widgetWithText(FilledButton, 'Edit this booklet').evaluate().isNotEmpty
        ? find.widgetWithText(FilledButton, 'Edit this booklet')
        : find.text('Edit this booklet').last);
    await h.settle(tester);
    expect(await total(tester), '3');
    await tapKey(tester, 'm-mark_row_2');
    await pad(tester, ['3', '.5']);
    expect(await total(tester), '4.5');
    expect(find.byKey(const ValueKey('total-mismatch')), findsOneWidget, reason: 'the written total (3) now differs from the calculated one');
    await h.reveal(tester, find.text('Confirm & next'));
    await tester.tap(find.text('Confirm & next'));
    await h.settle(tester);
    final b = await tester.runAsync(() => BookletRepository(h.db, h.scores).forScan(scanId));
    expect(b!.records.map((r) => (r.qNo, r.mark)), [(1, 1.0), (4, 3.5)]);
    expect(b.calculatedTotal, 4.5);
    expect(b.writtenTotal, 3);
    await h.stop(tester);
  });
}
