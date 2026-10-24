import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

/// A table of text cells read from a CSV file, an Excel sheet or pasted text.
/// Every cell is a trimmed string; blank cells are empty strings.
class RawTable {
  RawTable(List<List<String>> rows) : rows = _squared(rows);

  final List<List<String>> rows;

  bool get isEmpty => rows.isEmpty;
  int get rowCount => rows.length;
  int get columnCount => rows.isEmpty ? 0 : rows.first.length;

  String cell(int row, int col) {
    if (row < 0 || row >= rows.length) return '';
    final r = rows[row];
    return col >= 0 && col < r.length ? r[col] : '';
  }

  /// Drops rows that are entirely blank and pads the rest to equal length.
  static List<List<String>> _squared(List<List<String>> input) {
    final kept = input
        .map((r) => r.map((c) => c.trim()).toList())
        .where((r) => r.any((c) => c.isNotEmpty))
        .toList();
    final width = kept.fold<int>(0, (m, r) => r.length > m ? r.length : m);
    return [
      for (final r in kept) [...r, ...List.filled(width - r.length, '')],
    ];
  }
}

class TableReader {
  const TableReader._();

  /// CSV with the delimiter worked out from the text: comma, semicolon or tab.
  static RawTable fromCsv(String text) => fromDelimited(text);

  /// Pasted text from a spreadsheet (tabs), a CSV (commas) or a plain list
  /// with one number per line.
  static RawTable fromPaste(String text) => fromDelimited(text);

  static RawTable fromDelimited(String text) {
    var s = text;
    if (s.startsWith('﻿')) s = s.substring(1);
    s = s.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (s.trim().isEmpty) return RawTable(const []);

    final delimiter = _detectDelimiter(s);
    final rows = CsvToListConverter(
      fieldDelimiter: delimiter,
      eol: '\n',
      shouldParseNumbers: false,
      allowInvalid: true,
    ).convert(s);

    return RawTable([
      for (final r in rows) [for (final c in r) c == null ? '' : c.toString()],
    ]);
  }

  /// Counts delimiters outside quotes on the first few lines and picks the one
  /// that is consistent across lines.
  static String _detectDelimiter(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).take(8).toList();
    String best = ',';
    var bestScore = 0;
    for (final d in ['\t', ',', ';']) {
      final counts = lines.map((l) => _countOutsideQuotes(l, d)).toList();
      if (counts.isEmpty || counts.first == 0) continue;
      final consistent = counts.where((c) => c == counts.first).length;
      final score = consistent * 100 + counts.first;
      if (score > bestScore) {
        bestScore = score;
        best = d;
      }
    }
    return best;
  }

  static int _countOutsideQuotes(String line, String d) {
    var inQuotes = false;
    var n = 0;
    for (final ch in line.split('')) {
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == d && !inQuotes) {
        n++;
      }
    }
    return n;
  }

  /// The first sheet that has any data, or the sheet called [sheet].
  static RawTable fromExcel(Uint8List bytes, {String? sheet}) {
    final book = Excel.decodeBytes(bytes);
    for (final entry in book.tables.entries) {
      if (sheet != null && entry.key != sheet) continue;
      final rows = <List<String>>[
        for (final row in entry.value.rows) [for (final c in row) excelText(c?.value)],
      ];
      final table = RawTable(rows);
      if (!table.isEmpty || sheet != null) return table;
    }
    return RawTable(const []);
  }

  /// A cell's value as the text a person would read.
  static String excelText(CellValue? v) {
    if (v == null) return '';
    if (v is DoubleCellValue) {
      final d = v.value;
      return d == d.roundToDouble() ? d.toInt().toString() : d.toString();
    }
    return v.toString();
  }

  /// Chooses the reader from the file name. Excel files are binary; anything
  /// else is read as UTF-8 text (with a Latin-1 fallback for old exports).
  static RawTable fromFile(String name, Uint8List bytes) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.xlsx') || lower.endsWith('.xlsm')) {
      return fromExcel(bytes);
    }
    if (lower.endsWith('.xls')) {
      throw const FormatException(
          'Old .xls files are not supported. Save the sheet as .xlsx or CSV and try again.');
    }
    String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      text = latin1.decode(bytes);
    }
    return fromCsv(text);
  }
}
