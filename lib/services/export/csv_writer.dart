import 'dart:convert';

import 'package:csv/csv.dart';

import 'result_table.dart';

class CsvWriter {
  const CsvWriter._();

  /// The table only: a header row, then one row per student. A byte-order mark
  /// is added so Excel opens accents correctly.
  static List<int> build(ResultTable table) {
    final rows = <List<String>>[
      [for (final c in table.columns) c.title],
      for (final r in table.rows) [for (final c in r) c.text],
    ];
    final text = const ListToCsvConverter(eol: '\r\n').convert(rows);
    return [0xEF, 0xBB, 0xBF, ...utf8.encode(text)];
  }
}
