import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:unimarkly/domain/ocr.dart';
import 'package:unimarkly/domain/recognition.dart';
import 'package:unimarkly/services/reader/ocr_engine.dart';
import 'package:unimarkly/services/recognition/booklet_pipeline.dart';
import 'package:unimarkly/services/recognition/interfaces.dart';
import 'package:unimarkly/services/recognition/model_registry.dart';
import 'package:unimarkly/services/recognition/orientation.dart';
import 'package:unimarkly/services/reader/booklet_extractor.dart';
import 'package:unimarkly/services/vision/geometry.dart';
import 'package:unimarkly/services/vision/photo_codec.dart';
import 'package:unimarkly/services/vision/raster.dart';

import '../support/booklet_photo.dart';
import '../support/degrade.dart';
import '../support/process_ocr_engine.dart';

/// A booklet photographed sideways or upside down is turned upright before it is
/// read, and what is found on it is shown in the right place on the photo as the
/// examiner sees it. A turn is never made without the booklet's printed labels
/// to justify it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('turning a picture', () {
    // 3 wide, 2 high; every pixel different. Row 0: A B C; row 1: D E F.
    ColorRaster sample() {
      final px = Uint8List(3 * 2 * 4);
      for (var i = 0; i < 6; i++) {
        px[i * 4] = 10 * (i + 1);
        px[i * 4 + 3] = 255;
      }
      return ColorRaster(3, 2, px);
    }

    List<int> reds(ColorRaster r) => [for (var i = 0; i < r.width * r.height; i++) r.rgba[i * 4] ~/ 10];

    test('a quarter-turn clockwise puts the left edge on top', () {
      final t = sample().turned(1);
      expect((t.width, t.height), (2, 3));
      // Turned clockwise: D A / E B / F C.
      expect(reds(t), [4, 1, 5, 2, 6, 3]);
    });

    test('a half-turn reverses it, and three quarters is a quarter the other way', () {
      expect(reds(sample().turned(2)), [6, 5, 4, 3, 2, 1]);
      final t = sample().turned(3);
      expect((t.width, t.height), (2, 3));
      // Turned anticlockwise: C F / B E / A D.
      expect(reds(t), [3, 6, 2, 5, 1, 4]);
    });

    test('turning back is lossless, and a full turn changes nothing', () {
      final s = sample();
      expect(reds(s.turned(4)), reds(s));
      for (var q = 1; q < 4; q++) {
        final back = s.turned(q).turned(4 - q);
        expect((back.width, back.height), (3, 2));
        expect(reds(back), reds(s), reason: 'turn $q then ${4 - q}');
      }
      expect(reds(s.turned(-1)), reds(s.turned(3)));
    });
  });

  group('regions follow the turn', () {
    // A picture with one coloured block in it; after each turn the block is where
    // `PageOrientation.turn` says it is, and `unturn` puts it back.
    const w = 120, h = 80;
    const block = Region(0.55, 0.15, 0.80, 0.40);

    ColorRaster withBlock() {
      final px = Uint8List(w * h * 4)..fillRange(0, w * h * 4, 255);
      for (var y = (block.top * h).round(); y < (block.bottom * h).round(); y++) {
        for (var x = (block.left * w).round(); x < (block.right * w).round(); x++) {
          final o = (y * w + x) * 4;
          px[o] = 200;
          px[o + 1] = 0;
          px[o + 2] = 0;
        }
      }
      return ColorRaster(w, h, px);
    }

    Region blockIn(ColorRaster r) {
      var l = r.width, t = r.height, rt = -1, b = -1;
      for (var y = 0; y < r.height; y++) {
        for (var x = 0; x < r.width; x++) {
          if (r.rgba[(y * r.width + x) * 4 + 1] < 100) {
            if (x < l) l = x;
            if (x > rt) rt = x;
            if (y < t) t = y;
            if (y > b) b = y;
          }
        }
      }
      return Region(l / r.width, t / r.height, (rt + 1) / r.width, (b + 1) / r.height);
    }

    void expectNear(Region a, Region b, {String? reason}) {
      expect(a.left, closeTo(b.left, 0.02), reason: reason);
      expect(a.top, closeTo(b.top, 0.02), reason: reason);
      expect(a.right, closeTo(b.right, 0.02), reason: reason);
      expect(a.bottom, closeTo(b.bottom, 0.02), reason: reason);
    }

    for (var q = 0; q < 4; q++) {
      test('turned $q quarter(s): the block is where turn() says, and unturn() finds it again', () {
        final turned = withBlock().turned(q);
        final seen = blockIn(turned);
        expectNear(seen, PageOrientation.turn(block, q), reason: 'turn');
        expectNear(PageOrientation.unturn(seen, q), block, reason: 'unturn');
      });
    }

    test('turn and unturn are inverses for any region', () {
      const r = Region(0.1, 0.3, 0.45, 0.9);
      for (var q = 0; q < 4; q++) {
        final back = PageOrientation.unturn(PageOrientation.turn(r, q), q);
        expectNear(back, r);
      }
    });
  });

  group('which turns to try first', () {
    OcrDocument doc(List<Region> boxes) => OcrDocument(engine: 't', lines: [for (final b in boxes) OcrLine('Candidate', b)]);

    test('text running up or down a portrait picture: the sideways turns first', () {
      // 600 wide, 800 high: a box 0.04 wide and 0.2 high is 24 x 160 pixels.
      final d = doc(List.generate(8, (i) => Region(0.1 + i * 0.1, 0.1, 0.14 + i * 0.1, 0.3)));
      expect(PageOrientation.verticalTextShare(d, 600, 800), 1);
      expect(PageOrientation.candidates(d, 600, 800), [1, 3, 2]);
    });

    test('text running across: the half-turn first', () {
      final d = doc(List.generate(8, (i) => Region(0.1, 0.1 + i * 0.1, 0.5, 0.14 + i * 0.1)));
      expect(PageOrientation.verticalTextShare(d, 600, 800), 0);
      expect(PageOrientation.candidates(d, 600, 800), [2, 1, 3]);
    });

    test('a photo that is itself landscape is judged in pixels, not fractions', () {
      // 1000 x 400: a box 0.05 wide, 0.2 high is 50 x 80 pixels (tall); 0.2 wide, 0.1 high is 200 x 40 (wide).
      expect(PageOrientation.verticalTextShare(doc([const Region(0, 0, 0.05, 0.2)]), 1000, 400), 1);
      expect(PageOrientation.verticalTextShare(doc([const Region(0, 0, 0.2, 0.1)]), 1000, 400), 0);
    });

    test('short lines (a lone digit) and an empty page say nothing', () {
      const d = OcrDocument(engine: 't', lines: [OcrLine('7', Region(0, 0, 0.02, 0.1)), OcrLine('1 2', Region(0, 0.2, 0.02, 0.3))]);
      expect(PageOrientation.verticalTextShare(d, 600, 800), 0);
      expect(PageOrientation.verticalTextShare(OcrDocument.empty, 600, 800), 0);
    });

    test('every turn has a plain description, and "no turn" has none', () {
      expect(PageOrientation.describe(1), contains('on the left'));
      expect(PageOrientation.describe(3), contains('on the right'));
      expect(PageOrientation.describe(2), contains('upside down'));
      expect(PageOrientation.describe(0), isEmpty);
    });
  });

  group('what counts as evidence that a page is the wrong way round', () {
    // The booklet's labels as a reader would report them when the page is
    // photographed turned [quarters] clockwise.
    OcrDocument shot(int quarters) => OcrDocument(
          engine: 't',
          lines: [for (final l in _labels.lines) OcrLine(l.text, PageOrientation.turn(l.box, quarters), confidence: l.confidence)],
        );
    const extractor = BookletExtractor();

    test('an upright cover: every label found, every relation holds, nothing is suspect', () {
      final r = extractor.extract(shot(0));
      expect(r.foundAnchors, hasLength(5));
      expect(r.layoutContradictions, 0);
      expect(r.layoutSupport, greaterThanOrEqualTo(4));
      expect(PageOrientation.suspect(r, shot(0), 600, 800), isFalse);
    });

    for (var q = 1; q < 4; q++) {
      test('the same cover turned $q quarter(s) is suspect, whatever the position tests let through', () {
        final r = extractor.extract(shot(q));
        // Whatever half-page tests the turned labels happen to pass, the picture is
        // suspect: too few labels, labels in the wrong order, or text running sideways.
        expect(PageOrientation.suspect(r, shot(q), 600, 800), isTrue, reason: 'anchors ${r.foundAnchors.length}, contradicted ${r.layoutContradictions}');
        expect(r.layoutScore, lessThan(extractor.extract(shot(0)).layoutScore));
      });

      test('reading it turned back ${(4 - q) % 4} is clearly better, and the reverse is not', () {
        final turnedBack = extractor.extract(shot(0));
        final asTaken = extractor.extract(shot(q));
        expect(PageOrientation.better(turnedBack, asTaken), isTrue);
        expect(PageOrientation.better(asTaken, turnedBack), isFalse);
      });
    }

    test('an upright photo with one label missing (cropped) is not suspect and costs no extra reading', () {
      final lines = [for (final l in shot(0).lines) if (!l.text.contains('Total')) l];
      final r = extractor.extract(OcrDocument(engine: 't', lines: lines));
      expect(r.foundAnchors, hasLength(4));
      expect(PageOrientation.suspect(r, OcrDocument(engine: 't', lines: lines), 600, 800), isFalse);
    });

    test('a turn that finds the same or fewer labels is not "better", and neither is one with a relation broken', () {
      final upright = extractor.extract(shot(0));
      expect(PageOrientation.better(upright, upright), isFalse);
      final none = extractor.extract(const OcrDocument(engine: 't', lines: []));
      expect(PageOrientation.better(none, upright), isFalse);
    });

    test('the evidence is stored with the layout and read back', () {
      final r = extractor.extract(shot(1));
      final back = BookletReading.fromJson(r.toJson());
      expect(back.layoutSupport, r.layoutSupport);
      expect(back.layoutContradictions, r.layoutContradictions);
      expect(BookletReading.fromJson({}).layoutContradictions, 0, reason: 'a layout stored before this existed');
    });
  });

  group('the pipeline turns a photo only when the labels say so (deterministic reader)', () {
    late Directory work;
    setUpAll(() => work = Directory.systemTemp.createTempSync('unimarkly_orient_'));
    tearDownAll(() => work.deleteSync(recursive: true));

    // An upright picture whose top left corner is marked. The stand-in reader
    // below finds the booklet's labels only when that corner is at the top left.
    ColorRaster upright() {
      const w = 400, h = 560;
      final px = Uint8List(w * h * 4)..fillRange(0, w * h * 4, 250);
      for (var y = 0; y < 60; y++) {
        for (var x = 0; x < 60; x++) {
          final o = (y * w + x) * 4;
          px[o] = 220;
          px[o + 1] = 20;
          px[o + 2] = 20;
        }
      }
      return ColorRaster(w, h, px);
    }

    Future<File> save(ColorRaster r, String name) async {
      final f = File(p.join(work.path, name));
      await f.writeAsBytes(await encodeColorPng(r));
      return f;
    }

    for (var shot = 1; shot < 4; shot++) {
      test('photo turned $shot quarter(s) from upright: turned back by ${(4 - shot) % 4}, regions on the photo', () async {
        final reader = _MarkerReader();
        final photo = await save(upright().turned(shot), 'shot$shot.png');
        final r = await BookletPipeline(ocr: reader).run(photo);

        expect(r.turnedQuarters, (4 - shot) % 4);
        expect(r.layout.foundAnchors, hasLength(5));
        expect(r.notes.join(' '), contains(shot == 2 ? 'upside down' : 'on its side'));
        expect(r.timingsMs.keys, contains('orientation'));

        // The reader found the labels on the upright picture; the regions in the
        // result are those, moved onto the picture as it was photographed.
        final upper = const BookletExtractor().extract(_labels);
        final expected = PageOrientation.turn(upper.examNumberRegion!, shot);
        final got = r.layout.examNumberRegion!;
        expect(got.left, closeTo(expected.left, 1e-6));
        expect(got.top, closeTo(expected.top, 1e-6));
        expect(got.right, closeTo(expected.right, 1e-6));
        expect(got.bottom, closeTo(expected.bottom, 1e-6));

        // The same holds for a field's region (the one handed to "Show on photo").
        final field = r.fields.firstWhere((f) => f.key == 'exam_number');
        expect(field.region, isNotNull);
        expect(field.region!.left, closeTo(expected.left, 1e-6));
        expect(field.region!.bottom, closeTo(expected.bottom, 1e-6));

        // The upright reading is found at the first or second try, never all four.
        expect(reader.wholePhotoReads, lessThanOrEqualTo(4));
        expect(reader.wholePhotoReads, greaterThanOrEqualTo(2));
      });
    }

    test('an upright photo is read once and not turned', () async {
      final reader = _MarkerReader();
      final r = await BookletPipeline(ocr: reader).run(await save(upright(), 'upright.png'));
      expect(r.turnedQuarters, 0);
      expect(reader.wholePhotoReads, 1);
      expect(r.timingsMs.keys, isNot(contains('orientation')));
      expect(r.notes.join(' '), isNot(contains('turned')));
    });

    test('turning is off when asked: read as taken, one reading', () async {
      final reader = _MarkerReader();
      final r = await BookletPipeline(ocr: reader, orient: false).run(await save(upright().turned(1), 'off.png'));
      expect(r.turnedQuarters, 0);
      expect(reader.wholePhotoReads, 1);
    });

    test('labels found nowhere: all three turns are tried, none is kept, and the page is read as taken', () async {
      final reader = _MarkerReader(neverFound: true);
      final r = await BookletPipeline(ocr: reader).run(await save(upright().turned(1), 'nothing.png'));
      expect(r.turnedQuarters, 0);
      expect(reader.wholePhotoReads, 4);
      expect(r.notes.join(' '), contains('tried turned the other three ways'));
      expect(r.layout.foundAnchors, isEmpty);
    });

    test('a photo from which nothing was read at all is not turned (nothing to judge by)', () async {
      final reader = _MarkerReader(empty: true);
      final r = await BookletPipeline(ocr: reader).run(await save(upright().turned(1), 'empty.png'));
      expect(r.turnedQuarters, 0);
      expect(reader.wholePhotoReads, 1);
    });

    test('a reader that fails on one turned try is skipped for that turn, not fatal', () async {
      // The photo needs three quarters. The tries go half-turn, one, three:
      // read 2 (the half-turn) crashes and is skipped; read 4 finds the labels.
      final reader = _MarkerReader(failOn: {2});
      final r = await BookletPipeline(ocr: reader).run(await save(upright().turned(1), 'fail2.png'));
      expect(r.turnedQuarters, 3);
      expect(reader.wholePhotoReads, 4);
    });

    test('cancelling between turns stops the run before the next turn is read', () async {
      final reader = _MarkerReader();
      await expectLater(
        BookletPipeline(ocr: reader).run(await save(upright().turned(1), 'cancel.png'), isCancelled: () => reader.wholePhotoReads >= 2),
        throwsA(isA<RecognitionCancelled>()),
      );
      expect(reader.wholePhotoReads, 2);
    });

    test('the turn is stored and read back with the result', () async {
      final r = await BookletPipeline(ocr: _MarkerReader()).run(await save(upright().turned(3), 'json.png'));
      expect(r.turnedQuarters, 1);
      final back = RecognitionResult.fromJson(r.toJson());
      expect(back.turnedQuarters, 1);
      // A result stored before this existed reads as not turned.
      final old = r.toJson()..remove('turnedQuarters');
      expect(RecognitionResult.fromJson(old).turnedQuarters, 0);
    });
  });

  group('a real booklet photograph, turned (real OCR, real digit network)', () {
    late ColorRaster original;
    late LoadedDigitModel digits;
    ProcessOcrEngine? ocr;
    late Directory work;
    late RecognitionResult upright;

    setUpAll(() async {
      original = await loadBooklet();
      digits = await ModelRegistry.loadDigits();
      ocr = await ProcessOcrEngine.tryStart();
      work = Directory.systemTemp.createTempSync('unimarkly_orient_real_');
      if (ocr != null) upright = await BookletPipeline(ocr: ocr!, digits: digits).run(File(bookletPath));
    });
    tearDownAll(() async {
      work.deleteSync(recursive: true);
      await ocr?.stop();
    });

    for (var shot = 1; shot < 4; shot++) {
      test('photographed with ${const ['', 'its top to the right', 'it upside down', 'its top to the left'][shot]}: turned upright and read like the upright photo', () async {
        if (ocr == null) {
          markTestSkipped('OCR stand-in unavailable (pip install rapidocr-onnxruntime opencv-python-headless)');
          return;
        }
        final file = File(p.join(work.path, 'turned$shot.png'));
        await file.writeAsBytes(await encodeColorPng(original.turned(shot)));

        final asTaken = await BookletPipeline(ocr: ocr!, digits: digits, orient: false).run(file);
        final counting = _Counting(ocr!);
        final r = await BookletPipeline(ocr: counting, digits: digits).run(file);
        // ignore: avoid_print
        print('orientation | real photo turned $shot | labels found as taken: ${asTaken.layout.foundAnchors.length}/5, '
            'after turning: ${r.layout.foundAnchors.length}/5 | turned back by ${r.turnedQuarters} | whole-photo reads: ${counting.wholePhotoReads}');

        expect(r.turnedQuarters, (4 - shot) % 4);
        expect(r.layout.foundAnchors.length, greaterThanOrEqualTo(PageOrientation.minAnchors));
        expect(r.layout.foundAnchors.length, greaterThan(asTaken.layout.foundAnchors.length));
        expect(r.notes.join(' '), contains('turned upright'));

        // Read like the upright photo: the same labels, the same number of rows,
        // and each region where the upright reading's region lands on the turned photo.
        expect(r.layout.foundAnchors.toSet(), upright.layout.foundAnchors.toSet());
        final uprightRows = upright.fields.where((f) => f.key.startsWith('mark_row_') && f.region != null).toList();
        final rows = r.fields.where((f) => f.key.startsWith('mark_row_') && f.region != null).toList();
        expect(rows.length, uprightRows.length);
        for (var i = 0; i < rows.length; i++) {
          final want = PageOrientation.turn(uprightRows[i].region!, shot);
          final got = rows[i].region!;
          expect(got.centerX, closeTo(want.centerX, 0.02), reason: 'row ${i + 1} x');
          expect(got.centerY, closeTo(want.centerY, 0.02), reason: 'row ${i + 1} y');
          expect(rows[i].value, uprightRows[i].value, reason: 'row ${i + 1} reads like the upright photo');
        }
        // Handwriting is still never "recognized" by the machine (a blank box seen
        // as blank is a finding, not a handwritten value).
        final handwritten = r.fields.where((f) => (f.kind == FieldKind.mark || f.kind == FieldKind.registrationNumber) && f.value != null);
        expect(handwritten, isNotEmpty);
        expect(handwritten.every((f) => f.state != FieldState.recognized), isTrue, reason: '${[for (final f in handwritten) '${f.key}=${f.value}:${f.state.name}']}');
      }, timeout: const Timeout(Duration(minutes: 4)));
    }

    test('the upright photograph costs one whole-photo reading and is not turned', () async {
      if (ocr == null) {
        markTestSkipped('OCR stand-in unavailable');
        return;
      }
      final counting = _Counting(ocr!);
      final r = await BookletPipeline(ocr: counting, digits: digits).run(File(bookletPath));
      expect(r.turnedQuarters, 0);
      expect(counting.wholePhotoReads, 1);
    });

    test('a sideways photo of a page lying at an angle is straightened and turned, and the rows are where the camera saw them', () async {
      if (ocr == null) {
        markTestSkipped('OCR stand-in unavailable');
        return;
      }
      // The booklet turned a quarter, then laid on a desk at an angle (the same
      // placement the straightening test uses).
      const w = 1500, h = 1800;
      final sideways = original.turned(1);
      final placed = Degrade.place(sideways, w, h, const [Pt(330, 130), Pt(1170, 100), Pt(1420, 1690), Pt(110, 1730)]);
      final file = File(p.join(work.path, 'sideways_and_tilted.png'));
      await file.writeAsBytes(await encodeColorPng(placed.image));

      final r = await BookletPipeline(ocr: ocr!, digits: digits).run(file);
      // ignore: avoid_print
      print('orientation | sideways and tilted | straightened=${r.straightened} turned back by ${r.turnedQuarters} | labels: ${r.layout.foundAnchors.length}/5');
      expect(r.straightened, isTrue, reason: 'notes: ${r.notes}');
      expect(r.layout.foundAnchors.length, greaterThanOrEqualTo(PageOrientation.minAnchors), reason: 'notes: ${r.notes}');

      // The four annotated mark boxes of the upright photograph, followed through
      // the quarter-turn and the placement to where the camera saw them.
      const boxes = [
        Region(0.775, 0.340, 0.880, 0.378),
        Region(0.775, 0.384, 0.880, 0.420),
        Region(0.775, 0.434, 0.880, 0.472),
        Region(0.775, 0.490, 0.880, 0.532),
      ];
      var found = 0;
      for (final b in boxes) {
        final t = PageOrientation.turn(b, 1);
        final pts = [
          placed.photoToCanvas.apply(Pt(t.left * sideways.width, t.top * sideways.height)),
          placed.photoToCanvas.apply(Pt(t.right * sideways.width, t.top * sideways.height)),
          placed.photoToCanvas.apply(Pt(t.right * sideways.width, t.bottom * sideways.height)),
          placed.photoToCanvas.apply(Pt(t.left * sideways.width, t.bottom * sideways.height)),
        ];
        final cx = pts.map((q) => q.x).reduce((a, c) => a + c) / 4 / w;
        final cy = pts.map((q) => q.y).reduce((a, c) => a + c) / 4 / h;
        final hit = r.fields.where((f) => f.key.startsWith('mark_row_') && f.region != null).any((f) {
          final c = f.region!;
          return cx >= c.left && cx <= c.right && cy >= c.top && cy <= c.bottom;
        });
        if (hit) found++;
      }
      // ignore: avoid_print
      print('orientation | sideways and tilted | rows on the right place: $found/4');
      expect(found, greaterThanOrEqualTo(2), reason: 'rows must be found where the camera saw them even after straightening and turning');
    }, timeout: const Timeout(Duration(minutes: 4)));
  });
}

