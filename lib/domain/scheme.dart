/// The grading scheme of one course. Nothing here is hard-coded to 70 / 30:
/// every limit, pass mark, step and grade range comes from these objects.
enum CountRule {
  all('all', 'All answered questions'),
  bestN('best_n', 'Best N of the questions'),
  compulsoryPlusBestN(
      'compulsory_plus_best_n', 'Compulsory questions plus best N of the rest');

  const CountRule(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static CountRule fromDb(String? value) => CountRule.values.firstWhere(
        (r) => r.dbValue == value,
        orElse: () => CountRule.all,
      );
}

/// What a question on the paper with no mark means.
enum UnmarkedRule {
  /// It counts as zero. The usual case: the candidate did not answer it.
  zero('zero', 'Counts as zero'),

  /// Each one must be given a mark (0 if that is what it is) before the booklet
  /// is confirmed.
  ask('ask', 'Ask me about each one');

  const UnmarkedRule(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static UnmarkedRule fromDb(String? value) => UnmarkedRule.values.firstWhere(
        (r) => r.dbValue == value,
        orElse: () => UnmarkedRule.zero,
      );
}

enum PartSource {
  scanned('scanned', 'Scanned booklets'),
  typed('typed', 'Typed into the grid'),
  imported('imported', 'Imported file');

  const PartSource(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static PartSource fromDb(String? value) => PartSource.values.firstWhere(
        (s) => s.dbValue == value,
        orElse: () => PartSource.typed,
      );
}

class PartSpec {
  const PartSpec({
    required this.id,
    required this.name,
    required this.max,
    this.min = 0,
    this.passMark,
    this.step = 0.5,
    this.markedOutOf,
    this.countsFor,
    this.source = PartSource.typed,
    this.sortOrder = 0,
  });

  final String id;
  final String name;

  /// Highest mark allowed for the part.
  final double max;

  /// Lowest valid mark; anything below is flagged.
  final double min;

  /// Optional. Scores under it are highlighted, never blocked.
  final double? passMark;

  /// Smallest allowed increment (0.25, 0.5 or 1).
  final double step;

  /// What the raw mark is out of. Null means "same as [max]".
  final double? markedOutOf;

  /// How much the part adds to the total. Null means "same as [max]".
  final double? countsFor;

  final PartSource source;
  final int sortOrder;

  double get effectiveMarkedOutOf => markedOutOf ?? max;
  double get effectiveCountsFor => countsFor ?? max;

  /// Scaled contribution of a raw mark: a test marked out of 20 that counts
  /// for 10 contributes `raw / 20 * 10`.
  double contribution(double raw) {
    final outOf = effectiveMarkedOutOf;
    if (outOf == 0) return 0;
    return raw * effectiveCountsFor / outOf;
  }

  /// Parts filled from scanned booklets behave like the exam: shown as the
  /// examiner wrote them, and left blank in continuous-assessment exports.
  bool get isExamLike => source == PartSource.scanned;

