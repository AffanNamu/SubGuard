import '../../domain/layout_profile.dart';
import '../../domain/ocr.dart';
import '../../domain/reg_no.dart';
import 'booklet_reading.dart';
import 'exam_number.dart';

/// Finds where each part of a booklet cover is, from the printed labels, for any cover
/// described by a [LayoutProfile].
///
/// It reads what an OCR engine can read (the printed labels and numbers) and works out
/// where the handwritten parts are relative to them. The handwritten exam number is read
/// from a close-up of its area and matched to the class list as a suggestion; the marks
/// are read from the ink in the marks region by the marks stage. Because every region is
/// placed relative to a label, tilt and zoom matter less.
class ProfileLayoutAnalyzer implements LayoutAnalyzer {
  const ProfileLayoutAnalyzer(this.profile);

  final LayoutProfile profile;

  @override
  Map<String, String> get info => {
        'id': 'layout:${profile.id}',
        'name': profile.name,
        'version': '${profile.revision}',
        'role': 'where the exam number, marks table and total are on the cover',
      };

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

    // ---- labels ----
    final boxes = <String, Region>{};
    for (final a in profile.anchors) {
      OcrLine? hit;
      for (final l in lines) {
        if (!a.where.matches(l.box) || !a.words.any((w) => _hasWord(l.text, w))) continue;
        if (a.pick == AnchorPick.first) {
          hit = l;
          break;
        }
        if (hit == null || l.box.bottom > hit.box.bottom) hit = l;
      }
      if (hit != null) boxes[a.key] = hit.box;
      if (a.reported) (hit != null ? found : missing).add(a.name);
    }

    if (lines.isEmpty) {
      warnings.add(doc.note ?? 'No text was read from this photo.');
    } else if (missing.isNotEmpty) {
      warnings.add('Some printed labels were not found (${missing.join(', ')}). Check that the whole cover is in the photo, '
          'or enter the values from the photo yourself.');
    }

    // ---- the printed booklet number ----
    String? serial;
    double? serialConfidence;
    final serialRule = profile.serial;
    if (serialRule != null) {
      final pattern = RegExp(serialRule.pattern);
      for (final l in lines) {
        if (!serialRule.where.matches(l.box)) continue;
        final digits = l.text.replaceAll(RegExp(r'\s'), '');
        if (pattern.hasMatch(digits)) {
          serial = digits;
          serialConfidence = l.confidence;
          break;
        }
      }
    }

    String? institution;
    final institutionRule = profile.institution;
    if (institutionRule != null) {
      for (final l in lines) {
        if (institutionRule.where.matches(l.box) && _hasWord(l.text, institutionRule.word)) {
          institution = l.text.trim();
          break;
        }
      }
    }

    // ---- do the labels sit right relative to each other? ----
    // A page turned on its side still has labels in the half of the page the label tests
    // allow, but not in the right order. Each relation counts only when both labels it is
    // about were found.
    var support = (serial != null ? 1 : 0) + (institution != null ? 1 : 0);
    var contradictions = 0;
    for (final r in profile.relations) {
      final a = boxes[r.a], b = boxes[r.b];
      if (a == null || b == null) continue;
      r.holds(a, b) ? support++ : contradictions++;
    }

    // ---- regions ----
    Region? region(RegionKey key) => profile.regions[key]?.place(boxes);
    final examNumberRegion = region(RegionKey.examNumber);
    final marksRegion = region(RegionKey.marks);
    final questionRegion = region(RegionKey.questionColumn);
    final totalRegion = region(RegionKey.total);
    final answeredRegion = region(RegionKey.answered);

    String? answeredText;
    final readsAs = profile.regions[RegionKey.answered]?.readsAs;
    if (answeredRegion != null && readsAs != null) {
      final pattern = RegExp(readsAs);
      for (final l in lines) {
        final inside = l.box.centerY >= answeredRegion.top && l.box.centerY <= answeredRegion.bottom && l.box.centerX <= answeredRegion.right;
        if (inside && pattern.hasMatch(l.text.trim()) && l.text.trim().isNotEmpty) {
          answeredText = l.text.trim();
          break;
        }
      }
    }

    // ---- the exam number ----
    // Read from the close-up if there is one, else from the whole-photo reading. Only a
    // clear reading is offered, and only as a suggestion.
    final pick = examNumberRegion == null
        ? null
        : ExamNumberResolver.resolve(
            [
              for (final l in [
                ...?examNumberCrop?.lines,
                for (final l in lines)
                  if (_inside(l.box, examNumberRegion)) l,
              ])
                ExamNumberReading(reader: 'ocr', readerVersion: '', variant: 'any', line: l),
            ],
            classList,
          ).suggestion;
    if (examNumberRegion != null && pick == null && lines.isNotEmpty) {
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
      layoutSupport: support,
      layoutContradictions: contradictions,
      warnings: warnings,
    );
  }

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
