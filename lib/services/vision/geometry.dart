import 'dart:math' as math;
import 'dart:typed_data';

import 'raster.dart';

class Pt {
  const Pt(this.x, this.y);
  final double x;
  final double y;

  Pt operator +(Pt o) => Pt(x + o.x, y + o.y);
  Pt operator -(Pt o) => Pt(x - o.x, y - o.y);
  Pt operator *(double k) => Pt(x * k, y * k);
  double dist(Pt o) => math.sqrt((x - o.x) * (x - o.x) + (y - o.y) * (y - o.y));

  Map<String, double> toJson() => {'x': x, 'y': y};
  static Pt fromJson(Map<String, dynamic> j) => Pt((j['x'] as num).toDouble(), (j['y'] as num).toDouble());

  @override
  String toString() => '(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})';
}

/// Four corners in the order top-left, top-right, bottom-right, bottom-left.
class Quad {
  const Quad(this.tl, this.tr, this.br, this.bl);

  final Pt tl, tr, br, bl;

  List<Pt> get points => [tl, tr, br, bl];

  double get area {
    final p = points;
    var s = 0.0;
    for (var i = 0; i < 4; i++) {
      final a = p[i], b = p[(i + 1) % 4];
      s += a.x * b.y - b.x * a.y;
    }
    return s.abs() / 2;
  }

  double get topWidth => tl.dist(tr);
  double get bottomWidth => bl.dist(br);
  double get leftHeight => tl.dist(bl);
  double get rightHeight => tr.dist(br);

  /// Roughly how tall the page is for its width, from the longer sides.
  double get aspect => math.max(leftHeight, rightHeight) / math.max(topWidth, bottomWidth);

  /// How far the angle at [i] is from a right angle, in degrees.
  double cornerSkew(int i) {
    final p = points;
    final a = p[(i + 3) % 4] - p[i], b = p[(i + 1) % 4] - p[i];
    final cos = (a.x * b.x + a.y * b.y) / (math.sqrt(a.x * a.x + a.y * a.y) * math.sqrt(b.x * b.x + b.y * b.y) + 1e-9);
    return (math.acos(cos.clamp(-1, 1)) * 180 / math.pi - 90).abs();
  }

  /// The mean distance between this quad's corners and [other]'s.
  double meanCornerError(Quad other) {
    var s = 0.0;
    for (var i = 0; i < 4; i++) {
      s += points[i].dist(other.points[i]);
    }
    return s / 4;
  }

  Quad scaled(double k) => Quad(tl * k, tr * k, br * k, bl * k);

  Map<String, Object?> toJson() => {'tl': tl.toJson(), 'tr': tr.toJson(), 'br': br.toJson(), 'bl': bl.toJson()};
  static Quad fromJson(Map<String, dynamic> j) => Quad(
        Pt.fromJson(j['tl'] as Map<String, dynamic>),
        Pt.fromJson(j['tr'] as Map<String, dynamic>),
        Pt.fromJson(j['br'] as Map<String, dynamic>),
        Pt.fromJson(j['bl'] as Map<String, dynamic>),
      );
}

/// A 3x3 projective transform, row-major. Maps a point in one picture to the
/// matching point in another, which is how a field found on the straightened
/// page is traced back to the original photograph.
class Homography {
  const Homography(this.m);

  final List<double> m;

  static const identity = Homography([1, 0, 0, 0, 1, 0, 0, 0, 1]);

  /// The transform taking [src] corners to [dst] corners.
  static Homography? fromPoints(List<Pt> src, List<Pt> dst) {
    assert(src.length == 4 && dst.length == 4);
    final a = List.generate(8, (_) => List<double>.filled(9, 0));
    for (var i = 0; i < 4; i++) {
      final x = src[i].x, y = src[i].y, u = dst[i].x, v = dst[i].y;
      a[2 * i] = [x, y, 1, 0, 0, 0, -u * x, -u * y, u];
      a[2 * i + 1] = [0, 0, 0, x, y, 1, -v * x, -v * y, v];
    }
    // Gaussian elimination with partial pivoting.
    for (var c = 0; c < 8; c++) {
      var p = c;
      for (var r = c + 1; r < 8; r++) {
        if (a[r][c].abs() > a[p][c].abs()) p = r;
      }
      if (a[p][c].abs() < 1e-12) return null;
      final t = a[c];
      a[c] = a[p];
      a[p] = t;
      for (var r = 0; r < 8; r++) {
        if (r == c) continue;
        final k = a[r][c] / a[c][c];
        for (var j = c; j < 9; j++) {
          a[r][j] -= k * a[c][j];
        }
      }
    }
    return Homography([for (var i = 0; i < 8; i++) a[i][8] / a[i][i], 1]);
  }

  Pt apply(Pt p) {
    final w = m[6] * p.x + m[7] * p.y + m[8];
    return Pt((m[0] * p.x + m[1] * p.y + m[2]) / w, (m[3] * p.x + m[4] * p.y + m[5]) / w);
  }