/// The printed labels of a booklet cover in their usual places, upright.
const _labels = OcrDocument(engine: 'marker', lines: [
  OcrLine("Candidate's Examination Number:", Region(0.05, 0.15, 0.40, 0.19), confidence: 0.9),
  OcrLine("For Examiner's Use Only", Region(0.62, 0.24, 0.95, 0.28), confidence: 0.9),
  OcrLine('Question', Region(0.64, 0.30, 0.74, 0.33), confidence: 0.9),
  OcrLine('Marks', Region(0.78, 0.30, 0.88, 0.33), confidence: 0.9),
  OcrLine('Total', Region(0.66, 0.84, 0.76, 0.88), confidence: 0.9),
]);

/// Finds the booklet's labels only when the picture's marked corner is at its
/// top left, i.e. when the picture is upright. On any other turn it reads
/// plausible-looking text that is not the booklet's labels.
class _MarkerReader implements OcrEngine {
  _MarkerReader({this.neverFound = false, this.empty = false, this.failOn = const {}});

  /// Never finds the labels, whichever way the picture is turned.
  final bool neverFound;

  /// Reads nothing at all.
  final bool empty;

  /// Whole-photo reads (1-based) that throw.
  final Set<int> failOn;

  int wholePhotoReads = 0;

  @override
  String get name => 'marker';

