import 'dart:math' as math;
import 'dart:typed_data';

import 'geometry.dart';
import 'raster.dart';

/// Where the page is in a photograph.
class PageDetection {
  const PageDetection({
    this.quad,
    this.confidence = 0,
    this.fullyVisible = false,
    this.areaFraction = 0,
    this.reason,
  });

  /// The four page corners in the pixels of the picture given to the detector,
  /// or null when no page could be found.
  final Quad? quad;

  /// 0..1: how well the outline fits a four-sided page.
  final double confidence;

  /// All four corners are inside the picture. If not, the page is cropped by the
  /// frame and the corners found are where the frame cuts it, not real corners.
  final bool fullyVisible;

  final double areaFraction;
  final String? reason;
}

/// Finds the page's outline: separates the bright, pale paper from the table
/// it lies on, and fits the best four-sided outline around it.
///
/// It does not need a table of any particular colour, but it does need the
/// paper to look different from what is under it. A white page on a white desk
/// is reported as "no page found", never guessed.
/// Finds the page in a photograph.
abstract interface class DocumentBoundaryDetector {
  PageDetection detect(ColorRaster photo);
}

class PageDetector implements DocumentBoundaryDetector {
  const PageDetector({this.analysisSide = 320});

  final int analysisSide;

  @override
  PageDetection detect(ColorRaster photo) {
    final k = analysisSide / math.max(photo.width, photo.height);
    final w = math.max(8, (photo.width * k).round()), h = math.max(8, (photo.height * k).round());
    final small = photo.resized(w, h);

    // Features per pixel: brightness and colourfulness.
    final lum = small.toGray().gaussian(1.0);
    final sat = Raster(w, h);
    for (var i = 0, p = 0; i < w * h; i++, p += 4) {
      final r = small.rgba[p], g = small.rgba[p + 1], b = small.rgba[p + 2];
      sat.data[i] = math.max(r, math.max(g, b)) - math.min(r, math.min(g, b));
    }

    final mask = _paperMask(lum, sat);
    if (mask == null) return const PageDetection(reason: 'The picture has no clear page against its background.');

    final comp = _largest(mask);
    if (comp == null) return const PageDetection(reason: 'No page-sized area was found.');
    final area = comp.area / (w * h);
    if (area < 0.12) return PageDetection(areaFraction: area, reason: 'The page is too small in the picture, or not separate from its background.');

    final filled = _fillHoles(mask, comp);
    final hull = _hull(_boundary(filled));
    if (hull.length < 3) return const PageDetection(reason: 'The page outline could not be traced.');
    final four = _toFour(hull);
    if (four == null) return const PageDetection(reason: 'The page outline is not four-sided.');
    final ordered = _order(four);
    final quad = Quad(ordered[0], ordered[1], ordered[2], ordered[3]);

    // How well the page fills its four-sided outline, and how square its corners.
    final fit = (filled.data.where((v) => v != 0).length / math.max(1.0, quad.area)).clamp(0.0, 1.0);
    var skew = 0.0;
    for (var i = 0; i < 4; i++) {
      skew = math.max(skew, quad.cornerSkew(i));
    }
    final confidence = (fit * (skew > 45 ? 0.3 : (1 - skew / 90))).clamp(0.0, 1.0);

    const margin = 0.012;
    final inside = quad.points.every((p) => p.x > margin * w && p.x < (1 - margin) * w && p.y > margin * h && p.y < (1 - margin) * h);

    return PageDetection(
      quad: quad.scaled(1 / k),
      confidence: confidence,
      fullyVisible: inside,
      areaFraction: quad.area / (w * h),
      reason: confidence < 0.5 ? 'The outline found does not fit a page well.' : null,
    );
  }

  // ---- steps ----

