import 'dart:math' as math;
import 'dart:typed_data';

import 'raster.dart';

/// What the model says about one character picture.
class DigitPrediction {
  const DigitPrediction(this.probabilities);

  /// 11 values summing to 1: the digits 0 to 9, then "not a digit".
  final List<double> probabilities;

  static const rejectClass = 10;

  int get best {
    var b = 0;
    for (var i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > probabilities[b]) b = i;
    }
    return b;
  }

  double get confidence => probabilities[best];

  /// Classes by probability, most likely first.
  List<MapEntry<int, double>> get ranked => [for (var i = 0; i < probabilities.length; i++) MapEntry(i, probabilities[i])]..sort((a, b) => b.value.compareTo(a.value));

  /// The runner-up's probability relative to the winner's (0 sure, 1 a toss-up).
  double get ambiguity {
    final r = ranked;
    return r[0].value <= 0 ? 1 : r[1].value / r[0].value;
  }
}

/// A small convolutional network for handwritten digits, run in plain Dart.
///
/// Two 5x5 convolutions with pooling, a 64-unit layer and 11 outputs (the ten
/// digits and "not a digit"), 33,000 weights in 131 KB. It runs in a few
/// hundredths of a millisecond a character, needs no native library and gives
/// the same answer on every phone.
///
/// The weights come from `tool/train/train_digits.py`; the file's checksum,
/// training data and measured accuracy are in its manifest. This class only
/// computes; it knows nothing about marks or registration numbers.
class DigitModel {
  DigitModel._(this._w);

  static const int size = 28;
  static const int _c1 = 12, _c2 = 24, _fc = 64, _classes = 11, _k = 5;

  // Offsets of each tensor in the weight file, in floats.
  static const int _conv1W = 0;
  static const int _conv1B = _conv1W + _c1 * _k * _k;
  static const int _conv2W = _conv1B + _c1;
  static const int _conv2B = _conv2W + _c2 * _c1 * _k * _k;
  static const int _fc1W = _conv2B + _c2;
  static const int _fc1B = _fc1W + _fc * _c2 * 4 * 4;
  static const int _fc2W = _fc1B + _fc;
  static const int _fc2B = _fc2W + _classes * _fc;
  static const int weightCount = _fc2B + _classes;

  final Float32List _w;

  /// Reads little-endian float32 weights. Throws if the file is the wrong size,
  /// so a truncated or wrong model is an error and not a quiet misreading.
  factory DigitModel.fromBytes(Uint8List bytes) {
    if (bytes.length != weightCount * 4) {
      throw FormatException('Digit model has ${bytes.length} bytes, expected ${weightCount * 4}.');
    }
    final data = ByteData.sublistView(bytes);
    final w = Float32List(weightCount);
    for (var i = 0; i < weightCount; i++) {
      w[i] = data.getFloat32(i * 4, Endian.little);
      if (w[i].isNaN || w[i].isInfinite) throw const FormatException('Digit model contains an invalid number.');
    }
    return DigitModel._(w);
  }

