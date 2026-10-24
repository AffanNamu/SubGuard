import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:unimarkly/domain/models.dart';
import 'package:unimarkly/features/incoming/incoming_controller.dart';
import 'package:unimarkly/features/incoming/incoming_file_screen.dart';
import 'package:unimarkly/services/export/docx_writer.dart';
import 'package:unimarkly/services/export/pdf_writer.dart';
import 'package:unimarkly/services/export/result_table.dart';
import 'package:unimarkly/services/export/xlsx_writer.dart';
import 'package:unimarkly/services/incoming/file_inspector.dart';
import 'package:unimarkly/services/incoming/incoming_file.dart';

import '../support/fixtures.dart';
import '../support/images.dart';
import 'harness.dart';

/// Documents arriving from other apps: what the phone hands over is a private
/// copy, and these tests hand the app real files of every kind through the same
/// path the Android and iOS code uses.
void main() {
  final h = AppHarness();
  final fx = Fixture();

  ResultTable table() => ResultTableBuilder.build(
        course: fx.course,
        students: fx.students,
        scores: fx.scores,
        options: ExportOptions.preset(ExportPreset.fullResult, [fx.course.scheme]),
        header: const ExportHeader(university: 'Modibbo Adama University, Yola'),
      );

  var counter = 0;

  /// A private copy, where the platform code puts it: <cache>/incoming/<id>/<name>.
  IncomingFile copyOf(String name, List<int> bytes, {String? mime}) {
    final dir = Directory(p.join(h.work.path, 'incoming', 'copy${counter++}'))..createSync(recursive: true);
    final f = File(p.join(dir.path, name))..writeAsBytesSync(bytes);
    return IncomingFile(id: 'id${counter}_$name', path: f.path, name: name, mime: mime, size: bytes.length);
  }

  Future<void> until(WidgetTester tester, bool Function() done, {int max = 60}) async {
    for (var i = 0; i < max && !done(); i++) {
      await h.settle(tester);
    }
  }

  Future<void> arrive(WidgetTester tester, List<IncomingFile> files, {List<IncomingFailure> failures = const []}) async {
    h.incoming.deliver(IncomingArrived(files: files, failures: failures));
    await tester.pump();
    await h.settle(tester);
  }

  Future<void> startOnCourse(WidgetTester tester, {List<String> regNos = const ['FWM/24U/0538']}) => h.start(
        tester,
        size: const Size(390, 900),
        tab: null,
        seed: () async => await h.createCourse(regNos: regNos),
      );

  group('a PDF opened from another app', () {
    testWidgets('is shown, with next steps, and the private copy is cleaned up afterwards', (tester) async {
      await startOnCourse(tester);
      final pdf = await tester.runAsync(() => PdfWriter.build(table()));
      final file = copyOf('Results AGR 114.pdf', pdf!, mime: 'application/pdf');

      await arrive(tester, [file]);
      await until(tester, () => find.text('PDF PAGES: 3').evaluate().isNotEmpty);

      expect(find.text('Results AGR 114.pdf'), findsOneWidget);
      expect(find.textContaining('PDF document'), findsOneWidget);
      expect(find.text('PDF PAGES: 3'), findsOneWidget);
      expect(find.text('Scan its pages as booklets'), findsOneWidget);
      expect(find.text('Save a copy'), findsOneWidget);
      expect(h.pdf.viewed, [file.path]);
      expect(File(file.path).existsSync(), isTrue, reason: 'the copy stays while it is open');

      await tester.pageBack();
      await until(tester, () => !File(file.path).existsSync());
      expect(File(file.path).existsSync(), isFalse, reason: 'the private copy is removed when the viewer closes');
      await h.stop(tester);
    });

    testWidgets('Save a copy keeps it in UniMarkLy once, never twice, never over another file', (tester) async {
      await startOnCourse(tester);
      final bytes = (await tester.runAsync(() => PdfWriter.build(table())))!;
      await arrive(tester, [copyOf('r.pdf', bytes)]);
      await until(tester, () => find.text('Save a copy').evaluate().isNotEmpty);

      await h.tapText(tester, 'Save a copy');
      await until(tester, () => find.textContaining('Saved in UniMarkLy: r.pdf').evaluate().isNotEmpty);
      expect(find.textContaining('Saved in UniMarkLy: r.pdf'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5)); // the message goes away
      await tester.pump(const Duration(milliseconds: 500));
      await h.tapText(tester, 'Save a copy');
      await until(tester, () => find.textContaining('Already saved').evaluate().isNotEmpty);
      expect(find.textContaining('Already saved'), findsOneWidget);

      final saved = await tester.runAsync(() => h.savedDocuments.list());
      expect(saved!.map((s) => s.name), ['r.pdf']);
      await h.stop(tester);
    });

    testWidgets('its pages can be turned into booklet photos for scanning', (tester) async {
      await startOnCourse(tester);
      final bytes = (await tester.runAsync(() => PdfWriter.build(table())))!;
      await arrive(tester, [copyOf('booklets.pdf', bytes)]);
      await until(tester, () => find.text('Scan its pages as booklets').evaluate().isNotEmpty);

      await h.tapText(tester, 'Scan its pages as booklets');
      await until(tester, () => find.text('Scan & Extract').evaluate().isNotEmpty);

      expect(find.text('Scan & Extract'), findsWidgets);
      final batches = await tester.runAsync(() => h.scans.batches());
      expect(batches!.single.counts.images, 3);
      await h.stop(tester);
    });

    testWidgets('a PDF the phone cannot draw says so and still offers sharing and saving', (tester) async {
      await startOnCourse(tester);
      h.pdf.failToOpen = true;
      final bytes = (await tester.runAsync(() => PdfWriter.build(table())))!;
      await arrive(tester, [copyOf('odd.pdf', bytes)]);
      await until(tester, () => find.text('This PDF could not be drawn').evaluate().isNotEmpty);

      expect(find.text('This PDF could not be drawn'), findsOneWidget);
      expect(find.text('Save a copy'), findsOneWidget);
      expect(find.text('Open in another app'), findsWidgets);
      h.pdf.failToOpen = false;
      await h.stop(tester);
    });
  });

  group('Word', () {
    testWidgets('a .docx is shown as text with its table', (tester) async {
      await startOnCourse(tester);
      final bytes = DocxWriter.build(table());
      await arrive(tester, [copyOf('result.docx', bytes)]);
      await until(tester, () => find.textContaining('Text view').evaluate().isNotEmpty);

      expect(find.textContaining('Word document'), findsOneWidget);
      expect(find.textContaining('Modibbo Adama University'), findsOneWidget);
      expect(find.text('FWM/24U/0538'), findsOneWidget);
      expect(find.text('84.5'), findsOneWidget);
      await h.stop(tester);
    });

    testWidgets('an old .doc gets a plain fallback instead of a blank screen', (tester) async {
      await startOnCourse(tester);
      final ole = [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1, ...List.filled(600, 0)];
      await arrive(tester, [copyOf('old.doc', ole)]);
      await until(tester, () => find.textContaining('Old Word files').evaluate().isNotEmpty);

      expect(find.text('Old Word files cannot be shown here'), findsOneWidget);
      expect(find.text('Open in another app'), findsWidgets);
      expect(find.text('Save a copy'), findsOneWidget);
      await h.stop(tester);
    });

    testWidgets('a locked Word file says it is locked', (tester) async {
      await startOnCourse(tester);
      final ole = [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1, ...List.filled(600, 0)];
      await arrive(tester, [copyOf('locked.docx', ole)]);
      await until(tester, () => find.text('This file is locked').evaluate().isNotEmpty);
      expect(find.text('This file is locked'), findsOneWidget);
      expect(find.textContaining('protected with a password'), findsOneWidget);
      await h.stop(tester);
    });
  });

  group('Excel and CSV', () {
    testWidgets('an .xlsx is shown as a grid and its sheet is read', (tester) async {
      await startOnCourse(tester);
      final bytes = XlsxWriter.build(table());
      await arrive(tester, [copyOf('result.xlsx', bytes)]);
      await until(tester, () => find.text('FWM/24U/0538').evaluate().isNotEmpty);

      expect(find.textContaining('Excel workbook'), findsOneWidget);
      expect(find.text('Registration No.'), findsWidgets);
      expect(find.text('FWM/24U/0538'), findsOneWidget);
      expect(find.text('Use as class list'), findsOneWidget);
      await h.stop(tester);
    });

    testWidgets('a .csv class list: viewing changes nothing; adding needs the confirm button', (tester) async {
      late Course course;
      await h.start(tester, size: const Size(390, 900), tab: null, seed: () async {
        course = await h.createCourse(regNos: const ['FWM/24U/0538']);
      });
      const csv = 'Registration No.,Name\nFWM/24U/0601,Aisha Bello\nFWM/24U/0602,Bala Musa\n';
      await arrive(tester, [copyOf('new class.csv', csv.codeUnits)]);
      await until(tester, () => find.text('Aisha Bello').evaluate().isNotEmpty);

      expect(find.textContaining('CSV table'), findsOneWidget);
      expect(find.text('FWM/24U/0601'), findsOneWidget);
      var students = await tester.runAsync(() => h.students.getAll(course.id));
      expect(students!.length, 1, reason: 'opening a file changes no class list');

      await h.tapText(tester, 'Use as class list');
      await until(tester, () => find.text('Add to class list').evaluate().isNotEmpty);
      expect(find.textContaining('new class.csv'), findsWidgets);
      students = await tester.runAsync(() => h.students.getAll(course.id));
      expect(students!.length, 1, reason: 'the import screen still has not written anything');

      await h.tapText(tester, 'Add to class list');
      students = await tester.runAsync(() => h.students.getAll(course.id));
      expect(students!.map((s) => s.regNo), containsAll(['FWM/24U/0538', 'FWM/24U/0601', 'FWM/24U/0602']));
      await h.stop(tester);
    });

    testWidgets('with several courses the person chooses which one first', (tester) async {
      await h.start(tester, size: const Size(390, 900), tab: null, seed: () async {
        await h.createCourse(code: 'AGR 114', regNos: const []);
        await h.createCourse(code: 'BIO 201', department: 'FST', regNos: const []);
      });
      await arrive(tester, [copyOf('list.csv', 'Reg\nFWM/24U/0701\n'.codeUnits)]);
      await until(tester, () => find.text('Use as class list').evaluate().isNotEmpty);
      await h.tapText(tester, 'Use as class list');
      await h.settle(tester);
      expect(find.text('Which course is this class list for?'), findsOneWidget);
      await h.stop(tester);
    });
  });

  group('photos', () {
    testWidgets('a photo opened from another app can start the scan workflow', (tester) async {
      await startOnCourse(tester);
      final png = (await tester.runAsync(() => makePng(300, 400, const ui.Color(0xFF334455))))!;
      await arrive(tester, [copyOf('IMG_2041.jpg', png)]);
      await until(tester, () => find.text('Scan this booklet').evaluate().isNotEmpty);

      expect(find.textContaining('Photo'), findsWidgets);
      await h.tapText(tester, 'Scan this booklet');
      await until(tester, () => find.text('Scan & Extract').evaluate().isNotEmpty);

      expect(find.text('Scan & Extract'), findsWidgets);
      final batches = await tester.runAsync(() => h.scans.batches());
      expect(batches!.single.counts.images, 1);
      await h.stop(tester);
    });

    testWidgets('several photos arrive as a list that scans them together', (tester) async {
      await startOnCourse(tester);
      final a = (await tester.runAsync(() => makePng(300, 400, const ui.Color(0xFF334455))))!;
      final b = (await tester.runAsync(() => makePng(301, 400, const ui.Color(0xFF445566))))!;
      await arrive(tester, [copyOf('one.png', a), copyOf('two.png', b)]);
      await until(tester, () => find.textContaining('Scan 2 photos').evaluate().isNotEmpty);

      expect(find.text('2 documents'), findsOneWidget);
      await h.tapText(tester, 'Scan 2 photos as booklets');
      await until(tester, () => find.text('Scan & Extract').evaluate().isNotEmpty);
      final batches = await tester.runAsync(() => h.scans.batches());
      expect(batches!.single.counts.images, 2);
      await h.stop(tester);
    });
  });

  group('file safety', () {
    testWidgets('an unsupported file, a damaged PDF and an empty file each explain themselves', (tester) async {
      await startOnCourse(tester);

      await arrive(tester, [copyOf('movie.mp4', List.filled(200, 7))]);
      await until(tester, () => find.text('This kind of file cannot be opened').evaluate().isNotEmpty);
      expect(find.text('This kind of file cannot be opened'), findsOneWidget);
      await tester.pageBack();
      await h.settle(tester);

      await arrive(tester, [copyOf('broken.pdf', 'not really a pdf'.codeUnits)]);
      await until(tester, () => find.text('This file is damaged').evaluate().isNotEmpty);
      expect(find.text('This file is damaged'), findsOneWidget);
      expect(h.pdf.viewed, isEmpty, reason: 'a damaged PDF is never handed to the viewer');
      await tester.pageBack();
      await h.settle(tester);

      await arrive(tester, [copyOf('empty.csv', const [])]);
      await until(tester, () => find.text('This file is empty').evaluate().isNotEmpty);
      expect(find.text('This file is empty'), findsOneWidget);
      await h.stop(tester);
    });

    testWidgets('a file over the size limit is refused for viewing but can be shared or saved', (tester) async {
      await startOnCourse(tester);
      final dir = Directory(p.join(h.work.path, 'incoming', 'big'))..createSync(recursive: true);
      final big = File(p.join(dir.path, 'huge.csv'));
      final raf = big.openSync(mode: FileMode.write);
      raf.setPositionSync(FileInspector.maxViewBytes + 5);
      raf.writeByteSync(65);
      raf.closeSync();
      await arrive(tester, [IncomingFile(id: 'big', path: big.path, name: 'huge.csv', size: big.lengthSync())]);
      await until(tester, () => find.text('This file is too large to open here').evaluate().isNotEmpty);
      expect(find.text('This file is too large to open here'), findsOneWidget);
      expect(find.text('Open in another app'), findsOneWidget);
      await h.stop(tester);
    });

    testWidgets('files the phone could not copy are listed with the reason', (tester) async {
      await startOnCourse(tester);
      await arrive(tester, const [], failures: const [
        IncomingFailure(name: 'secret.pdf', message: 'UniMarkLy is not allowed to read this file.'),
      ]);
      expect(find.text('This file could not be opened'), findsOneWidget);
      expect(find.text('secret.pdf'), findsOneWidget);
      expect(find.text('UniMarkLy is not allowed to read this file.'), findsOneWidget);
      await h.stop(tester);
    });

    testWidgets('the same open delivered twice shows one screen, and the extra copy is removed', (tester) async {
      await startOnCourse(tester);
      final first = copyOf('twice.csv', 'Reg\nFWM/24U/0801\n'.codeUnits);
      final second = copyOf('twice.csv', 'Reg\nFWM/24U/0801\n'.codeUnits);
      h.incoming.deliver(IncomingArrived(files: [first]));
      h.incoming.deliver(IncomingArrived(files: [second]));
      await tester.pump();
      await until(tester, () => find.byType(IncomingFileScreen).evaluate().isNotEmpty);

      expect(find.byType(IncomingFileScreen), findsOneWidget);
      expect(File(second.path).existsSync(), isFalse);
      await h.stop(tester);
    });

    testWidgets('opening the same file again later is allowed and nothing is imported by it', (tester) async {
      late Course course;
      await h.start(tester, size: const Size(390, 900), tab: null, seed: () async {
        course = await h.createCourse(regNos: const ['FWM/24U/0538']);
      });
      IncomingController.duplicateWindow = Duration.zero; // "later" is later than the window
      addTearDown(() => IncomingController.duplicateWindow = const Duration(seconds: 4));
      for (var i = 0; i < 2; i++) {
        await arrive(tester, [copyOf('later.csv', 'Reg\nFWM/24U/0901\n'.codeUnits)]);
        await until(tester, () => find.text('FWM/24U/0901').evaluate().isNotEmpty);
        await tester.pageBack();
        await h.settle(tester);
        // Move the clock past the duplicate window for the second round.
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      }
      final students = await tester.runAsync(() => h.students.getAll(course.id));
      expect(students!.length, 1);
      await h.stop(tester);
    });
  });

  group('when the app is running, in the background, or closed', () {
    testWidgets('a document that started the app is opened once the app is up (cold start)', (tester) async {
      final bytes = XlsxWriter.build(table());
      // Arrives before anything can be shown, as when the file launched the app.
      h.incoming.beforeReady.add(const IncomingStarted(1));
      await h.start(tester, size: const Size(390, 900), tab: null, seed: () async {
        await h.createCourse();
      }, beforeStart: () {
        final file = copyOf('cold.xlsx', bytes);
        h.incoming.beforeReady.add(IncomingArrived(files: [file]));
      });
      await until(tester, () => find.text('FWM/24U/0538').evaluate().isNotEmpty);
      expect(find.textContaining('Excel workbook'), findsOneWidget);
      await h.stop(tester);
    });

    testWidgets('an "opening" message shows while the phone is still copying a large file', (tester) async {
      await startOnCourse(tester);
      h.incoming.deliver(const IncomingStarted(2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Opening 2 documents…'), findsOneWidget);

      h.incoming.deliver(IncomingArrived(files: [copyOf('a.csv', 'Reg\nX/24U/0001\n'.codeUnits)]));
      await tester.pump();
      expect(find.text('Opening the document…'), findsOneWidget, reason: 'one of the two is still coming');
      h.incoming.deliver(const IncomingArrived(failures: [IncomingFailure(name: 'b.pdf', message: 'Gone.')]));
      await h.settle(tester);
      expect(find.text('Opening 2 documents…'), findsNothing);
      await h.stop(tester);
    });

    testWidgets('a document arriving while another viewer is open opens on top of it', (tester) async {
      await startOnCourse(tester);
      await arrive(tester, [copyOf('first.csv', 'Reg\nFWM/24U/1001\n'.codeUnits)]);
      await until(tester, () => find.text('FWM/24U/1001').evaluate().isNotEmpty);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await arrive(tester, [copyOf('second.csv', 'Reg\nFWM/24U/1002\n'.codeUnits)]);
      await until(tester, () => find.text('FWM/24U/1002').evaluate().isNotEmpty);
      expect(find.text('second.csv'), findsOneWidget);

      await tester.pageBack();
      await h.settle(tester);
      expect(find.text('first.csv'), findsOneWidget, reason: 'the first document is still there underneath');
      await h.stop(tester);
    });
  });
}