  /// A 2-means split of (brightness, colourfulness) into paper and the rest.
  Raster? _paperMask(Raster lum, Raster sat) {
    final n = lum.data.length;
    var cp = lum.percentile(0.92).toDouble(), cs = sat.percentile(0.2).toDouble();
    var bp = lum.percentile(0.08).toDouble(), bs = sat.percentile(0.8).toDouble();
    if ((cp - bp).abs() < 25) return null; // nothing to separate
    final label = Uint8List(n);
    for (var iter = 0; iter < 10; iter++) {
      var sp = 0.0, sps = 0.0, np = 0, sb = 0.0, sbs = 0.0, nb = 0;
      for (var i = 0; i < n; i++) {
        final l = lum.data[i].toDouble(), s = sat.data[i] * 0.6;
        final dp = (l - cp) * (l - cp) + (s - cs * 0.6) * (s - cs * 0.6);
        final db = (l - bp) * (l - bp) + (s - bs * 0.6) * (s - bs * 0.6);
        if (dp <= db) {
          label[i] = 1;
          sp += l;
          sps += sat.data[i];
          np++;
        } else {
          label[i] = 0;
          sb += l;
          sbs += sat.data[i];
          nb++;
        }
      }
      if (np == 0 || nb == 0) return null;
      cp = sp / np;
      cs = sps / np;
      bp = sb / nb;
      bs = sbs / nb;
    }
    if ((cp - bp).abs() < 25) return null;
    final raw = Raster(lum.width, lum.height);
    for (var i = 0; i < n; i++) {
      raw.data[i] = label[i] == 1 ? 255 : 0;
    }
    // Smooth the ragged edge and close small gaps (printed text and stamps).
    final smooth = raw.boxBlur(2);
    final out = Raster(lum.width, lum.height);
    for (var i = 0; i < n; i++) {
      out.data[i] = smooth.data[i] > 127 ? 255 : 0;
    }
    return out;
  }

  Blob? _largest(Raster mask) {
    final blobs = connectedComponents(mask, minArea: 20);
    if (blobs.isEmpty) return null;
    blobs.sort((a, b) => b.area.compareTo(a.area));
    return blobs.first;
  }

  /// The page with its holes (writing, stamps) filled: everything the
  /// outside cannot reach.
  Raster _fillHoles(Raster mask, Blob comp) {
    final w = mask.width, h = mask.height;
    final outside = Uint8List(w * h);
    final stack = <int>[];
    void seed(int x, int y) {
      final i = y * w + x;
      if (mask.data[i] == 0 && outside[i] == 0) {
        outside[i] = 1;
        stack.add(i);
      }
    }

    for (var x = 0; x < w; x++) {
      seed(x, 0);
      seed(x, h - 1);
    }
    for (var y = 0; y < h; y++) {
      seed(0, y);
      seed(w - 1, y);
    }
    while (stack.isNotEmpty) {
      final i = stack.removeLast();
      final x = i % w, y = i ~/ w;
      if (x > 0) seed(x - 1, y);
      if (x < w - 1) seed(x + 1, y);
      if (y > 0) seed(x, y - 1);
      if (y < h - 1) seed(x, y + 1);
    }
    // Keep only the largest component's region plus holes inside the picture.
    final out = Raster(w, h);
    for (var i = 0; i < w * h; i++) {
      out.data[i] = outside[i] == 0 ? 255 : 0;
    }
    final keep = connectedComponents(out, minArea: 20)..sort((a, b) => b.area.compareTo(a.area));
    if (keep.isEmpty) return mask;
    final b = keep.first;
    final res = Raster(w, h);
    for (var y = b.top; y < b.bottom; y++) {
      for (var x = b.left; x < b.right; x++) {
        res.data[y * w + x] = out.data[y * w + x];
      }
    }
    return res;
  }

