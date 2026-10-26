import 'dart:convert';

import 'ocr.dart';

/// Where the parts of one kind of booklet cover are, written as data.
///
/// A layout profile says which printed labels to look for ([AnchorSpec]), how those
/// labels sit relative to one another ([RelationSpec], which is how a page turned the
/// wrong way round is recognised), and where each region of interest is, measured from
/// the labels ([RegionSpec]). Nothing else about reading depends on the cover: the marks
/// are read from the ink inside the regions found here.
///
/// Profiles are plain JSON. The built-in profile, [LayoutProfile.modibboAdama], is the
/// reference: the app can write it out as a starting point for another department's
/// cover, and a file read back is checked against every rule below before it is used.
/// Positions are fractions of the photo's width and height, measured from the top left.
enum BoxMeasure {
  left,
  top,
  right,
  bottom,
  centerX,
  centerY;

  double of(Region box) => switch (this) {
        left => box.left,
        top => box.top,
        right => box.right,
        bottom => box.bottom,
        centerX => box.centerX,
        centerY => box.centerY,
      };
}

/// A test on one number: every bound given must hold.
class Bound {
  const Bound({this.gt, this.gte, this.lt, this.lte});

  final double? gt, gte, lt, lte;

  bool get isEmpty => gt == null && gte == null && lt == null && lte == null;

  bool holds(double v) => (gt == null || v > gt!) && (gte == null || v >= gte!) && (lt == null || v < lt!) && (lte == null || v <= lte!);

  Map<String, Object?> toJson() => {if (gt != null) 'gt': gt, if (gte != null) 'gte': gte, if (lt != null) 'lt': lt, if (lte != null) 'lte': lte};
}

/// Tests on where a line of text is on the photo; every one must hold.
class Where {
  const Where([this.bounds = const {}]);

  final Map<BoxMeasure, Bound> bounds;

