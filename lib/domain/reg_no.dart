/// Registration (exam) number handling.
///
/// Numbers follow `DEPT/YYU/NNNN`, with an optional extra middle part
/// (`FST/25U/244/5772`). Handwriting often turns the `U` into a `4`, so the
/// normaliser repairs the pattern instead of trusting each character.
class RegNoResult {
  const RegNoResult({
    required this.raw,
    required this.canonical,
    required this.isValid,
    this.corrections = const [],
  });

  final String raw;

  /// Best-effort clean form: upper case, `/` separators, repaired characters.
  /// Always safe to store and compare, even when [isValid] is false.
  final String canonical;

  /// True when [canonical] matches the DEPT/YYU/NNNN pattern.
  final bool isValid;

  /// Plain-words list of what was repaired, for the review screen.
  final List<String> corrections;

  bool get wasCorrected => corrections.isNotEmpty;
}

class RegNoSuggestion {
  const RegNoSuggestion(this.regNo, this.distance);
  final String regNo;
  final int distance;
}

class RegNo {
  const RegNo._();

  static final RegExp _pattern =
      RegExp(r'^([A-Z]{2,6})/(\d{2})U/(?:(\d{1,4})/)?(\d{4})$');

  static final RegExp _compact = RegExp(r'^([A-Z]{2,6})(\d{2})[U4VW](\d{4})$');

  /// Characters handwriting commonly swaps with digits.
  static const Map<String, String> _toDigit = {
    'O': '0',
    'Q': '0',
    'D': '0',
    'I': '1',
    'L': '1',
    'Z': '2',
    'S': '5',
    'G': '6',
    'B': '8',
  };

  /// Digits that handwriting commonly swaps with letters (department code).
  static const Map<String, String> _toLetter = {
    '0': 'O',
    '1': 'I',
    '5': 'S',
    '8': 'B',
    '2': 'Z',
  };

  static bool isValid(String value) => _pattern.hasMatch(value);

  static RegNoResult normalise(String raw) {
    final corrections = <String>[];
    final cleaned = _clean(raw);
    if (cleaned.isEmpty) {
      return RegNoResult(
          raw: raw, canonical: '', isValid: false, corrections: corrections);
    }

    var parts = cleaned.split('/').where((p) => p.isNotEmpty).toList();

    if (parts.length == 1) {
      final m = _compact.firstMatch(parts.first);
      if (m != null) {
        parts = [m.group(1)!, '${m.group(2)}U', m.group(3)!];
        corrections.add('Added the missing "/" separators');
      }
    }

    if (parts.length < 3 || parts.length > 4) {
      return RegNoResult(
        raw: raw,
        canonical: parts.join('/'),
        isValid: false,
        corrections: corrections,
      );
    }

    final dept = _fixDepartment(parts.first, corrections);
    final year = _fixYear(parts[1], corrections);
    final seq = _fixDigits(parts.last, corrections, pad: 4, label: 'number');
    String? middle;
    if (parts.length == 4) {
      middle = _fixDigits(parts[2], corrections, label: 'middle part');
    }

    final canonical =
        [dept, year, if (middle != null) middle, seq].join('/');
    return RegNoResult(
      raw: raw,
      canonical: canonical,
      isValid: isValid(canonical),
      corrections: corrections,
    );
  }

  /// Canonical form used as the lookup key for students.
  static String key(String raw) => normalise(raw).canonical;

  static String _clean(String raw) {
    var s = raw.trim().toUpperCase();
    // Any run of separators, including spaces and hyphens, becomes one "/".
    s = s.replaceAll(RegExp(r'[\s\\\-_.,;:|]+'), '/');
    s = s.replaceAll(RegExp(r'[^A-Z0-9/]'), '');
    s = s.replaceAll(RegExp(r'/{2,}'), '/');
    return s.replaceAll(RegExp(r'^/|/$'), '');
  }

  static String _fixDepartment(String part, List<String> corrections) {
    if (!RegExp(r'\d').hasMatch(part)) return part;
    final fixed = part.split('').map((c) => _toLetter[c] ?? c).join();
    if (RegExp(r'^[A-Z]+$').hasMatch(fixed)) {
      corrections.add('Read "$part" as department "$fixed"');
      return fixed;
    }
    return part;
  }

  /// `24U`, where the U is often written so it looks like a 4.
  static String _fixYear(String part, List<String> corrections) {
    if (RegExp(r'^\d{2}U$').hasMatch(part)) return part;

    // "24" with no U at all.
    if (RegExp(r'^\d{2}$').hasMatch(part)) {
      corrections.add('Added the missing "U" to "$part"');
      return '${part}U';
    }

    if (part.length == 3) {
      final digits = _toDigitsOrNull(part.substring(0, 2));
      final last = part[2];
      if (digits != null && 'U4VW'.contains(last)) {
        final fixed = '${digits}U';
        corrections.add('Read "$part" as "$fixed"');
        return fixed;
      }
    }
    return part;
  }

  static String _fixDigits(
    String part,
    List<String> corrections, {
    int? pad,
    required String label,
  }) {
    var digits = RegExp(r'^\d+$').hasMatch(part) ? part : _toDigitsOrNull(part);
    if (digits == null) return part;
    if (digits != part) {
      corrections.add('Read the $label "$part" as "$digits"');
    }
    if (pad != null && digits.length < pad) {
      final padded = digits.padLeft(pad, '0');
      corrections.add('Padded the $label "$digits" to "$padded"');
      digits = padded;
    }
    return digits;
  }

  static String? _toDigitsOrNull(String s) {
    final buf = StringBuffer();
    for (final c in s.split('')) {
      if (RegExp(r'\d').hasMatch(c)) {
        buf.write(c);
      } else if (_toDigit.containsKey(c)) {
        buf.write(_toDigit[c]);
      } else {
        return null;
      }
    }
    return buf.toString();
  }

  /// Levenshtein distance, used to snap a read number to the class list.
  static int distance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    var prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        cur[j] = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost]
            .reduce((x, y) => x < y ? x : y);
      }
      prev = cur;
    }
    return prev[b.length];
  }

  /// Class-list numbers closest to [canonical], nearest first.
  static List<RegNoSuggestion> nearest(
    String canonical,
    Iterable<String> classList, {
    int maxDistance = 2,
    int limit = 3,
  }) {
    final out = <RegNoSuggestion>[];
    for (final candidate in classList) {
      final d = distance(canonical, candidate);
      if (d <= maxDistance) out.add(RegNoSuggestion(candidate, d));
    }
    out.sort((a, b) {
      final byDistance = a.distance.compareTo(b.distance);
      return byDistance != 0 ? byDistance : a.regNo.compareTo(b.regNo);
    });
    return out.take(limit).toList();
  }
}
