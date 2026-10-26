import 'exam_tally.dart';
import 'mark_rules.dart';
import 'row_suggestions.dart';
import 'scheme.dart';

/// One question-mark record in a review: the question number and the mark are two
/// separate fields, each holding what the examiner has *confirmed* (null until they have),
/// while what the machine suggested stays in [suggestions] and is never copied into
/// either field on its own.
class MarkRecord {
  const MarkRecord({
    required this.key,
    this.qNo,
    this.mark,
    this.suggestions,
    this.dismissed = false,
    this.manual = false,
  });

  /// `mark_row_3` for the third row the machine found, `manual-1` for a question the
  /// examiner added.
  final String key;

  /// The confirmed question number, or null while it is still to be decided.
  final int? qNo;

  /// The confirmed mark, or null while it is still to be decided.
  final double? mark;

  /// What the machine read for this row, or null for a row the examiner added.
  final RowSuggestions? suggestions;

  /// The examiner said this row is not a mark (a stray line, a smudge). It is kept
  /// out of everything.
  final bool dismissed;

  /// Added by the examiner, not found by the machine.
  final bool manual;

  bool get hasQuestion => qNo != null;
  bool get hasMark => mark != null;

  /// Both fields confirmed.
  bool get complete => hasQuestion && hasMark;

  MarkRecord copyWith({
    int? qNo,
    bool clearQuestion = false,
    double? mark,
    bool clearMark = false,
    bool? dismissed,
  }) =>
      MarkRecord(
        key: key,
        qNo: clearQuestion ? null : (qNo ?? this.qNo),
        mark: clearMark ? null : (mark ?? this.mark),
        suggestions: suggestions,
        dismissed: dismissed ?? this.dismissed,
        manual: manual,
      );
}

enum RecordIssue {
  /// The question number is not confirmed.
  questionMissing,

  /// The mark is not confirmed.
  markMissing,

  /// Two records give the same question number.
  duplicateQuestion,

  /// A question on the paper with no record, under a scheme that asks about each.
  unmarkedQuestion,

  /// The mark is above the question's maximum.
  aboveMaximum,

  /// The mark is not on the step marks go up in.
  offStep,

  /// The question is not on the course's question list.
  notOnPaper,
}

class RecordProblem {
  const RecordProblem(this.key, this.issue, this.message, {required this.blocks});

  /// The record it is about, or null when it is about the paper as a whole.
  final String? key;
  final RecordIssue issue;
  final String message;

  /// Confirming the booklet waits until it is dealt with.
  final bool blocks;
}

/// All the question-mark records of one booklet being reviewed.
///
/// A pure value: every change returns a new sheet, and the total, the problems and the
/// marks to store all follow from it, so nothing has to be kept in step by hand.
class MarkSheet {
  const MarkSheet(this.records);

  final List<MarkRecord> records;

  /// Records for the rows the machine found, nothing confirmed.
  static MarkSheet fromRows(Iterable<RowSuggestions> rows) => MarkSheet([
        for (final r in rows) MarkRecord(key: r.markKey, suggestions: r),
      ]);

  MarkRecord? byKey(String key) {
    for (final r in records) {
      if (r.key == key) return r;
    }
    return null;
  }

  MarkSheet _replace(String key, MarkRecord Function(MarkRecord) change) =>
      MarkSheet([for (final r in records) r.key == key ? change(r) : r]);

  MarkSheet setQuestion(String key, int? qNo) => _replace(key, (r) => qNo == null ? r.copyWith(clearQuestion: true) : r.copyWith(qNo: qNo));
  MarkSheet setMark(String key, double? mark) => _replace(key, (r) => mark == null ? r.copyWith(clearMark: true) : r.copyWith(mark: mark));
  MarkSheet dismiss(String key) => _replace(key, (r) => r.copyWith(dismissed: true));
  MarkSheet restore(String key) => _replace(key, (r) => r.copyWith(dismissed: false));

  /// Adds a record the examiner asked for, with the question number if they gave one.
  MarkSheet addManual({int? qNo, double? mark}) {
    var n = 1;
    for (final r in records) {
      final m = RegExp(r'^manual-(\d+)$').firstMatch(r.key);
      if (m != null) n = int.parse(m.group(1)!) >= n ? int.parse(m.group(1)!) + 1 : n;
    }
    return MarkSheet([...records, MarkRecord(key: 'manual-$n', qNo: qNo, mark: mark, manual: true)]);
  }

  /// Takes away a record the examiner added (a machine row is dismissed, not removed).
  MarkSheet remove(String key) => MarkSheet([for (final r in records) if (r.key != key || !r.manual) r]);

  /// The records that count: not dismissed.
  List<MarkRecord> get live => [for (final r in records) if (!r.dismissed) r];

  /// The confirmed marks, one per record with both fields confirmed.
  List<TallyMark> get confirmedMarks => [for (final r in live) if (r.complete) TallyMark(r.qNo!, r.mark!)];

  ExamTally tally(GradingScheme scheme) => ExamTally.compute(scheme, confirmedMarks);

  /// What still needs the examiner, and what is worth a second look.
  List<RecordProblem> problems(GradingScheme scheme, {String Function(MarkRecord r)? label}) {
    String name(MarkRecord r) => label?.call(r) ?? (r.manual ? 'The question you added' : 'Row ${r.suggestions?.index ?? ''}'.trim());
    final out = <RecordProblem>[];
    final counts = <int, int>{};
    for (final r in live) {
      if (r.qNo != null) counts[r.qNo!] = (counts[r.qNo!] ?? 0) + 1;
    }
    for (final r in live) {
      if (!r.hasQuestion) {
        out.add(RecordProblem(r.key, RecordIssue.questionMissing, '${name(r)}: the question number is not confirmed.', blocks: true));
      }
      if (!r.hasMark) {
        out.add(RecordProblem(r.key, RecordIssue.markMissing, '${name(r)}: the mark is not confirmed.', blocks: true));
      }
      if (r.qNo != null && counts[r.qNo!]! > 1) {
        out.add(RecordProblem(r.key, RecordIssue.duplicateQuestion, '${name(r)}: Q${r.qNo} is on more than one row, and only one mark can count.', blocks: true));
      }
      if (r.hasMark) {
        final p = MarkRules.forScheme(scheme, qNo: r.qNo).check(_text(r.mark!));
        if (!p.plausible) {
          out.add(RecordProblem(r.key, p.why == Why.offStep ? RecordIssue.offStep : RecordIssue.aboveMaximum, '${name(r)}: ${p.reason}.', blocks: false));
        }
      }
      if (r.qNo != null && scheme.questions.isNotEmpty && !scheme.questions.any((q) => q.qNo == r.qNo)) {
        out.add(RecordProblem(r.key, RecordIssue.notOnPaper, '${name(r)}: Q${r.qNo} is not on this course\'s question list.', blocks: false));
      }
    }
    if (scheme.unmarked == UnmarkedRule.ask) {
      final have = {for (final r in live) if (r.qNo != null) r.qNo!};
      for (final q in scheme.questions) {
        if (!have.contains(q.qNo)) {
          out.add(RecordProblem(null, RecordIssue.unmarkedQuestion, 'Q${q.qNo} has no mark. Add it (enter 0 if no marks were given).', blocks: true));
        }
      }
    }
    return out;
  }

  static String _text(double v) => v == v.roundToDouble() ? v.round().toString() : v.toString();
}
