import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:unimarkly/domain/layout_profile.dart';
import 'package:unimarkly/domain/ocr.dart';
import 'package:unimarkly/services/reader/booklet_extractor.dart';
import 'package:unimarkly/services/reader/ocr_engine.dart';
import 'package:unimarkly/services/recognition/booklet_pipeline.dart';
import 'package:unimarkly/services/recognition/interfaces.dart' show RecognitionResult;
import 'package:unimarkly/services/recognition/model_registry.dart';
import 'package:unimarkly/services/recognition/orientation.dart';
import 'package:unimarkly/services/vision/photo_codec.dart';

import '../support/legacy_extractor.dart';
import '../support/synthetic_table.dart';

/// A booklet cover described as data: the built-in profile reads every document exactly as
/// the hard-coded reader did, a file is checked before it is trusted, and a different
/// cover can be read by writing a different file.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  OcrDocument fixture(String name) {
    final j = jsonDecode(File('test/fixtures/$name').readAsStringSync()) as Map<String, dynamic>;
    return OcrDocument(
      engine: j['engine'] as String,
      lines: [
        for (final l in (j['lines'] as List).cast<Map<String, dynamic>>())
          OcrLine(
            l['text'] as String,
            Region((l['left'] as num).toDouble(), (l['top'] as num).toDouble(), (l['right'] as num).toDouble(), (l['bottom'] as num).toDouble()),
            confidence: (l['confidence'] as num).toDouble(),
          ),
      ],
    );
  }

  group('the built-in profile', () {
    test('survives being written out and read back', () {
      final back = LayoutProfile.parse(LayoutProfile.modibboAdama.encode());
      expect(back, LayoutProfile.modibboAdama);
      expect(back.canonical, LayoutProfile.modibboAdama.canonical);
    });

    test('is the file in the documentation, which is what a person starts from', () {
      final onDisk = File('docs/recognition/layouts/modibbo_adama.json').readAsStringSync();
      expect(onDisk.trim(), LayoutProfile.modibboAdama.encode().trim(), reason: 'regenerate the file from LayoutProfile.modibboAdama.encode()');
      expect(LayoutProfile.parse(onDisk), LayoutProfile.modibboAdama);
    });

    test('the documented second example is a valid file', () {
      final example = LayoutProfile.parse(File('docs/recognition/layouts/example_left_table.json').readAsStringSync());
      expect(example.id, 'example-left-table');
      expect(example.anchors.map((a) => a.key), ['matric', 'item', 'score', 'grand']);
      expect(example, isNot(LayoutProfile.modibboAdama));
    });

    test('is the layout BookletExtractor reads, and says which in the record', () {
      const extractor = BookletExtractor();
      expect(extractor.profile, LayoutProfile.modibboAdama);
      expect(extractor.info['id'], 'layout:modibbo-adama-cover');
      expect(extractor.info['name'], contains('Modibbo Adama'));
      expect(extractor.info['version'], '1');
    });
  });

  group('the profile engine reads every document the way the hard-coded reader did', () {
    const classList = ['FWM/24U/0537', 'FWM/24U/0538', 'FWM/24U/0539', 'FST/25U/244/5772'];
    const legacy = LegacyBookletExtractor();
    const profiled = BookletExtractor();

    /// Same structure, same text, same flags; numbers equal to rounding.
    void same(Object? a, Object? b, String path) {
      if (a is num && b is num) {
        expect(a.toDouble(), closeTo(b.toDouble(), 1e-9), reason: path);
      } else if (a is Map && b is Map) {
        expect(a.keys.toSet(), b.keys.toSet(), reason: path);
        for (final k in a.keys) {
          same(a[k], b[k], '$path.$k');
        }
      } else if (a is List && b is List) {
        expect(a.length, b.length, reason: path);
        for (var i = 0; i < a.length; i++) {
          same(a[i], b[i], '$path[$i]');
        }
      } else {
        expect(a, b, reason: path);
      }
    }

    void compare(OcrDocument doc, {OcrDocument? crop, String reason = ''}) {
      final a = legacy.extract(doc, examNumberCrop: crop, classList: classList);
      final b = profiled.extract(doc, examNumberCrop: crop, classList: classList);
      same(a.toJson(), b.toJson(), reason);
    }

    test('the two real OCR readings of real booklet covers', () {
      for (final name in ['sample_booklet_ocr.json', 'sample2_booklet_ocr.json']) {
        compare(fixture(name), reason: name);
        compare(fixture(name), crop: const OcrDocument(engine: 'crop', lines: [OcrLine('7200/0538', Region(0, 0.1, 1, 0.9), confidence: 0.55)]), reason: '$name with a close-up');
      }
    });

    test('the same covers photographed turned any of the four ways', () {
      for (final name in ['sample_booklet_ocr.json', 'sample2_booklet_ocr.json']) {
        for (var q = 0; q < 4; q++) {
          final doc = fixture(name);
          compare(OcrDocument(engine: doc.engine, lines: [for (final l in doc.lines) OcrLine(l.text, PageOrientation.turn(l.box, q), confidence: l.confidence)]), reason: '$name turned $q');
        }
      }
    });

    test('nothing read, and a note from the reader', () {
      compare(OcrDocument.empty);
      compare(const OcrDocument(engine: 'none', lines: [], note: 'Automatic reading is not available on this device.'));
    });

    test('400 damaged readings: lines lost, boxes moved, words misspelt, junk added', () {
      final rnd = math.Random(2026);
      final sources = [fixture('sample_booklet_ocr.json'), fixture('sample2_booklet_ocr.json')];
      const junk = ['MARKS', 'Total', 'Question', 'For Examiner\'s Use Only', 'Candidate', 'UNIVERSITY', '292011', '48 29 11', '1 2 4', '1,2,3', 'NUMBER YOUR ANSWERS', 'answers', 'have been written', 'x'];
      String typo(String s) {
        if (s.length < 3 || rnd.nextInt(3) != 0) return s;
        final i = rnd.nextInt(s.length);
        return rnd.nextBool() ? s.replaceRange(i, i + 1, '') : s.replaceRange(i, i + 1, 'e');
      }

      for (var n = 0; n < 400; n++) {
        final base = sources[rnd.nextInt(sources.length)];
        final q = rnd.nextInt(4);
        final dx = (rnd.nextDouble() - 0.5) * 0.06, dy = (rnd.nextDouble() - 0.5) * 0.06;
        final lines = <OcrLine>[
          for (final l in base.lines)
            if (rnd.nextInt(5) != 0)
              OcrLine(
                typo(l.text),
                PageOrientation.turn(Region(l.box.left + dx, l.box.top + dy, l.box.right + dx, l.box.bottom + dy), q),
                confidence: l.confidence,
              ),
          for (var j = 0; j < rnd.nextInt(5); j++)
            OcrLine(junk[rnd.nextInt(junk.length)], () {
              final l = rnd.nextDouble() * 0.8, t = rnd.nextDouble() * 0.9;
              return Region(l, t, l + 0.05 + rnd.nextDouble() * 0.2, t + 0.01 + rnd.nextDouble() * 0.04);
            }(), confidence: 0.5 + rnd.nextDouble() * 0.5),
        ]..shuffle(rnd);
        compare(OcrDocument(engine: 't', lines: lines), reason: 'damaged reading #$n');
      }
    });
  });

  group('a layout file is checked before it is used', () {
    Map<String, dynamic> good() => jsonDecode(LayoutProfile.modibboAdama.encode()) as Map<String, dynamic>;

    /// Parses a copy of the built-in file changed by [edit] and returns what was said.
    String problem(void Function(Map<String, dynamic> j) edit) {
      final j = good();
      edit(j);
      try {
        LayoutProfile.fromJson(j);
      } on LayoutProfileException catch (e) {
        return e.message;
      }
      fail('expected the file to be refused');
    }

    test('text that is not JSON, or not an object, or too large', () {
      expect(() => LayoutProfile.parse('{nope'), throwsA(isA<LayoutProfileException>().having((e) => e.message, 'message', contains('not valid JSON'))));
      expect(() => LayoutProfile.parse('[1,2]'), throwsA(isA<LayoutProfileException>().having((e) => e.message, 'message', contains('JSON object'))));
      expect(() => LayoutProfile.parse('{"a": "${'x' * (LayoutProfile.maxFileBytes + 1)}"}'), throwsA(isA<LayoutProfileException>().having((e) => e.message, 'message', contains('too large'))));
    });

    test('the schema number, the id and the name', () {
      expect(problem((j) => j['schema'] = 2), contains('schema: should be 1'));
      expect(problem((j) => j.remove('schema')), contains('schema'));
      expect(problem((j) => j['id'] = 'Has Spaces'), contains('id: "Has Spaces" should be 3 to 48 lower-case'));
      expect(problem((j) => j['name'] = 'ab'), contains('name: should be 3 to 80 characters'));
      expect(problem((j) => j['revision'] = 0), contains('revision'));
    });

    test('a setting nobody knows is named, not ignored', () {
      expect(problem((j) => j['colour'] = 'red'), contains('layout.colour: is not a known setting'));
      expect(problem((j) => ((j['anchors'] as List).first as Map)['wrods'] = ['x']), contains('anchors[0].wrods: is not a known setting'));
    });

    test('labels: keys, words, positions', () {
      expect(problem((j) => j['anchors'] = []), contains('anchors: should have at least 1 item'));
      expect(problem((j) => ((j['anchors'] as List)[1] as Map)['key'] = 'exam_label'), contains('anchors[1].key: "exam_label" is used twice'));
      expect(problem((j) => ((j['anchors'] as List).first as Map)['key'] = 'Exam Label'), contains('anchors[0].key'));
      expect(problem((j) => ((j['anchors'] as List).first as Map)['words'] = []), contains('anchors[0].words: should have at least 1 item'));
      expect(problem((j) => ((j['anchors'] as List).first as Map)['words'] = ['Can did']), contains('anchors[0].words[0]: "Can did" should be 3 to 20 lower-case letters'));
      expect(problem((j) => ((j['anchors'] as List).first as Map)['where'] = {'middle': {'lt': 0.5}}), contains('anchors[0].where.middle: is not a position'));
      expect(problem((j) => ((j['anchors'] as List).first as Map)['where'] = {'left': {}}), contains('needs at least one of gt, gte, lt, lte'));
      expect(problem((j) => ((j['anchors'] as List).first as Map)['where'] = {'left': {'lt': 1.5}}), contains('anchors[0].where.left.lt: should be a number from 0'));
      expect(problem((j) => ((j['anchors'] as List).first as Map)['pick'] = 'middle'), contains('anchors[0].pick'));
    });

    test('at least one label must be reported, or a bad photo could not be told from a good one', () {
      expect(problem((j) {
        for (final a in j['anchors'] as List) {
          (a as Map)['reported'] = false;
        }
      }), contains('at least one label should be reported'));
    });

    test('relations name labels that exist, and mean something', () {
      expect(problem((j) => ((j['relations'] as List).first as Map)['a'] = 'nothing'), contains('relations[0].a: "nothing" is not one of the labels'));
      expect(problem((j) => ((j['relations'] as List).first as Map)['rule'] = 'beside'), contains('relations[0].rule: should be one of'));
      expect(problem((j) => ((j['relations'] as List).first as Map)['b'] = 'question'), contains('compares "question" with itself'));
      expect(problem((j) => ((j['relations'] as List)[1] as Map)['tolerance'] = 0.1), contains('only applies to left_of_same_row'));
    });

    test('regions: known names, a marks table, labels the region needs', () {
      expect(problem((j) => (j['regions'] as Map)['footer'] = {}), contains('regions.footer: is not a region the app uses'));
      expect(problem((j) => (j['regions'] as Map).remove('marks')), contains('regions.marks: is required'));
      expect(problem((j) => ((j['regions'] as Map)['marks'] as Map)['variants'] = []), contains('regions.marks.variants: should have at least 1 item'));
      expect(problem((j) => (((j['regions'] as Map)['marks'] as Map)['variants'] as List).first['needs'] = ['nothing']), contains('"nothing" is not one of the labels'));
      expect(problem((j) => (((j['regions'] as Map)['marks'] as Map)['variants'] as List).first['needs'] = ['marks']),
          contains('uses "total", which is not in this variant\'s "needs"'));
      expect(problem((j) => (((j['regions'] as Map)['marks'] as Map)['variants'] as List).first['left'] = {'ref': 'marks'}), contains('should be a label and a position'));
      expect(problem((j) => (((j['regions'] as Map)['marks'] as Map)['variants'] as List).first['left'] = {'ref': 'marks.middle'}), contains('should be a label and a position'));
      expect(problem((j) => (((j['regions'] as Map)['marks'] as Map)['variants'] as List).first['left'] = {'ref': 'marks.left', 'offset': 5}), contains('offset: should be a number from -0.5 to 0.5'));
      expect(problem((j) => (((j['regions'] as Map)['marks'] as Map)['variants'] as List).first['right'] = 'wide'), contains('should be a number, {"ref"'));
      expect(problem((j) => (((j['regions'] as Map)['marks'] as Map)['variants'] as List).first['right'] = 1.4), contains('should be a number from 0'));
      expect(problem((j) => (((j['regions'] as Map)['marks'] as Map)['variants'] as List).first['right'] = {'max': [0.5]}), contains('.max: should have at least 2 items'));
      expect(problem((j) => ((j['regions'] as Map)['total'] as Map)['readsAs'] = 'x'), contains('only applies to the "answered" region'));
    });

    test('patterns must compile and stay short; the serial and institution rules are checked', () {
      expect(problem((j) => ((j['regions'] as Map)['answered'] as Map)['readsAs'] = '(['), contains('regions.answered.readsAs: is not a valid pattern'));
      expect(problem((j) => (j['serial'] as Map)['pattern'] = 'x' * 81), contains('serial.pattern: should be 1 to 80 characters'));
      expect(problem((j) => (j['serial'] as Map)['pattern'] = '('), contains('serial.pattern: is not a valid pattern'));
      expect(problem((j) => (j['institution'] as Map)['word'] = 'Uni versity'), contains('institution.word'));
    });

    test('patterns that could run for a very long time on a short line are not allowed', () {
      for (final bad in [r'^(a+)+$', r'^(\d|\d\d)*$', r'(\d+){2,}', r'^(.)\1$', r'^(?=\d)\d+$', r'(?<=a)b']) {
        expect(problem((j) => (j['serial'] as Map)['pattern'] = bad), contains('serial.pattern: uses a repeated group'), reason: bad);
      }
      // Ordinary patterns, including a group that is not repeated, are fine.
      for (final fine in [r'^\d{5,8}$', r'^[A-Z]{2,3}\/\d{2}U\/\d{4}$', r'^(?:FWM|FST)\d{4}$', r'^\d+(?:\.\d)?$']) {
        final j = good();
        (j['serial'] as Map)['pattern'] = fine;
        expect(LayoutProfile.fromJson(j).serial!.pattern, fine);
      }
    });

    test('expressions cannot be nested without end', () {
      Object deep(int n) => n == 0 ? 0.5 : {'max': [deep(n - 1), 0.4]};
      expect(problem((j) => (((j['regions'] as Map)['marks'] as Map)['variants'] as List).first['left'] = deep(6)), contains('is nested too deeply'));
    });

    test('a file that passes can be used on any reading without failing', () {
      // Whatever the text reader returns, a file that passed checking produces a reading.
      final profile = LayoutProfile.parse(File('docs/recognition/layouts/example_left_table.json').readAsStringSync());
      final analyzer = ProfileLayoutAnalyzer(profile);
      final r = analyzer.extract(fixture('sample_booklet_ocr.json'), classList: const ['FWM/24U/0538']);
      expect(r.foundAnchors.length, lessThan(profile.anchors.length), reason: 'a different cover is not recognised in this one');
      expect(r.layoutRecognised, isFalse);
      expect(r.marksRegion, isNull);
      expect(r.warnings.join(' '), contains('Some printed labels were not found'));
    });
  });

  group('another cover, described by another file', () {
    final profile = LayoutProfile.parse(File('docs/recognition/layouts/example_left_table.json').readAsStringSync());
    final analyzer = ProfileLayoutAnalyzer(profile);

    // The invented cover, upright: matric number top right, Item / Score down the left.
    const cover = OcrDocument(engine: 'test', lines: [
      OcrLine('Matric No.:', Region(0.55, 0.08, 0.72, 0.11), confidence: 0.9),
      OcrLine('482913', Region(0.80, 0.02, 0.95, 0.05), confidence: 0.9),
      OcrLine('Item', Region(0.05, 0.18, 0.15, 0.21), confidence: 0.9),
      OcrLine('Score', Region(0.25, 0.18, 0.40, 0.21), confidence: 0.9),
      OcrLine('Grand Total', Region(0.05, 0.84, 0.30, 0.88), confidence: 0.9),
    ]);

    test('finds its labels and places every region from them', () {
      final r = analyzer.extract(cover);
      expect(r.foundAnchors, ['Matric No.', 'Item', 'Score', 'Grand Total']);
      expect(r.layoutRecognised, isTrue);
      expect(r.serialNo, '482913');

      void near(Region? got, Region want, String what) {
        expect(got, isNotNull, reason: what);
        expect(got!.left, closeTo(want.left, 1e-9), reason: '$what left');
        expect(got.top, closeTo(want.top, 1e-9), reason: '$what top');
        expect(got.right, closeTo(want.right, 1e-9), reason: '$what right');
        expect(got.bottom, closeTo(want.bottom, 1e-9), reason: '$what bottom');
      }

      near(r.marksRegion, const Region(0.23, 0.21, 0.48, 0.836), 'marks');
      near(r.questionColumnRegion, const Region(0.03, 0.21, 0.226, 0.836), 'question column');
      near(r.examNumberRegion, const Region(0.72, 0.06, 0.97, 0.115), 'exam number');
      near(r.totalRegion, const Region(0.30, 0.82, 0.48, 0.91), 'total');
      expect(r.answeredRegion, isNull, reason: 'this cover has no "questions answered" line');
    });

    test('its relations tell upright from turned, as the built-in cover\'s do', () {
      final upright = analyzer.extract(cover);
      expect(upright.layoutContradictions, 0);
      expect(upright.layoutSupport, 4, reason: 'the serial number and three relations');
      for (var q = 1; q < 4; q++) {
        final turned = OcrDocument(engine: 't', lines: [for (final l in cover.lines) OcrLine(l.text, PageOrientation.turn(l.box, q))]);
        final r = analyzer.extract(turned);
        expect(PageOrientation.suspect(r, turned, 600, 800), isTrue, reason: 'turned $q');
        expect(PageOrientation.better(upright, r), isTrue, reason: 'turned $q');
        expect(PageOrientation.better(r, upright), isFalse, reason: 'turned $q');
      }
    });

    test('the built-in cover is not mistaken for it, and it is not mistaken for the built-in cover', () {
      expect(const BookletExtractor().extract(cover).foundAnchors.length, lessThan(3));
      expect(analyzer.extract(fixture('sample2_booklet_ocr.json')).foundAnchors.length, lessThan(3));
    });

    test('a label missing falls back to the next way of placing a region, when the file gives one', () {
      // Built-in: no "Marks" heading, but "For Examiner's Use Only" and "Total".
      final doc = OcrDocument(engine: 't', lines: [
        for (final l in fixture('sample2_booklet_ocr.json').lines)
          if (!l.text.toLowerCase().contains('marks')) l,
      ]);
      final r = const BookletExtractor().extract(doc);
      expect(r.missingAnchors, contains('Marks'));
      expect(r.marksRegion, isNotNull, reason: 'placed from "For Examiner\'s Use Only" instead');
      expect(r.questionColumnRegion, isNull, reason: 'the question column needs the Marks heading');
    });
  });

  group('reading a whole page with another cover\'s file (real digit network, drawn page)', () {
    late Directory work;
    setUpAll(() => work = Directory.systemTemp.createTempSync('unimarkly_layout_'));
    tearDownAll(() => work.deleteSync(recursive: true));

    final profile = LayoutProfile.parse(File('docs/recognition/layouts/example_left_table.json').readAsStringSync());

    // The marks table on the left of a 400 x 800 page, three rows written in red; the
    // question label (a ring, a dash, a one) to the left of each mark.
    SyntheticTable page() {
      final t = SyntheticTable();
      for (var i = 0; i < 3; i++) {
        final top = 190 + i * 70;
        t.one(110, top, 30, SyntheticTable.red);
        t.point(136, top + 30, SyntheticTable.red);
        t.ring(146, top, 30, SyntheticTable.red);
        t.ring(20, top, 30, SyntheticTable.red);
        t.line(48, top + 18, 72, top + 18, SyntheticTable.red);
        t.one(76, top, 30, SyntheticTable.red);
      }
      return t;
    }

    const labels = OcrDocument(engine: 'test', lines: [
      OcrLine('Matric No.:', Region(0.55, 0.08, 0.72, 0.11), confidence: 0.9),
      OcrLine('Item', Region(0.05, 0.18, 0.15, 0.21), confidence: 0.9),
      OcrLine('Score', Region(0.25, 0.18, 0.40, 0.21), confidence: 0.9),
      OcrLine('Grand Total', Region(0.05, 0.84, 0.30, 0.88), confidence: 0.9),
    ]);

    test('the rows are found in the table the file points at, and the record names the file', () async {
      final file = File(p.join(work.path, 'cover.png'))..writeAsBytesSync(await encodeColorPng(page().image));
      final digits = await ModelRegistry.loadDigits();
      final result = await BookletPipeline(ocr: const _FixedOcr(labels), digits: digits, layout: ProfileLayoutAnalyzer(profile)).run(file);

      expect(result.layout.foundAnchors, hasLength(4));
      final rows = result.fields.where((f) => f.key.startsWith('mark_row_') && f.region != null).toList();
      expect(rows, hasLength(3));
      for (var i = 0; i < 3; i++) {
        final c = rows[i].region!;
        expect(c.centerX, inInclusiveRange(0.23, 0.48), reason: 'row ${i + 1} is in the marks column of this cover');
        expect(c.centerY, closeTo((190 + i * 70 + 15) / 800, 0.03), reason: 'row ${i + 1}');
      }
      final model = result.models.firstWhere((m) => m['id'] == 'layout:example-left-table');
      expect(model['name'], 'Example: marks table on the left');
      expect(model['version'], '1');
      expect(RecognitionResult.fromJson(jsonDecode(jsonEncode(result.toJson())) as Map<String, dynamic>).models.map((m) => m['id']), contains('layout:example-left-table'));
    });

    test('the same page photographed on its side is turned upright using this file\'s relations', () async {
      final sideways = page().image.turned(1);
      final file = File(p.join(work.path, 'cover_sideways.png'))..writeAsBytesSync(await encodeColorPng(sideways));
      final digits = await ModelRegistry.loadDigits();
      // A reader that finds the cover's labels only when the picture is upright (the page
      // was drawn with its labels; the picture's top left pixel is paper-coloured, so use
      // the page itself: the labels are reported when the red marks sit in the left half).
      final result = await BookletPipeline(ocr: const _UprightOnlyOcr(labels), digits: digits, layout: ProfileLayoutAnalyzer(profile)).run(file);
      expect(result.turnedQuarters, 3);
      final rows = result.fields.where((f) => f.key.startsWith('mark_row_') && f.region != null).toList();
      expect(rows, hasLength(3), reason: '${result.notes}');
      // On the sideways photo the rows are where the turn puts them.
      for (var i = 0; i < 3; i++) {
        final want = PageOrientation.turn(Region(0.25, (190 + i * 70) / 800, 0.48, (190 + i * 70 + 30) / 800), 1);
        expect(rows[i].region!.centerX, closeTo(want.centerX, 0.05), reason: 'row ${i + 1} x');
        expect(rows[i].region!.centerY, closeTo(want.centerY, 0.05), reason: 'row ${i + 1} y');
      }
    });
  });
}

