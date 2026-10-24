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
/// | layout and field regions      | [LayoutAnalyzer]           | `BookletExtractor`    |
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
    this.page,
    this.notes = const [],
    this.answeredLine,
    this.pipelineVersion = BookletPipelineInfo.version,
  });

  final List<ExtractedField> fields;
  final QualityReport? quality;
  final List<ValidationFinding> findings;
  final BookletReading layout;

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
  final String pipelineVersion;

  ExtractedField? field(String key) {
    for (final f in fields) {
      if (f.key == key) return f;
    }
    return null;
  }
}

class BookletPipelineInfo {
  const BookletPipelineInfo._();

  /// Bump when a stage changes in a way that can change results, so a stored
  /// result says which version produced it.
  static const version = '1.0.0';
}
