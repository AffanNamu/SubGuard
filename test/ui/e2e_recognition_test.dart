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

  testWidgets('upload, read, review against the photo, confirm, export', (tester) async {
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
    expect(find.text('Machine readings of the marks table. Handwriting is read imperfectly: check each against the photo before using it.'), findsOneWidget);

    // ---- correct: the examiner types what the photograph shows ----
    await tester.enterText(find.widgetWithText(TextField, 'Registration number'), 'FWM/24U/0538');
    await h.settle(tester);
    Future<void> mark(int q, List<String> keys) async {
      await h.tapText(tester, 'Q-$q');
      for (final k in keys) {
        await tester.tap(find.descendant(of: find.byType(ScoreKeypad), matching: find.text(k)));
        await tester.pump();
      }
      await tester.tap(find.text('Save'));
      await h.settle(tester);
    }

    await mark(1, ['1']);
    await mark(2, ['1']);
    await mark(4, ['2']);
    await mark(5, ['5', '.5']);
    expect(find.text('9.5'), findsWidgets);

    // ---- confirm ----
    await tester.tap(find.text('Confirm & next'));
    await h.settle(tester);
    expect(find.text('Nothing to review'), findsOneWidget);

    // ---- saved, with the decisions and their evidence ----
    final data = await tester.runAsync(() async {
      final students = await h.students.getAll(course.id);
      final grid = await h.scores.get(course.id);
      final reviews = await h.db.select(h.db.fieldReviews).get();
      final runs = await h.db.select(h.db.recognitionRuns).get();
      return (students, grid, reviews, runs);
    });
    final student = data!.$1.firstWhere((s) => s.regNo == 'FWM/24U/0538');
    expect(data.$2[student.id]![course.scheme.examPart!.id]!.value, 9.5);
    expect(data.$3.map((r) => r.fieldKey), containsAll(['exam_number', 'mark_q1', 'mark_q2', 'mark_q4', 'mark_q5']));
    expect(data.$3.every((r) => r.reviewedAt.year >= 2026), isTrue);
    expect(data.$4, hasLength(1), reason: 'the machine output is kept, as produced');
    expect(data.$3.every((r) => r.runId == data.$4.single.id), isTrue);

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
    await h.reveal(tester, find.text('Q-1'));
    await h.tapText(tester, 'Q-1');
    await tester.tap(find.descendant(of: find.byType(ScoreKeypad), matching: find.text('1')));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await h.settle(tester);
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