  List<Pt> _boundary(Raster m) {
    final w = m.width, h = m.height;
    final pts = <Pt>[];
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (m.data[y * w + x] == 0) continue;
        final edge = x == 0 || y == 0 || x == w - 1 || y == h - 1 || m.data[y * w + x - 1] == 0 || m.data[y * w + x + 1] == 0 || m.data[(y - 1) * w + x] == 0 || m.data[(y + 1) * w + x] == 0;
        if (edge) pts.add(Pt(x.toDouble(), y.toDouble()));
      }
    }
    return pts;
  }

  /// Convex hull, Andrew's monotone chain.
  List<Pt> _hull(List<Pt> pts) {
    if (pts.length < 3) return pts;
    final p = [...pts]..sort((a, b) => a.x != b.x ? a.x.compareTo(b.x) : a.y.compareTo(b.y));
    double cross(Pt o, Pt a, Pt b) => (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);
    final lower = <Pt>[];
    for (final q in p) {
      while (lower.length >= 2 && cross(lower[lower.length - 2], lower.last, q) <= 0) {
        lower.removeLast();
      }
      lower.add(q);
    }
    final upper = <Pt>[];
    for (final q in p.reversed) {
      while (upper.length >= 2 && cross(upper[upper.length - 2], upper.last, q) <= 0) {
        upper.removeLast();
      }
      upper.add(q);
    }
    lower.removeLast();
    upper.removeLast();
    return [...lower, ...upper];
  }

  /// Reduces a convex polygon to four corners by repeatedly removing the side
  /// whose removal adds the least area: its two neighbours are extended until
  /// they meet. The result encloses the page, so corners are not cut off.
  List<Pt>? _toFour(List<Pt> poly) {
    var p = [...poly];
    var guard = 0;
    while (p.length > 4 && guard++ < 4000) {
      var best = -1;
      var bestArea = double.infinity;
      Pt? bestPt;
      final n = p.length;
      for (var i = 0; i < n; i++) {
        final a = p[(i + n - 1) % n], b = p[i], c = p[(i + 1) % n], d = p[(i + 2) % n];
        final x = _intersect(a, b, c, d);
        if (x == null) continue;
        // The new point must lie beyond the removed side.
        final tri = _triArea(b, c, x);
        final side = (c.x - b.x) * (x.y - b.y) - (c.y - b.y) * (x.x - b.x);
        final inward = (c.x - b.x) * (_centroid(p).y - b.y) - (c.y - b.y) * (_centroid(p).x - b.x);
        if (side * inward > 0) continue; // on the inside: not an enclosing corner
        if (tri < bestArea) {
          bestArea = tri;
          best = i;
          bestPt = x;
        }
      }
      if (best < 0 || bestPt == null) {
        // Parallel neighbours everywhere: fall back to dropping the sharpest-area vertex.
        var worst = 0;
        var wa = double.infinity;
        for (var i = 0; i < n; i++) {
          final t = _triArea(p[(i + n - 1) % n], p[i], p[(i + 1) % n]);
          if (t < wa) {
            wa = t;
            worst = i;
          }
        }
        p.removeAt(worst);
        continue;
      }
      final i = best, j = (best + 1) % n;
      final next = <Pt>[];
      for (var k = 0; k < n; k++) {
        if (k == i) {
          next.add(bestPt);
        } else if (k != j) {
          next.add(p[k]);
        }
      }
      p = next;
    }
    return p.length == 4 ? p : null;
  }

  Pt _centroid(List<Pt> p) {
    var x = 0.0, y = 0.0;
    for (final q in p) {
      x += q.x;
      y += q.y;
    }
    return Pt(x / p.length, y / p.length);
  }

  double _triArea(Pt a, Pt b, Pt c) => ((b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y)).abs() / 2;

  /// Where the line through [a],[b] meets the line through [c],[d].
  Pt? _intersect(Pt a, Pt b, Pt c, Pt d) {
    final d1 = b - a, d2 = d - c;
    final den = d1.x * d2.y - d1.y * d2.x;
    if (den.abs() < 1e-9) return null;
    final t = ((c.x - a.x) * d2.y - (c.y - a.y) * d2.x) / den;
    return Pt(a.x + t * d1.x, a.y + t * d1.y);
  }

  /// Top-left, top-right, bottom-right, bottom-left.
  List<Pt> _order(List<Pt> p) {
    final c = _centroid(p);
    final sorted = [...p]..sort((a, b) => math.atan2(a.y - c.y, a.x - c.x).compareTo(math.atan2(b.y - c.y, b.x - c.x)));
    // Angles run clockwise on screen (y down). Start from the top-left corner.
    var start = 0;
    var minSum = double.infinity;
    for (var i = 0; i < 4; i++) {
      final s = sorted[i].x + sorted[i].y;
      if (s < minSum) {
        minSum = s;
        start = i;
      }
    }
    return [for (var i = 0; i < 4; i++) sorted[(start + i) % 4]];
  }
}

/// The page straightened: the picture and the transform that maps a point on
/// the straightened page back to the original photograph.
class RectifiedPage {
  const RectifiedPage({required this.image, required this.pageToPhoto, required this.photoToPage});

  final ColorRaster image;
  final Homography pageToPhoto;
  final Homography photoToPage;
}

