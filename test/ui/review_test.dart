import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/core/widgets/score_keypad.dart';
import 'package:unimarkly/core/widgets/ui_kit.dart';
import 'package:unimarkly/data/repositories/booklet_repository.dart';
import 'package:unimarkly/data/repositories/recognition_repository.dart';
import 'package:unimarkly/domain/recognition.dart';
import 'package:unimarkly/features/home/batch_card.dart';
import 'package:unimarkly/features/scan/recognition_widgets.dart';
import 'package:unimarkly/features/scan/scan_widgets.dart';
import 'package:unimarkly/services/recognition/interfaces.dart';
import 'package:unimarkly/services/recognition/orientation.dart';
import 'package:unimarkly/services/recognition/validation.dart';
import 'package:unimarkly/services/vision/quality.dart';
import 'package:unimarkly/domain/models.dart';
import 'package:unimarkly/domain/ocr.dart';
import 'package:unimarkly/services/reader/booklet_extractor.dart';
import 'package:unimarkly/domain/scan.dart';

import 'harness.dart';

/// The review screen: the examiner types what the photo shows, the screen
/// checks it, and only Confirm puts a mark in the score grid.
void main() {
  final h = AppHarness();
  const tall = Size(390, 2400);

  late Course course;

  Future<void> seed({int photos = 1, List<ScanStatus>? states}) async {
    course = await h.createCourse(code: 'AGR 114', regNos: ['FWM/24U/0538', 'FWM/24U/0539']);
    await h.seedBatch(course, states: states ?? List.filled(photos, ScanStatus.needsReview));
  }

  Future<void> openFirstReview(WidgetTester tester) async {
    await h.tapText(tester, 'Home');
    await h.tapText(tester, 'Review Results');
    await tester.tap(find.byType(GlowCard).first); // the first booklet waiting
    await h.settle(tester);
  }

  /// Records the examiner added by hand in this test, by question number.
  final added = <int, String>{};
  setUp(added.clear);

  Future<void> pad(WidgetTester tester, List<String> keys) async {
    for (final k in keys) {
      await tester.tap(find.descendant(of: find.byType(ScoreKeypad), matching: find.text(k)));
      await tester.pump();
    }
    await tester.tap(find.text('Save'));
    await h.settle(tester);
  }

  /// Adds question [q] (once) and gives it [keys] as its mark: the examiner typing from the photo.
  Future<void> typeMark(WidgetTester tester, int q, List<String> keys) async {
    if (!added.containsKey(q)) {
      await h.reveal(tester, find.text('Add a question'));
      await tester.tap(find.text('Add a question'));
      await h.settle(tester);
      await pad(tester, [for (final d in '$q'.split('')) d]);
      added[q] = 'manual-${added.length + 1}';
    }
    final field = find.byKey(ValueKey('m-${added[q]}'));
    await h.reveal(tester, field);
    await tester.tap(field);
    await h.settle(tester);
    await pad(tester, keys);
  }

  /// Sets a record's mark, or question number, by typing on the pad.
  Future<void> typeInto(WidgetTester tester, String fieldKey, List<String> keys) async {
    final field = find.byKey(ValueKey(fieldKey));
    await h.reveal(tester, field);
    await tester.tap(field);
    await h.settle(tester);
    await pad(tester, keys);
  }

  /// The calculated total as shown, scrolled into view first.
  Future<String?> total(WidgetTester tester) async {
    await h.reveal(tester, find.byKey(const ValueKey('calculated-total')));
    return tester.widget<Text>(find.byKey(const ValueKey('calculated-total'))).data;
  }

  Future<void> typeExamNumber(WidgetTester tester, String value) async {
    await tester.enterText(find.widgetWithText(TextField, 'Registration number'), value);
    await h.settle(tester);
  }

  Finder confirmButton() => find.text('Confirm & next');

  bool confirmEnabled(WidgetTester tester) {
    final button = tester.widget<InkWell>(find.ancestor(of: confirmButton(), matching: find.byType(InkWell)).first);
    return button.onTap != null;
  }

  testWidgets('nothing can be confirmed until the exam number and a mark are entered', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: seed);
    await openFirstReview(tester);

    expect(find.text('Enter the exam number from the photo.'), findsOneWidget);
    expect(confirmEnabled(tester), isFalse);

    await typeExamNumber(tester, 'FWM/24U/0538');
    expect(find.textContaining('is on the class list'), findsOneWidget);
    expect(find.text('Confirm at least one question and its mark from the photo.'), findsOneWidget);
    expect(confirmEnabled(tester), isFalse);

    await typeMark(tester, 1, ['1', '2', '.5']);
    expect(find.text('12.5'), findsWidgets);
    expect(confirmEnabled(tester), isTrue);
    await h.stop(tester);
  });

  testWidgets('Confirm writes the exam score to the grid and marks the photo confirmed', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: seed);
    await openFirstReview(tester);

    await typeExamNumber(tester, 'fwm/24u/0538');
    await typeMark(tester, 1, ['1', '2']);
    await typeMark(tester, 2, ['9', '.5']);
    expect(find.text('21.5'), findsWidgets); // 12 + 9.5, the running total

    await tester.tap(confirmButton());
    await h.settle(tester);

    // Back on the queue: nothing left to review, and the grid has the mark.
    expect(find.text('Nothing to review'), findsOneWidget);
    final cell = await tester.runAsync(() async {
      final students = await h.students.getAll(course.id);
      final student = students.firstWhere((s) => s.regNo == 'FWM/24U/0538');
      return h.scores.cell(student.id, course.scheme.examPart!.id);
    });
    expect(cell?.value, 21.5);
    expect(cell?.source, isNot('typed'));

    final scans = await tester.runAsync(() async => h.scans.batches());
    expect(scans!.single.counts.confirmed, 1);
    expect(scans.single.counts.needsReview, 0);
    await h.stop(tester);
  });

  testWidgets('an exam number not on the class list can be corrected or added as an extra', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: seed);
    await openFirstReview(tester);

    await typeExamNumber(tester, 'FWM/24U/0540');
    expect(find.textContaining('is not on the class list'), findsOneWidget);
    expect(find.text('Add as an extra student'), findsOneWidget);
    expect(find.text('Did you mean'), findsOneWidget);
    expect(confirmEnabled(tester), isFalse);

    // Picking a suggestion fills the real class-list number.
    await tester.tap(find.widgetWithText(ActionChip, 'FWM/24U/0539'));
    await h.settle(tester);
    expect(find.textContaining('FWM/24U/0539 is on the class list'), findsOneWidget);

    // Or: keep the typed number and add it as an extra student.
    await typeExamNumber(tester, 'FWM/24U/0540');
    await tester.tap(find.byType(Switch));
    await h.settle(tester);
    await typeMark(tester, 1, ['4', '0']);
    expect(confirmEnabled(tester), isTrue);

    await tester.tap(confirmButton());
    await h.settle(tester);
    final students = await tester.runAsync(() => h.students.getAll(course.id));
    final added = students!.firstWhere((s) => s.regNo == 'FWM/24U/0540');
    expect(added.onClassList, isFalse);
    await h.stop(tester);
  });

  testWidgets('a mark above the question maximum, or an exam total above the part maximum, is flagged', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: seed);
    await openFirstReview(tester);
    await typeExamNumber(tester, 'FWM/24U/0538');

    // 70 is the exam maximum; 40 + 40 is above it.
    await typeMark(tester, 1, ['4', '0']);
    await typeMark(tester, 2, ['4', '0']);
    expect(find.textContaining('above the Exam maximum of 70'), findsOneWidget);
    await h.stop(tester);
  });

  testWidgets('a written total that disagrees with the marks is shown, not hidden', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: seed);
    await openFirstReview(tester);
    await typeExamNumber(tester, 'FWM/24U/0538');
    await typeMark(tester, 1, ['2', '0']);

    await h.reveal(tester, find.byKey(const ValueKey('written-total')));
    await tester.tap(find.byKey(const ValueKey('written-total')));
    await h.settle(tester);
    for (final k in ['2', '5']) {
      await tester.tap(find.descendant(of: find.byType(ScoreKeypad), matching: find.text(k)));
      await tester.pump();
    }
    await tester.tap(find.text('Save'));
    await h.settle(tester);

    expect(find.textContaining('The examiner wrote 25, but the confirmed marks add up to 20'), findsOneWidget);
    // It is a warning: the examiner can still confirm.
    expect(confirmEnabled(tester), isTrue);
    await h.stop(tester);
  });

  testWidgets('confirming a second booklet for the same student needs an explicit OK', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () => seed(photos: 2));
    await openFirstReview(tester);
    await typeExamNumber(tester, 'FWM/24U/0538');
    await typeMark(tester, 1, ['3', '0']);
    await tester.tap(confirmButton());
    await h.settle(tester);

    // Now on the second photo, same student.
    added.clear();
    expect(find.text('Review 2 of 2'), findsOneWidget);
    await typeExamNumber(tester, 'FWM/24U/0538');
    await typeMark(tester, 1, ['3', '1']);
    expect(find.textContaining('already has a confirmed booklet'), findsOneWidget);
    expect(find.text('Tick the box to confirm this booklet again.'), findsOneWidget);
    expect(confirmEnabled(tester), isFalse);

    await tester.tap(find.byType(CheckboxListTile));
    await h.settle(tester);
    expect(confirmEnabled(tester), isTrue);
    await h.stop(tester);
  });

  testWidgets('Skip for now leaves the booklet waiting and nothing is written', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () => seed(photos: 2));
    await openFirstReview(tester);
    await typeExamNumber(tester, 'FWM/24U/0538');
    await typeMark(tester, 1, ['3', '0']);

    await tester.tap(find.text('Skip for now'));
    await h.settle(tester);
    expect(find.text('Review 2 of 2'), findsOneWidget);

    final cell = await tester.runAsync(() async {
      final s = (await h.students.getAll(course.id)).firstWhere((s) => s.regNo == 'FWM/24U/0538');
      return h.scores.cell(s.id, course.scheme.examPart!.id);
    });
    expect(cell?.value, isNull);
    final batches = await tester.runAsync(() => h.scans.batches());
    expect(batches!.single.counts.needsReview, 2);
    await h.stop(tester);
  });

  /// A stored run of the pipeline for the first photo of the seeded batch.
  Future<String> seedRun(
    List<ExtractedField> fields, {
    QualityReport? quality,
    List<ValidationFinding> findings = const [],
    int turnedQuarters = 0,
  }) async {
    final scan = (await h.scans.batches()).first;
    final item = (await h.scans.scansOf(scan.id)).single;
    const layout = BookletReading(
      examNumberRegion: Region(0.3, 0.1, 0.95, 0.2),
      marksRegion: Region(0.78, 0.33, 0.98, 0.6),
      questionColumnRegion: Region(0.64, 0.33, 0.78, 0.6),
      totalRegion: Region(0.78, 0.82, 0.96, 0.87),
    );
    await BookletRepository(h.db, h.scores).saveReading(
      scanId: item.id,
      courseId: course.id,
      document: const OcrDocument(engine: 'test', lines: []),
      reading: layout,
    );
    return RecognitionRepository(h.db).saveRun(
      item.id,
      RecognitionResult(
        fields: fields,
        quality: quality,
        findings: findings,
        layout: layout,
        models: const [],
        timingsMs: const {'decode': 1},
        printed: const OcrDocument(engine: 'test', lines: []),
        turnedQuarters: turnedQuarters,
      ),
    );
  }

  const examField = ExtractedField(
    key: 'exam_number',
    kind: FieldKind.registrationNumber,
    state: FieldState.needsReview,
    candidates: [
      FieldCandidate('FWM/24U/0538', 0.48, source: 'class_list(test/closeup)', note: 'The only class-list number within 1 character of what was read ("FWM/24U/0548").'),
      FieldCandidate('FWM/24U/0548', 0.40, source: 'test/closeup'),
    ],
    value: 'FWM/24U/0548',
    region: Region(0.3, 0.1, 0.95, 0.2),
    attempts: [ReadAttempt(reader: 'test', readerVersion: '1', variant: 'closeup', text: 'FWM/24U/0548', confidence: 0.4)],
  );

  ExtractedField markRow(int i, {String? value, String? question, List<FieldCandidate>? candidates, FieldState state = FieldState.needsReview}) =>
      ExtractedField(
        key: 'mark_row_$i',
        kind: FieldKind.mark,
        state: state,
        value: value,
        question: question,
        candidates: candidates ?? [if (value != null && !value.contains('?')) FieldCandidate(value, 0.5, source: 'unimarkly-digits/red_ink')],
        region: Region(0.78, 0.33 + i * 0.05, 0.98, 0.37 + i * 0.05),
      );

  testWidgets('a number the machine suggests is offered as a tap and never entered: the field stays empty until the examiner taps it', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () async {
      await seed();
      await seedRun([examField]);
    });
    await openFirstReview(tester);

    final field = tester.widget<TextField>(find.widgetWithText(TextField, 'Registration number'));
    expect(field.controller!.text, isEmpty, reason: 'a machine reading is never entered for the examiner');
    expect(find.text('Check this'), findsWidgets);
    expect(find.text('Enter the exam number from the photo.'), findsOneWidget);
    expect(confirmEnabled(tester), isFalse);

    // Each suggestion says where it came from.
    expect(find.widgetWithText(ActionChip, 'FWM/24U/0538'), findsOneWidget);
    expect(find.textContaining('from the class list'), findsOneWidget);
    expect(find.textContaining('read from the photo'), findsOneWidget);

    await tester.tap(find.widgetWithText(ActionChip, 'FWM/24U/0538'));
    await h.settle(tester);
    expect(tester.widget<TextField>(find.widgetWithText(TextField, 'Registration number')).controller!.text, 'FWM/24U/0538');
    expect(find.textContaining('not yet checked by you'), findsOneWidget);

    // Typing anything clears the "unchecked suggestion" note: it is the examiner's now.
    await typeExamNumber(tester, 'FWM/24U/0539');
    expect(find.textContaining('not yet checked by you'), findsNothing);
    await h.stop(tester);
  });

  testWidgets('what was read is explained on request: reader, picture variant, text and confidence', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () async {
      await seed();
      await seedRun([examField]);
    });
    await openFirstReview(tester);
    await h.tapText(tester, 'How this was read');
    expect(find.textContaining('test · closeup: "FWM/24U/0548" (40%)'), findsOneWidget);
    await h.stop(tester);
  });

  testWidgets('a booklet read before results were kept still offers its one suggestion, labelled as earlier', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () async {
      await seed();
      final scan = (await h.scans.batches()).first;
      final item = (await h.scans.scansOf(scan.id)).single;
      await BookletRepository(h.db, h.scores).saveReading(
        scanId: item.id,
        courseId: course.id,
        document: const OcrDocument(engine: 'test', lines: []),
        reading: const BookletReading(examNumberSuggestion: 'FWM/24U/0538', examNumberConfidence: 0.82, examNumberOnClassList: true),
      );
    });
    await openFirstReview(tester);
    expect(tester.widget<TextField>(find.widgetWithText(TextField, 'Registration number')).controller!.text, isEmpty);
    expect(find.widgetWithText(ActionChip, 'FWM/24U/0538'), findsOneWidget);
    expect(find.textContaining('from an earlier reading'), findsOneWidget);
    await h.stop(tester);
  });

  testWidgets('each row is one record with a question number and a mark: suggestions are kept apart and become values only when tapped', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () async {
      await seed();
      await seedRun([
        markRow(1, value: '4.5', question: '3'),
        markRow(2, value: '2.0', question: null),
        markRow(3, value: '1?0', question: '2', candidates: const []),
        markRow(4, state: FieldState.unreadable),
      ]);
    });
    await openFirstReview(tester);
    await h.reveal(tester, find.byKey(const ValueKey('record-mark_row_1')));

    // Four rows found, four records. Nothing is confirmed, so there is no total yet.
    expect(find.byKey(const ValueKey('record-mark_row_1')), findsOneWidget);
    for (final i in [1, 2, 3, 4]) {
      await h.reveal(tester, find.byKey(ValueKey('record-mark_row_$i')));
      expect(find.byKey(ValueKey('record-mark_row_$i')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('record-mark_row_5')), findsNothing, reason: 'no fifth record, and no Q1 to Q100 list');
    expect(find.text('Needs checking'), findsWidgets);

    // Row 1: the machine suggests Q3 and 4.5 as two separate suggestions. Neither is a value yet.
    await h.reveal(tester, find.byKey(const ValueKey('record-mark_row_1')));
    expect(find.byKey(const ValueKey('sq-mark_row_1-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('sm-mark_row_1-4.5')), findsOneWidget);
    expect(find.textContaining('Suggested question number (not confirmed)'), findsWidgets);
    await h.reveal(tester, find.text('Calculated total'));
    expect(find.text('Calculated total'), findsOneWidget);
    expect(await total(tester), '—');

    // Tapping the question suggestion confirms the question only; the mark is still a suggestion.
    await h.reveal(tester, find.byKey(const ValueKey('sq-mark_row_1-3')));
    await tester.tap(find.byKey(const ValueKey('sq-mark_row_1-3')));
    await h.settle(tester);
    expect(find.byKey(const ValueKey('sq-mark_row_1-3')), findsNothing);
    expect(find.byKey(const ValueKey('sm-mark_row_1-4.5')), findsOneWidget);
    expect(await total(tester), '—');

    // Tapping the mark suggestion confirms the mark: now the record is complete and the total follows.
    await h.reveal(tester, find.byKey(const ValueKey('sm-mark_row_1-4.5')));
    await tester.tap(find.byKey(const ValueKey('sm-mark_row_1-4.5')));
    await h.settle(tester);
    expect(await total(tester), '4.5');

    // Row 2: the mark is suggested, the question number is not readable: it says so and asks.
    await h.reveal(tester, find.byKey(const ValueKey('record-mark_row_2')));
    expect(find.byKey(const ValueKey('sm-mark_row_2-2.0')), findsOneWidget);
    expect(find.text('Unable to read this question number confidently. Please check the photograph and enter it.'), findsWidgets);
    await h.reveal(tester, find.byKey(const ValueKey('sm-mark_row_2-2.0')));
    await tester.tap(find.byKey(const ValueKey('sm-mark_row_2-2.0')));
    await h.settle(tester);
    // The mark is not counted under a guessed question number: the total has not moved.
    expect(await total(tester), '4.5');
    expect(find.byKey(const ValueKey('unresolved')), findsOneWidget);

    // Row 3: a partial reading with no candidates: nothing is suggested, and the screen says so.
    await h.reveal(tester, find.byKey(const ValueKey('record-mark_row_3')));
    expect(find.text('Unable to read this mark confidently. Please check the photograph and enter the correct mark.'), findsWidgets);
    expect(find.byKey(const ValueKey('sm-mark_row_3-1?0')), findsNothing);
    await h.stop(tester);
  });

  testWidgets('"Use these suggestions" confirms the top suggestion for both fields of a row in one tap, and only when asked', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () async {
      await seed();
      await seedRun([markRow(1, value: '2.5', question: '4')]);
    });
    await openFirstReview(tester);
    await h.reveal(tester, find.byKey(const ValueKey('both-mark_row_1')));
    expect(await total(tester), '—', reason: 'opening the booklet confirms nothing');
    await h.reveal(tester, find.byKey(const ValueKey('both-mark_row_1')));
    await tester.tap(find.byKey(const ValueKey('both-mark_row_1')));
    await h.settle(tester);
    expect(await total(tester), '2.5');
    expect(find.text('Confirmed by you'), findsWidgets);
    await h.stop(tester);
  });

  testWidgets('implausible readings such as 147 are never offered as marks, and the examiner is told what was read and why it is not offered', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () async {
      await seed();
      await seedRun([
        markRow(1, value: '147', question: '1', candidates: const [FieldCandidate('147', 0.13), FieldCandidate('140', 0.11), FieldCandidate('180', 0.11)]),
      ]);
    });
    await openFirstReview(tester);
    await h.reveal(tester, find.byKey(const ValueKey('record-mark_row_1')));
    expect(find.byKey(const ValueKey('sm-mark_row_1-147')), findsNothing);
    expect(find.byKey(const ValueKey('sm-mark_row_1-140')), findsNothing);
    expect(find.text('Unable to read this mark confidently. Please check the photograph and enter the correct mark.'), findsOneWidget);
    // The raw reading is available as evidence, with the reason.
    await tester.tap(find.text('How this was read'));
    await h.settle(tester);
    expect(find.textContaining('Marks cell read as "147"'), findsOneWidget);
    expect(find.textContaining('Not offered as a mark: "147" (147 is above the most this can be (70))'), findsOneWidget);
    await h.stop(tester);
  });

  testWidgets('a row that is not a mark can be dismissed: it leaves the total, and can be put back', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () async {
      await seed();
      await seedRun([markRow(1, value: '2.0', question: '1'), markRow(2, value: '9.0', question: '2')]);
    });
    await openFirstReview(tester);
    await h.reveal(tester, find.byKey(const ValueKey('both-mark_row_1')));
    await h.reveal(tester, find.byKey(const ValueKey('both-mark_row_1')));
    await tester.tap(find.byKey(const ValueKey('both-mark_row_1')));
    await h.settle(tester);
    await h.reveal(tester, find.byKey(const ValueKey('both-mark_row_2')));
    await h.reveal(tester, find.byKey(const ValueKey('both-mark_row_2')));
    await tester.tap(find.byKey(const ValueKey('both-mark_row_2')));
    await h.settle(tester);
    expect(await total(tester), '11');

    await h.reveal(tester, find.byKey(const ValueKey('dismiss-mark_row_2')));

    await tester.tap(find.byKey(const ValueKey('dismiss-mark_row_2')));
    await h.settle(tester);
    expect(find.textContaining('Row 2: not a mark. Left out of the total.'), findsOneWidget);
    expect(await total(tester), '2');
    await tester.tap(find.text('Put back'));
    await h.settle(tester);
    expect(await total(tester), '11');
    await h.stop(tester);
  });

  testWidgets('Show on photo opens the whole photo with that field outlined', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () async {
      await seed();
      await seedRun([markRow(1, value: '4.5', question: '3')]);
    });
    await openFirstReview(tester);
    await h.tapText(tester, 'Show on photo');
    expect(find.byType(PhotoViewerScreen), findsOneWidget);
    expect(find.textContaining('Outlined: row 1'), findsOneWidget);
    await h.stop(tester);
  });

  testWidgets('a booklet photographed sideways is shown upright, with the outline where the field is on the turned picture', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () async {
      await seed();
      // Read turned three quarters clockwise (its top was on the right); the row is
      // on the photo as the camera took it, in the right-hand part of the picture.
      await seedRun([markRow(1, value: '4.5', question: '3')], turnedQuarters: 3);
    });
    await openFirstReview(tester);
    await h.tapText(tester, 'Show on photo');
    final viewer = tester.widget<PhotoViewerScreen>(find.byType(PhotoViewerScreen));
    expect(viewer.turnedQuarters, 3);
    expect(find.byWidgetPredicate((w) => w is RotatedBox && w.quarterTurns == 3), findsOneWidget);
    // The outline is drawn where the field is on the turned picture.
    final row = markRow(1, value: '4.5').region!;
    final on = PageOrientation.turn(row, 3);
    final outline = tester.widget<Positioned>(find.ancestor(of: find.bySemanticsLabel('Highlighted: row 1'), matching: find.byType(Positioned)).first);
    final stack = tester.getSize(find.byType(RotatedBox).evaluate().isEmpty ? find.byType(Stack).first : find.ancestor(of: find.byType(RotatedBox), matching: find.byType(Stack)).first);
    expect(outline.left! / stack.width, closeTo(on.left, 1e-6));
    expect(outline.top! / stack.height, closeTo(on.top, 1e-6));
    await h.stop(tester);
  });

  testWidgets('a photo that was not turned is shown as it is', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () async {
      await seed();
      await seedRun([markRow(1, value: '4.5', question: '3')]);
    });
    await openFirstReview(tester);
    await h.tapText(tester, 'Show on photo');
    expect(tester.widget<PhotoViewerScreen>(find.byType(PhotoViewerScreen)).turnedQuarters, 0);
    expect(find.byType(RotatedBox), findsNothing);
    await h.stop(tester);
  });

  testWidgets('a photo the quality check says to retake says so first, with the instruction', (tester) async {
    const metrics = QualityMetrics(
      originalWidth: 800,
      originalHeight: 600,
      sharpness: 0.1,
      noise: 1,
      p2: 40,
      p98: 220,
      darkClip: 0,
      brightClip: 0,
      shadowRatio: 0,
      glareFraction: 0,
      inkContrast: 30,
      textHeightPx: 6,
      tiltDegrees: 0,
      tiltStrength: 0,
      perspectiveDegrees: 0,
      pageFound: true,
      pageFullyVisible: true,
      pageAreaFraction: 0.8,
    );
    await h.start(tester, size: tall, tab: null, seed: () async {
      await seed();
      await seedRun(const [], quality: const QualityReport(
        metrics: metrics,
        verdict: QualityVerdict.poor,
        issues: [
          QualityIssue(
            code: 'blur',
            severity: QualitySeverity.blocking,
            message: 'The photo is too blurred to read the handwriting.',
            advice: 'Hold the phone steady and retake it.',
            value: 0.1,
            threshold: 0.3,
          ),
        ],
      ));
    });
    await openFirstReview(tester);
    expect(find.textContaining('too blurred to read the handwriting. Hold the phone steady and retake it.'), findsOneWidget);
    await h.stop(tester);
  });

  testWidgets('confirming records the examiner\'s decision on every field, with when, against what the machine read', (tester) async {
    late String runId;
    await h.start(tester, size: tall, tab: null, seed: () async {
      await seed();
      runId = await seedRun([
        examField,
        markRow(1, value: '1.0', question: '1'), // used as read
        markRow(2, value: '2.0', question: '2'), // used, then typed over
        markRow(3, value: '9.0', question: '3'), // dismissed
      ]);
    });
    await openFirstReview(tester);

    await tester.tap(find.widgetWithText(ActionChip, 'FWM/24U/0538')); // exam number, as suggested
    await h.settle(tester);
    await h.reveal(tester, find.byKey(const ValueKey('both-mark_row_1')));
    await h.reveal(tester, find.byKey(const ValueKey('both-mark_row_1')));
    await tester.tap(find.byKey(const ValueKey('both-mark_row_1'))); // row 1: Q1 = 1.0, as read
    await h.settle(tester);
    await h.reveal(tester, find.byKey(const ValueKey('both-mark_row_2')));
    await h.reveal(tester, find.byKey(const ValueKey('both-mark_row_2')));
    await tester.tap(find.byKey(const ValueKey('both-mark_row_2'))); // row 2: Q2, with the machine's 2.0 ...
    await h.settle(tester);
    await typeInto(tester, 'm-mark_row_2', ['5']); // ... which the examiner then types over with 5
    await typeMark(tester, 4, ['3']); // an added question: no machine reading at all
    await h.reveal(tester, find.byKey(const ValueKey('dismiss-mark_row_3')));
    await h.reveal(tester, find.byKey(const ValueKey('dismiss-mark_row_3')));
    await tester.tap(find.byKey(const ValueKey('dismiss-mark_row_3'))); // row 3's reading (9.0) is dismissed
    await h.settle(tester);
    await h.reveal(tester, confirmButton());
    await tester.tap(confirmButton());
    await h.settle(tester);

    final data = await tester.runAsync(() async {
      final rows = await h.db.select(h.db.fieldReviews).get();
      final examples = await RecognitionRepository(h.db).labelledExamples();
      return (rows, examples);
    });
    final rows = {for (final r in data!.$1) r.fieldKey: r};
    expect(rows['exam_number']!.decision, 'suggestion', reason: 'the examiner tapped a class-list suggestion, not the machine\'s own reading');
    expect(rows['exam_number']!.machineValue, 'FWM/24U/0548', reason: 'measured against the machine\'s own reading');
    expect(rows['exam_number']!.finalValue, 'FWM/24U/0538');
    expect(rows['mark_q1']!.decision, 'accepted');
    expect(rows['mark_q1']!.machineValue, '1.0');
    expect(rows['mark_q2']!.decision, 'edited');
    expect(rows['mark_q2']!.machineValue, '2.0');
    expect(rows['mark_q2']!.finalValue, '5');
    expect(rows['mark_q4']!.decision, 'entered');
    expect(rows['mark_q4']!.machineValue, isNull);
    expect(rows['question_q1']!.decision, 'suggestion', reason: 'the question number was tapped from the machine\'s suggestions');
    expect(rows['question_q1']!.finalValue, '1');
    expect(rows['mark_row_3']!.decision, 'rejected');
    expect(rows['mark_row_3']!.finalValue, isNull);
    for (final r in rows.values) {
      expect(r.runId, runId, reason: '${r.fieldKey} is tied to the run it was measured against');
      expect(r.reviewedAt.isUtc || r.reviewedAt.year >= 2026, isTrue);
    }

    // Each confirmed piece of writing with a place on the photo is a labelled example.
    final labelled = {for (final e in data.$2) e.fieldKey: e};
    expect(labelled['mark_q1']!.text, '1');
    expect(labelled['mark_q2']!.text, '5');
    expect(labelled.keys, isNot(contains('mark_row_3')), reason: 'a dismissed reading is not a label');
    await h.stop(tester);
  });

  testWidgets('Can\'t use this photo takes it out of the queue and marks it unusable, adding nothing to the grid', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: seed);
    await openFirstReview(tester);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await h.settle(tester);
    await h.tapText(tester, "Can't use this photo");
    expect(find.text('Reject this photo?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Reject photo'));
    await h.settle(tester);

    expect(find.text('Nothing to review'), findsOneWidget);
    final batches = await tester.runAsync(() => h.scans.batches());
    expect(batches!.single.counts.failed, 1);
    expect(batches.single.counts.confirmed, 0);
    await h.stop(tester);
  });

  testWidgets('the review queue says why each booklet is waiting', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () async {
      await seed();
      await seedRun(const [ExtractedField(key: 'exam_number', kind: FieldKind.registrationNumber, state: FieldState.unreadable)]);
    });
    await h.tapText(tester, 'Home');
    await h.tapText(tester, 'Review Results');
    expect(find.textContaining('Exam number not read'), findsOneWidget);
    expect(find.textContaining('no marks found'), findsOneWidget);
    await h.stop(tester);
  });

  testWidgets('a confirmed booklet shows what the machine read beside what the examiner confirmed', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () async {
      await seed();
      final runId = await seedRun([examField, markRow(1, value: '4.0', question: '1')]);
      final scan = (await h.scans.batches()).first;
      final item = (await h.scans.scansOf(scan.id)).single;
      final student = (await h.students.getAll(course.id)).firstWhere((s) => s.regNo == 'FWM/24U/0538');
      await BookletRepository(h.db, h.scores).confirm(
        scanId: item.id,
        courseId: course.id,
        studentId: student.id,
        serialNo: null,
        marks: const {1: 14.0},
        editedMarks: const {1},
        examScore: 14,
        examPartId: course.scheme.examPart!.id,
        photoPath: item.relativePath,
        runId: runId,
        reviews: const [
          FieldReviewDraft(fieldKey: 'exam_number', kind: 'registration_number', machineValue: 'FWM/24U/0548', finalValue: 'FWM/24U/0538', decision: 'edited'),
        ],
      );
    });
    await h.tapText(tester, 'Home');
    await h.reveal(tester, find.byType(BatchCard));
    await tester.tap(find.byType(BatchCard).first);
    await h.settle(tester);
    await tester.tap(find.byType(ScanThumb).first);
    await h.settle(tester);

    expect(find.text('Confirmed by you'), findsWidgets);
    expect(find.textContaining('The machine read "FWM/24U/0548"; you confirmed "FWM/24U/0538"'), findsOneWidget);
    await h.stop(tester);
  });
}
