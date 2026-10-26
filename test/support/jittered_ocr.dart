import 'dart:io';

import 'package:unimarkly/domain/ocr.dart';
import 'package:unimarkly/services/reader/ocr_engine.dart';

import 'process_ocr_engine.dart';

/// The real text reader, with every box it returns moved a little: [dx] and [dy] are added
/// to the box coordinates and [sx], [sy] scale them (all as fractions of the picture).
///
/// A different version of the reader, or the same one on a different processor, finds the
/// printed labels a few pixels away from where another does. The table of marks is cut out
/// relative to those labels, so this is how a test asks "does the result survive the table
/// being cut out slightly differently?" without a second reader to hand.
class JitteredOcr implements RegionOcrEngine {
  JitteredOcr(this.inner, {this.dx = 0, this.dy = 0, this.sx = 1, this.sy = 1});

  final ProcessOcrEngine inner;
  final double dx, dy, sx, sy;

  @override
  String get name => inner.name;

  OcrDocument _moved(OcrDocument d) => OcrDocument(
        engine: d.engine,
        note: d.note,
        lines: [
          for (final l in d.lines)
            OcrLine(
              l.text,
              Region(l.box.left * sx + dx, l.box.top * sy + dy, l.box.right * sx + dx, l.box.bottom * sy + dy),
              confidence: l.confidence,
            ),
        ],
      );

  @override
  Future<OcrDocument> recognize(File image, {required int width, required int height}) async =>
      _moved(await inner.recognize(image, width: width, height: height));

  @override
  Future<OcrDocument> recognizeRegion(File image, Region region) async => _moved(await inner.recognizeRegion(image, region));
}
