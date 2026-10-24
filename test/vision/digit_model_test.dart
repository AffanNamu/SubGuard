import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/services/recognition/model_registry.dart';
import 'package:unimarkly/services/vision/digit_model.dart';
import 'package:unimarkly/services/vision/raster.dart';

import '../support/file_bundle.dart';

/// The digit network: the shipped file is the one the manifest describes, the
/// Dart code computes what PyTorch computed, and the measured accuracy on
/// digits it never trained on is what the manifest claims. None of this says
/// how it reads exam handwriting; see docs/recognition/DATASET.md.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LoadedDigitModel loaded;
  late DigitModel model;

  setUpAll(() async {
    loaded = await ModelRegistry.loadDigits();
    model = loaded.build();
  });

  group('the shipped model file', () {
    test('matches its manifest by size and SHA-256', () {
      expect(loaded.weights.length, loaded.info.bytes);
      expect(loaded.info.id, 'unimarkly-digits');
      expect(loaded.info.sha256, hasLength(64));
    });

    test('a damaged file is refused with words an examiner can read', () async {
      final good = loaded.weights;
      final bad = Uint8List.fromList(good)..[100] ^= 0xFF;
      expect(
        () => ModelRegistry.loadDigits(FileAssetBundle(replaceWeights: true, weights: bad)),
        throwsA(isA<ModelException>().having((e) => e.message, 'message', contains('damaged'))),
      );
    });

    test('a truncated file is refused', () async {
      final short = Uint8List.sublistView(loaded.weights, 0, 4000);
      expect(
        () => ModelRegistry.loadDigits(FileAssetBundle(replaceWeights: true, weights: short)),
        throwsA(isA<ModelException>().having((e) => e.message, 'message', contains('wrong size'))),
      );
    });

    test('a missing file says to reinstall, and nothing else is read in its place', () async {
      expect(
        () => ModelRegistry.loadDigits(FileAssetBundle(replaceWeights: true)),
        throwsA(isA<ModelException>().having((e) => e.message, 'message', contains('Reinstall'))),
      );
    });

    test('weights with an invalid number are refused', () {
      final bytes = Uint8List(DigitModel.weightCount * 4);
      ByteData.sublistView(bytes).setFloat32(0, double.nan, Endian.little);
      expect(() => DigitModel.fromBytes(bytes), throwsFormatException);
    });
  });

  group('the Dart network computes what PyTorch computed', () {
    test('probabilities agree to 1e-4 on 24 test digits', () {
      final fx = jsonDecode(File('test/fixtures/digit_model_parity.json').readAsStringSync()) as Map<String, dynamic>;
      final inputs = (fx['inputs'] as List).cast<String>();
      final expected = (fx['probabilities'] as List).map((r) => (r as List).map((v) => (v as num).toDouble()).toList()).toList();
      expect(inputs, hasLength(24));
      var worst = 0.0;
      for (var i = 0; i < inputs.length; i++) {
        final px = base64Decode(inputs[i]);
        final x = Float32List(784);
        for (var k = 0; k < 784; k++) {
          x[k] = px[k] / 255;
        }
        final p = model.predict(x).probabilities;
        for (var c = 0; c < 11; c++) {
          worst = worst > (p[c] - expected[i][c]).abs() ? worst : (p[c] - expected[i][c]).abs();
        }
      }
      expect(worst, lessThan(1e-4), reason: 'largest difference $worst');
    });
  });

  group('accuracy on held-out digits (MNIST test set, never trained on)', () {
    late Map<String, dynamic> eval;
    setUpAll(() => eval = jsonDecode(File('test/fixtures/digits_eval.json').readAsStringSync()) as Map<String, dynamic>);

    ({int right, int total}) score(String set, {required bool throughNormaliser}) {
      final labels = ((eval[set] as Map)['labels'] as List).cast<int>();
      final images = ((eval[set] as Map)['images'] as List).cast<String>();
      var right = 0;
      for (var i = 0; i < labels.length; i++) {
        final px = base64Decode(images[i]);
        final Float32List x;
        if (throughNormaliser) {
          // The path a real cell takes: crop to the character, then normalise.
          x = DigitNormaliser.toModelInput(_cropToInk(Raster(28, 28, Uint8List.fromList(px))));
        } else {
          x = Float32List(784);
          for (var k = 0; k < 784; k++) {
            x[k] = px[k] / 255;
          }
        }
        if (model.predict(x).best == labels[i]) right++;
      }
      return (right: right, total: labels.length);
    }

    test('clean digits, as stored: at least 95% of 200', () {
      final s = score('clean', throughNormaliser: false);
      // ignore: avoid_print
      print('clean, direct: ${s.right}/${s.total}');
      expect(s.right / s.total, greaterThanOrEqualTo(0.95));
    });

    test('augmented digits (thin, faint, slanted, ruled): at least 80% of 200', () {
      final s = score('augmented', throughNormaliser: false);
      // ignore: avoid_print
      print('augmented, direct: ${s.right}/${s.total}');
      expect(s.right / s.total, greaterThanOrEqualTo(0.80));
    });

    test('clean digits through the app\'s own cropping and normalising: at least 93% of 200', () {
      final s = score('clean', throughNormaliser: true);
      // ignore: avoid_print
      print('clean, via DigitNormaliser: ${s.right}/${s.total}');
      expect(s.right / s.total, greaterThanOrEqualTo(0.93));
    });
  });

  group('what it does with things that are not digits', () {
    DigitPrediction predictOf(Raster r) => model.predict(DigitNormaliser.toModelInput(r));

    test('a plain horizontal stroke is "not a digit"', () {
      final r = Raster(60, 12);
      for (var y = 4; y < 8; y++) {
        for (var x = 0; x < 60; x++) {
          r.data[y * 60 + x] = 255;
        }
      }
      expect(predictOf(r).best, DigitPrediction.rejectClass);
    });

    test('a filled blob is "not a digit"', () {
      final r = Raster(40, 40);
      for (var y = 0; y < 40; y++) {
        for (var x = 0; x < 40; x++) {
          if ((x - 20) * (x - 20) + (y - 20) * (y - 20) < 300) r.data[y * 40 + x] = 255;
        }
      }
      expect(predictOf(r).best, DigitPrediction.rejectClass);
    });

    test('an empty picture does not become a confident digit', () {
      final p = model.predict(Float32List(784));
      expect(p.best == DigitPrediction.rejectClass || p.confidence < 0.9, isTrue, reason: 'empty read as ${p.best} at ${p.confidence}');
    });
  });
}

Raster _cropToInk(Raster r) {
  var l = r.width, t = r.height, rr = 0, b = 0;
  for (var y = 0; y < r.height; y++) {
    for (var x = 0; x < r.width; x++) {
      if (r.data[y * r.width + x] > 40) {
        if (x < l) l = x;
        if (x > rr) rr = x;
        if (y < t) t = y;
        if (y > b) b = y;
      }
    }
  }
  if (rr < l) return r;
  return r.crop(l, t, rr + 1, b + 1);
}
