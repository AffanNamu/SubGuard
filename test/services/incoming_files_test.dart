import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:unimarkly/services/export/csv_writer.dart';
import 'package:unimarkly/services/export/docx_writer.dart';
import 'package:unimarkly/services/export/pdf_writer.dart';
import 'package:unimarkly/services/export/result_table.dart';
import 'package:unimarkly/services/export/xlsx_writer.dart';
import 'package:unimarkly/services/incoming/document_loaders.dart';
import 'package:unimarkly/services/incoming/file_inspector.dart';
import 'package:unimarkly/services/incoming/incoming_file.dart';

import '../support/fixtures.dart';
import '../support/images.dart';

/// What the app does with real files of every kind it claims to open: the
/// formats UniMarkLy itself writes, plus the awkward cases (a renamed file, a
/// damaged file, a locked file).
void main() {
  late Directory dir;
  final f = Fixture();

  ResultTable table() => ResultTableBuilder.build(
        course: f.course,
        students: f.students,
        scores: f.scores,
        options: ExportOptions.preset(ExportPreset.fullResult, [f.course.scheme]),
        header: const ExportHeader(university: 'Modibbo Adama University, Yola'),
      );

  File write(String name, List<int> bytes) => File(p.join(dir.path, name))..writeAsBytesSync(bytes);

  setUp(() => dir = Directory.systemTemp.createTempSync('unimarkly_incoming_'));
  tearDown(() => dir.deleteSync(recursive: true));

  group('telling what a file really is', () {
    test('the four formats UniMarkLy writes are recognised from their bytes', () async {
      final pdf = write('result.pdf', await PdfWriter.build(table()));
      final docx = write('result.docx', DocxWriter.build(table()));
      final xlsx = write('result.xlsx', XlsxWriter.build(table()));
      final csv = write('result.csv', CsvWriter.build(table()));

      expect((await FileInspector.inspect(pdf)).kind, IncomingKind.pdf);
      expect((await FileInspector.inspect(docx)).kind, IncomingKind.docx);
      expect((await FileInspector.inspect(xlsx)).kind, IncomingKind.xlsx);
      expect((await FileInspector.inspect(csv)).kind, IncomingKind.csv);
      for (final file in [pdf, docx, xlsx, csv]) {
        expect((await FileInspector.inspect(file)).ok, isTrue, reason: file.path);
      }
    });

    test('a real photo is an image whatever its name says', () async {
      final png = write('IMG_0001.dat', await makePng(40, 30, const ui.Color(0xFF223344)));
      expect((await FileInspector.inspect(png)).kind, IncomingKind.image);
    });

    test('the name decides only when the bytes do not', () async {
      final xlsxNamedDocx = write('wrong.docx', XlsxWriter.build(table()));
      expect((await FileInspector.inspect(xlsxNamedDocx)).kind, IncomingKind.xlsx,
          reason: 'an Excel file named .docx is shown as Excel');
    });
  });

  group('files that can not be opened say why', () {
    test('a missing file', () async {
      final r = await FileInspector.inspect(File(p.join(dir.path, 'gone.pdf')));
      expect(r.problem, FileProblem.missing);
    });

    test('an empty file', () async {
      final r = await FileInspector.inspect(write('empty.pdf', const []));
      expect(r.problem, FileProblem.empty);
    });

    test('an unsupported type', () async {
      final r = await FileInspector.inspect(write('movie.mp4', List.filled(100, 7)));
      expect(r.problem, FileProblem.unsupported);
    });

    test('a file named .pdf that is not a PDF is damaged, not shown blank', () async {
      final r = await FileInspector.inspect(write('fake.pdf', 'hello, this is text'.codeUnits));
      expect(r.problem, FileProblem.corrupt);
      expect(r.kind, IncomingKind.pdf);
    });

    test('a PDF cut off in the middle still looks like a PDF but a text file named .docx is damaged', () async {
      final bytes = await PdfWriter.build(table());
      final cut = write('cut.pdf', bytes.sublist(0, bytes.length ~/ 2));
      // The header is intact; the viewer reports anything it can not draw.
      expect((await FileInspector.inspect(cut)).kind, IncomingKind.pdf);

      final r = await FileInspector.inspect(write('notes.docx', 'plain text'.codeUnits));
      expect(r.problem, FileProblem.corrupt);
    });

    test('a zip named .docx that is not a Word document is damaged', () async {
      final zip = ZipEncoder().encode(Archive()..addFile(ArchiveFile('hello.txt', 5, 'hello'.codeUnits)))!;
      final r = await FileInspector.inspect(write('x.docx', zip));
      expect(r.problem, FileProblem.corrupt);
    });

    test('a PDF with an /Encrypt entry is reported as password-protected', () async {
      final locked = write('locked.pdf', '%PDF-1.7\n1 0 obj<<>>endobj\ntrailer<</Encrypt 9 0 R/Root 1 0 R>>\n%%EOF'.codeUnits);
      expect((await FileInspector.inspect(locked)).problem, FileProblem.passwordProtected);
    });

    test('a .docx or .xlsx in the old binary container is what a password-protected one looks like', () async {
      final ole = Uint8List.fromList([0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1, ...List.filled(600, 0)]);
      expect((await FileInspector.inspect(write('locked.docx', ole))).problem, FileProblem.passwordProtected);
      expect((await FileInspector.inspect(write('locked.xlsx', ole))).problem, FileProblem.passwordProtected);
      // And the same bytes as a plain .doc / .xls are an old-format file, which opens (as a fallback screen).
      expect((await FileInspector.inspect(write('old.doc', ole))).kind, IncomingKind.doc);
      expect((await FileInspector.inspect(write('old.xls', ole))).kind, IncomingKind.xls);
    });

    test('a binary file named .csv is damaged', () async {
      final r = await FileInspector.inspect(write('bin.csv', [1, 2, 0, 3, 0, 0, 9]));
      expect(r.problem, FileProblem.corrupt);
    });

    test('a file over the size limit is refused for viewing (and still can be shared or saved)', () async {
      final big = File(p.join(dir.path, 'big.csv'));
      final raf = big.openSync(mode: FileMode.write);
      raf.setPositionSync(FileInspector.maxViewBytes + 10);
      raf.writeByteSync(65);
      raf.closeSync();
      final r = await FileInspector.inspect(big);
      expect(r.problem, FileProblem.tooLarge);
    });
  });

  group('showing the content', () {
    test('CSV: the exported table comes back with its columns and rows', () async {
      final doc = await DocumentLoader.loadCsv(write('r.csv', CsvWriter.build(table())).path);
      final sheet = doc.sheets.single;
      expect(sheet.rows.first, ['S/N', 'Registration No.', 'Exam', 'Attendance', 'Assignment', 'Test', 'Total', 'Grade']);
      expect(sheet.rows[1].sublist(0, 3), ['1', 'FWM/24U/0538', '9.5']);
      expect(sheet.totalRows, 5);
      expect(sheet.truncated, isFalse);
    });

    test('CSV: semicolons and a Latin-1 file are read too', () async {
      final latin = write('a.csv', [...'Reg;Name\nFWM/24U/0538;Ibrahim M'.codeUnits, 0xE9]);
      final doc = await DocumentLoader.loadCsv(latin.path);
      expect(doc.sheets.single.rows.first, ['Reg', 'Name']);
      expect(doc.sheets.single.rows[1][0], 'FWM/24U/0538');
    });

    test('CSV: a huge table is cut to a screenful and says so', () async {
      final lines = StringBuffer('Reg,Name\n');
      for (var i = 0; i < DocumentLoader.maxRows + 500; i++) {
        lines.writeln('FWM/24U/${i.toString().padLeft(4, '0')},Student $i');
      }
      final doc = await DocumentLoader.loadCsv(write('big.csv', lines.toString().codeUnits).path);
      final sheet = doc.sheets.single;
      expect(sheet.rows.length, DocumentLoader.maxRows);
      expect(sheet.totalRows, DocumentLoader.maxRows + 501);
      expect(sheet.truncated, isTrue);
    });

    test('Excel: the exported workbook comes back with its cell values', () async {
      final doc = await DocumentLoader.loadXlsx(write('r.xlsx', XlsxWriter.build(table())).path);
      final rows = doc.sheets.first.rows;
      expect(rows.any((r) => r.contains('FWM/24U/0538')), isTrue);
      expect(rows.any((r) => r.contains('Registration No.')), isTrue);
      expect(rows.expand((r) => r), contains('84.5'));
    });

    test('Excel: a file that is not a workbook is reported as damaged', () async {
      final zip = ZipEncoder().encode(Archive()..addFile(ArchiveFile('hello.txt', 5, 'hello'.codeUnits)))!;
      await expectLater(
        DocumentLoader.loadXlsx(write('bad.xlsx', zip).path),
        throwsA(isA<DocumentReadException>().having((e) => e.problem, 'problem', FileProblem.corrupt)),
      );
    });

    test('Word: the exported document comes back as its title, header lines and table', () async {
      final doc = await DocumentLoader.loadDocx(write('r.docx', DocxWriter.build(table())).path);
      final texts = doc.blocks.whereType<DocParagraph>().map((b) => b.text).toList();
      expect(texts.any((t) => t.contains('Modibbo Adama University')), isTrue);
      final tableBlock = doc.blocks.whereType<DocTable>().single;
      expect(tableBlock.rows.first, containsAll(['S/N', 'Registration No.', 'Exam']));
      expect(tableBlock.rows.any((r) => r.contains('FWM/24U/0538')), isTrue);
      expect(tableBlock.rows.any((r) => r.contains('84.5')), isTrue);
    });

    test('Word: bold, italic and headings are kept, empty paragraphs are dropped', () async {
      const xml = '<?xml version="1.0"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>'
          '<w:p><w:pPr><w:pStyle w:val="Heading1"/></w:pPr><w:r><w:t>Results</w:t></w:r></w:p>'
          '<w:p></w:p>'
          '<w:p><w:r><w:rPr><w:b/></w:rPr><w:t>Bold </w:t></w:r><w:r><w:rPr><w:i/></w:rPr><w:t>italic</w:t></w:r>'
          '<w:r><w:rPr><w:b w:val="0"/></w:rPr><w:t> plain</w:t></w:r></w:p>'
          '</w:body></w:document>';
      final zip = ZipEncoder().encode(Archive()..addFile(ArchiveFile('word/document.xml', xml.length, xml.codeUnits)))!;
      final doc = await DocumentLoader.loadDocx(write('h.docx', zip).path);
      final blocks = doc.blocks.cast<DocParagraph>();
      expect(blocks, hasLength(2));
      expect(blocks[0].heading, 1);
      expect(blocks[1].runs.map((r) => (r.text, r.bold, r.italic)),
          [('Bold ', true, false), ('italic', false, true), (' plain', false, false)]);
    });

    test('Word: a damaged document is reported, not shown empty', () async {
      final zip = ZipEncoder().encode(Archive()..addFile(ArchiveFile('word/document.xml', 9, '<w:broken'.codeUnits)))!;
      await expectLater(
        DocumentLoader.loadDocx(write('bad.docx', zip).path),
        throwsA(isA<DocumentReadException>()),
      );
    });
  });
}
