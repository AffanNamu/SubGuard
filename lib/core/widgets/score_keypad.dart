import 'package:flutter/material.dart';

/// A number pad for marks: large keys for one-handed use, a decimal point and
/// a ".5" key for half marks.
class ScoreKeypad extends StatelessWidget {
  const ScoreKeypad({
    super.key,
    required this.onKey,
    required this.onBackspace,
    this.showHalfKey = true,
    this.showDecimalKey = true,
  });

  /// Called with "0".."9", "." or ".5".
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final bool showHalfKey;
  final bool showDecimalKey;

  @override
  Widget build(BuildContext context) {
    Widget key(String label, VoidCallback? onTap, {String? semantics, bool accent = false}) {
      final scheme = Theme.of(context).colorScheme;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Semantics(
            button: true,
            label: semantics ?? label,
            excludeSemantics: true,
            child: Material(
              color: accent ? scheme.secondaryContainer : scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: SizedBox(
                  height: 58,
                  child: Center(
                    child: Text(
                      label,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: onTap == null ? scheme.outline : scheme.onSurface),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget digitRow(List<String> digits) =>
        Row(children: [for (final d in digits) key(d, () => onKey(d))]);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        digitRow(['7', '8', '9']),
        digitRow(['4', '5', '6']),
        digitRow(['1', '2', '3']),
        Row(children: [
          key(showDecimalKey ? '.' : '', showDecimalKey ? () => onKey('.') : null,
              semantics: 'Decimal point'),
          key('0', () => onKey('0')),
          key('⌫', onBackspace, semantics: 'Delete'),
        ]),
        if (showHalfKey)
          Row(children: [
            key('.5', () => onKey('.5'), semantics: 'Half mark', accent: true),
          ]),
      ],
    );
  }
}
