import 'dart:math' as math;

import '../../domain/ocr.dart';
import '../vision/geometry.dart';
import '../vision/page_geometry.dart';
import '../vision/quality.dart';
import '../vision/raster.dart';

/// A page picture straightened to a rectangle, with the transform back to the
/// photograph it came from, so every region found on the straightened page can
/// be shown on the original.
class StraightenedPage {
  const StraightenedPage({required this.image, required this.pageToPhoto, required this.photoWidth, required this.photoHeight});

  final ColorRaster image;

  /// Straightened-page pixels to pixels of the working picture it was cut from.
  final Homography pageToPhoto;

  /// Size of that working picture.
  final int photoWidth, photoHeight;

  /// Where a region of the straightened page (fractions of its width and
  /// height) is on the photograph (fractions of its width and height): the
  /// box around the four corners of the region as the camera saw them.
  Region toPhoto(Region r) {
    final w = image.width.toDouble(), h = image.height.toDouble();
    final corners = [
      pageToPhoto.apply(Pt(r.left * w, r.top * h)),
      pageToPhoto.apply(Pt(r.right * w, r.top * h)),
      pageToPhoto.apply(Pt(r.right * w, r.bottom * h)),
      pageToPhoto.apply(Pt(r.left * w, r.bottom * h)),
    ];
    final xs = corners.map((p) => p.x / photoWidth), ys = corners.map((p) => p.y / photoHeight);
    return Region(xs.reduce(math.min), ys.reduce(math.min), xs.reduce(math.max), ys.reduce(math.max)).clamped();
  }
}

/// Decides whether a photograph is worth straightening, and does it.
///
/// A page is straightened only when it was found with confidence, all four
/// corners are in the picture (so they are real corners, not where the frame cut
/// the page), and it is visibly tilted or foreshortened. Otherwise the photograph
/// is read as it is: warping on a doubtful outline would do more harm than good.
class PageStraightener {
  const PageStraightener._();

  static const minConfidence = 0.75;
  static const minAreaFraction = 0.35;
  static const minTiltDegrees = 2.0;
  static const minPerspectiveDegrees = 6.0;

  static bool worthIt(PageDetection page, QualityMetrics m) =>
      page.quad != null &&
      page.fullyVisible &&
      page.confidence >= minConfidence &&
      page.areaFraction >= minAreaFraction &&
      (m.tiltDegrees.abs() >= minTiltDegrees || m.perspectiveDegrees >= minPerspectiveDegrees);

  static StraightenedPage? straighten(ColorRaster photo, PageDetection page, {int maxSide = 2400}) {
    final quad = page.quad;
    if (quad == null) return null;
    final r = PageRectifier.rectify(photo, quad, maxSide: maxSide);
    if (r == null) return null;
    return StraightenedPage(image: r.image, pageToPhoto: r.pageToPhoto, photoWidth: photo.width, photoHeight: photo.height);
  }
}
