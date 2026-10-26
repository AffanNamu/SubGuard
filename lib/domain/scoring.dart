import 'exam_tally.dart';
import 'scheme.dart';

/// Floating-point sums of halves and quarters are exact, but scaled marks
/// (20 -> 10) are not. Round to six places so 4 + 4.5 never prints 8.499999.
double roundMark(double v) => (v * 1e6).round() / 1e6;

enum ScoreStatus {
  entered('entered'),
  absent('absent'),
  missing('missing');

  const ScoreStatus(this.dbValue);
  final String dbValue;

  static ScoreStatus fromDb(String? value) => ScoreStatus.values.firstWhere(
        (s) => s.dbValue == value,
        orElse: () => ScoreStatus.missing,
      );
}

/// One student's value for one part.
class PartValue {
  const PartValue({this.value, this.status = ScoreStatus.entered});

  const PartValue.absent() : this(status: ScoreStatus.absent);

  final double? value;
  final ScoreStatus status;

  bool get isAbsent => status == ScoreStatus.absent;
  bool get hasValue => status == ScoreStatus.entered && value != null;

  /// Something has been decided for this part: a mark, or absent.
  bool get isFilled => hasValue || isAbsent;
}

class ScoreResult {
  const ScoreResult({
    required this.total,
    required this.complete,
    required this.grade,
  });

  /// Sum of the scaled contributions of every filled part. Null when nothing
  /// has been filled yet. Calculated, never stored.
  final double? total;

  /// Every part has a mark or is marked absent.
  final bool complete;

  /// Null until the result is complete, or when the total is off the scale.
  final GradeBand? grade;
}

class ScoreCalculator {
  const ScoreCalculator._();

  static ScoreResult compute(
    GradingScheme scheme,
    Map<String, PartValue> byPartId,
  ) {
    var sum = 0.0;
    var anyFilled = false;
    var complete = scheme.parts.isNotEmpty;

    for (final part in scheme.parts) {
      final entry = byPartId[part.id];
      if (entry == null || !entry.isFilled) {
        complete = false;
        continue;
      }
      anyFilled = true;
      if (entry.hasValue) sum += part.contribution(entry.value!);
    }

    final total = anyFilled ? roundMark(sum) : null;
    final grade =
        (complete && total != null) ? gradeFor(scheme.bands, total) : null;
    return ScoreResult(total: total, complete: complete, grade: grade);
  }

  /// Picks the grade for [total].
  ///
  /// Marks can have halves, so a total of 69.5 falls between "60-69" and
  /// "70-100". A total belongs to the highest band whose minimum it reaches;
  /// only a total above the top band's maximum has no grade.
  static GradeBand? gradeFor(List<GradeBand> bands, double total) {
    if (bands.isEmpty) return null;
    final sorted = [...bands]..sort((a, b) => b.minScore.compareTo(a.minScore));
    if (total > sorted.first.maxScore + 1e-9) return null;
    for (final band in sorted) {
      if (total + 1e-9 >= band.minScore) return band;
    }
    return null;
  }

  /// Exam score from per-question marks under the course's counting rule. [marks]
  /// holds only the questions the examiner marked. See [ExamTally] for the rules;
  /// this is its calculated score, or 0 when nothing was marked.
  static double examScoreFromQuestions(
    GradingScheme scheme,
    Map<int, double> marks,
  ) =>
      ExamTally.compute(scheme, [for (final e in marks.entries) TallyMark(e.key, e.value)]).calculated ?? 0;

  /// Decimals a step needs: 1 -> 0, 0.5 -> 1, 0.25 -> 2.
  static int decimalsForStep(double step) {
    for (var d = 0; d <= 3; d++) {
      final scaled = step * _pow10(d);
      if ((scaled - scaled.round()).abs() < 1e-9) return d;
    }
    return 3;
  }

  static int _pow10(int d) {
    var r = 1;
    for (var i = 0; i < d; i++) {
      r *= 10;
    }
    return r;
  }

  static bool isOnStep(double value, double step) {
    if (step <= 0) return true;
    final n = value / step;
    return (n - n.round()).abs() < 1e-6;
  }

  /// Display for a part's mark. Parts filled from scanned booklets are shown
  /// as the examiner wrote them (9.5, 10); the others show as many decimals
  /// as the part's step needs (Attendance 4, Test 4.5).
  static String formatPartMark(PartSpec part, double value) {
    if (part.isExamLike) return formatNumber(value);
    return value.toStringAsFixed(decimalsForStep(part.step));
  }

  static String formatTotal(double value) => formatNumber(value);
}

/// Reads a typed or imported mark.
///
/// Handles the raised dot examiners use for halves (`5·5`), a decimal comma,
/// and stray spaces. After the dot only the part's step decides what is
/// valid; this class only parses.
class MarkParser {
  const MarkParser._();

  static double? parse(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    if (s.isEmpty) return null;
    s = s
        .replaceAll(RegExp(r'[·•∙⋅]'), '.')
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'\s+'), '');
    if (!RegExp(r'^\d+(\.\d+)?$|^\.\d+$').hasMatch(s)) return null;
    return double.tryParse(s);
  }

  static bool isAbsentText(String? raw) {
    if (raw == null) return false;
    final s = raw.trim().toLowerCase();
    return s == 'abs' || s == 'absent' || s == 'a' || s == 'ab';
  }
}
