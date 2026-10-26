import 'dart:io';

import '../../domain/ocr.dart';
import '../../domain/recognition.dart';
import '../reader/booklet_extractor.dart';
import '../reader/ocr_engine.dart';
import '../vision/page_geometry.dart';
import '../vision/quality.dart';
import 'validation.dart';

export '../reader/booklet_extractor.dart' show LayoutAnalyzer;
export '../vision/mark_reader.dart' show HandwritingRecognizer;
export '../vision/page_geometry.dart' show DocumentBoundaryDetector;
export '../vision/quality.dart' show DocumentQualityAnalyzer;

/// The stages of the recognition pipeline, as interfaces, so any stage can be
/// replaced (a better page detector, another handwriting model, a department's
/// own layout) without touching the others or the screens.
///
/// What implements each one today:
///
/// | stage                         | interface                  | implementation        |
/// |-------------------------------|----------------------------|-----------------------|
/// | picture quality               | [DocumentQualityAnalyzer]  | `QualityAnalyzer`     |
/// | page outline                  | [DocumentBoundaryDetector] | `PageDetector`        |
/// | printed text                  | [PrintedTextRecognizer]    | `OcrEngine` (PaddleOCR on the phone) |
/// | layout and field regions      | [LayoutAnalyzer]           | `ProfileLayoutAnalyzer` (a layout profile) |
/// | handwritten marks             | [HandwritingRecognizer]    | `MarkReader` + digit network |
/// | checks on the result          | `ExaminationValidator`     | `SchemeExaminationValidator` |
/// | when a reading may be trusted | [FieldConfidencePolicy]    | `RecognitionPolicy`   |
/// Reads printed text anywhere on the photo. Handwriting goes to
/// [HandwritingRecognizer]; this reads the printed labels the layout hangs on
/// and the printed booklet number.
typedef PrintedTextRecognizer = OcrEngine;

/// Decides when a machine reading may be called "recognized".
typedef FieldConfidencePolicy = RecognitionPolicy;

/// The result of running the whole pipeline on one photograph.
class RecognitionResult {
  const RecognitionResult({
    required this.fields,
    required this.quality,
    required this.findings,
    required this.layout,
    required this.models,
    required this.timingsMs,
    required this.printed,
    this.page,
    this.notes = const [],
    this.answeredLine,
    this.straightened = false,
    this.turnedQuarters = 0,
    this.pipelineVersion = BookletPipelineInfo.version,
  });

  final List<ExtractedField> fields;
  final QualityReport? quality;
  final List<ValidationFinding> findings;
  final BookletReading layout;

  /// The printed text found over the whole photo, with the engine that read it.
  final OcrDocument printed;

  /// Every model that produced something in this result: name, version, and
  /// what it was used for.
  final List<Map<String, String>> models;

  /// Milliseconds spent in each stage.
  final Map<String, int> timingsMs;
  final PageDetection? page;

  /// Plain-language things the examiner or an administrator should know: a
  /// reader that was unavailable, a stage that was skipped, and why.
  final List<String> notes;
  final String? answeredLine;

  /// The page was straightened before it was read. Regions in this result are on
  /// the original photograph either way; the printed text's boxes are on the
  /// straightened page when this is true.
  final bool straightened;

  /// The photo was turned clockwise by this many quarter-turns (0 to 3) before
  /// it was read, because it was taken sideways or upside down. Regions are on
  /// the original photograph either way.
  final int turnedQuarters;
  final String pipelineVersion;

  ExtractedField? field(String key) {
    for (final f in fields) {
      if (f.key == key) return f;
    }
    return null;
  }

  /// A stage failed, so some fields are `failed` rather than read.
  bool get partial => fields.any((f) => f.state == FieldState.failed);

  Map<String, Object?> toJson() => {
        'pipelineVersion': pipelineVersion,
        'fields': [for (final f in fields) f.toJson()],
        'quality': quality?.toJson(),
        'findings': [for (final f in findings) f.toJson()],
        'layout': layout.toJson(),
        'models': models,
        'timingsMs': timingsMs,
        'page': page?.toJson(),
        'notes': notes,
        'answeredLine': answeredLine,
        'straightened': straightened,
        'turnedQuarters': turnedQuarters,
      };

  static RecognitionResult fromJson(Map<String, dynamic> j, {OcrDocument printed = OcrDocument.empty}) => RecognitionResult(
        pipelineVersion: j['pipelineVersion'] as String? ?? 'unknown',
        fields: [for (final f in (j['fields'] as List? ?? const [])) ExtractedField.fromJson(f as Map<String, dynamic>)],
        quality: j['quality'] == null ? null : QualityReport.fromJson(j['quality'] as Map<String, dynamic>),
        findings: [for (final f in (j['findings'] as List? ?? const [])) ValidationFinding.fromJson(f as Map<String, dynamic>)],
        layout: BookletReading.fromJson((j['layout'] as Map?)?.cast<String, dynamic>() ?? const {}),
        models: [for (final m in (j['models'] as List? ?? const [])) (m as Map).map((k, v) => MapEntry(k as String, v as String))],
        timingsMs: ((j['timingsMs'] as Map?) ?? const {}).map((k, v) => MapEntry(k as String, (v as num).toInt())),
        printed: printed,
        page: j['page'] == null ? null : PageDetection.fromJson(j['page'] as Map<String, dynamic>),
        notes: [for (final n in (j['notes'] as List? ?? const [])) n as String],
        answeredLine: j['answeredLine'] as String?,
        straightened: j['straightened'] as bool? ?? false,
        turnedQuarters: (j['turnedQuarters'] as num?)?.toInt() ?? 0,
      );
}

/// Runs the recognition stages on one photo. The scan processor depends on this
/// interface, so a different orchestrator (or a test double) can replace the
/// pipeline.
abstract interface class RecognitionOrchestrator {
  /// Throws [RecognitionException] when the photo cannot be processed at all
  /// and [RecognitionCancelled] when [isCancelled] says to stop; any other
  /// problem is reported inside the result.
  Future<RecognitionResult> run(
    File photo, {
    List<String> classList,
    ExaminationValidator? validator,
    bool Function()? isCancelled,
  });
}

/// The photograph could not be processed at all (the file is missing, too large
/// or not a picture). One field failing is not this: it is reported as
/// `FieldState.failed` and the rest carry on.
class RecognitionException implements Exception {
  const RecognitionException(this.message);
  final String message;
  @override
  String toString() => 'RecognitionException($message)';
}

class RecognitionCancelled implements Exception {
  const RecognitionCancelled();
}

class BookletPipelineInfo {
  const BookletPipelineInfo._();

  /// Bump when a stage changes in a way that can change results, so a stored
  /// result says which version produced it.
  static const version = '1.1.0';
}
