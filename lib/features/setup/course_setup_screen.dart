import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../domain/defaults.dart';
import '../../domain/models.dart';
import '../../domain/scheme.dart';
import '../../providers/providers.dart';
import 'course_draft.dart';
import 'steps.dart';

/// A short wizard in plain words, with the running total always at the top:
/// "Exam 70 + Test 10 + Assignment 10 + Attendance 10 = 100".
///
/// Used both to create a course and to change an existing one. Every number
/// can be changed at any time; warnings guide and nothing is blocked.
class CourseSetupScreen extends ConsumerStatefulWidget {
  const CourseSetupScreen({super.key, this.existing});

  final Course? existing;

  @override
  ConsumerState<CourseSetupScreen> createState() => _CourseSetupScreenState();
}

class _CourseSetupScreenState extends ConsumerState<CourseSetupScreen> {
  late final CourseDraftController _draft;
  final _templateName = TextEditingController();
  int _step = 0;
  bool _saveAsTemplate = false;
  bool _saving = false;

  static const _titles = ['Course', 'Marks', 'Exam paper', 'Grades'];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _draft = CourseDraftController.edit(existing);
    } else {
      final settings = ref.read(settingsProvider);
      _draft = CourseDraftController.create(
        scheme: Defaults.nigerianScheme(),
        session: settings.defaultSession,
        semester: settings.defaultSemester,
      );
      _draft.templateName = Defaults.builtInTemplate().name;
      _draft.setBasics(department: settings.header.department);
    }
  }

  @override
  void dispose() {
    _draft.dispose();
    _templateName.dispose();
    super.dispose();
  }

  bool get _isLast => _step == _titles.length - 1;

  Future<void> _save() async {
    final problems = _draft.blockingProblems;
    if (problems.isNotEmpty) {
      setState(() => _step = 0);
      showMessage(context, problems.first);
      return;
    }
    if (_saveAsTemplate && _templateName.text.trim().isEmpty) {
      showMessage(context, 'Give the template a name, or switch it off.');
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(courseRepositoryProvider);
      final course = _draft.build();
      await repo.save(course);
      if (_saveAsTemplate) {
        await repo.saveTemplate(_templateName.text, course.scheme);
      }
      if (mounted) Navigator.pop(context, course.id);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showMessage(context, 'Could not save the course. Please try again.');
      }
    }
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    return confirm(
      context,
      title: 'Leave without saving?',
      message: 'The changes you made to this course will be lost.',
      confirmLabel: 'Leave',
      destructive: true,
    );
  }

  bool get _dirty {
    final existing = widget.existing;
    if (existing == null) {
      return _draft.code.trim().isNotEmpty || _draft.differsFrom(Defaults.nigerianScheme());
    }
    return _draft.code != existing.code ||
        _draft.department != existing.department ||
        _draft.session != existing.session ||
        _draft.semester != existing.semester ||
        _draft.differsFrom(existing.scheme);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmLeave();
        if (leave && context.mounted) Navigator.pop(context);
      },
      child: Builder(builder: (context) {
        final compact = isShortScreen(context);
        return Scaffold(
          appBar: AppBar(
            title: Text(compact
                ? '${_titles[_step]} · ${_step + 1} of ${_titles.length}'
                : (widget.existing == null ? 'New course' : 'Course setup')),
            // On a short screen the buttons move up here, so the form keeps
            // the room the bottom bar would have taken.
            actions: compact
                ? [
                    if (_step > 0)
                      TextButton(onPressed: _saving ? null : () => setState(() => _step--), child: const Text('Back')),
                    Padding(
                      padding: const EdgeInsets.only(right: 8, left: 4),
                      child: FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
                        onPressed: _saving ? null : (_isLast ? _save : () => setState(() => _step++)),
                        child: Text(_isLast ? (widget.existing == null ? 'Create' : 'Save') : 'Next'),
                      ),
                    ),
                  ]
                : null,
          ),
          body: ListenableBuilder(
            listenable: _draft,
            builder: (context, _) => Column(
              children: [
                _RunningTotal(scheme: _draft.scheme),
                if (!compact)
                  _StepBar(
                    titles: _titles,
                    current: _step,
                    onTap: (i) => setState(() => _step = i),
                  ),
                Expanded(
                  child: ContentWidth(
                    child: switch (_step) {
                      0 => BasicsStep(draft: _draft),
                      1 => PartsStep(draft: _draft),
                      2 => ExamStep(draft: _draft),
                      _ => GradesStep(
                          draft: _draft,
                          saveAsTemplate: _saveAsTemplate,
                          templateName: _templateName,
                          onSaveAsTemplate: (v) => setState(() => _saveAsTemplate = v),
                          onTemplateName: (_) {},
                        ),
                    },
                  ),
                ),
                if (!compact)
                  _BottomBar(
                    step: _step,
                    isLast: _isLast,
                    saving: _saving,
                    onBack: () => setState(() => _step--),
                    onNext: () => setState(() => _step++),
                    onSave: _save,
                    isNew: widget.existing == null,
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// "Exam 70 + Test 10 + Assignment 10 + Attendance 10 = 100", with a warning
/// underneath when the parts do not add up to what the examiner expects.
///
/// Two lines at most until tapped, so a large text size or a small phone
/// leaves room for the form below.
class _RunningTotal extends StatefulWidget {
  const _RunningTotal({required this.scheme});

  final GradingScheme scheme;

  @override
  State<_RunningTotal> createState() => _RunningTotalState();
}

class _RunningTotalState extends State<_RunningTotal> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final adds = (scheme.partsTotal - scheme.totalExpected).abs() < 1e-9;
    final warnings = scheme.warnings().where((w) => w.kind == SchemeWarningKind.partsDoNotAddUp);
    final short = isShortScreen(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, short ? 4 : 8),
      child: Material(
        color: adds ? c.successContainer : c.warningContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: EdgeInsets.fromLTRB(14, short ? 8 : 12, 8, short ? 8 : 12),
            child: Semantics(
              liveRegion: true,
              label: 'Running total. ${schemeSummary(scheme)}. Tap to ${_expanded ? 'shorten' : 'show all'}.',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(adds ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                          color: adds ? c.success : c.warning, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          schemeSummary(scheme),
                          maxLines: _expanded ? null : 2,
                          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                          style: text.titleMedium?.copyWith(height: 1.3),
                        ),
                      ),
                      Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 22),
                    ],
                  ),
                  for (final w in warnings)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 32, right: 24),
                      child: Text(w.message,
                          maxLines: _expanded ? null : 2,
                          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                          style: text.bodyMedium),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.titles, required this.current, required this.onTap});

  final List<String> titles;
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          for (var i = 0; i < titles.length; i++) ...[
            Expanded(
              child: Semantics(
                button: true,
                selected: i == current,
                label: 'Step ${i + 1} of ${titles.length}: ${titles[i]}',
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onTap(i),
                  child: SizedBox(
                    height: 48,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: i <= current ? scheme.primary : scheme.outlineVariant,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${i + 1}. ${titles[i]}',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontSize: 13.5,
                                  color: i == current ? scheme.onSurface : scheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (i < titles.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.step,
    required this.isLast,
    required this.saving,
    required this.onBack,
    required this.onNext,
    required this.onSave,
    required this.isNew,
  });

  final int step;
  final bool isLast;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSave;
  final bool isNew;

  @override
  Widget build(BuildContext context) => BottomActionBar(
        child: Row(
          children: [
            if (step > 0) ...[
              Expanded(
                child: OutlinedButton(onPressed: saving ? null : onBack, child: const Text('Back')),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: saving ? null : (isLast ? onSave : onNext),
                child: saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Text(isLast ? (isNew ? 'Create course' : 'Save changes') : 'Next'),
              ),
            ),
          ],
        ),
      );
}
