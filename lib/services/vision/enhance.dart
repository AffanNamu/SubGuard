import 'dart:math' as math;
import 'dart:typed_data';

import 'raster.dart';

/// One prepared version of a region, with how it was made. Different
/// preparations help different writing; when they disagree about a character,
/// the character is sent for review instead of one of them being trusted.
class EnhancedVariant {
  const EnhancedVariant(this.id, this.description, this.image);

  final String id;
  final String description;

  /// Grey picture, dark ink on light paper (the usual convention for readers).
  final Raster image;
}

/// Preparations of a photograph region. All of them keep the geometry: the
/// output has the input's size, so a position in a variant is a position in the
/// original. None invents detail; they only change contrast and remove colour.
class Enhancer {
  const Enhancer._();

  /// Removes shadows and paper tint by dividing by a heavily blurred copy.
  static Raster flatten(Raster gray, {double sigmaFraction = 0.12}) {
    final bg = gray.gaussian(math.max(3, math.max(gray.width, gray.height) * sigmaFraction));
    final out = Raster(gray.width, gray.height);
    for (var i = 0; i < out.data.length; i++) {
      out.data[i] = (gray.data[i] / math.max(1, bg.data[i]) * 215).round().clamp(0, 255);
    }
    return out;
  }

  /// Sauvola local thresholding: 0 for ink, 255 for paper. Adapts to uneven
  /// light because the threshold follows the local mean and spread.
  static Raster sauvola(Raster gray, {int window = 25, double k = 0.2}) {
    final w = gray.width, h = gray.height;
    final integral = Float64List((w + 1) * (h + 1)), integralSq = Float64List((w + 1) * (h + 1));
    for (var y = 0; y < h; y++) {
      var row = 0.0, rowSq = 0.0;
      for (var x = 0; x < w; x++) {
        final v = gray.data[y * w + x].toDouble();
        row += v;
        rowSq += v * v;
        integral[(y + 1) * (w + 1) + x + 1] = integral[y * (w + 1) + x + 1] + row;
        integralSq[(y + 1) * (w + 1) + x + 1] = integralSq[y * (w + 1) + x + 1] + rowSq;
      }
    }
    final out = Raster(w, h);
    final r = window ~/ 2;
    for (var y = 0; y < h; y++) {
      final y0 = math.max(0, y - r), y1 = math.min(h, y + r + 1);
      for (var x = 0; x < w; x++) {
        final x0 = math.max(0, x - r), x1 = math.min(w, x + r + 1);
        final n = (x1 - x0) * (y1 - y0);
        final s = integral[y1 * (w + 1) + x1] - integral[y0 * (w + 1) + x1] - integral[y1 * (w + 1) + x0] + integral[y0 * (w + 1) + x0];
        final sq = integralSq[y1 * (w + 1) + x1] - integralSq[y0 * (w + 1) + x1] - integralSq[y1 * (w + 1) + x0] + integralSq[y0 * (w + 1) + x0];
        final mean = s / n;
        final sd = math.sqrt(math.max(0, sq / n - mean * mean));
        final thr = mean * (1 + k * (sd / 128 - 1));
        out.data[y * w + x] = gray.data[y * w + x] <= thr ? 0 : 255;
      }
    }
    return out;
  }

  /// How much redder each pixel is than the paper around it, 0..255. Red and
  /// orange pen strokes light up; the blue-green form, printed text and ruled
  /// lines (which are less red than paper) are zero.
  static Raster redInk(ColorRaster c, {double sigmaFraction = 0.25}) {
    final w = c.width, h = c.height;
    final redness = Raster(w, h);
    // Offset so negative values (blue-green) survive in 8 bits.
    for (var i = 0, p = 0; i < w * h; i++, p += 4) {
      final r = c.rgba[p] - (c.rgba[p + 1] + c.rgba[p + 2]) / 2;
      redness.data[i] = (r + 128).round().clamp(0, 255);
    }
    final bg = redness.gaussian(math.max(3, math.max(w, h) * sigmaFraction));
    final out = Raster(w, h);
    for (var i = 0; i < w * h; i++) {
      out.data[i] = ((redness.data[i] - bg.data[i]) * 4).round().clamp(0, 255);
    }
    return out;
  }

  /// How much darker each pixel is than the paper around it, 0..255 (black,
  /// blue and grey pen, pencil, print).
  static Raster darkInk(Raster gray, {double sigmaFraction = 0.25}) {
    final bg = gray.gaussian(math.max(3, math.max(gray.width, gray.height) * sigmaFraction));
    final out = Raster(gray.width, gray.height);
    for (var i = 0; i < out.data.length; i++) {
      out.data[i] = ((bg.data[i] - gray.data[i]) * 3).round().clamp(0, 255);
    }
    return out;
  }

  /// An ink-strength map as a reader's picture: dark strokes on white.
  static Raster asDarkOnLight(Raster ink) {
    final out = Raster(ink.width, ink.height);
    final top = math.max(24, ink.percentile(0.995));
    for (var i = 0; i < out.data.length; i++) {
      out.data[i] = 255 - (ink.data[i] * 255 / top).round().clamp(0, 255);
    }
    return out;
  }

  /// The variants tried for a region of handwriting, from [color].
  static List<EnhancedVariant> variantsFor(ColorRaster color) {
    final gray = color.toGray();
    return [
      EnhancedVariant('gray', 'Grey, unchanged', gray),
      EnhancedVariant('flat', 'Shadows and paper tint removed', flatten(gray)),
      EnhancedVariant('sauvola', 'Black and white, adaptive threshold', sauvola(gray)),
      EnhancedVariant('red_ink', 'Red pen only', asDarkOnLight(redInk(color))),
      EnhancedVariant('dark_ink', 'Dark ink only', asDarkOnLight(darkInk(gray))),
    ];
  }
}
