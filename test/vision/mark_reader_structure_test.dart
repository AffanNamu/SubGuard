import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/services/vision/digit_model.dart';
import 'package:unimarkly/services/vision/mark_reader.dart';
import 'package:unimarkly/services/vision/raster.dart';

/// How the reader splits a cell into characters, with a stand-in network that
/// records what it was shown (the real network is tested separately).
void main() {
  Raster cell({int w = 220, int h = 90}) => Raster(w, h);

  void rect(Raster r, int l, int t, int rr, int b, [int v = 200]) {
    for (var y = t; y < b; y++) {
      for (var x = l; x < rr; x++) {
        r.data[y * r.width + x] = v;
      }
    }
  }

  late List<Float32List> seen;
  DigitPrediction stub(Float32List input) {
    seen.add(input);
    // Always "sure it is a 7", so the tests are about structure only.
    return DigitPrediction([for (var i = 0; i < 11; i++) i == 7 ? 0.9 : 0.01]);
  }

  setUp(() => seen = []);

  test('a blank cell is blank, not a guess', () {
    final r = MarkReader(stub).read(cell());
    expect(r.blank, isTrue);
    expect(r.text, isNull);
    expect(seen, isEmpty);
  });

  test('faint noise is blank too', () {
    final c = cell();
    for (var i = 0; i < c.data.length; i += 37) {
      c.data[i] = 12;
    }
    expect(MarkReader(stub).read(c).blank, isTrue);
  });

  test('digit, point, digit: three characters in reading order, the point recognised by its size', () {
    final c = cell();
    rect(c, 30, 20, 50, 70); // digit
    rect(c, 80, 56, 88, 64); // point
    rect(c, 110, 20, 135, 70); // digit
    final r = MarkReader(stub).read(c);
    expect(r.chars.map((c) => c.text), ['7', '.', '7']);
    expect(r.text, '7.7');
    expect(seen, hasLength(2), reason: 'only the two digits go to the network');
  });

  test('a decimal point high up (as examiners often write it) is still a point', () {
    final c = cell();
    rect(c, 30, 20, 50, 70);
    rect(c, 80, 26, 88, 34);
    rect(c, 110, 20, 135, 70);
    expect(MarkReader(stub).read(c).chars.map((c) => c.text), ['7', '.', '7']);
  });

  test('two digits with no point are read as two digits and no point is added', () {
    final c = cell();
    rect(c, 30, 20, 50, 70);
    rect(c, 90, 20, 115, 70);
    final r = MarkReader(stub).read(c);
    expect(r.text, '77');
    expect(r.warnings.join(' '), contains('No decimal point'));
  });

  test('a broken digit is joined back together', () {
    final c = cell();
    rect(c, 30, 20, 50, 42);
    rect(c, 30, 45, 50, 70); // gap of 3 px inside the same stroke
    final r = MarkReader(stub).read(c);
    expect(r.chars.where((c) => c.text != '.'), hasLength(1));
  });

  test('two digits that touch are separated at the valley between them', () {
    final c = cell();
    // Two vertical bars joined by a thin bridge.
    rect(c, 40, 25, 58, 61);
    rect(c, 58, 41, 64, 44);
    rect(c, 64, 25, 82, 61);
    final r = MarkReader(stub).read(c);
    expect(r.chars.where((c) => c.text != '.'), hasLength(2));
    expect(r.warnings.join(' '), contains('touching'));
  });

  test('a round zero, with its hollow middle, is one character and is not split', () {
    final c = cell();
    // A ring, 44 wide and 44 tall, strokes 9 thick.
    rect(c, 40, 20, 84, 64);
    for (var y = 29; y < 55; y++) {
      for (var x = 49; x < 75; x++) {
        c.data[y * c.width + x] = 0;
      }
    }
    final r = MarkReader(stub).read(c);
    expect(r.chars.where((c) => c.text != '.'), hasLength(1));
    expect(r.warnings.join(' '), isNot(contains('touching')));
  });

  test('specks too small to matter are ignored and reported', () {
    final c = cell();
    rect(c, 30, 20, 50, 70);
    rect(c, 150, 10, 151, 11);
    final r = MarkReader(stub).read(c);
    expect(r.chars, hasLength(1));
    expect(r.ignoredSpecks, greaterThanOrEqualTo(1));
  });

  test('a long flat stroke is "?", not a digit, and leaves no candidate', () {
    final c = cell();
    rect(c, 30, 20, 50, 70);
    rect(c, 70, 50, 130, 56);
    final r = MarkReader(stub).read(c);
    expect(r.chars.map((c) => c.text), contains('?'));
    expect(r.candidates, isEmpty);
    expect(r.text, isNull);
  });

  test('a network that says "not a digit" gives "?" and no reading', () {
    final c = cell();
    rect(c, 30, 20, 50, 70);
    final reject = MarkReader((_) => DigitPrediction([for (var i = 0; i < 11; i++) i == 10 ? 0.95 : 0.005])).read(c);
    expect(reject.chars.single.text, '?');
    expect(reject.text, isNull);
  });

  test('alternatives are kept and ranked, so a reviewer can see them', () {
    final c = cell();
    rect(c, 30, 20, 50, 70);
    final probs = [for (var i = 0; i < 11; i++) 0.005];
    probs[1] = 0.55;
    probs[7] = 0.40;
    final r = MarkReader((_) => DigitPrediction(probs)).read(c);
    expect(r.candidates.map((c) => c.text).take(2), ['1', '7']);
    expect(r.ambiguity, greaterThan(0.6), reason: '0.40 against 0.55 is close to a toss-up');
  });

  test('the picture handed to the network is 28 x 28 with the character in the middle', () {
    final c = cell();
    rect(c, 30, 20, 50, 70);
    MarkReader(stub).read(c);
    final img = seen.single;
    expect(img.length, 784);
    var sx = 0.0, sy = 0.0, m = 0.0;
    for (var y = 0; y < 28; y++) {
      for (var x = 0; x < 28; x++) {
        final v = img[y * 28 + x];
        sx += v * x;
        sy += v * y;
        m += v;
      }
    }
    expect(sx / m, closeTo(14, 1.5));
    expect(sy / m, closeTo(14, 1.5));
  });
}
