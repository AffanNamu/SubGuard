import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';
import '../../domain/mark_sheet.dart';
import '../../domain/ocr.dart';
import '../../domain/recognition.dart';
import '../../domain/row_suggestions.dart';
import '../../domain/scan.dart';
import '../../domain/scheme.dart' show formatNumber;
import 'scan_widgets.dart';

/// One question-mark record: the question number and the mark are two separate fields,
/// each showing what the examiner has *confirmed*; what the machine suggested sits below
/// each in its own band, marked as not confirmed, and only becomes the value when the
/// examiner taps it.
class MarkRecordCard extends StatelessWidget {
  const MarkRecordCard({
    super.key,
    required this.record,
    required this.label,
    required this.scan,
    required this.problems,
    required this.locked,
    this.maxMark,
    this.onEnterQuestion,
    this.onEnterMark,
    this.onUseQuestion,
    this.onUseMark,
    this.onUseBoth,
    this.onShow,
    this.onDismiss,
    this.onRestore,
    this.onRemove,
  });

  final MarkRecord record;

  /// "Row 2", or "Added question".
  final String label;
  final ScanItem scan;

  /// What is still to be decided or worth a second look about this record.
  final List<RecordProblem> problems;

  /// The booklet is confirmed: values only, nothing to decide.
  final bool locked;

  /// The question's maximum, when the course has one.
  final double? maxMark;

  final VoidCallback? onEnterQuestion;
  final VoidCallback? onEnterMark;
  final void Function(int qNo)? onUseQuestion;
  final void Function(double mark)? onUseMark;
  final VoidCallback? onUseBoth;
  final VoidCallback? onShow;
  final VoidCallback? onDismiss;
  final VoidCallback? onRestore;
  final VoidCallback? onRemove;

  Region? get _cropRegion {
    final s = record.suggestions;
    final a = s?.questionRegion, b = s?.markRegion;
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return Region(
      a.left < b.left ? a.left : b.left,
      a.top < b.top ? a.top : b.top,
      a.right > b.right ? a.right : b.right,
      a.bottom > b.bottom ? a.bottom : b.bottom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final sug = record.suggestions;

    if (record.dismissed) {
      return Container(
        key: ValueKey('record-${record.key}'),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$label: not a mark. Left out of the total.',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            if (!locked && onRestore != null)
              TextButton(onPressed: onRestore, child: const Text('Put back')),
          ],
        ),
      );
    }

    final crop = _cropRegion;
    final w = scan.width, h = scan.height;
    final needs = !record.complete;
    final qSuggested =
        !record.hasQuestion && (sug?.questionAlternatives.isNotEmpty ?? false);
    final mSuggested =
        !record.hasMark && (sug?.markAlternatives.isNotEmpty ?? false);
    final canUseBoth =
        !locked &&
        onUseBoth != null &&
        (qSuggested || mSuggested) &&
        (record.hasQuestion || qSuggested) &&
        (record.hasMark || mSuggested);

