import 'dart:io';

import 'package:paddle_ocr_native/paddle_ocr_native.dart' as paddle;

import '../../domain/ocr.dart';
import 'ocr_engine.dart';
import 'region_crop.dart';

/// One piece of text as PaddleOCR reports it: pixel corners in the image it
/// was given.
class PaddleLine {
  const PaddleLine(this.text, this.confidence, this.left, this.top, this.right, this.bottom);

  final String text;
  final double confidence;
  final double left, top, right, bottom;
}

/// PaddleOCR (PP-OCR text detection and recognition) running on the phone, with
/// no internet. It reads printed text like ML Kit does and reads handwriting
/// noticeably better, so it is the first choice; ML Kit takes over if it can
/// not start (an unsupported phone, for example).
///
/// The handwritten exam number is read from a close-up of its area. Handwriting
/// is still read imperfectly, so every value it produces is a suggestion the
/// examiner sees and can change.
class PaddleOcrEngine implements RegionOcrEngine {
  PaddleOcrEngine({paddle.PaddleOcr? ocr}) : _ocr = ocr ?? paddle.PaddleOcr();

  final paddle.PaddleOcr _ocr;
  Future<void>? _ready;

  /// Detection thresholds are a little looser than the defaults: handwriting
  /// strokes are thinner than print, so they score lower. Tested against a
  /// real booklet photo with the same models.
  static const config = paddle.PaddleOcrConfig(detBoxThresh: 0.5, detLimitSideLen: 1280);

  @override
  String get name => 'PaddleOCR (on-device)';

  Future<void> _init() => _ready ??= _ocr.init(config: config).catchError((Object e) {
        _ready = null; // try again next time
        throw e;
      });

  @override
  Future<OcrDocument> recognize(File image, {required int width, required int height}) async {
    await _init();
    final run = await _ocr.recognize(image.path);
    return OcrDocument(engine: name, lines: toLines(_lines(run), width, height));
  }

  @override
  Future<OcrDocument> recognizeRegion(File image, Region region) async {
    await _init();
    // Colour, not grey-and-contrast: the colour crop was read better.
    final crop = await cropForReading(image, region, boostContrast: false, maxWidth: 1280);
    if (crop == null) return OcrDocument(engine: name, lines: const []);
    try {
      final run = await _ocr.recognize(crop.file.path);
      return OcrDocument(engine: name, lines: toLines(_lines(run), crop.width, crop.height));
    } finally {
      try {
        await crop.file.parent.delete(recursive: true);
      } catch (_) {}
    }
  }

  static List<PaddleLine> _lines(paddle.OcrRunResult run) => [
        for (final r in run.results)
          if (r.text.trim().isNotEmpty)
            PaddleLine(r.text, r.confidence, r.boundingBox.left, r.boundingBox.top, r.boundingBox.right,
                r.boundingBox.bottom),
      ];

  /// Turns pixel boxes into fractions of the image, reading top to bottom, left
  /// to right. Shares the rotation handling with the ML Kit reader.
  static List<OcrLine> toLines(List<PaddleLine> lines, int width, int height) {
    final ordered = [...lines]..sort((a, b) {
        final byRow = a.top.compareTo(b.top);
        return byRow != 0 ? byRow : a.left.compareTo(b.left);
      });
    return MlKitOcrEngine.normaliseBoxes(
      [for (final l in ordered) RawOcrLine(l.text, l.left, l.top, l.right, l.bottom, l.confidence)],
      width,
      height,
    );
  }
}

/// Tries [primary]; if it throws (not installed, unsupported phone, native
/// crash), the same photo is read by [fallback], so reading never stops working.
class FallbackOcrEngine implements RegionOcrEngine {
  FallbackOcrEngine(this.primary, this.fallback);

  final OcrEngine primary;
  final OcrEngine fallback;

  @override
  String get name => primary.name;

  @override
  Future<OcrDocument> recognize(File image, {required int width, required int height}) async {
    try {
      return await primary.recognize(image, width: width, height: height);
    } catch (_) {
      return fallback.recognize(image, width: width, height: height);
    }
  }

  @override
  Future<OcrDocument> recognizeRegion(File image, Region region) async {
    final first = primary;
    if (first is RegionOcrEngine) {
      try {
        return await first.recognizeRegion(image, region);
      } catch (_) {}
    }
    final second = fallback;
    if (second is RegionOcrEngine) return second.recognizeRegion(image, region);
    return const OcrDocument(engine: 'none', lines: []);
  }
}
