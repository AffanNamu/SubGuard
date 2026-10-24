import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/number_pad_sheet.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/repositories/booklet_repository.dart';
import '../../data/repositories/student_repository.dart';
import '../../domain/models.dart';
import '../../domain/ocr.dart';
import '../../domain/reg_no.dart';
import '../../domain/scan.dart';
import '../../domain/scheme.dart';
import '../../domain/scoring.dart';
import '../../providers/providers.dart';
import '../../services/reader/booklet_extractor.dart';
import '../setup/course_setup_screen.dart';
import 'scan_widgets.dart';

/// Checks one booklet against its photo and confirms it.
///
/// The photo is shown beside every field. The reader fills in only what it
/// could read from print; the exam number and the marks are typed by the
/// examiner from the photo. Nothing reaches the score grid until Confirm.
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
  bool _examFromReader = false;
  bool _saving = false;
  bool _editing = false;

  StoredBooklet? _serialClash;
  StoredBooklet? _studentClash;
  ({double? value, ScoreStatus status, String source})? _existingScore;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _exam.dispose();
    _serial.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final scan = await ref.read(scanRepositoryProvider).scan(widget.scanId);
      if (scan == null) throw StateError('missing');
      final stored = await ref.read(bookletRepositoryProvider).forScan(widget.scanId);
      final course = await ref.read(courseRepositoryProvider).get(scan.courseId);
      if (course == null) throw StateError('course');
      final students = await ref.read(studentRepositoryProvider).getAll(course.id);

      _marks.clear();
      _edited.clear();
      _picked = null;
      _addExtra = false;
      _allowDuplicate = false;
      _written = null;

      if (stored != null && stored.confirmed) {
        final s = students.where((s) => s.id == stored.studentId).firstOrNull;
        _exam.text = s?.regNo ?? '';
        _serial.text = stored.serialNo ?? '';
        _serialFromReader = false;
        _examFromReader = false;
        _marks.addAll(stored.marks);
      } else {
        // What the reader found is put in the field so there is nothing to
        // type when it was right, and it says so, so it is checked.
        final suggested = stored?.reading.examNumberSuggestion;
        _exam.text = suggested ?? '';
        _examFromReader = suggested != null;
        _serial.text = stored?.reading.serialNo ?? '';
        _serialFromReader = stored?.reading.serialNo != null;
      }

      setState(() {
        _scan = scan;
        _stored = stored;
        _course = course;
        _students = students;
        _loading = false;
        _editing = !(stored?.confirmed ?? false);
      });
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
  /// twice needs an explicit OK.
  List<({BannerKind kind, String message})> get _issues {
    final out = <({BannerKind kind, String message})>[];
    final exam = _scheme.examPart;
    for (final e in _entered.entries) {
      final q = _spec(e.key);
      final max = q?.max;
      if (max != null && e.value > max + 1e-9) {
        out.add((kind: BannerKind.danger, message: 'Q${e.key}: ${formatNumber(e.value)} is above the question maximum of ${formatNumber(max)}.'));
      }
      if (exam != null && !ScoreCalculator.isOnStep(e.value, exam.step)) {
        out.add((kind: BannerKind.warning, message: 'Q${e.key}: ${formatNumber(e.value)} is not a multiple of ${formatNumber(exam.step)}.'));
      }
    }
    if (exam != null && _entered.isNotEmpty && _examScore > exam.max + 1e-9) {
      out.add((kind: BannerKind.danger, message: 'The exam score ${formatNumber(_examScore)} is above the ${exam.name} maximum of ${formatNumber(exam.max)}.'));
    }
    if (_written != null && _entered.isNotEmpty && (_written! - _examScore).abs() > 1e-6) {
      out.add((
        kind: BannerKind.warning,
        message:
            'The examiner wrote ${formatNumber(_written!)}, but the marks add up to ${formatNumber(_examScore)} under "${_scheme.countRule.label}". Check the marks, or the counting rule in Course setup.',
      ));
    }
    final answered = _stored?.reading.questionsAnsweredText;
    if (answered != null && _entered.isNotEmpty) {
      final listed = RegExp(r'\d+').allMatches(answered).map((m) => int.parse(m.group(0)!)).toSet();
      if (listed.isNotEmpty && !listed.containsAll(_entered.keys)) {
        out.add((
          kind: BannerKind.warning,
          message: 'The "questions answered" line reads "$answered", but you entered marks for ${_entered.keys.map((k) => 'Q$k').join(', ')}.',
        ));
      }
    }
    return out;
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
        if (reading?.examNumberSuggestion != null && student.regNo != reading!.examNumberSuggestion)
          CorrectionDraft(
            field: 'exam_number',
            readValue: reading.examNumberSuggestion,
            confirmedValue: student.regNo,
            region: reading.examNumberRegion,
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
          );
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

  void _openPhoto() {
    final scan = _scan;
    if (scan == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => _PhotoViewer(relativePath: scan.relativePath, title: scan.displayName)));
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
          IconButton(tooltip: 'See the whole photo', icon: const Icon(Icons.fullscreen_rounded), onPressed: _openPhoto),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PhotoPart(scan: scan, region: reading?.examNumberRegion, maxHeight: 110, onTap: _openPhoto),
                        const SizedBox(height: 10),
                        if (_examFromReader && !locked)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InfoBanner(
                              message: 'Read automatically'
                                  '${reading?.examNumberConfidence == null ? '' : ' (${((reading!.examNumberConfidence!) * 100).round()}% sure)'}'
                                  '${reading?.examNumberOnClassList == true ? ' and found on the class list' : ''}'
                                  '. Check it against the photo; tap the field to change it.',
                              kind: BannerKind.warning,
                              icon: Icons.auto_awesome_rounded,
                            ),
                          ),
                        TextField(
                          controller: _exam,
                          enabled: !locked,
                          autocorrect: false,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {
                            _picked = null;
                            _addExtra = false;
                            _examFromReader = false;
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PhotoPart(
                          scan: scan,
                          region: _marksRegion(reading),
                          maxHeight: 240,
                          onTap: _openPhoto,
                        ),
                        const SizedBox(height: 4),
                        Text('Skip a question that has a line through it or no mark.',
                            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                        const SizedBox(height: 8),
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
                        _PhotoPart(scan: scan, region: reading?.totalRegion, maxHeight: 70, onTap: _openPhoto),
                        const SizedBox(height: 8),
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
                    _examFromReader = false;
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
  const _Section({required this.icon, required this.color, required this.title, required this.child});

  final IconData icon;
  final Color color;
  final String title;
  final Widget child;

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

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.relativePath, required this.title});

  final String relativePath;
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(title),
        ),
        body: InteractiveViewer(
          minScale: 1,
          maxScale: 8,
          child: Center(child: ScanImage(relativePath: relativePath, fit: BoxFit.contain, cacheWidth: 2400)),
        ),
      );
}
