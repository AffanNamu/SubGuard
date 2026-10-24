import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import '../../domain/ocr.dart';
import '../../domain/recognition.dart';
import '../reader/booklet_extractor.dart';
import '../reader/exam_number.dart';
import '../reader/ocr_engine.dart';
import '../vision/digit_model.dart';
import '../vision/mark_reader.dart';
import '../vision/page_geometry.dart';
import '../vision/photo_codec.dart';
import '../vision/quality.dart';
import '../vision/raster.dart';
import 'interfaces.dart';
import 'marks_stage.dart';
import 'model_registry.dart';
import 'validation.dart';

/// Limits that keep one bad photograph from using up the phone.
class PipelineLimits {
  const PipelineLimits({
    this.maxFileBytes = 40 * 1024 * 1024,
    this.maxSidePixels = 12000,
    this.workingSide = 2400,
    this.ocrTimeout = const Duration(seconds: 60),
  });

  final int maxFileBytes;

  /// A photograph longer than this on either side is refused, not shrunk
  /// silently: it is almost certainly not a booklet photo.
  final int maxSidePixels;

  /// The long side, in pixels, of the working copy used for analysis. Marks
  /// are read from this copy, so it is large enough for small handwriting.
  final int workingSide;
  final Duration ocrTimeout;
}

/// Reads a booklet photograph: how good the picture is, where the fields are,
/// what each one says, and how far each reading can be trusted.
///
/// The stages, in order:
///  1. check the file, decode it at a bounded size;
///  2. picture quality and page outline (background isolate);
///  3. printed text over the whole photo, and the layout found from its labels;
///  4. close-up readings of the printed booklet number and the handwritten
///     exam number, each in more than one picture variant;
///  5. the marks table: rows found from the ink, each mark and question label
///     read character by character (background isolate);
///  6. checks against the examination rules, which never change a reading;
///  7. every field is given a state by [FieldConfidencePolicy].
///
/// Nothing here writes to the database or decides a record: it returns evidence.
class BookletPipeline implements RecognitionOrchestrator {
  BookletPipeline({
    required this.ocr,
    this.digits,
    this.digitsError,
    this.quality = const QualityAnalyzer(),
    this.boundary = const PageDetector(),
    this.layout = const BookletExtractor(),
    this.policy = RecognitionPolicy.conservative,
    this.limits = const PipelineLimits(),
  });

  final PrintedTextRecognizer ocr;

  /// The verified handwriting model, or null with [digitsError] saying why not.
  /// Without it marks are reported as failed with that message; there is no
  /// silent substitute reader.
  final LoadedDigitModel? digits;
  final String? digitsError;
  final DocumentQualityAnalyzer quality;
  final DocumentBoundaryDetector boundary;
  final LayoutAnalyzer layout;
  final FieldConfidencePolicy policy;
  final PipelineLimits limits;

