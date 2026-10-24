import 'dart:math' as math;

import 'geometry.dart';
import 'page_geometry.dart';
import 'raster.dart';

enum QualitySeverity {
  /// Worth knowing; does not hurt reading.
  info,

  /// Reading may be wrong; values are checked more carefully.
  warning,

  /// Information has genuinely been lost; a better photo is needed.
  blocking,
}

/// One problem found in a photograph, in words for the person who took it.
class QualityIssue {
  const QualityIssue({
    required this.code,
    required this.severity,
    required this.message,
    required this.advice,
    required this.value,
    required this.threshold,
  });

  final String code;
  final QualitySeverity severity;
  final String message;

  /// What to do about it, as an instruction.
  final String advice;
  final double value;
  final double threshold;

  Map<String, Object?> toJson() => {
        'code': code,
        'severity': severity.name,
        'message': message,
        'advice': advice,
        'value': value,
        'threshold': threshold,
      };

  static QualityIssue fromJson(Map<String, dynamic> j) => QualityIssue(
        code: j['code'] as String,
        severity: QualitySeverity.values.byName(j['severity'] as String),
        message: j['message'] as String,
        advice: j['advice'] as String,
        value: (j['value'] as num).toDouble(),
        threshold: (j['threshold'] as num).toDouble(),
      );
}

enum QualityVerdict {
  /// Nothing found that should hurt reading.
  good,

  /// Readable, but some values will need a closer look.
  usable,

  /// Too much is lost; a new photograph is the better course.
  poor,
}

/// The numbers measured on a photograph.
class QualityMetrics {
  const QualityMetrics({
    required this.originalWidth,
    required this.originalHeight,
    required this.sharpness,
    required this.noise,
    required this.p2,
    required this.p98,
    required this.darkClip,
    required this.brightClip,
    required this.shadowRatio,
    required this.glareFraction,
    required this.inkContrast,
    required this.textHeightPx,
    required this.tiltDegrees,
    required this.tiltStrength,
    required this.perspectiveDegrees,
    required this.pageFound,
    required this.pageFullyVisible,
    required this.pageAreaFraction,
  });

  final int originalWidth, originalHeight;

  /// Edge acutance of the text-bearing parts of the page (see [QualityAnalyzer]).
  final double sharpness;

  /// Estimated sensor noise, grey levels (standard deviation).
  final double noise;

  /// Dark and light ends of the page's brightness, 0..255.
  final int p2, p98;

  /// Share of page pixels that are nearly black / nearly white.
  final double darkClip, brightClip;

  /// How much brighter the lightest part of the page is than the darkest.
  final double shadowRatio;

  /// Largest blown-out patch as a share of the page.
  final double glareFraction;

  /// How much darker the writing is than its paper, as a share of the paper.
  final double inkContrast;

  /// Typical height of a printed character, in original pixels.
  final double textHeightPx;

  /// Dominant tilt of the text lines and how sure that is.
  final double tiltDegrees, tiltStrength;

  /// Largest departure of a page corner from a right angle, degrees.
  final double perspectiveDegrees;

  final bool pageFound, pageFullyVisible;
  final double pageAreaFraction;

  double get megapixels => originalWidth * originalHeight / 1e6;

  Map<String, Object?> toJson() => {
        'originalWidth': originalWidth,
        'originalHeight': originalHeight,
        'sharpness': sharpness,
        'noise': noise,
        'p2': p2,
        'p98': p98,
        'darkClip': darkClip,
        'brightClip': brightClip,
        'shadowRatio': shadowRatio,
        'glareFraction': glareFraction,
        'inkContrast': inkContrast,
        'textHeightPx': textHeightPx,
        'tiltDegrees': tiltDegrees,
        'tiltStrength': tiltStrength,
        'perspectiveDegrees': perspectiveDegrees,
        'pageFound': pageFound,
        'pageFullyVisible': pageFullyVisible,
        'pageAreaFraction': pageAreaFraction,
      };

