import '../../domain/ocr.dart';

/// What was found on a booklet cover.
///
/// Printed text is read; handwriting is only ever offered as a suggestion that
/// the examiner must confirm. A value that was not found is null, never a guess
/// and never a zero.
class BookletReading {
  const BookletReading({
    this.serialNo,
    this.serialConfidence,
    this.examNumberSuggestion,
    this.examNumberConfidence,
    this.examNumberOnClassList = false,
    this.questionsAnsweredText,
    this.institution,
    this.examNumberRegion,
    this.questionColumnRegion,
    this.marksRegion,
    this.totalRegion,
    this.answeredRegion,
    this.foundAnchors = const [],
    this.missingAnchors = const [],
    this.layoutSupport = 0,
    this.layoutContradictions = 0,
    this.warnings = const [],
  });

  /// The printed booklet number, top right. Unique per booklet, so it also
  /// catches the same booklet being photographed twice.
  final String? serialNo;
  final double? serialConfidence;

  /// The exam number the engine read from the handwriting, only when it
  /// matches DEPT/YYU/NNNN or is close to exactly one number on the class list
  /// (in which case it is that class-list number). The review screen fills the
  /// field with it and says it was read automatically, so it can be checked and
  /// edited. When the writing is not clear this is null and the field is left
  /// for the examiner.
  final String? examNumberSuggestion;
  final double? examNumberConfidence;

  /// The suggestion is a number on the class list.
  final bool examNumberOnClassList;

  /// The handwritten "questions answered" line (for example "4 5 1 2"), as read.
  final String? questionsAnsweredText;
  final String? institution;

  /// Where on the photo each thing is, found from the printed labels, so the
  /// review screen can show the examiner the right part of the photo.
  final Region? examNumberRegion;
  final Region? questionColumnRegion;
  final Region? marksRegion;
  final Region? totalRegion;
  final Region? answeredRegion;

  final List<String> foundAnchors;
  final List<String> missingAnchors;

  /// How many things about where the labels sit *relative to each other* agree
  /// with the booklet's layout (the Question heading left of the Marks heading
  /// on the same row, the Total below them, ...), and how many disagree. Finding
  /// a label somewhere on the page proves little: a page turned on its side still
  /// has labels in the half of the page the label test allows. Labels in the wrong
  /// order say the page is not the way up the layout expects.
  final int layoutSupport;
  final int layoutContradictions;
  final List<String> warnings;

  /// All the printed labels the layout depends on were found.
  bool get layoutRecognised => missingAnchors.isEmpty;

  /// How well the labels found fit the layout the right way up: labels found and
  /// relations that hold count for it, relations that do not hold count twice against.
  int get layoutScore => foundAnchors.length + layoutSupport - 2 * layoutContradictions;

  /// The same reading with every region moved by [f]; used to put regions found
  /// on a straightened page back onto the photograph the examiner sees.
  BookletReading mapRegions(Region Function(Region) f) => BookletReading(
        serialNo: serialNo,
        serialConfidence: serialConfidence,
        examNumberSuggestion: examNumberSuggestion,
        examNumberConfidence: examNumberConfidence,
        examNumberOnClassList: examNumberOnClassList,
        questionsAnsweredText: questionsAnsweredText,
        institution: institution,
        examNumberRegion: examNumberRegion == null ? null : f(examNumberRegion!),
        questionColumnRegion: questionColumnRegion == null ? null : f(questionColumnRegion!),
        marksRegion: marksRegion == null ? null : f(marksRegion!),
        totalRegion: totalRegion == null ? null : f(totalRegion!),
        answeredRegion: answeredRegion == null ? null : f(answeredRegion!),
        foundAnchors: foundAnchors,
        missingAnchors: missingAnchors,
        layoutSupport: layoutSupport,
        layoutContradictions: layoutContradictions,
        warnings: warnings,
      );

  /// Rebuilds a reading from what [toJson] stored.
  factory BookletReading.fromJson(Map<String, dynamic> j) {
    Region? region(String key) {
      final r = (j['regions'] as Map?)?[key] as Map?;
      if (r == null) return null;
      return Region((r['left'] as num).toDouble(), (r['top'] as num).toDouble(), (r['right'] as num).toDouble(),
          (r['bottom'] as num).toDouble());
    }

    return BookletReading(
      serialNo: j['serialNo'] as String?,
      serialConfidence: (j['serialConfidence'] as num?)?.toDouble(),
      examNumberSuggestion: j['examNumberSuggestion'] as String?,
      examNumberConfidence: (j['examNumberConfidence'] as num?)?.toDouble(),
      examNumberOnClassList: j['examNumberOnClassList'] as bool? ?? false,
      questionsAnsweredText: j['questionsAnsweredText'] as String?,
      institution: j['institution'] as String?,
      examNumberRegion: region('examNumber'),
      questionColumnRegion: region('questionColumn'),
      marksRegion: region('marks'),
      totalRegion: region('total'),
      answeredRegion: region('answered'),
      foundAnchors: [for (final a in (j['foundAnchors'] as List? ?? const [])) a as String],
      missingAnchors: [for (final a in (j['missingAnchors'] as List? ?? const [])) a as String],
      layoutSupport: (j['layoutSupport'] as num?)?.toInt() ?? 0,
      layoutContradictions: (j['layoutContradictions'] as num?)?.toInt() ?? 0,
      warnings: [for (final a in (j['warnings'] as List? ?? const [])) a as String],
    );
  }

  Map<String, Object?> toJson() => {
        'serialNo': serialNo,
        'serialConfidence': serialConfidence,
        'examNumberSuggestion': examNumberSuggestion,
        'examNumberConfidence': examNumberConfidence,
        'examNumberOnClassList': examNumberOnClassList,
        'questionsAnsweredText': questionsAnsweredText,
        'institution': institution,
        'regions': {
          'examNumber': examNumberRegion?.toJson(),
          'questionColumn': questionColumnRegion?.toJson(),
          'marks': marksRegion?.toJson(),
          'total': totalRegion?.toJson(),
          'answered': answeredRegion?.toJson(),
        },
        'foundAnchors': foundAnchors,
        'missingAnchors': missingAnchors,
        'layoutSupport': layoutSupport,
        'layoutContradictions': layoutContradictions,
        'warnings': warnings,
      };
}

/// Finds where each field is on the photo, from the printed labels, and reads
/// what can be read from print.
abstract interface class LayoutAnalyzer {
  /// What produced the layout, for the record kept with every reading: `id`, `name`,
  /// `version` and `role`.
  Map<String, String> get info;

  /// [printed] is the printed text of the whole photo; [examNumberCrop] a close-up
  /// reading of the exam-number area; [classList] the course's registration
  /// numbers, used only to suggest.
  BookletReading extract(OcrDocument printed, {OcrDocument? examNumberCrop, List<String> classList});
}
