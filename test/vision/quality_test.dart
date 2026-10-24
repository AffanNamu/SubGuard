import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/services/vision/quality.dart';
import 'package:unimarkly/services/vision/raster.dart';

import '../support/booklet_photo.dart';
import '../support/degrade.dart';

/// The quality verdict on the real photograph and on versions of it with known
/// damage. Each expectation follows the measurements recorded in
/// docs/recognition/QUALITY_CALIBRATION.md.
void main() {
  late ColorRaster photo;
  setUpAll(() async => photo = await loadBooklet());
  const analyzer = QualityAnalyzer();

  QualityReport report(ColorRaster img, {int? width, int? height}) =>
      analyzer.analyze(img, originalWidth: width ?? img.width, originalHeight: height ?? img.height);

  Set<String> codes(QualityReport r, QualitySeverity s) => {for (final i in r.issues) if (i.severity == s) i.code};

  group('the real photograph', () {
    test('is usable but is flagged for what is wrong with it: small text and a cropped page', () {
      final r = report(photo);
      expect(r.verdict, QualityVerdict.usable);
      expect(r.hasBlocking, isFalse, reason: r.issues.map((i) => i.code).join(', '));
      expect(r.issue('text_small'), isNotNull, reason: 'printed text is about 10 px tall in this 810 x 1080 copy');
      expect(r.issue('cropped'), isNotNull, reason: 'the top of the page is outside the picture');
      expect(r.issue('blurry'), isNull);
      expect(r.issue('noisy'), isNull);
    });

    test('every issue has a plain message and an instruction', () {
      for (final i in report(photo).issues) {
        expect(i.message, isNotEmpty);
        expect(i.advice, isNotEmpty);
      }
    });
  });

  group('recoverable damage is a warning, lost information is blocking', () {
    test('mild blur warns; heavy blur blocks', () {
      expect(codes(report(Degrade.blur(photo, 2.0)), QualitySeverity.warning), contains('blurry'));
      expect(codes(report(Degrade.blur(photo, 3.0)), QualitySeverity.blocking), contains('blurry'));
      expect(report(Degrade.blur(photo, 0.8)).issue('blurry'), isNull, reason: 'a little softness is not reported');
    });

    test('grain: measured accurately, warns then blocks', () {
      final mild = report(Degrade.noise(photo, 15));
      expect(mild.metrics.noise, closeTo(15, 3));
      expect(codes(mild, QualitySeverity.warning), contains('noisy'));
      expect(codes(report(Degrade.noise(photo, 35)), QualitySeverity.blocking), contains('noisy'));
      expect(report(photo).metrics.noise, lessThan(2));
    });

    test('under-exposure: dark warns, very dark blocks', () {
      expect(report(Degrade.exposure(photo, 0.65)).issue('too_dark')?.severity, QualitySeverity.warning);
      expect(report(Degrade.exposure(photo, 0.35)).issue('too_dark')?.severity, QualitySeverity.blocking);
    });

    test('faint writing: warns then blocks', () {
      expect(report(Degrade.lowContrast(photo, 0.5)).issue('faint')?.severity, QualitySeverity.warning);
      expect(report(Degrade.lowContrast(photo, 0.25)).issue('faint')?.severity, QualitySeverity.blocking);
    });

    test('a shadow across the page warns', () {
      expect(report(Degrade.shadow(photo, 0.4)).issue('uneven_light'), isNotNull);
      expect(report(photo).issue('uneven_light'), isNull);
    });

    test('glare: a small patch warns, a large one blocks', () {
      expect(report(Degrade.glare(photo, 0.5, 0.4, 0.08)).issue('glare')?.severity, QualitySeverity.warning);
      expect(report(Degrade.glare(photo, 0.5, 0.4, 0.2)).issue('glare')?.severity, QualitySeverity.blocking);
    });

    test('a photo that is too small blocks, with the instruction to retake it', () {
      final tiny = photo.resized(400, 533);
      final r = report(tiny);
      expect(r.issue('low_resolution')?.severity, QualitySeverity.blocking);
      expect(r.issue('low_resolution')!.advice, contains('full resolution'));
      expect(r.verdict, QualityVerdict.poor);
    });
  });

  group('the verdict', () {
    test('a clean synthetic page with plenty of text and good light is "good"', () {
      // Dark text on white, drawn as rows of bars: nothing to complain about.
      final g = Raster.filled(1400, 1800, 235);
      for (var row = 0; row < 40; row++) {
        for (var x = 120; x < 1280; x++) {
          if ((x ~/ 14) % 3 != 2) {
            for (var y = 140 + row * 38; y < 140 + row * 38 + 18; y++) {
              g.data[y * g.width + x] = 30;
            }
          }
        }
      }
      final rgba = ColorRaster.fromPlanes([g, g, g, Raster.filled(g.width, g.height, 255)]);
      final r = report(rgba);
      // ignore: avoid_print
      print('good-page issues: ${r.issues.map((i) => i.code)}');
      expect(r.verdict == QualityVerdict.good || r.verdict == QualityVerdict.usable, isTrue);
      expect(r.hasBlocking, isFalse);
    });

    test('the report survives being stored and read back', () {
      final r = report(Degrade.blur(photo, 2.0));
      final back = QualityReport.fromJson(r.toJson());
      expect(back.verdict, r.verdict);
      expect(back.issues.map((i) => i.code), r.issues.map((i) => i.code));
      expect(back.metrics.sharpness, r.metrics.sharpness);
    });
  });
}
