import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart' as mlkit;

import '../../domain/ocr.dart';

/// Reads the text in a photo. An interface so the processor, the extractor and
/// the tests do not depend on a phone's native text-recognition plugin.
abstract class OcrEngine {
  String get name;

  /// [width] and [height] are the photo's size in pixels, used to turn the
  /// engine's pixel boxes into fractions of the photo.
  Future<OcrDocument> recognize(File image, {required int width, required int height});
}

/// An engine that can also read one part of a photo close up. Handwriting is
/// read far better when the part is cut out and enlarged than when it is a
/// small corner of a whole-page photo.
abstract class RegionOcrEngine implements OcrEngine {
  /// Reads only [region] (fractions of the photo). Boxes in the result are
  /// fractions of that region.
  Future<OcrDocument> recognizeRegion(File image, Region region);
}

/// For platforms with no text recognition (desktop, web, most tests). It says
/// so plainly instead of pretending to read, and the examiner enters the values
/// from the photo.
class UnavailableOcrEngine implements OcrEngine {
  const UnavailableOcrEngine();

  @override
  String get name => 'none';

  @override
  Future<OcrDocument> recognize(File image, {required int width, required int height}) async =>
      const OcrDocument(
        engine: 'none',
        lines: [],
        note: 'Automatic reading is not available on this device. Enter the values from the photo.',
      );
}

/// Google ML Kit text recognition, running on the phone with no internet. It
/// reads printed text well. It does not read handwriting reliably, so
/// handwritten values are only ever offered as suggestions.
class MlKitOcrEngine implements RegionOcrEngine {
  const MlKitOcrEngine();

  @override
  String get name => 'Google ML Kit text recognition (on-device, Latin)';

  @override
  Future<OcrDocument> recognize(File image, {required int width, required int height}) async {
    final recognizer = mlkit.TextRecognizer(script: mlkit.TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(mlkit.InputImage.fromFile(image));
      final raw = <RawOcrLine>[
        for (final block in result.blocks)
          for (final line in block.lines)
            RawOcrLine(
              line.text,
              line.boundingBox.left,
              line.boundingBox.top,
              line.boundingBox.right,
              line.boundingBox.bottom,
              line.confidence,
            ),
      ];
      return OcrDocument(engine: name, lines: normaliseBoxes(raw, width, height));
    } finally {
      await recognizer.close();
    }
  }

  @override
  Future<OcrDocument> recognizeRegion(File image, Region region) async {
    final crop = await cropForReading(image, region);
    if (crop == null) return OcrDocument(engine: name, lines: const []);
    final recognizer = mlkit.TextRecognizer(script: mlkit.TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(mlkit.InputImage.fromFile(crop.file));
      final raw = <RawOcrLine>[
        for (final block in result.blocks)
          for (final line in block.lines)
            RawOcrLine(line.text, line.boundingBox.left, line.boundingBox.top, line.boundingBox.right,
                line.boundingBox.bottom, line.confidence),
      ];
      return OcrDocument(engine: name, lines: normaliseBoxes(raw, crop.width, crop.height));
    } finally {
      await recognizer.close();
      try {
        await crop.file.parent.delete(recursive: true);
      } catch (_) {}
    }
  }

  /// Cuts [region] out of the photo, enlarges it so the writing is at least
  /// ~220 px tall, and boosts the contrast of the pen strokes. The stored
  /// original is never touched; the cut-out is a temporary file.
  static Future<({File file, int width, int height})?> cropForReading(File image, Region region) async {
    final codec = await ui.instantiateImageCodec(await image.readAsBytes());
    final frame = await codec.getNextFrame();
    final src = frame.image;
    try {
      final r = region.clamped();
      final sx = r.left * src.width, sy = r.top * src.height;
      final sw = (r.right - r.left) * src.width, sh = (r.bottom - r.top) * src.height;
      if (sw < 8 || sh < 8) return null;
      final scale = math.min(math.max(1.0, 220 / sh), 2400 / sw);
      final w = (sw * scale).round(), h = (sh * scale).round();

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), ui.Paint()..color = const ui.Color(0xFFFFFFFF));
      canvas.drawImageRect(
        src,
        ui.Rect.fromLTWH(sx, sy, sw, sh),
        ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        ui.Paint()
          ..filterQuality = ui.FilterQuality.high
          // Grey, with the contrast raised 1.5x around mid-grey.
          ..colorFilter = const ui.ColorFilter.matrix(<double>[
            0.675, 0.675, 0.15, 0, -64, //
            0.675, 0.675, 0.15, 0, -64,
            0.675, 0.675, 0.15, 0, -64,
            0, 0, 0, 1, 0,
          ]),
      );
      final out = await recorder.endRecording().toImage(w, h);
      final bytes = await out.toByteData(format: ui.ImageByteFormat.png);
      out.dispose();
      if (bytes == null) return null;
      final dir = await Directory.systemTemp.createTemp('unimarkly_crop_');
      final file = File('${dir.path}/crop.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      return (file: file, width: w, height: h);
    } finally {
      src.dispose();
    }
  }

  /// Turns pixel boxes into fractions of the photo.
  ///
  /// A phone photo can carry a rotation flag, in which case the engine reports
  /// boxes in the upright photo while the stored size is the sensor's. If the
  /// boxes do not fit the stored size but fit the swapped one, the width and
  /// height are swapped.
  static List<OcrLine> normaliseBoxes(List<RawOcrLine> raw, int width, int height) {
    if (raw.isEmpty || width <= 0 || height <= 0) return const [];
    final maxRight = raw.map((l) => l.right).reduce(math.max);
    final maxBottom = raw.map((l) => l.bottom).reduce(math.max);
    var w = width.toDouble(), h = height.toDouble();
    final fits = maxRight <= w * 1.02 && maxBottom <= h * 1.02;
    final fitsSwapped = maxRight <= h * 1.02 && maxBottom <= w * 1.02;
    if (!fits && fitsSwapped) {
      final t = w;
      w = h;
      h = t;
    }
    return [
      for (final l in raw)
        OcrLine(
          l.text,
          Region(l.left / w, l.top / h, l.right / w, l.bottom / h).clamped(),
          confidence: l.confidence,
        ),
    ];
  }
}

/// A line exactly as the engine reported it, in pixels.
class RawOcrLine {
  const RawOcrLine(this.text, this.left, this.top, this.right, this.bottom, this.confidence);
  final String text;
  final double left, top, right, bottom;
  final double? confidence;
}

OcrEngine defaultOcrEngine() =>
    (Platform.isAndroid || Platform.isIOS) ? const MlKitOcrEngine() : const UnavailableOcrEngine();
