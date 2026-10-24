import '../../domain/recognition.dart';
import '../../domain/scheme.dart';
import '../../domain/scoring.dart';

enum FindingSeverity { info, warning, danger }

/// Something the examiner should look at. A finding is only ever a message: a
/// validator never changes a value, because a mark an examiner wrote is the
/// record and a rule can be wrong (or the arithmetic on the cover can be).
class ValidationFinding {
  const ValidationFinding(this.code, this.severity, this.message, {this.fields = const []});

  /// A stable name, for tests and for grouping ("total_mismatch").
  final String code;
  final FindingSeverity severity;
  final String message;

  /// The fields the finding is about (their [ExtractedField.key]).
  final List<String> fields;

  Map<String, Object?> toJson() => {'code': code, 'severity': severity.name, 'message': message, 'fields': fields};

  static ValidationFinding fromJson(Map<String, dynamic> j) => ValidationFinding(
        j['code'] as String,
        FindingSeverity.values.firstWhere((s) => s.name == j['severity'], orElse: () => FindingSeverity.warning),
        j['message'] as String,
        fields: [for (final f in (j['fields'] as List? ?? const [])) f as String],
      );
}

/// What was read or typed for the marks of one booklet.
class ExamSnapshot {
  const ExamSnapshot({this.marks = const {}, this.writtenTotal, this.answeredLine});

  /// Question number to mark; one entry per question.
  final Map<int, double> marks;

  /// The total the examiner wrote on the cover, when there is one.
  final double? writtenTotal;

  /// The handwritten "questions answered" line, as read ("4, 5, 1, 2").
  final String? answeredLine;
}

/// Checks marks against the examination rules. An interface so a department's
/// own rules can replace the course-scheme rules.
abstract interface class ExaminationValidator {
  List<ValidationFinding> validate(ExamSnapshot exam);
}

/// The rules in a course's grading scheme: question maxima, the mark step, the
/// part's maximum and how many questions count.
///
/// Where the examiner's written total differs from the sum of the marks, both
/// numbers are kept and the difference is reported; neither is changed to
/// make them agree.
class SchemeExaminationValidator implements ExaminationValidator {
  const SchemeExaminationValidator(this.scheme);

  final GradingScheme scheme;

  QuestionSpec? _spec(int qNo) {
    for (final q in scheme.questions) {
      if (q.qNo == qNo) return q;
    }
    return null;
  }

  @override
  List<ValidationFinding> validate(ExamSnapshot exam) {
    final out = <ValidationFinding>[];
    final part = scheme.examPart;
    for (final e in exam.marks.entries) {
      final max = _spec(e.key)?.max;
      if (max != null && e.value > max + 1e-9) {
        out.add(ValidationFinding(
          'mark_above_max',
          FindingSeverity.danger,
          'Q${e.key}: ${formatNumber(e.value)} is above the question maximum of ${formatNumber(max)}.',
          fields: ['mark_q${e.key}'],
        ));
      }
      if (part != null && !ScoreCalculator.isOnStep(e.value, part.step)) {
        out.add(ValidationFinding(
          'mark_off_step',
          FindingSeverity.warning,
          'Q${e.key}: ${formatNumber(e.value)} is not a multiple of ${formatNumber(part.step)}.',
          fields: ['mark_q${e.key}'],
        ));
      }
    }

    final score = exam.marks.isEmpty ? null : ScoreCalculator.examScoreFromQuestions(scheme, exam.marks);
    if (part != null && score != null && score > part.max + 1e-9) {
      out.add(ValidationFinding(
        'exam_above_max',
        FindingSeverity.danger,
        'The exam score ${formatNumber(score)} is above the ${part.name} maximum of ${formatNumber(part.max)}.',
      ));
    }
    if (exam.writtenTotal != null && score != null && (exam.writtenTotal! - score).abs() > 1e-6) {
      out.add(ValidationFinding(
        'total_mismatch',
        FindingSeverity.warning,
        'The examiner wrote ${formatNumber(exam.writtenTotal!)}, but the marks add up to ${formatNumber(score)} '
        'under "${scheme.countRule.label}". Check the marks, or the counting rule in Course setup.',
        fields: const ['total_written'],
      ));
    }

    final answered = exam.answeredLine;
    if (answered != null && exam.marks.isNotEmpty) {
      final listed = RegExp(r'\d+').allMatches(answered).map((m) => int.parse(m.group(0)!)).toSet();
      if (listed.isNotEmpty && !listed.containsAll(exam.marks.keys)) {
        final nos = exam.marks.keys.toList()..sort();
        out.add(ValidationFinding(
          'answered_mismatch',
          FindingSeverity.warning,
          'The "questions answered" line reads "$answered", but you entered marks for ${nos.map((k) => 'Q$k').join(', ')}.',
          fields: const ['answered'],
        ));
      }
    }
    return out;
  }
}

