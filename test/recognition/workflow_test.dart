import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:unimarkly/data/database/app_database.dart';
import 'package:unimarkly/data/repositories/booklet_repository.dart';
import 'package:unimarkly/data/repositories/course_repository.dart';
import 'package:unimarkly/data/repositories/recognition_repository.dart';
import 'package:unimarkly/data/repositories/scan_repository.dart';
import 'package:unimarkly/data/repositories/score_repository.dart';
import 'package:unimarkly/data/repositories/student_repository.dart';
import 'package:unimarkly/domain/defaults.dart';
import 'package:unimarkly/domain/ids.dart';
import 'package:unimarkly/domain/models.dart';
import 'package:unimarkly/domain/scan.dart';
import 'package:unimarkly/services/export/export_service.dart';
import 'package:unimarkly/services/export/result_table.dart';
import 'package:unimarkly/services/reader/scan_processor.dart';
import 'package:unimarkly/services/recognition/booklet_pipeline.dart';
import 'package:unimarkly/services/recognition/model_registry.dart';
import 'package:unimarkly/services/scan/image_source.dart';
import 'package:unimarkly/services/scan/intake_service.dart';
import 'package:unimarkly/services/scan/scan_files.dart';

import '../support/booklet_photo.dart';
import '../support/process_ocr_engine.dart';

