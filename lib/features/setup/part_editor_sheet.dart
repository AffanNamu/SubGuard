import 'package:flutter/material.dart';

import '../../core/widgets/common.dart';
import '../../core/widgets/number_field.dart';
import '../../domain/scheme.dart';

/// Edits one part of the grading scheme. Opens as a full-width sheet so every
/// field is large and has room for its help text.
Future<PartSpec?> showPartEditor(
  BuildContext context,
  PartSpec part, {
  required bool canRemove,
  required VoidCallback onRemove,
}) {
  return showModalBottomSheet<PartSpec>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _PartEditor(part: part, canRemove: canRemove, onRemove: onRemove),
  );
}

class _PartEditor extends StatefulWidget {
  const _PartEditor({required this.part, required this.canRemove, required this.onRemove});

  final PartSpec part;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  State<_PartEditor> createState() => _PartEditorState();
}

class _PartEditorState extends State<_PartEditor> {
  late PartSpec _p = widget.part;
  late final TextEditingController _name = TextEditingController(text: widget.part.name);
  late bool _hasPass = widget.part.passMark != null;
  late bool _scaled = widget.part.markedOutOf != null || widget.part.countsFor != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _set(PartSpec p) => setState(() => _p = p);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    final nameBlank = _name.text.trim().isEmpty;
    final limitsBad = _p.min > _p.max;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Edit part', style: text.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                onChanged: (v) {
                  _p = _p.copyWith(name: v);
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelText: 'Name',
                  helperText: 'For example Exam, Test, Practical',
                  errorText: nameBlank ? 'Give the part a name' : null,
                ),
              ),
              const SizedBox(height: 16),
              NumberField(
                label: 'Highest mark allowed',
                value: _p.max,
                onChanged: (v) => _set(_p.copyWith(max: v)),
                helper: 'Marks above this are flagged.',
              ),
              const SizedBox(height: 16),
              NumberField(
                label: 'Lowest mark allowed',
                value: _p.min,
                onChanged: (v) => _set(_p.copyWith(min: v)),
                helper: 'Marks below this are flagged. Usually 0.',
              ),
              if (limitsBad) ...[
                const SizedBox(height: 8),
                const InfoBanner(
                  message: 'The lowest mark is above the highest mark. Nothing is blocked, but every mark will be flagged.',
                  kind: BannerKind.warning,
                ),
              ],
              const SizedBox(height: 16),
              Text('Smallest step', style: text.titleMedium),
              const SizedBox(height: 4),
              Text('Marks that are not a multiple of this are flagged.',
                  style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              SegmentedButton<double>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 1, label: Text('1')),
                  ButtonSegment(value: 0.5, label: Text('0.5')),
                  ButtonSegment(value: 0.25, label: Text('0.25')),
                ],
                selected: {
                  if ([1.0, 0.5, 0.25].contains(_p.step)) _p.step,
                },
                emptySelectionAllowed: true,
                onSelectionChanged: (s) {
                  if (s.isNotEmpty) _set(_p.copyWith(step: s.first));
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pass mark'),
                subtitle: const Text('Scores under it are highlighted, never blocked.'),
                value: _hasPass,
                onChanged: (on) {
                  setState(() => _hasPass = on);
                  _set(on
                      ? _p.copyWith(passMark: _p.passMark ?? (_p.max / 2))
                      : _p.copyWith(clearPassMark: true));
                },
              ),
              if (_hasPass)
                NumberField(
                  label: 'Pass mark',
                  value: _p.passMark,
                  onChanged: (v) => _set(_p.copyWith(passMark: v)),
                ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Scale this part'),
                subtitle: const Text('For example a test marked out of 20 that counts for 10.'),
                value: _scaled,
                onChanged: (on) {
                  setState(() => _scaled = on);
                  _set(on
                      ? _p.copyWith(markedOutOf: _p.max, countsFor: _p.max)
                      : _p.copyWith(clearMarkedOutOf: true, clearCountsFor: true));
                },
              ),
              if (_scaled) ...[
                NumberField(
                  label: 'Marked out of',
                  value: _p.markedOutOf,
                  onChanged: (v) => _set(_p.copyWith(markedOutOf: v)),
                ),
                const SizedBox(height: 16),
                NumberField(
                  label: 'Counts for',
                  value: _p.countsFor,
                  onChanged: (v) => _set(_p.copyWith(countsFor: v)),
                  helper: 'How much this part adds to the total.',
                ),
              ],
              const SizedBox(height: 16),
              Text('Where the marks come from', style: text.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<PartSource>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: PartSource.scanned, label: Text('Scanned')),
                  ButtonSegment(value: PartSource.typed, label: Text('Typed')),
                  ButtonSegment(value: PartSource.imported, label: Text('Imported')),
                ],
                selected: {_p.source},
                onSelectionChanged: (s) => _set(_p.copyWith(source: s.first)),
              ),
              const SizedBox(height: 6),
              Text(
                _p.source == PartSource.scanned
                    ? 'Treated as the exam: shown as the examiner wrote it, and blank on continuous assessment sheets.'
                    : 'Shown with the decimals its step needs.',
                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: nameBlank ? null : () => Navigator.pop(context, _p.copyWith(name: _name.text.trim())),
                child: const Text('Done'),
              ),
              if (widget.canRemove) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    widget.onRemove();
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                  label: Text('Remove this part', style: TextStyle(color: scheme.error)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
