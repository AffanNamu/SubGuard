import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/services/export/csv_writer.dart';
import 'package:unimarkly/services/export/docx_writer.dart';
import 'package:unimarkly/services/export/export_service.dart';
import 'package:unimarkly/services/export/pdf_writer.dart';
import 'package:unimarkly/services/export/result_table.dart';
import 'package:unimarkly/services/export/xlsx_writer.dart';
import 'package:xml/xml.dart';

import '../support/fixtures.dart';

const _w = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';

void main() {
  final f = Fixture();
  const header = ExportHeader(university: 'Modibbo Adama University, Yola', faculty: 'Faculty of Agriculture');

  ResultTable table(ExportPreset preset, {Fixture? fixture, ExportHeader h = const ExportHeader()}) {
    final fx = fixture ?? f;
    return ResultTableBuilder.build(
      course: fx.course,
      students: fx.students,
      scores: fx.scores,
      options: ExportOptions.preset(preset, [fx.course.scheme]),
      header: h,
    );
  }

  group('CSV', () {
    test('has the same columns and rows as the table, with a byte-order mark', () {
      final bytes = CsvWriter.build(table(ExportPreset.fullResult));
      expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
      final lines = const LineSplitter().convert(utf8.decode(bytes.skip(3).toList()));
      expect(lines.first, 'S/N,Registration No.,Exam,Attendance,Assignment,Test,Total,Grade');
      expect(lines[1], '1,FWM/24U/0538,9.5,4,3.5,5.0,22,F');
      expect(lines[2], '2,FST/25U/244/5772,58,9,8.0,9.5,84.5,A');
      expect(lines.length, 5);
    });

    test('quotes a value that contains a comma', () {
      const t = ResultTable(
        title: 't',
        headerLines: [],
        columns: [ExportColumn(ExportColumnKind.regNo, 'Registration No.')],
        rows: [
          [ExportCell('A,B')]
        ],
      );
      expect(utf8.decode(CsvWriter.build(t).skip(3).toList()), contains('"A,B"'));
    });
  });

  group('DOCX', () {
    late Archive zip;
    late XmlDocument doc;
    late XmlDocument styles;

    XmlDocument parse(String name) {
      final file = zip.findFile(name)!;
      return XmlDocument.parse(utf8.decode(file.content as List<int>));
    }

    setUp(() {
      final bytes = DocxWriter.build(table(ExportPreset.fullResult, h: header));
      zip = ZipDecoder().decodeBytes(bytes);
      doc = parse('word/document.xml');
      styles = parse('word/styles.xml');
    });

    Iterable<XmlElement> all(XmlNode n, String name) => n.findAllElements(name, namespace: _w);
    String text(XmlNode n) => all(n, 't').map((t) => t.innerText).join();

    test('is a valid package with the parts Word needs', () {
      final names = zip.files.map((e) => e.name).toSet();
      expect(names, containsAll([
        '[Content_Types].xml', '_rels/.rels', 'word/document.xml',
        'word/_rels/document.xml.rels', 'word/styles.xml',
      ]));
      expect(zip.files.first.name, '[Content_Types].xml');
      for (final n in names.where((n) => n.endsWith('.xml') || n.endsWith('.rels'))) {
        expect(() => parse(n), returnsNormally, reason: '$n is well-formed XML');
      }
    });

    test('is A4 portrait', () {
      final pg = all(doc, 'pgSz').single;
      expect(pg.getAttribute('w', namespace: _w), '11906');
      expect(pg.getAttribute('h', namespace: _w), '16838');
      expect(pg.getAttribute('orient', namespace: _w), isNull);
    });

    test('is Times New Roman 12 pt', () {
      final fonts = all(styles, 'rFonts').single;
      expect(fonts.getAttribute('ascii', namespace: _w), 'Times New Roman');
      expect(fonts.getAttribute('hAnsi', namespace: _w), 'Times New Roman');
      expect(all(styles, 'sz').first.getAttribute('val', namespace: _w), '24');
    });

    test('has the heading and the header lines', () {
      final paragraphs = doc.findAllElements('p', namespace: _w).map(text).where((t) => t.isNotEmpty).toList();
      expect(paragraphs.take(3), ['Modibbo Adama University, Yola', 'Faculty of Agriculture', '(FWM) AGR 114']);
    });

    test('has one table with a header row and a row per student', () {
      final tables = all(doc, 'tbl').toList();
      expect(tables, hasLength(1));
      final rows = all(tables.single, 'tr').toList();
      expect(rows, hasLength(1 + f.students.length));
      expect(all(rows.first, 'tc').map(text).toList(),
          ['S/N', 'Registration No.', 'Exam', 'Attendance', 'Assignment', 'Test', 'Total', 'Grade']);
      expect(all(rows[1], 'tc').map(text).toList(),
          ['1', 'FWM/24U/0538', '9.5', '4', '3.5', '5.0', '22', 'F']);
    });

    test('header row is grey, bold and repeats on every page', () {
      final header = all(doc, 'tr').first;
      expect(all(header, 'tblHeader'), isNotEmpty);
      for (final tc in all(header, 'tc')) {
        expect(all(tc, 'shd').single.getAttribute('fill', namespace: _w), 'D9D9D9');
        expect(all(tc, 'b'), isNotEmpty);
      }
      final body = all(doc, 'tr').elementAt(1);
      expect(all(body, 'shd'), isEmpty);
    });

    test('has borders on every cell', () {
      final borders = all(doc, 'tblBorders').single;
      for (final side in ['top', 'left', 'bottom', 'right', 'insideH', 'insideV']) {
        final b = borders.findElements(side, namespace: _w).single;
        expect(b.getAttribute('val', namespace: _w), 'single', reason: side);
      }
    });

    test('every row has a cell for every column, even when blank', () {
      final exam = DocxWriter.build(table(ExportPreset.examSheet));
      final d = XmlDocument.parse(
          utf8.decode(ZipDecoder().decodeBytes(exam).findFile('word/document.xml')!.content as List<int>));
      for (final tr in all(d, 'tr')) {
        expect(all(tr, 'tc'), hasLength(7));
        for (final tc in all(tr, 'tc')) {
          expect(all(tc, 'p'), isNotEmpty, reason: 'a cell must hold a paragraph');
        }
      }
    });

    test('escapes characters that are special in XML', () {
      expect(DocxWriter.esc('A & B <C> "D"'), 'A &amp; B &lt;C&gt; &quot;D&quot;');
      const t = ResultTable(
        title: 'R&D <test>',
        headerLines: [],
        columns: [ExportColumn(ExportColumnKind.regNo, 'Registration No.')],
        rows: [[ExportCell('A & B')]],
      );
      final d = XmlDocument.parse(utf8.decode(
          ZipDecoder().decodeBytes(DocxWriter.build(t)).findFile('word/document.xml')!.content as List<int>));
      expect(text(d), contains('R&D <test>'));
      expect(text(d), contains('A & B'));
    });

    test('turns landscape when there are too many columns for the page', () {
      final wide = ResultTable(
        title: 'wide',
        headerLines: const [],
        columns: [for (var i = 0; i < 10; i++) ExportColumn(ExportColumnKind.part, 'Part $i')],
        rows: const [],
      );
      final d = XmlDocument.parse(utf8.decode(
          ZipDecoder().decodeBytes(DocxWriter.build(wide)).findFile('word/document.xml')!.content as List<int>));
      final pg = all(d, 'pgSz').single;
      expect(pg.getAttribute('orient', namespace: _w), 'landscape');
      expect(pg.getAttribute('w', namespace: _w), '16838');
    });
  });

  group('XLSX', () {
    test('has the same columns and typed values as the table', () {
      final bytes = XlsxWriter.build(table(ExportPreset.fullResult, h: header));
      final book = Excel.decodeBytes(bytes);
      final sheet = book.tables.values.single;
      final rows = sheet.rows
          .map((r) => r.map((c) => c?.value).toList())
          .where((r) => r.any((c) => c != null))
          .toList();

      expect(rows[0].first.toString(), 'Modibbo Adama University, Yola');
      expect(rows[2].first.toString(), '(FWM) AGR 114');

      final headerIndex = rows.indexWhere((r) => r.first?.toString() == 'S/N');
      expect(rows[headerIndex].map((c) => c.toString()).toList(),
          ['S/N', 'Registration No.', 'Exam', 'Attendance', 'Assignment', 'Test', 'Total', 'Grade']);

      final first = rows[headerIndex + 1];
      expect(first[0], isA<IntCellValue>());
      expect(first[1].toString(), 'FWM/24U/0538');
      expect((first[2] as DoubleCellValue).value, 9.5);
      expect((first[3] as IntCellValue).value, 4);
      expect((first[4] as DoubleCellValue).value, 3.5);
      expect((first[6] as IntCellValue).value, 22);
      expect(first[7].toString(), 'F');

      final absent = rows[headerIndex + 4];
      expect(absent[2].toString(), 'ABS');
    });

    test('blank cells are empty', () {
      final book = Excel.decodeBytes(XlsxWriter.build(table(ExportPreset.examSheet)));
      final sheet = book.tables.values.single;
      final headerRow = sheet.rows.indexWhere((r) => r.first?.value.toString() == 'S/N');
      final first = sheet.rows[headerRow + 1];
      expect(first[2]?.value.toString(), '9.5');
      expect(first[3]?.value, isNull);
      expect(first[6]?.value, isNull);
    });
  });

  group('PDF', () {
    int pageCount(List<int> bytes) =>
        RegExp(r'/Type\s*/Page\b').allMatches(latin1.decode(Uint8List.fromList(bytes))).length;

    test('is a PDF with at least one page', () async {
      final bytes = await PdfWriter.build(table(ExportPreset.fullResult, h: header));
      expect(latin1.decode(bytes.take(5).toList()), '%PDF-');
      expect(pageCount(bytes), greaterThanOrEqualTo(1));
    });

    test('a long class list runs over several pages', () async {
      final big = Fixture(extraStudents: 120);
      final bytes = await PdfWriter.build(table(ExportPreset.fullResult, fixture: big));
      expect(pageCount(bytes), greaterThan(2));
    });
  });

  group('ExportService', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('unimarkly_export_'));
    tearDown(() => dir.deleteSync(recursive: true));

    CourseExportData data(Fixture fx) =>
        CourseExportData(course: fx.course, students: fx.students, scores: fx.scores);

    test('file names are safe and descriptive', () {
      expect(ExportService.fileName(f.course, ExportFormat.docx, label: 'Full result'),
          'FWM_AGR-114_2024-2025_Full-result.docx');
      expect(ExportService.fileName(f.course, ExportFormat.csv), 'FWM_AGR-114_2024-2025.csv');
    });

    for (final format in ExportFormat.values) {
      test('writes a ${format.label} file that is not empty', () async {
        final result = await const ExportService().exportCourses(
          courses: [data(f)],
          format: format,
          options: ExportOptions.preset(ExportPreset.fullResult, [f.course.scheme]),
          directory: dir,
        );
        expect(result.failures, isEmpty);
        final file = File(result.files.single.path);
        expect(file.existsSync(), isTrue);
        expect(file.lengthSync(), greaterThan(200));
        expect(result.files.single.name.endsWith('.${format.extension}'), isTrue);
      });
    }

    test('several courses export in one go, one file per course', () async {
      final other = Fixture();
      final renamed = other.course.copyWith(code: 'BIO 201');
      final result = await const ExportService().exportCourses(
        courses: [
          data(f),
          CourseExportData(course: renamed, students: other.students, scores: other.scores),
        ],
        format: ExportFormat.xlsx,
        options: ExportOptions.preset(ExportPreset.examSheet, [f.course.scheme]),
        directory: dir,
        label: 'Exam sheet',
      );
      expect(result.files.map((e) => e.name),
          ['FWM_AGR-114_2024-2025_Exam-sheet.xlsx', 'FWM_BIO-201_2024-2025_Exam-sheet.xlsx']);
      expect(dir.listSync(), hasLength(2));
    });

    test('a course of 500 students exports in every format in good time', () async {
      final big = Fixture(extraStudents: 496);
      final watch = Stopwatch()..start();
      for (final format in ExportFormat.values) {
        final result = await const ExportService().exportCourses(
          courses: [data(big)],
          format: format,
          options: ExportOptions.preset(ExportPreset.fullResult, [big.course.scheme]),
          directory: dir,
        );
        expect(result.failures, isEmpty, reason: format.label);
      }
      expect(watch.elapsed.inSeconds, lessThan(30));
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
