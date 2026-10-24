import '../../domain/ocr.dart';
import '../../domain/reg_no.dart';
import 'exam_number.dart';

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
  final List<String> warnings;

  /// All the printed labels the layout depends on were found.
  bool get layoutRecognised => missingAnchors.isEmpty;

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
        'warnings': warnings,
      };
}

/// Finds where each field is on the photo, from the printed labels, and reads
/// what can be read from print.
abstract interface class LayoutAnalyzer {
  /// [printed] is the printed text of the whole photo; [examNumberCrop] a close-up
  /// reading of the exam-number area; [classList] the course's registration
  /// numbers, used only to suggest.
  BookletReading extract(OcrDocument printed, {OcrDocument? examNumberCrop, List<String> classList});
}

/// Finds the printed labels on a booklet cover (the Modibbo Adama layout) and
/// works out where the handwritten parts are relative to them. Because every
/// region is placed relative to a label, tilt and zoom matter less.
///
/// It reads what an OCR engine can read: the printed labels and numbers.
/// The handwritten exam number is read from a close-up of its area and matched
/// to the class list; the marks need a trained handwriting model, which is a
/// later step, so they are entered by the examiner with the right part of the
/// photo beside the field.
class BookletExtractor implements LayoutAnalyzer {
  const BookletExtractor();

  /// Below this, a handwriting suggestion is not offered at all.
  static const double suggestionThreshold = ExamNumberResolver.suggestionThreshold;

