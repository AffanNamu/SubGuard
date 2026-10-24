import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/number_field.dart';
import '../../domain/models.dart';
import '../../domain/scheme.dart';
import '../../providers/providers.dart';
import 'course_draft.dart';
import 'part_editor_sheet.dart';

// ---------------------------------------------------------------------------
// Step 1: the course itself, and where to start from.
// ---------------------------------------------------------------------------

class BasicsStep extends ConsumerStatefulWidget {
  const BasicsStep({super.key, required this.draft});

  final CourseDraftController draft;

  @override
  ConsumerState<BasicsStep> createState() => _BasicsStepState();
}

class _BasicsStepState extends ConsumerState<BasicsStep> {
  late final _code = TextEditingController(text: widget.draft.code);
  late final _dept = TextEditingController(text: widget.draft.department);
  late final _session = TextEditingController(text: widget.draft.session);
  late final _semester = TextEditingController(text: widget.draft.semester);

  @override
  void dispose() {
    _code.dispose();
    _dept.dispose();
    _session.dispose();
    _semester.dispose();
    super.dispose();
  }

  Future<void> _pickTemplate(SchemeTemplate t) async {
    final draft = widget.draft;
    if (draft.differsFrom(t.scheme)) {
      final ok = await confirm(
        context,
        title: 'Start from "${t.name}"?',
        message: 'This replaces the marks, exam paper and grades you have set up so far.',
        confirmLabel: 'Replace',
      );
      if (!ok) return;
    }
    draft.applyTemplate(t);
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final templates = ref.watch(allTemplatesProvider);
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        TextField(
          controller: _code,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.next,
          onChanged: (v) => draft.setBasics(code: v),
          decoration: const InputDecoration(
            labelText: 'Course code',
            hintText: 'AGR 114',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _dept,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.next,
          onChanged: (v) => draft.setBasics(department: v),
          decoration: const InputDecoration(
            labelText: 'Department',
            hintText: 'FWM',
            helperText: 'Printed in the heading as (FWM) AGR 114.',
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _session,
                textInputAction: TextInputAction.next,
                onChanged: (v) => draft.setBasics(session: v),
                decoration: const InputDecoration(labelText: 'Session', hintText: '2024/2025'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _semester,
                textInputAction: TextInputAction.done,
                onChanged: (v) => draft.setBasics(semester: v),
                decoration: const InputDecoration(labelText: 'Semester', hintText: 'First'),
              ),
            ),
          ],
        ),
        if (draft.isNew) ...[
          const SectionHeading('Start from'),
          Text('Pick a saved set of marks and grades. You can change every number after.',
              style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 10),
          for (final t in templates)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  minTileHeight: 64,
                  onTap: () => _pickTemplate(t),
                  leading: Icon(
                    t.isBuiltIn ? Icons.verified_rounded : Icons.bookmark_rounded,
                    color: draft.templateName == t.name
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  title: Text(t.name),
                  subtitle: Text(schemeSummary(t.scheme)),
                  trailing: draft.templateName == t.name
                      ? Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary)
                      : null,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2: the parts that make up the total.
// ---------------------------------------------------------------------------

class PartsStep extends StatelessWidget {
  const PartsStep({super.key, required this.draft});

  final CourseDraftController draft;

  static const _suggestions = ['Practical', 'Quiz 2', 'Project', 'Presentation'];

  Future<void> _edit(BuildContext context, PartSpec part) async {
    final edited = await showPartEditor(
      context,
      part,
      canRemove: draft.scheme.parts.length > 1,
      onRemove: () => draft.removePart(part.id),
    );
    if (edited != null) draft.updatePart(edited);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = draft.scheme;
    final text = Theme.of(context).textTheme;
    final unused = _suggestions
        .where((s) => !scheme.parts.any((p) => p.name.toLowerCase() == s.toLowerCase()))
        .toList();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Text(
              'These are the parts of the total. Rename, add, remove or reorder them. Tap a part to change its limits.',
              style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverReorderableList(
            itemCount: scheme.parts.length,
            onReorderItem: draft.movePart,
            proxyDecorator: (child, i, a) => Material(color: Colors.transparent, child: child),
            itemBuilder: (context, i) {
              final p = scheme.parts[i];
              return Padding(
                key: ValueKey(p.id),
                padding: const EdgeInsets.only(bottom: 8),
                child: _PartCard(
                  part: p,
                  index: i,
                  onTap: () => _edit(context, p),
                ),
              );
            },
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          sliver: SliverList.list(children: [
            OutlinedButton.icon(
              onPressed: () async {
                final part = draft.addPart('New part');
                await _edit(context, part);
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add a part'),
            ),
            if (unused.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in unused)
                    ActionChip(
                      label: Text('+ $s'),
                      onPressed: () async {
                        final part = draft.addPart(s);
                        await _edit(context, part);
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            NumberField(
              label: 'The parts should add up to',
              value: scheme.totalExpected,
              onChanged: (v) {
                if (v != null) draft.setTotalExpected(v);
              },
              helper: 'You get a warning if they do not. Nothing is ever blocked.',
            ),
          ]),
        ),
      ],
    );
  }
}

class _PartCard extends StatelessWidget {
  const _PartCard({required this.part, required this.index, required this.onTap});

  final PartSpec part;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final details = <String>[
      'Out of ${formatNumber(part.max)}',
      'step ${formatNumber(part.step)}',
      if (part.passMark != null) 'pass ${formatNumber(part.passMark!)}',
      if (part.markedOutOf != null || part.countsFor != null)
        'counts for ${formatNumber(part.effectiveCountsFor)}',
      part.source.label.toLowerCase(),
    ];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(part.name.isEmpty ? 'Unnamed part' : part.name, style: text.titleMedium),
                    const SizedBox(height: 2),
                    Text(details.join(' · '),
                        style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Semantics(
                label: 'Drag to reorder ${part.name}',
                child: ReorderableDragStartListener(
                  index: index,
                  child: const SizedBox(
                    width: 52,
                    height: 52,
                    child: Icon(Icons.drag_indicator_rounded),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3: the exam paper.
// ---------------------------------------------------------------------------

class ExamStep extends StatelessWidget {
  const ExamStep({super.key, required this.draft});

  final CourseDraftController draft;

  @override
  Widget build(BuildContext context) {
    final scheme = draft.scheme;
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    final count = scheme.questions.length;
    final exam = scheme.examPart;
    final warnings = scheme
        .warnings()
        .where((w) => w.kind == SchemeWarningKind.questionsCannotReachExamMax)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text(
          exam == null
              ? 'No part is filled from scanned booklets, so you can skip this step.'
              : 'Set up the questions on the ${exam.name} paper. You can skip this and type ${exam.name} totals instead.',
          style: muted,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Number of questions', style: text.titleMedium),
                      Text(count == 0 ? 'None set' : '$count on the paper', style: muted),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Fewer questions',
                  onPressed: count == 0 ? null : () => draft.setQuestionCount(count - 1),
                  icon: const Icon(Icons.remove_rounded),
                  iconSize: 28,
                  constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
                ),
                SizedBox(
                  width: 44,
                  child: Text('$count',
                      textAlign: TextAlign.center, style: text.headlineSmall),
                ),
                IconButton.filledTonal(
                  tooltip: 'More questions',
                  onPressed: count >= 30 ? null : () => draft.setQuestionCount(count + 1),
                  icon: const Icon(Icons.add_rounded),
                  iconSize: 28,
                  constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
                ),
              ],
            ),
          ),
        ),
        if (count > 0) ...[
          const SizedBox(height: 12),
          // Feedback sits next to the controls that change it.
          if (warnings.isNotEmpty)
            for (final w in warnings)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InfoBanner(message: w.message, kind: BannerKind.warning),
              )
          else if (scheme.reachableExamScore != null)
            InfoBanner(
              message: 'The questions can reach ${formatNumber(scheme.reachableExamScore!)}.',
              kind: BannerKind.success,
            ),
          const SectionHeading('Marks for each question'),
          NumberField(
            label: 'Same maximum for every question',
            value: scheme.questions.map((q) => q.max).toSet().length == 1 ? scheme.questions.first.max : null,
            allowEmpty: true,
            onChanged: (v) {
              if (v != null) draft.setAllQuestionMax(v);
            },
            helper: 'Or set each one below.',
          ),
          const SizedBox(height: 12),
          for (final q in scheme.questions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text('Q${q.qNo}', style: text.titleMedium),
                      ),
                      SizedBox(
                        width: 96,
                        child: NumberField(
                          key: ValueKey('${q.id}-max'),
                          label: 'Max',
                          value: q.max,
                          onChanged: (v) {
                            if (v != null) draft.updateQuestion(q.copyWith(max: v));
                          },
                        ),
                      ),
                      const Spacer(),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: q.compulsory,
                            onChanged: (v) => draft.updateQuestion(q.copyWith(compulsory: v)),
                          ),
                          Text('Compulsory', style: text.bodySmall),
                        ],
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ),
          const SectionHeading('Which answers count'),
          RadioGroup<CountRule>(
            groupValue: scheme.countRule,
            onChanged: (v) => draft.setCountRule(v!),
            child: Column(
              children: [
                for (final rule in CountRule.values)
                  RadioListTile<CountRule>(
                    contentPadding: EdgeInsets.zero,
                    value: rule,
                    title: Text(rule.label),
                  ),
              ],
            ),
          ),
          if (scheme.countRule != CountRule.all) ...[
            const SizedBox(height: 8),
            NumberField(
              key: ValueKey('countN-${scheme.countRule.name}'),
              label: scheme.countRule == CountRule.bestN
                  ? 'How many of the best answers count'
                  : 'How many of the other answers count',
              value: scheme.countN?.toDouble(),
              integer: true,
              min: 1,
              onChanged: (v) {
                if (v != null) draft.setCountN(v.round());
              },
            ),
          ],
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 4: the grade scale, and saving as a template.
// ---------------------------------------------------------------------------

class GradesStep extends StatelessWidget {
  const GradesStep({
    super.key,
    required this.draft,
    required this.saveAsTemplate,
    required this.templateName,
    required this.onSaveAsTemplate,
    required this.onTemplateName,
  });

  final CourseDraftController draft;
  final bool saveAsTemplate;
  final TextEditingController templateName;
  final ValueChanged<bool> onSaveAsTemplate;
  final ValueChanged<String> onTemplateName;

  @override
  Widget build(BuildContext context) {
    final scheme = draft.scheme;
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    final bands = [...scheme.bands]..sort((a, b) => b.minScore.compareTo(a.minScore));
    final overlaps = scheme.warnings().where((w) => w.kind == SchemeWarningKind.gradeScaleOverlap);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text('Used for the optional Grade column in exports. Each row is a score range, a letter and its points.',
            style: muted),
        const SizedBox(height: 12),
        if (bands.isEmpty)
          const InfoBanner(
            message: 'No grades set. The Grade column will stay empty.',
            kind: BannerKind.info,
          ),
        for (final b in bands)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _BandCard(
              key: ValueKey(b.id),
              band: b,
              onChanged: draft.updateBand,
              onRemove: () => draft.removeBand(b.id),
            ),
          ),
        for (final w in overlaps)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InfoBanner(message: w.message, kind: BannerKind.warning),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: draft.addBand,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add a grade'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final ok = await confirm(
                    context,
                    title: 'Use the Nigerian scale?',
                    message: 'A 70–100, B 60–69, C 50–59, D 45–49, E 40–44, F 0–39. This replaces the grades above.',
                    confirmLabel: 'Replace',
                  );
                  if (ok) draft.resetBands();
                },
                child: const Text('Nigerian scale'),
              ),
            ),
          ],
        ),
        const SectionHeading('Templates'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Save as a template'),
                  subtitle: const Text('Start the next course or semester from these settings in two taps.'),
                  value: saveAsTemplate,
                  onChanged: onSaveAsTemplate,
                ),
                if (saveAsTemplate)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      controller: templateName,
                      onChanged: onTemplateName,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(labelText: 'Template name', hintText: 'My 60 + 40 scheme'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BandCard extends StatelessWidget {
  const _BandCard({super.key, required this.band, required this.onChanged, required this.onRemove});

  final GradeBand band;
  final ValueChanged<GradeBand> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Two short rows rather than one crowded one, so every field stays wide
    // enough to read on a small phone.
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: band.letter,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 3,
                    textInputAction: TextInputAction.next,
                    onChanged: (v) => onChanged(band.copyWith(letter: v)),
                    decoration: const InputDecoration(labelText: 'Grade', counterText: ''),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NumberField(
                    label: 'Points',
                    value: band.points,
                    onChanged: (v) {
                      if (v != null) onChanged(band.copyWith(points: v));
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Remove grade ${band.letter}',
                  onPressed: onRemove,
                  icon: Icon(Icons.close_rounded, color: c.danger),
                  constraints: const BoxConstraints(minWidth: 52, minHeight: 56),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: NumberField(
                      label: 'From score',
                      value: band.minScore,
                      onChanged: (v) {
                        if (v != null) onChanged(band.copyWith(minScore: v));
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NumberField(
                      label: 'To score',
                      value: band.maxScore,
                      textInputAction: TextInputAction.done,
                      onChanged: (v) {
                        if (v != null) onChanged(band.copyWith(maxScore: v));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