/// Returns the same reading whatever picture it is given.
class _FixedOcr implements OcrEngine {
  const _FixedOcr(this.doc);
  final OcrDocument doc;
  @override
  String get name => 'fixed';
  @override
  Future<OcrDocument> recognize(File image, {required int width, required int height}) async => doc;
}

/// Finds the labels only when the picture it is given is upright: portrait, and (for
/// this drawn page) with its ink in the left half.
class _UprightOnlyOcr implements OcrEngine {
  const _UprightOnlyOcr(this.labels);
  final OcrDocument labels;
  @override
  String get name => 'upright-only';
  @override
  Future<OcrDocument> recognize(File image, {required int width, required int height}) async {
    final pic = (await decodePhoto(image, maxSide: 4000)).image;
    var left = 0, right = 0;
    for (var y = 0; y < pic.height; y++) {
      for (var x = 0; x < pic.width; x++) {
        final o = (y * pic.width + x) * 4;
        if (pic.rgba[o] > 150 && pic.rgba[o + 1] < 110) {
          x < pic.width / 2 ? left++ : right++;
        }
      }
    }
    final upright = pic.height > pic.width && left > right * 3;
    return upright ? labels : const OcrDocument(engine: 'upright-only', lines: [OcrLine('Faculty of Science', Region(0.1, 0.05, 0.9, 0.09), confidence: 0.9)]);
  }
}
