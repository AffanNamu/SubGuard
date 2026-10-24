import 'reg_no.dart';
import 'scheme.dart';
import 'scoring.dart';

enum FlagKind {
  invalidRegNo,
  notOnClassList,
  duplicateRegNo,
  belowMin,
  aboveMax,
  offStep,
  totalAboveMax,
  belowPass,
}

enum FlagSeverity { error, warning, info }

class ScoreFlag {
  const ScoreFlag({
    required this.kind,
    required this.severity,
    required this.message,
    this.partId,
  });

  final FlagKind kind;
  final FlagSeverity severity;
  final String message;

  /// Set when the flag belongs to one cell rather than the whole row.
  final String? partId;

  /// Warnings and errors need attention; info (below pass mark) does not.
  bool get needsAttention => severity != FlagSeverity.info;
}

class FlagInput {
  const FlagInput({
    required this.studentId,
    required this.regNo,
    required this.onClassList,
  });

  final String studentId;
  final String regNo;
  final bool onClassList;
}

/// Checks one course. Every limit comes from the course's [GradingScheme];
/// nothing is hard-coded, and nothing here edits or blocks a value.
class FlagChecker {
  const FlagChecker._();

  static Map<String, List<ScoreFlag>> check({
    required GradingScheme scheme,
    required List<FlagInput> students,
    required Map<String, Map<String, PartValue>> scores,
  }) {
    final duplicates = _duplicateKeys(students);
    final result = <String, List<ScoreFlag>>{};

    for (final s in students) {
      final flags = <ScoreFlag>[];

      final reg = RegNo.normalise(s.regNo);
      if (!reg.isValid) {
        flags.add(const ScoreFlag(
          kind: FlagKind.invalidRegNo,
          severity: FlagSeverity.warning,
          message: 'Registration number does not match DEPT/YYU/NNNN.',
        ));
      }
      if (duplicates.contains(reg.canonical)) {
        flags.add(const ScoreFlag(
          kind: FlagKind.duplicateRegNo,
          severity: FlagSeverity.error,
          message: 'This registration number appears more than once.',
        ));
      }
      if (!s.onClassList) {
        flags.add(const ScoreFlag(
          kind: FlagKind.notOnClassList,
          severity: FlagSeverity.warning,
          message: 'Not on the class list.',
        ));
      }

      final byPart = scores[s.studentId] ?? const <String, PartValue>{};
      for (final part in scheme.parts) {
        final entry = byPart[part.id];
        if (entry == null || !entry.hasValue) continue;
        flags.addAll(cellFlags(part, entry.value!));
      }

      final total = ScoreCalculator.compute(scheme, byPart).total;
      if (total != null && total > scheme.totalExpected + 1e-9) {
        flags.add(ScoreFlag(
          kind: FlagKind.totalAboveMax,
          severity: FlagSeverity.error,
          message:
              'Total ${formatNumber(total)} is above the maximum of ${formatNumber(scheme.totalExpected)}.',
        ));
      }

      if (flags.isNotEmpty) result[s.studentId] = flags;
    }
    return result;
  }

  /// Flags for a single mark against its part's limits.
  static List<ScoreFlag> cellFlags(PartSpec part, double value) {
    final flags = <ScoreFlag>[];
    if (value < part.min - 1e-9) {
      flags.add(ScoreFlag(
        kind: FlagKind.belowMin,
        severity: FlagSeverity.error,
        message:
            '${part.name} ${formatNumber(value)} is below the minimum of ${formatNumber(part.min)}.',
        partId: part.id,
      ));
    }
    if (value > part.max + 1e-9) {
      flags.add(ScoreFlag(
        kind: FlagKind.aboveMax,
        severity: FlagSeverity.error,
        message:
            '${part.name} ${formatNumber(value)} is above the maximum of ${formatNumber(part.max)}.',
        partId: part.id,
      ));
    }
    if (!ScoreCalculator.isOnStep(value, part.step)) {
      flags.add(ScoreFlag(
        kind: FlagKind.offStep,
        severity: FlagSeverity.warning,
        message:
            '${part.name} ${formatNumber(value)} is not a multiple of ${formatNumber(part.step)}.',
        partId: part.id,
      ));
    }
    final pass = part.passMark;
    if (pass != null && value < pass - 1e-9) {
      flags.add(ScoreFlag(
        kind: FlagKind.belowPass,
        severity: FlagSeverity.info,
        message:
            '${part.name} is under the pass mark of ${formatNumber(pass)}.',
        partId: part.id,
      ));
    }
    return flags;
  }

  static Set<String> _duplicateKeys(List<FlagInput> students) {
    final seen = <String>{};
    final dupes = <String>{};
    for (final s in students) {
      final key = RegNo.key(s.regNo);
      if (key.isEmpty) continue;
      if (!seen.add(key)) dupes.add(key);
    }
    return dupes;
  }
}