  Homography? inverse() {
    final a = m;
    final det = a[0] * (a[4] * a[8] - a[5] * a[7]) - a[1] * (a[3] * a[8] - a[5] * a[6]) + a[2] * (a[3] * a[7] - a[4] * a[6]);
    if (det.abs() < 1e-12) return null;
    final i = 1 / det;
    return Homography([
      (a[4] * a[8] - a[5] * a[7]) * i,
      (a[2] * a[7] - a[1] * a[8]) * i,
      (a[1] * a[5] - a[2] * a[4]) * i,
      (a[5] * a[6] - a[3] * a[8]) * i,
      (a[0] * a[8] - a[2] * a[6]) * i,
      (a[2] * a[3] - a[0] * a[5]) * i,
      (a[3] * a[7] - a[4] * a[6]) * i,
      (a[1] * a[6] - a[0] * a[7]) * i,
      (a[0] * a[4] - a[1] * a[3]) * i,
    ]);
  }

  /// First [other], then this one.
  Homography after(Homography other) {
    final a = m, b = other.m;
    return Homography([
      for (var r = 0; r < 3; r++)
        for (var c = 0; c < 3; c++) a[r * 3] * b[c] + a[r * 3 + 1] * b[3 + c] + a[r * 3 + 2] * b[6 + c],
    ]);
  }

  List<double> toJson() => m;
  static Homography fromJson(List<dynamic> j) => Homography([for (final v in j) (v as num).toDouble()]);
}

/// Resamples [src] into a [width] x [height] picture where output pixel (x, y)
/// takes its value from [toSource] applied to (x, y). Bilinear.
Raster warpRaster(Raster src, Homography toSource, int width, int height, {int fill = 255}) {
  final out = Raster(width, height);
  final h = toSource.m;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final w = h[6] * x + h[7] * y + h[8];
      final sx = (h[0] * x + h[1] * y + h[2]) / w;
      final sy = (h[3] * x + h[4] * y + h[5]) / w;
      if (sx < -0.5 || sy < -0.5 || sx > src.width - 0.5 || sy > src.height - 0.5) {
        out.data[y * width + x] = fill;
      } else {
        out.data[y * width + x] = src.sampleBilinear(sx, sy).round().clamp(0, 255);
      }
    }
  }
  return out;
}

/// The same for a colour picture, channel by channel.
ColorRaster warpColor(ColorRaster src, Homography toSource, int width, int height) {
  final planes = [for (var c = 0; c < 3; c++) warpRaster(src.channel(c), toSource, width, height)];
  final out = Uint8List(width * height * 4);
  for (var i = 0, p = 0; i < width * height; i++, p += 4) {
    out[p] = planes[0].data[i];
    out[p + 1] = planes[1].data[i];
    out[p + 2] = planes[2].data[i];
    out[p + 3] = 255;
  }
  return ColorRaster(width, height, out);
}

/// A connected group of ink pixels.
class Blob {
  Blob(this.left, this.top, this.right, this.bottom, this.area, this.sumX, this.sumY);

  int left, top, right, bottom; // right/bottom exclusive
  int area;
  double sumX, sumY;

  int get width => right - left;
  int get height => bottom - top;
  double get cx => sumX / area;
  double get cy => sumY / area;
}

/// Connected components of the non-zero pixels of [mask] (8-connected), with
/// their bounding boxes. Groups smaller than [minArea] pixels are dropped.
List<Blob> connectedComponents(Raster mask, {int minArea = 1}) {
  final w = mask.width, h = mask.height;
  final labels = Int32List(w * h);
  final parent = <int>[0];
  int find(int a) {
    while (parent[a] != a) {
      parent[a] = parent[parent[a]];
      a = parent[a];
    }
    return a;
  }

  var next = 1;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      if (mask.data[i] == 0) continue;
      final neigh = <int>[];
      if (x > 0 && labels[i - 1] != 0) neigh.add(labels[i - 1]);
      if (y > 0) {
        if (labels[i - w] != 0) neigh.add(labels[i - w]);
        if (x > 0 && labels[i - w - 1] != 0) neigh.add(labels[i - w - 1]);
        if (x < w - 1 && labels[i - w + 1] != 0) neigh.add(labels[i - w + 1]);
      }
      if (neigh.isEmpty) {
        labels[i] = next;
        parent.add(next);
        next++;
      } else {
        var m = neigh.first;
        for (final n in neigh) {
          if (n < m) m = n;
        }
        labels[i] = m;
        for (final n in neigh) {
          final a = find(n), b = find(m);
          if (a != b) parent[math.max(a, b)] = math.min(a, b);
        }
      }
    }
  }
  final blobs = <int, Blob>{};
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final l = labels[y * w + x];
      if (l == 0) continue;
      final r = find(l);
      final b = blobs[r];
      if (b == null) {
        blobs[r] = Blob(x, y, x + 1, y + 1, 1, x.toDouble(), y.toDouble());
      } else {
        if (x < b.left) b.left = x;
        if (y < b.top) b.top = y;
        if (x + 1 > b.right) b.right = x + 1;
        if (y + 1 > b.bottom) b.bottom = y + 1;
        b.area++;
        b.sumX += x;
        b.sumY += y;
      }
    }
  }
  return [for (final b in blobs.values) if (b.area >= minArea) b];
}