  static QualityMetrics fromJson(Map<String, dynamic> j) => QualityMetrics(
        originalWidth: (j['originalWidth'] as num).toInt(),
        originalHeight: (j['originalHeight'] as num).toInt(),
        sharpness: (j['sharpness'] as num).toDouble(),
        noise: (j['noise'] as num?)?.toDouble() ?? 0,
        p2: (j['p2'] as num).toInt(),
        p98: (j['p98'] as num).toInt(),
        darkClip: (j['darkClip'] as num).toDouble(),
        brightClip: (j['brightClip'] as num).toDouble(),
        shadowRatio: (j['shadowRatio'] as num).toDouble(),
        glareFraction: (j['glareFraction'] as num).toDouble(),
        inkContrast: (j['inkContrast'] as num).toDouble(),
        textHeightPx: (j['textHeightPx'] as num).toDouble(),
        tiltDegrees: (j['tiltDegrees'] as num).toDouble(),
        tiltStrength: (j['tiltStrength'] as num).toDouble(),
        perspectiveDegrees: (j['perspectiveDegrees'] as num).toDouble(),
        pageFound: j['pageFound'] as bool,
        pageFullyVisible: j['pageFullyVisible'] as bool,
        pageAreaFraction: (j['pageAreaFraction'] as num).toDouble(),
      );
}

/// The verdict on a photograph: what was measured and what it means.
class QualityReport {
  const QualityReport({required this.metrics, required this.issues, required this.verdict});

  final QualityMetrics metrics;
  final List<QualityIssue> issues;
  final QualityVerdict verdict;

  bool get hasBlocking => issues.any((i) => i.severity == QualitySeverity.blocking);

  QualityIssue? issue(String code) => issues.where((i) => i.code == code).firstOrNull;

  Map<String, Object?> toJson() => {
        'metrics': metrics.toJson(),
        'issues': [for (final i in issues) i.toJson()],
        'verdict': verdict.name,
      };

  static QualityReport fromJson(Map<String, dynamic> j) => QualityReport(
        metrics: QualityMetrics.fromJson(j['metrics'] as Map<String, dynamic>),
        issues: [for (final i in (j['issues'] as List)) QualityIssue.fromJson(i as Map<String, dynamic>)],
        verdict: QualityVerdict.values.byName(j['verdict'] as String),
      );
}

/// Where a problem becomes a warning, and where it becomes "take it again".
/// Set from measurements on blurred, darkened, faint, grainy and shadowed
/// versions of a real booklet photograph (docs/recognition/QUALITY_CALIBRATION.md).
/// They come from one source document, so they are starting points to be
/// re-measured on more photographs, not settled constants.
class QualityThresholds {
  const QualityThresholds({
    this.minLongSidePx = 1000,
    this.blockingLongSidePx = 600,
    this.warnSharpness = 0.50,
    this.blockSharpness = 0.30,
    this.warnNoise = 12,
    this.blockNoise = 30,
    this.warnDarkClip = 0.18,
    this.blockDarkClip = 0.55,
    this.blockP98 = 64,
    this.warnBrightClip = 0.25,
    this.warnShadowRatio = 1.30,
    this.warnGlare = 0.004,
    this.blockGlare = 0.03,
    this.warnInkContrast = 0.20,
    this.blockInkContrast = 0.12,
    this.minTextHeightPx = 16,
    this.warnTiltDegrees = 4,
    this.warnPerspectiveDegrees = 18,
  });

  final int minLongSidePx, blockingLongSidePx;
  final double warnSharpness, blockSharpness;
  final double warnNoise, blockNoise;
  final double warnDarkClip, blockDarkClip, warnBrightClip;
  final int blockP98;
  final double warnShadowRatio;
  final double warnGlare, blockGlare;
  final double warnInkContrast, blockInkContrast;
  final double minTextHeightPx;
  final double warnTiltDegrees, warnPerspectiveDegrees;
}

/// Measures a photograph and explains what is wrong with it, if anything.
///
/// Every measurement is made on the page itself when it can be found (not on
/// the table around it), at a fixed analysis size so a 12-megapixel photo and a
/// small one are judged on the same footing.
class QualityAnalyzer {
  const QualityAnalyzer({this.thresholds = const QualityThresholds(), this.analysisSide = 1200});

  final QualityThresholds thresholds;
  final int analysisSide;

  /// [photo] is the working-size picture; [originalWidth] x [originalHeight] is
  /// the stored photograph. [page] is the detection result when there is one.
  QualityReport analyze(ColorRaster photo, {required int originalWidth, required int originalHeight, PageDetection? page}) {
    final m = measure(photo, originalWidth: originalWidth, originalHeight: originalHeight, page: page);
    return judge(m);
  }

