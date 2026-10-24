import 'ids.dart';
import 'models.dart';
import 'scheme.dart';

/// The Nigerian default: Exam 70 plus 30 for the other parts, 100 in all.
/// A starting point only; the examiner can change every number.
class Defaults {
  const Defaults._();

  static const String nigerianTemplateId = 'builtin-nigerian-default';

  /// Fresh ids every call, so each course owns its own rows.
  static GradingScheme nigerianScheme() => GradingScheme(
        totalExpected: 100,
        countRule: CountRule.all,
        parts: [
          PartSpec(
            id: newId(),
            name: 'Exam',
            max: 70,
            step: 0.5,
            source: PartSource.scanned,
            sortOrder: 0,
          ),
          PartSpec(
            id: newId(),
            name: 'Attendance',
            max: 10,
            step: 1,
            sortOrder: 1,
          ),
          PartSpec(
            id: newId(),
            name: 'Assignment',
            max: 10,
            step: 0.5,
            sortOrder: 2,
          ),
          PartSpec(
            id: newId(),
            name: 'Test',
            max: 10,
            step: 0.5,
            sortOrder: 3,
          ),
        ],
        bands: nigerianGradeScale(),
      );

  /// A 70-100, B 60-69, C 50-59, D 45-49, E 40-44, F 0-39 (points 5 to 0).
  static List<GradeBand> nigerianGradeScale() => [
        GradeBand(id: newId(), minScore: 70, maxScore: 100, letter: 'A', points: 5),
        GradeBand(id: newId(), minScore: 60, maxScore: 69, letter: 'B', points: 4),
        GradeBand(id: newId(), minScore: 50, maxScore: 59, letter: 'C', points: 3),
        GradeBand(id: newId(), minScore: 45, maxScore: 49, letter: 'D', points: 2),
        GradeBand(id: newId(), minScore: 40, maxScore: 44, letter: 'E', points: 1),
        GradeBand(id: newId(), minScore: 0, maxScore: 39, letter: 'F', points: 0),
      ];

  static SchemeTemplate builtInTemplate() => SchemeTemplate(
        id: nigerianTemplateId,
        name: 'Nigerian default (Exam 70 + 30)',
        scheme: nigerianScheme(),
        isBuiltIn: true,
      );
}