  /// Pass `clearPassMark`, `clearMarkedOutOf` or `clearCountsFor` to set that
  /// field back to "not set" (null).
  PartSpec copyWith({
    String? name,
    double? max,
    double? min,
    double? passMark,
    bool clearPassMark = false,
    double? step,
    double? markedOutOf,
    bool clearMarkedOutOf = false,
    double? countsFor,
    bool clearCountsFor = false,
    PartSource? source,
    int? sortOrder,
  }) {
    return PartSpec(
      id: id,
      name: name ?? this.name,
      max: max ?? this.max,
      min: min ?? this.min,
      passMark: clearPassMark ? null : (passMark ?? this.passMark),
      step: step ?? this.step,
      markedOutOf:
          clearMarkedOutOf ? null : (markedOutOf ?? this.markedOutOf),
      countsFor: clearCountsFor ? null : (countsFor ?? this.countsFor),
      source: source ?? this.source,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class QuestionSpec {
  const QuestionSpec({
    required this.id,
    required this.qNo,
    required this.max,
    this.compulsory = false,
    this.weight = 1,
  });

  final String id;
  final int qNo;
  final double max;
  final bool compulsory;

  /// What a mark on this question is multiplied by before it counts. 1 for an
  /// ordinary question; a question that counts double has 2.
  final double weight;

  /// The most this question can add to the score: its maximum times its weight.
  double get maxContribution => max * weight;

  QuestionSpec copyWith({int? qNo, double? max, bool? compulsory, double? weight}) =>
      QuestionSpec(
        id: id,
        qNo: qNo ?? this.qNo,
        max: max ?? this.max,
        compulsory: compulsory ?? this.compulsory,
        weight: weight ?? this.weight,
      );
}

class GradeBand {
  const GradeBand({
    required this.id,
    required this.minScore,
    required this.maxScore,
    required this.letter,
    required this.points,
  });

  final String id;
  final double minScore;
  final double maxScore;
  final String letter;
  final double points;

  GradeBand copyWith({
    double? minScore,
    double? maxScore,
    String? letter,
    double? points,
  }) =>
      GradeBand(
        id: id,
        minScore: minScore ?? this.minScore,
        maxScore: maxScore ?? this.maxScore,
        letter: letter ?? this.letter,
        points: points ?? this.points,
      );
}

enum SchemeWarningKind {
  partsDoNotAddUp,
  questionsCannotReachExamMax,
  noParts,
  badPartLimits,
  duplicatePartName,
  gradeScaleGap,
  gradeScaleOverlap,
}

class SchemeWarning {
  const SchemeWarning(this.kind, this.message, {this.partId});
  final SchemeWarningKind kind;
  final String message;
  final String? partId;
}

class GradingScheme {
  const GradingScheme({
    this.totalExpected = 100,
    this.countRule = CountRule.all,
    this.countN,
    this.unmarked = UnmarkedRule.zero,
    this.parts = const [],
    this.questions = const [],
    this.bands = const [],
  });

  /// What the parts should add up to (100 by default).
  final double totalExpected;
  final CountRule countRule;
  final int? countN;

  /// What a question on the list with no mark means for a booklet.
  final UnmarkedRule unmarked;
  final List<PartSpec> parts;
  final List<QuestionSpec> questions;
  final List<GradeBand> bands;

  /// Sum of what every part counts for; the scheme's own maximum total.
  double get partsTotal =>
      parts.fold(0.0, (sum, p) => sum + p.effectiveCountsFor);

  PartSpec? partById(String id) {
    for (final p in parts) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// The exam part: the first part filled from scanned booklets.
  PartSpec? get examPart {
    for (final p in parts) {
      if (p.isExamLike) return p;
    }
    return null;
  }

  /// Highest exam score the questions can produce under the counting rule.
  double? get reachableExamScore {
    if (questions.isEmpty) return null;
    final maxes = questions.map((q) => q.maxContribution).toList()..sort((a, b) => b.compareTo(a));
    switch (countRule) {
      case CountRule.all:
        return maxes.fold<double>(0, (a, b) => a + b);
      case CountRule.bestN:
        final n = (countN ?? maxes.length).clamp(0, maxes.length);
        return maxes.take(n).fold<double>(0, (a, b) => a + b);
      case CountRule.compulsoryPlusBestN:
        final compulsory = questions.where((q) => q.compulsory).map((q) => q.maxContribution);
        final rest = questions
            .where((q) => !q.compulsory)
            .map((q) => q.maxContribution)
            .toList()
          ..sort((a, b) => b.compareTo(a));
        final n = (countN ?? rest.length).clamp(0, rest.length);
        return compulsory.fold<double>(0, (a, b) => a + b) +
            rest.take(n).fold<double>(0, (a, b) => a + b);
    }
  }

  /// Plain-words warnings. They guide; nothing is ever blocked or changed.
  List<SchemeWarning> warnings() {
    final out = <SchemeWarning>[];
    if (parts.isEmpty) {
      out.add(const SchemeWarning(
          SchemeWarningKind.noParts, 'Add at least one part, such as Exam.'));
    }

    final total = partsTotal;
    if ((total - totalExpected).abs() > 1e-9) {
      out.add(SchemeWarning(
        SchemeWarningKind.partsDoNotAddUp,
        'The parts add up to ${_n(total)}, but you expect ${_n(totalExpected)}.',
      ));
    }

    final seen = <String>{};
    for (final p in parts) {
      if (p.max < p.min) {
        out.add(SchemeWarning(
          SchemeWarningKind.badPartLimits,
          '${p.name}: the minimum (${_n(p.min)}) is above the maximum (${_n(p.max)}).',
          partId: p.id,
        ));
      }
      if (p.step <= 0) {
        out.add(SchemeWarning(
          SchemeWarningKind.badPartLimits,
          '${p.name}: the step must be more than 0.',
          partId: p.id,
        ));
      }
      if (!seen.add(p.name.trim().toLowerCase())) {
        out.add(SchemeWarning(
          SchemeWarningKind.duplicatePartName,
          'Two parts are called "${p.name}".',
          partId: p.id,
        ));
      }
    }

    final exam = examPart;
    final reach = reachableExamScore;
    if (exam != null && reach != null && reach + 1e-9 < exam.max) {
      out.add(SchemeWarning(
        SchemeWarningKind.questionsCannotReachExamMax,
        'The questions can only reach ${_n(reach)}, but ${exam.name} is out of ${_n(exam.max)}.',
        partId: exam.id,
      ));
    }

    if (bands.length > 1) {
      final sorted = [...bands]..sort((a, b) => a.minScore.compareTo(b.minScore));
      for (var i = 0; i < sorted.length - 1; i++) {
        final lower = sorted[i];
        final upper = sorted[i + 1];
        if (lower.maxScore >= upper.minScore) {
          out.add(SchemeWarning(
            SchemeWarningKind.gradeScaleOverlap,
            'Grades ${lower.letter} and ${upper.letter} overlap.',
          ));
        }
      }
    }
    return out;
  }

  GradingScheme copyWith({
    double? totalExpected,
    CountRule? countRule,
    int? countN,
    bool clearCountN = false,
    UnmarkedRule? unmarked,
    List<PartSpec>? parts,
    List<QuestionSpec>? questions,
    List<GradeBand>? bands,
  }) =>
      GradingScheme(
        totalExpected: totalExpected ?? this.totalExpected,
        countRule: countRule ?? this.countRule,
        countN: clearCountN ? null : (countN ?? this.countN),
        unmarked: unmarked ?? this.unmarked,
        parts: parts ?? this.parts,
        questions: questions ?? this.questions,
        bands: bands ?? this.bands,
      );

  static String _n(double v) => formatNumber(v);
}

/// Shortest readable form: 70, 9.5, 0.25.
String formatNumber(double v) {
  var s = v.toStringAsFixed(2);
  if (s.contains('.')) {
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
  return s;
}

/// "Exam 70 + Test 10 + Assignment 10 + Attendance 10 = 100"
String schemeSummary(GradingScheme scheme) {
  if (scheme.parts.isEmpty) return 'No parts yet';
  final parts = scheme.parts
      .map((p) => '${p.name} ${formatNumber(p.effectiveCountsFor)}')
      .join(' + ');
  return '$parts = ${formatNumber(scheme.partsTotal)}';
}