  QualityMetrics measure(ColorRaster photo, {required int originalWidth, required int originalHeight, PageDetection? page}) {
    final detection = page ?? const PageDetector().detect(photo);
    final longSide = math.max(photo.width, photo.height);
    final k = longSide > analysisSide ? analysisSide / longSide : 1.0;
    final working = k < 1 ? photo.resized((photo.width * k).round(), (photo.height * k).round()) : photo;
    final gray = working.toGray();

    // The part of the picture that is page.
    var l = 0, t = 0, r = gray.width, b = gray.height;
    final quad = detection.quad;
    final usePage = quad != null && detection.confidence >= 0.5;
    if (usePage) {
      final xs = quad.points.map((p) => p.x * k), ys = quad.points.map((p) => p.y * k);
      // Shrunk a little: the edge of the page is not text.
      final mx = (xs.reduce(math.max) - xs.reduce(math.min)) * 0.04, my = (ys.reduce(math.max) - ys.reduce(math.min)) * 0.04;
      l = (xs.reduce(math.min) + mx).floor().clamp(0, gray.width - 1);
      r = (xs.reduce(math.max) - mx).ceil().clamp(l + 1, gray.width);
      t = (ys.reduce(math.min) + my).floor().clamp(0, gray.height - 1);
      b = (ys.reduce(math.max) - my).ceil().clamp(t + 1, gray.height);
    }
    final pageGray = gray.crop(l, t, r, b);

    final p2 = pageGray.percentile(0.02), p98 = pageGray.percentile(0.98);
    var dark = 0, bright = 0;
    for (final v in pageGray.data) {
      if (v < 24) dark++;
      if (v >= 250) bright++;
    }
    final n = pageGray.data.length.toDouble();

    // Shading: the slowly varying brightness across the page.
    final shade = pageGray.gaussian(math.max(4, pageGray.width / 12));
    final shadeLo = math.max(1, shade.percentile(0.05)), shadeHi = shade.percentile(0.95);

    final skew = SkewEstimator.estimate(pageGray);

    return QualityMetrics(
      originalWidth: originalWidth,
      originalHeight: originalHeight,
      sharpness: _sharpness(pageGray),
      noise: _noise(pageGray),
      p2: p2,
      p98: p98,
      darkClip: dark / n,
      brightClip: bright / n,
      shadowRatio: shadeHi / shadeLo,
      glareFraction: _glare(pageGray),
      inkContrast: _inkContrast(pageGray),
      textHeightPx: _textHeight(pageGray) * (originalWidth / photo.width) / k,
      tiltDegrees: skew.degrees,
      tiltStrength: skew.strength,
      perspectiveDegrees: quad == null ? 0 : [for (var i = 0; i < 4; i++) quad.cornerSkew(i)].reduce(math.max),
      pageFound: usePage,
      pageFullyVisible: detection.fullyVisible,
      pageAreaFraction: detection.areaFraction,
    );
  }

  /// Edge acutance: how steep the sharpest edges are compared with the contrast
  /// around them. 1 is a perfect step; a blur of s pixels gives about 0.4 / s.
  /// Taken over the tiles that carry writing (the 75th percentile of them) so a
  /// page with little on it does not look blurred. Normalising by each tile's
  /// own contrast keeps a faint page from looking soft, and using the steepest
  /// edges (not all pixels) keeps sensor noise from looking like sharpness.
  double _sharpness(Raster g) {
    const cols = 6, rows = 8;
    final grad = g.gaussian(0.7).sobel();
    final values = <double>[];
    for (var ty = 0; ty < rows; ty++) {
      for (var tx = 0; tx < cols; tx++) {
        final l = tx * g.width ~/ cols, t = ty * g.height ~/ rows, r = (tx + 1) * g.width ~/ cols, b = (ty + 1) * g.height ~/ rows;
        final tile = g.crop(l, t, r, b);
        if (tile.width < 8 || tile.height < 8) continue;
        final contrast = tile.percentile(0.95) - tile.percentile(0.05);
        if (contrast < 18) continue; // blank paper: nothing to judge by
        final edges = grad.crop(l, t, r, b);
        final steep = edges.percentile(0.985);
        values.add(steep / (contrast + 6));
      }
    }
    if (values.isEmpty) return 0;
    values.sort();
    return values[(values.length * 0.75).floor().clamp(0, values.length - 1)];
  }

  /// Median over the tiles that carry writing of (p95 - p5) / p95: how much
  /// darker the writing is than its paper, as a share of the paper. Measured
  /// per tile so it does not depend on where the page ends, and 0 when no
  /// tile has any writing contrast at all.
  double _inkContrast(Raster g) {
    const cols = 6, rows = 8;
    final values = <double>[];
    for (var ty = 0; ty < rows; ty++) {
      for (var tx = 0; tx < cols; tx++) {
        final tile = g.crop(tx * g.width ~/ cols, ty * g.height ~/ rows, (tx + 1) * g.width ~/ cols, (ty + 1) * g.height ~/ rows);
        if (tile.width < 8 || tile.height < 8) continue;
        final hi = tile.percentile(0.95), lo = tile.percentile(0.05);
        if (hi - lo < 10) continue;
        values.add((hi - lo) / math.max(1, hi));
      }
    }
    if (values.length < 4) return 0;
    values.sort();
    return values[values.length ~/ 2];
  }

