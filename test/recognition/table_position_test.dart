import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/domain/defaults.dart';
import 'package:unimarkly/domain/mark_rules.dart';
import 'package:unimarkly/domain/ocr.dart';
import 'package:unimarkly/domain/row_suggestions.dart';
import 'package:unimarkly/services/recognition/booklet_pipeline.dart';
import 'package:unimarkly/services/recognition/marks_stage.dart';
import 'package:unimarkly/services/recognition/model_registry.dart';
import 'package:unimarkly/services/vision/digit_model.dart';
import 'package:unimarkly/services/vision/mark_reader.dart';

import '../support/booklet_photo.dart';
import '../support/jittered_ocr.dart';
import '../support/process_ocr_engine.dart';

/// The table of marks is cut out of the photograph relative to the printed labels the text
/// reader finds, and another version of the reader (or another processor) finds them a few
/// pixels away. CI once installed a newer reader than the one the code was written against,
/// and a scrap of the long pen line struck through the unused rows came back as extra "rows"
/// that did not appear on the machine the code was written on.
///
/// These tests are the guard: the same real photograph, with the table cut out in many
/// slightly different places, must always give the four written rows in order.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the marks stage finds the four written rows wherever the table is cut out (27 positions)', () async {
    final photo = await loadBooklet();
    final model = await ModelRegistry.loadDigits();
    final net = DigitModel.fromBytes(model.weights);
    final reader = MarkReader((input) => net.predict(input));
    final wrong = <String>[];
    var tried = 0;
    for (final top in [0.30, 0.335, 0.345]) {
      for (final bottom in [0.74, 0.82, 0.90]) {
        for (final dx in [-0.004, 0.0, 0.004]) {
          tried++;
          final r = readMarksTable(
            photo,
            marks: Region(0.7654 + dx, top, 0.9802, bottom),
            questions: Region(0.6185 + dx, top, 0.7630 + dx, bottom),
            total: const Region(0.7654, 0.93, 0.9802, 0.98),
            reader: reader,
          );
          final questions = [for (final x in r.rows) x.questionText].join(',');
          if (questions != '1,2,4,5') wrong.add('top $top, bottom $bottom, dx $dx: ${r.rows.length} rows, questions [$questions]');
        }
      }
    }
    expect(tried, 27);
    expect(wrong, isEmpty, reason: 'a scrap of the pen line came back as a row, or a written row was lost');
  });

  group('the whole pipeline, with the text reader\'s boxes nudged', () {
    late ProcessOcrEngine? ocr;
    late LoadedDigitModel digits;
    setUpAll(() async {
      ocr = await ProcessOcrEngine.tryStart();
      digits = await ModelRegistry.loadDigits();
    });
    tearDownAll(() async => ocr?.stop());

    // Each is a plausible difference between two versions of the reader, a few pixels on an 810 x 1080 photograph.
    const nudges = <String, List<double>>{
      'none': [0, 0, 1, 1],
      'left 3 px': [-0.0037, 0, 1, 1],
      'right 3 px': [0.0037, 0, 1, 1],
      'up 6 px': [0, -0.0056, 1, 1],
      'down 6 px': [0, 0.0056, 1, 1],
      'taller 0.4%': [0, 0, 1, 1.004],
      'shorter 0.4%': [0, 0, 1, 0.996],
      'wider 0.4%': [0, 0, 1.004, 1],
    };

    for (final e in nudges.entries) {
      test('${e.key}: the four written rows are found, in order, and nothing else is a question', () async {
        final engine = ocr;
        if (engine == null) {
          markTestSkipped('OCR stand-in unavailable (pip install rapidocr-onnxruntime opencv-python-headless)');
          return;
        }
        final n = e.value;
        final result = await BookletPipeline(ocr: JitteredOcr(engine, dx: n[0], dy: n[1], sx: n[2], sy: n[3]), digits: digits).run(File(bookletPath));
        final scheme = Defaults.nigerianScheme();
        final all = RowSuggestions.allOf(
          result.fields,
          marksFor: (q) => MarkRules.forScheme(scheme, qNo: q),
          questionRules: const QuestionRules(highest: 60),
        );
        final labelled = [for (final r in all) if (r.questionAlternatives.isNotEmpty) r.questionAlternatives.first.text];
        expect(labelled, ['1', '2', '4', '5'], reason: 'notes: ${result.notes}');
        expect(all.take(4).every((r) => r.questionAlternatives.isNotEmpty), isTrue, reason: 'the written rows come first');
        expect(all.length - labelled.length, lessThanOrEqualTo(2), reason: 'at most a scrap or two of the pen line, with no question number');
        // Nothing offered as a mark is a number a mark cannot be.
        for (final r in all) {
          for (final c in r.markAlternatives) {
            final v = double.parse(c.text);
            expect(v <= 70 && (v / 0.5 - (v / 0.5).round()).abs() < 1e-6, isTrue, reason: 'row ${r.index} offered ${c.text}');
          }
        }
      });
    }
  });
}
