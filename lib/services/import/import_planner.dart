import '../../data/repositories/student_repository.dart';
import '../../domain/models.dart';
import '../../domain/reg_no.dart';
import '../../domain/scheme.dart';
import '../../domain/scoring.dart';
import '../../data/repositories/score_repository.dart';
import 'table_reader.dart';

/// Column guesses for the mapping screen. The user can change every one.
class ColumnGuess {
  const ColumnGuess({
    required this.hasHeader,
    this.regNoColumn,
    this.nameColumn,
    this.partColumns = const {},
  });

  final bool hasHeader;
  final int? regNoColumn;
  final int? nameColumn;

  /// partId -> column index.
  final Map<String, int> partColumns;
}

class ImportPlanner {
  const ImportPlanner._();

  static final RegExp _regHeader =
      RegExp(r'reg|matric|exam(ination)?\s*(no|num)|candidate|student\s*(no|id)', caseSensitive: false);
  static final RegExp _nameHeader = RegExp(r'name', caseSensitive: false);

  static bool _looksLikeRegNo(String s) => RegNo.normalise(s).isValid;

  /// Guesses the header row, the registration number column and the name
  /// column. When [parts] is given, also matches columns to parts by name.
  static ColumnGuess guess(RawTable table, {List<PartSpec> parts = const []}) {
    if (table.isEmpty) return const ColumnGuess(hasHeader: false);

    // Registration number column: the one whose cells most often match.
    int? regCol;
    var bestHits = 0;
    final sample = table.rows.take(40).toList();
    for (var c = 0; c < table.columnCount; c++) {
      final hits = sample.where((r) => _looksLikeRegNo(r[c])).length;
      if (hits > bestHits) {
        bestHits = hits;
        regCol = c;
      }
    }

    // A header row is a first row whose registration column does not match.
    var hasHeader = false;
    if (regCol != null) {
      hasHeader = !_looksLikeRegNo(table.cell(0, regCol));
    } else {
      hasHeader = table.rows.first.any((c) => _regHeader.hasMatch(c) || _nameHeader.hasMatch(c));
    }

    final header = hasHeader ? table.rows.first : const <String>[];
    if (regCol == null && hasHeader) {
      final i = header.indexWhere(_regHeader.hasMatch);
      if (i >= 0) regCol = i;
    }

    int? nameCol;
    if (hasHeader) {
      final i = header.indexWhere(_nameHeader.hasMatch);
      if (i >= 0 && i != regCol) nameCol = i;
    } else if (regCol != null) {
      // No header: a text column next to the numbers is probably the name.
      for (var c = 0; c < table.columnCount; c++) {
        if (c == regCol) continue;
        final texts = sample.where((r) => RegExp(r'^[A-Za-z][A-Za-z .,\-]+$').hasMatch(r[c])).length;
        if (texts >= (sample.length / 2).ceil()) {
          nameCol = c;
          break;
        }
      }
    }

    final partCols = <String, int>{};
    if (hasHeader) {
      for (final p in parts) {
        final key = p.name.trim().toLowerCase();
        final i = header.indexWhere((h) {
          final t = h.trim().toLowerCase();
          return t == key || (t.isNotEmpty && (t.startsWith(key) || key.startsWith(t)));
        });
        if (i >= 0 && i != regCol && !partCols.containsValue(i)) partCols[p.id] = i;
      }
    }

    return ColumnGuess(
      hasHeader: hasHeader,
      regNoColumn: regCol,
      nameColumn: nameCol,
      partColumns: partCols,
    );
  }

  /// Class list rows, in file order.
  static List<NewStudent> classList(
    RawTable table, {
    required int regNoColumn,
    int? nameColumn,
    required bool hasHeader,
  }) {
    final out = <NewStudent>[];
    for (var r = hasHeader ? 1 : 0; r < table.rowCount; r++) {
      final reg = table.cell(r, regNoColumn);
      final name = nameColumn == null ? null : table.cell(r, nameColumn);
      out.add(NewStudent(reg, name: name));
    }
    return out;
  }

