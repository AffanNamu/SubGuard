/// A rectangle on a photo as fractions of its width and height, so it does not
/// depend on the resolution the photo was read at.
class Region {
  const Region(this.left, this.top, this.right, this.bottom);

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;
  double get centerX => (left + right) / 2;
  double get centerY => (top + bottom) / 2;

  Region clamped() => Region(
        left.clamp(0.0, 1.0),
        top.clamp(0.0, 1.0),
        right.clamp(0.0, 1.0),
        bottom.clamp(0.0, 1.0),
      );

  Region inflate({double x = 0, double y = 0}) => Region(left - x, top - y, right + x, bottom + y);

  /// "left,top,right,bottom", the form stored in the database.
  String encode() => [left, top, right, bottom].map((v) => v.toStringAsFixed(4)).join(',');

  static Region? decode(String? s) {
    if (s == null) return null;
    final p = s.split(',').map(double.tryParse).toList();
    if (p.length != 4 || p.any((v) => v == null)) return null;
    return Region(p[0]!, p[1]!, p[2]!, p[3]!);
  }

  Map<String, double> toJson() => {'left': left, 'top': top, 'right': right, 'bottom': bottom};

  @override
  String toString() => 'Region(${encode()})';
}

/// One line of text an engine found, with where it was and how sure it was.
class OcrLine {
  const OcrLine(this.text, this.box, {this.confidence});

  final String text;
  final Region box;

  /// 0 to 1 when the engine reports one; null when it does not.
  final double? confidence;
}

class OcrDocument {
  const OcrDocument({required this.engine, required this.lines, this.note});

  /// Which engine produced this, kept with the result so a reading can always
  /// be traced to what made it.
  final String engine;
  final List<OcrLine> lines;

  /// Set when the engine could not do its job, in words for the examiner.
  final String? note;

  static const OcrDocument empty = OcrDocument(engine: 'none', lines: []);

  Map<String, Object?> toJson() => {
        'engine': engine,
        if (note != null) 'note': note,
        'lines': [
          for (final l in lines)
            {'text': l.text, 'box': l.box.toJson(), if (l.confidence != null) 'confidence': l.confidence},
        ],
      };
}
