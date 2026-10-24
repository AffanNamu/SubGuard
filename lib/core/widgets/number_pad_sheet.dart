import 'package:flutter/material.dart';

import '../../domain/scheme.dart';
import '../../domain/scoring.dart';
import 'common.dart';
import 'score_keypad.dart';

class NumberPadResult {
  const NumberPadResult(this.value);

  /// The mark typed, or null if the examiner cleared it.
  final double? value;
}

/// A bottom sheet with the mark number pad (with its .5 key) for one value.
/// Returns null if dismissed, a result with a null value if cleared.
Future<NumberPadResult?> showNumberPad(
  BuildContext context, {
  required String title,
  String? hint,
  double? initial,
  double? max,
  double step = 0.5,
}) {
  return showModalBottomSheet<NumberPadResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _NumberPad(title: title, hint: hint, initial: initial, max: max, step: step),
  );
}

class _NumberPad extends StatefulWidget {
  const _NumberPad({required this.title, this.hint, this.initial, this.max, required this.step});

  final String title;
  final String? hint;
  final double? initial;
  final double? max;
  final double step;

  @override
  State<_NumberPad> createState() => _NumberPadState();
}

class _NumberPadState extends State<_NumberPad> {
  late String _text = widget.initial == null ? '' : formatNumber(widget.initial!);
  bool _fresh = true;

  void _key(String k) => setState(() {
        if (_fresh) {
          _text = '';
          _fresh = false;
        }
        if (_text.length >= 7) return;
        if (k == '.' || k == '.5') {
          if (_text.contains('.')) return;
          _text = _text.isEmpty ? '0$k' : '$_text$k';
        } else {
          _text = _text == '0' ? k : '$_text$k';
        }
      });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final parsed = MarkParser.parse(_text);
    final bad = _text.isNotEmpty && parsed == null;
    final over = parsed != null && widget.max != null && parsed > widget.max! + 1e-9;
    final off = parsed != null && !ScoreCalculator.isOnStep(parsed, widget.step);
    final fractional = widget.step < 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ContentWidth(
        maxWidth: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: text.titleLarge, textAlign: TextAlign.center),
            if (widget.hint != null)
              Text(widget.hint!, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: bad || over ? scheme.error : scheme.primary, width: 2),
              ),
              child: Semantics(
                liveRegion: true,
                label: _text.isEmpty ? 'Nothing entered' : 'Entered $_text',
                child: Text(_text.isEmpty ? '—' : _text,
                    textAlign: TextAlign.center,
                    style: text.displaySmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: bad
                  ? const InfoBanner(message: 'That is not a number.', kind: BannerKind.danger)
                  : over
                      ? InfoBanner(message: '$_text is above the maximum of ${formatNumber(widget.max!)}.', kind: BannerKind.danger)
                      : off
                          ? InfoBanner(
                              message: '$_text is not a multiple of ${formatNumber(widget.step)}.', kind: BannerKind.warning)
                          : const SizedBox.shrink(),
            ),
            ScoreKeypad(
              onKey: _key,
              onBackspace: () => setState(() {
                _fresh = false;
                if (_text.isNotEmpty) _text = _text.substring(0, _text.length - 1);
              }),
              showHalfKey: fractional,
              showDecimalKey: fractional,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, const NumberPadResult(null)),
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: bad
                        ? null
                        : () => Navigator.pop(context, NumberPadResult(_text.isEmpty ? null : parsed)),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