  @override
  Future<OcrDocument> recognize(File image, {required int width, required int height}) async {
    wholePhotoReads++;
    if (failOn.contains(wholePhotoReads)) throw StateError('reader crashed');
    if (empty) return const OcrDocument(engine: 'marker', lines: []);
    final pic = (await decodePhoto(image, maxSide: 4000)).image;
    final cornerIsRed = pic.rgba[1] < 100 && pic.rgba[0] > 150; // pixel (0,0)
    if (cornerIsRed && !neverFound) return _labels;
    return const OcrDocument(engine: 'marker', lines: [
      OcrLine('Department of Agricultural Extension', Region(0.1, 0.05, 0.9, 0.09), confidence: 0.9),
      OcrLine('Faculty of Agriculture', Region(0.1, 0.12, 0.6, 0.16), confidence: 0.9),
    ]);
  }
}

/// Counts whole-photo readings, passing everything through.
class _Counting implements RegionOcrEngine {
  _Counting(this.inner);
  final ProcessOcrEngine inner;
  int wholePhotoReads = 0;

  @override
  String get name => inner.name;

  @override
  Future<OcrDocument> recognize(File image, {required int width, required int height}) {
    wholePhotoReads++;
    return inner.recognize(image, width: width, height: height);
  }

  @override
  Future<OcrDocument> recognizeRegion(File image, Region region) => inner.recognizeRegion(image, region);
}
