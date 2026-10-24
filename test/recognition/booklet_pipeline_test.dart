import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:unimarkly/domain/ocr.dart';
import 'package:unimarkly/domain/recognition.dart';
import 'package:unimarkly/services/reader/ocr_engine.dart';
import 'package:unimarkly/services/recognition/booklet_pipeline.dart';
import 'package:unimarkly/services/recognition/interfaces.dart' show RecognitionCancelled, RecognitionException, RecognitionResult;
import 'package:unimarkly/services/recognition/model_registry.dart';

import '../support/booklet_photo.dart';
import '../support/process_ocr_engine.dart';

/// The pipeline on the real booklet photograph, with the real digit network and
/// a real PP-OCR model standing in for the phone's PaddleOCR.
///
/// These tests state what must be true of ANY reading (nothing handwritten is
/// auto-accepted, evidence is kept, a failed reader is reported, not hidden).
/// They do not assert that a particular mark was read correctly: one photograph
/// that the pipeline was developed on says nothing about accuracy. Accuracy is
/// measured, with denominators, by the benchmark (docs/recognition/BENCHMARK.md).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const classList = ['FWM/24U/0538', 'FWM/24U/0539'];
  ProcessOcrEngine? ocr;
  late LoadedDigitModel digits;
  late RecognitionResult result;
  var wall = Duration.zero;

  setUpAll(() async {
    digits = await ModelRegistry.loadDigits();
    ocr = await ProcessOcrEngine.tryStart();
    if (ocr == null) return;
    final sw = Stopwatch()..start();
    // No network is available to the pipeline: any attempt to open one fails the run.
    result = await HttpOverrides.runZoned(
      () => BookletPipeline(ocr: ocr!, digits: digits).run(File(bookletPath), classList: classList),
      createHttpClient: (_) => throw StateError('the recognition pipeline tried to use the network'),
    );
    wall = sw.elapsed;
  });

  tearDownAll(() async => ocr?.stop());

  void needsStandIn(String name, FutureOr<void> Function() body) {
    test(name, () async {
      if (ocr == null) {
        markTestSkipped('OCR stand-in unavailable (pip install rapidocr-onnxruntime opencv-python-headless)');
      } else {
        await body();
      }
    });
  }

  group('a real booklet photograph', () {
    needsStandIn('runs offline, end to end, and reports its stages', () {
      expect(result.fields, isNotEmpty);
      expect(result.timingsMs.keys, containsAll(['decode', 'quality', 'printed_text', 'closeups', 'marks', 'validation']));
      expect(wall.inSeconds, lessThan(60));
    });

    needsStandIn('no handwritten field is ever "recognized" or given a calibrated confidence', () {
      for (final f in result.fields) {
        expect(f.calibratedConfidence, isNull, reason: '${f.key} has a calibrated confidence but no calibration exists');
        if (f.kind.isHandwritten && f.key != 'total_written') {
          expect(f.state, isNot(FieldState.recognized), reason: '${f.key} was auto-accepted: ${f.value}');
        }
      }
    });

    needsStandIn('zero false acceptances: a field marked recognized with a value matches the ground truth', () {
      final truth = {
        'serial_no': '292011',
      };
      for (final f in result.fields) {
        if (f.state == FieldState.recognized && f.value != null) {
          expect(truth[f.key], f.value, reason: '${f.key} was accepted as ${f.value}');
        }
      }
    });

    needsStandIn('the blank Total box is seen as blank, not read as a number', () {
      final total = result.field('total_written')!;
      expect(total.value, isNull);
      expect(total.warnings.join(' '), contains('blank'));
    });

    needsStandIn('the picture is judged: small text and a cropped page are reported with advice', () {
      final q = result.quality!;
      expect(q.issues.map((i) => i.code), containsAll(['text_small', 'cropped']));
      expect(q.issues.every((i) => i.advice.isNotEmpty), isTrue);
    });

    needsStandIn('the marks table gives rows with a mark and a question each, and every one needs checking', () {
      final marks = result.fields.where((f) => f.key.startsWith('mark_row_')).toList();
      final questions = result.fields.where((f) => f.key.startsWith('question_row_')).toList();
      expect(marks.length, inInclusiveRange(4, 6), reason: 'four rows are written; a stray mark may add one');
      expect(questions.length, marks.length);
      for (final f in [...marks, ...questions]) {
        expect(f.state, anyOf(FieldState.needsReview, FieldState.unreadable));
      }
    });

    needsStandIn('every reading keeps its evidence: where it is, which reader, which picture variant, and the other candidates', () {
      for (final f in result.fields.where((f) => f.value != null)) {
        expect(f.region, isNotNull, reason: '${f.key} has no place on the photo');
        expect(f.attempts, isNotEmpty, reason: '${f.key} has no record of what read it');
        for (final a in f.attempts) {
          expect(a.reader, isNotEmpty);
          expect(a.variant, isNotEmpty);
        }
      }
      final exam = result.field('exam_number')!;
      expect(exam.attempts.length, greaterThanOrEqualTo(2), reason: 'the exam number is read in more than one picture variant');
    });

    needsStandIn('class-list help is a candidate with a note, and never the reading itself', () {
      final exam = result.field('exam_number')!;
      for (final c in exam.candidates.where((c) => c.source.startsWith('class_list'))) {
        expect(c.note, isNotNull, reason: 'a class-list candidate must say how it was reached');
      }
      // value is only ever what was read from the picture.
      if (exam.value != null) {
        expect(exam.candidates.any((c) => c.text == exam.value && !c.source.startsWith('class_list')), isTrue);
      }
    });

    needsStandIn('the models used are listed with their versions', () {
      final ids = result.models.map((m) => m['id']);
      expect(ids, containsAll(['ocr', 'unimarkly-digits', 'unimarkly-pipeline']));
      expect(result.models.firstWhere((m) => m['id'] == 'unimarkly-digits')['sha256'], digits.info.sha256);
    });
  });

  group('failure handling', () {
    test('a missing photo is refused with words an examiner can act on', () async {
      final pipeline = BookletPipeline(ocr: const UnavailableOcrEngine(), digits: digits);
      await expectLater(
        pipeline.run(File('/no/such/photo.jpg')),
        throwsA(isA<RecognitionException>().having((e) => e.message, 'message', contains('missing'))),
      );
    });

    test('a file that is not a picture is refused', () async {
      final dir = Directory.systemTemp.createTempSync('pipeline_bad_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final f = File(p.join(dir.path, 'x.jpg'))..writeAsStringSync('this is not an image');
      await expectLater(
        BookletPipeline(ocr: const UnavailableOcrEngine(), digits: digits).run(f),
        throwsA(isA<RecognitionException>()),
      );
    });

    test('an oversized file is refused before it is decoded', () async {
      final pipeline = BookletPipeline(ocr: const UnavailableOcrEngine(), digits: digits, limits: const PipelineLimits(maxFileBytes: 1000));
      await expectLater(
        pipeline.run(File(bookletPath)),
        throwsA(isA<RecognitionException>().having((e) => e.message, 'message', contains('too large'))),
      );
    });

    test('cancelling stops the run', () async {
      final pipeline = BookletPipeline(ocr: const UnavailableOcrEngine(), digits: digits);
      await expectLater(pipeline.run(File(bookletPath), isCancelled: () => true), throwsA(isA<RecognitionCancelled>()));
    });

    test('a text reader that fails leaves the fields failed or unreadable, with a note, and does not throw', () async {
      final r = await BookletPipeline(ocr: _FailingOcr(), digits: digits).run(File(bookletPath));
      expect(r.notes.join(' '), contains('text reader failed'));
      expect(r.field('serial_no')!.state, FieldState.failed);
      expect(r.fields.every((f) => f.state != FieldState.recognized || f.value == null), isTrue);
    });

    test('a missing handwriting model is a failed marks field with the reason: no quiet fallback', () async {
      final r = await BookletPipeline(
        ocr: const _LabelsOcr(),
        digits: null,
        digitsError: 'The handwriting model is missing from this install of the app. Reinstall UniMarkLy, or enter the marks by hand.',
      ).run(File(bookletPath));
      expect(r.fields.where((f) => f.key.startsWith('mark_row_')), isEmpty);
      final failed = r.field('mark_rows');
      expect(failed?.state, FieldState.failed);
      expect(failed?.warnings.join(' '), contains('missing from this install'));
    });

    test('variants that were tried and read nothing are still in the record', () async {
      // A reader that finds no text at all: the exam number has no reading, but the
      // record still shows which picture variants were tried.
      final r = await BookletPipeline(ocr: const _LabelsRegionOcr(), digits: digits).run(File(bookletPath));
      final exam = r.field('exam_number')!;
      expect(exam.attempts.map((a) => a.variant), containsAll(['closeup', 'closeup_wide', 'whole_photo']));
      expect(exam.attempts.every((a) => a.text == null), isTrue);
      expect(exam.value, isNull);
    });

    test('a text reader that is too slow times out into a note, not a hang', () async {
      final r = await BookletPipeline(
        ocr: _SlowOcr(),
        digits: digits,
        limits: const PipelineLimits(ocrTimeout: Duration(milliseconds: 50)),
      ).run(File(bookletPath));
      expect(r.notes.join(' '), contains('took too long'));
    });
  });
}