  /// Sensor noise (grey levels), after Immerkaer: the response to a mask that
  /// ignores straight edges, taken over the quietest quarter of the tiles.
  double _noise(Raster g) {
    const cols = 6, rows = 8;
    final tiles = <(double, double)>[]; // (tile variance, noise estimate)
    for (var ty = 0; ty < rows; ty++) {
      for (var tx = 0; tx < cols; tx++) {
        final tile = g.crop(tx * g.width ~/ cols, ty * g.height ~/ rows, (tx + 1) * g.width ~/ cols, (ty + 1) * g.height ~/ rows);
        if (tile.width < 8 || tile.height < 8) continue;
        var sum = 0.0;
        for (var y = 1; y < tile.height - 1; y++) {
          for (var x = 1; x < tile.width - 1; x++) {
            final i = y * tile.width + x, w = tile.width;
            final v = tile.data[i - w - 1] -
                2 * tile.data[i - w] +
                tile.data[i - w + 1] -
                2 * tile.data[i - 1] +
                4 * tile.data[i] -
                2 * tile.data[i + 1] +
                tile.data[i + w - 1] -
                2 * tile.data[i + w] +
                tile.data[i + w + 1];
            sum += v.abs();
          }
        }
        final n = (tile.width - 2) * (tile.height - 2);
        final mean = tile.mean();
        var variance = 0.0;
        for (final p in tile.data) {
          variance += (p - mean) * (p - mean);
        }
        tiles.add((variance / tile.data.length, math.sqrt(math.pi / 2) * sum / (6 * n)));
      }
    }
    if (tiles.isEmpty) return 0;
    tiles.sort((a, b) => a.$1.compareTo(b.$1));
    final quiet = tiles.take(math.max(1, tiles.length ~/ 4)).map((t) => t.$2).toList()..sort();
    return quiet[quiet.length ~/ 2];
  }

  /// The biggest bright patch that has lost its detail, as a share of the page.
  double _glare(Raster g) {
    final mask = Raster(g.width, g.height);
    for (var i = 0; i < g.data.length; i++) {
      mask.data[i] = g.data[i] >= 250 ? 255 : 0;
    }
    final blobs = connectedComponents(mask.boxBlur(1), minArea: 12);
    if (blobs.isEmpty) return 0;
    final biggest = blobs.map((b) => b.area).reduce(math.max);
    return biggest / g.data.length;
  }

  /// Median height of the dark marks that are the size of printed characters.
  double _textHeight(Raster g) {
    final bg = g.boxBlur(math.max(4, g.width ~/ 30));
    final mask = Raster(g.width, g.height);
    for (var i = 0; i < g.data.length; i++) {
      mask.data[i] = g.data[i] + 22 < bg.data[i] ? 255 : 0;
    }
    final heights = <int>[
      for (final b in connectedComponents(mask, minArea: 6))
        if (b.height >= 4 && b.height <= 60 && b.width <= 80 && b.area >= 6) b.height,
    ];
    if (heights.length < 20) return 0;
    heights.sort();
    return heights[heights.length ~/ 2].toDouble();
  }