class PageRectifier {
  const PageRectifier._();

  /// Warps the area inside [quad] to a flat rectangle, no larger than
  /// [maxSide] on its long side.
  static RectifiedPage? rectify(ColorRaster photo, Quad quad, {int maxSide = 2400}) {
    var w = math.max(quad.topWidth, quad.bottomWidth);
    var h = math.max(quad.leftHeight, quad.rightHeight);
    if (w < 16 || h < 16) return null;
    final k = math.min(1.0, maxSide / math.max(w, h));
    w *= k;
    h *= k;
    final outW = w.round(), outH = h.round();
    final dst = [const Pt(0, 0), Pt(outW.toDouble(), 0), Pt(outW.toDouble(), outH.toDouble()), Pt(0, outH.toDouble())];
    final pageToPhoto = Homography.fromPoints(dst, quad.points);
    final photoToPage = Homography.fromPoints(quad.points, dst);
    if (pageToPhoto == null || photoToPage == null) return null;
    return RectifiedPage(image: warpColor(photo, pageToPhoto, outW, outH), pageToPhoto: pageToPhoto, photoToPage: photoToPage);
  }
}

/// Estimates how far the printed lines are from horizontal.
class SkewEstimator {
  const SkewEstimator._();

  /// How much the text lines tilt, in degrees, and how sure that is (0..1):
  /// positive when they run downhill to the right. Turning the picture by
  /// minus this makes them level. Lines of print and rules both count. A page
  /// photographed at an angle has lines that tilt by different amounts, so
  /// this is the dominant tilt.
  static ({double degrees, double strength}) estimate(Raster gray, {double range = 12, int side = 700}) {
    final k = math.min(1.0, side / math.max(gray.width, gray.height));
    final g = k < 1 ? gray.resized((gray.width * k).round(), (gray.height * k).round()) : gray;
    // Dark ink on a locally lighter page.
    final bg = g.boxBlur(math.max(3, g.width ~/ 40));
    final xs = <double>[], ys = <double>[];
    for (var y = 0; y < g.height; y++) {
      for (var x = 0; x < g.width; x++) {
        if (g.data[y * g.width + x] + 28 < bg.data[y * g.width + x]) {
          xs.add(x.toDouble());
          ys.add(y.toDouble());
        }
      }
    }
    if (xs.length < 200) return (degrees: 0, strength: 0);

    final bins = g.width + g.height;
    double score(double deg) {
      final t = deg * math.pi / 180, c = math.cos(t), s = math.sin(t);
      final hist = List<double>.filled(bins + 1, 0);
      for (var i = 0; i < xs.length; i++) {
        // Row position after rotating the picture by -deg: lines at +deg level out.
        final yy = ys[i] * c - xs[i] * s + g.width * math.sin(t.abs());
        final b = yy.round();
        if (b >= 0 && b <= bins) hist[b]++;
      }
      var m = 0.0;
      for (final v in hist) {
        m += v;
      }
      m /= hist.length;
      var v2 = 0.0;
      for (final v in hist) {
        v2 += (v - m) * (v - m);
      }
      return v2;
    }

    var best = 0.0, bestScore = -1.0;
    final scores = <double>[];
    for (var d = -range; d <= range + 1e-9; d += 0.5) {
      final sc = score(d);
      scores.add(sc);
      if (sc > bestScore) {
        bestScore = sc;
        best = d;
      }
    }
    var fine = best, fineScore = bestScore;
    for (var d = best - 0.5; d <= best + 0.5 + 1e-9; d += 0.1) {
      final sc = score(d);
      if (sc > fineScore) {
        fineScore = sc;
        fine = d;
      }
    }
    scores.sort();
    final median = scores[scores.length ~/ 2];
    final strength = ((fineScore / math.max(1.0, median)) - 1).clamp(0.0, 1.0);
    return (degrees: fine, strength: strength);
  }

  /// A transform that rotates by [degrees] about the centre of a [w] x [h] picture.
  static Homography rotation(double degrees, int w, int h) {
    final t = degrees * math.pi / 180, c = math.cos(t), s = math.sin(t);
    final cx = w / 2, cy = h / 2;
    return Homography([c, -s, cx - c * cx + s * cy, s, c, cy - s * cx - c * cy, 0, 0, 1]);
  }
}
