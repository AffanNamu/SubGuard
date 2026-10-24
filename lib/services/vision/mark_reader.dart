import 'dart:math' as math;
import 'dart:typed_data';

import 'digit_model.dart';
import 'geometry.dart';
import 'raster.dart';

/// One character found in a cell: a digit, a decimal point, or something that
/// could not be read.
class MarkChar {
  const MarkChar({required this.text, required this.box, required this.alternatives, required this.confidence, this.prediction});

  /// '0'..'9', '.', or '?' when the picture is not a readable character.
  final String text;

  /// Where it is in the cell picture, pixels (right and bottom exclusive).
  final ({int left, int top, int right, int bottom}) box;

  /// Other readings of this character, most likely first, with their probabilities.
  final List<({String text, double probability})> alternatives;

  final double confidence;
  final DigitPrediction? prediction;
}

/// A reading of the whole cell and the next best ones.
class MarkCandidate {
  const MarkCandidate(this.text, this.score);
  final String text;

  /// Product of the characters' probabilities. Not a calibrated chance of being
  /// right: it ranks readings of this one cell against each other.
  final double score;
}

/// What was read in a cell, with the evidence behind it.
class MarkReading {
  const MarkReading({
    required this.chars,
    required this.candidates,
    required this.blank,
    required this.warnings,
    this.ignoredSpecks = 0,
  });

  final List<MarkChar> chars;

  /// Best first. Empty when nothing readable was found.
  final List<MarkCandidate> candidates;

  /// No ink worth reading was found in the cell.
  final bool blank;
  final List<String> warnings;
  final int ignoredSpecks;

  String? get text => candidates.isEmpty ? null : candidates.first.text;

  /// Product of the best reading's characters' top probabilities, or 0.
  double get rawConfidence => candidates.isEmpty ? 0 : candidates.first.score;

  /// How close the runner-up reading is to the best (0 clear winner, 1 tie).
  double get ambiguity => candidates.length < 2 || candidates.first.score <= 0 ? 0 : candidates[1].score / candidates.first.score;
}

/// Reads a handwritten mark such as "5.5" from the ink picture of its cell.
///
/// It finds the separate characters by their ink, tells decimal points from
/// digits by size, and reads each digit with the digit network. It reports every
/// alternative it considered and never fills a gap: a missing decimal point is
/// not added, a character that does not look like a digit is a "?", and a
/// reading is only as good as its weakest character.
class MarkReader {
  const MarkReader(this.predict, {this.maxDigitsPerCell = 5});

  final DigitPrediction Function(Float32List input) predict;
  final int maxDigitsPerCell;

  /// [ink] is the cell's ink strength, 0..255 (see `Enhancer.redInk` / `darkInk`).
  MarkReading read(Raster ink) {
    final warnings = <String>[];
    final strong = ink.percentile(0.995);
    if (strong < 28) return const MarkReading(chars: [], candidates: [], blank: true, warnings: []);

    // Binary ink mask. A fixed share of the strongest ink, so a faint cell is
    // judged against its own pen, not against a global level.
    final threshold = math.max(14, math.min(ink.otsu(), (strong * 0.55).round()));
    final raw = Raster(ink.width, ink.height);
    for (var i = 0; i < ink.data.length; i++) {
      raw.data[i] = ink.data[i] >= threshold ? 255 : 0;
    }

    // Characters are often broken into pieces: join pieces that nearly touch.
    final first = connectedComponents(raw, minArea: 3);
    if (first.isEmpty) return const MarkReading(chars: [], candidates: [], blank: true, warnings: []);
    first.sort((a, b) => b.area.compareTo(a.area));
    final hRef = first.take(math.min(2, first.length)).map((b) => b.height).reduce(math.max).toDouble();
    final reach = math.max(1, (hRef * 0.07).round());
    final joined = _dilate(raw, reach);
    var groups = connectedComponents(joined, minArea: 4);

    // Specks too small to be a digit or a point are not part of the mark.
    final specksBelow = hRef * hRef * 0.006;
    var specks = 0;
    groups = [
      for (final g in groups)
        if (_inkIn(raw, g) >= specksBelow) g else (() {
          specks++;
          return null;
        })()
    ].whereType<Blob>().toList();
    if (groups.isEmpty) return MarkReading(chars: const [], candidates: const [], blank: true, warnings: const [], ignoredSpecks: specks);

    final boxes = [for (final g in groups) (left: g.left, top: g.top, right: g.right, bottom: g.bottom)];
    final tallest = boxes.map((b) => b.bottom - b.top).reduce(math.max).toDouble();

    // Sort left to right, then split any group that is clearly two characters.
    boxes.sort((a, b) => a.left.compareTo(b.left));
    final parts = <({int left, int top, int right, int bottom})>[];
    for (final b in boxes) {
      final w = b.right - b.left, h = b.bottom - b.top;
      if (h > tallest * 0.5 && w > h * 1.1) {
        final cut = _valley(raw, b);
        if (cut != null) {
          parts.add((left: b.left, top: b.top, right: cut, bottom: b.bottom));
          parts.add((left: cut, top: b.top, right: b.right, bottom: b.bottom));
          warnings.add('Two characters were touching and were separated.');
          continue;
        }
      }
      parts.add(b);
    }

    final chars = <MarkChar>[];
    for (final b in parts) {
      final w = b.right - b.left, h = b.bottom - b.top;
      final isPoint = h < tallest * 0.4 && w < tallest * 0.55;
      if (isPoint) {
        chars.add(MarkChar(text: '.', box: b, alternatives: const [], confidence: 1));
        continue;
      }
      if (h < tallest * 0.4) {
        // Wider than a point and short: a dash or a stroke, not a digit.
        chars.add(MarkChar(text: '?', box: b, alternatives: const [], confidence: 0));
        warnings.add('A mark that is not a digit or a point was found.');
        continue;
      }
      final crop = _cropInk(ink, raw, b);
      final pred = predict(DigitNormaliser.toModelInput(crop));
      final ranked = pred.ranked;
      final best = ranked.first;
      final rejected = best.key == DigitPrediction.rejectClass;
      chars.add(MarkChar(
        text: rejected ? '?' : '${best.key}',
        box: b,
        alternatives: [
          for (final e in ranked.skip(1).take(3))
            if (e.value >= 0.02) (text: e.key == DigitPrediction.rejectClass ? '?' : '${e.key}', probability: e.value),
        ],
        confidence: best.value,
        prediction: pred,
      ));
    }

    final digits = chars.where((c) => c.text != '.').length;
    if (digits > maxDigitsPerCell) warnings.add('More characters than a mark has were found.');
    final points = chars.where((c) => c.text == '.').length;
    if (points > 1) warnings.add('More than one decimal point was found.');
    if (digits >= 2 && points == 0) warnings.add('No decimal point was seen between the digits; none has been added.');
    if (chars.any((c) => c.text == '?')) warnings.add('At least one character could not be read.');
    if (specks > 0) warnings.add('$specks small marks were ignored.');

    return MarkReading(chars: chars, candidates: _candidates(chars), blank: false, warnings: warnings, ignoredSpecks: specks);
  }

