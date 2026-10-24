import 'dart:math' as math;
import 'dart:typed_data';

import 'package:unimarkly/services/vision/raster.dart';

/// A photograph-like picture of a marks table, drawn from simple shapes, so
/// tests can state exactly where the ink is. Shapes stand in for characters;
/// which digit a shape "is" is decided by the reader under test, not here.
class SyntheticTable {
  SyntheticTable({this.width = 400, this.height = 800, this.paper = const [236, 214, 208]}) : rgba = Uint8List(width * height * 4) {
    for (var i = 0; i < width * height; i++) {
      rgba[i * 4] = paper[0];
      rgba[i * 4 + 1] = paper[1];
      rgba[i * 4 + 2] = paper[2];
      rgba[i * 4 + 3] = 255;
    }
  }

  final int width, height;
  final List<int> paper;
  final Uint8List rgba;

  static const red = [196, 62, 60];
  static const blue = [40, 60, 150];
  static const teal = [40, 140, 150];

  ColorRaster get image => ColorRaster(width, height, Uint8List.fromList(rgba));

  void _set(int x, int y, List<int> c) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    final p = (y * width + x) * 4;
    rgba[p] = c[0];
    rgba[p + 1] = c[1];
    rgba[p + 2] = c[2];
  }

  void rect(int l, int t, int r, int b, List<int> c) {
    for (var y = t; y < b; y++) {
      for (var x = l; x < r; x++) {
        _set(x, y, c);
      }
    }
  }

  /// A stroke of [thick] pixels from one point to another.
  void line(double x0, double y0, double x1, double y1, List<int> c, {int thick = 2, int dash = 0, int gap = 0}) {
    final len = math.sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0));
    var n = 0;
    var on = true;
    for (var d = 0.0; d <= len; d += 1) {
      final t = len == 0 ? 0.0 : d / len;
      if (on) {
        final cx = (x0 + (x1 - x0) * t).round(), cy = (y0 + (y1 - y0) * t).round();
        rect(cx - thick ~/ 2, cy - thick ~/ 2, cx - thick ~/ 2 + thick, cy - thick ~/ 2 + thick, c);
      }
      n++;
      if (dash > 0 && on && n >= dash) {
        on = false;
        n = 0;
      } else if (dash > 0 && !on && n >= gap) {
        on = true;
        n = 0;
      }
    }
  }

  /// A character-sized ring (a "0"), [h] tall.
  void ring(int left, int top, int h, List<int> c) {
    final w = (h * 0.62).round();
    rect(left, top, left + w, top + 3, c);
    rect(left, top + h - 3, left + w, top + h, c);
    rect(left, top, left + 3, top + h, c);
    rect(left + w - 3, top, left + w, top + h, c);
  }

  /// A character-sized upright stroke with a flag (a "1"), [h] tall.
  void one(int left, int top, int h, List<int> c) {
    rect(left + 6, top, left + 9, top + h, c);
    line(left + 6.0, top.toDouble(), left.toDouble(), top + h * 0.25, c);
  }

  /// A decimal point.
  void point(int left, int baseline, List<int> c) => rect(left, baseline - 5, left + 5, baseline, c);

  /// Printed form: a vertical rule in a colour that is not the pen's.
  void rule(int x, int top, int bottom) => line(x.toDouble(), top.toDouble(), x.toDouble(), bottom.toDouble(), teal, thick: 2);
}
