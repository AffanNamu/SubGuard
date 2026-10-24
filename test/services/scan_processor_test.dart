import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

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
import 'package:unimarkly/domain/ocr.dart';
import 'package:unimarkly/domain/scan.dart';
import 'package:unimarkly/services/reader/booklet_extractor.dart';
import 'package:unimarkly/services/reader/ocr_engine.dart';
import 'package:unimarkly/services/reader/scan_processor.dart';
import 'package:unimarkly/services/recognition/booklet_pipeline.dart';
import 'package:unimarkly/services/recognition/model_registry.dart';
import 'package:unimarkly/services/scan/image_source.dart';
import 'package:unimarkly/services/scan/intake_service.dart';
import 'package:unimarkly/services/scan/scan_files.dart';

import '../support/images.dart';

/// An engine that also reads a close-up of one region.
class FakeRegionEngine extends FakeEngine implements RegionOcrEngine {
  FakeRegionEngine(super.respond, this.crop);
  final Future<OcrDocument> Function() crop;
  final regions = <Region>[];

  @override
  Future<OcrDocument> recognizeRegion(File image, Region region) {
    regions.add(region);
    return crop();
  }
}

/// An engine that returns a fixed document, or throws, or never answers.
class FakeEngine implements OcrEngine {
  FakeEngine(this.respond);
  final Future<OcrDocument> Function() respond;
  int calls = 0;

  @override
  String get name => 'fake';

  @override
  Future<OcrDocument> recognize(File image, {required int width, required int height}) {
    calls++;
    return respond();
  }
}

