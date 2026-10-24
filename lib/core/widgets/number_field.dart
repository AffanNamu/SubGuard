import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/scheme.dart';
import '../../domain/scoring.dart';

/// A numeric text field that keeps what the user is typing, checks it, and
/// reports a value only when it is a valid number.
class NumberField extends StatefulWidget {
  const NumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.helper,
    this.suffix,
    this.integer = false,
    this.allowEmpty = false,
    this.min,
    this.textInputAction = TextInputAction.next,
  });

  final String label;
  final double? value;

  /// Called with the parsed number, or null when the field is emptied and
  /// [allowEmpty] is true. Not called while the text is not a valid number.
  final ValueChanged<double?> onChanged;
  final String? helper;
  final String? suffix;
  final bool integer;
  final bool allowEmpty;
  final double? min;
  final TextInputAction textInputAction;

  @override
  State<NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<NumberField> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(NumberField old) {
    super.didUpdateWidget(old);
    // Follow outside changes (such as "same maximum for all"), but never
    // overwrite what the user is typing.
    final typed = MarkParser.parse(_controller.text);
    if (widget.value != old.value && widget.value != typed) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(double? v) => v == null ? '' : formatNumber(v);

  void _changed(String text) {
    if (text.trim().isEmpty) {
      setState(() => _error = widget.allowEmpty ? null : 'Enter a number');
      if (widget.allowEmpty) widget.onChanged(null);
      return;
    }
    final v = MarkParser.parse(text);
    if (v == null || (widget.integer && v != v.roundToDouble())) {
      setState(() => _error = widget.integer ? 'Use a whole number' : 'Use a number, like 10 or 7.5');
      return;
    }
    if (widget.min != null && v < widget.min!) {
      setState(() => _error = 'Must be at least ${formatNumber(widget.min!)}');
      return;
    }
    setState(() => _error = null);
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _controller,
        onChanged: _changed,
        keyboardType: TextInputType.numberWithOptions(decimal: !widget.integer),
        textInputAction: widget.textInputAction,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,·]'))],
        decoration: InputDecoration(
          labelText: widget.label,
          helperText: widget.helper,
          suffixText: widget.suffix,
          errorText: _error,
        ),
      );
}
