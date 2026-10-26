import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:unimarkly/core/widgets/score_keypad.dart';
import 'package:unimarkly/core/widgets/ui_kit.dart';
import 'package:unimarkly/data/repositories/recognition_repository.dart';
import 'package:unimarkly/data/repositories/booklet_repository.dart';
import 'package:unimarkly/domain/models.dart';
import 'package:unimarkly/features/scan/recognition_widgets.dart';
import 'package:unimarkly/services/export/labelled_export.dart';
import 'package:unimarkly/services/vision/photo_codec.dart';
import 'package:unimarkly/services/export/export_service.dart';
import 'package:unimarkly/services/export/result_table.dart';
import 'package:unimarkly/services/scan/image_source.dart';

import '../support/booklet_photo.dart';
import '../support/process_ocr_engine.dart';
import 'harness.dart';

/// The whole workflow through the real app: a photograph of a real booklet is
/// added, read by the real pipeline (real digit network, a real PP-OCR model
/// through the stand-in), reviewed against the photo, corrected, confirmed and
/// exported. Nothing in the recognition path is a mock.
void main() {
  final h = AppHarness();
  const tall = Size(390, 2600);

  testWidgets('upload, read, review against the photo, confirm, export (with the network switched off)', (tester) async {
    // Any attempt to open a network connection during the whole workflow fails the test: reading,
    // suggesting, reviewing, calculating the total, saving and exporting all work offline.
    final network = _NoNetwork();
    HttpOverrides.global = network;
    addTearDown(() => HttpOverrides.global = null);
    final ocr = await tester.runAsync(ProcessOcrEngine.tryStart);
    if (ocr == null) {
      markTestSkipped('OCR stand-in unavailable (pip install rapidocr-onnxruntime opencv-python-headless)');
      return;
    }
    late Course course;
    await h.start(tester, size: tall, tab: null, ocr: ocr, seed: () async {
      course = await h.createCourse(code: 'AGR 114', regNos: ['FWM/24U/0538', 'FWM/24U/0539']);
    });

    // ---- upload the photograph ----
    final photo = File(p.join(h.work.path, 'booklet.jpg'))..writeAsBytesSync(File(bookletPath).readAsBytesSync());
    h.imageSource.next = [PickedImage(name: 'booklet.jpg', path: photo.path)];
    await h.tapText(tester, 'Choose Images');
    for (var i = 0; i < 20 && find.byType(BackButton).evaluate().isEmpty; i++) {
      await h.settle(tester);
    }

    // ---- it is read in the background, offline, and waits for the examiner ----
    await h.waitForReading(tester, limit: const Duration(seconds: 180), untilQueueEmpty: true);
    await h.settle(tester);
    expect(ocr.calls, greaterThan(0), reason: 'the real text reader was used');
    final batches = await tester.runAsync(() => h.scans.batches());
    expect(batches!.single.counts.needsReview, 1);
    expect(batches.single.counts.confirmed, 0, reason: "reading never confirms anything");

    // Nothing is in the score grid yet.
    expect(await tester.runAsync(() => h.scores.get(course.id)), isEmpty);

    // ---- review: against the photo ----
    await tester.pageBack();
    await h.settle(tester);
    await h.tapText(tester, 'Home');
    await h.tapText(tester, 'Review Results');
    expect(find.textContaining('mark row'), findsWidgets, reason: 'the queue says why it is waiting');
    await tester.tap(find.byType(GlowCard).first); // the booklet waiting
    await h.settle(tester);

    // The picture was judged, and the field is empty: nothing was entered for the examiner.
    expect(find.textContaining('text is small'), findsWidgets);
    final exam = tester.widget<TextField>(find.widgetWithText(TextField, 'Registration number'));
    expect(exam.controller!.text, isEmpty);

    // ---- the marks table, as records: four rows found on the photograph, no fifth, no list of questions made up ----
    for (final i in [1, 2, 3, 4]) {
      await h.reveal(tester, find.byKey(ValueKey('record-mark_row_$i')));
      expect(find.byKey(ValueKey('record-mark_row_$i')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('record-mark_row_5')), findsNothing);
    expect(find.textContaining('Unable to read this mark confidently'), findsWidgets, reason: 'rows whose marks the reader could not read say so');
    // Nothing has been confirmed by recognition: there is no calculated total yet.
    await h.reveal(tester, find.byKey(const ValueKey('calculated-total')));
    expect(tester.widget<Text>(find.byKey(const ValueKey('calculated-total'))).data, '—');

    // ---- the examiner types the exam number from the photograph ----
    await h.reveal(tester, find.widgetWithText(TextField, 'Registration number'));
    await tester.enterText(find.widgetWithText(TextField, 'Registration number'), 'FWM/24U/0538');
    await h.settle(tester);

    Future<void> pad(List<String> keys) async {
      for (final k in keys) {
        await tester.tap(find.descendant(of: find.byType(ScoreKeypad), matching: find.text(k)));
        await tester.pump();
      }
      await tester.tap(find.text('Save'));
      await h.settle(tester);
    }

    Future<void> tapKey(String key) async {
      await h.reveal(tester, find.byKey(ValueKey(key)));
      await tester.tap(find.byKey(ValueKey(key)));
      await h.settle(tester);
    }

    // Row 1 and row 4: the examiner looked at the crops and takes both suggestions (Q1 = 1.0, Q5 = 5.5).
    await tapKey('both-mark_row_1');
    await tapKey('both-mark_row_4');
    // Rows 2 and 3: the question numbers are suggested (2 and 4); the marks could not be read, so they are typed.
    await tapKey('sq-mark_row_2-2');
    await tapKey('m-mark_row_2');
    await pad(['1']); // 1
    await tapKey('sq-mark_row_3-4');
    await tapKey('m-mark_row_3');
    await pad(['2']); // 2

    // The total is calculated from the four confirmed marks: 1 + 1 + 2 + 5.5 = 9.5. The Total box on the booklet is blank.
    await h.reveal(tester, find.byKey(const ValueKey('calculated-total')));
    expect(tester.widget<Text>(find.byKey(const ValueKey('calculated-total'))).data, '9.5');
    expect(find.textContaining('A blank Total box is normal'), findsOneWidget);

    // ---- confirm ----
    await h.reveal(tester, find.text('Confirm & next'));
    await tester.tap(find.text('Confirm & next'));
    await h.settle(tester);
    expect(find.text('Nothing to review'), findsOneWidget);

    // ---- saved: the records keep what was read apart from what was confirmed ----
    final data = await tester.runAsync(() async {
      final students = await h.students.getAll(course.id);
      final grid = await h.scores.get(course.id);
      final reviews = await h.db.select(h.db.fieldReviews).get();
      final runs = await h.db.select(h.db.recognitionRuns).get();
      final batches = await h.scans.batches();
      final scan = (await h.scans.scansOf(batches.single.id)).single;
      final booklet = await BookletRepository(h.db, h.scores).forScan(scan.id);
      return (students, grid, reviews, runs, booklet);
    });
    final student = data!.$1.firstWhere((s) => s.regNo == 'FWM/24U/0538');
    expect(data.$2[student.id]![course.scheme.examPart!.id]!.value, 9.5);
    expect(data.$3.map((r) => r.fieldKey), containsAll(['exam_number', 'mark_q1', 'mark_q2', 'mark_q4', 'mark_q5', 'question_q1', 'question_q5']));
    expect(data.$3.every((r) => r.reviewedAt.year >= 2026), isTrue);
    expect(data.$4, hasLength(1), reason: 'the machine output is kept, as produced');
    expect(data.$3.every((r) => r.runId == data.$4.single.id), isTrue);

    final booklet = data.$5!;
    expect(booklet.records.map((r) => (r.qNo, r.mark)), [(1, 1.0), (2, 1.0), (4, 2.0), (5, 5.5)]);
    expect(booklet.calculatedTotal, 9.5, reason: 'the derived total is stored with the booklet');
    expect(booklet.writtenTotal, isNull, reason: 'the Total box was blank and none was recorded');
    final byQ = {for (final r in booklet.records) r.qNo: r};
    expect(byQ[2]!.recognisedMark, isNotNull, reason: 'what the reader returned for the cell is kept apart from the confirmed 1.0');
    expect(byQ[2]!.status, 'edited', reason: 'the examiner typed over a reading that was not a mark');
    expect(byQ[5]!.status, 'accepted');
    expect(byQ[5]!.recognisedMark, '5.5');
    expect(byQ.values.every((r) => r.region != null && r.questionRegion != null), isTrue, reason: 'each record keeps where it is on the photograph');
    expect(byQ.values.every((r) => r.recognisedQuestion != null), isTrue);

    // ---- export: the confirmed score is in it ----
    final out = await tester.runAsync(() async {
      final c = (await h.courses.get(course.id))!;
      final result = await const ExportService().exportCourses(
        courses: [CourseExportData(course: c, students: await h.students.getAll(c.id), scores: await h.scores.get(c.id))],
        format: ExportFormat.csv,
        options: ExportOptions.preset(ExportPreset.fullResult, [c.scheme]),
        directory: Directory(p.join(h.work.path, 'out')),
        inBackground: false,
      );
      return utf8.decode(File(result.files.single.path).readAsBytesSync());
    });
    expect(out, contains('FWM/24U/0538'));
    expect(out, contains('9.5'));
    expect(network.attempts, 0, reason: 'the workflow tried to use the network');
    await tester.runAsync(ocr.stop);
    await h.stop(tester);
  }, timeout: const Timeout(Duration(minutes: 8)));
  testWidgets('a booklet photographed sideways: turned upright for reading, shown upright, its crops exported upright', (tester) async {
    final ocr = await tester.runAsync(ProcessOcrEngine.tryStart);
    if (ocr == null) {
      markTestSkipped('OCR stand-in unavailable (pip install rapidocr-onnxruntime opencv-python-headless)');
      return;
    }
    await h.start(tester, size: tall, tab: null, ocr: ocr, seed: () async {
      await h.createCourse(code: 'AGR 114', regNos: ['FWM/24U/0538', 'FWM/24U/0539']);
    });

    // The same booklet, lying on its side in the photograph (its top to the right).
    final photo = File(p.join(h.work.path, 'sideways.png'));
    await tester.runAsync(() async => photo.writeAsBytesSync(await encodeColorPng((await loadBooklet()).turned(1))));
    h.imageSource.next = [PickedImage(name: 'sideways.png', path: photo.path)];
    await h.tapText(tester, 'Choose Images');
    for (var i = 0; i < 20 && find.byType(BackButton).evaluate().isEmpty; i++) {
      await h.settle(tester);
    }
    await h.waitForReading(tester, limit: const Duration(seconds: 180), untilQueueEmpty: true);
    await h.settle(tester);

    // The reading says so, with the turn stored on the run.
    final run = await tester.runAsync(() async => RecognitionRepository(h.db).latestRun((await h.scans.scansOf((await h.scans.batches()).single.id)).single.id));
    expect(run!.result.turnedQuarters, 3);
    expect(run.result.layout.foundAnchors, hasLength(5));

    await tester.pageBack();
    await h.settle(tester);
    await h.tapText(tester, 'Home');
    await h.tapText(tester, 'Review Results');
    await tester.tap(find.byType(GlowCard).first);
    await h.settle(tester);
    expect(find.textContaining('photographed on its side'), findsOneWidget);

    // The machine's rows are found even though the photo was sideways, and "Show on photo"
    // shows the photograph upright with the row outlined.
    await h.reveal(tester, find.text('Show on photo'));
    await tester.tap(find.text('Show on photo').first);
    await h.settle(tester);
    expect(tester.widget<PhotoViewerScreen>(find.byType(PhotoViewerScreen)).turnedQuarters, 3);
    expect(find.byWidgetPredicate((w) => w is RotatedBox && w.quarterTurns == 3), findsOneWidget);
    await tester.pageBack();
    await h.settle(tester);

    // The examiner types what the photograph shows and confirms.
    await h.reveal(tester, find.widgetWithText(TextField, 'Registration number'));
    await tester.enterText(find.widgetWithText(TextField, 'Registration number'), 'FWM/24U/0538');
    await h.settle(tester);
    await h.reveal(tester, find.byKey(const ValueKey('both-mark_row_1')));
    await tester.tap(find.byKey(const ValueKey('both-mark_row_1')));
    await h.settle(tester);
    // The other rows are left out for this check (every row has to be dealt with before Confirm).
    for (final i in [2, 3, 4]) {
      await h.reveal(tester, find.byKey(ValueKey('dismiss-mark_row_$i')));
      await tester.tap(find.byKey(ValueKey('dismiss-mark_row_$i')));
      await h.settle(tester);
    }
    await h.reveal(tester, find.text('Confirm & next'));
    await tester.tap(find.text('Confirm & next'));
    await h.settle(tester);

    // What was confirmed becomes labelled examples whose crops are upright.
    final crops = await tester.runAsync(() async {
      final examples = await RecognitionRepository(h.db).labelledExamples();
      expect(examples, isNotEmpty);
      expect(examples.every((e) => e.turnedQuarters == 3), isTrue);
      final built = await LabelledExport.build(examples: examples, files: h.scanFiles, directory: Directory(p.join(h.work.path, 'labels')));
      final zip = ZipDecoder().decodeBytes(built!.file.readAsBytesSync());
      final out = <(String, int, int)>[];
      for (final f in zip.files.where((f) => f.name.startsWith('crops/'))) {
        final image = (await (await ui.instantiateImageCodec((f.content as List<int>) as dynamic)).getNextFrame()).image;
        out.add((f.name, image.width, image.height));
      }
      return out;
    });
    expect(crops, isNotEmpty);
    for (final c in crops!) {
      expect(c.$2, greaterThan(c.$3), reason: '${c.$1} is a line or a cell of writing: wider than tall once upright (${c.$2} x ${c.$3})');
    }
    await tester.runAsync(ocr.stop);
    await h.stop(tester);
  }, timeout: const Timeout(Duration(minutes: 8)));
}

/// Counts, and refuses, every attempt to open an HTTP connection.
class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw const SocketException('There is no network in this test: UniMarkLy must work offline.');
  }
}
