import '../../domain/layout_profile.dart';
import 'exam_number.dart';
import 'layout_engine.dart';

export 'booklet_reading.dart';
export 'layout_engine.dart' show ProfileLayoutAnalyzer;

/// Finds the printed labels on a Modibbo Adama University booklet cover and works out
/// where the handwritten parts are relative to them: the layout every version of the app
/// has read, now written as a [LayoutProfile] (see [LayoutProfile.modibboAdama]) and read
/// by [ProfileLayoutAnalyzer]. Another cover is read by giving that class another profile.
class BookletExtractor extends ProfileLayoutAnalyzer {
  const BookletExtractor() : super(LayoutProfile.modibboAdama);

  /// Below this, a handwriting suggestion is not offered at all.
  static const double suggestionThreshold = ExamNumberResolver.suggestionThreshold;
}
