import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:xml/xml.dart';

import '../import/table_reader.dart';
import 'file_inspector.dart';

/// Thrown when a file that looked fine can not actually be read.
class DocumentReadException implements Exception {
  const DocumentReadException(this.problem);
  final FileProblem problem;

  @override
  String toString() => 'DocumentReadException(${problem.name})';
}

/// One worksheet, or the one table of a CSV, as shown on screen.
class SheetData {
  const SheetData({required this.name, required this.rows, required this.totalRows, required this.totalColumns});

  final String name;

  /// At most [DocumentLoader.maxRows] rows and [DocumentLoader.maxColumns]
  /// columns, so a huge sheet never freezes the screen.
  final List<List<String>> rows;
  final int totalRows;
  final int totalColumns;

  bool get truncated => rows.length < totalRows || (rows.isNotEmpty && rows.first.length < totalColumns);
}

class TableDoc {
  const TableDoc(this.sheets);
  final List<SheetData> sheets;
}

class DocRun {
  const DocRun(this.text, {this.bold = false, this.italic = false});
  final String text;
  final bool bold;
  final bool italic;
}

sealed class DocBlock {
  const DocBlock();
}

class DocParagraph extends DocBlock {
  const DocParagraph(this.runs, {this.heading = 0, this.bullet = false});
  final List<DocRun> runs;

  /// 0 for body text, 1 to 6 for headings.
  final int heading;
  final bool bullet;

  String get text => runs.map((r) => r.text).join();
}

class DocTable extends DocBlock {
  const DocTable(this.rows);
  final List<List<String>> rows;
}

class TextDoc {
  const TextDoc(this.blocks, {this.truncated = false});
  final List<DocBlock> blocks;
  final bool truncated;
}

/// Reads a document into something the viewer can draw. The reading runs in a
/// separate isolate, so a large file never freezes the interface.
class DocumentLoader {
  const DocumentLoader._();

  static const int maxRows = 5000;
  static const int maxColumns = 60;
  static const int maxBlocks = 5000;

  /// One whole table (every row, not just the part shown), for importing.
  /// [sheet] picks a worksheet of an Excel file; without it the first with data.
  static Future<RawTable> loadTable(String path, {required bool excel, String? sheet}) => Isolate.run(() {
        final bytes = File(path).readAsBytesSync();
        if (excel) return TableReader.fromExcel(Uint8List.fromList(bytes), sheet: sheet);
        String text;
        try {
          text = utf8.decode(bytes);
        } on FormatException {
          text = latin1.decode(bytes);
        }
        return TableReader.fromDelimited(text);
      });

  static Future<TableDoc> loadCsv(String path) => Isolate.run(() => _csv(path));
  static Future<TableDoc> loadXlsx(String path) => Isolate.run(() => _xlsx(path));
  static Future<TextDoc> loadDocx(String path) => Isolate.run(() => _docx(path));

  // ---- CSV ----

  static TableDoc _csv(String path) {
    final bytes = File(path).readAsBytesSync();
    String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      text = latin1.decode(bytes);
    }
    final table = TableReader.fromDelimited(text);
    if (table.isEmpty) throw const DocumentReadException(FileProblem.empty);
    return TableDoc([_sheet('CSV', table.rows)]);
  }

  // ---- Excel ----

  static TableDoc _xlsx(String path) {
    final Excel book;
    try {
      book = Excel.decodeBytes(File(path).readAsBytesSync());
    } catch (_) {
      throw const DocumentReadException(FileProblem.corrupt);
    }
    final sheets = <SheetData>[];
    for (final entry in book.tables.entries) {
      final rows = <List<String>>[
        for (final row in entry.value.rows) [for (final c in row) TableReader.excelText(c?.value)],
      ];
      final table = RawTable(rows);
      sheets.add(_sheet(entry.key, table.rows));
    }
    if (sheets.every((s) => s.rows.isEmpty)) throw const DocumentReadException(FileProblem.empty);
    return TableDoc(sheets);
  }

  static SheetData _sheet(String name, List<List<String>> all) {
    final cols = all.isEmpty ? 0 : all.first.length;
    final shown = [
      for (final r in all.take(maxRows)) r.length > maxColumns ? r.sublist(0, maxColumns) : r,
    ];
    return SheetData(name: name, rows: shown, totalRows: all.length, totalColumns: cols);
  }

  // ---- Word ----

  static TextDoc _docx(String path) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(File(path).readAsBytesSync());
    } catch (_) {
      throw const DocumentReadException(FileProblem.corrupt);
    }
    final part = archive.findFile('word/document.xml');
    if (part == null) throw const DocumentReadException(FileProblem.corrupt);

    final XmlDocument xml;
    try {
      xml = XmlDocument.parse(utf8.decode(part.content as Uint8List, allowMalformed: true));
    } catch (_) {
      throw const DocumentReadException(FileProblem.corrupt);
    }
    final body = xml.findAllElements('w:body').firstOrNull;
    if (body == null) throw const DocumentReadException(FileProblem.corrupt);

    final blocks = <DocBlock>[];
    var truncated = false;
    for (final node in body.childElements) {
      if (blocks.length >= maxBlocks) {
        truncated = true;
        break;
      }
      switch (node.name.qualified) {
        case 'w:p':
          final p = _paragraph(node);
          if (p != null) blocks.add(p);
        case 'w:tbl':
          final rows = <List<String>>[
            for (final tr in node.findElements('w:tr'))
              [
                for (final tc in tr.findElements('w:tc'))
                  tc.findAllElements('w:p').map((p) => _plain(p)).where((t) => t.isNotEmpty).join('\n'),
              ],
          ];
          if (rows.isNotEmpty) blocks.add(DocTable(rows));
      }
    }
    if (blocks.isEmpty) throw const DocumentReadException(FileProblem.empty);
    return TextDoc(blocks, truncated: truncated);
  }

  static DocParagraph? _paragraph(XmlElement p) {
    final runs = <DocRun>[];
    for (final r in p.findAllElements('w:r')) {
      final props = r.getElement('w:rPr');
      final bold = _on(props?.getElement('w:b'));
      final italic = _on(props?.getElement('w:i'));
      final text = StringBuffer();
      for (final c in r.childElements) {
        switch (c.name.qualified) {
          case 'w:t':
            text.write(c.innerText);
          case 'w:tab':
            text.write('\t');
          case 'w:br':
            text.write('\n');
        }
      }
      if (text.isNotEmpty) runs.add(DocRun(text.toString(), bold: bold, italic: italic));
    }
    if (runs.every((r) => r.text.trim().isEmpty)) return null;

    final pPr = p.getElement('w:pPr');
    final style = pPr?.getElement('w:pStyle')?.getAttribute('w:val') ?? '';
    var heading = 0;
    final m = RegExp(r'^[Hh]eading\s*([1-6])$').firstMatch(style);
    if (m != null) {
      heading = int.parse(m.group(1)!);
    } else if (style == 'Title') {
      heading = 1;
    }
    return DocParagraph(runs, heading: heading, bullet: pPr?.getElement('w:numPr') != null);
  }

  /// Word writes `<w:b/>` for bold, and `<w:b w:val="0"/>` for "not bold".
  static bool _on(XmlElement? e) {
    if (e == null) return false;
    final v = e.getAttribute('w:val');
    return v == null || (v != '0' && v != 'false');
  }

  static String _plain(XmlElement p) => p.findAllElements('w:t').map((t) => t.innerText).join();
}
