import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/core/widgets/score_keypad.dart';
import 'package:unimarkly/core/widgets/ui_kit.dart';
import 'package:unimarkly/data/repositories/booklet_repository.dart';
import 'package:unimarkly/data/repositories/recognition_repository.dart';
import 'package:unimarkly/domain/models.dart';
import 'package:unimarkly/domain/ocr.dart';
import 'package:unimarkly/domain/recognition.dart';
import 'package:unimarkly/services/reader/booklet_extractor.dart';
import 'package:unimarkly/services/recognition/interfaces.dart';
import 'package:unimarkly/domain/review_draft.dart';
import 'package:unimarkly/domain/scan.dart';

import 'harness.dart';

/// Entries typed on a booklet and not yet confirmed are kept, so a phone call,
/// a dead battery or a closed app does not cost the examiner their work. They
/// are not results: nothing but Confirm reaches the score grid.
void main() {
  final h = AppHarness();
  const tall = Size(390, 2400);

  late Course course;
  late String firstScanId;

  Future<void> seed({int photos = 1, ReviewDraft? draft}) async {
    course = await h.createCourse(code: 'AGR 114', regNos: ['FWM/24U/0538', 'FWM/24U/0539']);
    await h.seedBatch(course, states: List.filled(photos, ScanStatus.needsReview));
    final batch = (await h.scans.batches()).first;
    firstScanId = (await h.scans.scansOf(batch.id)).first.id;
    if (draft != null) await h.drafts.save(firstScanId, draft);
  }

  Future<void> openFirstReview(WidgetTester tester) async {
    await h.tapText(tester, 'Home');
    await h.tapText(tester, 'Review Results');
    await tester.tap(find.byType(GlowCard).first);
    await h.settle(tester);
  }

  /// Back on the review queue after [leave]: open the same booklet again.
  Future<void> reopen(WidgetTester tester) async {
    await tester.tap(find.byType(GlowCard).first);
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

  String examNumberShown(WidgetTester tester) => tester.widget<TextField>(find.widgetWithText(TextField, 'Registration number')).controller!.text;

  /// Leaves the booklet the way an examiner does, then lets the save finish.
  Future<void> leave(WidgetTester tester) async {
    await tester.pageBack();
    await h.settle(tester);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  }

  bool confirmEnabled(WidgetTester tester) {
    final button = tester.widget<InkWell>(find.ancestor(of: find.text('Confirm & next'), matching: find.byType(InkWell)).first);
    return button.onTap != null;
  }

  testWidgets('what was typed and not confirmed is still there when the booklet is opened again', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: seed);
    await openFirstReview(tester);
    expect(find.textContaining('were restored'), findsNothing);

    await typeExamNumber(tester, 'FWM/24U/0538');
    await typeMark(tester, 1, ['1', '2', '.5']);
    await leave(tester);

    final saved = await tester.runAsync(() => h.drafts.load(firstScanId));
    expect(saved, isNotNull);
    expect(saved!.draft.examNumber, 'FWM/24U/0538');
    expect(saved.draft.marks, {1: 12.5});
    expect(saved.draft.editedMarks, {1});

    await reopen(tester);
    expect(examNumberShown(tester), 'FWM/24U/0538');
    expect(find.text('12.5'), findsWidgets);
    expect(find.textContaining('unconfirmed entries from'), findsOneWidget);
    expect(find.textContaining('were restored'), findsOneWidget);
    expect(confirmEnabled(tester), isTrue);
    await h.stop(tester);
  });

  testWidgets('a draft saved in an earlier session is restored the same way, with its notice', (tester) async {
    await h.start(
      tester,
      size: tall,
      tab: null,
      seed: () => seed(draft: const ReviewDraft(examNumber: 'FWM/24U/0539', marks: {2: 7.0}, editedMarks: {2})),
    );
    await openFirstReview(tester);
    expect(examNumberShown(tester), 'FWM/24U/0539');
    expect(find.text('7'), findsWidgets);
    expect(find.textContaining('were restored'), findsOneWidget);
    await h.stop(tester);
  });

  testWidgets('Discard them clears the entries and the draft', (tester) async {
    await h.start(
      tester,
      size: tall,
      tab: null,
      seed: () => seed(draft: const ReviewDraft(examNumber: 'FWM/24U/0539', marks: {2: 7.0}, editedMarks: {2})),
    );
    await openFirstReview(tester);
    await h.tapText(tester, 'Discard them');

    expect(examNumberShown(tester), '');
    expect(find.textContaining('were restored'), findsNothing);
    expect(confirmEnabled(tester), isFalse);
    expect(await tester.runAsync(() => h.drafts.load(firstScanId)), isNull);

    // Left again with nothing typed, nothing is kept, and the next opening is clean.
    await leave(tester);
    expect(await tester.runAsync(() => h.drafts.load(firstScanId)), isNull);
    await reopen(tester);
    expect(examNumberShown(tester), '');
    expect(find.textContaining('were restored'), findsNothing);
    await h.stop(tester);
  });

  testWidgets('opening and leaving a booklet without typing keeps no draft', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: seed);
    await openFirstReview(tester);
    await leave(tester);
    expect(await tester.runAsync(() => h.drafts.count()), 0);
    await h.stop(tester);
  });

  testWidgets('typing something and then clearing it again keeps no draft', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: seed);
    await openFirstReview(tester);
    await typeExamNumber(tester, 'FWM/24U/0538');
    await typeExamNumber(tester, '');
    await leave(tester);
    expect(await tester.runAsync(() => h.drafts.count()), 0);
    await h.stop(tester);
  });

  testWidgets('a draft is not a result: the grid has no score and the booklet still waits', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: seed);
    await openFirstReview(tester);
    await typeExamNumber(tester, 'FWM/24U/0538');
    await typeMark(tester, 1, ['3', '0']);
    await leave(tester);

    final cell = await tester.runAsync(() async {
      final s = (await h.students.getAll(course.id)).firstWhere((s) => s.regNo == 'FWM/24U/0538');
      return h.scores.cell(s.id, course.scheme.examPart!.id);
    });
    expect(cell?.value, isNull);
    final batches = await tester.runAsync(() => h.scans.batches());
    expect(batches!.single.counts.needsReview, 1);
    expect(batches.single.counts.confirmed, 0);
    await h.stop(tester);
  });

  testWidgets('confirming removes the draft, and the score is the confirmed one', (tester) async {
    await h.start(
      tester,
      size: tall,
      tab: null,
      seed: () => seed(draft: const ReviewDraft(examNumber: 'FWM/24U/0538', marks: {1: 20.0}, editedMarks: {1})),
    );
    await openFirstReview(tester);
    expect(examNumberShown(tester), 'FWM/24U/0538');
    await typeMark(tester, 1, ['1', '5']); // the examiner corrects the restored mark before confirming
    await h.tapText(tester, 'Confirm & next');
    await h.settle(tester);

    expect(await tester.runAsync(() => h.drafts.load(firstScanId)), isNull);
    expect(await tester.runAsync(() => h.drafts.count()), 0);
    final cell = await tester.runAsync(() async {
      final s = (await h.students.getAll(course.id)).firstWhere((s) => s.regNo == 'FWM/24U/0538');
      return h.scores.cell(s.id, course.scheme.examPart!.id);
    });
    expect(cell?.value, 15, reason: 'the confirmed mark, not the restored one');
    await h.stop(tester);
  });

  testWidgets('rejecting the photo removes the draft', (tester) async {
    await h.start(
      tester,
      size: tall,
      tab: null,
      seed: () => seed(draft: const ReviewDraft(examNumber: 'FWM/24U/0538')),
    );
    await openFirstReview(tester);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await h.settle(tester);
    await h.tapText(tester, "Can't use this photo");
    await tester.tap(find.widgetWithText(FilledButton, 'Reject photo'));
    await h.settle(tester);
    expect(await tester.runAsync(() => h.drafts.load(firstScanId)), isNull);
    await h.stop(tester);
  });

  testWidgets('a damaged draft is ignored and the booklet opens clean', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () async {
      await seed();
      await h.db.customStatement("INSERT INTO review_draft (id, updated_at, scan_id, draft_json) "
          "VALUES ('d1', '2026-10-01T10:00:00.000Z', '$firstScanId', '{broken')");
    });
    await openFirstReview(tester);
    expect(examNumberShown(tester), '');
    expect(find.textContaining('were restored'), findsNothing);
    await h.stop(tester);
  });
  /// Reads the seeded booklet "by machine": two rows, so a dismissal is visible.
  Future<String> seedRun() async {
    final item = (await h.scans.scansOf((await h.scans.batches()).first.id)).single;
    const layout = BookletReading(marksRegion: Region(0.78, 0.33, 0.98, 0.6), questionColumnRegion: Region(0.64, 0.33, 0.78, 0.6));
    await BookletRepository(h.db, h.scores).saveReading(
      scanId: item.id,
      courseId: course.id,
      document: const OcrDocument(engine: 'test', lines: []),
      reading: layout,
    );
    ExtractedField row(int i, String value) => ExtractedField(
          key: 'mark_row_$i',
          kind: FieldKind.mark,
          state: FieldState.needsReview,
          value: value,
          question: '$i',
          candidates: [FieldCandidate(value, 0.5, source: 'unimarkly-digits/red_ink')],
          region: Region(0.78, 0.33 + i * 0.05, 0.98, 0.37 + i * 0.05),
        );
    return RecognitionRepository(h.db).saveRun(
      item.id,
      RecognitionResult(
        fields: [row(1, '4.5'), row(2, '2.0')],
        quality: null,
        findings: const [],
        layout: layout,
        models: const [],
        timingsMs: const {'decode': 1},
        printed: const OcrDocument(engine: 'test', lines: []),
      ),
    );
  }

  testWidgets('a machine row the examiner dismissed stays dismissed when the same reading is reopened', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () async {
      await seed();
      final runId = await seedRun();
      await h.drafts.save(firstScanId, ReviewDraft(dismissedRows: const {'mark_row_1'}, runId: runId));
    });
    await openFirstReview(tester);
    expect(find.textContaining('Row 1 · reads as Q1'), findsNothing);
    expect(find.textContaining('Row 2 · reads as Q2'), findsOneWidget);
    expect(find.textContaining('were restored'), findsOneWidget);
    await h.stop(tester);
  });

  testWidgets('dismissals made against an older reading are not applied to a newer one', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () async {
      await seed();
      await seedRun();
      await h.drafts.save(firstScanId, const ReviewDraft(dismissedRows: {'mark_row_1'}, runId: 'an-earlier-run'));
    });
    await openFirstReview(tester);
    expect(find.textContaining('Row 1 · reads as Q1'), findsOneWidget);
    expect(find.textContaining('Row 2 · reads as Q2'), findsOneWidget);
    await h.stop(tester);
  });
}
