import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import '../data/database/app_database.dart';
import '../data/repositories/course_repository.dart';
import '../data/repositories/booklet_repository.dart';
import '../data/repositories/recognition_repository.dart';
import '../data/repositories/review_draft_repository.dart';
import '../data/repositories/scan_repository.dart';
import '../data/repositories/score_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/student_repository.dart';
import '../domain/defaults.dart';
import '../domain/flags.dart';
import '../domain/layout_profile.dart';
import '../domain/models.dart';
import '../domain/scan.dart';
import '../domain/scheme.dart';
import '../domain/scoring.dart';
import '../services/reader/layout_engine.dart';
import '../services/reader/ocr_engine.dart';
import '../services/reader/scan_processor.dart';
import '../services/recognition/attention.dart';
import '../services/recognition/booklet_pipeline.dart';
import '../services/recognition/interfaces.dart';
import '../services/recognition/model_registry.dart';
import '../services/scan/image_source.dart';
import '../services/scan/intake_service.dart';
import '../services/scan/scan_files.dart';

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
final scanRepositoryProvider = Provider(
    (ref) => ScanRepository(ref.watch(databaseProvider), ref.watch(courseRepositoryProvider)));

final bookletRepositoryProvider = Provider(
    (ref) => BookletRepository(ref.watch(databaseProvider), ref.watch(scoreRepositoryProvider)));

/// What reads the text in photos. Tests replace it.
final ocrEngineProvider = Provider<OcrEngine>((ref) => defaultOcrEngine());

final recognitionRepositoryProvider = Provider((ref) => RecognitionRepository(ref.watch(databaseProvider)));
final reviewDraftRepositoryProvider = Provider((ref) => ReviewDraftRepository(ref.watch(databaseProvider)));

/// Why a photo is waiting for review, from its stored recognition run.
final attentionProvider = FutureProvider.family<String?, String>((ref, scanId) async {
  final run = await ref.watch(recognitionRepositoryProvider).latestRun(scanId);
  return attentionOf(run?.result);
});

/// The recognition pipeline: the text reader above, the layout, and the
/// verified handwriting model. If the model file is missing or damaged the
/// pipeline is still built, and says so for every photo (marks fail with the
/// reason) rather than reading with something else. Tests replace this.
final recognitionPipelineProvider = FutureProvider<RecognitionOrchestrator>((ref) async {
  final ocr = ref.watch(ocrEngineProvider);
  LoadedDigitModel? digits;
  String? error;
  try {
    digits = await ModelRegistry.loadDigits();
  } on ModelException catch (e) {
    error = e.message;
  }
  // The layout in use is read for each photo, so choosing another applies from the next one.
  final layout = ref.watch(layoutChoiceProvider.select((c) => c.selected));
  return BookletPipeline(ocr: ocr, digits: digits, digitsError: error, layout: ProfileLayoutAnalyzer(layout));
});

final scanProcessorProvider = Provider((ref) => ScanProcessor(
      scans: ref.watch(scanRepositoryProvider),
      booklets: ref.watch(bookletRepositoryProvider),
      files: ref.watch(scanFilesProvider),
      pipeline: () => ref.read(recognitionPipelineProvider.future),
      recognitions: ref.watch(recognitionRepositoryProvider),
      students: ref.watch(studentRepositoryProvider),
      courses: ref.watch(courseRepositoryProvider),
    ));

/// Where the original photos are kept. Overridden in main() and in tests.
final scanFilesProvider = Provider<ScanFiles>((ref) {
  throw UnimplementedError('scanFilesProvider must be overridden');
});

/// Where photos come from: the camera and the phone's storage. Tests replace it.
final imageSourceProvider = Provider<ImageSource>((ref) => DeviceImageSource());

final intakeServiceProvider = Provider(
    (ref) => IntakeService(ref.watch(scanRepositoryProvider), ref.watch(scanFilesProvider)));

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

// ---- booklet layouts ----

/// The layouts the app can read a booklet cover with: the built-in one and any the
/// administrator added, and which one is in use.
class LayoutChoice {
  const LayoutChoice({this.imported = const [], this.selectedId = 'modibbo-adama-cover'});

  final List<LayoutProfile> imported;
  final String selectedId;

  List<LayoutProfile> get all => [LayoutProfile.modibboAdama, ...imported];

  /// The layout in use; the built-in one if the selected one is gone.
  LayoutProfile get selected => all.firstWhere((p) => p.id == selectedId, orElse: () => LayoutProfile.modibboAdama);

  bool isBuiltIn(LayoutProfile p) => p.id == LayoutProfile.modibboAdama.id;
}

class LayoutChoiceNotifier extends Notifier<LayoutChoice> {
  @override
  LayoutChoice build() {
    final repo = ref.watch(settingsRepositoryProvider);
    return LayoutChoice(imported: repo.importedLayouts(), selectedId: repo.selectedLayoutId ?? LayoutProfile.modibboAdama.id);
  }

  Future<void> _save(LayoutChoice next) async {
    state = next;
    await ref.read(settingsRepositoryProvider).saveLayouts(next.imported, next.selectedId);
  }

  /// Uses this layout for the photos read from now on. Photos already read keep the
  /// record of the layout that read them.
  Future<void> select(String id) async {
    if (!state.all.any((p) => p.id == id)) return;
    await _save(LayoutChoice(imported: state.imported, selectedId: id));
  }

