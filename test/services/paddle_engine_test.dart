import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/domain/ocr.dart';
import 'package:unimarkly/services/reader/ocr_engine.dart';
import 'package:unimarkly/services/reader/paddle_ocr_engine.dart';

class _Engine implements RegionOcrEngine {
  _Engine(this.name, {this.fail = false});

  @override
  final String name;
  final bool fail;
  int whole = 0, region = 0;

  @override
  Future<OcrDocument> recognize(File image, {required int width, required int height}) async {
    whole++;
    if (fail) throw StateError('native crash');
    return OcrDocument(engine: name, lines: const [OcrLine('x', Region(0, 0, 1, 1))]);
  }

  @override
  Future<OcrDocument> recognizeRegion(File image, Region region) async {
    this.region++;
    if (fail) throw StateError('native crash');
    return OcrDocument(engine: name, lines: const [OcrLine('crop', Region(0, 0, 1, 1))]);
  }
}

/// An engine that can only read a whole photo.
class _WholeOnly implements OcrEngine {
  @override
  String get name => 'whole-only';

  @override
  Future<OcrDocument> recognize(File image, {required int width, required int height}) async =>
      const OcrDocument(engine: 'whole-only', lines: [OcrLine('w', Region(0, 0, 1, 1))]);
}

void main() {
  group('PaddleOCR results become lines of fractions, top to bottom', () {
    test('converts pixel boxes and orders them by row then column', () {
      final lines = PaddleOcrEngine.toLines(
        const [
          PaddleLine('second row', 0.9, 100, 500, 400, 540),
          PaddleLine('right', 0.8, 600, 100, 800, 140),
          PaddleLine('left', 0.7, 100, 100, 300, 140),
        ],
        800,
        1000,
      );
      expect(lines.map((l) => l.text), ['left', 'right', 'second row']);
      expect(lines.first.box.left, closeTo(0.125, 1e-9));
      expect(lines.first.box.top, closeTo(0.1, 1e-9));
      expect(lines.first.box.right, closeTo(0.375, 1e-9));
      expect(lines.first.box.bottom, closeTo(0.14, 1e-9));
      expect(lines.first.confidence, 0.7);
    });

    test('a photo the phone stores sideways is turned the right way round', () {
      // Boxes that fit the swapped size, as with a rotation flag.
      final lines = PaddleOcrEngine.toLines(const [PaddleLine('a', 0.9, 100, 100, 1000, 200)], 800, 1200);
      expect(lines.single.box.right, lessThanOrEqualTo(1.0));
    });

    test('nothing read is an empty list', () {
      expect(PaddleOcrEngine.toLines(const [], 800, 1000), isEmpty);
    });
  });

  group('falling back to ML Kit', () {
    final file = File('unused.jpg');

    test('uses the first reader when it works', () async {
      final a = _Engine('paddle'), b = _Engine('mlkit');
      final doc = await FallbackOcrEngine(a, b).recognize(file, width: 10, height: 10);
      expect(doc.engine, 'paddle');
      expect(b.whole, 0);
    });

    test('reads with the second when the first fails, so reading never stops working', () async {
      final a = _Engine('paddle', fail: true), b = _Engine('mlkit');
      final doc = await FallbackOcrEngine(a, b).recognize(file, width: 10, height: 10);
      expect(doc.engine, 'mlkit');
      expect(a.whole, 1);
    });

    test('the close-up also falls back, and ends empty when nobody can do it', () async {
      final a = _Engine('paddle', fail: true), b = _Engine('mlkit');
      final doc = await FallbackOcrEngine(a, b).recognizeRegion(file, const Region(0, 0, 1, 1));
      expect(doc.engine, 'mlkit');

      final none = await FallbackOcrEngine(_Engine('paddle', fail: true), _WholeOnly())
          .recognizeRegion(file, const Region(0, 0, 1, 1));
      expect(none.lines, isEmpty);
    });
  });
}