  /// [examNumberCrop] is a second reading of just the exam-number area, made
  /// at higher magnification (handwriting is read far better close up).
  /// [classList] is the course's registration numbers; a reading that is close
  /// to exactly one of them is taken to be that one.
  @override
  BookletReading extract(
    OcrDocument doc, {
    OcrDocument? examNumberCrop,
    List<String> classList = const [],
  }) {
    final lines = doc.lines;
    final found = <String>[];
    final missing = <String>[];
    final warnings = <String>[];

    OcrLine? find(String name, bool Function(OcrLine) test) {
      for (final l in lines) {
        if (test(l)) {
          found.add(name);
          return l;
        }
      }
      missing.add(name);
      return null;
    }

    final examLabel = find(
      "Candidate's Examination Number",
      (l) => l.box.left < 0.45 && l.box.top < 0.45 && _hasWord(l.text, 'candidate'),
    );
    final forExaminer = find(
      "For Examiner's Use Only",
      (l) => l.box.centerX > 0.5 && (_hasWord(l.text, 'examiner') || _hasWord(l.text, 'useonly')),
    );
    final questionHeader = find(
      'Question',
      (l) => l.box.left > 0.5 && _hasWord(l.text, 'question'),
    );
    final marksHeader = find(
      'Marks',
      (l) => l.box.left > 0.5 && l.box.top > 0.2 && _hasWord(l.text, 'marks'),
    );
    final total = find(
      'Total',
      (l) => l.box.left > 0.5 && l.box.top > 0.6 && _hasWord(l.text, 'total'),
    );

    if (lines.isEmpty) {
      warnings.add(doc.note ?? 'No text was read from this photo.');
    } else if (missing.isNotEmpty) {
      warnings.add(
          'Some printed labels were not found (${missing.join(', ')}). Check that the whole cover is in the photo, '
          'or enter the values from the photo yourself.');
    }

    // The printed booklet number: digits only, 5 to 8 of them, in the top right.
    String? serial;
    double? serialConfidence;
    for (final l in lines) {
      if (l.box.top > 0.2 || l.box.centerX < 0.5) continue;
      final digits = l.text.replaceAll(RegExp(r'\s'), '');
      if (RegExp(r'^\d{5,8}$').hasMatch(digits)) {
        serial = digits;
        serialConfidence = l.confidence;
        break;
      }
    }

    String? institution;
    for (final l in lines) {
      if (l.box.top < 0.1 && _hasWord(l.text, 'university')) {
        institution = l.text.trim();
        break;
      }
    }

    // Regions, each placed from a printed label.
    Region? examNumberRegion;
    if (examLabel != null) {
      final b = examLabel.box;
      // The writing sits on the line the label is printed on, mostly above it.
      // Below the label comes the handwritten title, so the area stops there.
      examNumberRegion = Region(
        b.right < 0.3 ? 0.3 : b.right,
        b.top - 0.03,
        0.96,
        b.bottom - 0.002,
      ).clamped();
    }

    Region? marksRegion, questionRegion, totalRegion;
    if (marksHeader != null && total != null) {
      final left = marksHeader.box.left - 0.025;
      marksRegion = Region(left, marksHeader.box.bottom, 0.98, total.box.top - 0.004).clamped();
      if (questionHeader != null) {
        questionRegion =
            Region(questionHeader.box.left - 0.025, marksHeader.box.bottom, left - 0.004, total.box.top - 0.004).clamped();
      }
    } else if (forExaminer != null && total != null) {
      marksRegion = Region(forExaminer.box.left, forExaminer.box.bottom + 0.03, 0.98, total.box.top - 0.004).clamped();
    }
    if (total != null) {
      totalRegion = Region(total.box.right, total.box.top - 0.02, 0.98, total.box.bottom + 0.03).clamped();
    }

    // The handwritten "questions answered" line, bottom left under the
    // printed "NUMBER YOUR ANSWERS" instruction.
    Region? answeredRegion;
    String? answeredText;
    OcrLine? instruction;
    for (final l in lines) {
      if (l.box.left < 0.4 && l.box.top > 0.75 && (_hasWord(l.text, 'havebeenwritten') || _hasWord(l.text, 'answers'))) {
        if (instruction == null || l.box.bottom > instruction.box.bottom) instruction = l;
      }
    }
    if (instruction != null) {
      answeredRegion = Region(0.04, instruction.box.bottom, 0.55, instruction.box.bottom + 0.1).clamped();
      for (final l in lines) {
        final inside = l.box.centerY >= answeredRegion.top &&
            l.box.centerY <= answeredRegion.bottom &&
            l.box.centerX <= answeredRegion.right;
        if (inside && RegExp(r'^[\d\s,.\-]{1,12}$').hasMatch(l.text.trim()) && l.text.trim().isNotEmpty) {
          answeredText = l.text.trim();
          break;
        }
      }
    }

    // The exam number: read from the close-up if there is one, else from the
    // whole-photo reading. Only a clear reading is offered.
    final pick = examNumberRegion == null
        ? null
        : _pickExamNumber(
            [
              ...?examNumberCrop?.lines,
              for (final l in lines)
                if (_inside(l.box, examNumberRegion)) l,
            ],
            classList,
          );
    if (examLabel != null && pick == null && lines.isNotEmpty) {
      warnings.add('The exam number could not be read clearly from the photo. Type it from the photo beside the field.');
    }

    return BookletReading(
      serialNo: serial,
      serialConfidence: serialConfidence,
      examNumberSuggestion: pick?.regNo,
      examNumberConfidence: pick?.confidence,
      examNumberOnClassList: pick?.onClassList ?? false,
      questionsAnsweredText: answeredText,
      institution: institution,
      examNumberRegion: examNumberRegion,
      questionColumnRegion: questionRegion,
      marksRegion: marksRegion,
      totalRegion: totalRegion,
      answeredRegion: answeredRegion,
      foundAnchors: found,
      missingAnchors: missing,
      warnings: warnings,
    );
  }

  /// Chooses the exam number to suggest from what was read in its area, by the
  /// rule in [ExamNumberResolver]. It is only ever a suggestion.
  static ({String regNo, double confidence, bool onClassList})? _pickExamNumber(
    List<OcrLine> candidates,
    List<String> classList,
  ) =>
      ExamNumberResolver.resolve(
        [for (final l in candidates) ExamNumberReading(reader: 'ocr', readerVersion: '', variant: 'any', line: l)],
        classList,
      ).suggestion;

  static bool _inside(Region box, Region area) =>
      box.centerX >= area.left && box.centerX <= area.right && box.centerY >= area.top && box.centerY <= area.bottom;

  /// True when [text] contains [word], allowing for the odd wrong or missing
  /// letter an engine makes (ignoring case, spaces and punctuation).
  static bool _hasWord(String text, String word) {
    final t = text.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    final w = word.toLowerCase();
    final allowed = w.length <= 5 ? 1 : (w.length <= 9 ? 2 : 3);
    if (t.contains(w)) return true;
    for (var len = w.length - 1; len <= w.length + 1; len++) {
      if (len <= 0 || len > t.length) continue;
      for (var i = 0; i + len <= t.length; i++) {
        if (RegNo.distance(t.substring(i, i + len), w) <= allowed) return true;
      }
    }
    return false;
  }
}