  QualityReport judge(QualityMetrics m) {
    final t = thresholds;
    final issues = <QualityIssue>[];
    void add(String code, QualitySeverity sev, String msg, String advice, double v, double th) =>
        issues.add(QualityIssue(code: code, severity: sev, message: msg, advice: advice, value: v, threshold: th));

    final longSide = math.max(m.originalWidth, m.originalHeight);
    if (longSide < t.blockingLongSidePx) {
      add('low_resolution', QualitySeverity.blocking, 'The photo is very small (${m.originalWidth} x ${m.originalHeight}).',
          'Take it again with the camera at its full resolution, with the booklet filling the picture.', longSide.toDouble(), t.blockingLongSidePx.toDouble());
    } else if (longSide < t.minLongSidePx) {
      add('low_resolution', QualitySeverity.warning, 'The photo is small (${m.originalWidth} x ${m.originalHeight}), so handwriting has few pixels.',
          'Move closer or use the camera at full resolution.', longSide.toDouble(), t.minLongSidePx.toDouble());
    }

    if (m.sharpness < t.blockSharpness) {
      add('blurry', QualitySeverity.blocking, 'The photo is too blurred to read the writing.',
          'Hold the phone steady, let it focus (tap the booklet on the screen), and take it again.', m.sharpness, t.blockSharpness);
    } else if (m.sharpness < t.warnSharpness) {
      add('blurry', QualitySeverity.warning, 'The photo is a little blurred.', 'Hold the phone steady and tap the booklet to focus.', m.sharpness, t.warnSharpness);
    }

    if (m.noise > t.blockNoise) {
      add('noisy', QualitySeverity.blocking, 'The photo is too grainy to read the writing.', 'Take it again in better light; low light makes photos grainy.', m.noise, t.blockNoise);
    } else if (m.noise > t.warnNoise) {
      add('noisy', QualitySeverity.warning, 'The photo is grainy.', 'Take it again in better light.', m.noise, t.warnNoise);
    }

    if (m.darkClip > t.blockDarkClip || m.p98 < t.blockP98) {
      add('too_dark', QualitySeverity.blocking, 'Most of the photo is too dark to see the writing.', 'Take it again in better light, or switch on the light.', m.darkClip, t.blockDarkClip);
    } else if (m.darkClip > t.warnDarkClip || m.p98 < 120) {
      add('too_dark', QualitySeverity.warning, 'The photo is dark, so faint writing may be lost.', 'Take it again in better light.', m.darkClip, t.warnDarkClip);
    }

    if (m.glareFraction > t.blockGlare) {
      add('glare', QualitySeverity.blocking, 'A bright reflection hides part of the page.', 'Tilt the booklet or the phone so the light does not reflect, and take it again.', m.glareFraction, t.blockGlare);
    } else if (m.glareFraction > t.warnGlare) {
      add('glare', QualitySeverity.warning, 'A reflection covers a small part of the page.', 'Tilt the booklet slightly to avoid the reflection.', m.glareFraction, t.warnGlare);
    } else if (m.brightClip > t.warnBrightClip) {
      add('overexposed', QualitySeverity.warning, 'The photo is very bright, so pale ink may be washed out.', 'Take it again with less light on the page.', m.brightClip, t.warnBrightClip);
    }

    if (m.shadowRatio > t.warnShadowRatio) {
      add('uneven_light', QualitySeverity.warning, 'One side of the page is in shadow.', 'Move so your own shadow is not on the page, or use even light.', m.shadowRatio, t.warnShadowRatio);
    }

    if (m.inkContrast < t.blockInkContrast) {
      add('faint', QualitySeverity.blocking, 'The writing is too faint against the paper to read.', 'Take it again in stronger, even light.', m.inkContrast, t.blockInkContrast);
    } else if (m.inkContrast < t.warnInkContrast) {
      add('faint', QualitySeverity.warning, 'The writing is faint against the paper.', 'Take it again in stronger, even light.', m.inkContrast, t.warnInkContrast);
    }

    if (m.textHeightPx > 0 && m.textHeightPx < t.minTextHeightPx) {
      add('text_small', QualitySeverity.warning, 'The text is small in the photo, so handwriting may be too small to read.',
          'Move closer so the booklet fills the picture.', m.textHeightPx, t.minTextHeightPx);
    }

    if (!m.pageFound) {
      add('page_not_found', QualitySeverity.info, 'The edges of the page could not be found, so the page was not straightened.',
          'Photograph the booklet on a plain, darker surface with all four corners in view.', 0, 1);
    } else if (!m.pageFullyVisible) {
      add('cropped', QualitySeverity.warning, 'Part of the page is outside the picture.', 'Step back so all four corners of the booklet are in view.', m.pageAreaFraction, 1);
    }
    if (m.pageFound && m.perspectiveDegrees > t.warnPerspectiveDegrees) {
      add('perspective', QualitySeverity.warning, 'The booklet was photographed at a steep angle.', 'Hold the phone directly above the booklet.', m.perspectiveDegrees, t.warnPerspectiveDegrees);
    }
    if (m.tiltStrength > 0.25 && m.tiltDegrees.abs() > t.warnTiltDegrees) {
      add('tilted', QualitySeverity.info, 'The page is tilted; it is straightened for reading.', 'Hold the phone square to the page for the best result.', m.tiltDegrees.abs(), t.warnTiltDegrees);
    }

    final verdict = issues.any((i) => i.severity == QualitySeverity.blocking)
        ? QualityVerdict.poor
        : (issues.any((i) => i.severity == QualitySeverity.warning) ? QualityVerdict.usable : QualityVerdict.good);
    return QualityReport(metrics: m, issues: issues, verdict: verdict);
  }
}
