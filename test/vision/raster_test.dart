import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/services/vision/raster.dart';

/// Basic image arithmetic. The large blurs matter most: ink maps and lighting
/// correction estimate the paper with blurs far wider than a small test picture.
void main() {
  group('blurring wide', () {
    test('a flat picture stays flat under a blur wider than the picture', () {
      final flat = Raster.filled(300, 500, 200);
      for (final radius in [1, 50, 127, 128, 129, 300, 700]) {
        final b = flat.boxBlur(radius);
        expect(b.data.every((v) => v == 200), isTrue, reason: 'box blur radius $radius changed a flat picture (mean ${b.mean()})');
      }
    });

    test('a Gaussian with sigma 230 (what a 900 px table crop asks for) keeps the average brightness', () {
      final r = Raster(470, 900);
      for (var i = 0; i < r.data.length; i++) {
        r.data[i] = 160 + (i % 7) * 3;
      }
      final g = r.gaussian(230);
      expect((g.mean() - r.mean()).abs(), lessThan(3), reason: 'blurred mean ${g.mean()} against ${r.mean()}');
    });

    test('ink on paper stands out against the blurred paper level at any picture size', () {
      for (final side in [200, 600, 1200]) {
        final paper = Raster.filled(side, side, 210);
        for (var y = side ~/ 2; y < side ~/ 2 + 12; y++) {
          for (var x = side ~/ 3; x < side ~/ 3 + 60; x++) {
            paper.data[y * side + x] = 120;
          }
        }
        final bg = paper.gaussian(side * 0.25);
        expect(bg.at(side ~/ 3 + 30, side ~/ 2 + 6) - 120, greaterThan(60), reason: 'paper level at the ink, picture $side px');
      }
    });
  });
}
