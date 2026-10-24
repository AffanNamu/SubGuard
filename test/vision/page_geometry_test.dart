import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/services/vision/geometry.dart';
import 'package:unimarkly/services/vision/page_geometry.dart';
import 'package:unimarkly/services/vision/raster.dart';

import '../support/booklet_photo.dart';
import '../support/degrade.dart';

/// Page finding and straightening, measured against transformations whose true
/// corners are known. The photo underneath is the one real booklet, so these
/// show how the stage behaves, not how it generalises to other documents.
void main() {
  late ColorRaster photo;
  setUpAll(() async => photo = await loadBooklet());

  const w = 1200, h = 1400;
  final diag = math.sqrt(w * w + h * h);

  Future<({double error, PageDetection found})> run(List<Pt> corners, {List<int> background = const [40, 90, 55]}) async {
    final placed = Degrade.place(photo, w, h, corners, background: background);
    final found = const PageDetector().detect(placed.image);
    final truth = Quad(corners[0], corners[1], corners[2], corners[3]);
    return (error: found.quad == null ? double.infinity : found.quad!.meanCornerError(truth) / diag, found: found);
  }

  group('finding the page', () {
    final cases = <String, List<Pt>>{
      'frontal, centred': const [Pt(150, 100), Pt(1050, 100), Pt(1050, 1300), Pt(150, 1300)],
      'mild keystone (top narrower)': const [Pt(230, 110), Pt(980, 90), Pt(1090, 1290), Pt(120, 1310)],
      'strong keystone': const [Pt(330, 130), Pt(870, 100), Pt(1120, 1290), Pt(90, 1330)],
      'rotated 20 degrees': const [Pt(360, 80), Pt(1110, 360), Pt(840, 1300), Pt(110, 1030)],
      'small in the frame': const [Pt(400, 400), Pt(800, 400), Pt(800, 1000), Pt(400, 1000)],
    };
    final backgrounds = <String, List<int>>{
      'green mat': [40, 90, 55],
      'dark desk': [35, 35, 38],
      'brown wood': [150, 105, 65],
    };

    for (final c in cases.entries) {
      for (final b in backgrounds.entries) {
        test('${c.key} on ${b.key}', () async {
          final r = await run(c.value, background: b.value);
          // ignore: avoid_print
          print('page-detect | ${c.key} | ${b.key} | corner error ${(r.error * 100).toStringAsFixed(2)}% of diagonal | confidence ${r.found.confidence.toStringAsFixed(2)}');
          expect(r.found.quad, isNotNull, reason: r.found.reason);
          expect(r.error, lessThan(0.025), reason: 'mean corner error as a share of the picture diagonal');
          expect(r.found.fullyVisible, isTrue);
        });
      }
    }

    test('a page cut off by the frame is reported as not fully visible', () async {
      final r = await run(const [Pt(-80, 120), Pt(1000, 100), Pt(1060, 1500), Pt(-120, 1480)]);
      expect(r.found.quad, isNotNull);
      expect(r.found.fullyVisible, isFalse);
    });

    test('a white page on a white desk is "not found", not guessed', () async {
      final r = await run(const [Pt(150, 100), Pt(1050, 100), Pt(1050, 1300), Pt(150, 1300)], background: [236, 238, 240]);
      // Either no outline, or an outline the detector itself does not trust.
      expect(r.found.quad == null || r.found.confidence < 0.5 || r.error > 0.02, isTrue,
          reason: 'confidence ${r.found.confidence}, error ${r.error}');
    });
  });

  group('straightening the page', () {
    test('the transform takes a point on the page back to the right place on the photo', () async {
      const corners = [Pt(230, 110), Pt(980, 90), Pt(1090, 1290), Pt(120, 1310)];
      final placed = Degrade.place(photo, w, h, corners);
      final found = const PageDetector().detect(placed.image);
      final page = PageRectifier.rectify(placed.image, found.quad!)!;

      // A point 30% across and 20% down the straightened page, traced back.
      final onPage = Pt(page.image.width * 0.3, page.image.height * 0.2);
      final backOnCanvas = page.pageToPhoto.apply(onPage);
      final expected = placed.photoToCanvas.apply(Pt(photo.width * 0.3, photo.height * 0.2));
      expect(backOnCanvas.dist(expected) / diag, lessThan(0.02));

      // And the round trip is the identity.
      final round = page.photoToPage.apply(page.pageToPhoto.apply(onPage));
      expect(round.dist(onPage), lessThan(0.01));
    });

    test('the straightened page has about the page shape', () async {
      const corners = [Pt(230, 110), Pt(980, 90), Pt(1090, 1290), Pt(120, 1310)];
      final placed = Degrade.place(photo, w, h, corners);
      final page = PageRectifier.rectify(placed.image, const PageDetector().detect(placed.image).quad!)!;
      final aspect = page.image.height / page.image.width;
      expect(aspect, closeTo(photo.height / photo.width, 0.12));
    });
  });

  group('skew', () {
    // The photo has a tilt of its own, so the measurement is checked as a
    // difference from the unturned photo, which is what was actually applied.
    late double baseline;
    setUpAll(() => baseline = SkewEstimator.estimate(photo.toGray()).degrees);

    for (final deg in [-6.0, -3.0, 2.0, 5.0]) {
      test('a page turned $deg degrees reads as $deg degrees more tilt, within a degree', () async {
        final g = photo.toGray();
        final turned = warpRaster(g, SkewEstimator.rotation(deg, g.width, g.height).inverse()!, g.width, g.height);
        final est = SkewEstimator.estimate(turned);
        // ignore: avoid_print
        print('skew | photo own tilt ${baseline.toStringAsFixed(2)} | applied $deg | measured change ${(est.degrees - baseline).toStringAsFixed(2)}');
        expect((est.degrees - baseline - deg).abs(), lessThan(1.0));
      });
    }

    test('a blank page gives no confident answer', () {
      final est = SkewEstimator.estimate(Raster.filled(600, 800, 220));
      expect(est.strength, lessThan(0.05));
    });
  });
}
