import 'geometry.dart';
import 'raster.dart';

/// How strong the pen's ink is in an ink picture (0..255), or 0 when nothing is
/// written.
///
/// It must not depend on how much of the picture is ink: a marks table with four
/// written rows in a large empty area is mostly paper, and a level taken from the
/// whole picture (a high percentile, say) lands on the paper and reports "no
/// ink". It must also not mistake paper grain for writing. So it looks only at
/// pieces of ink of real size: pixels above [floor] that join into pieces of at
/// least [minPiece] pixels, and at least [minTotal] such pixels altogether. Grain
/// breaks into specks and is ignored. The level is the 90th percentile of the
/// strength within those pieces.
int inkLevel(Raster ink, {int floor = 28, int minPiece = 12, int minTotal = 40}) {
  final mask = Raster(ink.width, ink.height);
  var any = false;
  for (var i = 0; i < ink.data.length; i++) {
    if (ink.data[i] >= floor) {
      mask.data[i] = 255;
      any = true;
    }
  }
  if (!any) return 0;
  final pieces = connectedComponents(mask, minArea: minPiece);
  if (pieces.isEmpty) return 0;

  final histogram = List<int>.filled(256, 0);
  var total = 0;
  for (final b in pieces) {
    for (var y = b.top; y < b.bottom; y++) {
      for (var x = b.left; x < b.right; x++) {
        final i = y * ink.width + x;
        if (mask.data[i] != 0) {
          histogram[ink.data[i]]++;
          total++;
        }
      }
    }
  }
  if (total < minTotal) return 0;
  final target = total * 0.9;
  var seen = 0;
  for (var v = 0; v < 256; v++) {
    seen += histogram[v];
    if (seen >= target) return v;
  }
  return 255;
}