class _FailingOcr implements OcrEngine {
  @override
  String get name => 'failing';
  @override
  Future<OcrDocument> recognize(File image, {required int width, required int height}) async => throw StateError('native crash');
}

class _SlowOcr implements OcrEngine {
  @override
  String get name => 'slow';
  @override
  Future<OcrDocument> recognize(File image, {required int width, required int height}) => Completer<OcrDocument>().future;
}

/// Finds the three printed labels the layout needs, so the marks stage has a
/// region, and nothing else. Used only to test the "model missing" path.
class _LabelsOcr implements OcrEngine {
  const _LabelsOcr();
  @override
  String get name => 'labels';
  @override
  Future<OcrDocument> recognize(File image, {required int width, required int height}) async => const OcrDocument(engine: 'labels', lines: [
        OcrLine('Marks', Region(0.78, 0.30, 0.88, 0.33), confidence: 0.9),
        OcrLine('Question', Region(0.64, 0.30, 0.74, 0.33), confidence: 0.9),
        OcrLine('Total', Region(0.66, 0.84, 0.76, 0.88), confidence: 0.9),
      ]);
}

/// Finds the label the exam number hangs on and nothing else, and reads nothing
/// in any close-up.
class _LabelsRegionOcr implements RegionOcrEngine {
  const _LabelsRegionOcr();
  @override
  String get name => 'labels';
  @override
  Future<OcrDocument> recognize(File image, {required int width, required int height}) async => const OcrDocument(engine: 'labels', lines: [
        OcrLine("Candidate's Examination Number:", Region(0.05, 0.15, 0.40, 0.19), confidence: 0.9),
      ]);
  @override
  Future<OcrDocument> recognizeRegion(File image, Region region) async => const OcrDocument(engine: 'labels', lines: []);
}
