import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unimarkly/app.dart';
import 'package:unimarkly/data/database/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:unimarkly/data/repositories/course_repository.dart';
import 'package:unimarkly/data/repositories/scan_repository.dart';
import 'package:unimarkly/data/repositories/score_repository.dart';
import 'package:unimarkly/data/repositories/student_repository.dart';
import 'package:unimarkly/domain/defaults.dart';
import 'package:unimarkly/domain/ids.dart';
import 'package:unimarkly/domain/models.dart';
import 'package:unimarkly/domain/scan.dart';
import 'package:unimarkly/features/incoming/incoming_controller.dart';
import 'package:unimarkly/providers/providers.dart';
import 'package:unimarkly/services/incoming/incoming_file.dart';
import 'package:unimarkly/services/incoming/incoming_source.dart';
import 'package:unimarkly/services/incoming/pdf_backend.dart';
import 'package:unimarkly/services/incoming/saved_documents.dart';
import 'package:unimarkly/services/reader/ocr_engine.dart';
import 'package:unimarkly/services/recognition/booklet_pipeline.dart';
import 'package:unimarkly/services/recognition/model_registry.dart';
import 'package:unimarkly/services/scan/image_source.dart';
import 'package:unimarkly/services/scan/intake_service.dart';
import 'package:unimarkly/services/scan/scan_files.dart';

import '../support/file_bundle.dart';
import '../support/images.dart';

/// Photos the buttons "pick" in a test, or an error such as a refused
/// camera permission.
class FakeImageSource implements ImageSource {
  List<PickedImage> next = [];
  Object? error;
  final calls = <String>[];

  Future<List<PickedImage>> _pick(String how) async {
    calls.add(how);
    if (error != null) throw error!;
    final out = next;
    next = [];
    return out;
  }

  @override
  Future<List<PickedImage>> takePhoto(PhotoQuality quality) => _pick('camera');

  @override
  Future<List<PickedImage>> chooseImages(PhotoQuality quality) => _pick('gallery');

  @override
  Future<List<PickedImage>> chooseFiles() => _pick('files');
}

/// Stands in for the operating system handing documents to the app.
class FakeIncomingSource implements IncomingSource {
  final _controller = StreamController<IncomingEvent>.broadcast();

  /// What had arrived before the app could show anything (a cold start).
  final List<IncomingEvent> beforeReady = [];

  @override
  Stream<IncomingEvent> get events => _controller.stream;

  @override
  Future<List<IncomingEvent>> ready() async => [...beforeReady];

  /// A document arriving while the app is open.
  void deliver(IncomingEvent event) => _controller.add(event);
}

/// The phone's PDF engine does not exist in widget tests. This draws a marker
/// instead, and "renders" pages as small image files.
class FakePdfBackend extends PdfBackend {
  FakePdfBackend();

  int pages = 3;
  bool failToOpen = false;
  final viewed = <String>[];

  @override
  Widget view(String path, {required void Function(String message) onError}) {
    viewed.add(path);
    if (failToOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onError('This PDF could not be drawn.'));
    }
    return Center(child: Text('PDF PAGES: $pages'));
  }

  @override
  Future<List<File>> renderPages(
    String path,
    Directory outDir, {
    int maxPages = 40,
    void Function(int done, int total)? onProgress,
  }) async {
    if (failToOpen) throw StateError('cannot open');
    await outDir.create(recursive: true);
    final out = <File>[];
    for (var i = 1; i <= pages; i++) {
      final f = File(p.join(outDir.path, 'page_$i.jpg'));
      await f.writeAsBytes(await makePng(300 + i, 400, ui.Color(0xFF105070 + i * 0x070503)));
      out.add(f);
      onProgress?.call(i, pages);
    }
    return out;
  }
}

