/// What the recognition pipeline hands to the rest of the app.
///
/// The central rule: a value read by a machine is a *suggestion*, kept apart
/// from what an examiner has confirmed, and it never becomes a record by itself.
library;

import 'ocr.dart' show Region;

/// How much a field's reading can be relied on.
enum FieldState {
  /// Supported by enough visual evidence under a validated threshold.
  recognized('recognized'),

  /// A reading exists but is ambiguous, inconsistent or not yet validated.
  needsReview('needs_review'),

  /// There is not enough ink or detail to offer any reading.
  unreadable('unreadable'),

  /// The pipeline could not process this field (an error, not a judgement).
  failed('failed');

  const FieldState(this.dbValue);
  final String dbValue;

  static FieldState fromDb(String? v) => FieldState.values.firstWhere((s) => s.dbValue == v, orElse: () => FieldState.needsReview);
}

enum FieldKind {
  registrationNumber('registration_number'),
  printedNumber('printed_number'),
  handwrittenText('handwritten_text'),
  questionNumber('question_number'),
  mark('mark');

  const FieldKind(this.dbValue);
  final String dbValue;

  static FieldKind fromDb(String? v) => FieldKind.values.firstWhere((k) => k.dbValue == v, orElse: () => FieldKind.handwrittenText);

  bool get isHandwritten => this != printedNumber;
}

/// One possible reading of a field.
class FieldCandidate {
  const FieldCandidate(this.text, this.score, {this.source = '', this.note});

  final String text;

  /// Ranks this reading against the others for the same field. Not a
  /// probability of being correct.
  final double score;

  /// Which reader and which picture variant produced it.
  final String source;

  /// Why it is offered, when that is not obvious (for example, that part of it
  /// was taken from the class list rather than read).
  final String? note;

  Map<String, Object?> toJson() => {'text': text, 'score': score, 'source': source, if (note != null) 'note': note};

  static FieldCandidate fromJson(Map<String, dynamic> j) =>
      FieldCandidate(j['text'] as String, (j['score'] as num).toDouble(), source: j['source'] as String? ?? '', note: j['note'] as String?);
}

/// One attempt to read a field, kept so a result can always be traced to what
/// produced it.
class ReadAttempt {
  const ReadAttempt({required this.reader, required this.readerVersion, required this.variant, this.text, this.confidence});

  final String reader;
  final String readerVersion;

  /// The picture variant that was read ("gray", "flat", "red_ink", ...).
  final String variant;
  final String? text;
  final double? confidence;

  Map<String, Object?> toJson() => {'reader': reader, 'readerVersion': readerVersion, 'variant': variant, 'text': text, 'confidence': confidence};

  static ReadAttempt fromJson(Map<String, dynamic> j) => ReadAttempt(
        reader: j['reader'] as String,
        readerVersion: j['readerVersion'] as String,
        variant: j['variant'] as String,
        text: j['text'] as String?,
        confidence: (j['confidence'] as num?)?.toDouble(),
      );
}

/// One field found on a photographed booklet.
class ExtractedField {
  const ExtractedField({
    required this.key,
    required this.kind,
    required this.state,
    this.value,
    this.candidates = const [],
    this.rawConfidence,
    this.calibratedConfidence,
    this.region,
    this.attempts = const [],
    this.warnings = const [],
    this.question,
  });

  /// Stable name within a booklet: "exam_number", "serial_no", "mark_row_2", ...
  final String key;
  final FieldKind kind;
  final FieldState state;

  /// The machine's best reading, or null. A suggestion, not a record.
  final String? value;
  final List<FieldCandidate> candidates;

  /// The reader's own score for [value]. Not a probability of being right.
  final double? rawConfidence;

  /// Set only when thresholds have been calibrated on labelled data.
  final double? calibratedConfidence;

  /// Where it is on the original photograph, as fractions of its width and height.
  final Region? region;
  final List<ReadAttempt> attempts;
  final List<String> warnings;

  /// For marks: the question number read for the row, when there is one.
  final String? question;