  /// [classList] is the course's registration numbers (suggestions only);
  /// [validator] checks marks against the course's rules, when there is a course.
  @override
  Future<RecognitionResult> run(
    File photo, {
    List<String> classList = const [],
    ExaminationValidator? validator,
    bool Function()? isCancelled,
  }) async {
    final timings = <String, int>{};
    final notes = <String>[];
    final watch = Stopwatch()..start();
    void lap(String stage) {
      timings[stage] = watch.elapsedMilliseconds;
      watch.reset();
    }

    void checkCancelled() {
      if (isCancelled?.call() ?? false) throw const RecognitionCancelled();
    }

    // ---- 1. the file ----
    if (!await photo.exists()) {
      throw const RecognitionException('The photo file is missing from this phone, so it cannot be read. Remove it and add the photo again.');
    }
    final bytes = await photo.length();
    if (bytes > limits.maxFileBytes) {
      throw RecognitionException('This photo is ${(bytes / 1048576).round()} MB, which is too large to read safely. Take it again at a lower resolution.');
    }
    final DecodedPhoto decoded;
    try {
      decoded = await decodePhoto(photo, maxSide: limits.workingSide);
    } on PhotoDecodeException catch (e) {
      throw RecognitionException(e.message);
    }
    if (decoded.originalWidth > limits.maxSidePixels || decoded.originalHeight > limits.maxSidePixels) {
      throw RecognitionException('This picture is ${decoded.originalWidth} x ${decoded.originalHeight} pixels, which is not a normal photo of a booklet.');
    }
    lap('decode');
    checkCancelled();

    // ---- 2. picture quality and page outline ----
    QualityReport? report;
    PageDetection? page;
    try {
      final qa = await _analyseInIsolate(decoded.image, decoded.originalWidth, decoded.originalHeight, quality, boundary);
      report = qa.$1;
      page = qa.$2;
    } catch (e) {
      notes.add('Picture quality could not be assessed ($e). Every reading below is unchecked for it.');
    }
    final blocking = report?.hasBlocking ?? false;
    lap('quality');
    checkCancelled();

    // ---- 3. printed text, layout ----
    var doc = OcrDocument.empty;
    String? ocrFailure;
    try {
      doc = await ocr.recognize(photo, width: decoded.originalWidth, height: decoded.originalHeight).timeout(limits.ocrTimeout);
    } catch (e) {
      ocrFailure = e is TimeoutException ? 'Reading the printed text took too long.' : 'The text reader failed.';
      notes.add('$ocrFailure The values must be entered from the photo.');
      doc = OcrDocument(
        engine: ocr.name,
        lines: const [],
        note: e is TimeoutException
            ? 'Reading took too long. Enter the values from the photo.'
            : 'Automatic reading failed. Enter the values from the photo.',
      );
    }
    if (doc.note != null && ocrFailure == null) notes.add(doc.note!);
    lap('printed_text');
    checkCancelled();

    var reading = layout.extract(doc, classList: classList);

    // ---- 4. close-ups ----
    final engine = ocr;
    final closeups = <String, OcrDocument>{};
    Future<void> closeup(String variant, Region region) async {
      if (engine is! RegionOcrEngine) return;
      try {
        final d = await engine.recognizeRegion(photo, region).timeout(limits.ocrTimeout);
        closeups[variant] = d;
        // A weaker reader taking over is said once, never silently.
        if (d.note != null && !notes.contains(d.note)) notes.add(d.note!);
      } catch (_) {
        notes.add('A close-up reading ($variant) failed and was skipped.');
      }
    }

    final examRegion = reading.examNumberRegion;
    if (examRegion != null) {
      await closeup('closeup', examRegion);
      await closeup('closeup_wide', examRegion.inflate(x: 0.01, y: 0.012).clamped());
      reading = layout.extract(doc, examNumberCrop: closeups['closeup'], classList: classList);
    }
    final serialLine = _serialLine(doc, reading.serialNo);
    if (serialLine != null) await closeup('serial', serialLine.box.inflate(x: 0.02, y: 0.012).clamped());
    lap('closeups');
    checkCancelled();

    // ---- 5. marks ----
    MarksStageResult? marks;
    String? marksFailure;
    final marksRegion = reading.marksRegion;
    final model = digits;
    if (marksRegion != null && model != null) {
      try {
        marks = await _readMarks(decoded.image, reading, model);
      } catch (e) {
        marksFailure = 'Reading the marks failed ($e).';
        notes.add('$marksFailure Enter the marks from the photo.');
      }
    } else if (marksRegion != null && model == null) {
      marksFailure = digitsError ?? 'The handwriting model is not available.';
      notes.add('$marksFailure Enter the marks from the photo.');
    }
    if (marks != null) notes.addAll(marks.notes);
    lap('marks');

    // ---- 6/7. fields, checks, states ----
    final fields = <ExtractedField>[];
    final qualityWarnings = [for (final i in report?.issues ?? const <QualityIssue>[]) if (i.severity != QualitySeverity.info) i.message];

    fields.addAll(_serialField(doc, reading, closeups['serial'], blocking, ocrFailure));
    fields.addAll(_examNumberField(doc, reading, closeups, classList, marks, blocking, ocrFailure));
    final answered = _answeredField(doc, reading, marks, blocking, ocrFailure);
    if (answered != null) fields.add(answered);
    fields.addAll(_markFields(marks, model, blocking, marksFailure, reading));

    final checks = validator ?? const _NoRules();
    var findings = ReadingChecks.validate(fields, checks, answeredLine: reading.questionsAnsweredText);
    // A finding about a field becomes a warning on it, and a field with a
    // warning is not "recognized".
    final withWarnings = <ExtractedField>[];
    for (final f in fields) {
      final mine = [for (final x in findings) if (x.fields.contains(f.key)) x.message];
      withWarnings.add(mine.isEmpty
          ? f
          : f.copyWith(
              warnings: [...f.warnings, ...mine],
              state: f.state == FieldState.recognized ? FieldState.needsReview : f.state,
            ));
    }
    lap('validation');

    final models = <Map<String, String>>[
      {'id': 'ocr', 'name': doc.engine == 'none' ? ocr.name : doc.engine, 'role': 'printed text; close-up readings of the exam number'},
      if (model != null) {...model.info.toJson(), 'role': 'handwritten digits in the marks table'},
      {'id': 'unimarkly-pipeline', 'version': BookletPipelineInfo.version, 'role': 'quality, page outline, layout, mark rows'},
    ];
    if (qualityWarnings.isNotEmpty) notes.addAll(qualityWarnings.map((m) => 'Picture: $m'));

    return RecognitionResult(
      fields: withWarnings,
      quality: report,
      findings: findings,
      layout: reading,
      models: models,
      timingsMs: timings,
      printed: doc,
      page: page,
      notes: notes,
      answeredLine: reading.questionsAnsweredText,
    );
  }

