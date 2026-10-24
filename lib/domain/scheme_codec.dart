import 'dart:convert';

import 'ids.dart';
import 'scheme.dart';

/// Saves a scheme and its grade scale as JSON for the `scheme_template` table.
///
/// Ids are not saved. Loading a template gives every part, question and grade
/// band a new id, so a new course never shares rows with the template.
class SchemeCodec {
  const SchemeCodec._();

  static String encode(GradingScheme s) => jsonEncode({
        'version': 1,
        'totalExpected': s.totalExpected,
        'countRule': s.countRule.dbValue,
        'countN': s.countN,
        'parts': [
          for (final p in s.parts)
            {
              'name': p.name,
              'max': p.max,
              'min': p.min,
              'passMark': p.passMark,
              'step': p.step,
              'markedOutOf': p.markedOutOf,
              'countsFor': p.countsFor,
              'source': p.source.dbValue,
            }
        ],
        'questions': [
          for (final q in s.questions)
            {'qNo': q.qNo, 'max': q.max, 'compulsory': q.compulsory}
        ],
        'bands': [
          for (final b in s.bands)
            {
              'min': b.minScore,
              'max': b.maxScore,
              'letter': b.letter,
              'points': b.points,
            }
        ],
      });

  static GradingScheme decode(String source) {
    final m = jsonDecode(source) as Map<String, dynamic>;
    double d(Object? v, [double fallback = 0]) =>
        (v as num?)?.toDouble() ?? fallback;
    double? dn(Object? v) => (v as num?)?.toDouble();

    final parts = <PartSpec>[];
    final rawParts = (m['parts'] as List?) ?? const [];
    for (var i = 0; i < rawParts.length; i++) {
      final p = rawParts[i] as Map<String, dynamic>;
      parts.add(PartSpec(
        id: newId(),
        name: p['name'] as String? ?? 'Part ${i + 1}',
        max: d(p['max']),
        min: d(p['min']),
        passMark: dn(p['passMark']),
        step: d(p['step'], 0.5),
        markedOutOf: dn(p['markedOutOf']),
        countsFor: dn(p['countsFor']),
        source: PartSource.fromDb(p['source'] as String?),
        sortOrder: i,
      ));
    }

    return GradingScheme(
      totalExpected: d(m['totalExpected'], 100),
      countRule: CountRule.fromDb(m['countRule'] as String?),
      countN: (m['countN'] as num?)?.toInt(),
      parts: parts,
      questions: [
        for (final q in (m['questions'] as List?) ?? const [])
          QuestionSpec(
            id: newId(),
            qNo: ((q as Map)['qNo'] as num).toInt(),
            max: d(q['max']),
            compulsory: q['compulsory'] as bool? ?? false,
          )
      ],
      bands: [
        for (final b in (m['bands'] as List?) ?? const [])
          GradeBand(
            id: newId(),
            minScore: d((b as Map)['min']),
            maxScore: d(b['max']),
            letter: b['letter'] as String? ?? '',
            points: d(b['points']),
          )
      ],
    );
  }

  /// A copy of [scheme] with fresh ids, for starting a course from a template.
  static GradingScheme freshCopy(GradingScheme scheme) => decode(encode(scheme));
}