  ExtractedField copyWith({FieldState? state, String? value, List<FieldCandidate>? candidates, List<String>? warnings, Region? region}) => ExtractedField(
        key: key,
        kind: kind,
        state: state ?? this.state,
        value: value ?? this.value,
        candidates: candidates ?? this.candidates,
        rawConfidence: rawConfidence,
        calibratedConfidence: calibratedConfidence,
        region: region ?? this.region,
        attempts: attempts,
        warnings: warnings ?? this.warnings,
        question: question,
      );

  Map<String, Object?> toJson() => {
        'key': key,
        'kind': kind.dbValue,
        'state': state.dbValue,
        'value': value,
        'candidates': [for (final c in candidates) c.toJson()],
        'rawConfidence': rawConfidence,
        'calibratedConfidence': calibratedConfidence,
        'region': region?.toJson(),
        'attempts': [for (final a in attempts) a.toJson()],
        'warnings': warnings,
        'question': question,
      };

  static ExtractedField fromJson(Map<String, dynamic> j) => ExtractedField(
        key: j['key'] as String,
        kind: FieldKind.fromDb(j['kind'] as String?),
        state: FieldState.fromDb(j['state'] as String?),
        value: j['value'] as String?,
        candidates: [for (final c in (j['candidates'] as List? ?? const [])) FieldCandidate.fromJson(c as Map<String, dynamic>)],
        rawConfidence: (j['rawConfidence'] as num?)?.toDouble(),
        calibratedConfidence: (j['calibratedConfidence'] as num?)?.toDouble(),
        region: j['region'] == null ? null : _region(j['region'] as Map<String, dynamic>),
        attempts: [for (final a in (j['attempts'] as List? ?? const [])) ReadAttempt.fromJson(a as Map<String, dynamic>)],
        warnings: [for (final w in (j['warnings'] as List? ?? const [])) w as String],
        question: j['question'] as String?,
      );

  static Region _region(Map<String, dynamic> r) =>
      Region((r['left'] as num).toDouble(), (r['top'] as num).toDouble(), (r['right'] as num).toDouble(), (r['bottom'] as num).toDouble());
}

/// When a machine reading may be called "recognized", and when it must be
/// checked.
///
/// The thresholds here are NOT calibrated: no labelled set large enough exists
/// yet (docs/recognition/DATASET.md), so for handwriting the answer is "always
/// check". Printed numbers can be accepted when two different picture variants
/// give the same reading above a floor. Loosening any of this needs a
/// calibration report, and the report's numbers, to be committed with the change.
class RecognitionPolicy {
  const RecognitionPolicy({
    this.autoAcceptHandwriting = false,
    this.printedAcceptConfidence = 0.90,
    this.minReadingScore = 0.0,
  });

  /// Handwritten values (registration numbers, marks, question numbers) are
  /// never "recognized" by the machine alone while this is false.
  final bool autoAcceptHandwriting;

  /// A printed value is "recognized" only when at least two picture variants
  /// agree and the reader's confidence is at least this.
  final double printedAcceptConfidence;

  /// Readings scoring below this are not even offered as candidates.
  final double minReadingScore;

  static const conservative = RecognitionPolicy();

  /// The state for a field with these characteristics.
  FieldState stateFor({
    required FieldKind kind,
    required bool hasReading,
    required bool inkPresent,
    required bool variantsAgree,
    required double confidence,
    required bool qualityBlocking,
    required bool warnings,
  }) {
    if (!hasReading) return (inkPresent && !qualityBlocking) ? FieldState.needsReview : FieldState.unreadable;
    if (qualityBlocking) return FieldState.needsReview;
    if (kind == FieldKind.printedNumber) {
      return (variantsAgree && confidence >= printedAcceptConfidence && !warnings) ? FieldState.recognized : FieldState.needsReview;
    }
    if (autoAcceptHandwriting && variantsAgree && !warnings) return FieldState.recognized;
    return FieldState.needsReview;
  }
}