  // ---- stage helpers ----

  /// Static, and handed only plain data: a background isolate cannot be sent
  /// the pipeline itself, because it holds the platform text reader.
  static Future<MarksStageResult> _readMarks(ColorRaster image, BookletReading reading, LoadedDigitModel model) {
    final marks = reading.marksRegion!;
    final questions = reading.questionColumnRegion;
    final total = reading.totalRegion;
    final probes = <String, Region>{
      if (reading.examNumberRegion != null) 'exam_number': reading.examNumberRegion!,
      if (reading.answeredRegion != null) 'answered': reading.answeredRegion!,
    };
    final weights = model.weights;
    return Isolate.run(() {
      final net = DigitModel.fromBytes(weights);
      final reader = MarkReader((input) => net.predict(input));
      return readMarksTable(image, marks: marks, questions: questions, total: total, probes: probes, reader: reader);
    });
  }

  static Future<(QualityReport, PageDetection)> _analyseInIsolate(
    ColorRaster image,
    int originalWidth,
    int originalHeight,
    DocumentQualityAnalyzer analyzer,
    DocumentBoundaryDetector detector,
  ) =>
      Isolate.run(() => _analyse(image, originalWidth, originalHeight, analyzer, detector));

  OcrLine? _serialLine(OcrDocument doc, String? serial) {
    if (serial == null) return null;
    for (final l in doc.lines) {
      if (l.text.replaceAll(RegExp(r'\s'), '') == serial) return l;
    }
    return null;
  }

  List<ExtractedField> _serialField(OcrDocument doc, BookletReading reading, OcrDocument? crop, bool blocking, String? ocrFailure) {
    final line = _serialLine(doc, reading.serialNo);
    if (line == null) {
      if (ocrFailure != null) {
        return [const ExtractedField(key: 'serial_no', kind: FieldKind.printedNumber, state: FieldState.failed, warnings: ['The text reader failed on this photo.'])];
      }
      return [
        const ExtractedField(
          key: 'serial_no',
          kind: FieldKind.printedNumber,
          state: FieldState.unreadable,
          warnings: ['The printed booklet number was not found.'],
        ),
      ];
    }
    final attempts = <ReadAttempt>[
      ReadAttempt(reader: doc.engine, readerVersion: '', variant: 'whole_photo', text: reading.serialNo, confidence: reading.serialConfidence),
    ];
    String? second;
    if (crop != null) {
      for (final l in crop.lines) {
        final digits = l.text.replaceAll(RegExp(r'\s'), '');
        if (RegExp(r'^\d{5,8}$').hasMatch(digits)) {
          second = digits;
          attempts.add(ReadAttempt(reader: crop.engine, readerVersion: '', variant: 'closeup', text: digits, confidence: l.confidence));
          break;
        }
      }
      if (second == null) attempts.add(ReadAttempt(reader: crop.engine, readerVersion: '', variant: 'closeup', text: null));
    }
    final agree = second != null && second == reading.serialNo;
    final conf = reading.serialConfidence ?? 0;
    final warnings = [
      if (second != null && !agree) 'The close-up read $second but the whole photo read ${reading.serialNo}.',
    ];
    final state = policy.stateFor(
      kind: FieldKind.printedNumber,
      hasReading: true,
      inkPresent: true,
      variantsAgree: agree,
      confidence: conf,
      qualityBlocking: blocking,
      warnings: warnings.isNotEmpty,
    );
    return [
      ExtractedField(
        key: 'serial_no',
        kind: FieldKind.printedNumber,
        state: state,
        value: reading.serialNo,
        candidates: [
          FieldCandidate(reading.serialNo!, conf, source: 'whole_photo'),
          if (second != null && second != reading.serialNo) FieldCandidate(second, conf, source: 'closeup'),
        ],
        rawConfidence: reading.serialConfidence,
        region: line.box,
        attempts: attempts,
        warnings: warnings,
      ),
    ];
  }

