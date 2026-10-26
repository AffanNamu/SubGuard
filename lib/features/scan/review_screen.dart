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
import '../../domain/models.dart';
import '../../domain/ocr.dart';
import '../../domain/recognition.dart';
import '../../domain/reg_no.dart';
import '../../domain/review_draft.dart';
import '../../domain/scan.dart';
import '../../domain/scheme.dart';
import '../../domain/scoring.dart';
import '../../providers/providers.dart';
import '../../services/reader/booklet_extractor.dart';
import '../../services/recognition/validation.dart';
import '../setup/course_setup_screen.dart';
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
  final Map<int, double?> _marks = {};
  final Set<int> _edited = {};
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

  /// Question number -> the machine row its mark was taken from.
  final Map<int, String> _markFrom = {};

  /// Machine rows the examiner dismissed.
  final Set<String> _dismissed = {};

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
        marks: Map.of(_marks),
        editedMarks: Set.of(_edited),
        writtenTotal: _written,
        addExtra: _addExtra,
        allowDuplicate: _allowDuplicate,
        dismissedRows: Set.of(_dismissed),
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

      _marks.clear();
      _edited.clear();
      _markFrom.clear();
      _dismissed.clear();
      _examChosen = null;
      _picked = null;
      _addExtra = false;
      _allowDuplicate = false;
      _written = null;

      if (stored != null && stored.confirmed) {
        final s = students.where((s) => s.id == stored.studentId).firstOrNull;
        _exam.text = s?.regNo ?? '';
        _serial.text = stored.serialNo ?? '';
        _serialFromReader = false;
        _marks.addAll(stored.marks);
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
          _marks
            ..clear()
            ..addAll(d.marks);
          _edited
            ..clear()
            ..addAll(d.editedMarks);
          _written = d.writtenTotal;
          _addExtra = d.addExtra;
          _allowDuplicate = d.allowDuplicate;
          if (d.runId == run?.id) _dismissed.addAll(d.dismissedRows);
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

  List<int> get _questionNumbers {
    final nos = <int>{for (final q in _scheme.questions) q.qNo, ..._marks.keys};
    // A course with no question list still shows the usual six rows, and
    // keeps showing them once a mark is typed.
    if (_scheme.questions.isEmpty) nos.addAll([1, 2, 3, 4, 5, 6]);
    return nos.toList()..sort();
  }

  QuestionSpec? _spec(int qNo) {
    for (final q in _scheme.questions) {
      if (q.qNo == qNo) return q;
    }
    return null;
  }

  Map<int, double> get _entered => {
        for (final e in _marks.entries)
          if (e.value != null) e.key: e.value!,
      };

  double get _examScore => ScoreCalculator.examScoreFromQuestions(_scheme, _entered);

  /// Things the examiner should look at. They guide; only the same booklet
  /// twice needs an explicit OK. The rules are the same ones the pipeline
  /// applies to what it read.
  List<({BannerKind kind, String message})> get _issues {
    final findings = SchemeExaminationValidator(_scheme).validate(ExamSnapshot(
      marks: _entered,
      writtenTotal: _written,
      answeredLine: _stored?.reading.questionsAnsweredText,
    ));
    return [
      for (final f in findings) (kind: f.severity == FindingSeverity.danger ? BannerKind.danger : BannerKind.warning, message: f.message),
    ];
  }

  bool get _duplicateNeedsOk => _serialClash != null || _studentClash != null;

  String? get _blocker {
    if (_scheme.examPart == null) return 'This course has no part filled from scanned booklets.';
    if (_matched == null && !(_addExtra && _typed.canonical.isNotEmpty)) return 'Enter the exam number from the photo.';
    if (_entered.isEmpty) return 'Enter at least one mark from the photo.';
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

  List<ExtractedField> get _markRows => [
        for (final f in _run?.result.fields ?? const <ExtractedField>[])
          if (f.key.startsWith('mark_row_')) f,
      ];

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

  void _useMark(ExtractedField row, int? q, FieldCandidate c) {
    final v = double.tryParse(c.text);
    if (q == null || v == null) {
      showMessage(context, 'The question number for this row is not clear. Type the mark under the right question.');
      return;
    }
    setState(() {
      _marks[q] = v;
      _edited.remove(q);
      _markFrom[q] = row.key;
    });
  }

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

    final rowsByQuestion = <int, ExtractedField>{};
    for (final r in _markRows) {
      final q = int.tryParse(r.question ?? '');
      if (q != null) rowsByQuestion.putIfAbsent(q, () => r);
    }
    final used = <String>{};
    for (final e in _entered.entries) {
      final row = rowsByQuestion[e.key];
      if (row != null) used.add(row.key);
      final machine = row?.value;
      final fin = formatNumber(e.value);
      final same = machine != null && _numeric(machine) != null && (_numeric(machine)! - e.value).abs() < 1e-9;
      out.add(FieldReviewDraft(
        fieldKey: 'mark_q${e.key}',
        kind: FieldKind.mark.dbValue,
        machineValue: machine,
        machineState: row?.state.dbValue,
        finalValue: fin,
        decision: machine == null ? 'entered' : (same ? 'accepted' : 'edited'),
        region: row?.region,
      ));
    }
    for (final r in _markRows) {
      if (used.contains(r.key) || r.value == null) continue;
      out.add(FieldReviewDraft(
        fieldKey: r.key,
        kind: FieldKind.mark.dbValue,
        machineValue: r.value,
        machineState: r.state.dbValue,
        decision: 'rejected',
        region: r.region,
      ));
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

  Future<void> _enterMark(int qNo) async {
    final spec = _spec(qNo);
    final step = _scheme.examPart?.step ?? 0.5;
    final result = await showNumberPad(
      context,
      title: 'Question $qNo mark',
      hint: spec == null ? 'As written in the Marks column' : 'Out of ${formatNumber(spec.max)}',
      initial: _marks[qNo],
      max: spec?.max,
      step: step,
    );
    if (result == null) return;
    setState(() {
      _marks[qNo] = result.value;
      _edited.add(qNo);
    });
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
            marks: _entered,
            editedMarks: _edited.intersection(_entered.keys.toSet()),
            examScore: _examScore,
            examPartId: exam.id,
            photoPath: _scan!.relativePath,
            corrections: corrections,
            reviews: _reviewDrafts(student, serial),
            runId: _run?.id,
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
                    title: 'Marks',
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
                        const SizedBox(height: 4),
                        Text('Skip a question that has a line through it or no mark.',
                            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                        const SizedBox(height: 8),
                        if (!locked) _machineMarks(),
                        for (final q in _questionNumbers) _markRow(q, locked),
                        if (!locked)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => setState(() {
                                final next = (_questionNumbers.isEmpty ? 0 : _questionNumbers.last) + 1;
                                _marks[next] = null;
                              }),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_entered.isEmpty ? '—' : formatNumber(_examScore), style: text.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text('of ${formatNumber(_scheme.examPart?.max ?? 0)}', style: text.titleMedium?.copyWith(color: scheme.onSurfaceVariant)),
                            ),
                          ],
                        ),
                        Text('Counting rule: ${_scheme.countRule.label}${_scheme.countN == null ? '' : ' (${_scheme.countN})'}',
                            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                        const SizedBox(height: 10),
                        _PhotoPart(
                          scan: scan,
                          region: reading?.totalRegion,
                          maxHeight: 70,
                          onTap: () => _openPhoto(highlight: reading?.totalRegion, label: "examiner's total"),
                        ),
                        const SizedBox(height: 8),
                        if (!locked) _machineTotal(),
                        OutlinedButton(
                          onPressed: locked ? null : _enterWritten,
                          child: Text(_written == null ? "Add the examiner's written total (optional)" : "Examiner's total: ${formatNumber(_written!)}"),
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
                    ),
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

  /// One card per row of the marks table the machine found, each a suggestion
  /// the examiner can use, dismiss, or look at on the photo.
  Widget _machineMarks() {
    final run = _run;
    if (run == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final failed = _field('mark_rows');
    if (failed != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InfoBanner(message: failed.warnings.isEmpty ? 'The marks could not be read by machine.' : failed.warnings.first, kind: BannerKind.warning),
      );
    }
    final rows = [for (final r in _markRows) if (!_dismissed.contains(r.key)) r];
    final notes = [
      for (final f in run.result.findings)
        if (const {'mark_unclear', 'question_unclear', 'duplicate_question'}.contains(f.code)) f.message,
    ];
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(_markRows.isEmpty ? 'No marks were found by machine. Enter them from the photo.' : 'All machine readings were dismissed.',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Machine readings of the marks table. Handwriting is read imperfectly: check each against the photo before using it.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          for (final row in rows) _markCard(row),
          for (final n in notes)
            Padding(padding: const EdgeInsets.only(bottom: 6), child: InfoBanner(message: n, kind: BannerKind.info)),
        ],
      ),
    );
  }

  Widget _markCard(ExtractedField row) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final q = int.tryParse(row.question ?? '');
    final partial = row.value != null && row.value!.contains('?');
    final numeric = [for (final c in row.candidates) if (_numeric(c.text) != null) c];
    final index = row.key.replaceFirst('mark_row_', '');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Row $index${q == null ? ' · question not clear' : ' · reads as Q$q'}', style: text.titleSmall)),
              FieldStateChip(row.state),
            ],
          ),
          const SizedBox(height: 6),
          if (row.value == null)
            Text('Nothing readable in this cell.', style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant))
          else if (partial || numeric.isEmpty)
            Text('Partly read: "${row.value}". Type the mark from the photo.', style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant))
          else
            CandidateChips(candidates: numeric, onUse: (c) => _useMark(row, q, c)),
          if (row.warnings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(row.warnings.first, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ),
          Wrap(
            children: [
              TextButton(
                onPressed: () => _openPhoto(highlight: row.region, label: 'mark in row $index'),
                child: const Text('Show on photo'),
              ),
              TextButton(
                onPressed: () => setState(() => _dismissed.add(row.key)),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ],
      ),
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

  Widget _markRow(int qNo, bool locked) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final value = _marks[qNo];
    final spec = _spec(qNo);
    final bad = value != null && spec != null && value > spec.max + 1e-9;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: !locked,
        label: 'Question $qNo, ${value == null ? 'no mark' : 'mark ${formatNumber(value)}'}${spec == null ? '' : ', out of ${formatNumber(spec.max)}'}',
        excludeSemantics: true,
        child: Material(
          color: bad ? context.colors.dangerContainer : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: locked ? null : () => _enterMark(qNo),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(width: 56, child: Text('Q-$qNo', style: text.titleMedium)),
                    Expanded(
                      child: Text(
                        value == null ? (locked ? '—' : 'Tap to enter') : formatNumber(value),
                        style: value == null
                            ? text.bodyLarge?.copyWith(color: scheme.outline)
                            : text.titleLarge?.copyWith(color: bad ? context.colors.danger : null),
                      ),
                    ),
                    if (spec != null) Text('/ ${formatNumber(spec.max)}', style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                    if (!locked && value != null)
                      IconButton(
                        tooltip: 'Clear Q$qNo',
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => setState(() {
                          _marks[qNo] = null;
                          _edited.add(qNo);
                        }),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