OcrDocument sampleDocument() {
  final j = jsonDecode(File('test/fixtures/sample_booklet_ocr.json').readAsStringSync()) as Map<String, dynamic>;
  return OcrDocument(engine: 'sample', lines: [
    for (final l in (j['lines'] as List).cast<Map<String, dynamic>>())
      OcrLine(
        l['text'] as String,
        Region((l['left'] as num).toDouble(), (l['top'] as num).toDouble(), (l['right'] as num).toDouble(),
            (l['bottom'] as num).toDouble()),
        confidence: (l['confidence'] as num).toDouble(),
      ),
  ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late CourseRepository courses;
  late ScanRepository scans;
  late BookletRepository booklets;
  late RecognitionRepository recognitions;
  late LoadedDigitModel digits;
  late ScoreRepository scores;
  late StudentRepository students;
  late ScanFiles files;
  late IntakeService intake;
  late Directory work;
  late Course course;
  late String batchId;

  setUpAll(() async => digits = await ModelRegistry.loadDigits());

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    courses = CourseRepository(db);
    scans = ScanRepository(db, courses);
    scores = ScoreRepository(db);
    students = StudentRepository(db);
    booklets = BookletRepository(db, scores);
    recognitions = RecognitionRepository(db);
    work = Directory.systemTemp.createTempSync('unimarkly_proc_');
    files = ScanFiles(Directory(p.join(work.path, 'scans')));
    intake = IntakeService(scans, files);
    course = Course(id: newId(), code: 'AGR 114', department: 'FWM', scheme: Defaults.nigerianScheme());
    await courses.save(course);
    await students.addMany(course.id, const [NewStudent('FWM/24U/0538'), NewStudent('FWM/24U/0539')]);
    batchId = await scans.createBatch(course.id);
  });

  tearDown(() async {
    await db.close();
    work.deleteSync(recursive: true);
  });

  /// The real processor and the real pipeline (real quality analysis, layout,
  /// marks stage, digit model), reading text through a fake engine.
  ScanProcessor processor(OcrEngine engine, {Duration timeout = const Duration(seconds: 30)}) => ScanProcessor(
        scans: scans,
        booklets: booklets,
        files: files,
        pipeline: () async => BookletPipeline(ocr: engine, digits: digits),
        recognitions: recognitions,
        students: students,
        courses: courses,
        perPhotoTimeout: timeout,
      );

  Future<List<ScanItem>> addPhotos(int n) async {
    final picks = <PickedImage>[];
    for (var i = 0; i < n; i++) {
      final f = File(p.join(work.path, 'IMG_00$i.png'));
      await f.writeAsBytes(await makePng(100 + i, 140, ui.Color(0xFF000000 + i * 40)));
      picks.add(PickedImage(name: 'IMG_00$i.png', path: f.path));
    }
    return (await intake.addImages(courseId: course.id, batchId: batchId, images: picks)).added;
  }

  group('reading a batch', () {
    test('every queued photo becomes a record waiting for review, each tracked on its own', () async {
      final photos = await addPhotos(3);
      final engine = FakeEngine(() async => sampleDocument());
      final progress = <String>[];
      await processor(engine).processBatch(batchId, onProgress: (d, t) => progress.add('$d/$t'));

      expect(engine.calls, 3);
      expect(progress, ['0/3', '1/3', '2/3', '3/3'], reason: 'progress is real, not animated');
      for (final photo in photos) {
        final item = (await scans.scan(photo.id))!;
        expect(item.status, ScanStatus.needsReview, reason: 'nothing is confirmed by reading');
        final b = (await booklets.forScan(photo.id))!;
        expect(b.scanId, photo.id);
        expect(b.reading.serialNo, '292011');
        expect(b.engine, 'sample');
        expect(b.confirmed, isFalse);
        expect(b.studentId, isNull, reason: 'a student is only attached when the examiner confirms');
      }
    });

    test('reads the exam number close up and matches it to the class list', () async {
      final photo = (await addPhotos(1)).single;
      final engine = FakeRegionEngine(
        () async => sampleDocument(),
        // A shaky reading of the handwriting: O for 0.
        () async => const OcrDocument(engine: 'crop', lines: [OcrLine('FWM/24U/O538', Region(0, 0.1, 1, 0.9), confidence: 0.55)]),
      );
      await processor(engine).processBatch(batchId);

      // The exam-number area is re-read close up in two picture variants (tight and
      // a little wider), plus a close-up of the printed booklet number.
      final examAreas = engine.regions.where((r) => r.top > 0.1 && r.top < 0.2).toList();
      expect(examAreas, hasLength(2), reason: 'tight and wide close-ups of the exam-number area');
      expect(examAreas.last.width, greaterThan(examAreas.first.width));
      final reading = (await booklets.forScan(photo.id))!.reading;
      expect(reading.examNumberSuggestion, 'FWM/24U/0538');
      expect(reading.examNumberOnClassList, isTrue);
      expect((await scans.scan(photo.id))!.status, ScanStatus.needsReview, reason: 'still needs the examiner to confirm');
    });

    test('a close-up that fails leaves the field empty for the examiner and the photo still goes to review', () async {
      final photo = (await addPhotos(1)).single;
      final engine = FakeRegionEngine(() async => sampleDocument(), () async => throw StateError('plugin crashed'));
      await processor(engine).processBatch(batchId);
      final reading = (await booklets.forScan(photo.id))!.reading;
      expect(reading.examNumberSuggestion, isNull);
      expect(reading.serialNo, '292011');
      expect((await scans.scan(photo.id))!.status, ScanStatus.needsReview);
    });

    test('keeps the engine output with the record, so a reading can be traced', () async {
      final photo = (await addPhotos(1)).single;
      await processor(FakeEngine(() async => sampleDocument())).processBatch(batchId);
      final row = await (db.select(db.booklets)..where((b) => b.scanId.equals(photo.id))).getSingle();
      final json = jsonDecode(row.readJson!) as Map<String, dynamic>;
      expect(json['engine'], 'sample');
      expect((json['ocr'] as Map)['lines'], isNotEmpty);
      expect((json['reading'] as Map)['serialNo'], '292011');
    });

    test('an engine that throws leaves the photo for manual entry, with the reason', () async {
      final photo = (await addPhotos(1)).single;
      await processor(FakeEngine(() async => throw StateError('boom'))).processBatch(batchId);
      expect((await scans.scan(photo.id))!.status, ScanStatus.needsReview);
      final b = (await booklets.forScan(photo.id))!;
      expect(b.reading.warnings.single, contains('Automatic reading failed'));
      expect(b.reading.serialNo, isNull, reason: 'nothing is invented');
    });

    test('an engine that never answers is stopped', () async {
      final photo = (await addPhotos(1)).single;
      final never = FakeEngine(() => Completer<OcrDocument>().future);
      await processor(never, timeout: const Duration(milliseconds: 50)).processBatch(batchId);
      expect((await scans.scan(photo.id))!.status, ScanStatus.needsReview);
      expect((await booklets.forScan(photo.id))!.reading.warnings.single, contains('too long'));
    });

    test('a device with no reading says so plainly and invents nothing', () async {
      final photo = (await addPhotos(1)).single;
      await processor(const UnavailableOcrEngine()).processBatch(batchId);
      final b = (await booklets.forScan(photo.id))!;
      expect(b.reading.warnings.single, contains('not available on this device'));
      expect(b.reading.serialNo, isNull);
      expect(b.reading.examNumberSuggestion, isNull);
      expect(b.marks, isEmpty);
    });

    test('a missing file is a failure with advice, not a crash', () async {
      final photo = (await addPhotos(1)).single;
      await files.delete(photo.relativePath);
      await processor(FakeEngine(() async => sampleDocument())).processBatch(batchId);
      final item = (await scans.scan(photo.id))!;
      expect(item.status, ScanStatus.failed);
      expect(item.errorMessage, contains('missing'));
    });

    test('pausing stops after the photo in hand and leaves the rest queued', () async {
      await addPhotos(3);
      var reads = 0;
      final engine = FakeEngine(() async {
        reads++;
        return sampleDocument();
      });
      await processor(engine).processBatch(batchId, shouldStop: () => reads >= 1);
      final all = await scans.scansOf(batchId);
      expect(all.where((s) => s.status == ScanStatus.needsReview), hasLength(1));
      expect(all.where((s) => s.status == ScanStatus.queued), hasLength(2));
    });

    test('photos already read are not read again', () async {
      await addPhotos(2);
      final engine = FakeEngine(() async => sampleDocument());
      await processor(engine).processBatch(batchId);
      await processor(engine).processBatch(batchId);
      expect(engine.calls, 2);
    });
  });

  group('confirming', () {
    Future<ScanItem> readOne() async {
      final photo = (await addPhotos(1)).single;
      await processor(FakeEngine(() async => sampleDocument())).processBatch(batchId);
      return photo;
    }

    Future<String> studentId(String reg) async =>
        (await students.getAll(course.id)).firstWhere((s) => s.regNo == reg).id;

    test('the brief sample: marks 1.0 + 1.0 + 2.0 + 5.5 give an exam score of 9.5 in the grid', () async {
      final photo = await readOne();
      final sid = await studentId('FWM/24U/0538');
      final examPart = course.scheme.examPart!;

      await booklets.confirm(
        scanId: photo.id,
        courseId: course.id,
        studentId: sid,
        serialNo: '292011',
        marks: const {1: 1.0, 2: 1.0, 4: 2.0, 5: 5.5},
        editedMarks: const {1, 2, 4, 5},
        examScore: 9.5,
        examPartId: examPart.id,
        photoPath: photo.relativePath,
      );

      final b = (await booklets.forScan(photo.id))!;
      expect(b.confirmed, isTrue);
      expect(b.studentId, sid);
      expect(b.marks, {1: 1.0, 2: 1.0, 4: 2.0, 5: 5.5});
      expect((await scans.scan(photo.id))!.status, ScanStatus.confirmed);

      final grid = await scores.get(course.id);
      expect(grid[sid]![examPart.id]!.value, 9.5);
      final row = await (db.select(db.partScores)..where((s) => s.studentId.equals(sid))).getSingle();
      expect(row.source, 'scanned');
    });

    test('keeps a record of every value the examiner changed from what was read', () async {
      final photo = await readOne();
      await booklets.confirm(
        scanId: photo.id,
        courseId: course.id,
        studentId: await studentId('FWM/24U/0538'),
        serialNo: '292017',
        marks: const {1: 4},
        editedMarks: const {1},
        examScore: 4,
        examPartId: course.scheme.examPart!.id,
        photoPath: photo.relativePath,
        corrections: [
          const CorrectionDraft(
              field: 'serial_no', readValue: '292011', confirmedValue: '292017', region: Region(0.6, 0.06, 0.74, 0.1)),
        ],
      );
      final c = await db.select(db.corrections).getSingle();
      expect(c.field, 'serial_no');
      expect(c.readValue, '292011');
      expect(c.confirmedValue, '292017');
      expect(c.cropPath, photo.relativePath);
      expect(Region.decode(c.region)!.left, closeTo(0.6, 1e-3));
    });

    test('reading the photo again can not undo a confirmed record', () async {
      final photo = await readOne();
      final sid = await studentId('FWM/24U/0538');
      await booklets.confirm(
        scanId: photo.id,
        courseId: course.id,
        studentId: sid,
        serialNo: '292011',
        marks: const {1: 7},
        editedMarks: const {1},
        examScore: 7,
        examPartId: course.scheme.examPart!.id,
        photoPath: photo.relativePath,
      );

      // Force it back into the queue and read it again with a different result.
      await scans.setStatus(photo.id, ScanStatus.queued);
      await processor(FakeEngine(() async => const OcrDocument(engine: 'other', lines: []))).processBatch(batchId);

      final b = (await booklets.forScan(photo.id))!;
      expect(b.confirmed, isTrue);
      expect(b.marks, {1: 7});
      expect(b.engine, 'sample', reason: 'the verified record was left alone');
      expect((await scores.get(course.id))[sid]![course.scheme.examPart!.id]!.value, 7);
    });

    test('confirming again replaces the marks rather than adding to them', () async {
      final photo = await readOne();
      final sid = await studentId('FWM/24U/0538');
      Future<void> confirmWith(Map<int, double> marks, double total) => booklets.confirm(
            scanId: photo.id,
            courseId: course.id,
            studentId: sid,
            serialNo: '292011',
            marks: marks,
            editedMarks: marks.keys.toSet(),
            examScore: total,
            examPartId: course.scheme.examPart!.id,
            photoPath: photo.relativePath,
          );
      await confirmWith(const {1: 5, 2: 5}, 10);
      await booklets.reopen(photo.id);
      expect((await scans.scan(photo.id))!.status, ScanStatus.needsReview);
      expect((await scores.get(course.id))[sid]![course.scheme.examPart!.id]!.value, 10,
          reason: 'the grid keeps the confirmed score until it is confirmed again');
      await confirmWith(const {1: 6}, 6);
      expect((await booklets.forScan(photo.id))!.marks, {1: 6});
      expect((await scores.get(course.id))[sid]![course.scheme.examPart!.id]!.value, 6);
    });

    test('finds the same student, or the same printed booklet, already confirmed', () async {
      final first = await readOne();
      final sid = await studentId('FWM/24U/0538');
      await booklets.confirm(
        scanId: first.id,
        courseId: course.id,
        studentId: sid,
        serialNo: '292011',
        marks: const {1: 7},
        editedMarks: const {1},
        examScore: 7,
        examPartId: course.scheme.examPart!.id,
        photoPath: first.relativePath,
      );
      expect((await booklets.confirmedFor(course.id, sid))!.scanId, first.id);
      expect(await booklets.confirmedFor(course.id, sid, exceptScanId: first.id), isNull);
      expect((await booklets.confirmedWithSerial(course.id, '292011'))!.scanId, first.id);
      expect(await booklets.confirmedWithSerial(course.id, '999999'), isNull);
      expect(await booklets.confirmedFor(course.id, await studentId('FWM/24U/0539')), isNull);
    });
  });

  group('ML Kit box handling', () {
    test('boxes become fractions of the photo', () {
      final lines = MlKitOcrEngine.normaliseBoxes(const [RawOcrLine('Total', 100, 200, 300, 250, 0.9)], 1000, 2000);
      expect(lines.single.box.left, closeTo(0.1, 1e-9));
      expect(lines.single.box.bottom, closeTo(0.125, 1e-9));
      expect(lines.single.confidence, 0.9);
    });

    test('a rotated photo is detected when the boxes only fit the swapped size', () {
      // Stored as 4000 wide x 3000 high, but the engine saw it upright (3000 x 4000).
      final lines = MlKitOcrEngine.normaliseBoxes(const [RawOcrLine('x', 100, 100, 2900, 3900, null)], 4000, 3000);
      expect(lines.single.box.right, closeTo(2900 / 3000, 1e-9));
      expect(lines.single.box.bottom, closeTo(3900 / 4000, 1e-9));
    });

    test('nothing read gives no lines, and an unknown size does not divide by zero', () {
      expect(MlKitOcrEngine.normaliseBoxes(const [], 100, 100), isEmpty);
      expect(MlKitOcrEngine.normaliseBoxes(const [RawOcrLine('x', 1, 1, 2, 2, null)], 0, 0), isEmpty);
    });
  });

  test('an interrupted app does not lose a photo: it is queued again and then read', () async {
    final photo = (await addPhotos(1)).single;
    await scans.setStatus(photo.id, ScanStatus.processing); // the app was closed mid-read
    expect(await scans.requeueInterrupted(), 1);
    await processor(FakeEngine(() async => sampleDocument())).processBatch(batchId);
    expect((await scans.scan(photo.id))!.status, ScanStatus.needsReview);
  });

  test('the extractor is the real one: the sample gives printed anchors and no invented handwriting', () async {
    final photo = (await addPhotos(1)).single;
    await processor(FakeEngine(() async => sampleDocument())).processBatch(batchId);
    final r = (await booklets.forScan(photo.id))!.reading;
    expect(r.marksRegion, isNotNull);
    expect(r.examNumberSuggestion, isNull);
    expect(const BookletExtractor().extract(sampleDocument()).serialNo, r.serialNo);
  });
}