  List<ExtractedField> _examNumberField(
    OcrDocument doc,
    BookletReading reading,
    Map<String, OcrDocument> closeups,
    List<String> classList,
    MarksStageResult? marks,
    bool blocking,
    String? ocrFailure,
  ) {
    final region = reading.examNumberRegion;
    if (region == null) {
      return [
        ExtractedField(
          key: 'exam_number',
          kind: FieldKind.registrationNumber,
          state: ocrFailure != null ? FieldState.failed : FieldState.unreadable,
          warnings: [ocrFailure ?? 'The "Candidate\'s Examination Number" label was not found, so the number could not be located.'],
        ),
      ];
    }
    final readings = <ExamNumberReading>[];
    void addAll(String variant, OcrDocument? d) {
      if (d == null) return;
      for (final l in d.lines) {
        readings.add(ExamNumberReading(reader: d.engine, readerVersion: '', variant: variant, line: l));
      }
    }

    addAll('closeup', closeups['closeup']);
    addAll('closeup_wide', closeups['closeup_wide']);
    addAll('whole_photo', OcrDocument(engine: doc.engine, lines: [
      for (final l in doc.lines)
        if (l.box.centerX >= region.left && l.box.centerX <= region.right && l.box.centerY >= region.top && l.box.centerY <= region.bottom) l,
    ]));

    final ev = ExamNumberResolver.resolve(readings, classList);
    final strokes = marks?.strokes['exam_number'];
    final inkPresent = readings.isNotEmpty || (strokes ?? 0) >= 3;
    final state = policy.stateFor(
      kind: FieldKind.registrationNumber,
      hasReading: ev.candidates.isNotEmpty,
      inkPresent: inkPresent,
      variantsAgree: ev.variantsAgree,
      confidence: ev.candidates.isEmpty ? 0 : ev.candidates.first.score,
      qualityBlocking: blocking,
      warnings: ev.warnings.isNotEmpty,
    );
    return [
      ExtractedField(
        key: 'exam_number',
        kind: FieldKind.registrationNumber,
        state: state,
        value: ev.raw,
        candidates: ev.candidates,
        rawConfidence: ev.candidates.isEmpty ? null : ev.candidates.first.score,
        region: region,
        attempts: ev.attempts,
        warnings: [
          ...ev.warnings,
          if (ev.candidates.isEmpty && inkPresent) 'Writing was seen but could not be read. Type the number from the photo.',
          if (!inkPresent) 'No writing was found beside the label.',
        ],
      ),
    ];
  }

  ExtractedField? _answeredField(OcrDocument doc, BookletReading reading, MarksStageResult? marks, bool blocking, String? ocrFailure) {
    final region = reading.answeredRegion;
    if (region == null) return null;
    final text = reading.questionsAnsweredText;
    final strokes = marks?.strokes['answered'] ?? 0;
    final state = policy.stateFor(
      kind: FieldKind.handwrittenText,
      hasReading: text != null,
      inkPresent: strokes >= 1,
      variantsAgree: false,
      confidence: 0,
      qualityBlocking: blocking,
      warnings: false,
    );
    return ExtractedField(
      key: 'answered',
      kind: FieldKind.handwrittenText,
      state: state,
      value: text,
      candidates: [if (text != null) FieldCandidate(text, 0.5, source: '${doc.engine}/whole_photo')],
      region: region,
      attempts: [ReadAttempt(reader: doc.engine, readerVersion: '', variant: 'whole_photo', text: text)],
      warnings: [if (text == null && strokes >= 1) 'Writing was seen but could not be read.'],
    );
  }