    // A Material, not a coloured box, so the evidence tile's ink shows.
    return Padding(
      key: ValueKey('record-${record.key}'),
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: needs && !locked
                ? context.colors.warning
                : scheme.outlineVariant,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(label, style: text.titleSmall)),
                  if (locked || record.complete)
                    const StatusChip(
                      kind: ChipKind.completed,
                      label: 'Confirmed by you',
                    )
                  else
                    const StatusChip(
                      kind: ChipKind.needsReview,
                      label: 'Needs checking',
                    ),
                ],
              ),
              if (crop != null &&
                  w != null &&
                  h != null &&
                  crop.width > 0.02 &&
                  crop.height > 0.005) ...[
                const SizedBox(height: 8),
                RegionView(
                  relativePath: scan.relativePath,
                  region: crop,
                  photoWidth: w,
                  photoHeight: h,
                  maxHeight: 64,
                  onTap: onShow,
                ),
              ],
              const SizedBox(height: 8),

              // ---- question number ----
              _Field(
                fieldKey: ValueKey('q-${record.key}'),
                label: 'Question number',
                value: record.qNo == null ? null : 'Q${record.qNo}',
                hint: locked ? '—' : 'Tap to enter',
                onTap: locked ? null : onEnterQuestion,
              ),
              if (!locked && !record.hasQuestion)
                _Suggestions(
                  title: 'Suggested question number (not confirmed)',
                  none: sug == null
                      ? null
                      : 'Unable to read this question number confidently. Please check the photograph and enter it.',
                  chips: [
                    for (final c
                        in sug?.questionAlternatives ??
                            const <FieldCandidate>[])
                      (
                        key: ValueKey('sq-${record.key}-${c.text}'),
                        label: 'Q${c.text}',
                        semantics: 'Use question ${c.text}',
                        onTap: () => onUseQuestion?.call(int.parse(c.text)),
                      ),
                  ],
                ),
              const SizedBox(height: 8),

              // ---- mark ----
              _Field(
                fieldKey: ValueKey('m-${record.key}'),
                label: 'Mark',
                value: record.mark == null ? null : formatNumber(record.mark!),
                hint: locked ? '—' : 'Tap to enter',
                suffix: maxMark == null ? null : '/ ${formatNumber(maxMark!)}',
                onTap: locked ? null : onEnterMark,
              ),
              if (!locked && !record.hasMark)
                _Suggestions(
                  title: 'Suggested mark (not confirmed)',
                  none: sug == null
                      ? null
                      : 'Unable to read this mark confidently. Please check the photograph and enter the correct mark.',
                  chips: [
                    for (final c
                        in sug?.markAlternatives ?? const <FieldCandidate>[])
                      (
                        key: ValueKey('sm-${record.key}-${c.text}'),
                        label: formatNumber(double.parse(c.text)),
                        semantics: 'Use mark ${c.text}',
                        onTap: () => onUseMark?.call(double.parse(c.text)),
                      ),
                  ],
                ),

              for (final p in problems.where((p) => !p.blocks))
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    p.message,
                    style: text.bodySmall?.copyWith(
                      color: context.colors.warning,
                    ),
                  ),
                ),
              for (final p in problems.where(
                (p) => p.blocks && p.issue == RecordIssue.duplicateQuestion,
              ))
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    p.message,
                    style: text.bodySmall?.copyWith(
                      color: context.colors.danger,
                    ),
                  ),
                ),
              if (sug != null) _Evidence(sug: sug),
              Wrap(
                children: [
                  if (canUseBoth)
                    TextButton(
                      key: ValueKey('both-${record.key}'),
                      onPressed: onUseBoth,
                      child: const Text('Use these suggestions'),
                    ),
                  if (onShow != null)
                    TextButton(
                      onPressed: onShow,
                      child: const Text('Show on photo'),
                    ),
                  if (!locked && sug != null && onDismiss != null)
                    TextButton(
                      key: ValueKey('dismiss-${record.key}'),
                      onPressed: onDismiss,
                      child: const Text('Not a mark'),
                    ),
                  if (!locked && record.manual && onRemove != null)
                    TextButton(
                      onPressed: onRemove,
                      child: const Text('Remove'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A confirmed value, or an empty field waiting for the examiner.
class _Field extends StatelessWidget {
  const _Field({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.hint,
    this.suffix,
    this.onTap,
  });

  final Key fieldKey;
  final String label;
  final String? value;
  final String hint;
  final String? suffix;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: onTap != null,
      label: '$label, ${value ?? 'not confirmed'}',
      excludeSemantics: true,
      child: Material(
        key: fieldKey,
        color: value == null
            ? scheme.surface
            : scheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          value ?? hint,
                          style: value == null
                              ? text.bodyLarge?.copyWith(color: scheme.outline)
                              : text.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  if (suffix != null)
                    Text(
                      suffix!,
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  if (value != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 20,
                        color: context.colors.success,
                      ),
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

typedef _Chip = ({Key key, String label, String semantics, VoidCallback onTap});

/// What the machine suggests for one field, apart from the field itself.
class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.title, required this.chips, this.none});

  final String title;
  final List<_Chip> chips;

  /// Said when there is nothing to suggest.
  final String? none;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    if (chips.isEmpty) {
      if (none == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          none!,
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final c in chips)
                Semantics(
                  button: true,
                  label: c.semantics,
                  excludeSemantics: true,
                  child: ActionChip(
                    key: c.key,
                    label: Text(c.label),
                    onPressed: c.onTap,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// How the cells were read, including the readings that were left out and why.
class _Evidence extends StatelessWidget {
  const _Evidence({required this.sug});

  final RowSuggestions sug;

  @override
  Widget build(BuildContext context) {
    final s = sug;
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final lines = <String>[
      if (s.rawQuestion != null) 'Question cell read as "${s.rawQuestion}".',
      if (s.rawMark != null) 'Marks cell read as "${s.rawMark}".',
      for (final o in s.questionLeftOut)
        'Not offered as a question number: "${o.text}" (${o.reason}).',
      for (final o in s.markLeftOut)
        'Not offered as a mark: "${o.text}" (${o.reason}).',
      ...s.warnings,
    ];
    if (lines.isEmpty) return const SizedBox.shrink();
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        dense: true,
        title: Text(
          'How this was read',
          style: text.bodyMedium?.copyWith(color: muted),
        ),
        children: [
          for (final l in lines)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(l, style: text.bodySmall?.copyWith(color: muted)),
              ),
            ),
        ],
      ),
    );
  }
}
