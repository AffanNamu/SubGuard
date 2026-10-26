import 'dart:math' as math;
import 'dart:typed_data';

/// An 8-bit grey image. The vision stages work on these plain arrays, not on
/// `dart:ui` images, so they can run in a background isolate and be tested
/// without an engine.
class Raster {
  Raster(this.width, this.height, [Uint8List? data]) : data = data ?? Uint8List(width * height) {
    assert(this.data.length == width * height);
  }

  factory Raster.filled(int width, int height, int value) => Raster(width, height, Uint8List(width * height)..fillRange(0, width * height, value));

  final int width;
  final int height;
  final Uint8List data;

  int at(int x, int y) => data[y * width + x];

  /// Pixel with the position clamped into the image.
  int atClamped(int x, int y) => data[y.clamp(0, height - 1) * width + x.clamp(0, width - 1)];

  Raster copy() => Raster(width, height, Uint8List.fromList(data));

  Raster crop(int left, int top, int right, int bottom) {
    final l = left.clamp(0, width), t = top.clamp(0, height);
    final r = right.clamp(l, width), b = bottom.clamp(t, height);
    final out = Raster(r - l, b - t);
    for (var y = t; y < b; y++) {
      out.data.setRange((y - t) * out.width, (y - t + 1) * out.width, data, y * width + l);
    }
    return out;
  }

  /// Shrinks by averaging the covered pixels (so thin strokes are not lost) and
  /// enlarges with bilinear interpolation.
  Raster resized(int newWidth, int newHeight) {
    if (newWidth == width && newHeight == height) return copy();
    final out = Raster(newWidth, newHeight);
    final sx = width / newWidth, sy = height / newHeight;
    if (sx > 1 || sy > 1) {
      for (var y = 0; y < newHeight; y++) {
        final y0 = (y * sy).floor(), y1 = math.max(y0 + 1, ((y + 1) * sy).ceil()).clamp(0, height);
        for (var x = 0; x < newWidth; x++) {
          final x0 = (x * sx).floor(), x1 = math.max(x0 + 1, ((x + 1) * sx).ceil()).clamp(0, width);
          var sum = 0, n = 0;
          for (var yy = y0; yy < y1; yy++) {
            final row = yy * width;
            for (var xx = x0; xx < x1; xx++) {
              sum += data[row + xx];
              n++;
            }
          }
          out.data[y * newWidth + x] = n == 0 ? 0 : (sum / n).round();
        }
      }
    } else {
      for (var y = 0; y < newHeight; y++) {
        final fy = (y + 0.5) * sy - 0.5;
        for (var x = 0; x < newWidth; x++) {
          out.data[y * newWidth + x] = sampleBilinear((x + 0.5) * sx - 0.5, fy).round().clamp(0, 255);
        }
      }
    }
    return out;
  }

  /// Bilinear sample at a fractional position; outside the image is the edge.
  double sampleBilinear(double x, double y) {
    final x0 = x.floor(), y0 = y.floor();
    final fx = x - x0, fy = y - y0;
    final a = atClamped(x0, y0), b = atClamped(x0 + 1, y0);
    final c = atClamped(x0, y0 + 1), d = atClamped(x0 + 1, y0 + 1);
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy;
  }

  /// Box blur with the given radius, edges clamped.
  Raster boxBlur(int radius) {
    if (radius <= 0) return copy();
    // 32 bits: a row sum is up to (2r+1) x 255, which overflows 16 bits once
    // the radius passes 128, and the large blurs used to estimate paper and
    // lighting are far wider than that on a real photograph.
    final tmp = Int32List(width * height);
    final w = 2 * radius + 1;
    // horizontal
    for (var y = 0; y < height; y++) {
      final row = y * width;
      var sum = 0;
      for (var i = -radius; i <= radius; i++) {
        sum += data[row + i.clamp(0, width - 1)];
      }
      for (var x = 0; x < width; x++) {
        tmp[row + x] = sum;
        sum += data[row + (x + radius + 1).clamp(0, width - 1)] - data[row + (x - radius).clamp(0, width - 1)];
      }
    }
    final out = Raster(width, height);
    // vertical
    for (var x = 0; x < width; x++) {
      var sum = 0;
      for (var i = -radius; i <= radius; i++) {
        sum += tmp[i.clamp(0, height - 1) * width + x];
      }
      for (var y = 0; y < height; y++) {
        out.data[y * width + x] = (sum / (w * w)).round();
        sum += tmp[(y + radius + 1).clamp(0, height - 1) * width + x] - tmp[(y - radius).clamp(0, height - 1) * width + x];
      }
    }
    return out;
  }

