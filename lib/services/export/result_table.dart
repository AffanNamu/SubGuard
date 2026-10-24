import '../../data/repositories/score_repository.dart';
import '../../domain/models.dart';
import '../../domain/reg_no.dart';
import '../../domain/scheme.dart';
import '../../domain/scoring.dart';

enum SerialOrder {
  entryOrder('Order entered'),
  byRegNo('Sorted by exam number');

  const SerialOrder(this.label);
  final String label;
}

enum ExportPreset {
  examSheet(
    'Exam sheet',
    'Exam filled in. Everything else left blank.',
  ),
  continuousAssessment(
    'Continuous assessment sheet',
    'Attendance, Assignment, Test and the other parts filled in. Exam and Total blank.',
  ),
  fullResult(
    'Full result',
    'Every part filled in, with Total and Grade worked out.',
  );

  const ExportPreset(this.label, this.description);
  final String label;
  final String description;
}

/// The optional header printed above the table, set once in Settings.
class ExportHeader {
  const ExportHeader({
    this.university = '',
    this.faculty = '',
    this.department = '',
    this.session = '',
    this.examiner = '',
  });

  final String university;
  final String faculty;
  final String department;
  final String session;
  final String examiner;

  bool get isEmpty => lines().isEmpty;

  /// Non-empty lines in print order.
  List<String> lines() => [
        if (university.trim().isNotEmpty) university.trim(),
        if (faculty.trim().isNotEmpty) faculty.trim(),
        if (department.trim().isNotEmpty) department.trim(),
        if (session.trim().isNotEmpty) 'Session: ${session.trim()}',
        if (examiner.trim().isNotEmpty) 'Examiner: ${examiner.trim()}',
      ];
}

/// What the column chooser decides. Every column is either filled or left
/// blank; Grade can also be left out altogether. Registration No. is always
/// filled.
class ExportOptions {
  const ExportOptions({
    this.serialOrder = SerialOrder.entryOrder,
    this.partFilled = const {},
    this.totalFilled = true,
    this.includeGrade = true,
    this.includeHeader = true,
  });

  final SerialOrder serialOrder;

  /// Part name (lower case) -> filled. A part that is not listed is filled,
  /// so a part added after the options were chosen is not silently dropped.
  final Map<String, bool> partFilled;
  final bool totalFilled;
  final bool includeGrade;
  final bool includeHeader;

  static String partKey(String name) => name.trim().toLowerCase();

  bool isFilled(PartSpec part) => partFilled[partKey(part.name)] ?? true;

  /// The three presets. Parts are told apart by where their marks come from:
  /// parts filled from scanned booklets are the exam, the rest are
  /// continuous assessment. [schemes] lets one preset cover several courses.
  static ExportOptions preset(
    ExportPreset preset,
    Iterable<GradingScheme> schemes, {
    SerialOrder serialOrder = SerialOrder.entryOrder,
    bool includeHeader = true,
  }) {
    final filled = <String, bool>{};
    for (final scheme in schemes) {
      for (final p in scheme.parts) {
        final bool on;
        switch (preset) {
          case ExportPreset.examSheet:
            on = p.isExamLike;
          case ExportPreset.continuousAssessment:
            on = !p.isExamLike;
          case ExportPreset.fullResult:
            on = true;
        }
        final key = partKey(p.name);
        filled[key] = (filled[key] ?? false) || on;
      }
    }
    return ExportOptions(
      serialOrder: serialOrder,
      partFilled: filled,
      totalFilled: preset == ExportPreset.fullResult,
      includeGrade: preset == ExportPreset.fullResult,
      includeHeader: includeHeader,
    );
  }

  ExportOptions copyWith({
    SerialOrder? serialOrder,
    Map<String, bool>? partFilled,
    bool? totalFilled,
    bool? includeGrade,
    bool? includeHeader,
  }) =>
      ExportOptions(
        serialOrder: serialOrder ?? this.serialOrder,
        partFilled: partFilled ?? this.partFilled,
        totalFilled: totalFilled ?? this.totalFilled,
        includeGrade: includeGrade ?? this.includeGrade,
        includeHeader: includeHeader ?? this.includeHeader,
      );
}

enum ExportColumnKind { serial, regNo, part, total, grade }

class ExportColumn {
  const ExportColumn(this.kind, this.title, {this.partId});

  final ExportColumnKind kind;
  final String title;
  final String? partId;
}

