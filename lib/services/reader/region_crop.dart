import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import '../../domain/ocr.dart';

/// Cuts [region] out of the photo and enlarges it so the writing is at least
/// ~220 px tall. With [boostContrast] the pen strokes are darkened (helps
/// some readers, hurts others, so the engine chooses). The stored original is
/// never touched; the cut-out is a temporary file the caller deletes. It is
/// no wider than [maxWidth] pixels.
Future<({File file, int width, int height})?> cropForReading(
  File image,
  Region region, {
  required bool boostContrast,
  int maxWidth = 2400,
}) async {
  final codec = await ui.instantiateImageCodec(await image.readAsBytes());
  final frame = await codec.getNextFrame();
  final src = frame.image;
  try {
    final r = region.clamped();
    final sx = r.left * src.width, sy = r.top * src.height;
    final sw = (r.right - r.left) * src.width, sh = (r.bottom - r.top) * src.height;
    if (sw < 8 || sh < 8) return null;
    final scale = math.min(math.max(1.0, 220 / sh), maxWidth / sw);
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
        ..colorFilter = !boostContrast
            ? null
            : const ui.ColorFilter.matrix(<double>[
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

