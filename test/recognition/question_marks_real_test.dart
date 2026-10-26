import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/domain/defaults.dart';
import 'package:unimarkly/domain/exam_tally.dart';
import 'package:unimarkly/domain/mark_rules.dart';
import 'package:unimarkly/domain/mark_sheet.dart';
import 'package:unimarkly/domain/row_suggestions.dart';
import 'package:unimarkly/domain/scheme.dart';
import 'package:unimarkly/services/recognition/booklet_pipeline.dart';
import 'package:unimarkly/services/recognition/interfaces.dart';
import 'package:unimarkly/services/recognition/model_registry.dart';

import '../support/process_ocr_engine.dart';

/// Question numbers, marks and the total, taken from a real photograph of a real booklet
/// (eval/dataset/booklet-001, its ground truth annotated from the photo) through the real
/// pipeline: the PP-OCR stand-in for the printed text and the real digit network for the
/// handwriting. Nothing here is a canned recogniser output.
///
/// What the photograph says (truth.json): Q1 = 1.0, Q2 = 1.0, Q4 = 2.0, Q5 = 5.5, and a
/// blank Total box. Question numbers 1, 2, 4 and 5: there is no Q3.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const photo = 'eval/dataset/booklet-001/image.jpg';
  final truth = jsonDecode(File('eval/dataset/booklet-001/truth.json').readAsStringSync()) as Map<String, dynamic>;
  final truthMarks = {
    for (final f in (truth['fields'] as List).cast<Map<String, dynamic>>())
      if ((f['key'] as String).startsWith('mark_q')) f['question'] as int: double.parse(f['text'] as String),
  };

  late ProcessOcrEngine? ocr;
  late RecognitionResult result;
  late GradingScheme scheme;

  /// Everything the pipeline offered as a row, and the rows that have a question number: the
  /// four that are written. Where the table's crop falls on the photograph varies by a few
  /// pixels with the text reader's version, and a scrap of the long pen line below the
  /// writing can then come back as a further row with no question number. What must not
  /// vary is that the four written rows are found, in order, and that nothing else counts.
  late List<RowSuggestions> allRows;
  late List<RowSuggestions> rows;

  setUpAll(() async {
    ocr = await ProcessOcrEngine.tryStart();
    if (ocr == null) return;
    final digits = await ModelRegistry.loadDigits();
    result = await BookletPipeline(ocr: ocr!, digits: digits).run(File(photo));
    scheme = Defaults.nigerianScheme(); // exam part: 70, marks go up in 0.5
    allRows = RowSuggestions.allOf(
      result.fields,
      marksFor: (q) => MarkRules.forScheme(scheme, qNo: q),
      questionRules: const QuestionRules(highest: 60),
    );
    rows = [for (final r in allRows) if (r.questionAlternatives.isNotEmpty) r];
  });
  tearDownAll(() async => ocr?.stop());

  bool skip() {
    if (ocr == null) {
      markTestSkipped('OCR stand-in unavailable (pip install rapidocr-onnxruntime opencv-python-headless)');
      return true;
    }
    return false;
  }

  test('the photograph has four written rows; the pen line below them is not read as marks', () {
    if (skip()) return;
    expect(truthMarks.keys.toList()..sort(), [1, 2, 4, 5]);
    expect(rows, hasLength(4), reason: 'notes: ${result.notes}');
    // The four written rows come first, in order.
    expect(allRows.take(4).map((r) => r.index), [1, 2, 3, 4]);
    expect(allRows.take(4).every((r) => r.questionAlternatives.isNotEmpty), isTrue);
    // Whatever else came back has no question number, so it is not a question: at most a scrap
    // of the pen line, which the examiner dismisses, and which counts for nothing until then.
    expect(allRows.length - rows.length, lessThanOrEqualTo(2), reason: 'notes: ${result.notes}');
    expect(allRows.skip(4).every((r) => r.questionAlternatives.isEmpty), isTrue);
    expect(result.notes.join(' '), contains('were ignored, not read as marks'), reason: 'the long strokes are reported, not read');
  });

  test('the question numbers are read apart from the marks: 1, 2, 4, 5, with no Q3 and no list of questions made up', () {
    if (skip()) return;
    final questions = [for (final r in rows) r.questionAlternatives.map((c) => c.text).toList()];
    expect(questions.map((q) => q.isEmpty ? null : q.first).toList(), ['1', '2', '4', '5']);
    for (final r in rows) {
      expect(r.questionReadable, isTrue);
      expect(r.questionAlternatives.every((c) => RegExp(r'^\d{1,2}$').hasMatch(c.text)), isTrue, reason: 'a question alternative is a whole question number');
    }
    final sheet = MarkSheet.fromRows(allRows);
    expect(sheet.records.length, allRows.length);
    expect(sheet.records.any((r) => r.key.contains('manual')), isFalse);
    expect(sheet.records.where((r) => r.suggestions!.questionAlternatives.isNotEmpty).length, 4);
  });

  test('no mark is suggested that a mark cannot be: the digit strings made of "1.0" stay evidence, with the reason', () {
    if (skip()) return;
    for (final r in rows) {
      for (final c in r.markAlternatives) {
        final v = double.parse(c.text);
        expect(v <= 70, isTrue, reason: 'row ${r.index} offered ${c.text}');
        expect((v / 0.5 - (v / 0.5).round()).abs() < 1e-6, isTrue, reason: 'row ${r.index} offered ${c.text}, off the 0.5 step');
        expect(RegExp(r'^\d{1,2}(\.\d)?$').hasMatch(c.text), isTrue, reason: c.text);
      }
    }
    // Row 2 reads as three digits ("141"): not a mark, so nothing is offered and the examiner is told.
    final row2 = rows[1];
    expect(row2.markAlternatives, isEmpty);
    expect(row2.rawMark, isNotNull, reason: 'what the reader returned is kept');
    expect(row2.markLeftOut, isNotEmpty);
    expect(row2.markLeftOut.first.reason, anyOf(contains('above the most'), contains('not a multiple'), contains('could not be read')));
    // Row 3 ("2.0") reads with decimals that are not on the step: not offered either.
    expect(rows[2].markAlternatives, isEmpty);
  });

  test('the suggestions that are offered are ones the photograph supports: 1.0 for Q1 and 5.5 for Q5', () {
    if (skip()) return;
    expect(rows[0].markAlternatives.map((c) => c.text), contains('1.0'));
    expect(rows[3].markAlternatives.map((c) => c.text), contains('5.5'));
    expect(rows[3].markAlternatives.first.text, '5.5');
  });

  test('a decimal point is found between the digits of "1.0" because there is a dot there, and none is invented elsewhere', () {
    if (skip()) return;
    // Row 1: a raised dot between the 1 and the 0 (the reader reads three characters, the middle one a point).
    final attempts = result.field('mark_row_1')!.attempts.first.text!;
    expect(attempts.contains('.'), isTrue, reason: 'raw reading "$attempts"');
    // No row's raw reading was given a decimal point it did not have a dot for: a reading with two or more digits and
    // no point warns that none was added.
    for (final f in result.fields.where((f) => f.key.startsWith('mark_row_'))) {
      final raw = f.attempts.first.text ?? '';
      if (raw.length >= 2 && !raw.contains('.') && !raw.contains('?')) {
        expect(f.warnings.join(' '), contains('No decimal point was seen'), reason: '${f.key} read "$raw"');
      }
    }
  });

  test('nothing is confirmed by recognition: with no confirmation there is no calculated total', () {
    if (skip()) return;
    final sheet = MarkSheet.fromRows(allRows);
    expect(sheet.confirmedMarks, isEmpty);
    expect(sheet.tally(scheme).calculated, isNull);
    expect(sheet.problems(scheme).where((p) => p.blocks), isNotEmpty);
  });

  test('an examiner who takes the suggestions that are right and types the rest gets 1.0 + 1.0 + 2.0 + 5.5 = 9.5, with the Total box blank', () {
    if (skip()) return;
    var sheet = MarkSheet.fromRows(allRows);
    // A scrap of the pen line that came back as a row is dismissed ("Not a mark"); it never counted.
    for (final r in allRows.where((r) => r.questionAlternatives.isEmpty)) {
      sheet = sheet.dismiss(r.markKey);
    }
    for (final r in rows) {
      final key = r.markKey;
      // Question number: the top suggestion (the examiner looked at the crop and agreed).
      sheet = sheet.setQuestion(key, int.parse(r.questionAlternatives.first.text));
      final q = sheet.byKey(key)!.qNo!;
      // Mark: a suggestion when there is one and it is the right one; otherwise typed from the photograph.
      final want = truthMarks[q]!;
      final offered = r.markAlternatives.where((c) => double.parse(c.text) == want);
      sheet = sheet.setMark(key, offered.isNotEmpty ? double.parse(offered.first.text) : want);
    }
    final t = sheet.tally(scheme);
    expect(t.calculated, 9.5);
    expect(t.calculated, (truth['totals'] as Map)['calculated_from_marks']);
    expect(sheet.problems(scheme).where((p) => p.blocks), isEmpty);

    // The written Total box is blank on this booklet: it does not stop the calculation.
    final written = result.field('total_written')!;
    expect(written.value, isNull);
    expect(written.warnings.join(' '), contains('blank'));
    expect(TotalComparison.of(calculated: t.calculated, written: null).agreement, TotalAgreement.notComparable);
  });

  test('a wrong suggestion taken in error is corrected by the examiner and the total follows at once', () {
    if (skip()) return;
    var sheet = MarkSheet.fromRows(rows);
    for (final r in rows) {
      sheet = sheet.setQuestion(r.markKey, int.parse(r.questionAlternatives.first.text));
    }
    // Q1: the examiner takes the alternative the model ranks second for the first digit: 9.0 (a wrong reading).
    final nine = rows[0].markAlternatives.where((c) => c.text == '9.0');
    expect(nine, isNotEmpty, reason: 'the model did offer it as an alternative for the same field');
    sheet = sheet.setMark(rows[0].markKey, 9.0);
    expect(sheet.tally(scheme).calculated, 9.0);
    sheet = sheet.setMark(rows[0].markKey, 1.0);
    expect(sheet.tally(scheme).calculated, 1.0, reason: 'replaced, not added to');
  });

  test('the recognition, review model and calculation need no network', () {
    if (skip()) return;
    // The pipeline above ran with the Python stand-in on this machine only. In the app the same stages run on the phone:
    // none of the code that reads, suggests or adds up imports a network client.
    final offenders = <String>[];
    for (final dir in ['lib/services/recognition', 'lib/services/vision', 'lib/services/reader', 'lib/domain', 'lib/features/scan']) {
      for (final f in Directory(dir).listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
        final text = f.readAsStringSync();
        if (RegExp(r"import 'package:(http|dio|web_socket_channel)[/']|HttpClient\(|Socket\.connect|WebSocket\.connect|Uri\.https?\(").hasMatch(text)) offenders.add(f.path);
      }
    }
    expect(offenders, isEmpty);
  });
}