/// Runs the real app on an in-memory database.
///
/// Data a test needs up front goes in through `seed`, which runs before the
/// app starts. (Writing from the test body while the app's streams are live
/// would wait on the test's fake clock.) Changes made through the UI work
/// normally.
class AppHarness {
  late AppDatabase db;
  late SharedPreferences prefs;
  late Directory work;
  late ScanFiles scanFiles;
  late SavedDocuments savedDocuments;
  FakeIncomingSource incoming = FakeIncomingSource();
  FakePdfBackend pdf = FakePdfBackend();

  /// What the Take photo / Choose images buttons return in a test.
  final FakeImageSource imageSource = FakeImageSource();

  CourseRepository get courses => CourseRepository(db);
  StudentRepository get students => StudentRepository(db);
  ScoreRepository get scores => ScoreRepository(db);
  ScanRepository get scans => ScanRepository(db, courses);

  Future<void> start(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1.0,
    Map<String, Object> prefsValues = const {},
    Future<void> Function()? seed,

    /// Runs after the app's folders exist and before it starts (for files a
    /// test needs on disk first).
    void Function()? beforeStart,

    /// The bottom-bar tab to open first. Most tests are about courses.
    String? tab = 'Courses',

    /// The text reader. Most tests use the "unavailable" one, so photos wait for
    /// the examiner; the end-to-end test gives it a real model.
    OcrEngine? ocr,
  }) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    SharedPreferences.setMockInitialValues(prefsValues);
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase(NativeDatabase.memory());
    work = Directory.systemTemp.createTempSync('unimarkly_ui_');
    scanFiles = ScanFiles(Directory(p.join(work.path, 'scans')));
    incoming = FakeIncomingSource();
    pdf = FakePdfBackend();
    savedDocuments = SavedDocuments(Directory(p.join(work.path, 'saved_documents')));

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearAllTestValues();
    });

    if (seed != null) await tester.runAsync(seed);
    beforeStart?.call();
    // The real handwriting model, loaded once outside the test's fake clock.
    final digits = await tester.runAsync(() => ModelRegistry.loadDigits(FileAssetBundle()));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        scanFilesProvider.overrideWithValue(scanFiles),
        savedDocumentsProvider.overrideWithValue(savedDocuments),
        incomingSourceProvider.overrideWithValue(incoming),
        pdfBackendProvider.overrideWithValue(pdf),
        // No real reader in widget tests: photos wait for the examiner.
        ocrEngineProvider.overrideWithValue(ocr ?? const UnavailableOcrEngine()),
        imageSourceProvider.overrideWithValue(imageSource),
        recognitionPipelineProvider.overrideWith((ref) async => BookletPipeline(ocr: ref.watch(ocrEngineProvider), digits: digits)),
      ],
      child: const UniMarkLyApp(),
    ));
    await settle(tester);
    if (tab != null) await tapText(tester, tab);
  }

  /// Lets database streams deliver and animations finish.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 15)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Bounded: a screen with a spinner or other endless animation must not
    // hang the test.
    try {
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 3),
      );
    } catch (_) {
      // Still animating; whatever is on screen now is what we check.
    }
  }

  /// Waits (in real time) until no photo is being read or waiting to be read
  /// automatically. The reader runs the real recognition pipeline, which uses
  /// real isolates and so takes real time that the test's fake clock does not.
  ///
  /// Queued photos count as unfinished when reading is automatic, or when
  /// [untilQueueEmpty] says the test itself started the reading.
  Future<void> waitForReading(WidgetTester tester, {Duration limit = const Duration(seconds: 40), bool untilQueueEmpty = false}) async {
    final stop = DateTime.now().add(limit);
    while (DateTime.now().isBefore(stop)) {
      final busy = await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        final auto = untilQueueEmpty || (prefs.getBool('read_automatically') ?? true);
        for (final b in await scans.batches()) {
          if (b.counts.processing > 0 || (auto && b.counts.queued > 0)) return true;
        }
        return false;
      });
      await tester.pump(const Duration(milliseconds: 50));
      if (busy != true) return;
    }
  }

  /// Unmounts the app first and lets the fake clock run, so the providers and
  /// drift's stream clean-up timers fire; only then closes the database.
  Future<void> stop(WidgetTester tester) async {
    await waitForReading(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => db.close().timeout(const Duration(seconds: 5), onTimeout: () {}));
    await tester.pump(const Duration(seconds: 1));
    try {
      work.deleteSync(recursive: true);
    } catch (_) {}
  }

  /// Scrolls the top screen's vertical list, down and then back up, until
  /// [finder] is built.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    final vertical = find.byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.vertical);
    for (final dy in [-240.0, 240.0]) {
      for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
        if (vertical.evaluate().isEmpty) break;
        await tester.drag(vertical.last, Offset(0, dy), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 50));
      }
      if (finder.evaluate().isNotEmpty) break;
    }
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder.first);
      await tester.pump();
    }
  }

  Future<void> tapText(WidgetTester tester, String text, {bool settleAfter = true}) async {
    final finder = find.text(text);
    if (finder.evaluate().isEmpty) await reveal(tester, finder);
    expect(finder, findsAtLeastNWidgets(1), reason: 'looking for "$text"');
    // Scroll it into view, and look again: a list that was still settling can
    // move the widget back out of view after the first attempt.
    for (var i = 0; i < 3; i++) {
      await tester.ensureVisible(finder.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final y = tester.getCenter(finder.first).dy;
      if (y >= 0 && y <= tester.view.physicalSize.height) break;
    }
    await tester.tap(finder.first);
    if (settleAfter) await settle(tester);
  }

  // ---- data for `seed` ----

  static Course makeCourse({String code = 'AGR 114', String department = 'FWM'}) => Course(
        id: newId(),
        code: code,
        department: department,
        session: '2024/2025',
        semester: 'Second',
        scheme: Defaults.nigerianScheme(),
      );

  /// A course with the default scheme and the given students.
  Future<Course> createCourse({
    String code = 'AGR 114',
    String department = 'FWM',
    List<String> regNos = const ['FWM/24U/0538', 'FWM/24U/0539', 'FST/25U/244/5772'],
  }) async {
    final course = makeCourse(code: code, department: department);
    await courses.save(course);
    if (regNos.isNotEmpty) {
      await students.addMany(course.id, [for (final r in regNos) NewStudent(r)]);
    }
    return course;
  }

  /// Writes marks by part index for one student.
  Future<void> setMarks(Course course, Student student, Map<int, double> byPartIndex) async {
    for (final e in byPartIndex.entries) {
      await scores.set(
        course.id,
        ScoreWrite(studentId: student.id, partId: course.scheme.parts[e.key].id, value: e.value),
      );
    }
  }

  int _seeded = 0;

  /// Stores real photo files as one upload of [course], in the given states.
  /// Returns the batch id. Run from `seed`.
  Future<String> seedBatch(
    Course course, {
    String? title,
    List<ScanStatus> states = const [ScanStatus.needsReview],
    int width = 300,
    int height = 400,
  }) async {
    final batchId = await scans.createBatch(course.id, title: title);
    final intake = IntakeService(scans, scanFiles);
    for (var i = 0; i < states.length; i++) {
      final f = File(p.join(work.path, 'seed_${batchId}_$i.png'));
      f.parent.createSync(recursive: true);
      // A different shade each time, so the photos are not duplicates.
      await f.writeAsBytes(await makePng(width + _seeded, height, ui.Color(0xFF203040 + (_seeded++) * 0x050309)));
      final report = await intake.addImages(
        courseId: course.id,
        batchId: batchId,
        images: [PickedImage(name: 'IMG_${1000 + i}.png', path: f.path)],
      );
      if (report.added.length != 1) {
        throw StateError('seedBatch: photo not added: ${report.rejected} ${report.duplicates}');
      }
      await scans.setStatus(report.added.single.id, states[i]);
    }
    return batchId;
  }
}
