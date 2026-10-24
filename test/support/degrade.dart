import 'dart:math' as math;
import 'dart:typed_data';

import 'package:unimarkly/services/vision/geometry.dart';
import 'package:unimarkly/services/vision/raster.dart';

/// Controlled damage applied to a good photograph, so each vision stage can be
/// measured against what is known to have been done to it. Every variant is
/// derived from one source photograph; these measure stage behaviour, they are
/// not independent test documents.
class Degrade {
  const Degrade._();

  /// Gaussian blur of [sigma] pixels.
  static ColorRaster blur(ColorRaster src, double sigma) => ColorRaster.fromPlanes([
        for (var c = 0; c < 3; c++) src.channel(c).gaussian(sigma),
        Raster.filled(src.width, src.height, 255),
      ]);

  /// Multiplies the image by a smooth shade running from 1 on the left to
  /// [dark] on the right, as a shadow across the page does.
  static ColorRaster shadow(ColorRaster src, double dark) {
    final out = Uint8List.fromList(src.rgba);
    for (var y = 0; y < src.height; y++) {
      for (var x = 0; x < src.width; x++) {
        final k = 1 - (1 - dark) * (x / (src.width - 1));
        final p = (y * src.width + x) * 4;
        out[p] = (out[p] * k).round();
        out[p + 1] = (out[p + 1] * k).round();
        out[p + 2] = (out[p + 2] * k).round();
      }
    }
    return ColorRaster(src.width, src.height, out);
  }

  /// Pulls every channel toward mid-grey: [keep] 1 is unchanged, 0.4 is faint.
  static ColorRaster lowContrast(ColorRaster src, double keep) {
    final out = Uint8List.fromList(src.rgba);
    for (var i = 0; i < out.length; i += 4) {
      for (var c = 0; c < 3; c++) {
        out[i + c] = (128 + (out[i + c] - 128) * keep).round().clamp(0, 255);
      }
    }
    return ColorRaster(src.width, src.height, out);
  }

  /// Brightness scaled by [k] (below 1 is under-exposed, above 1 over-exposed).
  static ColorRaster exposure(ColorRaster src, double k) {
    final out = Uint8List.fromList(src.rgba);
    for (var i = 0; i < out.length; i += 4) {
      for (var c = 0; c < 3; c++) {
        out[i + c] = (out[i + c] * k).round().clamp(0, 255);
      }
    }
    return ColorRaster(src.width, src.height, out);
  }

  /// Adds Gaussian noise with a seeded generator, so the test is repeatable.
  static ColorRaster noise(ColorRaster src, double sigma, {int seed = 7}) {
    final rnd = math.Random(seed);
    final out = Uint8List.fromList(src.rgba);
    for (var i = 0; i < out.length; i += 4) {
      final n = _gauss(rnd) * sigma;
      for (var c = 0; c < 3; c++) {
        out[i + c] = (out[i + c] + n).round().clamp(0, 255);
      }
    }
    return ColorRaster(src.width, src.height, out);
  }

  /// A bright oval of glare with its centre at fractions [cx], [cy].
  static ColorRaster glare(ColorRaster src, double cx, double cy, double radiusFraction) {
    final out = Uint8List.fromList(src.rgba);
    final r = radiusFraction * math.max(src.width, src.height);
    for (var y = 0; y < src.height; y++) {
      for (var x = 0; x < src.width; x++) {
        final d = math.sqrt(math.pow(x - cx * src.width, 2) + math.pow(y - cy * src.height, 2));
        if (d < r) {
          final k = 1 - d / r;
          final p = (y * src.width + x) * 4;
          for (var c = 0; c < 3; c++) {
            out[p + c] = (out[p + c] + (255 - out[p + c]) * math.min(1, k * 2.2)).round();
          }
        }
      }
    }
    return ColorRaster(src.width, src.height, out);
  }

  /// Puts the photo on a larger canvas, warped so its corners land on [corners]
  /// (top-left, top-right, bottom-right, bottom-left, in canvas pixels). The
  /// canvas outside the page is a dull green table with a little texture.
  /// Returns the picture and the transform from photo pixels to canvas pixels.
  static ({ColorRaster image, Homography photoToCanvas}) place(
    ColorRaster photo,
    int canvasW,
    int canvasH,
    List<Pt> corners, {
    List<int> background = const [40, 90, 55],
    int seed = 3,
  }) {
    final src = [const Pt(0, 0), Pt(photo.width.toDouble(), 0), Pt(photo.width.toDouble(), photo.height.toDouble()), Pt(0, photo.height.toDouble())];
    final h = Homography.fromPoints(src, corners)!;
    final inv = h.inverse()!;
    final rnd = math.Random(seed);
    final out = Uint8List(canvasW * canvasH * 4);
    final planes = [for (var c = 0; c < 3; c++) photo.channel(c)];
    for (var y = 0; y < canvasH; y++) {
      for (var x = 0; x < canvasW; x++) {
        final s = inv.apply(Pt(x + 0.5, y + 0.5));
        final p = (y * canvasW + x) * 4;
        if (s.x >= 0 && s.y >= 0 && s.x <= photo.width - 1 && s.y <= photo.height - 1) {
          for (var c = 0; c < 3; c++) {
            out[p + c] = planes[c].sampleBilinear(s.x, s.y).round();
          }
        } else {
          final n = (rnd.nextDouble() - 0.5) * 18;
          for (var c = 0; c < 3; c++) {
            out[p + c] = (background[c] + n).round().clamp(0, 255);
          }
        }
        out[p + 3] = 255;
      }
    }
    return (image: ColorRaster(canvasW, canvasH, out), photoToCanvas: h);
  }

  static double _gauss(math.Random r) {
    final u = 1 - r.nextDouble(), v = r.nextDouble();
    return math.sqrt(-2 * math.log(u)) * math.cos(2 * math.pi * v);
  }
}