  List<ExtractedField> _markFields(MarksStageResult? marks, LoadedDigitModel? model, bool blocking, String? failure, BookletReading reading) {
    if (marks == null) {
      if (failure == null) return const [];
      return [
        ExtractedField(
          key: 'mark_rows',
          kind: FieldKind.mark,
          state: FieldState.failed,
          region: reading.marksRegion,
          warnings: [failure],
        ),
      ];
    }
    final version = model?.info.version ?? '';
    final out = <ExtractedField>[];
    for (final row in marks.rows) {
      final m = row.mark;
      final text = m.text;
      final display = m.displayText;
      final conf = m.rawConfidence;
      final variantAttempt = ReadAttempt(reader: 'unimarkly-digits', readerVersion: version, variant: row.inkVariant, text: display.isEmpty ? null : display, confidence: conf);
      out.add(ExtractedField(
        key: 'mark_row_${row.index}',
        kind: FieldKind.mark,
        state: policy.stateFor(
          kind: FieldKind.mark,
          hasReading: text != null,
          inkPresent: !m.blank && m.chars.isNotEmpty,
          variantsAgree: false,
          confidence: conf,
          qualityBlocking: blocking,
          warnings: m.warnings.isNotEmpty || row.questionText == null,
        ),
        value: text ?? (display.isEmpty ? null : display),
        candidates: [for (final c in m.candidates) FieldCandidate(c.text, c.score, source: 'unimarkly-digits/${row.inkVariant}')],
        rawConfidence: text == null ? null : conf,
        region: row.markCell,
        attempts: [variantAttempt],
        warnings: [...m.warnings, if (m.blank) 'No ink was found in this cell.'],
        question: row.questionText,
      ));
      final q = row.question;
      out.add(ExtractedField(
        key: 'question_row_${row.index}',
        kind: FieldKind.questionNumber,
        state: policy.stateFor(
          kind: FieldKind.questionNumber,
          hasReading: row.questionText != null,
          inkPresent: q != null && !q.blank,
          variantsAgree: false,
          confidence: row.questionCandidates.isEmpty ? 0 : row.questionCandidates.first.score,
          qualityBlocking: blocking,
          warnings: false,
        ),
        value: row.questionText,
        candidates: row.questionCandidates,
        rawConfidence: row.questionCandidates.isEmpty ? null : row.questionCandidates.first.score,
        region: row.questionCell,
        attempts: [ReadAttempt(reader: 'unimarkly-digits', readerVersion: version, variant: row.inkVariant, text: q?.displayText, confidence: q?.rawConfidence)],
        warnings: [if (row.questionText == null) 'The question number in this row could not be read.'],
      ));
    }

    // The Total box: blank is a finding, not a failure.
    final cell = marks.totalCell;
    if (cell != null) {
      final t = marks.total;
      if (marks.totalStrokes == 0 || t == null) {
        out.add(ExtractedField(
          key: 'total_written',
          kind: FieldKind.mark,
          state: blocking ? FieldState.needsReview : FieldState.recognized,
          region: cell,
          warnings: ['The Total box appears to be blank.'],
        ));
      } else {
        out.add(ExtractedField(
          key: 'total_written',
          kind: FieldKind.mark,
          state: policy.stateFor(
            kind: FieldKind.mark,
            hasReading: t.text != null,
            inkPresent: true,
            variantsAgree: false,
            confidence: t.rawConfidence,
            qualityBlocking: blocking,
            warnings: t.warnings.isNotEmpty,
          ),
          value: t.text ?? t.displayText,
          candidates: [for (final c in t.candidates) FieldCandidate(c.text, c.score, source: 'unimarkly-digits/${marks.inkVariant ?? 'dark_ink'}')],
          rawConfidence: t.text == null ? null : t.rawConfidence,
          region: cell,
          attempts: [ReadAttempt(reader: 'unimarkly-digits', readerVersion: version, variant: marks.inkVariant ?? 'dark_ink', text: t.displayText, confidence: t.rawConfidence)],
          warnings: t.warnings,
        ));
      }
    }
    return out;
  }
}

/// Used when there is no course to take rules from: only the machine-reading
/// checks apply.
class _NoRules implements ExaminationValidator {
  const _NoRules();
  @override
  List<ValidationFinding> validate(ExamSnapshot exam) => const [];
}

(QualityReport, PageDetection) _analyse(
  ColorRaster image,
  int originalWidth,
  int originalHeight,
  DocumentQualityAnalyzer quality,
  DocumentBoundaryDetector boundary,
) {
  final page = boundary.detect(image);
  final report = quality.analyze(image, originalWidth: originalWidth, originalHeight: originalHeight, page: page);
  return (report, page);
}