  /// A close approximation of a Gaussian blur: three box blurs.
  Raster gaussian(double sigma) {
    if (sigma <= 0.3) return copy();
    // Width of the ideal box filter for three passes.
    final wIdeal = math.sqrt(12 * sigma * sigma / 3 + 1);
    var wl = wIdeal.floor();
    if (wl.isEven) wl--;
    final wu = wl + 2;
    final m = ((12 * sigma * sigma - 3 * wl * wl - 12 * wl - 9) / (-4 * wl - 4)).round();
    var r = this;
    for (var i = 0; i < 3; i++) {
      r = r.boxBlur(((i < m ? wl : wu) - 1) ~/ 2);
    }
    return r;
  }

  /// A 3x3 rotation-free sample set used by several metrics.
  double mean() {
    var s = 0;
    for (final v in data) {
      s += v;
    }
    return s / data.length;
  }

  /// The value below which [fraction] of the pixels fall (0..1).
  int percentile(double fraction) {
    final hist = histogram();
    final target = fraction * data.length;
    var acc = 0;
    for (var i = 0; i < 256; i++) {
      acc += hist[i];
      if (acc >= target) return i;
    }
    return 255;
  }

  List<int> histogram() {
    final h = List<int>.filled(256, 0);
    for (final v in data) {
      h[v]++;
    }
    return h;
  }

  /// Otsu's threshold: the grey level that best separates dark from light.
  int otsu() {
    final hist = histogram();
    final total = data.length;
    var sum = 0.0;
    for (var i = 0; i < 256; i++) {
      sum += i * hist[i];
    }
    var sumB = 0.0, wB = 0, best = 0;
    var maxVar = -1.0;
    for (var t = 0; t < 256; t++) {
      wB += hist[t];
      if (wB == 0) continue;
      final wF = total - wB;
      if (wF == 0) break;
      sumB += t * hist[t];
      final mB = sumB / wB, mF = (sum - sumB) / wF;
      final between = wB.toDouble() * wF * (mB - mF) * (mB - mF);
      if (between > maxVar) {
        maxVar = between;
        best = t;
      }
    }
    return best;
  }

  /// 0 or 255 per pixel; pixels at or below [threshold] are dark (255 = ink).
  Raster inkMask(int threshold) {
    final out = Raster(width, height);
    for (var i = 0; i < data.length; i++) {
      out.data[i] = data[i] <= threshold ? 255 : 0;
    }
    return out;
  }

  /// Variance of the Laplacian: high for a sharp image, low for a blurred one.
  double laplacianVariance() {
    if (width < 3 || height < 3) return 0;
    var sum = 0.0, sumSq = 0.0;
    var n = 0;
    for (var y = 1; y < height - 1; y++) {
      final row = y * width;
      for (var x = 1; x < width - 1; x++) {
        final v = 4 * data[row + x] - data[row + x - 1] - data[row + x + 1] - data[row - width + x] - data[row + width + x];
        sum += v;
        sumSq += v * v;
        n++;
      }
    }
    final mean = sum / n;
    return sumSq / n - mean * mean;
  }

  /// Gradient magnitude (Sobel), scaled into 0..255.
  Raster sobel() {
    final out = Raster(width, height);
    for (var y = 1; y < height - 1; y++) {
      for (var x = 1; x < width - 1; x++) {
        final i = y * width + x;
        final gx = -data[i - width - 1] + data[i - width + 1] - 2 * data[i - 1] + 2 * data[i + 1] - data[i + width - 1] + data[i + width + 1];
        final gy = -data[i - width - 1] - 2 * data[i - width] - data[i - width + 1] + data[i + width - 1] + 2 * data[i + width] + data[i + width + 1];
        out.data[i] = math.min(255, (math.sqrt((gx * gx + gy * gy).toDouble()) / 4).round());
      }
    }
    return out;
  }
}

