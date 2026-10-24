import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/domain/ocr.dart';
import 'package:unimarkly/services/reader/exam_number.dart';

/// The handwritten registration number: what was read stays visible beside
/// anything the class list contributes, and nothing is invented.
void main() {
  const box = Region(0.4, 0.1, 0.9, 0.15);
  ExamNumberReading r(String text, {double? conf, String variant = 'closeup', String reader = 'ocr'}) =>
      ExamNumberReading(reader: reader, readerVersion: '1', variant: variant, line: OcrLine(text, box, confidence: conf));

  const classList = ['FWM/24U/0538', 'FWM/24U/0539', 'FST/25U/244/5772'];

  test('an exact reading is a candidate and the suggestion, with the class list agreeing', () {
    final e = ExamNumberResolver.resolve([r('FWM/24U/0538', conf: 0.95)], classList);
    expect(e.raw, 'FWM/24U/0538');
    expect(e.suggestion?.regNo, 'FWM/24U/0538');
    expect(e.suggestion?.onClassList, isTrue);
    expect(e.candidates.first.text, 'FWM/24U/0538');
  });

  test('a letter O read for a zero is tidied, and the candidate says what was changed', () {
    final e = ExamNumberResolver.resolve([r('FWM/24U/O538', conf: 0.8)], classList);
    expect(e.raw, 'FWM/24U/0538');
    final c = e.candidates.firstWhere((c) => c.text == 'FWM/24U/0538');
    expect(c.note, contains('FWM/24U/O538'));
  });

  test('a reading one character from a single class-list number is offered as that number, with a note, beside the reading', () {
    final e = ExamNumberResolver.resolve([r('FWM/24U/0548', conf: 0.7)], classList);
    // The raw reading is still there, untouched by the class list.
    expect(e.raw, 'FWM/24U/0548');
    expect(e.candidates.map((c) => c.text), containsAll(['FWM/24U/0548', 'FWM/24U/0538']));
    final listed = e.candidates.firstWhere((c) => c.text == 'FWM/24U/0538');
    expect(listed.source, startsWith('class_list'));
    expect(listed.note, contains('only class-list number within 1 character'));
    // But 0548 is equally 1 away from 0538 only; 0539 is 2 away, so 0538 is unique.
    expect(e.suggestion?.regNo, 'FWM/24U/0538');
  });

  test('a reading equally close to two class-list numbers offers neither, and says so', () {
    // 0537 is one digit from both 0538 and ... make a real tie:
    final e = ExamNumberResolver.resolve([r('FWM/24U/0534', conf: 0.7)], ['FWM/24U/0532', 'FWM/24U/0536']);
    expect(e.candidates.where((c) => c.source.startsWith('class_list')), isEmpty);
    expect(e.suggestion, isNull);
    expect(e.warnings.join(' '), contains('equally close'));
    expect(e.raw, 'FWM/24U/0534');
  });

  test('when only the last digits are clear and match one class-list number, that is a candidate with an honest note', () {
    final e = ExamNumberResolver.resolve([r('F?M/2?U/0538', conf: 0.6)], classList);
    final listed = e.candidates.where((c) => c.source.startsWith('class_list')).toList();
    expect(listed, isNotEmpty);
    expect(listed.first.text, 'FWM/24U/0538');
    expect(listed.first.note, contains('prefix was not read clearly'));
    expect(e.raw, isNull, reason: 'nothing resembling a registration number was actually read');
  });

  test('a reading that matches no class-list number is the suggestion only when confident and well formed', () {
    final confident = ExamNumberResolver.resolve([r('ABC/24U/0777', conf: 0.9)], classList);
    expect(confident.suggestion?.regNo, 'ABC/24U/0777');
    expect(confident.suggestion?.onClassList, isFalse);
    final unsure = ExamNumberResolver.resolve([r('ABC/24U/0777', conf: 0.5)], classList);
    expect(unsure.suggestion, isNull);
    expect(unsure.raw, 'ABC/24U/0777', reason: 'still reported as read, just not suggested');
  });

  test('printed label text and other non-numbers are evidence, not candidates', () {
    final e = ExamNumberResolver.resolve([r('Number:', conf: 0.9), r('Hon', conf: 0.7), r('L0/0538', conf: 0.5)], classList);
    expect(e.candidates.map((c) => c.text), isNot(contains('Number:')));
    expect(e.candidates.map((c) => c.text), isNot(contains('Hon')));
    expect(e.attempts.map((a) => a.text), containsAll(['Number:', 'Hon', 'L0/0538']), reason: 'every reading is still kept as evidence');
    // A partial number is still worth showing, as a poor candidate.
    final partial = e.candidates.firstWhere((c) => c.text == 'L0/0538');
    expect(partial.note, contains('Does not fit'));
  });

  test('nothing read gives nothing: no candidates, no suggestion', () {
    final e = ExamNumberResolver.resolve(const [], classList);
    expect(e.candidates, isEmpty);
    expect(e.suggestion, isNull);
    expect(e.raw, isNull);
  });

  test('every attempt is kept, with its reader and picture variant', () {
    final e = ExamNumberResolver.resolve([
      r('FWM/24U/0538', conf: 0.9, variant: 'closeup'),
      r('FWM/24U/0558', conf: 0.5, variant: 'closeup_wide'),
    ], classList);
    expect(e.attempts.map((a) => a.variant), ['closeup', 'closeup_wide']);
    expect(e.attempts.map((a) => a.text), ['FWM/24U/0538', 'FWM/24U/0558']);
    expect(e.attempts.first.reader, 'ocr');
    expect(e.attempts.first.readerVersion, '1');
  });

  test('two variants giving the same tidied reading are "agreeing", and different ones are flagged as disagreeing', () {
    final agree = ExamNumberResolver.resolve([r('FWM/24U/0538', conf: 0.8), r('FWM/24U/O538', conf: 0.6, variant: 'closeup_wide')], classList);
    expect(agree.variantsAgree, isTrue);
    final differ = ExamNumberResolver.resolve([r('FWM/24U/0538', conf: 0.8), r('FWM/24U/0839', conf: 0.6, variant: 'closeup_wide')], classList);
    expect(differ.variantsAgree, isFalse);
    expect(differ.warnings.join(' '), contains('disagree'));
  });

  test('the same reader on two variants is evidence of stability, and the doc comment says so', () {
    // Agreement is reported but the policy never auto-accepts handwriting on it.
    final e = ExamNumberResolver.resolve([r('FWM/24U/0538', conf: 0.99), r('FWM/24U/0538', conf: 0.99, variant: 'closeup_wide')], classList);
    expect(e.variantsAgree, isTrue);
  });
}
