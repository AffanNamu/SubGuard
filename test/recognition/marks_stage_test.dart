import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/domain/ocr.dart';
import 'package:unimarkly/services/recognition/marks_stage.dart';
import 'package:unimarkly/services/vision/digit_model.dart';
import 'package:unimarkly/services/vision/mark_reader.dart';

import '../support/synthetic_table.dart';

/// Finding the rows of a marks table and the question label beside each, on
/// pictures drawn so the right answer is known. The network is a stand-in that
/// says "7" for every character, because these tests are about structure: which
/// rows exist, where, and what was left out. How well the real network reads
/// digits is measured in digit_model_test.dart and the benchmark.
void main() {
  DigitPrediction sevens(Float32List _) => DigitPrediction([for (var i = 0; i < 11; i++) i == 7 ? 0.9 : 0.01]);
  final reader = MarkReader(sevens);

  // The marks column is the right-hand 35% of the picture, the label column the
  // 25% beside it.
  const marks = Region(0.62, 0.20, 0.97, 0.80);
  const questions = Region(0.36, 0.20, 0.62, 0.80);
  const total = Region(0.62, 0.84, 0.97, 0.94);

  /// A table with printed rules and [rows] written rows at 56 px spacing.
  SyntheticTable table({int rows = 3, List<int> pen = SyntheticTable.red}) {
    final t = SyntheticTable();
    t.rule(248, 140, 780);
    t.rule(150, 140, 780);
    for (var i = 0; i < rows; i++) {
      final top = 190 + i * 70;
      // a mark: digit, point, digit
      t.one(270, top, 30, pen);
      t.point(296, top + 30, pen);
      t.ring(306, top, 30, pen);
      // a label: a circled "Q", a dash, a digit
      t.ring(160, top, 30, pen);
      t.line(185, top + 18, 215, top + 18, pen);
      t.one(224, top, 30, pen);
    }
    return t;
  }

  MarksStageResult read(SyntheticTable t, {Region? totalRegion = total}) =>
      readMarksTable(t.image, marks: marks, questions: questions, total: totalRegion, reader: reader);

  test('each written row is a row, in order from the top, inside the marks column', () {
    final r = read(table(rows: 3));
    expect(r.inkVariant, 'red_ink');
    expect(r.rows, hasLength(3));
    for (var i = 0; i < 3; i++) {
      expect(r.rows[i].index, i + 1);
      expect(r.rows[i].markCell.left, closeTo(0.62, 0.01));
      expect(r.rows[i].markCell.centerY, closeTo((190 + i * 70 + 15) / 800, 0.02));
    }
    expect(r.rows[1].markCell.top, greaterThan(r.rows[0].markCell.bottom - 0.01));
  });

  test('a mark is read as characters in order: digit, point, digit', () {
    final row = read(table(rows: 1)).rows.single;
    expect(row.mark.chars.map((c) => c.text), ['7', '.', '7']);
    expect(row.mark.displayText, '7.7');
  });

  test('the question number is the digit at the right of the label, not the circled Q or the dash', () {
    final row = read(table(rows: 1)).rows.single;
    expect(row.questionText, '7');
    expect(row.questionCandidates.first.text, '7');
    expect(row.questionCell, isNotNull);
  });

  test('printed rules and form lines are not read as rows or marks', () {
    final withRules = read(table(rows: 2));
    expect(withRules.rows, hasLength(2));
  });

  test('a line struck through the unused rows is ignored, not read as marks', () {
    final t = table(rows: 2);
    // Dashed diagonal across the empty lower part of the table, as examiners draw it.
    t.line(255, 520, 380, 760, SyntheticTable.red, dash: 16, gap: 7);
    final r = read(t);
    expect(r.rows, hasLength(2), reason: 'the strike-through must not become a third row');
    expect(r.strokesCrossingRows, isNotEmpty);
    expect(r.notes.join(' '), contains('long line'));
  });

  test('an underline below the last row is ignored', () {
    final t = table(rows: 2);
    t.line(256, 480, 380, 484, SyntheticTable.red, thick: 3);
    final r = read(t);
    expect(r.rows, hasLength(2));
    expect(r.strokesCrossingRows, isNotEmpty);
  });

  test('blue pen: the red picture finds nothing, so the dark ink is read, and it says so', () {
    final r = read(table(rows: 2, pen: SyntheticTable.blue));
    expect(r.inkVariant, 'dark_ink');
    expect(r.rows, hasLength(2));
    expect(r.notes.join(' '), contains('No red pen was found'));
  });

  test('an empty marks table has no rows and says no ink was found', () {
    final t = SyntheticTable();
    t.rule(248, 140, 780);
    final r = read(t);
    expect(r.rows, isEmpty);
    expect(r.inkVariant, isNull);
    expect(r.notes.join(' '), contains('No pen ink'));
  });

  test('a blank Total box is reported as blank, not as a zero', () {
    final r = read(table(rows: 1));
    expect(r.totalStrokes, 0);
    expect(r.total, isNull);
    expect(r.totalCell, isNotNull);
  });

  test('a written Total is read, with its own box', () {
    final t = table(rows: 1);
    t.one(300, 650, 30, SyntheticTable.red);
    t.ring(320, 650, 30, SyntheticTable.red);
    final r = read(t);
    expect(r.totalStrokes, greaterThan(0));
    expect(r.total?.displayText, '77');
  });

  test('ink in a probed region is counted, so "nothing written" differs from "written but unread"', () {
    final t = table(rows: 1);
    t.ring(40, 100, 30, SyntheticTable.red);
    final r = readMarksTable(
      t.image,
      marks: marks,
      questions: questions,
      reader: reader,
      probes: const {'there': Region(0.05, 0.10, 0.25, 0.20), 'empty': Region(0.05, 0.50, 0.25, 0.60)},
    );
    expect(r.strokes['there'], greaterThanOrEqualTo(1));
    expect(r.strokes['empty'], 0);
  });

  test('a marks area too small to hold writing is reported, not read', () {
    final r = readMarksTable(table(rows: 1).image, marks: const Region(0.5, 0.5, 0.51, 0.51), reader: reader);
    expect(r.rows, isEmpty);
    expect(r.notes.join(' '), contains('too small'));
  });
  group('a decimal point, and what is not one', () {
    test('a dot written raised, at about half the height of the digits, between two digits is the decimal point', () {
      final t = SyntheticTable();
      t.rule(248, 140, 780);
      t.one(270, 200, 30, SyntheticTable.red);
      // 8 wide, 14 tall, mid-height: a raised dot. Before this was understood it was read as a digit.
      t.rect(299, 208, 307, 222, SyntheticTable.red);
      t.ring(318, 200, 30, SyntheticTable.red);
      final row = read(t).rows.single;
      expect(row.mark.chars.map((c) => c.text), ['7', '.', '7']);
      expect(row.mark.displayText, '7.7');
    });

    test('the same small blob at the end of a mark is not a decimal point', () {
      final t = SyntheticTable();
      t.rule(248, 140, 780);
      t.one(270, 200, 30, SyntheticTable.red);
      t.ring(290, 200, 30, SyntheticTable.red);
      t.rect(330, 208, 338, 222, SyntheticTable.red);
      final chars = read(t).rows.single.mark.chars.map((c) => c.text).toList();
      expect(chars.where((c) => c == '.'), isEmpty, reason: 'a point has to stand between two digits');
    });

    test('two digits with no dot between them get no point added: the reading says so', () {
      final t = SyntheticTable();
      t.rule(248, 140, 780);
      t.one(270, 200, 30, SyntheticTable.red);
      t.ring(296, 200, 30, SyntheticTable.red);
      final row = read(t).rows.single;
      expect(row.mark.displayText, '77');
      expect(row.mark.warnings.join(' '), contains('No decimal point was seen'));
    });

    test('a flat stroke is not a digit, whatever the network says about it', () {
      final t = SyntheticTable();
      t.rule(248, 140, 780);
      t.ring(270, 200, 30, SyntheticTable.red);
      t.rect(300, 214, 372, 220, SyntheticTable.red); // 72 wide, 6 tall
      final row = read(t).rows.single;
      expect(row.mark.chars.map((c) => c.text), contains('?'), reason: 'the stroke is not read as a digit');
      expect(row.mark.chars.where((c) => c.text != '?' && c.box.right - c.box.left > 40), isEmpty);
      expect(row.mark.candidates, isEmpty, reason: 'an unreadable character leaves no candidates');
    });
  });

  test('a pen stroke left below the last row is a fraction of the size of the writing, and is not a row', () {
    final t = table(rows: 3);
    t.rect(262, 470, 336, 476, SyntheticTable.red); // 74 wide, 6 tall: the end of a strike-through
    final r = read(t);
    expect(r.rows, hasLength(3));
    expect(r.rows.map((row) => row.index), [1, 2, 3]);
    expect(r.notes.join(' '), contains('pen stroke below row'));
    expect(r.strokesCrossingRows, isNotEmpty);
  });

  test('rows of ordinary size are all kept, however many there are', () {
    final r = read(table(rows: 6));
    expect(r.rows, hasLength(6));
  });
}
