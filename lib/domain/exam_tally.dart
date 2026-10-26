import 'scheme.dart';
import 'scoring.dart';

/// A mark the examiner has confirmed for one question.
class TallyMark {
  const TallyMark(this.qNo, this.mark);

  final int qNo;
  final double mark;
}

/// The exam score worked out from the marks the examiner has confirmed, under the
/// course's own rules. Pure arithmetic: nothing here reads a photograph, a written
/// total or a recognition result, so it can be recalculated whenever a mark changes
/// and always gives the same answer for the same marks.
///
///  * Each question counts once. A question number given twice is counted at its first
///    mark only and reported in [duplicates] for the examiner to resolve.
///  * A mark counts as `mark x weight` (weight 1 unless the scheme says otherwise).
///  * The counting rule (all, best N, compulsory plus best N) decides which marks are
///    added up; the ones left out are in [leftOut], never dropped silently.
///  * A question on the paper with no mark is in [unmarked]. It adds nothing, so it is
///    "zero" by arithmetic; whether that is acceptable is the scheme's
///    [UnmarkedRule], which the review screen applies.
///  * Whatever had to be assumed is in [assumptions], in plain words.
class ExamTally {
  const ExamTally({
    required this.calculated,
    required this.sumOfMarks,
    required this.counted,
    required this.leftOut,
    required this.duplicates,
    required this.unmarked,
    required this.maxPossible,
    required this.assumptions,
  });

  /// The exam score, or null when no mark has been confirmed yet.
  final double? calculated;

  /// Every confirmed mark added up as written, before weights and the counting rule.
  final double sumOfMarks;

  /// Question number -> what it adds to the score.
  final Map<int, double> counted;

  /// Question number -> what it would add but does not (best-N leaves it out).
  final Map<int, double> leftOut;

  /// Question numbers that were given more than one mark.
  final List<int> duplicates;

  /// Questions on the course's list with no mark.
  final List<int> unmarked;

  /// The most the questions can add under the counting rule, or null with no question list.
  final double? maxPossible;
  final List<String> assumptions;

  static ExamTally compute(GradingScheme scheme, Iterable<TallyMark> marks) {
    final byQuestion = <int, double>{};
    final duplicates = <int>[];
    for (final m in marks) {
      if (byQuestion.containsKey(m.qNo)) {
        if (!duplicates.contains(m.qNo)) duplicates.add(m.qNo);
        continue;
      }
      byQuestion[m.qNo] = m.mark;
    }
    duplicates.sort();

    double weightOf(int qNo) {
      for (final q in scheme.questions) {
        if (q.qNo == qNo) return q.weight;
      }
      return 1;
    }

    final contribution = {for (final e in byQuestion.entries) e.key: roundMark(e.value * weightOf(e.key))};
    final compulsoryNos = {for (final q in scheme.questions) if (q.compulsory) q.qNo};

    final counted = <int, double>{};
    final leftOut = <int, double>{};
    List<int> ranked(Iterable<int> nos) => nos.toList()
      ..sort((a, b) {
        final c = contribution[b]!.compareTo(contribution[a]!);
        return c != 0 ? c : a.compareTo(b);
      });

    switch (scheme.countRule) {
      case CountRule.all:
        counted.addAll(contribution);
      case CountRule.bestN:
        final order = ranked(contribution.keys);
        final n = scheme.countN ?? order.length;
        for (final (i, q) in order.indexed) {
          (i < n ? counted : leftOut)[q] = contribution[q]!;
        }
      case CountRule.compulsoryPlusBestN:
        final rest = <int>[];
        for (final q in contribution.keys) {
          if (compulsoryNos.contains(q)) {
            counted[q] = contribution[q]!;
          } else {
            rest.add(q);
          }
        }
        final order = ranked(rest);
        final n = scheme.countN ?? order.length;
        for (final (i, q) in order.indexed) {
          (i < n ? counted : leftOut)[q] = contribution[q]!;
        }
    }

    final unmarked = [for (final q in scheme.questions) if (!byQuestion.containsKey(q.qNo)) q.qNo]..sort();

    final assumptions = <String>[];
    if (scheme.questions.isEmpty) {
      assumptions.add('This course has no question list, so every question you confirmed is counted, whatever its number.');
    }
    if (scheme.countRule != CountRule.all && scheme.countN == null) {
      assumptions.add('The counting rule is "${scheme.countRule.label}" but no number is set for it, so every mark counts.');
    }
    final weighted = [for (final q in scheme.questions) if (q.weight != 1 && byQuestion.containsKey(q.qNo)) q];
    for (final q in weighted) {
      assumptions.add('Q${q.qNo} counts ${_n(q.weight)} times its mark (its weight).');
    }
    if (unmarked.isNotEmpty && scheme.unmarked == UnmarkedRule.zero) {
      assumptions.add('${_list(unmarked)} on the paper ${unmarked.length == 1 ? 'has' : 'have'} no mark and ${unmarked.length == 1 ? 'counts' : 'count'} as zero.');
    }
    if (leftOut.isNotEmpty) {
      assumptions.add('${_list(leftOut.keys.toList()..sort())} ${leftOut.length == 1 ? 'is' : 'are'} not counted: ${scheme.countRule.label.toLowerCase()}.');
    }

    return ExamTally(
      calculated: byQuestion.isEmpty ? null : roundMark(counted.values.fold(0.0, (a, b) => a + b)),
      sumOfMarks: roundMark(byQuestion.values.fold(0.0, (a, b) => a + b)),
      counted: counted,
      leftOut: leftOut,
      duplicates: duplicates,
      unmarked: unmarked,
      maxPossible: scheme.reachableExamScore,
      assumptions: assumptions,
    );
  }

  static String _n(double v) => v == v.roundToDouble() ? v.round().toString() : v.toString();
  static String _list(List<int> nos) => nos.map((q) => 'Q$q').join(', ');
}

/// How the total the examiner wrote on the booklet stands against the calculated one.
enum TotalAgreement {
  /// Only one of them exists (or neither): nothing to compare.
  notComparable,
  agree,
  disagree,
}

class TotalComparison {
  const TotalComparison(this.agreement, {this.difference});

  final TotalAgreement agreement;

  /// written - calculated, when they disagree.
  final double? difference;

  static TotalComparison of({required double? calculated, required double? written}) {
    if (calculated == null || written == null) return const TotalComparison(TotalAgreement.notComparable);
    final d = roundMark(written - calculated);
    return d.abs() < 1e-9 ? const TotalComparison(TotalAgreement.agree) : TotalComparison(TotalAgreement.disagree, difference: d);
  }
}