  /// Plans an import of part scores (Attendance, Assignment, Test, ...) from
  /// a table. Nothing is written here; the plan is shown first.
  static ScoreImportPlan scores(
    RawTable table, {
    required int regNoColumn,
    required Map<String, int> partColumns,
    required bool hasHeader,
    required GradingScheme scheme,
    required List<Student> students,
  }) {
    final byKey = {for (final s in students) RegNo.key(s.regNo): s};
    final classList = byKey.keys.toList();

    final writes = <ScoreWrite>[];
    final unmatched = <UnmatchedRow>[];
    final unreadable = <UnreadableCell>[];
    final matchedStudents = <String>{};
    var blankRows = 0;
    var cellsRead = 0;
    var absent = 0;
    final seenKeys = <String>{};
    var repeatedRows = 0;

    for (var r = hasHeader ? 1 : 0; r < table.rowCount; r++) {
      final rawReg = table.cell(r, regNoColumn);
      final reg = RegNo.normalise(rawReg);
      if (reg.canonical.isEmpty) {
        blankRows++;
        continue;
      }
      if (!seenKeys.add(reg.canonical)) {
        repeatedRows++;
        continue;
      }

      final values = <String, PartValue>{};
      for (final entry in partColumns.entries) {
        final part = scheme.partById(entry.key);
        if (part == null) continue;
        final text = table.cell(r, entry.value);
        if (text.isEmpty) continue;
        if (MarkParser.isAbsentText(text)) {
          values[part.id] = const PartValue.absent();
          continue;
        }
        final v = MarkParser.parse(text);
        if (v == null) {
          unreadable.add(UnreadableCell(
              row: r + 1, regNo: reg.canonical, partName: part.name, text: text));
          continue;
        }
        values[part.id] = PartValue(value: v);
      }

      final student = byKey[reg.canonical];
      if (student == null) {
        unmatched.add(UnmatchedRow(
          rawRegNo: rawReg,
          regNo: reg.canonical,
          suggestions: RegNo.nearest(reg.canonical, classList),
          values: values,
        ));
        continue;
      }

      matchedStudents.add(student.id);
      for (final e in values.entries) {
        cellsRead++;
        if (e.value.isAbsent) absent++;
        writes.add(ScoreWrite(
          studentId: student.id,
          partId: e.key,
          value: e.value.value,
          status: e.value.isAbsent ? ScoreStatus.absent : ScoreStatus.entered,
          source: 'imported',
        ));
      }
    }

    return ScoreImportPlan(
      writes: writes,
      matchedStudents: matchedStudents.length,
      cellsRead: cellsRead,
      absentCells: absent,
      blankRows: blankRows,
      repeatedRows: repeatedRows,
      unmatched: unmatched,
      unreadable: unreadable,
    );
  }
}

class UnmatchedRow {
  const UnmatchedRow({
    required this.rawRegNo,
    required this.regNo,
    required this.suggestions,
    required this.values,
  });

  final String rawRegNo;
  final String regNo;

  /// Nearest numbers on the class list, in case it is a typing slip.
  final List<RegNoSuggestion> suggestions;
  final Map<String, PartValue> values;
}

class UnreadableCell {
  const UnreadableCell({
    required this.row,
    required this.regNo,
    required this.partName,
    required this.text,
  });

  /// 1-based row number in the file.
  final int row;
  final String regNo;
  final String partName;
  final String text;
}

class ScoreImportPlan {
  const ScoreImportPlan({
    required this.writes,
    required this.matchedStudents,
    required this.cellsRead,
    required this.absentCells,
    required this.blankRows,
    required this.repeatedRows,
    required this.unmatched,
    required this.unreadable,
  });

  final List<ScoreWrite> writes;
  final int matchedStudents;
  final int cellsRead;
  final int absentCells;
  final int blankRows;

  /// Rows whose registration number already appeared higher in the file.
  final int repeatedRows;

  /// Rows whose number is not on the class list.
  final List<UnmatchedRow> unmatched;

  /// Cells that could not be read as a mark.
  final List<UnreadableCell> unreadable;
}
