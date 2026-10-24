import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:unimarkly/domain/ocr.dart';
import 'package:unimarkly/services/recognition/booklet_pipeline.dart';
import 'package:unimarkly/services/recognition/interfaces.dart' show RecognitionResult;
import 'package:unimarkly/services/recognition/model_registry.dart';
import 'package:unimarkly/services/recognition/straighten.dart';
import 'package:unimarkly/services/vision/geometry.dart';
import 'package:unimarkly/services/vision/page_geometry.dart';
import 'package:unimarkly/services/vision/photo_codec.dart';
import 'package:unimarkly/services/vision/quality.dart';
import 'package:unimarkly/services/vision/raster.dart';

import '../support/booklet_photo.dart';
import '../support/degrade.dart';
import '../support/process_ocr_engine.dart';

/// Straightening the page before it is read: when it is done, that regions found
/// on the straightened page land in the right place on the original photograph,
/// and what it does for reading a photograph taken at an angle.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('mapping a region back to the photograph', () {
    test('a region on the straightened page is the box around where the camera saw it', () {
      // A 100 x 200 straightened page cut from a 1000 x 2000 photograph at
      // (200,300)-(600,300)-(600,1100)-(200,1100): a plain shift and scale.
      final h = Homography.fromPoints(
        const [Pt(0, 0), Pt(100, 0), Pt(100, 200), Pt(0, 200)],
        const [Pt(200, 300), Pt(600, 300), Pt(600, 1100), Pt(200, 1100)],
      )!;
      final page = StraightenedPage(image: ColorRaster(100, 200, Uint8List(100 * 200 * 4)), pageToPhoto: h, photoWidth: 1000, photoHeight: 2000);
      final r = page.toPhoto(const Region(0.5, 0.25, 1, 0.5));
      expect(r.left, closeTo(0.4, 1e-9));
      expect(r.right, closeTo(0.6, 1e-9));
      expect(r.top, closeTo((300 + 0.25 * 800) / 2000, 1e-9));
      expect(r.bottom, closeTo((300 + 0.5 * 800) / 2000, 1e-9));
    });

    test('on a tilted page the box is the bounding box of the four corners', () {
      final h = Homography.fromPoints(
        const [Pt(0, 0), Pt(100, 0), Pt(100, 100), Pt(0, 100)],
        const [Pt(100, 100), Pt(500, 160), Pt(440, 560), Pt(40, 500)],
      )!;
      final page = StraightenedPage(image: ColorRaster(100, 100, Uint8List(100 * 100 * 4)), pageToPhoto: h, photoWidth: 1000, photoHeight: 1000);
      final r = page.toPhoto(const Region(0, 0, 1, 1));
      expect(r.left, closeTo(0.04, 1e-6));
      expect(r.right, closeTo(0.5, 1e-6));
      expect(r.top, closeTo(0.1, 1e-6));
      expect(r.bottom, closeTo(0.56, 1e-6));
    });
  });

  group('when a photograph is straightened', () {
    PageDetection page({double confidence = 0.9, bool visible = true, double area = 0.6}) => PageDetection(
          quad: const Quad(Pt(10, 10), Pt(90, 12), Pt(88, 95), Pt(8, 92)),
          confidence: confidence,
          fullyVisible: visible,
          areaFraction: area,
        );
    QualityMetrics metrics({double tilt = 0, double perspective = 0}) => QualityMetrics(
          originalWidth: 3000,
          originalHeight: 4000,
          sharpness: 1,
          noise: 2,
          p2: 30,
          p98: 230,
          darkClip: 0,
          brightClip: 0,
          shadowRatio: 1,
          glareFraction: 0,
          inkContrast: 0.4,
          textHeightPx: 40,
          tiltDegrees: tilt,
          tiltStrength: 1,
          perspectiveDegrees: perspective,
          pageFound: true,
          pageFullyVisible: true,
          pageAreaFraction: 0.6,
        );

    test('tilted or foreshortened, found with confidence, fully in view: yes', () {
      expect(PageStraightener.worthIt(page(), metrics(tilt: 5)), isTrue);
      expect(PageStraightener.worthIt(page(), metrics(perspective: 12)), isTrue);
    });

    test('already straight: no (warping would only blur it)', () {
      expect(PageStraightener.worthIt(page(), metrics(tilt: 0.5, perspective: 1)), isFalse);
    });

    test('a doubtful outline, a cropped page or a small page: no', () {
      expect(PageStraightener.worthIt(page(confidence: 0.5), metrics(tilt: 8)), isFalse);
      expect(PageStraightener.worthIt(page(visible: false), metrics(tilt: 8)), isFalse);
      expect(PageStraightener.worthIt(page(area: 0.2), metrics(tilt: 8)), isFalse);
      expect(PageStraightener.worthIt(const PageDetection(), metrics(tilt: 8)), isFalse);
    });
  });

  group('reading a photograph taken at an angle (real OCR, real digit network)', () {
    late ColorRaster original;
    late LoadedDigitModel digits;
    ProcessOcrEngine? ocr;
    late Directory work;

    setUpAll(() async {
      original = await loadBooklet();
      digits = await ModelRegistry.loadDigits();
      ocr = await ProcessOcrEngine.tryStart();
      work = Directory.systemTemp.createTempSync('unimarkly_straighten_');
    });
    tearDownAll(() async {
      work.deleteSync(recursive: true);
      await ocr?.stop();
    });

    // The booklet placed on a desk at an angle; the annotated boxes follow it.
    const w = 1500, h = 1800;
    final cases = <String, List<Pt>>{
      'keystone': const [Pt(330, 130), Pt(1170, 100), Pt(1420, 1690), Pt(110, 1730)],
      'rotated 12 degrees': const [Pt(300, 120), Pt(1330, 330), Pt(1130, 1700), Pt(120, 1480)],
    };

    /// How many of the four annotated mark rows fall inside a cell the pipeline found.
    int rowsFound(RecognitionResult r, List<Region> truth) {
      var n = 0;
      for (final t in truth) {
        final hit = r.fields.where((f) => f.key.startsWith('mark_row_') && f.region != null).any((f) {
          final c = f.region!;
          return t.centerX >= c.left && t.centerX <= c.right && t.centerY >= c.top && t.centerY <= c.bottom && c.height <= t.height * 2.5;
        });
        if (hit) n++;
      }
      return n;
    }

    for (final c in cases.entries) {
      test('${c.key}: straightening finds the rows on the right place on the photograph', () async {
        if (ocr == null) {
          markTestSkipped('OCR stand-in unavailable (pip install rapidocr-onnxruntime opencv-python-headless)');
          return;
        }
        final placed = Degrade.place(original, w, h, c.value);
        final file = File(p.join(work.path, '${c.key.replaceAll(' ', '_')}.png'));
        await file.writeAsBytes(await encodeColorPng(placed.image));

        // The annotated mark boxes (fractions of the original), as the camera saw them.
        const boxes = [
          Region(0.775, 0.340, 0.880, 0.378),
          Region(0.775, 0.384, 0.880, 0.420),
          Region(0.775, 0.434, 0.880, 0.472),
          Region(0.775, 0.490, 0.880, 0.532),
        ];
        final truth = [
          for (final b in boxes)
            () {
              final pts = [
                placed.photoToCanvas.apply(Pt(b.left * original.width, b.top * original.height)),
                placed.photoToCanvas.apply(Pt(b.right * original.width, b.top * original.height)),
                placed.photoToCanvas.apply(Pt(b.right * original.width, b.bottom * original.height)),
                placed.photoToCanvas.apply(Pt(b.left * original.width, b.bottom * original.height)),
              ];
              final xs = pts.map((p) => p.x / w), ys = pts.map((p) => p.y / h);
              return Region(xs.reduce((a, b) => a < b ? a : b), ys.reduce((a, b) => a < b ? a : b), xs.reduce((a, b) => a > b ? a : b), ys.reduce((a, b) => a > b ? a : b));
            }(),
        ];

        final straight = await BookletPipeline(ocr: ocr!, digits: digits).run(file);
        final asIs = await BookletPipeline(ocr: ocr!, digits: digits, straighten: false).run(file);
        final a = rowsFound(straight, truth), b = rowsFound(asIs, truth);
        // ignore: avoid_print
        print('straighten | ${c.key} | rows on the right place: $a/4 straightened, $b/4 as taken | straightened=${straight.straightened}');
        expect(straight.straightened, isTrue, reason: 'a tilted, fully visible page should have been straightened: ${straight.notes}');
        expect(asIs.straightened, isFalse);
        expect(a, greaterThanOrEqualTo(b), reason: 'straightening must not make finding the rows worse');
        expect(straight.timingsMs.keys, contains('straighten'));
      }, timeout: const Timeout(Duration(minutes: 3)));
    }

    test('the real photograph (page cropped by the frame) is not straightened', () async {
      if (ocr == null) {
        markTestSkipped('OCR stand-in unavailable');
        return;
      }
      final r = await BookletPipeline(ocr: ocr!, digits: digits).run(File(bookletPath));
      expect(r.straightened, isFalse);
    });
  });
}
