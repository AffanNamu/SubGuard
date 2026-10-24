import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/domain/ocr.dart';
import 'package:unimarkly/services/reader/ocr_engine.dart';
import 'package:unimarkly/services/reader/paddle_ocr_engine.dart';
import 'package:unimarkly/services/recognition/booklet_pipeline.dart';
import 'package:unimarkly/services/recognition/model_registry.dart';

import '../support/booklet_photo.dart';

/// A reader that cannot run is replaced by a weaker one, and that is said, not hidden.
class _Broken implements RegionOcrEngine {
  @override
  String get name => 'Main reader';
  @override
  Future<OcrDocument> recognize(File image, {required int width, required int height}) async => throw StateError('no native library');
  @override
  Future<OcrDocument> recognizeRegion(File image, Region region) async => throw StateError('no native library');
}

class _Weak implements RegionOcrEngine {
  @override
  String get name => 'Weak reader';
  @override
  Future<OcrDocument> recognize(File image, {required int width, required int height}) async =>
      const OcrDocument(engine: 'Weak reader', lines: [OcrLine('292011', Region(0.64, 0.06, 0.74, 0.1), confidence: 0.9)]);
  @override
  Future<OcrDocument> recognizeRegion(File image, Region region) async => const OcrDocument(engine: 'Weak reader', lines: []);
}

class _Fine extends _Weak {
  @override
  String get name => 'Fine reader';
  @override
  Future<OcrDocument> recognize(File image, {required int width, required int height}) async => const OcrDocument(engine: 'Fine reader', lines: []);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final file = File('x.jpg');

  test('a working main reader is used with no note', () async {
    final d = await FallbackOcrEngine(_Fine(), _Weak()).recognize(file, width: 100, height: 100);
    expect(d.engine, 'Fine reader');
    expect(d.note, isNull);
  });

  test('when the main reader cannot run, the weaker one is used and the document says so', () async {
    final d = await FallbackOcrEngine(_Broken(), _Weak()).recognize(file, width: 100, height: 100);
    expect(d.engine, 'Weak reader');
    expect(d.lines, isNotEmpty);
    expect(d.note, allOf(contains('Main reader'), contains('could not run'), contains('Weak reader'), contains('printed text only')));
  });

  test('the same holds for close-up readings', () async {
    final d = await FallbackOcrEngine(_Broken(), _Weak()).recognizeRegion(file, const Region(0, 0, 1, 1));
    expect(d.note, contains('could not run'));
  });

  test('the pipeline passes it on to the examiner as a note on the result', () async {
    final digits = await ModelRegistry.loadDigits();
    final r = await BookletPipeline(ocr: FallbackOcrEngine(_Broken(), _Weak()), digits: digits).run(File(bookletPath));
    expect(r.notes.join(' '), contains('could not run on this phone'));
    expect(r.printed.engine, 'Weak reader');
    expect(r.models.firstWhere((m) => m['id'] == 'ocr')['name'], 'Weak reader', reason: 'the models list names the reader that actually read');
  });
}