/// Column sizing shared by the Word and PDF writers, so a heading such as
/// "Attendance" never breaks in the middle of a word.
class ColumnLayout {
  const ColumnLayout._();

  /// Usable width of an A4 portrait page with 2.54 cm margins, in twips.
  static const int portraitTwips = 9026;

  /// Narrowest width, in twips, at which the column heading still fits.
  static int minTwips(ExportColumn c) {
    switch (c.kind) {
      case ExportColumnKind.serial:
        return 640;
      case ExportColumnKind.regNo:
        return 2250;
      default:
        // About 125 twips per bold 12 pt character, plus cell padding.
        final byTitle = c.title.length * 125 + 170;
        return byTitle < 800 ? 800 : byTitle;
    }
  }

  static bool needsLandscape(List<ExportColumn> columns) =>
      columns.fold<int>(0, (sum, c) => sum + minTwips(c)) > portraitTwips;
}

class ExportCell {
  const ExportCell(this.text, {this.number, this.decimals});

  static const ExportCell blank = ExportCell('');

  final String text;

  /// Set when the cell is a number, so Excel can store it as one.
  final double? number;

  /// Decimals to show for [number]; null means "as written".
  final int? decimals;
}

/// Everything a writer needs. Plain data, so it can cross to a background
/// isolate and be drawn the same way in every format.
class ResultTable {
  const ResultTable({
    required this.title,
    required this.headerLines,
    required this.columns,
    required this.rows,
  });

  /// "(FWM) AGR 114"
  final String title;
  final List<String> headerLines;
  final List<ExportColumn> columns;
  final List<List<ExportCell>> rows;
}

class ResultTableBuilder {
  const ResultTableBuilder._();

  /// Shown for a student marked absent in a part.
  static const String absentText = 'ABS';

  static ResultTable build({
    required Course course,
    required List<Student> students,
    required ScoreMap scores,
    required ExportOptions options,
    ExportHeader header = const ExportHeader(),
  }) {
    final scheme = course.scheme;

    final columns = <ExportColumn>[
      const ExportColumn(ExportColumnKind.serial, 'S/N'),
      const ExportColumn(ExportColumnKind.regNo, 'Registration No.'),
      for (final p in scheme.parts)
        ExportColumn(ExportColumnKind.part, p.name, partId: p.id),
      const ExportColumn(ExportColumnKind.total, 'Total'),
      if (options.includeGrade) const ExportColumn(ExportColumnKind.grade, 'Grade'),
    ];

    final ordered = [...students];
    if (options.serialOrder == SerialOrder.byRegNo) {
      ordered.sort((a, b) =>
          RegNo.key(a.regNo).compareTo(RegNo.key(b.regNo)));
    } else {
      ordered.sort((a, b) => a.position.compareTo(b.position));
    }

    // The total and grade only count parts that are filled in this export, so
    // what is printed always adds up.
    final shown = scheme.parts.where(options.isFilled).toList();
    final shownScheme = scheme.copyWith(parts: shown);
    final everyPartShown = shown.length == scheme.parts.length;

    final rows = <List<ExportCell>>[];
    for (var i = 0; i < ordered.length; i++) {
      final s = ordered[i];
      final byPart = scores[s.id] ?? const <String, PartValue>{};
      final result = ScoreCalculator.compute(shownScheme, byPart);

      rows.add([
        ExportCell('${i + 1}', number: (i + 1).toDouble(), decimals: 0),
        ExportCell(s.regNo),
        for (final p in scheme.parts) _partCell(p, options.isFilled(p), byPart[p.id]),
        if (options.totalFilled && result.total != null)
          ExportCell(ScoreCalculator.formatTotal(result.total!), number: result.total)
        else
          ExportCell.blank,
        if (options.includeGrade)
          ExportCell(options.totalFilled && everyPartShown && result.grade != null
              ? result.grade!.letter
              : ''),
      ]);
    }

    return ResultTable(
      title: course.title,
      headerLines: options.includeHeader ? header.lines() : const [],
      columns: columns,
      rows: rows,
    );
  }

  static ExportCell _partCell(PartSpec part, bool filled, PartValue? v) {
    if (!filled || v == null) return ExportCell.blank;
    if (v.isAbsent) return const ExportCell(absentText);
    if (!v.hasValue) return ExportCell.blank;
    final decimals =
        part.isExamLike ? null : ScoreCalculator.decimalsForStep(part.step);
    return ExportCell(
      ScoreCalculator.formatPartMark(part, v.value!),
      number: v.value,
      decimals: decimals,
    );
  }
}