  /// The best few readings of the whole cell: each digit's top choices, combined
  /// and ranked by the product of their probabilities. A cell with an unreadable
  /// character has no candidates.
  List<MarkCandidate> _candidates(List<MarkChar> chars) {
    if (chars.isEmpty || chars.any((c) => c.text == '?')) return const [];
    var beams = <({String text, double score})>[(text: '', score: 1)];
    for (final c in chars) {
      final options = c.text == '.'
          ? [(text: '.', probability: 1.0)]
          : [(text: c.text, probability: c.confidence), ...c.alternatives.where((a) => a.text != '?')];
      final next = <({String text, double score})>[];
      for (final b in beams) {
        for (final o in options) {
          next.add((text: b.text + o.text, score: b.score * o.probability));
        }
      }
      next.sort((a, b) => b.score.compareTo(a.score));
      beams = next.take(8).toList();
    }
    return [for (final b in beams.take(4)) MarkCandidate(b.text, b.score)];
  }

  // ---- helpers ----

  Raster _dilate(Raster mask, int r) {
    // Box blur then threshold: a cheap dilation by about r pixels.
    final b = mask.boxBlur(r);
    final out = Raster(mask.width, mask.height);
    for (var i = 0; i < out.data.length; i++) {
      out.data[i] = b.data[i] > 0 ? 255 : 0;
    }
    return out;
  }

  int _inkIn(Raster raw, Blob g) {
    var n = 0;
    for (var y = g.top; y < g.bottom; y++) {
      for (var x = g.left; x < g.right; x++) {
        if (raw.data[y * raw.width + x] != 0) n++;
      }
    }
    return n;
  }

  /// The column with the least ink in the middle of a wide group: where two
  /// touching characters most likely meet. Null if there is no clear valley.
  int? _valley(Raster raw, ({int left, int top, int right, int bottom}) b) {
    final w = b.right - b.left;
    final sums = List<int>.filled(w, 0);
    for (var x = 0; x < w; x++) {
      for (var y = b.top; y < b.bottom; y++) {
        if (raw.data[y * raw.width + b.left + x] != 0) sums[x]++;
      }
    }
    final lo = (w * 0.3).floor(), hi = (w * 0.7).ceil();
    var best = lo;
    for (var x = lo; x < hi; x++) {
      if (sums[x] < sums[best]) best = x;
    }
    final avg = sums.reduce((a, b) => a + b) / w;
    // Strict: a round "0" or "8" also has little ink in its middle columns.
    return sums[best] <= avg * 0.22 ? b.left + best : null;
  }

  /// The ink strength inside [b], with ink that belongs to no neighbour kept.
  Raster _cropInk(Raster ink, Raster raw, ({int left, int top, int right, int bottom}) b) {
    final w = b.right - b.left, h = b.bottom - b.top;
    final out = Raster(w, h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        out.data[y * w + x] = ink.data[(b.top + y) * ink.width + b.left + x];
      }
    }
    return out;
  }
}
