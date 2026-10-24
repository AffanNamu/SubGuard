import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/services/vision/quality.dart';
import 'package:unimarkly/services/vision/raster.dart';

import '../support/booklet_photo.dart';
import '../support/degrade.dart';

/// Prints the measured quality numbers for the real photograph and for
/// versions of it with known damage. Run with
///   flutter test test/vision/quality_calibration_test.dart
/// to reproduce the table in docs/recognition/QUALITY_CALIBRATION.md.
void main() {
  late ColorRaster photo;
  setUpAll(() async => photo = await loadBooklet());
  const a = QualityAnalyzer();

  void row(String name, ColorRaster img) {
    final m = a.measure(img, originalWidth: img.width, originalHeight: img.height);
    // ignore: avoid_print
    print('QUALITY | ${name.padRight(22)} | sharp ${m.sharpness.toStringAsFixed(2)} noise ${m.noise.toStringAsFixed(1)} | p2 ${m.p2} p98 ${m.p98} | dark ${m.darkClip.toStringAsFixed(2)} bright ${m.brightClip.toStringAsFixed(2)} | shade ${m.shadowRatio.toStringAsFixed(2)} | glare ${m.glareFraction.toStringAsFixed(4)} | inkC ${m.inkContrast.toStringAsFixed(2)} | textH ${m.textHeightPx.toStringAsFixed(1)} | tilt ${m.tiltDegrees.toStringAsFixed(1)}(${m.tiltStrength.toStringAsFixed(2)}) | persp ${m.perspectiveDegrees.toStringAsFixed(0)} | page ${m.pageFound}/${m.pageFullyVisible}');
  }

  test('measurement table', () {
    row('original', photo);
    for (final s in [1.0, 1.5, 2.0, 3.0, 4.0, 6.0]) {
      row('blur sigma $s', Degrade.blur(photo, s));
    }
    for (final k in [0.7, 0.5, 0.35, 0.2]) {
      row('exposure x$k', Degrade.exposure(photo, k));
    }
    for (final k in [0.45, 0.3, 0.2, 0.12]) {
      row('contrast keep $k', Degrade.lowContrast(photo, k));
    }
    for (final d in [0.7, 0.5, 0.3]) {
      row('shadow to $d', Degrade.shadow(photo, d));
    }
    for (final r in [0.03, 0.08, 0.2]) {
      row('glare radius $r', Degrade.glare(photo, 0.5, 0.4, r));
    }
    for (final s in [10.0, 25.0]) {
      row('noise sigma $s', Degrade.noise(photo, s));
    }
    for (final f in [0.75, 0.5, 0.35]) {
      row('downscale x$f', photo.resized((photo.width * f).round(), (photo.height * f).round()));
    }
    expect(File(bookletPath).existsSync(), isTrue);
  });
}
