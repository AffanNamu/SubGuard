import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database/app_database.dart';
import '../data/repositories/course_repository.dart';
import '../data/repositories/score_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/student_repository.dart';
import '../domain/defaults.dart';
import '../domain/flags.dart';
import '../domain/models.dart';
import '../domain/scheme.dart';
import '../domain/scoring.dart';

// ---- infrastructure (overridden in main() and in tests) ----

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden');
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final courseRepositoryProvider =
    Provider((ref) => CourseRepository(ref.watch(databaseProvider)));
final studentRepositoryProvider =
    Provider((ref) => StudentRepository(ref.watch(databaseProvider)));
final scoreRepositoryProvider =
    Provider((ref) => ScoreRepository(ref.watch(databaseProvider)));
final settingsRepositoryProvider =
    Provider((ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)));

/// App version, for the About row. Null where the platform cannot say, so a
/// missing plugin never breaks Settings.
final packageInfoProvider = FutureProvider<PackageInfo?>((ref) async {
  try {
    return await PackageInfo.fromPlatform();
  } catch (_) {
    return null;
  }
});

// ---- settings ----

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).load();

  Future<void> update(AppSettings Function(AppSettings) change) async {
    state = change(state);
    await ref.read(settingsRepositoryProvider).save(state);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

// ---- data streams ----

final coursesProvider = StreamProvider<List<Course>>(
    (ref) => ref.watch(courseRepositoryProvider).watchAll());

final deletedCoursesProvider = StreamProvider<List<Course>>(
    (ref) => ref.watch(courseRepositoryProvider).watchDeleted());

final courseProvider = StreamProvider.family<Course?, String>(
    (ref, id) => ref.watch(courseRepositoryProvider).watch(id));

final studentsProvider = StreamProvider.family<List<Student>, String>(
    (ref, courseId) => ref.watch(studentRepositoryProvider).watch(courseId));

final deletedStudentsProvider = StreamProvider.family<List<Student>, String>(
    (ref, courseId) =>
        ref.watch(studentRepositoryProvider).watchDeleted(courseId));

final scoresProvider = StreamProvider.family<ScoreMap, String>(
    (ref, courseId) => ref.watch(scoreRepositoryProvider).watch(courseId));

final templatesProvider = StreamProvider<List<SchemeTemplate>>(
    (ref) => ref.watch(courseRepositoryProvider).watchTemplates());

/// The built-in Nigerian default followed by the examiner's saved templates.
final allTemplatesProvider = Provider<List<SchemeTemplate>>((ref) {
  final saved = ref.watch(templatesProvider).valueOrNull ?? const [];
  return [Defaults.builtInTemplate(), ...saved];
});

// ---- the score grid ----

class GridRow {
  const GridRow({
    required this.student,
    required this.values,
    required this.result,
    required this.flags,
  });

  final Student student;
  final Map<String, PartValue> values;
  final ScoreResult result;
  final List<ScoreFlag> flags;

  bool get needsAttention => flags.any((f) => f.needsAttention);

  List<ScoreFlag> flagsFor(String partId) =>
      flags.where((f) => f.partId == partId).toList();

  List<ScoreFlag> get rowFlags => flags.where((f) => f.partId == null).toList();
}

class CourseStats {
  const CourseStats({
    required this.students,
    required this.complete,
    required this.started,
    required this.flagged,
    required this.cellsEntered,
    required this.cellsTotal,
  });

  final int students;

  /// Every part has a mark or is marked absent.
  final int complete;

  /// At least one part has a mark, but not all.
  final int started;

  /// Students with at least one flag that needs attention.
  final int flagged;
  final int cellsEntered;
  final int cellsTotal;

  int get notStarted => students - complete - started;
  double get progress => cellsTotal == 0 ? 0 : cellsEntered / cellsTotal;
}

class GridData {
  const GridData({
    required this.course,
    required this.rows,
    required this.stats,
  });

  final Course course;
  final List<GridRow> rows;
  final CourseStats stats;

  GradingScheme get scheme => course.scheme;
}

/// Totals, grades and flags for every student, recalculated whenever the
/// scheme, the class list or any mark changes. Changing the scheme later
/// therefore re-checks every student straight away.
final gridProvider = Provider.family<AsyncValue<GridData>, String>((ref, courseId) {
  final course = ref.watch(courseProvider(courseId));
  final students = ref.watch(studentsProvider(courseId));
  final scores = ref.watch(scoresProvider(courseId));

  if (course.hasError) return AsyncError(course.error!, course.stackTrace!);
  if (students.hasError) return AsyncError(students.error!, students.stackTrace!);
  if (scores.hasError) return AsyncError(scores.error!, scores.stackTrace!);

  final c = course.valueOrNull;
  final s = students.valueOrNull;
  final sc = scores.valueOrNull;
  if (c == null || s == null || sc == null) {
    return course.hasValue && course.value == null
        ? AsyncError(StateError('Course not found'), StackTrace.current)
        : const AsyncLoading();
  }
  return AsyncData(buildGrid(c, s, sc));
});

GridData buildGrid(Course course, List<Student> students, ScoreMap scores) {
  final scheme = course.scheme;
  final flags = FlagChecker.check(
    scheme: scheme,
    students: [
      for (final s in students)
        FlagInput(studentId: s.id, regNo: s.regNo, onClassList: s.onClassList),
    ],
    scores: scores,
  );

  var complete = 0, started = 0, flagged = 0, entered = 0;
  final rows = <GridRow>[];
  for (final s in students) {
    final values = scores[s.id] ?? const <String, PartValue>{};
    final result = ScoreCalculator.compute(scheme, values);
    final f = flags[s.id] ?? const <ScoreFlag>[];
    final row = GridRow(student: s, values: values, result: result, flags: f);
    rows.add(row);

    if (result.complete) {
      complete++;
    } else if (result.total != null) {
      started++;
    }
    if (row.needsAttention) flagged++;
    entered += scheme.parts.where((p) => values[p.id]?.isFilled ?? false).length;
  }

  return GridData(
    course: course,
    rows: rows,
    stats: CourseStats(
      students: students.length,
      complete: complete,
      started: started,
      flagged: flagged,
      cellsEntered: entered,
      cellsTotal: students.length * scheme.parts.length,
    ),
  );
}