  /// [image] is 28 x 28 values in 0..1, ink high and paper 0.
  DigitPrediction predict(Float32List image) {
    assert(image.length == size * size);
    // conv1: 1 -> 12, 5x5 valid: 24 x 24
    final a1 = Float32List(_c1 * 24 * 24);
    for (var o = 0; o < _c1; o++) {
      for (var y = 0; y < 24; y++) {
        for (var x = 0; x < 24; x++) {
          var s = _w[_conv1B + o];
          for (var ky = 0; ky < _k; ky++) {
            for (var kx = 0; kx < _k; kx++) {
              s += _w[_conv1W + o * _k * _k + ky * _k + kx] * image[(y + ky) * size + x + kx];
            }
          }
          a1[(o * 24 + y) * 24 + x] = s > 0 ? s : 0;
        }
      }
    }
    final p1 = _pool(a1, _c1, 24); // 12 x 12
    // conv2: 12 -> 24, 5x5 valid: 8 x 8
    final a2 = Float32List(_c2 * 8 * 8);
    for (var o = 0; o < _c2; o++) {
      for (var y = 0; y < 8; y++) {
        for (var x = 0; x < 8; x++) {
          var s = _w[_conv2B + o];
          for (var i = 0; i < _c1; i++) {
            final wBase = _conv2W + ((o * _c1 + i) * _k) * _k;
            for (var ky = 0; ky < _k; ky++) {
              for (var kx = 0; kx < _k; kx++) {
                s += _w[wBase + ky * _k + kx] * p1[(i * 12 + y + ky) * 12 + x + kx];
              }
            }
          }
          a2[(o * 8 + y) * 8 + x] = s > 0 ? s : 0;
        }
      }
    }
    final p2 = _pool(a2, _c2, 8); // 4 x 4, 24 channels -> 384
    // fc1: 384 -> 64
    final h = Float32List(_fc);
    for (var o = 0; o < _fc; o++) {
      var s = _w[_fc1B + o];
      final base = _fc1W + o * p2.length;
      for (var i = 0; i < p2.length; i++) {
        s += _w[base + i] * p2[i];
      }
      h[o] = s > 0 ? s : 0;
    }
    // fc2: 64 -> 11, softmax
    final logits = List<double>.filled(_classes, 0);
    for (var o = 0; o < _classes; o++) {
      var s = _w[_fc2B + o].toDouble();
      final base = _fc2W + o * _fc;
      for (var i = 0; i < _fc; i++) {
        s += _w[base + i] * h[i];
      }
      logits[o] = s;
    }
    final m = logits.reduce(math.max);
    var sum = 0.0;
    final e = [for (final l in logits) math.exp(l - m)];
    for (final v in e) {
      sum += v;
    }
    return DigitPrediction([for (final v in e) v / sum]);
  }

  Float32List _pool(Float32List a, int channels, int side) {
    final half = side ~/ 2;
    final out = Float32List(channels * half * half);
    for (var c = 0; c < channels; c++) {
      for (var y = 0; y < half; y++) {
        for (var x = 0; x < half; x++) {
          final i = (c * side + 2 * y) * side + 2 * x;
          out[(c * half + y) * half + x] = math.max(math.max(a[i], a[i + 1]), math.max(a[i + side], a[i + side + 1]));
        }
      }
    }
    return out;
  }
}

/// Turns the ink of one character into the 28 x 28 picture the model was
/// trained on: cropped to the character, scaled to fit a 20 x 20 box without
/// changing its shape, and placed so its centre of mass is at the centre.
class DigitNormaliser {
  const DigitNormaliser._();

  /// [ink] is the character's ink strength (0..255), tightly cropped.
  static Float32List toModelInput(Raster ink) {
    final out = Float32List(DigitModel.size * DigitModel.size);
    if (ink.width < 1 || ink.height < 1) return out;
    final scale = 20 / math.max(ink.width, ink.height);
    final w = math.max(1, (ink.width * scale).round()), h = math.max(1, (ink.height * scale).round());
    final small = ink.resized(w, h);
    var top = small.percentile(0.995);
    if (top < 16) top = 16;

    // Centre of mass of the small picture, then shift it to (14, 14).
    var sx = 0.0, sy = 0.0, sm = 0.0;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final v = small.data[y * w + x].toDouble();
        sx += v * x;
        sy += v * y;
        sm += v;
      }
    }
    final cx = sm > 0 ? sx / sm : w / 2, cy = sm > 0 ? sy / sm : h / 2;
    final ox = (14 - cx).round().clamp(0, DigitModel.size - w), oy = (14 - cy).round().clamp(0, DigitModel.size - h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        out[(y + oy) * DigitModel.size + x + ox] = (small.data[y * w + x] / top).clamp(0.0, 1.0);
      }
    }
    return out;
  }
}