/// Checks that apply only to what a machine read, where a row can be missing,
/// unreadable or assigned to a question twice.
class ReadingChecks {
  const ReadingChecks._();

  /// Turns the mark rows the pipeline read into a snapshot a validator can check,
  /// plus the problems that stop a row being used at all.
  ///
  /// A row joins the snapshot only when its question number and its mark both
  /// read cleanly (no "?"). When any row cannot be used the sum is incomplete,
  /// so [complete] is false and totals must not be compared.
  static ({ExamSnapshot snapshot, List<ValidationFinding> findings, bool complete}) snapshotOf(
    List<ExtractedField> fields, {
    String? answeredLine,
  }) {
    final findings = <ValidationFinding>[];
    final marks = <int, double>{};
    final seen = <int, String>{};
    var complete = true;
    double? written;

    final rows = [for (final f in fields) if (f.kind == FieldKind.mark && f.key.startsWith('mark_row_')) f];
    for (final row in rows) {
      final text = row.value;
      if (row.state == FieldState.unreadable || text == null) {
        complete = false;
        continue;
      }
      final mark = double.tryParse(text);
      final qText = row.question;
      final q = qText == null ? null : int.tryParse(qText);
      if (mark == null || text.contains('?')) {
        complete = false;
        findings.add(ValidationFinding('mark_unclear', FindingSeverity.warning, 'The mark in ${row.key.replaceFirst('mark_row_', 'row ')} could not be read clearly: "$text".', fields: [row.key]));
        continue;
      }
      if (q == null) {
        complete = false;
        findings.add(ValidationFinding('question_unclear', FindingSeverity.warning, 'The question number beside mark $text in ${row.key.replaceFirst('mark_row_', 'row ')} could not be read clearly.', fields: [row.key]));
        continue;
      }
      final earlier = seen[q];
      if (earlier != null) {
        complete = false;
        findings.add(ValidationFinding('duplicate_question', FindingSeverity.warning, 'Q$q appears in two rows, so neither is used until you check them.', fields: [earlier, row.key]));
        marks.remove(q);
        continue;
      }
      seen[q] = row.key;
      marks[q] = mark;
    }

    for (final f in fields) {
      if (f.key == 'total_written' && f.value != null) written = double.tryParse(f.value!);
    }
    return (snapshot: ExamSnapshot(marks: marks, writtenTotal: written, answeredLine: answeredLine), findings: findings, complete: complete);
  }

  /// All the findings for a machine reading: its own problems, then the
  /// scheme's rules over the marks that were usable. The written total is
  /// compared only when every row was usable.
  static List<ValidationFinding> validate(
    List<ExtractedField> fields,
    ExaminationValidator validator, {
    String? answeredLine,
  }) {
    final s = snapshotOf(fields, answeredLine: answeredLine);
    final usable = s.complete ? s.snapshot : ExamSnapshot(marks: s.snapshot.marks, answeredLine: null);
    return [...s.findings, ...validator.validate(usable)];
  }
}
