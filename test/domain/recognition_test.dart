import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/domain/ocr.dart';
import 'package:unimarkly/domain/recognition.dart';

/// When a reading may be called "recognized", and that what a field carries
/// survives being stored and read back.
void main() {
  const policy = RecognitionPolicy.conservative;

  FieldState state(
    FieldKind kind, {
    bool hasReading = true,
    bool inkPresent = true,
    bool agree = true,
    double confidence = 0.99,
    bool blocking = false,
    bool warnings = false,
  }) =>
      policy.stateFor(
        kind: kind,
        hasReading: hasReading,
        inkPresent: inkPresent,
        variantsAgree: agree,
        confidence: confidence,
        qualityBlocking: blocking,
        warnings: warnings,
      );

  group('handwriting is never accepted by the machine', () {
    for (final kind in [FieldKind.registrationNumber, FieldKind.mark, FieldKind.questionNumber, FieldKind.handwrittenText]) {
      test('${kind.dbValue}: even with every variant agreeing at 99% and nothing wrong', () {
        expect(state(kind), FieldState.needsReview);
      });
    }

    test('unless a calibration report loosened the policy, which is an explicit act', () {
      const loosened = RecognitionPolicy(autoAcceptHandwriting: true);
      expect(
        loosened.stateFor(kind: FieldKind.mark, hasReading: true, inkPresent: true, variantsAgree: true, confidence: 0.99, qualityBlocking: false, warnings: false),
        FieldState.recognized,
      );
      expect(
        loosened.stateFor(kind: FieldKind.mark, hasReading: true, inkPresent: true, variantsAgree: false, confidence: 0.99, qualityBlocking: false, warnings: false),
        FieldState.needsReview,
        reason: 'even then, variants must agree',
      );
    });
  });

  group('a printed number', () {
    test('is recognized only with agreeing variants, enough confidence and no warning', () {
      expect(state(FieldKind.printedNumber), FieldState.recognized);
      expect(state(FieldKind.printedNumber, agree: false), FieldState.needsReview);
      expect(state(FieldKind.printedNumber, confidence: 0.89), FieldState.needsReview);
      expect(state(FieldKind.printedNumber, confidence: 0.90), FieldState.recognized);
      expect(state(FieldKind.printedNumber, warnings: true), FieldState.needsReview);
    });
  });

  group('routing for review', () {
    test('a blocking picture caps everything at needs-review', () {
      expect(state(FieldKind.printedNumber, blocking: true), FieldState.needsReview);
      expect(state(FieldKind.mark, blocking: true), FieldState.needsReview);
    });

    test('no reading and no ink is unreadable; no reading but ink is for the examiner', () {
      expect(state(FieldKind.mark, hasReading: false, inkPresent: false), FieldState.unreadable);
      expect(state(FieldKind.mark, hasReading: false, inkPresent: true), FieldState.needsReview);
    });

    test('no reading with ink under a blocking picture is unreadable, not a hopeful guess', () {
      expect(state(FieldKind.mark, hasReading: false, inkPresent: true, blocking: true), FieldState.unreadable);
    });
  });

  test('a field survives being stored and read back, evidence and all', () {
    const field = ExtractedField(
      key: 'mark_row_2',
      kind: FieldKind.mark,
      state: FieldState.needsReview,
      value: '1?0',
      question: '2',
      candidates: [FieldCandidate('140', 0.2, source: 'unimarkly-digits/red_ink', note: 'n')],
      rawConfidence: 0.2,
      region: Region(0.7, 0.4, 0.9, 0.45),
      attempts: [ReadAttempt(reader: 'unimarkly-digits', readerVersion: '1.0.0', variant: 'red_ink', text: '1?0', confidence: 0.2)],
      warnings: ['At least one character could not be read.'],
    );
    final back = ExtractedField.fromJson(field.toJson());
    expect(back.toJson(), field.toJson());
    expect(back.state, FieldState.needsReview);
    expect(back.region!.left, 0.7);
    expect(back.attempts.single.variant, 'red_ink');
    expect(back.calibratedConfidence, isNull, reason: 'no calibration exists, and the stored copy does not invent one');
  });

  test('an unknown stored state is read as needs-review, never as recognized', () {
    expect(FieldState.fromDb('something_new'), FieldState.needsReview);
    expect(FieldState.fromDb(null), FieldState.needsReview);
  });
}