/// A colour photograph as 8-bit RGBA, as `dart:ui` hands it over.
class ColorRaster {
  ColorRaster(this.width, this.height, this.rgba) {
    assert(rgba.length == width * height * 4);
  }

  /// From four planes: red, green, blue, alpha.
  factory ColorRaster.fromPlanes(List<Raster> planes) {
    final w = planes[0].width, h = planes[0].height;
    final out = Uint8List(w * h * 4);
    for (var i = 0, p = 0; i < w * h; i++, p += 4) {
      out[p] = planes[0].data[i];
      out[p + 1] = planes[1].data[i];
      out[p + 2] = planes[2].data[i];
      out[p + 3] = planes[3].data[i];
    }
    return ColorRaster(w, h, out);
  }

  final int width;
  final int height;
  final Uint8List rgba;

  /// Luma (Rec. 601).
  Raster toGray() {
    final out = Raster(width, height);
    for (var i = 0, p = 0; i < out.data.length; i++, p += 4) {
      out.data[i] = ((rgba[p] * 299 + rgba[p + 1] * 587 + rgba[p + 2] * 114) / 1000).round();
    }
    return out;
  }

  /// One colour channel (0 red, 1 green, 2 blue) as grey.
  Raster channel(int c) {
    final out = Raster(width, height);
    for (var i = 0, p = c; i < out.data.length; i++, p += 4) {
      out.data[i] = rgba[p];
    }
    return out;
  }

  ColorRaster crop(int left, int top, int right, int bottom) {
    final l = left.clamp(0, width), t = top.clamp(0, height);
    final r = right.clamp(l, width), b = bottom.clamp(t, height);
    final w = r - l, h = b - t;
    final out = Uint8List(w * h * 4);
    for (var y = 0; y < h; y++) {
      out.setRange(y * w * 4, (y + 1) * w * 4, rgba, ((t + y) * width + l) * 4);
    }
    return ColorRaster(w, h, out);
  }

  /// This picture turned clockwise by [quarters] quarter-turns (0 to 3; any
  /// integer is taken modulo 4). Every pixel is kept exactly, so turning and
  /// turning back is lossless.
  ColorRaster turned(int quarters) {
    final q = quarters % 4;
    if (q == 0) return this;
    final nw = q == 2 ? width : height, nh = q == 2 ? height : width;
    // One 32-bit word per pixel, so each pixel is moved in one step.
    final from = rgba.offsetInBytes % 4 == 0
        ? Uint32List.view(rgba.buffer, rgba.offsetInBytes, width * height)
        : Uint8List.fromList(rgba).buffer.asUint32List();
    final to = Uint32List(nw * nh);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        // Where the pixel at (x, y) lands in the turned picture.
        final nx = q == 1 ? height - 1 - y : (q == 2 ? width - 1 - x : y);
        final ny = q == 1 ? x : (q == 2 ? height - 1 - y : width - 1 - x);
        to[ny * nw + nx] = from[y * width + x];
      }
    }
    return ColorRaster(nw, nh, to.buffer.asUint8List());
  }

  /// Area-averaged shrink / bilinear enlarge, per channel.
  ColorRaster resized(int newWidth, int newHeight) {
    final planes = [for (var c = 0; c < 4; c++) channel(c).resized(newWidth, newHeight)];
    final out = Uint8List(newWidth * newHeight * 4);
    for (var i = 0, p = 0; i < newWidth * newHeight; i++, p += 4) {
      out[p] = planes[0].data[i];
      out[p + 1] = planes[1].data[i];
      out[p + 2] = planes[2].data[i];
      out[p + 3] = planes[3].data[i];
    }
    return ColorRaster(newWidth, newHeight, out);
  }
}
