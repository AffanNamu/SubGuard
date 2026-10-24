import '../../domain/recognition.dart';
import 'interfaces.dart';

/// Why a booklet is waiting for the examiner, in a few words, so the list can
/// put the ones that need the most care where they can be seen. Null when no
/// run is stored (a photo that was never read): it is simply waiting.
String? attentionOf(RecognitionResult? r) {
  if (r == null) return null;
  final reasons = <String>[];
  if (r.quality?.hasBlocking ?? false) reasons.add('retake the photo');
  if (r.fields.any((f) => f.state == FieldState.failed)) reasons.add('reading failed');
  final exam = r.field('exam_number');
  if (exam == null || (exam.value == null && exam.candidates.isEmpty)) reasons.add('exam number not read');
  final rows = r.fields.where((f) => f.key.startsWith('mark_row_')).toList();
  if (rows.isEmpty && !r.fields.any((f) => f.state == FieldState.failed)) {
    reasons.add('no marks found');
  } else if (rows.isNotEmpty) {
    final unclear = rows.where((f) => f.state != FieldState.recognized || f.value == null || f.value!.contains('?') || f.question == null).length;
    if (unclear > 0) reasons.add('$unclear mark ${unclear == 1 ? 'row' : 'rows'} to check');
  }
  if (r.findings.any((f) => f.severity.name == 'danger')) reasons.add('marks break a rule');
  if (reasons.isEmpty) return 'Check every value against the photo';
  final first = reasons.first;
  return '${first[0].toUpperCase()}${first.substring(1)}${reasons.length > 1 ? ' · ${reasons.skip(1).join(' · ')}' : ''}';
}
