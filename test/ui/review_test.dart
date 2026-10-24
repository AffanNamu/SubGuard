import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/core/widgets/score_keypad.dart';
import 'package:unimarkly/core/widgets/ui_kit.dart';
import 'package:unimarkly/data/repositories/booklet_repository.dart';
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

  Future<void> typeMark(WidgetTester tester, int q, List<String> keys) async {
    await h.tapText(tester, 'Q-$q');
    for (final k in keys) {
      await tester.tap(find.descendant(of: find.byType(ScoreKeypad), matching: find.text(k)));
      await tester.pump();
    }
    await tester.tap(find.text('Save'));
    await h.settle(tester);
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
    expect(find.text('Enter at least one mark from the photo.'), findsOneWidget);
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

    await h.tapText(tester, "Add the examiner's written total (optional)");
    for (final k in ['2', '5']) {
      await tester.tap(find.descendant(of: find.byType(ScoreKeypad), matching: find.text(k)));
      await tester.pump();
    }
    await tester.tap(find.text('Save'));
    await h.settle(tester);

    expect(find.textContaining('The examiner wrote 25, but the marks add up to 20'), findsOneWidget);
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

  testWidgets('an exam number the reader found is already in the field, marked as read automatically', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () async {
      await seed();
      final scan = (await h.scans.batches()).first;
      final item = (await h.scans.scansOf(scan.id)).single;
      await BookletRepository(h.db, h.scores).saveReading(
        scanId: item.id,
        courseId: course.id,
        document: const OcrDocument(engine: 'test', lines: []),
        reading: const BookletReading(
          examNumberSuggestion: 'FWM/24U/0538',
          examNumberConfidence: 0.82,
          examNumberOnClassList: true,
          examNumberRegion: Region(0.3, 0.1, 0.95, 0.2),
        ),
      );
    });
    await openFirstReview(tester);

    final field = tester.widget<TextField>(find.widgetWithText(TextField, 'Registration number'));
    expect(field.controller!.text, 'FWM/24U/0538');
    expect(find.textContaining('Read automatically (82% sure) and found on the class list'), findsOneWidget);
    expect(find.textContaining('FWM/24U/0538 is on the class list'), findsOneWidget);

    // Only the marks are left to enter.
    expect(find.text('Enter at least one mark from the photo.'), findsOneWidget);
    await typeMark(tester, 1, ['3', '0']);
    expect(confirmEnabled(tester), isTrue);

    // Changing it takes the "automatic" label away: it is now the examiner's.
    await typeExamNumber(tester, 'FWM/24U/0539');
    expect(find.textContaining('Read automatically'), findsNothing);
    await h.stop(tester);
  });
}
