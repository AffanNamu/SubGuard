import 'dart:math' as math;
import 'dart:typed_data';

import 'raster.dart';

/// A long straight stroke found in an ink picture.
class StrokeLine {
  const StrokeLine({required this.x0, required this.y0, required this.x1, required this.y1, required this.support});

  /// The two ends, in pixels.
  final double x0, y0, x1, y1;

  /// How many ink pixels lie on it.
  final int support;

  double get length => math.sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0));
}

/// Finds long straight strokes in an ink picture with a Hough transform: table
/// rules, underlines, and the line an examiner draws through unused rows.
///
/// A stroke may be broken into pieces by faint pen or by thresholding, so no
/// single piece of ink looks like a line. What gives it away is that many ink
/// pixels lie on one straight line, covering most of its length. Handwriting
/// does not do that over more than a few character heights.
class LineFinder {
  const LineFinder._();

  /// Finds up to [maxLines] strokes at least [minLength] pixels long in the
  /// binary [mask] (non-zero is ink). A stroke is accepted when its pixels,
  /// within [tolerance] of the line, leave no gap longer than [maxGapShare] of
  /// its length.
  static List<StrokeLine> find(
    Raster mask, {
    required double minLength,
    double tolerance = 2.5,
    double maxGapShare = 0.28,
    int maxLines = 4,
    int maxCandidates = 30,
  }) {
    final xs = <int>[], ys = <int>[];
    for (var y = 0; y < mask.height; y++) {
      for (var x = 0; x < mask.width; x++) {
        if (mask.data[y * mask.width + x] != 0) {
          xs.add(x);
          ys.add(y);
        }
      }
    }
    if (xs.length < minLength) return const [];

    final diag = math.sqrt(mask.width * mask.width + mask.height * mask.height);
    final rhoOffset = diag.ceil() + 2;
    final rhoBins = rhoOffset * 2 + 1;
    const thetaSteps = 180;
    final cos = List<double>.generate(thetaSteps, (t) => math.cos(t * math.pi / thetaSteps));
    final sin = List<double>.generate(thetaSteps, (t) => math.sin(t * math.pi / thetaSteps));

    // The accumulator is built once. Pixels that belong to a candidate, whether
    // it is accepted or not, are taken out of it so the next-best candidate
    // can be examined: the strongest cluster of collinear pixels is often a few
    // characters' strokes, not the line.
    final acc = Int32List(thetaSteps * rhoBins);
    final rhoOf = List<Int32List>.generate(xs.length, (_) => Int32List(thetaSteps));
    for (var i = 0; i < xs.length; i++) {
      for (var t = 0; t < thetaSteps; t++) {
        final rho = (xs[i] * cos[t] + ys[i] * sin[t]).round() + rhoOffset;
        rhoOf[i][t] = rho;
        acc[t * rhoBins + rho]++;
      }
    }
    void take(int i) {
      for (var t = 0; t < thetaSteps; t++) {
        acc[t * rhoBins + rhoOf[i][t]]--;
      }
    }

    final alive = List<bool>.filled(xs.length, true);
    final lines = <StrokeLine>[];
    final reach = tolerance.floor();
    for (var attempt = 0; attempt < maxCandidates && lines.length < maxLines; attempt++) {
      var bestScore = 0, bestT = 0, bestRho = 0;
      for (var t = 0; t < thetaSteps; t++) {
        for (var r = reach; r < rhoBins - reach; r++) {
          var sum = 0;
          for (var d = -reach; d <= reach; d++) {
            sum += acc[t * rhoBins + r + d];
          }
          if (sum > bestScore) {
            bestScore = sum;
            bestT = t;
            bestRho = r;
          }
        }
      }
      // Too few pixels left on any line to make one of the required length.
      if (bestScore < minLength * 0.5) break;

      // The pixels on this candidate, ordered along it.
      final rho0 = (bestRho - rhoOffset).toDouble();
      final on = <({double along, int index})>[];
      for (var i = 0; i < xs.length; i++) {
        if (!alive[i]) continue;
        final dist = (xs[i] * cos[bestT] + ys[i] * sin[bestT] - rho0).abs();
        if (dist <= tolerance) on.add((along: -xs[i] * sin[bestT] + ys[i] * cos[bestT], index: i));
      }
      if (on.isEmpty) break;
      on.sort((a, b) => a.along.compareTo(b.along));

      // Longest unbroken run along the line: split at gaps wider than allowed.
      var runStart = 0, bestStart = 0, bestEnd = 0;
      var bestLen = 0.0;
      final gapLimit = math.max(3.0, minLength * maxGapShare);
      for (var i = 1; i <= on.length; i++) {
        final broken = i == on.length || on[i].along - on[i - 1].along > gapLimit;
        if (broken) {
          final len = on[i - 1].along - on[runStart].along;
          if (len > bestLen) {
            bestLen = len;
            bestStart = runStart;
            bestEnd = i - 1;
          }
          runStart = i;
        }
      }

      if (bestLen >= minLength) {
        final first = on[bestStart].index, last = on[bestEnd].index;
        lines.add(StrokeLine(
          x0: xs[first].toDouble(),
          y0: ys[first].toDouble(),
          x1: xs[last].toDouble(),
          y1: ys[last].toDouble(),
          support: bestEnd - bestStart + 1,
        ));
        for (var k = bestStart; k <= bestEnd; k++) {
          alive[on[k].index] = false;
          take(on[k].index);
        }
      } else {
        // Not a line: set these pixels aside and look at the next candidate.
        for (final p in on) {
          alive[p.index] = false;
          take(p.index);
        }
      }
    }
    return lines;
  }

  /// Sets the pixels of [ink] within [width] of each line to zero.
  static void erase(Raster ink, List<StrokeLine> lines, {double width = 3.5}) {
    for (final l in lines) {
      final dx = l.x1 - l.x0, dy = l.y1 - l.y0;
      final len2 = dx * dx + dy * dy;
      if (len2 == 0) continue;
      final x0 = math.max(0, math.min(l.x0, l.x1).floor() - width.ceil());
      final x1 = math.min(ink.width, math.max(l.x0, l.x1).ceil() + width.ceil() + 1);
      final y0 = math.max(0, math.min(l.y0, l.y1).floor() - width.ceil());
      final y1 = math.min(ink.height, math.max(l.y0, l.y1).ceil() + width.ceil() + 1);
      for (var y = y0; y < y1; y++) {
        for (var x = x0; x < x1; x++) {
          final t = ((x - l.x0) * dx + (y - l.y0) * dy) / len2;
          if (t < -0.05 || t > 1.05) continue;
          final px = l.x0 + t * dx, py = l.y0 + t * dy;
          final d = math.sqrt((x - px) * (x - px) + (y - py) * (y - py));
          if (d <= width) ink.data[y * ink.width + x] = 0;
        }
      }
    }
  }
}
