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

  /// The redness of the paper around each pixel: a blurred copy of the redness
  /// picture with every pixel held within a few levels of the typical (median)
  /// redness first. Pen strokes, dark print and the table under the page are
  /// far from the median, so clamping keeps them from dragging the paper level
  /// towards themselves (a blue pen would otherwise make the paper look red).
  static Raster _paperRedness(Raster redness, double sigmaFraction) {
    final median = redness.percentile(0.5);
    final held = Raster(redness.width, redness.height);
    for (var i = 0; i < held.data.length; i++) {
      held.data[i] = redness.data[i].clamp(median - 12, median + 12);
    }
    return held.gaussian(math.max(3, math.max(redness.width, redness.height) * sigmaFraction));
  }

  /// How much redder each pixel is than the paper around it, 0..255, by colour
  /// alone. Phone JPEGs store colour at half the resolution of brightness
  /// (and in blocks), so this map is coarse and blocky; use it to decide
  /// *where* red ink is, and [redInk] for its shape.
  static Raster redChroma(ColorRaster c, {double sigmaFraction = 0.25}) {
    final w = c.width, h = c.height;
    final redness = Raster(w, h);
    // Offset so negative values (blue-green) survive in 8 bits.
    for (var i = 0, p = 0; i < w * h; i++, p += 4) {
      final r = c.rgba[p] - (c.rgba[p + 1] + c.rgba[p + 2]) / 2;
      redness.data[i] = (r + 128).round().clamp(0, 255);
    }
    final bg = _paperRedness(redness, sigmaFraction);
    final out = Raster(w, h);
    for (var i = 0; i < w * h; i++) {
      out.data[i] = ((redness.data[i] - bg.data[i]) * 4).round().clamp(0, 255);
    }
    return out;
  }

  /// The strokes of a red pen: brightness gives their crisp shape and colour
  /// says which strokes are red.
  ///
  /// Dark strokes (the pen's shadow in the brightness picture) are kept only
  /// where the colour is redder than the paper around it, with the colour
  /// picture softened because its resolution is lower. That removes the
  /// printed form (ruled lines and text are dark but not red) while keeping
  /// the pen's real outline. On the one real booklet photo this was the
  /// difference between unreadable blocks and clean digits; see
  /// docs/recognition/AUDIT.md.
  static Raster redInk(ColorRaster c, {double sigmaFraction = 0.25}) {
    final w = c.width, h = c.height;
    final dark = darkInk(c.toGray(), sigmaFraction: sigmaFraction);
    final red = Raster(w, h);
    for (var i = 0, p = 0; i < w * h; i++, p += 4) {
      final r = c.rgba[p] - (c.rgba[p + 1] + c.rgba[p + 2]) / 2;
      red.data[i] = (r + 128).round().clamp(0, 255);
    }
    final bg = _paperRedness(red, sigmaFraction);
    // Redder than the paper by at least ~9 levels (the paper's own level is not
    // quite zero, because the pen pulls the local average towards red).
    final isRed = Raster(w, h);
    for (var i = 0; i < isRed.data.length; i++) {
      isRed.data[i] = (red.data[i] - bg.data[i]) >= 9 ? 255 : 0;
    }
    // A pixel counts as red ink when red is common around it (within about one
    // chroma block); the picture's brightness, not its colour, then gives the
    // stroke its shape.
    final near = isRed.boxBlur(3);
    final out = Raster(w, h);
    for (var i = 0; i < out.data.length; i++) {
      final k = (near.data[i] / 255 * 2).clamp(0.0, 1.0);
      out.data[i] = (dark.data[i] * k).round();
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
      EnhancedVariant('red_ink', 'Red pen only, shaped by brightness', asDarkOnLight(redInk(color))),
      EnhancedVariant('red_chroma', 'Red pen only, by colour alone', asDarkOnLight(redChroma(color))),
      EnhancedVariant('dark_ink', 'Dark ink only', asDarkOnLight(darkInk(gray))),
    ];
  }
}
