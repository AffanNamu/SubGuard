import 'mark_rules.dart';
import 'ocr.dart';
import 'recognition.dart';

/// A reading that was left out of the suggestions, with the reason.
class LeftOut {
  const LeftOut(this.text, this.reason);

  final String text;
  final String reason;
}

/// What the machine offers for one row of the examiner's marks table, kept as two
/// independent pieces: the question number written in the Question column and the mark
/// written in the Marks column.
///
/// Suggestions are alternatives *for one field each*. The question alternatives are only
/// ever question numbers and the mark alternatives only ever marks; neither is used to
/// guess the other, and none of them is a value until the examiner picks it. A reading
/// that cannot be a question number or a mark under the course's rules is left out of
/// the alternatives ([markLeftOut], [questionLeftOut]) and kept as evidence, with why.
class RowSuggestions {
  const RowSuggestions({
    required this.index,
    required this.rawMark,
    required this.rawQuestion,
    required this.markAlternatives,
    required this.markLeftOut,
    required this.questionAlternatives,
    required this.questionLeftOut,
    this.markRegion,
    this.questionRegion,
    this.warnings = const [],
  });

  /// 1 for the row at the top of the table.
  final int index;

  /// What the reader returned for each cell, characters as seen ("1.7", "1?0"), whether
  /// or not it could be a mark. Null when nothing was read.
  final String? rawMark;
  final String? rawQuestion;

  /// The plausible readings, best first.
  final List<FieldCandidate> markAlternatives;
  final List<LeftOut> markLeftOut;
  final List<FieldCandidate> questionAlternatives;
  final List<LeftOut> questionLeftOut;

  /// Where the cells are on the photograph.
  final Region? markRegion;
  final Region? questionRegion;

  /// What the reader noticed about the cell (a stroke ignored, a character that was
  /// not a digit).
  final List<String> warnings;

  bool get markReadable => markAlternatives.isNotEmpty;
  bool get questionReadable => questionAlternatives.isNotEmpty;

  /// The row's key in the stored recognition result.
  String get markKey => 'mark_row_$index';
  String get questionKey => 'question_row_$index';

  static RowSuggestions of({
    required int index,
    required ExtractedField? mark,
    required ExtractedField? question,
    required MarkRules Function(int? qNo) marksFor,
    required QuestionRules questionRules,
  }) {
    // The question number first: it decides which maximum a mark is judged against.
    final qAlt = <FieldCandidate>[];
    final qOut = <LeftOut>[];
    final qSeen = <String>{};
    for (final c in [...?question?.candidates, if (question == null && mark?.question != null) FieldCandidate(mark!.question!, 0.5, source: 'mark row')]) {
      if (!qSeen.add(c.text)) continue;
      final p = questionRules.check(c.text);
      if (p.plausible) {
        qAlt.add(c);
      } else {
        qOut.add(LeftOut(c.text, p.reason!));
      }
    }
    final rawQuestion = question?.attempts.isNotEmpty == true ? question!.attempts.first.text : question?.value;
    if (qAlt.isEmpty && rawQuestion != null && qSeen.add(rawQuestion)) {
      final p = questionRules.check(rawQuestion);
      if (!p.plausible) qOut.add(LeftOut(rawQuestion, p.reason!));
    }

    final topQ = qAlt.isEmpty ? null : int.tryParse(qAlt.first.text);
    final rules = marksFor(topQ);
    final mAlt = <FieldCandidate>[];
    final mOut = <LeftOut>[];
    final mSeen = <String>{};
    for (final c in mark?.candidates ?? const <FieldCandidate>[]) {
      if (!mSeen.add(c.text)) continue;
      final p = rules.check(c.text);
      if (p.plausible) {
        mAlt.add(c);
      } else {
        mOut.add(LeftOut(c.text, p.reason!));
      }
    }
    final rawMark = mark?.attempts.isNotEmpty == true ? mark!.attempts.first.text : mark?.value;
    if (mAlt.isEmpty && rawMark != null && mSeen.add(rawMark)) {
      final p = rules.check(rawMark);
      mOut.add(LeftOut(rawMark, p.plausible ? 'it is a number but it is not one of the reader\'s complete readings' : p.reason!));
    }

    return RowSuggestions(
      index: index,
      rawMark: rawMark,
      rawQuestion: rawQuestion,
      markAlternatives: mAlt,
      markLeftOut: mOut,
      questionAlternatives: qAlt,
      questionLeftOut: qOut,
      markRegion: mark?.region,
      questionRegion: question?.region,
      warnings: mark?.warnings ?? const [],
    );
  }

  /// One entry per row of the stored result, top to bottom.
  static List<RowSuggestions> allOf(
    Iterable<ExtractedField> fields, {
    required MarkRules Function(int? qNo) marksFor,
    required QuestionRules questionRules,
  }) {
    final marks = <int, ExtractedField>{};
    final questions = <int, ExtractedField>{};
    for (final f in fields) {
      final m = RegExp(r'^(mark|question)_row_(\d+)$').firstMatch(f.key);
      if (m == null) continue;
      (m.group(1) == 'mark' ? marks : questions)[int.parse(m.group(2)!)] = f;
    }
    final indexes = {...marks.keys, ...questions.keys}.toList()..sort();
    return [
      for (final i in indexes)
        RowSuggestions.of(index: i, mark: marks[i], question: questions[i], marksFor: marksFor, questionRules: questionRules),
    ];
  }
}