  /// Adds the layout in [text], checked first; throws [LayoutProfileException] saying
  /// what is wrong. A file with an id already added replaces it (a new revision); the
  /// built-in layout's id cannot be replaced.
  Future<LayoutProfile> add(String text) async {
    final profile = LayoutProfile.parse(text);
    if (profile.id == LayoutProfile.modibboAdama.id) {
      throw const LayoutProfileException('id: "modibbo-adama-cover" is the built-in layout. Give your layout its own id.');
    }
    final imported = [for (final p in state.imported) if (p.id != profile.id) p, profile];
    await _save(LayoutChoice(imported: imported, selectedId: state.selectedId));
    return profile;
  }

  Future<void> remove(String id) async {
    final imported = [for (final p in state.imported) if (p.id != id) p];
    await _save(LayoutChoice(imported: imported, selectedId: state.selectedId == id ? LayoutProfile.modibboAdama.id : state.selectedId));
  }
}

final layoutChoiceProvider = NotifierProvider<LayoutChoiceNotifier, LayoutChoice>(LayoutChoiceNotifier.new);

/// Where a layout file comes from. Null when the examiner chose nothing. Tests replace it.
final layoutFilePickerProvider = Provider<Future<({String name, String text})?> Function()>((ref) => () async {
      final picked = await FilePicker.platform.pickFiles(type: FileType.any, withData: true); // the file's contents are checked, not its name
      final file = picked?.files.singleOrNull;
      final bytes = file?.bytes;
      if (file == null || bytes == null) return null;
      return (name: file.name, text: utf8.decode(bytes, allowMalformed: true));
    });

/// Where a layout file goes when the administrator shares one. Tests replace it.
final layoutFileSharerProvider = Provider<Future<void> Function(String fileName, String text)>((ref) => (name, text) async {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$name')..writeAsStringSync(text);
      await Share.shareXFiles([XFile(file.path, mimeType: 'application/json')], subject: 'UniMarkLy booklet layout');
    });

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

// ---- uploads ----

final batchesProvider = StreamProvider<List<BatchSummary>>(
    (ref) => ref.watch(scanRepositoryProvider).watchBatches());

/// Counted from stored records, never typed in.
final scanStatsProvider = Provider<ScanStats>((ref) {
  final list = ref.watch(batchesProvider).valueOrNull ?? const <BatchSummary>[];
  var records = 0, confirmed = 0, review = 0;
  for (final b in list) {
    records += b.counts.records;
    confirmed += b.counts.confirmed;
    review += b.counts.needsReview;
  }
  return ScanStats(batches: list.length, records: records, confirmed: confirmed, needReview: review);
});

final batchProvider = Provider.family<BatchSummary?, String>((ref, id) {
  for (final b in ref.watch(batchesProvider).valueOrNull ?? const <BatchSummary>[]) {
    if (b.id == id) return b;
  }
  return null;
});

final batchScansProvider = StreamProvider.family<List<ScanItem>, String>(
    (ref, batchId) => ref.watch(scanRepositoryProvider).watchScans(batchId));

final reviewQueueProvider = StreamProvider<List<ScanItem>>(
    (ref) => ref.watch(scanRepositoryProvider).watchNeedingReview());

/// Bytes used by the stored booklet photos. Re-counted when an upload is
/// added or deleted, so Settings shows the real figure.
final storageUsedProvider = FutureProvider<int>((ref) {
  ref.watch(batchesProvider);
  return ref.watch(scanFilesProvider).bytesUsed();
});

// ---- reading ----

class ProcessingState {
  const ProcessingState({this.batchId, this.done = 0, this.total = 0, this.paused = false});

  /// The batch being read now; null when idle.
  final String? batchId;
  final int done;
  final int total;
  final bool paused;

  bool get running => batchId != null;
  double get progress => total == 0 ? 0 : done / total;
}

/// Runs the reader over a batch in the background and reports real progress.
/// One batch at a time; the screen stays responsive because each photo is read
/// and stored before the next begins.
class ProcessingController extends Notifier<ProcessingState> {
  bool _stop = false;

  @override
  ProcessingState build() => const ProcessingState();

  Future<void> start(String batchId) async {
    if (state.running) return;
    _stop = false;
    state = ProcessingState(batchId: batchId);
    try {
      await ref.read(scanProcessorProvider).processBatch(
            batchId,
            shouldStop: () => _stop,
            onProgress: (done, total) => state = ProcessingState(batchId: batchId, done: done, total: total, paused: _stop),
          );
    } finally {
      state = const ProcessingState();
    }
  }

  /// Stops after the photo being read; the rest stay queued.
  void pause() {
    _stop = true;
    if (state.running) {
      state = ProcessingState(batchId: state.batchId, done: state.done, total: state.total, paused: true);
    }
  }

  /// Reads whatever is still queued in every batch, oldest first, when
  /// "Read photos when added" is on. Used when the app opens, after photos left
  /// half-read by a closed app were re-queued.
  Future<void> resumeAll() async {
    final repo = ref.read(scanRepositoryProvider);
    await repo.requeueInterrupted();
    // Photos the examiner chose not to read automatically stay queued until
    // they press Read.
    if (!ref.read(settingsProvider).readAutomatically) return;
    for (final batch in (await repo.batches()).reversed) {
      if (batch.counts.queued > 0) await start(batch.id);
    }
  }
}

final processingProvider =
    NotifierProvider<ProcessingController, ProcessingState>(ProcessingController.new);

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