/// A batch through the real processor and the real pipeline, on a database in a
/// file that is closed and reopened (an app restart), with the network
/// forbidden: what is stored, what survives, and what reaches an export.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory work;
  late File dbFile;
  late AppDatabase db;
  late ProcessOcrEngine? ocr;
  late LoadedDigitModel digits;
  late Course course;
  late String batchId;
  late List<ScanItem> photos;

  AppDatabase open() => AppDatabase(NativeDatabase(dbFile));
  ScoreRepository scoresOf(AppDatabase d) => ScoreRepository(d);

  setUpAll(() async {
    digits = await ModelRegistry.loadDigits();
    ocr = await ProcessOcrEngine.tryStart();
  });
  tearDownAll(() async => ocr?.stop());

  setUp(() async {
    work = Directory.systemTemp.createTempSync('unimarkly_workflow_');
    dbFile = File(p.join(work.path, 'app.sqlite'));
    db = open();
    final courses = CourseRepository(db);
    course = Course(id: newId(), code: 'AGR 114', department: 'FWM', scheme: Defaults.nigerianScheme());
    await courses.save(course);
    await StudentRepository(db).addMany(course.id, const [NewStudent('FWM/24U/0538'), NewStudent('FWM/24U/0539')]);
    batchId = await ScanRepository(db, courses).createBatch(course.id);

    // Three photos of the real booklet (slightly different, so none is a
    // duplicate), and a fourth whose file then goes missing.
    final files = ScanFiles(Directory(p.join(work.path, 'scans')));
    final intake = IntakeService(ScanRepository(db, courses), files);
    final picks = <PickedImage>[];
    final bytes = File(bookletPath).readAsBytesSync();
    for (var i = 0; i < 4; i++) {
      final f = File(p.join(work.path, 'IMG_$i.jpg'))..writeAsBytesSync([...bytes, ...List.filled(i * 7 + 1, 0)]);
      picks.add(PickedImage(name: 'IMG_$i.jpg', path: f.path));
    }
    final report = await intake.addImages(courseId: course.id, batchId: batchId, images: picks);
    photos = report.added;
    expect(photos, hasLength(4), reason: '${report.rejected} ${report.duplicates}');
    await files.delete(photos[3].relativePath);
  });

  tearDown(() async {
    try {
      await db.close();
    } catch (_) {}
    work.deleteSync(recursive: true);
  });

  ScanProcessor processor(AppDatabase d) {
    final courses = CourseRepository(d);
    return ScanProcessor(
      scans: ScanRepository(d, courses),
      booklets: BookletRepository(d, scoresOf(d)),
      files: ScanFiles(Directory(p.join(work.path, 'scans'))),
      pipeline: () async => BookletPipeline(ocr: ocr!, digits: digits),
      recognitions: RecognitionRepository(d),
      students: StudentRepository(d),
      courses: courses,
      perPhotoTimeout: const Duration(minutes: 2),
    );
  }

  Future<String> csvOf(AppDatabase d) async {
    final courses = CourseRepository(d);
    final c = (await courses.get(course.id))!;
    final result = await const ExportService().exportCourses(
      courses: [
        CourseExportData(course: c, students: await StudentRepository(d).getAll(c.id), scores: await scoresOf(d).get(c.id)),
      ],
      format: ExportFormat.csv,
      options: ExportOptions.preset(ExportPreset.fullResult, [c.scheme]),
      directory: Directory(p.join(work.path, 'out')),
      inBackground: false,
    );
    expect(result.failures, isEmpty);
    return utf8.decode(File(result.files.single.path).readAsBytesSync());
  }

  void needsStandIn(String name, Future<void> Function() body) {
    test(name, () async {
      if (ocr == null) {
        markTestSkipped('OCR stand-in unavailable (pip install rapidocr-onnxruntime opencv-python-headless)');
      } else {
        await body();
      }
    }, timeout: const Timeout(Duration(minutes: 5)));
  }

  needsStandIn('read, restart, review, confirm, restart, export: only confirmed values reach the export', () async {
    final scans = ScanRepository(db, CourseRepository(db));

    // ---- read the batch, offline ----
    await HttpOverrides.runZoned(
      () => processor(db).processBatch(batchId),
      createHttpClient: (_) => throw StateError('the app tried to use the network'),
    );
    final after = await scans.scansOf(batchId);
    expect(after.where((s) => s.status == ScanStatus.needsReview), hasLength(3));
    final failed = after.singleWhere((s) => s.status == ScanStatus.failed);
    expect(failed.errorMessage, contains('missing'), reason: 'one bad photo is reported, and did not stop the others');
    expect(after.where((s) => s.status == ScanStatus.confirmed), isEmpty);

    // Reading stored a run per photo, and put nothing in the grid.
    final recognitions = RecognitionRepository(db);
    for (final s in after.where((s) => s.status == ScanStatus.needsReview)) {
      final run = await recognitions.latestRun(s.id);
      expect(run, isNotNull);
      expect(run!.result.fields.any((f) => f.key == 'exam_number'), isTrue);
      expect(run.result.models.map((m) => m['id']), contains('unimarkly-digits'));
    }
    expect(await scoresOf(db).get(course.id), isEmpty, reason: 'machine readings never become scores');
    expect(await csvOf(db), isNot(contains('9.5')));

    // ---- restart: close the database and open the file again ----
    final first = after.firstWhere((s) => s.status == ScanStatus.needsReview);
    final runBefore = (await recognitions.latestRun(first.id))!;
    await db.close();
    db = open();
    final scans2 = ScanRepository(db, CourseRepository(db));
    final recognitions2 = RecognitionRepository(db);
    final reopened = await scans2.scansOf(batchId);
    expect(reopened.where((s) => s.status == ScanStatus.needsReview), hasLength(3), reason: 'nothing was lost by the restart');
    final runAfter = (await recognitions2.latestRun(first.id))!;
    expect(runAfter.id, runBefore.id);
    expect(runAfter.result.toJson(), runBefore.result.toJson(), reason: 'the stored evidence is exactly what was produced');

    // ---- the examiner reviews booklet 1 and confirms what the photo shows ----
    final booklets = BookletRepository(db, scoresOf(db));
    final student = (await StudentRepository(db).getAll(course.id)).firstWhere((s) => s.regNo == 'FWM/24U/0538');
    final marks = {1: 1.0, 2: 1.0, 4: 2.0, 5: 5.5};
    final exam = runAfter.result.field('exam_number')!;
    await booklets.confirm(
      scanId: first.id,
      courseId: course.id,
      studentId: student.id,
      serialNo: '292011',
      marks: marks,
      editedMarks: marks.keys.toSet(),
      examScore: 9.5,
      examPartId: course.scheme.examPart!.id,
      photoPath: first.relativePath,
      runId: runAfter.id,
      reviews: [
        FieldReviewDraft(
          fieldKey: 'exam_number',
          kind: 'registration_number',
          machineValue: exam.value ?? (exam.candidates.isEmpty ? null : exam.candidates.first.text),
          machineState: exam.state.dbValue,
          finalValue: student.regNo,
          decision: exam.value == student.regNo ? 'accepted' : (exam.value == null ? 'entered' : 'edited'),
          region: exam.region,
        ),
        for (final e in marks.entries)
          FieldReviewDraft(fieldKey: 'mark_q${e.key}', kind: 'mark', finalValue: '${e.value}', decision: 'entered', region: runAfter.result.layout.marksRegion),
      ],
    );

    // ---- export: only the confirmed booklet's score is there ----
    final csv = await csvOf(db);
    expect(csv, contains('FWM/24U/0538'));
    expect(csv, contains('9.5'));
    expect((await scoresOf(db).get(course.id)).length, 1, reason: 'one student has a score; the two unconfirmed booklets have none');

    // ---- restart again: the confirmed record and the decisions survive ----
    await db.close();
    db = open();
    final stored = (await BookletRepository(db, scoresOf(db)).forScan(first.id))!;
    expect(stored.confirmed, isTrue);
    expect(stored.marks, marks);
    final reviews = await RecognitionRepository(db).reviewsOf(first.id);
    expect(reviews.map((r) => r.fieldKey), containsAll(['exam_number', 'mark_q1', 'mark_q5']));
    expect(reviews.every((r) => r.runId == runAfter.id), isTrue);
    final examples = await RecognitionRepository(db).labelledExamples();
    expect(examples.map((e) => e.fieldKey), containsAll(['exam_number', 'mark_q5']));
    expect(examples.firstWhere((e) => e.fieldKey == 'mark_q5').text, '5.5');
    expect(await csvOf(db), contains('9.5'));

    // Reading the photo again can not undo what the examiner confirmed.
    await ScanRepository(db, CourseRepository(db)).setStatus(first.id, ScanStatus.queued);
    await processor(db).processBatch(batchId);
    final again = (await BookletRepository(db, scoresOf(db)).forScan(first.id))!;
    expect(again.confirmed, isTrue);
    expect(again.marks, marks);
  });

  needsStandIn('a written total that disagrees with the marks is stored as the examiner entered it: validation never rewrites a mark', () async {
    await processor(db).processBatch(batchId);
    final first = (await ScanRepository(db, CourseRepository(db)).scansOf(batchId)).firstWhere((s) => s.status == ScanStatus.needsReview);
    final student = (await StudentRepository(db).getAll(course.id)).firstWhere((s) => s.regNo == 'FWM/24U/0538');
    final marks = {1: 10.0, 2: 8.0, 3: 20.0}; // adds to 38
    await BookletRepository(db, scoresOf(db)).confirm(
      scanId: first.id,
      courseId: course.id,
      studentId: student.id,
      serialNo: null,
      marks: marks,
      editedMarks: marks.keys.toSet(),
      examScore: 38,
      examPartId: course.scheme.examPart!.id,
      photoPath: first.relativePath,
    );
    final stored = (await BookletRepository(db, scoresOf(db)).forScan(first.id))!;
    expect(stored.marks, marks, reason: 'a total of 36 on the cover would have been reported, never applied');
  });
}
