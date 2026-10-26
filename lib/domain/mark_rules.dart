import 'scheme.dart';

/// Why a reading cannot be a mark or a question number.
enum Why { unreadable, notANumber, aboveMaximum, offStep, belowOne, aboveLimit }

/// Whether a reading can be offered to the examiner at all, and why not.
///
/// A recogniser returns whatever string of characters it saw: three glyphs of one
/// handwritten "1·0" can come back as "147". That is a digit string, not a mark. These
/// rules decide, from the course's own scheme and nothing else, which readings are
/// possible marks or question numbers. A reading that fails is never offered as a
/// suggestion, and never repaired (no decimal point is added, no value is pulled back
/// into range); it stays in the evidence with the reason it was left out.
class Plausibility {
  const Plausibility.ok(this.value)
      : plausible = true,
        reason = null,
        why = null;
  const Plausibility.no(this.reason, [this.why = Why.unreadable])
      : plausible = false,
        value = null;

  final bool plausible;
  final double? value;

  /// The kind of failure, when [plausible] is false.
  final Why? why;

  /// In words the examiner can read, when [plausible] is false.
  final String? reason;
}

/// What a mark can be: no more than the question's maximum (or the exam's, when the
/// question is not on the list), a multiple of the scheme's step, and a number.
class MarkRules {
  const MarkRules({this.max, this.step = 0});

  /// Highest mark possible here, or null when the scheme gives none.
  final double? max;

  /// Smallest increment marks go up in (0.5, 1, ...); 0 means any.
  final double step;

  /// The rules for [qNo] (null: a row whose question is not known) under [scheme]:
  /// the question's own maximum when it has one, else the exam part's.
  static MarkRules forScheme(GradingScheme scheme, {int? qNo}) {
    double? max;
    if (qNo != null) {
      for (final q in scheme.questions) {
        if (q.qNo == qNo) max = q.max;
      }
    }
    final exam = scheme.examPart;
    max ??= exam?.max;
    return MarkRules(max: max, step: exam?.step ?? 0);
  }

  static final _shape = RegExp(r'^\d{1,3}(\.\d{1,2})?$');

  Plausibility check(String? text) {
    final t = text?.trim() ?? '';
    if (t.isEmpty) return const Plausibility.no('nothing was read');
    if (t.contains('?')) return const Plausibility.no('part of it could not be read');
    if (!_shape.hasMatch(t)) return Plausibility.no('"$t" is not a number a mark can be', Why.notANumber);
    final v = double.parse(t);
    if (max != null && v > max! + 1e-9) {
      return Plausibility.no('$t is above the most this can be (${_n(max!)})', Why.aboveMaximum);
    }
    if (step > 0) {
      final n = v / step;
      if ((n - n.round()).abs() > 1e-6) return Plausibility.no('$t is not a multiple of ${_n(step)}, the step marks go up in', Why.offStep);
    }
    return Plausibility.ok(v);
  }

  static String _n(double v) => v == v.roundToDouble() ? v.round().toString() : v.toString();
}

/// What a question number can be: a whole number from 1 to the highest question
/// number the examiner has allowed (a setting, not a list the app fills in).
class QuestionRules {
  const QuestionRules({required this.highest});

  final int highest;

  static final _shape = RegExp(r'^\d{1,3}$');

  Plausibility check(String? text) {
    final t = text?.trim() ?? '';
    if (t.isEmpty) return const Plausibility.no('nothing was read');
    if (t.contains('?')) return const Plausibility.no('part of it could not be read');
    if (!_shape.hasMatch(t)) return Plausibility.no('"$t" is not a question number', Why.notANumber);
    final v = int.parse(t);
    if (v < 1) return const Plausibility.no('there is no question 0', Why.belowOne);
    if (v > highest) return Plausibility.no('$t is above the highest question number allowed ($highest)', Why.aboveLimit);
    return Plausibility.ok(v.toDouble());
  }
}
