import 'dart:convert';

/// One question-mark record as the examiner left it: the question number and the mark
/// they have confirmed (null where not yet), whether the row was dismissed, and whether
/// they added it themselves. What the machine suggested is not stored: it comes from the
/// stored recognition result.
class DraftRecord {
  const DraftRecord({required this.key, this.qNo, this.mark, this.dismissed = false, this.manual = false});

  final String key;
  final int? qNo;
  final double? mark;
  final bool dismissed;
  final bool manual;

  Map<String, Object?> toJson() => {'key': key, 'qNo': qNo, 'mark': mark, 'dismissed': dismissed, 'manual': manual};

  static DraftRecord fromJson(Map<String, dynamic> j) => DraftRecord(
        key: j['key'] as String,
        qNo: (j['qNo'] as num?)?.toInt(),
        mark: (j['mark'] as num?)?.toDouble(),
        dismissed: j['dismissed'] as bool? ?? false,
        manual: j['manual'] as bool? ?? false,
      );
}

/// What the examiner has entered on one booklet and not yet confirmed.
///
/// It exists so an interrupted review is not lost. It is never a record and is
/// never read by the score grid or by an export; only Confirm writes a result.
class ReviewDraft {
  const ReviewDraft({
    this.examNumber = '',
    this.serial = '',
    this.marks = const {},
    this.editedMarks = const {},
    this.records = const [],
    this.writtenTotal,
    this.addExtra = false,
    this.allowDuplicate = false,
    this.dismissedRows = const {},
    this.runId,
    this.chosenText,
    this.chosenSource,
    this.chosenNote,
  });

  final String examNumber;
  final String serial;

  /// Version 1 drafts only: question number -> mark; null for a mark the examiner
  /// cleared. A version 1 draft is read back as added questions.
  final Map<int, double?> marks;
  final Set<int> editedMarks;

  /// The question-mark records, one per row the machine found or the examiner added.
  final List<DraftRecord> records;
  final double? writtenTotal;
  final bool addExtra;
  final bool allowDuplicate;

  /// Machine rows the examiner dismissed (valid only for the run in [runId]).
  final Set<String> dismissedRows;

  /// The recognition run the draft was made against.
  final String? runId;

  /// The machine suggestion the examiner tapped for the exam number, if any.
  final String? chosenText;
  final String? chosenSource;
  final String? chosenNote;

  Map<String, Object?> toJson() => {
        'v': 2,
        'examNumber': examNumber,
        'serial': serial,
        'marks': {for (final e in marks.entries) '${e.key}': e.value},
        'editedMarks': (editedMarks.toList()..sort()),
        'records': [for (final r in records) r.toJson()],
        'writtenTotal': writtenTotal,
        'addExtra': addExtra,
        'allowDuplicate': allowDuplicate,
        'dismissedRows': (dismissedRows.toList()..sort()),
        'runId': runId,
        'chosenText': chosenText,
        'chosenSource': chosenSource,
        'chosenNote': chosenNote,
      };

  String encode() => jsonEncode(toJson());

  /// Reads a stored draft, or null if it cannot be read (a draft that is
  /// damaged is treated as no draft, never half-applied).
  static ReviewDraft? decode(String? text) {
    if (text == null) return null;
    try {
      final j = jsonDecode(text) as Map<String, dynamic>;
      if (j['v'] != 1 && j['v'] != 2) return null;
      return ReviewDraft(
        examNumber: j['examNumber'] as String? ?? '',
        serial: j['serial'] as String? ?? '',
        marks: {
          for (final e in (j['marks'] as Map? ?? const {}).entries) int.parse(e.key as String): (e.value as num?)?.toDouble(),
        },
        editedMarks: {for (final v in (j['editedMarks'] as List? ?? const [])) (v as num).toInt()},
        records: [for (final r in (j['records'] as List? ?? const [])) DraftRecord.fromJson((r as Map).cast<String, dynamic>())],
        writtenTotal: (j['writtenTotal'] as num?)?.toDouble(),
        addExtra: j['addExtra'] as bool? ?? false,
        allowDuplicate: j['allowDuplicate'] as bool? ?? false,
        dismissedRows: {for (final v in (j['dismissedRows'] as List? ?? const [])) v as String},
        runId: j['runId'] as String?,
        chosenText: j['chosenText'] as String?,
        chosenSource: j['chosenSource'] as String?,
        chosenNote: j['chosenNote'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