  bool matches(Region box) {
    for (final e in bounds.entries) {
      if (!e.value.holds(e.key.of(box))) return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {for (final e in bounds.entries) e.key.name: e.value.toJson()};
}

/// Which of several lines that match an anchor is the anchor.
enum AnchorPick {
  /// The first, in reading order of the text reader's output.
  first,

  /// The one lowest on the photo.
  lowest,
}

/// A printed label the layout hangs on.
class AnchorSpec {
  const AnchorSpec({
    required this.key,
    required this.name,
    required this.words,
    this.where = const Where(),
    this.pick = AnchorPick.first,
    this.reported = true,
  });

  /// What regions and relations call it.
  final String key;

  /// What the examiner is told when it is found or missing.
  final String name;

  /// Lower-case letters of a word in the label; a line matches when it contains any
  /// of them, allowing for the odd wrong or missing letter a reader makes.
  final List<String> words;
  final Where where;
  final AnchorPick pick;

  /// Counted in "labels found" / "labels missing". A label that only places a region
  /// (and whose absence is not a fault in the photo) is not reported.
  final bool reported;
}

/// How two labels should sit. The first named is `a`.
enum RelationRule {
  /// `a` is left of `b` and their centres are on the same row (within the tolerance).
  leftOfSameRow('left_of_same_row'),

  /// `a` is entirely below `b`.
  below('below'),

  /// `a` is entirely above `b`.
  above('above'),

  /// `a`'s centre is higher up the page than `b`'s.
  higher('higher');

  const RelationRule(this.json);
  final String json;
}

class RelationSpec {
  const RelationSpec({required this.a, required this.rule, required this.b, this.tolerance = 0.03});

  final String a, b;
  final RelationRule rule;

  /// Only for [RelationRule.leftOfSameRow]: how far apart the two centres may be
  /// vertically, as a fraction of the photo's height.
  final double tolerance;

  /// Whether the rule holds for these two labels' boxes.
  bool holds(Region boxA, Region boxB) => switch (rule) {
        RelationRule.leftOfSameRow => boxA.centerX < boxB.centerX && (boxA.centerY - boxB.centerY).abs() <= tolerance,
        RelationRule.below => boxA.top > boxB.bottom,
        RelationRule.above => boxA.bottom < boxB.top,
        RelationRule.higher => boxA.centerY < boxB.centerY,
      };
}

/// A number worked out from the labels found: one edge of a region.
sealed class Expr {
  const Expr();

  /// [found] gives the box of each anchor that was found.
  double eval(Map<String, Region> found);

  Iterable<String> get anchorsUsed;

  Object toJson();
}

class ConstExpr extends Expr {
  const ConstExpr(this.value);
  final double value;

  @override
  double eval(Map<String, Region> found) => value;

  @override
  Iterable<String> get anchorsUsed => const [];

  @override
  Object toJson() => value;
}

/// An edge of a found label, moved by [offset].
class RefExpr extends Expr {
  const RefExpr(this.anchor, this.edge, [this.offset = 0]);
  final String anchor;
  final BoxMeasure edge;
  final double offset;

  @override
  double eval(Map<String, Region> found) => edge.of(found[anchor]!) + offset;

  @override
  Iterable<String> get anchorsUsed => [anchor];

  @override
  Object toJson() => {'ref': '$anchor.${edge.name}', if (offset != 0) 'offset': offset};
}

class MaxExpr extends Expr {
  const MaxExpr(this.of);
  final List<Expr> of;

  @override
  double eval(Map<String, Region> found) => of.map((e) => e.eval(found)).reduce((a, b) => a > b ? a : b);

  @override
  Iterable<String> get anchorsUsed => of.expand((e) => e.anchorsUsed);

  @override
  Object toJson() => {'max': [for (final e in of) e.toJson()]};
}

class MinExpr extends Expr {
  const MinExpr(this.of);
  final List<Expr> of;

  @override
  double eval(Map<String, Region> found) => of.map((e) => e.eval(found)).reduce((a, b) => a < b ? a : b);

  @override
  Iterable<String> get anchorsUsed => of.expand((e) => e.anchorsUsed);

  @override
  Object toJson() => {'min': [for (final e in of) e.toJson()]};
}

/// One way of working a region out: usable when every label in [needs] was found.
class RegionVariant {
  const RegionVariant({required this.needs, required this.left, required this.top, required this.right, required this.bottom});

  final List<String> needs;
  final Expr left, top, right, bottom;

  /// The region, or null when a label it needs was not found.
  Region? place(Map<String, Region> found) {
    if (needs.any((n) => !found.containsKey(n))) return null;
    return Region(left.eval(found), top.eval(found), right.eval(found), bottom.eval(found)).clamped();
  }
}

/// The regions the rest of the app knows about.
enum RegionKey {
  examNumber('exam_number'),
  questionColumn('question_column'),
  marks('marks'),
  total('total'),
  answered('answered');

  const RegionKey(this.json);
  final String json;
}

/// A region, with the ways of finding it in order of preference: the first variant
/// whose labels were all found is used.
class RegionSpec {
  const RegionSpec({required this.variants, this.readsAs});

  final List<RegionVariant> variants;

  /// For the handwritten line of question numbers: a pattern a line inside the region
  /// must match to be taken as that line's text.
  final String? readsAs;

  Region? place(Map<String, Region> found) {
    for (final v in variants) {
      final r = v.place(found);
      if (r != null) return r;
    }
    return null;
  }
}

/// The printed booklet number: digits only, in a part of the photo.
class SerialRule {
  const SerialRule({required this.pattern, this.where = const Where()});
  final String pattern;
  final Where where;
}

/// The institution's name printed as a heading.
class InstitutionRule {
  const InstitutionRule({required this.word, this.where = const Where()});
  final String word;
  final Where where;
}

/// What was wrong with a layout file, in words an administrator can act on.
class LayoutProfileException implements Exception {
  const LayoutProfileException(this.message);
  final String message;
  @override
  String toString() => 'LayoutProfileException($message)';
}

class LayoutProfile {
  const LayoutProfile({
    required this.id,
    required this.name,
    required this.anchors,
    required this.regions,
    this.description,
    this.revision = 1,
    this.relations = const [],
    this.serial,
    this.institution,
  });

  static const schema = 1;

  /// Largest layout file read.
  static const maxFileBytes = 64 * 1024;

  final String id;
  final String name;
  final String? description;

  /// Bumped by whoever edits the file; stored with every reading made with it.
  final int revision;
  final List<AnchorSpec> anchors;
  final List<RelationSpec> relations;
  final Map<RegionKey, RegionSpec> regions;
  final SerialRule? serial;
  final InstitutionRule? institution;

  /// Layout files written by a person are compared by what they say.
  String get canonical => jsonEncode(toJson());

  @override
  bool operator ==(Object other) => other is LayoutProfile && other.canonical == canonical;

  @override
  int get hashCode => canonical.hashCode;

  AnchorSpec? anchor(String key) {
    for (final a in anchors) {
      if (a.key == key) return a;
    }
    return null;
  }

  /// The Modibbo Adama University examination booklet cover, as the engine has always
  /// read it: the layout every earlier version of the app was written for.
  static const modibboAdama = LayoutProfile(
    id: 'modibbo-adama-cover',
    name: 'Modibbo Adama University exam booklet',
    description: 'The cover with the candidate\'s examination number at the top and the "For Examiner\'s Use Only" marks table down the right.',
    revision: 1,
    anchors: [
      AnchorSpec(
        key: 'exam_label',
        name: "Candidate's Examination Number",
        words: ['candidate'],
        where: Where({BoxMeasure.left: Bound(lt: 0.45), BoxMeasure.top: Bound(lt: 0.45)}),
      ),
      AnchorSpec(
        key: 'examiner',
        name: "For Examiner's Use Only",
        words: ['examiner', 'useonly'],
        where: Where({BoxMeasure.centerX: Bound(gt: 0.5)}),
      ),
      AnchorSpec(
        key: 'question',
        name: 'Question',
        words: ['question'],
        where: Where({BoxMeasure.left: Bound(gt: 0.5)}),
      ),
      AnchorSpec(
        key: 'marks',
        name: 'Marks',
        words: ['marks'],
        where: Where({BoxMeasure.left: Bound(gt: 0.5), BoxMeasure.top: Bound(gt: 0.2)}),
      ),
      AnchorSpec(
        key: 'total',
        name: 'Total',
        words: ['total'],
        where: Where({BoxMeasure.left: Bound(gt: 0.5), BoxMeasure.top: Bound(gt: 0.6)}),
      ),
      AnchorSpec(
        key: 'instruction',
        name: 'Number your answers',
        words: ['havebeenwritten', 'answers'],
        where: Where({BoxMeasure.left: Bound(lt: 0.4), BoxMeasure.top: Bound(gt: 0.75)}),
        pick: AnchorPick.lowest,
        reported: false,
      ),
    ],
    relations: [
      RelationSpec(a: 'question', rule: RelationRule.leftOfSameRow, b: 'marks', tolerance: 0.03),
      RelationSpec(a: 'total', rule: RelationRule.below, b: 'marks'),
      RelationSpec(a: 'exam_label', rule: RelationRule.above, b: 'marks'),
      RelationSpec(a: 'examiner', rule: RelationRule.higher, b: 'question'),
    ],
    regions: {
      // The writing sits on the line the label is printed on, mostly above it. Below the
      // label comes the handwritten title, so the area stops there.
      RegionKey.examNumber: RegionSpec(variants: [
        RegionVariant(
          needs: ['exam_label'],
          left: MaxExpr([ConstExpr(0.3), RefExpr('exam_label', BoxMeasure.right)]),
          top: RefExpr('exam_label', BoxMeasure.top, -0.03),
          right: ConstExpr(0.96),
          bottom: RefExpr('exam_label', BoxMeasure.bottom, -0.002),
        ),
      ]),
      RegionKey.marks: RegionSpec(variants: [
        RegionVariant(
          needs: ['marks', 'total'],
          left: RefExpr('marks', BoxMeasure.left, -0.025),
          top: RefExpr('marks', BoxMeasure.bottom),
          right: ConstExpr(0.98),
          bottom: RefExpr('total', BoxMeasure.top, -0.004),
        ),
        // No "Marks" heading found: start under "For Examiner's Use Only".
        RegionVariant(
          needs: ['examiner', 'total'],
          left: RefExpr('examiner', BoxMeasure.left),
          top: RefExpr('examiner', BoxMeasure.bottom, 0.03),
          right: ConstExpr(0.98),
          bottom: RefExpr('total', BoxMeasure.top, -0.004),
        ),
      ]),
      RegionKey.questionColumn: RegionSpec(variants: [
        RegionVariant(
          needs: ['question', 'marks', 'total'],
          left: RefExpr('question', BoxMeasure.left, -0.025),
          top: RefExpr('marks', BoxMeasure.bottom),
          right: RefExpr('marks', BoxMeasure.left, -0.029),
          bottom: RefExpr('total', BoxMeasure.top, -0.004),
        ),
      ]),
      RegionKey.total: RegionSpec(variants: [
        RegionVariant(
          needs: ['total'],
          left: RefExpr('total', BoxMeasure.right),
          top: RefExpr('total', BoxMeasure.top, -0.02),
          right: ConstExpr(0.98),
          bottom: RefExpr('total', BoxMeasure.bottom, 0.03),
        ),
      ]),
      // The handwritten "questions answered" line, under the printed "NUMBER YOUR ANSWERS".
      RegionKey.answered: RegionSpec(
        readsAs: r'^[\d\s,.\-]{1,12}$',
        variants: [
          RegionVariant(
            needs: ['instruction'],
            left: ConstExpr(0.04),
            top: RefExpr('instruction', BoxMeasure.bottom),
            right: ConstExpr(0.55),
            bottom: RefExpr('instruction', BoxMeasure.bottom, 0.1),
          ),
        ],
      ),
    },
    serial: SerialRule(pattern: r'^\d{5,8}$', where: Where({BoxMeasure.top: Bound(lte: 0.2), BoxMeasure.centerX: Bound(gte: 0.5)})),
    institution: InstitutionRule(word: 'university', where: Where({BoxMeasure.top: Bound(lt: 0.1)})),
  );

  // ---- JSON ----

  Map<String, Object?> toJson() => {
        'schema': schema,
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        'revision': revision,
        'anchors': [
          for (final a in anchors)
            {
              'key': a.key,
              'name': a.name,
              'words': a.words,
              if (a.where.bounds.isNotEmpty) 'where': a.where.toJson(),
              if (a.pick != AnchorPick.first) 'pick': a.pick.name,
              if (!a.reported) 'reported': false,
            },
        ],
        if (relations.isNotEmpty)
          'relations': [
            for (final r in relations)
              {'a': r.a, 'rule': r.rule.json, 'b': r.b, if (r.rule == RelationRule.leftOfSameRow) 'tolerance': r.tolerance},
          ],
        'regions': {
          for (final e in regions.entries)
            e.key.json: {
              if (e.value.readsAs != null) 'readsAs': e.value.readsAs,
              'variants': [
                for (final v in e.value.variants)
                  {'needs': v.needs, 'left': v.left.toJson(), 'top': v.top.toJson(), 'right': v.right.toJson(), 'bottom': v.bottom.toJson()},
              ],
            },
        },
        if (serial != null) 'serial': {'pattern': serial!.pattern, if (serial!.where.bounds.isNotEmpty) 'where': serial!.where.toJson()},
        if (institution != null) 'institution': {'word': institution!.word, if (institution!.where.bounds.isNotEmpty) 'where': institution!.where.toJson()},
      };

  /// The file as it is shared: JSON, indented, with short lists and objects kept on one
  /// line so a person can read and edit it.
  String encode() => _pretty(toJson(), 0);

  static String _inline(Object? v) => switch (v) {
        Map() => '{${v.entries.map((e) => '${jsonEncode(e.key)}: ${_inline(e.value)}').join(', ')}}',
        List() => '[${v.map(_inline).join(', ')}]',
        _ => jsonEncode(v),
      };

  static String _pretty(Object? v, int depth) {
    final flat = _inline(v);
    if (flat.length + depth * 2 <= 96 || (v is! Map && v is! List)) return flat;
    final pad = '  ' * (depth + 1), end = '  ' * depth;
    if (v is Map) {
      return '{\n${v.entries.map((e) => '$pad${jsonEncode(e.key)}: ${_pretty(e.value, depth + 1)}').join(',\n')}\n$end}';
    }
    return '[\n${(v as List).map((e) => '$pad${_pretty(e, depth + 1)}').join(',\n')}\n$end]';
  }

  /// Reads a layout file. Throws [LayoutProfileException] saying what is wrong and where.
  static LayoutProfile parse(String text) {
    if (utf8.encode(text).length > maxFileBytes) {
      throw const LayoutProfileException('This file is too large to be a layout file (the limit is 64 KB).');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException catch (e) {
      throw LayoutProfileException('This is not a layout file: it is not valid JSON (${e.message}).');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const LayoutProfileException('This is not a layout file: it should be a JSON object.');
    }
    return fromJson(decoded);
  }

  static LayoutProfile fromJson(Map<String, dynamic> j) => _Reader().read(j);
}

/// Reads and checks a layout file. Every rule here exists so a file that passes cannot
/// make the reader fail or place a region off the page.
class _Reader {
  static final _id = RegExp(r'^[a-z0-9][a-z0-9._-]{2,47}$');
  static final _key = RegExp(r'^[a-z][a-z0-9_]{0,23}$');
  static final _word = RegExp(r'^[a-z]{3,20}$');

  Never fail(String path, String why) => throw LayoutProfileException('$path: $why');

  Map<String, dynamic> obj(Object? v, String path) => v is Map ? Map<String, dynamic>.from(v) : fail(path, 'should be an object');

  List<dynamic> list(Object? v, String path, {int min = 0, int max = 64}) {
    if (v is! List) fail(path, 'should be a list');
    if (v.length < min) fail(path, 'should have at least $min item${min == 1 ? '' : 's'}');
    if (v.length > max) fail(path, 'has more than $max items');
    return v;
  }

  String str(Object? v, String path, {int min = 1, int max = 200}) {
    if (v is! String) fail(path, 'should be text');
    final t = v.trim();
    if (t.length < min || t.length > max) fail(path, 'should be $min to $max characters long');
    return t;
  }

  double number(Object? v, String path, {double min = -1, double max = 1}) {
    if (v is! num) fail(path, 'should be a number');
    final d = v.toDouble();
    if (d.isNaN || d < min || d > max) fail(path, 'should be a number from $min to $max');
    return d;
  }

  void onlyKeys(Map<String, dynamic> m, String path, Set<String> allowed) {
    for (final k in m.keys) {
      if (!allowed.contains(k)) fail('$path.$k', 'is not a known setting (known: ${(allowed.toList()..sort()).join(', ')})');
    }
  }

  Where where(Object? v, String path) {
    if (v == null) return const Where();
    final m = obj(v, path);
    final bounds = <BoxMeasure, Bound>{};
    for (final e in m.entries) {
      final measure = BoxMeasure.values.where((x) => x.name == e.key).firstOrNull;
      if (measure == null) fail('$path.${e.key}', 'is not a position (use ${BoxMeasure.values.map((x) => x.name).join(', ')})');
      final b = obj(e.value, '$path.${e.key}');
      onlyKeys(b, '$path.${e.key}', {'gt', 'gte', 'lt', 'lte'});
      double? n(String k) => b.containsKey(k) ? number(b[k], '$path.${e.key}.$k', min: 0, max: 1) : null;
      final bound = Bound(gt: n('gt'), gte: n('gte'), lt: n('lt'), lte: n('lte'));
      if (bound.isEmpty) fail('$path.${e.key}', 'needs at least one of gt, gte, lt, lte');
      bounds[measure] = bound;
    }
    return Where(bounds);
  }

  Expr expr(Object? v, String path, Set<String> needs, {int depth = 0}) {
    if (depth > 3) fail(path, 'is nested too deeply');
    if (v is num) return ConstExpr(number(v, path, min: 0, max: 1));
    if (v is! Map) fail(path, 'should be a number, {"ref": "label.position"}, {"max": [...]} or {"min": [...]}');
    final m = obj(v, path);
    if (m.containsKey('ref')) {
      onlyKeys(m, path, {'ref', 'offset'});
      final ref = str(m['ref'], '$path.ref', max: 60);
      final parts = ref.split('.');
      final edge = parts.length == 2 ? BoxMeasure.values.where((x) => x.name == parts[1]).firstOrNull : null;
      if (edge == null) fail('$path.ref', '"$ref" should be a label and a position, like "total.top" (positions: ${BoxMeasure.values.map((x) => x.name).join(', ')})');
      if (!needs.contains(parts[0])) {
        fail('$path.ref', 'uses "${parts[0]}", which is not in this variant\'s "needs" (a region can only be measured from labels it needs)');
      }
      return RefExpr(parts[0], edge, m.containsKey('offset') ? number(m['offset'], '$path.offset', min: -0.5, max: 0.5) : 0);
    }
    for (final op in const ['max', 'min']) {
      if (m.containsKey(op)) {
        onlyKeys(m, path, {op});
        final raw = list(m[op], '$path.$op', min: 2, max: 6);
        final items = [for (final (i, e) in raw.indexed) expr(e, '$path.$op[$i]', needs, depth: depth + 1)];
        return op == 'max' ? MaxExpr(items) : MinExpr(items);
      }
    }
    fail(path, 'should be a number, {"ref": "label.position"}, {"max": [...]} or {"min": [...]}');
  }

  /// A pattern is matched against every line of text the reader finds, so one that can run
  /// for a very long time on a short line would freeze the app. Patterns are therefore kept
  /// to a plain subset: no repeat applied to a group, no back-references, no look-ahead or
  /// look-behind.
  static final _unsafe = RegExp(r'\)[*+{]|\\[1-9]|\(\?[^:]');

  String pattern(Object? v, String path) {
    final p = str(v, path, max: 80);
    try {
      RegExp(p);
    } on FormatException {
      fail(path, 'is not a valid pattern');
    }
    if (_unsafe.hasMatch(p)) {
      fail(path, 'uses a repeated group, a back-reference or a look-ahead, which layout patterns do not allow (use plain characters, classes like \\d, and repeats like {1,12})');
    }
    return p;
  }

  LayoutProfile read(Map<String, dynamic> j) {
    onlyKeys(j, 'layout', {'schema', 'id', 'name', 'description', 'revision', 'anchors', 'relations', 'regions', 'serial', 'institution'});
    if (j['schema'] != LayoutProfile.schema) {
      fail('schema', 'should be ${LayoutProfile.schema} (this version of UniMarkLy reads layout files with schema ${LayoutProfile.schema})');
    }
    final id = str(j['id'], 'id', max: 48);
    if (!_id.hasMatch(id)) fail('id', '"$id" should be 3 to 48 lower-case letters, digits, dots, dashes or underscores');
    final name = str(j['name'], 'name', min: 3, max: 80);
    final description = j['description'] == null ? null : str(j['description'], 'description', max: 300);
    final revision = j['revision'] == null ? 1 : (number(j['revision'], 'revision', min: 1, max: 100000)).toInt();

    final anchors = <AnchorSpec>[];
    final keys = <String>{};
    for (final (i, raw) in list(j['anchors'], 'anchors', min: 1, max: 16).indexed) {
      final p = 'anchors[$i]';
      final a = obj(raw, p);
      onlyKeys(a, p, {'key', 'name', 'words', 'where', 'pick', 'reported'});
      final key = str(a['key'], '$p.key', max: 24);
      if (!_key.hasMatch(key)) fail('$p.key', '"$key" should be lower-case letters, digits and underscores, starting with a letter');
      if (!keys.add(key)) fail('$p.key', '"$key" is used twice');
      final words = [
        for (final (k, w) in list(a['words'], '$p.words', min: 1, max: 6).indexed)
          () {
            final s = str(w, '$p.words[$k]', max: 20);
            if (!_word.hasMatch(s)) fail('$p.words[$k]', '"$s" should be 3 to 20 lower-case letters with no spaces or punctuation');
            return s;
          }(),
      ];
      final pickName = a['pick'];
      final pick = pickName == null ? AnchorPick.first : AnchorPick.values.where((x) => x.name == pickName).firstOrNull;
      if (pick == null) fail('$p.pick', 'should be "first" or "lowest"');
      final reported = a['reported'];
      if (reported != null && reported is! bool) fail('$p.reported', 'should be true or false');
      anchors.add(AnchorSpec(
        key: key,
        name: str(a['name'], '$p.name', max: 60),
        words: words,
        where: where(a['where'], '$p.where'),
        pick: pick,
        reported: reported as bool? ?? true,
      ));
    }
    if (!anchors.any((a) => a.reported)) fail('anchors', 'at least one label should be reported (a layout cannot tell a good photo from a bad one without)');

    final relations = <RelationSpec>[];
    for (final (i, raw) in list(j['relations'] ?? const [], 'relations', max: 16).indexed) {
      final p = 'relations[$i]';
      final r = obj(raw, p);
      onlyKeys(r, p, {'a', 'rule', 'b', 'tolerance'});
      String label(String k) {
        final s = str(r[k], '$p.$k', max: 24);
        if (!keys.contains(s)) fail('$p.$k', '"$s" is not one of the labels in "anchors"');
        return s;
      }

      final a = label('a'), b = label('b');
      if (a == b) fail(p, 'compares "$a" with itself');
      final rule = RelationRule.values.where((x) => x.json == r['rule']).firstOrNull;
      if (rule == null) fail('$p.rule', 'should be one of ${RelationRule.values.map((x) => x.json).join(', ')}');
      if (r.containsKey('tolerance') && rule != RelationRule.leftOfSameRow) fail('$p.tolerance', 'only applies to left_of_same_row');
      relations.add(RelationSpec(a: a, rule: rule, b: b, tolerance: r.containsKey('tolerance') ? number(r['tolerance'], '$p.tolerance', min: 0, max: 0.2) : 0.03));
    }

    final regions = <RegionKey, RegionSpec>{};
    for (final e in obj(j['regions'], 'regions').entries) {
      final p = 'regions.${e.key}';
      final key = RegionKey.values.where((x) => x.json == e.key).firstOrNull;
      if (key == null) fail(p, 'is not a region the app uses (use ${RegionKey.values.map((x) => x.json).join(', ')})');
      final r = obj(e.value, p);
      onlyKeys(r, p, {'variants', 'readsAs'});
      if (r.containsKey('readsAs') && key != RegionKey.answered) fail('$p.readsAs', 'only applies to the "answered" region');
      final variants = <RegionVariant>[];
      for (final (i, raw) in list(r['variants'], '$p.variants', min: 1, max: 4).indexed) {
        final vp = '$p.variants[$i]';
        final v = obj(raw, vp);
        onlyKeys(v, vp, {'needs', 'left', 'top', 'right', 'bottom'});
        final needs = [
          for (final (k, n) in list(v['needs'], '$vp.needs', min: 1, max: 8).indexed)
            () {
              final s = str(n, '$vp.needs[$k]', max: 24);
              if (!keys.contains(s)) fail('$vp.needs[$k]', '"$s" is not one of the labels in "anchors"');
              return s;
            }(),
        ];
        final set = needs.toSet();
        final built = RegionVariant(
          needs: needs,
          left: expr(v['left'], '$vp.left', set),
          top: expr(v['top'], '$vp.top', set),
          right: expr(v['right'], '$vp.right', set),
          bottom: expr(v['bottom'], '$vp.bottom', set),
        );
        variants.add(built);
      }
      regions[key] = RegionSpec(variants: variants, readsAs: r['readsAs'] == null ? null : pattern(r['readsAs'], '$p.readsAs'));
    }
    if (!regions.containsKey(RegionKey.marks)) fail('regions.marks', 'is required: it is the table the marks are read from');

    SerialRule? serial;
    if (j['serial'] != null) {
      final s = obj(j['serial'], 'serial');
      onlyKeys(s, 'serial', {'pattern', 'where'});
      serial = SerialRule(pattern: pattern(s['pattern'], 'serial.pattern'), where: where(s['where'], 'serial.where'));
    }
    InstitutionRule? institution;
    if (j['institution'] != null) {
      final s = obj(j['institution'], 'institution');
      onlyKeys(s, 'institution', {'word', 'where'});
      final w = str(s['word'], 'institution.word', max: 20);
      if (!_word.hasMatch(w)) fail('institution.word', '"$w" should be 3 to 20 lower-case letters');
      institution = InstitutionRule(word: w, where: where(s['where'], 'institution.where'));
    }

    return LayoutProfile(
      id: id,
      name: name,
      description: description,
      revision: revision,
      anchors: anchors,
      relations: relations,
      regions: regions,
      serial: serial,
      institution: institution,
    );
  }
}
