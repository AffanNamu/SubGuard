import 'dart:math' as math;

import 'ink.dart';
import 'raster.dart';

/// A horizontal band of writing: one row of a marks table.
class RowBand {
  const RowBand(this.top, this.bottom, this.ink);

  final int top;
  final int bottom;

  /// Total ink in the band, for telling real rows from stray marks.
  final int ink;

  int get height => bottom - top;
}

/// Finds the rows of writing in a column of cells.
///
/// Rows are found from where the ink is, not from ruled lines, because many
/// mark tables are not ruled between rows. A gap of clear paper between two
/// bands is what separates two rows; a character's own gaps (a decimal point,
/// a broken stroke) do not.
class TableRows {
  const TableRows._();

  /// [ink] is an ink-strength map of the column (0..255).
  static List<RowBand> find(Raster ink, {double minRowShare = 0.04}) {
    if (ink.width == 0 || ink.height == 0) return const [];
    final strong = inkLevel(ink);
    if (strong == 0) return const [];
    final thr = math.max(14, (strong * 0.5).round());

    final profile = List<int>.filled(ink.height, 0);
    for (var y = 0; y < ink.height; y++) {
      var n = 0;
      for (var x = 0; x < ink.width; x++) {
        if (ink.data[y * ink.width + x] >= thr) n++;
      }
      profile[y] = n;
    }
    // Smooth over a few rows so a thin gap inside a digit does not split it.
    final smooth = List<double>.filled(ink.height, 0);
    const r = 2;
    for (var y = 0; y < ink.height; y++) {
      var s = 0.0;
      var c = 0;
      for (var k = -r; k <= r; k++) {
        final yy = y + k;
        if (yy >= 0 && yy < ink.height) {
          s += profile[yy];
          c++;
        }
      }
      smooth[y] = s / c;
    }
    final peak = smooth.reduce(math.max);
    final floor = math.max(0.8, peak * minRowShare);

    // Bands where the smoothed profile is above the floor.
    final bands = <(int, int)>[];
    int? start;
    for (var y = 0; y < ink.height; y++) {
      if (smooth[y] > floor) {
        start ??= y;
      } else if (start != null) {
        bands.add((start, y));
        start = null;
      }
    }
    if (start != null) bands.add((start, ink.height));
    if (bands.isEmpty) return const [];

    // Join bands separated by a gap shorter than about a quarter of a row.
    final heights = bands.map((b) => b.$2 - b.$1).toList()..sort();
    final typical = heights[heights.length ~/ 2].toDouble();
    final merged = <(int, int)>[bands.first];
    for (final b in bands.skip(1)) {
      final last = merged.last;
      if (b.$1 - last.$2 < typical * 0.25) {
        merged[merged.length - 1] = (last.$1, b.$2);
      } else {
        merged.add(b);
      }
    }

    final out = <RowBand>[];
    for (final b in merged) {
      var n = 0;
      for (var y = b.$1; y < b.$2; y++) {
        n += profile[y];
      }
      out.add(RowBand(b.$1, b.$2, n));
    }
    // A band far smaller than the others is a stray mark, not a row.
    final biggest = out.map((b) => b.ink).reduce(math.max);
    return [for (final b in out) if (b.ink >= biggest * 0.08 && b.height >= 6) b];
  }
}
