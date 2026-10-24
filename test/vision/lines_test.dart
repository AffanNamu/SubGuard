import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/services/vision/lines.dart';
import 'package:unimarkly/services/vision/raster.dart';

/// Long straight strokes: what is a line, and what is only writing.
void main() {
  Raster blank({int w = 240, int h = 320}) => Raster(w, h);

  void dot(Raster r, int cx, int cy, [int rad = 1]) {
    for (var y = cy - rad; y <= cy + rad; y++) {
      for (var x = cx - rad; x <= cx + rad; x++) {
        if (x >= 0 && y >= 0 && x < r.width && y < r.height) r.data[y * r.width + x] = 255;
      }
    }
  }

  void segment(Raster r, double x0, double y0, double x1, double y1, {int dash = 0, int gap = 0}) {
    final len = math.sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0));
    var drawn = 0;
    var on = true;
    for (var d = 0.0; d <= len; d += 1) {
      final t = d / len;
      if (on) dot(r, (x0 + (x1 - x0) * t).round(), (y0 + (y1 - y0) * t).round());
      drawn++;
      if (dash > 0 && on && drawn >= dash) {
        on = false;
        drawn = 0;
      } else if (dash > 0 && !on && drawn >= gap) {
        on = true;
        drawn = 0;
      }
    }
  }

  test('a diagonal drawn in dashes is found as one line', () {
    final r = blank();
    segment(r, 20, 300, 220, 40, dash: 14, gap: 6);
    final lines = LineFinder.find(r, minLength: 100);
    expect(lines, hasLength(1));
    expect(lines.single.length, greaterThan(230));
  });

  test('a long horizontal underline is found', () {
    final r = blank();
    segment(r, 10, 280, 230, 283);
    expect(LineFinder.find(r, minLength: 100), hasLength(1));
  });

  test('a digit-sized stroke is not a line', () {
    final r = blank();
    segment(r, 60, 100, 60, 130); // a "1": one character tall
    segment(r, 100, 100, 120, 130);
    segment(r, 150, 100, 165, 100);
    expect(LineFinder.find(r, minLength: 100), isEmpty);
  });

  test('scattered handwriting-like strokes are not a line', () {
    final r = blank();
    final rnd = math.Random(3);
    for (var i = 0; i < 40; i++) {
      final x = 20 + rnd.nextInt(200), y = 20 + rnd.nextInt(280);
      segment(r, x.toDouble(), y.toDouble(), x + rnd.nextInt(24) - 12.0, y + rnd.nextInt(24) - 12.0);
    }
    expect(LineFinder.find(r, minLength: 120), isEmpty);
  });

  test('two separate lines are both found', () {
    final r = blank();
    segment(r, 10, 40, 230, 40);
    segment(r, 30, 300, 210, 100, dash: 20, gap: 5);
    expect(LineFinder.find(r, minLength: 100), hasLength(2));
  });

  test('a line is found even when a cluster of character strokes is the strongest collinear set', () {
    final r = blank();
    // Four upright strokes in a row at the same x make a strong vertical cluster,
    // but only one character tall; the dashed diagonal is the real line.
    for (var i = 0; i < 4; i++) {
      segment(r, 40, 40.0 + i * 8, 40, 46.0 + i * 8);
      segment(r, 41, 40.0 + i * 8, 41, 46.0 + i * 8);
    }
    segment(r, 70, 300, 210, 100, dash: 12, gap: 6);
    final lines = LineFinder.find(r, minLength: 100);
    expect(lines, hasLength(1));
    expect(lines.single.length, greaterThan(150));
  });

  test('erasing a line leaves writing that merely crosses it', () {
    final r = blank();
    segment(r, 20, 300, 220, 40);
    // A "digit" beside the line, away from it.
    segment(r, 40, 60, 40, 90);
    segment(r, 40, 60, 60, 60);
    final lines = LineFinder.find(r, minLength: 100);
    LineFinder.erase(r, lines);
    expect(r.at(40, 75), 255, reason: 'the stroke away from the line survives');
    expect(r.at(120, 170), 0, reason: 'the line itself is gone');
  });
}
