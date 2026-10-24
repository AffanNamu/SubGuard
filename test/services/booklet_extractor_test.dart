import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/domain/ocr.dart';
import 'package:unimarkly/services/reader/booklet_extractor.dart';

/// The real photo supplied by the product owner, read by an OCR engine; see the
/// note inside the fixture. It is a Modibbo Adama University booklet cover with
/// a handwritten exam number and red marks, which no printed-text engine reads.
OcrDocument loadSample() {
  final j = jsonDecode(File('test/fixtures/sample_booklet_ocr.json').readAsStringSync()) as Map<String, dynamic>;
  return OcrDocument(
    engine: j['engine'] as String,
    lines: [
      for (final l in (j['lines'] as List).cast<Map<String, dynamic>>())
        OcrLine(
          l['text'] as String,
          Region((l['left'] as num).toDouble(), (l['top'] as num).toDouble(), (l['right'] as num).toDouble(),
              (l['bottom'] as num).toDouble()),
          confidence: (l['confidence'] as num).toDouble(),
        ),
    ],
  );
}

OcrLine line(String text, double l, double t, double r, double b, [double conf = 0.9]) =>
    OcrLine(text, Region(l, t, r, b), confidence: conf);

void main() {
  const extractor = BookletExtractor();

  group('the real sample booklet', () {
    final reading = extractor.extract(loadSample());

    test('finds the printed booklet number', () {
      expect(reading.serialNo, '292011');
    });

    test('finds the institution', () {
      expect(reading.institution, contains('UNIVERSITY'));
    });

    test('finds the printed labels that anchor the layout', () {
      expect(reading.foundAnchors, containsAll(["Candidate's Examination Number", 'Total']));
    });

    test('places the exam-number region on the line beside the label', () {
      final r = reading.examNumberRegion!;
      expect(r.top, inInclusiveRange(0.12, 0.17));
      expect(r.bottom, inInclusiveRange(0.19, 0.24));
      expect(r.left, inInclusiveRange(0.28, 0.36));
      expect(r.right, greaterThan(0.85));
    });

    test('places the marks region under the header and above Total', () {
      final r = reading.marksRegion!;
      expect(r.left, inInclusiveRange(0.7, 0.85));
      expect(r.top, inInclusiveRange(0.3, 0.4));
      expect(r.bottom, inInclusiveRange(0.78, 0.84));
    });

    test('does not invent the handwriting it cannot read', () {
      // The engine read none of the handwritten exam number or marks, so none
      // are offered. This is the honest result for printed-text OCR.
      expect(reading.examNumberSuggestion, isNull);
    });

    test('the whole reading can be stored as JSON', () {
      final text = jsonEncode(reading.toJson());
      expect(text, contains('292011'));
    });

    test('writes the regions out for checking against the photo', () {
      final out = Platform.environment['REGIONS_OUT'];
      if (out == null) return;
      File(out).writeAsStringSync(jsonEncode(reading.toJson()['regions']));
    });
  });

  group('synthetic layouts', () {
    OcrDocument doc(List<OcrLine> lines) => OcrDocument(engine: 'test', lines: lines);

    List<OcrLine> cover() => [
          line('MODIBBO ADAMA UNIVERSITY, YOLA', 0.17, 0.0, 0.83, 0.05),
          line('292011', 0.64, 0.06, 0.74, 0.09),
          line("Candidate's Examination Number:", 0.1, 0.15, 0.35, 0.18),
          line('For Examiner\'s', 0.67, 0.27, 0.84, 0.29),
          line('Use Only', 0.7, 0.29, 0.81, 0.31),
          line('Question', 0.69, 0.33, 0.77, 0.35),
          line('Marks', 0.82, 0.33, 0.88, 0.35),
          line('Total', 0.7, 0.83, 0.78, 0.86),
          line('NUMBER YOUR ANSWERS in the order in which they', 0.08, 0.83, 0.5, 0.85),
          line('Have been written', 0.1, 0.86, 0.28, 0.88),
          line('4, 5, 1, 2', 0.08, 0.9, 0.25, 0.93),
        ];

    test('a clean cover is fully recognised', () {
      final r = extractor.extract(doc(cover()));
      expect(r.layoutRecognised, isTrue);
      expect(r.missingAnchors, isEmpty);
      expect(r.serialNo, '292011');
      expect(r.questionsAnsweredText, '4, 5, 1, 2');
      expect(r.questionColumnRegion, isNotNull);
      expect(r.marksRegion!.left, greaterThan(r.questionColumnRegion!.left));
      expect(r.totalRegion, isNotNull);
      expect(r.answeredRegion, isNotNull);
    });

    test('tolerates the odd wrong letter in a label', () {
      final lines = cover()
        ..removeWhere((l) => l.text.startsWith('Question'))
        ..add(line('Quest1on', 0.69, 0.33, 0.77, 0.35));
      final r = extractor.extract(doc(lines));
      expect(r.foundAnchors, contains('Question'));
    });

    test('a missing label is reported, with a warning in plain words', () {
      final lines = cover()..removeWhere((l) => l.text == 'Total');
      final r = extractor.extract(doc(lines));
      expect(r.layoutRecognised, isFalse);
      expect(r.missingAnchors, contains('Total'));
      expect(r.marksRegion, isNull, reason: 'no guess when the layout is not found');
      expect(r.warnings.first, contains('Total'));
    });

    test('a photo with no text reads nothing and says so', () {
      final r = extractor.extract(const OcrDocument(engine: 'none', lines: [], note: 'Reading is not available on this device.'));
      expect(r.serialNo, isNull);
      expect(r.examNumberRegion, isNull);
      expect(r.warnings.single, 'Reading is not available on this device.');
    });

    test('a handwriting suggestion is offered only when confident and a valid number', () {
      final confident = cover()..add(line('FWM/24U/0538', 0.45, 0.15, 0.85, 0.18, 0.93));
      expect(extractor.extract(doc(confident)).examNumberSuggestion, 'FWM/24U/0538');

      final unsure = cover()..add(line('FWM/24U/0538', 0.45, 0.15, 0.85, 0.18, 0.55));
      expect(extractor.extract(doc(unsure)).examNumberSuggestion, isNull);

      final nonsense = cover()..add(line('hello there', 0.45, 0.15, 0.85, 0.18, 0.99));
      expect(extractor.extract(doc(nonsense)).examNumberSuggestion, isNull);
    });

    test('repairs a suggestion where the U was read as a 4', () {
      final lines = cover()..add(line('FWM/244/0538', 0.45, 0.15, 0.85, 0.18, 0.9));
      expect(extractor.extract(doc(lines)).examNumberSuggestion, 'FWM/24U/0538');
    });

    group('the exam number read close up and matched to the class list', () {
      const classList = ['FWM/24U/0538', 'FWM/24U/0539', 'FST/25U/0101'];

      OcrDocument crop(String text, [double conf = 0.6]) =>
          OcrDocument(engine: 'crop', lines: [line(text, 0.0, 0.1, 1.0, 0.9, conf)]);

      test('a shaky reading that is one slip from exactly one student is that student', () {
        final r = extractor.extract(doc(cover()), examNumberCrop: crop('FWM/24U/O538', 0.55), classList: classList);
        expect(r.examNumberSuggestion, 'FWM/24U/0538');
        expect(r.examNumberOnClassList, isTrue);
      });

      test('an exact class-list match is accepted even when the engine is unsure', () {
        final r = extractor.extract(doc(cover()), examNumberCrop: crop('FWM/24U/0539', 0.3), classList: classList);
        expect(r.examNumberSuggestion, 'FWM/24U/0539');
      });

      test('a reading equally close to two students is not guessed', () {
        // 0530 is one digit from both 0538 and 0539.
        final r = extractor.extract(doc(cover()), examNumberCrop: crop('FWM/24U/0530', 0.8), classList: classList);
        expect(r.examNumberSuggestion, isNull);
        expect(r.warnings.join(' '), contains('could not be read clearly'));
      });

      test('a scribble leaves the field for the examiner, with a plain-words warning', () {
        final r = extractor.extract(doc(cover()), examNumberCrop: crop('~~ // ~', 0.9), classList: classList);
        expect(r.examNumberSuggestion, isNull);
        expect(r.warnings.join(' '), contains('Type it from the photo'));
      });

      test('a number that is not on the class list is offered only when clearly read', () {
        final clear = extractor.extract(doc(cover()), examNumberCrop: crop('ABC/24U/0777', 0.92), classList: classList);
        expect(clear.examNumberSuggestion, 'ABC/24U/0777');
        expect(clear.examNumberOnClassList, isFalse);
        final unsure = extractor.extract(doc(cover()), examNumberCrop: crop('ABC/24U/0777', 0.5), classList: classList);
        expect(unsure.examNumberSuggestion, isNull);
      });

      test('the choice is stored with the reading', () {
        final r = extractor.extract(doc(cover()), examNumberCrop: crop('FWM/24U/O538', 0.55), classList: classList);
        final back = BookletReading.fromJson(jsonDecode(jsonEncode(r.toJson())) as Map<String, dynamic>);
        expect(back.examNumberSuggestion, 'FWM/24U/0538');
        expect(back.examNumberOnClassList, isTrue);
      });
    });

    test('a number outside the exam-number line is ignored', () {
      final lines = cover()..add(line('FWM/24U/0538', 0.1, 0.5, 0.4, 0.53, 0.95));
      expect(extractor.extract(doc(lines)).examNumberSuggestion, isNull);
    });

    test('the booklet number must be digits in the top right', () {
      final lines = cover()
        ..removeWhere((l) => l.text == '292011')
        ..add(line('292011', 0.1, 0.5, 0.2, 0.52))
        ..add(line('12', 0.7, 0.06, 0.74, 0.09));
      expect(extractor.extract(doc(lines)).serialNo, isNull);
    });
  });

  group('Region', () {
    test('round-trips through its stored form', () {
      const r = Region(0.1, 0.2, 0.9, 0.3);
      final back = Region.decode(r.encode())!;
      expect(back.left, closeTo(0.1, 1e-4));
      expect(back.bottom, closeTo(0.3, 1e-4));
      expect(Region.decode('nonsense'), isNull);
      expect(Region.decode(null), isNull);
    });
  });
}
