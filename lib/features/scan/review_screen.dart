import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/number_pad_sheet.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/repositories/booklet_repository.dart';
import '../../data/repositories/recognition_repository.dart';
import '../../data/repositories/review_draft_repository.dart';
import '../../data/repositories/student_repository.dart';
import '../../domain/exam_tally.dart';
import '../../domain/mark_rules.dart';
import '../../domain/mark_sheet.dart';
import '../../domain/models.dart';
import '../../domain/ocr.dart';
import '../../domain/recognition.dart';
import '../../domain/reg_no.dart';
import '../../domain/review_draft.dart';
import '../../domain/row_suggestions.dart';
import '../../domain/scan.dart';
import '../../domain/scheme.dart';
import '../../domain/scoring.dart';
import '../../providers/providers.dart';
import '../../services/reader/booklet_extractor.dart';
import '../../services/recognition/validation.dart';
import '../setup/course_setup_screen.dart';
import 'mark_records_view.dart';
import 'recognition_widgets.dart';
import 'scan_widgets.dart';

/// Checks one booklet against its photo and confirms it.
///
/// The photo is shown beside every field. What the machine read is offered as
/// suggestions, each saying where it came from and how far it can be trusted;
/// nothing handwritten is entered for the examiner. The examiner confirms every
/// value, and only Confirm puts a mark in the score grid.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.scanId, required this.queue});

  final String scanId;

  /// The photos waiting for review, in order, so Confirm can move to the next.
  final List<String> queue;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  ScanItem? _scan;
  StoredBooklet? _stored;
  Course? _course;
  List<Student> _students = const [];
  bool _loading = true;
  String? _loadError;

  final _exam = TextEditingController();
  final _serial = TextEditingController();

  /// The question-mark records: one per row the machine found or question the examiner
  /// added, each with the question number and the mark the examiner has confirmed (null
  /// until then) and, apart from them, what the machine suggested.
  MarkSheet _sheet = const MarkSheet([]);
  double? _written;
  Student? _picked;
  bool _addExtra = false;
  bool _allowDuplicate = false;
  bool _serialFromReader = false;
  bool _saving = false;
  bool _editing = false;

  /// What the pipeline found (kept as produced), and what the examiner decided
  /// about each field the last time this booklet was confirmed.
  StoredRun? _run;
  List<FieldReview> _reviews = const [];

  /// The suggestion the examiner tapped for the exam number, if they did.
  FieldCandidate? _examChosen;

  // ---- unsaved entries ----
  //
  // What the examiner has typed or chosen and not confirmed is saved a moment
  // after each change, so an interrupted review is not lost. It is restored when
  // the booklet is opened again, says so, and can be discarded. Nothing here
  // reaches the score grid.
  late final ReviewDraftRepository _drafts;
  Timer? _draftTimer;
  bool _draftsOn = false;

  /// The entries as they stood when the booklet was opened (nothing typed yet).
  String? _pristine;
  String? _lastDraft;

  /// When the entries that were restored were saved; null if none were.
  DateTime? _restoredAt;

  StoredBooklet? _serialClash;
  StoredBooklet? _studentClash;
  ({double? value, ScoreStatus status, String source})? _existingScore;

  @override
  void initState() {
    super.initState();
    _drafts = ref.read(reviewDraftRepositoryProvider);
    _load();
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _saveDraftNow(); // before the controllers go: the last keystrokes count
    _exam.dispose();
    _serial.dispose();
    super.dispose();
  }

  /// Every change to what is on screen schedules a save of the entries.
  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    if (_draftsOn) {
      _draftTimer?.cancel();
      _draftTimer = Timer(const Duration(milliseconds: 500), _saveDraftNow);
    }
  }

  ReviewDraft _snapshot({String? runId}) => ReviewDraft(
        examNumber: _exam.text,
        serial: _serial.text,
        records: [for (final r in _sheet.records) DraftRecord(key: r.key, qNo: r.qNo, mark: r.mark, dismissed: r.dismissed, manual: r.manual)],
        writtenTotal: _written,
        addExtra: _addExtra,
        allowDuplicate: _allowDuplicate,
        runId: runId ?? _run?.id,
        chosenText: _examChosen?.text,
        chosenSource: _examChosen?.source,
        chosenNote: _examChosen?.note,
      );

  /// Writes the entries (or removes the draft when they are back to how they
  /// began). Never throws: a draft that cannot be saved must not break the review.
  void _saveDraftNow() {
    if (!_draftsOn || _pristine == null) return;
    final draft = _snapshot();
    final json = draft.encode();
    if (json == _lastDraft) return;
    _lastDraft = json;
    final id = widget.scanId;
    final write = json == _pristine ? _drafts.delete(id) : _drafts.save(id, draft);
    unawaited(write.catchError((_) {}));
  }

  /// The booklet is confirmed or rejected: its draft is gone for good.
  Future<void> _dropDraft() async {
    _draftsOn = false;
    _draftTimer?.cancel();
    try {
      await _drafts.delete(widget.scanId);
    } catch (_) {}
  }

  /// "14:05" for today, "3 Oct, 14:05" otherwise.
  static String _when(DateTime t) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String two(int n) => n.toString().padLeft(2, '0');
    final now = DateTime.now();
    final clock = '${two(t.hour)}:${two(t.minute)}';
    final today = now.year == t.year && now.month == t.month && now.day == t.day;
    return today ? 'today $clock' : '${t.day} ${months[t.month - 1]}, $clock';
  }

  Future<void> _discardDraft() async {
    await _dropDraft();
    if (!mounted) return;
    setState(() => _loading = true);
    await _load(restore: false);
  }

  Future<void> _load({bool restore = true}) async {
    if (restore && _draftsOn) _saveDraftNow(); // reloading must not lose what is on screen
    try {
      final scan = await ref.read(scanRepositoryProvider).scan(widget.scanId);
      if (scan == null) throw StateError('missing');
      final stored = await ref.read(bookletRepositoryProvider).forScan(widget.scanId);
      final course = await ref.read(courseRepositoryProvider).get(scan.courseId);
      if (course == null) throw StateError('course');
      final students = await ref.read(studentRepositoryProvider).getAll(course.id);

      final recognitions = ref.read(recognitionRepositoryProvider);
      final run = await recognitions.latestRun(widget.scanId);
      final reviews = stored?.confirmed == true ? await recognitions.reviewsOf(widget.scanId) : const <FieldReview>[];

      _examChosen = null;
      _picked = null;
      _addExtra = false;
      _allowDuplicate = false;
      _written = null;

      // The records start from the machine's rows with nothing confirmed, or from the
      // marks the examiner confirmed earlier (a booklet being edited again).
      _sheet = _buildSheet(run, stored, course.scheme);
      if (stored != null && (stored.confirmed || stored.records.isNotEmpty)) {
        final s = students.where((s) => s.id == stored.studentId).firstOrNull;
        _exam.text = s?.regNo ?? '';
        _serial.text = stored.serialNo ?? '';
        _serialFromReader = false;
        _written = stored.writtenTotal;
      } else {
        // The exam number is left for the examiner: the machine's readings are
        // offered below it as suggestions to tap, never entered for them. The
        // printed booklet number is filled in and labelled, because it is
        // printed, not handwritten.
        _exam.text = '';
        _serial.text = stored?.reading.serialNo ?? '';
        _serialFromReader = stored?.reading.serialNo != null;
      }

      // Entries left unconfirmed the last time this booklet was open.
      _pristine = _snapshot(runId: run?.id).encode();
      _restoredAt = null;
      final open = !(stored?.confirmed ?? false);
      if (open && restore) {
        final saved = await _drafts.load(widget.scanId);
        if (saved != null && saved.draft.encode() != _pristine) {
          final d = saved.draft;
          _exam.text = d.examNumber;
          _serial.text = d.serial;
          _serialFromReader = _serial.text == (stored?.reading.serialNo ?? '') && _serialFromReader;
          _sheet = _restoreRecords(_sheet, d, run);
          _written = d.writtenTotal;
          _addExtra = d.addExtra;
          _allowDuplicate = d.allowDuplicate;
          if (d.chosenText != null) _examChosen = FieldCandidate(d.chosenText!, 0, source: d.chosenSource ?? '', note: d.chosenNote);
          _restoredAt = saved.savedAt.toLocal();
        }
      }
      _lastDraft = _restoredAt == null ? _pristine : _snapshot(runId: run?.id).encode();

      setState(() {
        _scan = scan;
        _stored = stored;
        _course = course;
        _students = students;
        _run = run;
        _reviews = reviews;
        _loading = false;
        _editing = !(stored?.confirmed ?? false);
      });
      _draftsOn = open;
      await _refreshChecks();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'This booklet could not be opened. It may have been removed.';
        });
      }
    }
  }

  // ---- what the fields add up to ----

  RegNoResult get _typed => RegNo.normalise(_exam.text);

  Student? get _matched {
    if (_picked != null) return _picked;
    final key = _typed.canonical;
    if (key.isEmpty) return null;
    for (final s in _students) {
      if (RegNo.key(s.regNo) == key) return s;
    }
    return null;
  }

  GradingScheme get _scheme => _course!.scheme;

  QuestionSpec? _spec(int qNo) {
    for (final q in _scheme.questions) {
      if (q.qNo == qNo) return q;
    }
    return null;
  }

  int get _highestQuestion => ref.read(settingsProvider).maxQuestionNumber;

  /// The records the review starts from. Machine rows come with their suggestions and
  /// nothing confirmed. When the booklet was confirmed before, each earlier mark is
  /// matched to its machine row by where it was on the photograph (a mark confirmed
  /// before that was recorded has no place, so it is an added question); machine rows
  /// that no earlier mark came from were left out by the examiner, and stay left out.
  MarkSheet _buildSheet(StoredRun? run, StoredBooklet? stored, GradingScheme scheme) {
    final rows = RowSuggestions.allOf(
      run?.result.fields ?? const <ExtractedField>[],
      marksFor: (q) => MarkRules.forScheme(scheme, qNo: q),
      questionRules: QuestionRules(highest: _highestQuestion),
    );
    final fresh = MarkSheet.fromRows(rows);
    final earlier = stored?.records ?? const <ConfirmedMark>[];
    if (earlier.isEmpty) return fresh;

    final used = <String>{};
    final matched = <String, ConfirmedMark>{};
    final manual = <ConfirmedMark>[];
    for (final r in earlier) {
      final here = r.region?.encode();
      final row = here == null ? null : rows.where((x) => !used.contains(x.markKey) && x.markRegion?.encode() == here).firstOrNull;
      if (row == null) {
        manual.add(r);
      } else {
        used.add(row.markKey);
        matched[row.markKey] = r;
      }
    }
    return MarkSheet([
      for (final row in rows)
        if (matched[row.markKey] case final r?)
          MarkRecord(key: row.markKey, qNo: r.qNo, mark: r.mark, suggestions: row)
        else
          MarkRecord(key: row.markKey, suggestions: row, dismissed: true),
      for (final (i, r) in manual.indexed) MarkRecord(key: 'manual-${i + 1}', qNo: r.qNo, mark: r.mark, manual: true),
    ]);
  }

  /// Puts the examiner's unsaved entries back on [base]. A version 1 draft (before the
  /// records existed) comes back as added questions. A row is restored only when the
  /// booklet has not been read again since the draft was made.
  MarkSheet _restoreRecords(MarkSheet base, ReviewDraft d, StoredRun? run) {
    var sheet = base;
    if (d.records.isEmpty) {
      for (final e in d.marks.entries) {
        sheet = sheet.addManual(qNo: e.key, mark: e.value);
      }
      return sheet;
    }
    for (final r in d.records) {
      if (r.manual) {
        sheet = sheet.addManual(qNo: r.qNo, mark: r.mark);
      } else if (d.runId == run?.id && sheet.byKey(r.key) != null) {
        sheet = sheet.setQuestion(r.key, r.qNo).setMark(r.key, r.mark);
        if (r.dismissed) sheet = sheet.dismiss(r.key);
      }
    }
    return sheet;
  }

  ExamTally get _tally => _sheet.tally(_scheme);

  /// The score calculated from the confirmed marks; 0 when none is confirmed.
  double get _examScore => _tally.calculated ?? 0;

  List<RecordProblem> get _problems => _sheet.problems(_scheme, label: _labelOf);

  String _labelOf(MarkRecord r) {
    if (!r.manual) return 'Row ${r.suggestions?.index ?? ''}'.trim();
    return r.qNo == null ? 'An added question' : 'Question ${r.qNo} (added)';
  }

  /// The comparisons the paper's own rules make over the confirmed marks that are not
  /// about one record: the exam score against the exam's maximum, and the "questions
  /// answered" line against the questions that have marks. The written total is compared
  /// with the calculated one separately, and the marks themselves per record.
  List<({BannerKind kind, String message})> get _issues {
    final marks = {for (final m in _sheet.confirmedMarks) m.qNo: m.mark};
    final findings = SchemeExaminationValidator(_scheme).validate(ExamSnapshot(
      marks: marks,
      answeredLine: _stored?.reading.questionsAnsweredText,
    ));
    return [
      for (final f in findings)
        if (const {'exam_above_max', 'answered_mismatch'}.contains(f.code))
          (kind: f.severity == FindingSeverity.danger ? BannerKind.danger : BannerKind.warning, message: f.message),
    ];
  }

  bool get _duplicateNeedsOk => _serialClash != null || _studentClash != null;

  String? get _blocker {
    if (_scheme.examPart == null) return 'This course has no part filled from scanned booklets.';
    if (_matched == null && !(_addExtra && _typed.canonical.isNotEmpty)) return 'Enter the exam number from the photo.';
    if (_sheet.confirmedMarks.isEmpty && !_problems.any((p) => p.blocks)) return 'Confirm at least one question and its mark from the photo.';
    final blocking = _problems.where((p) => p.blocks).toList();
    if (blocking.isNotEmpty) {
      return blocking.length == 1 ? blocking.first.message : '${blocking.first.message} (${blocking.length - 1} more to check)';
    }
    if (_duplicateNeedsOk && !_allowDuplicate) return 'Tick the box to confirm this booklet again.';
    return null;
  }

  Future<void> _refreshChecks() async {
    final course = _course;
    if (course == null || _stored?.confirmed == true && !_editing) return;
    final booklets = ref.read(bookletRepositoryProvider);
    final serial = _serial.text.trim();
    final serialClash = serial.isEmpty ? null : await booklets.confirmedWithSerial(course.id, serial, exceptScanId: widget.scanId);
    final student = _matched;
    final studentClash = student == null ? null : await booklets.confirmedFor(course.id, student.id, exceptScanId: widget.scanId);
    final examPart = _scheme.examPart;
    ({double? value, ScoreStatus status, String source})? existing;
    if (student != null && examPart != null) {
      existing = await ref.read(scoreRepositoryProvider).cell(student.id, examPart.id);
    }
    if (!mounted) return;
    setState(() {
      _serialClash = serialClash;
      _studentClash = studentClash;
      _existingScore = existing;
      if (serialClash == null && studentClash == null) _allowDuplicate = false;
    });
  }

  // ---- what the machine found ----

  ExtractedField? _field(String key) => _run?.result.field(key);

  static double? _numeric(String? v) => (v == null || v.contains('?')) ? null : double.tryParse(v);

  FieldReview? _reviewOf(String key) {
    FieldReview? last;
    for (final r in _reviews) {
      if (r.fieldKey == key) last = r;
    }
    return last;
  }

  /// The machine's first choice for a field, used to say what the examiner's
  /// decision was measured against.
  static String? _machineValue(ExtractedField? f) => f == null ? null : (f.value ?? (f.candidates.isEmpty ? null : f.candidates.first.text));

  void _useExamSuggestion(FieldCandidate c) => setState(() {
        _exam.text = c.text;
        _examChosen = c;
        _picked = null;
        _addExtra = false;
        _refreshChecks();
      });

  void _useWritten(FieldCandidate c) {
    final v = double.tryParse(c.text);
    if (v == null) return;
    setState(() => _written = v);
  }

  /// The examiner's decision about every field, against what the machine read.
  List<FieldReviewDraft> _reviewDrafts(Student student, String? serial) {
    final out = <FieldReviewDraft>[];
    String decide(String? machine, String? finalValue) {
      if (finalValue == null || finalValue.isEmpty) return machine == null ? 'blank' : 'rejected';
      if (machine == null) return 'entered';
      return machine == finalValue ? 'accepted' : 'edited';
    }

    final reading = _stored?.reading;
    final exam = _field('exam_number');
    final machineExam = _machineValue(exam) ?? reading?.examNumberSuggestion;
    // The number the examiner confirmed, measured against what the machine read:
    // the machine's own reading ("accepted"), another of its suggestions that
    // the examiner tapped (for instance a class-list number, "suggestion"),
    // or something the examiner typed ("edited" or "entered").
    final finalKey = RegNo.key(student.regNo);
    final String examDecision;
    if (machineExam != null && RegNo.key(machineExam) == finalKey) {
      examDecision = 'accepted';
    } else if (exam != null && exam.candidates.any((c) => RegNo.key(c.text) == finalKey)) {
      examDecision = 'suggestion';
    } else {
      examDecision = machineExam == null ? 'entered' : 'edited';
    }
    out.add(FieldReviewDraft(
      fieldKey: 'exam_number',
      kind: FieldKind.registrationNumber.dbValue,
      machineValue: machineExam,
      machineState: exam?.state.dbValue,
      finalValue: student.regNo,
      decision: examDecision,
      region: exam?.region ?? reading?.examNumberRegion,
    ));

    final serialField = _field('serial_no');
    final machineSerial = serialField?.value ?? reading?.serialNo;
    if (machineSerial != null || serial != null) {
      out.add(FieldReviewDraft(
        fieldKey: 'serial_no',
        kind: FieldKind.printedNumber.dbValue,
        machineValue: machineSerial,
        machineState: serialField?.state.dbValue,
        finalValue: serial,
        decision: decide(machineSerial, serial),
        region: serialField?.region,
      ));
    }

    // One mark review and one question review for each record the examiner confirmed,
    // each measured against what the machine read for that cell; a row the examiner left
    // out is "rejected".
    for (final r in _sheet.records) {
      final sug = r.suggestions;
      if (r.dismissed) {
        if (sug?.rawMark != null) {
          out.add(FieldReviewDraft(
            fieldKey: sug!.markKey,
            kind: FieldKind.mark.dbValue,
            machineValue: sug.rawMark,
            machineState: _field(sug.markKey)?.state.dbValue,
            decision: 'rejected',
            region: sug.markRegion,
          ));
        }
        continue;
      }
      if (!r.complete) continue;
      out.add(FieldReviewDraft(
        fieldKey: 'mark_q${r.qNo}',
        kind: FieldKind.mark.dbValue,
        machineValue: sug?.rawMark,
        machineState: sug == null ? null : _field(sug.markKey)?.state.dbValue,
        finalValue: formatNumber(r.mark!),
        decision: _markDecision(r),
        region: sug?.markRegion,
      ));
      if (sug != null) {
        out.add(FieldReviewDraft(
          fieldKey: 'question_q${r.qNo}',
          kind: FieldKind.questionNumber.dbValue,
          machineValue: sug.rawQuestion,
          machineState: _field(sug.questionKey)?.state.dbValue,
          finalValue: '${r.qNo}',
          decision: _questionDecision(r),
          region: sug.questionRegion,
        ));
      }
    }

    final total = _field('total_written');
    final machineTotal = total?.value;
    if (_written != null || machineTotal != null) {
      final fin = _written == null ? null : formatNumber(_written!);
      final same = machineTotal != null && _written != null && _numeric(machineTotal) != null && (_numeric(machineTotal)! - _written!).abs() < 1e-9;
      out.add(FieldReviewDraft(
        fieldKey: 'total_written',
        kind: FieldKind.mark.dbValue,
        machineValue: machineTotal,
        machineState: total?.state.dbValue,
        finalValue: fin,
        decision: fin == null ? 'rejected' : (machineTotal == null ? 'entered' : (same ? 'accepted' : 'edited')),
        region: total?.region,
      ));
    }
    return out;
  }

  // ---- actions ----

  /// How the examiner arrived at a record's mark, against what the machine read:
  /// `accepted` (the machine's own reading), `suggestion` (another of its readings,
  /// tapped), `edited` (typed over a reading) or `entered` (typed, nothing was read).
  String _markDecision(MarkRecord r) {
    final sug = r.suggestions;
    if (sug == null) return 'entered';
    bool same(String? text) {
      final v = double.tryParse(text ?? '');
      return v != null && (v - r.mark!).abs() < 1e-9;
    }

    if (same(sug.rawMark)) return 'accepted';
    if (sug.markAlternatives.any((c) => same(c.text))) return 'suggestion';
    return sug.rawMark == null ? 'entered' : 'edited';
  }

  String _questionDecision(MarkRecord r) {
    final sug = r.suggestions;
    if (sug == null) return 'entered';
    bool same(String? text) => int.tryParse(text ?? '') == r.qNo;
    if (same(sug.rawQuestion)) return 'accepted';
    if (sug.questionAlternatives.any((c) => same(c.text))) return 'suggestion';
    return sug.rawQuestion == null ? 'entered' : 'edited';
  }

  Future<void> _enterQuestion(String key) async {
    final r = _sheet.byKey(key);
    final result = await showNumberPad(
      context,
      title: 'Question number',
      hint: 'As written in the Question column',
      initial: r?.qNo?.toDouble(),
      max: _highestQuestion.toDouble(),
      step: 1,
    );
    if (result == null || !mounted) return;
    final v = result.value;
    if (v == null) {
      setState(() => _sheet = _sheet.setQuestion(key, null));
      return;
    }
    final q = v.round();
    if (q < 1 || q > _highestQuestion) {
      showMessage(context, 'Question numbers go from 1 to $_highestQuestion. You can change that limit in Settings.');
      return;
    }
    setState(() => _sheet = _sheet.setQuestion(key, q));
  }

  Future<void> _enterMarkFor(String key) async {
    final r = _sheet.byKey(key);
    final spec = r?.qNo == null ? null : _spec(r!.qNo!);
    final result = await showNumberPad(
      context,
      title: r?.qNo == null ? 'Mark' : 'Question ${r!.qNo} mark',
      hint: spec == null ? 'As written in the Marks column' : 'Out of ${formatNumber(spec.max)}',
      initial: r?.mark,
      max: spec?.max ?? _scheme.examPart?.max,
      step: _scheme.examPart?.step ?? 0.5,
    );
    if (result == null || !mounted) return;
    setState(() => _sheet = _sheet.setMark(key, result.value));
  }

  void _useQuestion(String key, int q) => setState(() => _sheet = _sheet.setQuestion(key, q));
  void _useMark(String key, double m) => setState(() => _sheet = _sheet.setMark(key, m));

  /// Confirms the top suggestion for each field of a row that is not yet confirmed. The
  /// examiner chose to; nothing does it for them.
  void _useBoth(String key) {
    final r = _sheet.byKey(key);
    final sug = r?.suggestions;
    if (r == null || sug == null) return;
    setState(() {
      if (!r.hasQuestion && sug.questionAlternatives.isNotEmpty) _sheet = _sheet.setQuestion(key, int.parse(sug.questionAlternatives.first.text));
      if (!r.hasMark && sug.markAlternatives.isNotEmpty) _sheet = _sheet.setMark(key, double.parse(sug.markAlternatives.first.text));
    });
  }

  /// Adds a question the machine did not find, with a number the examiner gives.
  Future<void> _addQuestion({int? qNo}) async {
    var q = qNo;
    if (q == null) {
      final result = await showNumberPad(
        context,
        title: 'Add a question',
        hint: 'The question number, from 1 to $_highestQuestion',
        max: _highestQuestion.toDouble(),
        step: 1,
      );
      if (result == null || result.value == null || !mounted) return;
      q = result.value!.round();
    }
    if (q < 1 || q > _highestQuestion) {
      showMessage(context, 'Question numbers go from 1 to $_highestQuestion. You can change that limit in Settings.');
      return;
    }
    if (_sheet.live.any((r) => r.qNo == q)) {
      showMessage(context, 'Q$q is already on a row below.');
      return;
    }
    setState(() => _sheet = _sheet.addManual(qNo: q));
  }

  Future<void> _enterWritten() async {
    final result = await showNumberPad(
      context,
      title: "Examiner's total",
      hint: 'The total written in the Total box, if there is one',
      initial: _written,
      max: _scheme.examPart?.max,
      step: _scheme.examPart?.step ?? 0.5,
    );
    if (result == null) return;
    setState(() => _written = result.value);
  }

  Future<void> _confirm() async {
    final course = _course!;
    final exam = _scheme.examPart!;
    setState(() => _saving = true);
    try {
      var student = _matched;
      if (student == null) {
        final studentsRepo = ref.read(studentRepositoryProvider);
        await studentsRepo.addMany(course.id, [NewStudent(_exam.text)], onClassList: false);
        final key = _typed.canonical;
        student = (await studentsRepo.getAll(course.id)).where((s) => RegNo.key(s.regNo) == key).firstOrNull;
      }
      if (student == null) throw StateError('student');

      final reading = _stored?.reading;
      final serial = _serial.text.trim().isEmpty ? null : _serial.text.trim();
      final corrections = <CorrectionDraft>[
        if (reading?.serialNo != null && serial != reading!.serialNo)
          CorrectionDraft(
            field: 'serial_no',
            readValue: reading.serialNo,
            confirmedValue: serial ?? '',
            region: null,
          ),
        if (_machineValue(_field('exam_number')) ?? reading?.examNumberSuggestion case final machine?)
          if (RegNo.key(machine) != RegNo.key(student.regNo))
            CorrectionDraft(
              field: 'exam_number',
              readValue: machine,
              confirmedValue: student.regNo,
              region: reading?.examNumberRegion,
            ),
      ];

      await ref.read(bookletRepositoryProvider).confirm(
            scanId: widget.scanId,
            courseId: course.id,
            studentId: student.id,
            serialNo: serial,
            marks: {for (final m in _sheet.confirmedMarks) m.qNo: m.mark},
            editedMarks: {
              for (final r in _sheet.live)
                if (r.complete && const {'edited', 'entered'}.contains(_markDecision(r))) r.qNo!,
            },
            examScore: _examScore,
            examPartId: exam.id,
            photoPath: _scan!.relativePath,
            corrections: corrections,
            reviews: _reviewDrafts(student, serial),
            runId: _run?.id,
            records: [
              for (final r in _sheet.live)
                if (r.complete)
                  ConfirmedMark(
                    qNo: r.qNo!,
                    mark: r.mark!,
                    edited: const {'edited', 'entered'}.contains(_markDecision(r)),
                    status: _markDecision(r),
                    recognisedMark: r.suggestions?.rawMark,
                    recognisedQuestion: r.suggestions?.rawQuestion,
                    maxMark: _spec(r.qNo!)?.max,
                    region: r.suggestions?.markRegion,
                    questionRegion: r.suggestions?.questionRegion,
                  ),
            ],
            calculatedTotal: _tally.calculated,
            writtenTotal: _written,
            maxTotal: _tally.maxPossible,
            totalNotes: _tally.assumptions,
          );
      await _dropDraft();
      if (!mounted) return;
      _next(confirmedMessage: '${student.regNo}: ${exam.name} ${formatNumber(_examScore)} saved');
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showMessage(context, 'This booklet could not be saved. Nothing was changed. Please try again.');
      }
    }
  }

  /// Moves to the next photo waiting for review, or closes when there is none.
  void _next({String? confirmedMessage}) {
    final queue = widget.queue;
    final i = queue.indexOf(widget.scanId);
    final remaining = [for (var k = i + 1; k < queue.length; k++) queue[k]];
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (remaining.isEmpty) {
      nav.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(confirmedMessage == null ? 'No more booklets to review.' : '$confirmedMessage. All booklets reviewed.'),
      ));
      return;
    }
    nav.pushReplacement(MaterialPageRoute(builder: (_) => ReviewScreen(scanId: remaining.first, queue: queue)));
    if (confirmedMessage != null) {
      messenger.showSnackBar(SnackBar(content: Text(confirmedMessage)));
    }
  }

  Future<void> _reopen() async {
    await ref.read(bookletRepositoryProvider).reopen(widget.scanId);
    setState(() => _loading = true);
    await _load();
    if (mounted) setState(() => _editing = true);
  }

  /// The whole photo, zoomable. With [highlight] the field's place on it is
  /// outlined and brought into view.
  void _openPhoto({Region? highlight, String? label}) {
    final scan = _scan;
    if (scan == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoViewerScreen(
          relativePath: scan.relativePath,
          title: scan.displayName,
          highlight: highlight,
          label: label,
          photoWidth: scan.width,
          photoHeight: scan.height,
          turnedQuarters: _run?.result.turnedQuarters ?? 0,
        ),
      ),
    );
  }

  Future<void> _rejectPhoto() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject this photo?'),
        content: const Text('It will leave the review queue and be marked as not usable. Nothing is added to the score grid. Take the photo again to read it.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reject photo')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(scanRepositoryProvider).setStatus(widget.scanId, ScanStatus.failed, error: 'You rejected this photo. Take it again to read it.');
    await _dropDraft();
    if (mounted) _next();
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null || _scan == null || _course == null) {
      return Scaffold(appBar: AppBar(), body: ErrorState(message: _loadError ?? 'This booklet could not be opened.'));
    }

    final scan = _scan!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final confirmed = _stored?.confirmed ?? false;
    final locked = confirmed && !_editing;
    final position = widget.queue.indexOf(widget.scanId);
    final reading = _stored?.reading;

    return Scaffold(
      appBar: AppBar(
        title: Text(position >= 0 && widget.queue.length > 1 ? 'Review ${position + 1} of ${widget.queue.length}' : 'Review'),
        actions: [
          IconButton(tooltip: 'See the whole photo', icon: const Icon(Icons.fullscreen_rounded), onPressed: () => _openPhoto()),
          if (!locked)
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (v) {
                if (v == 'reject') _rejectPhoto();
              },
              itemBuilder: (context) => const [PopupMenuItem(value: 'reject', child: Text("Can't use this photo"))],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ContentWidth(
              maxWidth: 760,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  Text('${scan.displayName} · ${_course!.title}', style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  if (!locked && _restoredAt != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InfoBanner(
                        message: 'Your unconfirmed entries from ${_when(_restoredAt!)} were restored. Check them against the photo.',
                        kind: BannerKind.info,
                        action: 'Discard them',
                        onAction: _discardDraft,
                      ),
                    ),
                  if (!locked && _run?.result.quality != null) QualityNotice(_run!.result.quality!),
                  if (!locked) _runNotes(),
                  if (reading != null && reading.warnings.isNotEmpty)
                    for (final w in reading.warnings)
                      Padding(padding: const EdgeInsets.only(bottom: 8), child: InfoBanner(message: w, kind: BannerKind.info)),
                  if (_scheme.examPart == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InfoBanner(
                        message: 'This course has no part filled from scanned booklets, so there is nowhere to put the exam score. '
                            'In Course setup, set one part\'s source to "Scanned".',
                        kind: BannerKind.danger,
                        action: 'Open Course setup',
                        onAction: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CourseSetupScreen(existing: _course)),
                        ).then((_) => _load()),
                      ),
                    ),
                  if (confirmed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InfoBanner(
                        message: locked
                            ? 'Confirmed. Its exam score is in the score grid.'
                            : 'Editing a confirmed booklet. Its score changes only when you confirm again.',
                        kind: BannerKind.success,
                        action: locked ? 'Edit this booklet' : null,
                        onAction: _reopen,
                      ),
                    ),

                  // ---- exam number ----
                  _Section(
                    icon: Icons.badge_rounded,
                    color: context.colors.tileBlue,
                    title: 'Exam number',
                    trailing: locked
                        ? const FieldStateChip(FieldState.recognized, confirmed: true)
                        : (_field('exam_number') == null ? null : FieldStateChip(_field('exam_number')!.state)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PhotoPart(
                          scan: scan,
                          region: reading?.examNumberRegion,
                          maxHeight: 110,
                          onTap: () => _openPhoto(highlight: reading?.examNumberRegion, label: 'exam number'),
                        ),
                        const SizedBox(height: 10),
                        if (!locked) _examSuggestions(reading),
                        if (locked) _confirmedNote('exam_number'),
                        TextField(
                          controller: _exam,
                          enabled: !locked,
                          autocorrect: false,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {
                            _picked = null;
                            _addExtra = false;
                            _examChosen = null;
                            _refreshChecks();
                          }),
                          decoration: const InputDecoration(labelText: 'Registration number', hintText: 'FWM/24U/0538'),
                        ),
                        const SizedBox(height: 8),
                        if (!locked) _studentMatch(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ---- booklet number ----
                  _Section(
                    icon: Icons.tag_rounded,
                    color: context.colors.tilePurple,
                    title: 'Booklet number',
                    trailing: locked
                        ? const FieldStateChip(FieldState.recognized, confirmed: true)
                        : (_field('serial_no') == null ? null : FieldStateChip(_field('serial_no')!.state)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (locked) _confirmedNote('serial_no'),
                        TextField(
                          controller: _serial,
                          enabled: !locked,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {
                            _serialFromReader = false;
                            _refreshChecks();
                          }),
                          decoration: const InputDecoration(
                              labelText: 'Printed number, top right', helperText: 'Optional. It stops the same booklet being counted twice.'),
                        ),
                        if (_serialFromReader && !locked) ...[
                          const SizedBox(height: 8),
                          InfoBanner(
                            message: 'Read automatically'
                                '${reading?.serialConfidence == null ? '' : ' (${(reading!.serialConfidence! * 100).round()}% sure)'}'
                                '. Check it against the photo.',
                            kind: BannerKind.warning,
                          ),
                        ],
                        if (_serialClash != null && !locked) ...[
                          const SizedBox(height: 8),
                          InfoBanner(
                            message: 'Booklet ${_serial.text.trim()} was already confirmed from another photo.',
                            kind: BannerKind.danger,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ---- marks ----
                  _Section(
                    icon: Icons.edit_note_rounded,
                    color: context.colors.tileGreen,
                    title: 'Question marks',
                    trailing: locked ? const FieldStateChip(FieldState.recognized, confirmed: true) : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PhotoPart(
                          scan: scan,
                          region: _marksRegion(reading),
                          maxHeight: 240,
                          onTap: () => _openPhoto(highlight: _marksRegion(reading), label: 'marks'),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          locked
                              ? 'The marks you confirmed, one for each question.'
                              : 'One card for each row of the examiner\'s table. The question number and the mark are confirmed separately, '
                                  'and a suggestion is not a value until you tap it.',
                          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        if (!locked) _marksFailure(),
                        if (_sheet.records.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              locked ? 'No marks were recorded.' : 'No rows were found on the photo. Add each question and its mark from the photo.',
                              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ),
                        for (final r in _sheet.records)
                          MarkRecordCard(
                            record: r,
                            label: _labelOf(r),
                            scan: scan,
                            problems: [for (final p in _problems) if (p.key == r.key) p],
                            locked: locked,
                            maxMark: r.qNo == null ? null : _spec(r.qNo!)?.max,
                            onEnterQuestion: () => _enterQuestion(r.key),
                            onEnterMark: () => _enterMarkFor(r.key),
                            onUseQuestion: (q) => _useQuestion(r.key, q),
                            onUseMark: (m) => _useMark(r.key, m),
                            onUseBoth: () => _useBoth(r.key),
                            onShow: r.suggestions == null
                                ? null
                                : () => _openPhoto(highlight: r.suggestions!.markRegion ?? r.suggestions!.questionRegion, label: _labelOf(r).toLowerCase()),
                            onDismiss: () => setState(() => _sheet = _sheet.dismiss(r.key)),
                            onRestore: () => setState(() => _sheet = _sheet.restore(r.key)),
                            onRemove: () => setState(() => _sheet = _sheet.remove(r.key)),
                          ),
                        if (!locked) _notMarked(),
                        if (!locked)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => _addQuestion(),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add a question'),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ---- total ----
                  _Section(
                    icon: Icons.functions_rounded,
                    color: context.colors.tileAmber,
                    title: 'Exam score',
                    child: _totalCard(scan: scan, reading: reading, locked: locked),
                  ),
                  if (_duplicateNeedsOk && !locked) ...[
                    const SizedBox(height: 12),
                    InfoBanner(
                      message: _studentClash != null
                          ? '${_matched?.regNo ?? 'This student'} already has a confirmed booklet. Counting the same booklet twice is the one thing that needs your OK.'
                          : 'This booklet number is already confirmed.',
                      kind: BannerKind.danger,
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _allowDuplicate,
                      onChanged: (v) => setState(() => _allowDuplicate = v ?? false),
                      title: const Text('This is a different booklet. Confirm it anyway.'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          BottomActionBar(
            child: locked
                ? Row(children: [
                    Expanded(child: OutlinedButton(onPressed: () => Navigator.maybePop(context), child: const Text('Close'))),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: GradientButton(label: 'Edit this booklet', expand: true, onPressed: _reopen)),
                  ])
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_blocker != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(_blocker!, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                        ),
                      Row(children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving ? null : () => _next(),
                            child: Text(widget.queue.indexOf(widget.scanId) < widget.queue.length - 1 ? 'Skip for now' : 'Close'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: GradientButton(
                            label: _saving ? 'Saving…' : 'Confirm & next',
                            trailing: Icons.check_rounded,
                            expand: true,
                            onPressed: (_blocker == null && !_saving) ? _confirm : null,
                          ),
                        ),
                      ]),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ---- machine readings ----

  /// Things the run itself reports that the examiner should know: a reader that
  /// was unavailable, a weaker reader that took over, a stage that failed.
  /// (Picture-quality notes are shown by the quality notice instead.)
  Widget _runNotes() {
    final notes = [
      for (final n in _run?.result.notes ?? const <String>[])
        if (!n.startsWith('Picture:')) n,
    ];
    if (notes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final n in notes.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InfoBanner(
              message: n,
              // What the pipeline did on its own (and nothing is wrong) is information;
              // what it could not do is a warning.
              kind: n.contains('ignored') || n.contains('turned upright') || n.contains('was straightened') ? BannerKind.info : BannerKind.warning,
            ),
          ),
      ],
    );
  }

  /// The exam number the machine may have read, as suggestions to tap. Nothing
  /// is entered for the examiner.
  Widget _examSuggestions(BookletReading? reading) {
    final f = _field('exam_number');
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    var candidates = f?.candidates ?? const <FieldCandidate>[];
    if (f == null && reading?.examNumberSuggestion != null) {
      // A photo read before recognition results were kept: its one suggestion.
      candidates = [
        FieldCandidate(
          reading!.examNumberSuggestion!,
          reading.examNumberConfidence ?? 0,
          source: reading.examNumberOnClassList ? 'class_list' : 'ocr',
          note: 'from an earlier reading of this photo',
        ),
      ];
    }
    final chosen = _examChosen != null && _exam.text == _examChosen!.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (candidates.isEmpty)
            Text(
              f == null ? 'Read the number from the photo and type it below.' : 'The machine could not read this clearly. Type the number from the photo.',
              style: text.bodyMedium?.copyWith(color: muted),
            )
          else ...[
            Text('Suggestions. Tap one to use it, then check it against the photo.', style: text.bodyMedium?.copyWith(color: muted)),
            const SizedBox(height: 6),
            CandidateChips(candidates: candidates, onUse: _useExamSuggestion),
          ],
          if (chosen)
            const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 4),
              child: InfoBanner(
                message: 'This is the machine\'s suggestion, not yet checked by you. Compare it with the photo before you confirm.',
                kind: BannerKind.warning,
                icon: Icons.auto_awesome_rounded,
              ),
            ),
          if (f != null) EvidenceTile(f),
        ],
      ),
    );
  }

  /// For a confirmed booklet: what the machine read, beside what was confirmed.
  Widget _confirmedNote(String key) {
    final r = _reviewOf(key);
    if (r == null || r.machineValue == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final String msg;
    if (r.decision == 'accepted') {
      msg = 'The machine read "${r.machineValue}" and you confirmed it.';
    } else if (r.decision == 'rejected') {
      msg = 'The machine read "${r.machineValue}"; you left it out.';
    } else {
      msg = 'The machine read "${r.machineValue}"; you confirmed "${r.finalValue}".';
    }
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(msg, style: text.bodyMedium?.copyWith(color: muted)));
  }

  /// Shown when the marks table could not be read at all.
  Widget _marksFailure() {
    final failed = _field('mark_rows');
    if (failed == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InfoBanner(message: failed.warnings.isEmpty ? 'The marks could not be read by machine.' : failed.warnings.first, kind: BannerKind.warning),
    );
  }

  /// Questions on the course's list that have no record. Tapping one adds a record for
  /// it; they are never added on their own.
  Widget _notMarked() {
    final have = {for (final r in _sheet.live) if (r.qNo != null) r.qNo!};
    final missing = [for (final q in _scheme.questions) if (!have.contains(q.qNo)) q.qNo]..sort();
    if (missing.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _scheme.unmarked == UnmarkedRule.ask
                ? 'On this paper and not marked yet. Each needs a mark (0 if none was given):'
                : 'On this paper and not marked. They count as zero. Tap one to add its mark:',
            style: text.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final q in missing) ActionChip(key: ValueKey('unmarked-$q'), label: Text('Q$q'), onPressed: () => _addQuestion(qNo: q)),
            ],
          ),
        ],
      ),
    );
  }

  /// The exam score: calculated from the confirmed marks, the total the examiner wrote
  /// (if any) beside it, how they compare, and what is still to be decided.
  Widget _totalCard({required ScanItem scan, required BookletReading? reading, required bool locked}) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final tally = _tally;
    final calculated = tally.calculated;
    final part = _scheme.examPart;
    final blocking = [for (final p in _problems) if (p.blocks) p];
    final comparison = TotalComparison.of(calculated: calculated, written: _written);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Calculated total', style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(calculated == null ? '—' : formatNumber(calculated),
                key: const ValueKey('calculated-total'), style: text.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('of ${formatNumber(part?.max ?? 0)}', style: text.titleMedium?.copyWith(color: scheme.onSurfaceVariant)),
            ),
          ],
        ),
        Text(
          calculated == null
              ? 'Worked out from the marks you confirm. Nothing is confirmed yet.'
              : 'Worked out from the ${_sheet.confirmedMarks.length == 1 ? 'mark' : '${_sheet.confirmedMarks.length} marks'} you confirmed. It changes as you change them.',
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        Text(
          'Counting rule: ${_scheme.countRule.label}${_scheme.countN == null ? '' : ' (${_scheme.countN})'}'
          '${tally.maxPossible == null ? '' : '. The questions can add up to at most ${formatNumber(tally.maxPossible!)}.'}',
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (!locked && blocking.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: InfoBanner(
              key: const ValueKey('unresolved'),
              message: blocking.length == 1
                  ? '1 thing still needs you before this can be confirmed: ${blocking.first.message}'
                  : '${blocking.length} things still need you before this can be confirmed. The total leaves them out until they are confirmed.',
              kind: BannerKind.warning,
            ),
          ),
        for (final a in tally.assumptions)
          Padding(padding: const EdgeInsets.only(top: 4), child: Text(a, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
        const Divider(height: 24),
        Text("Examiner's written total", style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        _PhotoPart(
          scan: scan,
          region: reading?.totalRegion,
          maxHeight: 70,
          onTap: () => _openPhoto(highlight: reading?.totalRegion, label: "examiner's total"),
        ),
        const SizedBox(height: 8),
        if (!locked) _machineTotal(),
        OutlinedButton(
          key: const ValueKey('written-total'),
          onPressed: locked ? null : _enterWritten,
          child: Text(_written == null ? (locked ? 'No total was written' : "Record the examiner's written total (optional)") : "Examiner's written total: ${formatNumber(_written!)}"),
        ),
        if (_written == null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('A blank Total box is normal. The calculated total above is what is used.', style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          )
        else if (comparison.agreement == TotalAgreement.agree)
          const Padding(padding: EdgeInsets.only(top: 8), child: InfoBanner(message: 'The written total matches the calculated total.', kind: BannerKind.success))
        else if (comparison.agreement == TotalAgreement.disagree)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: InfoBanner(
              key: const ValueKey('total-mismatch'),
              message: 'The examiner wrote ${formatNumber(_written!)}, but the confirmed marks add up to ${formatNumber(calculated!)} '
                  '(${formatNumber(comparison.difference!.abs())} ${comparison.difference! > 0 ? 'more' : 'less'}). '
                  'Neither has been changed. Check the marks against the photo.',
              kind: BannerKind.warning,
            ),
          ),
        if (!locked)
          for (final issue in _issues)
            Padding(padding: const EdgeInsets.only(top: 8), child: InfoBanner(message: issue.message, kind: issue.kind)),
        if (!locked && _existingScore != null && _existingScore!.value != null && _matched != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: InfoBanner(
              message:
                  '${_matched!.regNo} already has ${_scheme.examPart?.name ?? 'Exam'} ${formatNumber(_existingScore!.value!)} in the score grid '
                  '(${_existingScore!.source == 'typed' ? 'typed in' : _existingScore!.source}). Confirming replaces it.',
              kind: BannerKind.warning,
            ),
          ),
      ],
    );
  }

  /// The machine's reading of the Total box: a suggestion, or "blank".
  Widget _machineTotal() {
    final f = _field('total_written');
    if (f == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final numeric = [for (final c in f.candidates) if (_numeric(c.text) != null) c];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (f.value == null)
            Text(f.state == FieldState.recognized ? 'The Total box looks blank on the photo.' : 'The Total box could not be read. Check the photo.',
                style: text.bodyMedium?.copyWith(color: muted))
          else if (numeric.isEmpty)
            Text('Partly read: "${f.value}". Type the total from the photo.', style: text.bodyMedium?.copyWith(color: muted))
          else ...[
            Text('Machine reading of the Total box (check it):', style: text.bodyMedium?.copyWith(color: muted)),
            const SizedBox(height: 4),
            CandidateChips(candidates: numeric, onUse: _useWritten, max: 2),
          ],
        ],
      ),
    );
  }

  Region? _marksRegion(BookletReading? r) {
    final m = r?.marksRegion;
    if (m == null) return null;
    final q = r!.questionColumnRegion;
    return q == null ? m : Region(q.left, m.top, m.right, m.bottom);
  }

  Widget _studentMatch() {
    final typed = _typed;
    if (typed.canonical.isEmpty) {
      return Text('Type the number written beside "Candidate\'s Examination Number".',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant));
    }
    final match = _matched;
    if (match != null) {
      return InfoBanner(
        message: '${match.regNo}${(match.name ?? '').isEmpty ? '' : ' · ${match.name}'} is on the class list.'
            '${typed.wasCorrected && _picked == null ? ' (${typed.corrections.join('. ')})' : ''}',
        kind: BannerKind.success,
      );
    }
    final suggestions = RegNo.nearest(typed.canonical, _students.map((s) => RegNo.key(s.regNo)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InfoBanner(
          message: typed.isValid
              ? '${typed.canonical} is not on the class list.'
              : '"${typed.canonical}" does not look like DEPT/YYU/NNNN and is not on the class list.',
          kind: BannerKind.warning,
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Did you mean', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in suggestions)
                ActionChip(
                  label: Text(s.regNo),
                  onPressed: () => setState(() {
                    _picked = _students.firstWhere((st) => RegNo.key(st.regNo) == s.regNo);
                    _exam.text = _picked!.regNo;
                    _examChosen = null;
                    _refreshChecks();
                  }),
                ),
            ],
          ),
        ],
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Add as an extra student'),
          subtitle: const Text('Flagged as not on the class list.'),
          value: _addExtra,
          onChanged: (v) => setState(() => _addExtra = v),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.color, required this.title, required this.child, this.trailing});

  final IconData icon;
  final Color color;
  final String title;
  final Widget child;

  /// A chip saying how far the machine's reading of this section can be trusted.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => GlowCard(
        tint: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              GradientIcon(icon: icon, color: color, size: 38),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
              if (trailing != null) trailing!,
            ]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}

/// The part of the photo next to a field. When the printed labels were not
/// found there is no part to show, so the whole photo is shown instead.
class _PhotoPart extends StatelessWidget {
  const _PhotoPart({required this.scan, required this.region, required this.maxHeight, required this.onTap});

  final ScanItem scan;
  final Region? region;
  final double maxHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = scan.width, h = scan.height;
    if (region != null && w != null && h != null && region!.width > 0.02 && region!.height > 0.005) {
      return RegionView(
        relativePath: scan.relativePath,
        region: region!,
        photoWidth: w,
        photoHeight: h,
        maxHeight: maxHeight,
        onTap: onTap,
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        label: 'The whole photo. Tap to enlarge.',
        image: true,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 180,
            width: double.infinity,
            child: ScanImage(relativePath: scan.relativePath, fit: BoxFit.contain, cacheWidth: 900),
          ),
        ),
      ),
    );
  }
}
