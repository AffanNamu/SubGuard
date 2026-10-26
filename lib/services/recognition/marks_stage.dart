import 'dart:math' as math;
import 'dart:typed_data';

import '../../domain/ocr.dart';
import '../../domain/recognition.dart';
import '../vision/enhance.dart';
import '../vision/geometry.dart';
import '../vision/ink.dart';
import '../vision/lines.dart';
import '../vision/mark_reader.dart';
import '../vision/raster.dart';
import '../vision/table_rows.dart';

/// One row of the marks table as the machine read it.
class MarkRowRead {
  const MarkRowRead({
    required this.index,
    required this.row,
    required this.markCell,
    required this.questionCell,
    required this.mark,
    required this.question,
    required this.questionText,
    required this.questionCandidates,
    required this.inkVariant,
  });

  /// 1 for the first row from the top.
  final int index;

  /// The same row under another number (rows are numbered from the top after any
  /// leftover pen stroke has been left out).
  MarkRowRead withIndex(int i) => MarkRowRead(
        index: i,
        row: row,
        markCell: markCell,
        questionCell: questionCell,
        mark: mark,
        question: question,
        questionText: questionText,
        questionCandidates: questionCandidates,
        inkVariant: inkVariant,
      );

  /// The whole row, and its two cells, as fractions of the photograph.
  final Region row;
  final Region markCell;
  final Region? questionCell;

  final MarkReading mark;
  final MarkReading? question;

  /// The question number read from the label cell (the digits at its right
  /// end), or null when none could be read.
  final String? questionText;
  final List<FieldCandidate> questionCandidates;

  /// Which picture variant the row was found and read in ("red_ink", "dark_ink").
  final String inkVariant;
}

class MarksStageResult {
  const MarksStageResult({
    required this.rows,
    required this.inkVariant,
    required this.notes,
    required this.strokesCrossingRows,
    this.total,
    this.totalCell,
    this.totalStrokes = 0,
    this.strokes = const {},
  });

  final List<MarkRowRead> rows;

  /// The ink picture the rows were read from, or null when no ink was found.
  final String? inkVariant;
  final List<String> notes;

  /// Regions where one long stroke crosses several rows, which is how unused
  /// rows are usually struck out. They are reported, not read as marks.
  final List<Region> strokesCrossingRows;

  /// The "Total" box: its reading, where it is, and how many separate pen
  /// strokes were found in it. No strokes means the box is blank.
  final MarkReading? total;
  final Region? totalCell;
  final int totalStrokes;

  /// Pen strokes counted in each extra region asked about ([readMarksTable]'s
  /// `probes`), to tell "nothing written" from "written but not read".
  final Map<String, int> strokes;
}

/// Finds the rows of the marks table and reads each row's mark and question
/// label.
///
/// Pure and synchronous, so the pipeline can run it in a background isolate.
/// Nothing here decides whether a reading is trusted: it returns what was seen
/// and how sure the reader was, and the pipeline's policy decides the rest.
MarksStageResult readMarksTable(
  ColorRaster photo, {
  required Region marks,
  Region? questions,
  Region? total,
  Map<String, Region> probes = const {},
  required HandwritingRecognizer reader,
}) {
  final notes = <String>[];
  final w = photo.width, h = photo.height;
  ({int l, int t, int r, int b}) px(Region r) => (
        l: (r.left * w).floor().clamp(0, w - 1),
        t: (r.top * h).floor().clamp(0, h - 1),
        r: (r.right * w).ceil().clamp(1, w),
        b: (r.bottom * h).ceil().clamp(1, h),
      );

  final probed = <String, int>{
    for (final e in probes.entries) e.key: _strokesIn(photo, px(e.value)),
  };

  final m = px(marks);
  if (m.r - m.l < 12 || m.b - m.t < 12) {
    return MarksStageResult(
        rows: const [], inkVariant: null, notes: const ['The marks area is too small in the photo to read.'], strokesCrossingRows: const [], strokes: probed);
  }
  final qpx = questions == null ? null : px(questions);
  final tpx = total == null ? null : px(total);
  final hasQuestions = qpx != null && qpx.r - qpx.l >= 8;
  final hasTotal = tpx != null && tpx.r - tpx.l >= 8 && tpx.b - tpx.t >= 8;

  // One ink picture over the whole table (labels, marks and total), so a line
  // struck across it is found at its full length and removed everywhere, and
  // the typical character size is judged from every character in the table.
  final boxes = [m, if (hasQuestions) qpx, if (hasTotal) tpx];
  final u = (
    l: boxes.map((b) => b.l).reduce(math.min),
    t: boxes.map((b) => b.t).reduce(math.min),
    r: boxes.map((b) => b.r).reduce(math.max),
    b: boxes.map((b) => b.b).reduce(math.max),
  );
  final tableColor = photo.crop(u.l, u.t, u.r, u.b);
  Raster cut(Raster ink, ({int l, int t, int r, int b}) box) => ink.crop(box.l - u.l, box.t - u.t, box.r - u.l, box.b - u.t);

  // Rows are found in the picture of the pen's ink. Red is tried first: it is
  // the examiner's usual pen and separates cleanly from the printed form. Dark
  // ink is the fallback, with printed rules removed so they are not read as rows.
  String? variant;
  Raster? ink;
  var bands = const <RowBand>[];
  final strokesRemoved = <({int left, int top, int right, int bottom})>[];
  for (final v in const ['red_ink', 'dark_ink']) {
    strokesRemoved.clear();
    final im = _ink(tableColor, v, strokesRemoved);
    final b = TableRows.find(cut(im, m));
    if (b.isNotEmpty) {
      variant = v;
      ink = im;
      bands = b;
      break;
    }
  }

  if (variant == null || ink == null) {
    notes.add('No pen ink was found in the marks area.');
    // The total box may still have writing in it.
    final t = hasTotal ? _readTotal(tableColor, tpx, u, null, reader, w, h) : null;
    return MarksStageResult(
      rows: const [],
      inkVariant: null,
      notes: notes,
      strokesCrossingRows: const [],
      total: t?.reading,
      totalCell: t?.cell,
      totalStrokes: t?.strokes ?? 0,
      strokes: probed,
    );
  }
  if (variant == 'dark_ink') {
    notes.add('No red pen was found, so dark ink was read instead. Printed lines can interfere; check every row.');
  }

  // Lines, underlines and strike-throughs were removed from the ink picture
  // before the rows were found; they are reported so the examiner can see them.
  final crossings = <Region>[
    for (final r in strokesRemoved) _regionOf(u, r.left, r.top, r.right, r.bottom, w, h),
  ];
  if (crossings.isNotEmpty) {
    notes.add('${crossings.length} long line${crossings.length == 1 ? '' : 's'} (a rule, underline or strike-through) were ignored, not read as marks.');
  }

  final inkMarks = cut(ink, m);
  final inkQuestions = hasQuestions ? cut(ink, qpx) : null;
  final rows = <MarkRowRead>[];
  for (final b in bands) {
    final pad = math.max(2, (b.height * 0.18).round());
    final top = math.max(0, b.top - pad), bottom = math.min(inkMarks.height, b.bottom + pad);
    final mark = reader.read(inkMarks.crop(0, top, inkMarks.width, bottom));

    MarkReading? question;
    String? qText;
    var qCandidates = const <FieldCandidate>[];
    Region? qRegion;
    if (inkQuestions != null) {
      // The label cell shares the row's vertical extent in the photo.
      final photoTop = m.t + top, photoBottom = m.t + bottom;
      final qTop = (photoTop - qpx!.t).clamp(0, inkQuestions.height - 1), qBottom = (photoBottom - qpx.t).clamp(qTop + 1, inkQuestions.height);
      question = reader.read(inkQuestions.crop(0, qTop, inkQuestions.width, qBottom));
      final parsed = _questionNumber(question);
      qText = parsed?.text;
      qCandidates = parsed?.candidates ?? const [];
      qRegion = Region(qpx.l / w, (qpx.t + qTop) / h, qpx.r / w, (qpx.t + qBottom) / h).clamped();
    }

    final markRegion = Region(m.l / w, (m.t + top) / h, m.r / w, (m.t + bottom) / h).clamped();
    final whole = qRegion == null ? markRegion : Region(qRegion.left, math.min(qRegion.top, markRegion.top), markRegion.right, math.max(qRegion.bottom, markRegion.bottom));
    rows.add(MarkRowRead(
      index: rows.length + 1,
      row: whole,
      markCell: markRegion,
      questionCell: qRegion,
      mark: mark,
      question: question,
      questionText: qText,
      questionCandidates: qCandidates,
      inkVariant: variant,
    ));
  }
  // A pen stroke left over below the last row (the end of a strike-through, an
  // underline) can survive as a "row" of tiny ink. It is not a mark: its characters
  // are a fraction of the height of every other row's. It is reported and left out,
  // never offered as a reading.
  //
  // So is what is left of a stroke that was pressed lightly, which no size rule can
  // catch because a scrap of it can be as tall as a digit: a row below the last row
  // that has a question number, with no question number of its own and nothing in the
  // mark cell but ink that could not be read, with at most one other piece that is a
  // lone "1" or sits among the unreadable bits. A lone upright stroke is what the
  // digit reader calls "1" for any pen line, so on its own it is no evidence of a
  // mark; the note says so, and a mark that really is there can be added.
  final heights = [for (final r in rows) r.mark.chars.isEmpty ? 0 : r.mark.chars.map((c) => c.box.bottom - c.box.top).reduce(math.max)];
  var kept = rows;
  if (rows.length >= 2) {
    final sortedHeights = [...heights]..sort();
    final median = sortedHeights[sortedHeights.length ~/ 2];
    final lastLabelled = rows.lastIndexWhere((r) => r.questionText != null);
    final keep = <MarkRowRead>[];
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final tinyWriting = rows.length >= 3 && median > 0 && heights[i] < median * 0.4;
      final digits = [for (final c in r.mark.chars) if (c.text != '?') c.text];
      final strayStroke = lastLabelled >= 0 &&
          i > lastLabelled &&
          r.questionText == null &&
          r.mark.chars.length <= 3 &&
          digits.length <= 1 &&
          (digits.every((d) => d == '1') || digits.length < r.mark.chars.length);
      if (tinyWriting || strayStroke) {
        crossings.add(r.row);
        notes.add(tinyWriting
            ? 'A pen stroke below row ${r.index} is far smaller than the writing in the other rows, so it was ignored, not read as a mark.'
            : 'A stray stroke below the written rows (no question number, nothing that reads as a mark) was ignored. If it is a mark, add it with "Add a question".');
        continue;
      }
      keep.add(r);
    }
    if (keep.length != rows.length) {
      kept = [for (final (i, r) in keep.indexed) r.withIndex(i + 1)];
    }
  }
  final t = hasTotal ? _readTotal(tableColor, tpx, u, ink, reader, w, h) : null;
  return MarksStageResult(
    rows: kept,
    inkVariant: variant,
    notes: notes,
    strokesCrossingRows: crossings,
    total: t?.reading,
    totalCell: t?.cell,
    totalStrokes: t?.strokes ?? 0,
    strokes: probed,
  );
}

/// Reads the Total box from the table's ink picture. When there is none (no ink
/// in the marks area), both pictures are tried for the box on its own.
({MarkReading? reading, Region cell, int strokes}) _readTotal(
  ColorRaster tableColor,
  ({int l, int t, int r, int b}) box,
  ({int l, int t, int r, int b}) origin,
  Raster? ink,
  HandwritingRecognizer reader,
  int w,
  int h,
) {
  final cell = Region(box.l / w, box.t / h, box.r / w, box.b / h).clamped();
  Raster cut(Raster r) => r.crop(box.l - origin.l, box.t - origin.t, box.r - origin.l, box.b - origin.t);
  for (final picture in [if (ink != null) ink else ...[_ink(tableColor, 'red_ink'), _ink(tableColor, 'dark_ink')]]) {
    final cell0 = cut(picture);
    final n = strokeCount(cell0);
    if (n > 0) return (reading: reader.read(cell0), cell: cell, strokes: n);
  }
  return (reading: null, cell: cell, strokes: 0);
}

/// Separate pen strokes in a region, in the better of the two ink pictures.
int _strokesIn(ColorRaster photo, ({int l, int t, int r, int b}) box) {
  if (box.r - box.l < 8 || box.b - box.t < 8) return 0;
  final color = photo.crop(box.l, box.t, box.r, box.b);
  return math.max(strokeCount(_ink(color, 'red_ink')), strokeCount(_ink(color, 'dark_ink')));
}

/// How many separate pieces of ink there are in an ink map, ignoring specks.
/// Zero means nothing is written there.
int strokeCount(Raster ink) {
  final strong = inkLevel(ink);
  if (strong == 0) return 0;
  final mask = Raster(ink.width, ink.height);
  final thr = math.max(14, (strong * 0.5).round());
  for (var i = 0; i < ink.data.length; i++) {
    mask.data[i] = ink.data[i] >= thr ? 255 : 0;
  }
  final floor = math.max(6, ink.height * ink.height ~/ 600);
  return connectedComponents(mask, minArea: floor).length;
}

Region _regionOf(({int l, int t, int r, int b}) origin, int l, int t, int r, int b, int w, int h) =>
    Region((origin.l + l) / w, (origin.t + t) / h, (origin.l + r) / w, (origin.t + b) / h).clamped();

/// The ink picture of [color] for [variant], with strokes that are not
/// characters removed (see [_withoutLongStrokes]). Removed strokes are added to
/// [removed] as boxes in the picture's own pixels.
Raster _ink(ColorRaster color, String variant, [List<({int left, int top, int right, int bottom})>? removed]) {
  final raw = variant == 'red_ink' ? Enhancer.redInk(color) : Enhancer.darkInk(color.toGray());
  return _withoutLongStrokes(raw, removed);
}

/// Removes strokes that cannot be characters: a table rule, an underline, or a
/// line struck diagonally through unused rows.
///
/// The rule is geometric and the same for every photo. A character is not much
/// taller than the other characters in the table, so a piece of ink is a
/// stroke, not a character, when it is
///  - very elongated (more than 10 times longer than thick) and longer than 3
///    typical character heights, or
///  - longer, corner to corner, than 3.2 typical character heights while being
///    mostly empty inside its bounding box (a diagonal line: under 15% ink).
/// The typical height is the median of the ink pieces in the picture.
///
/// This exists because a long straight stroke looks to a digit network exactly
/// like a "1": on the development photo the diagonal strike-through was read as
/// "1" with 100% confidence before this rule.
Raster _withoutLongStrokes(Raster ink, List<({int left, int top, int right, int bottom})>? removed) {
  final strong = inkLevel(ink);
  if (strong == 0) return ink;
  final w = ink.width, h = ink.height;
  Raster maskAt(int level) {
    final m = Raster(w, h);
    for (var i = 0; i < ink.data.length; i++) {
      m.data[i] = ink.data[i] >= level ? 255 : 0;
    }
    return m;
  }

  final thr = math.max(14, (strong * 0.5).round());
  final mask = maskAt(thr);
  final blobs = connectedComponents(mask, minArea: 8);
  if (blobs.isEmpty) return ink;
  // The typical character height is taken from pieces that could be characters.
  // Rules are left out of it, or a picture holding only rules would take a rule's
  // length as the size of a character. With no character-like piece at all the
  // typical height is zero and every long, thin piece is a stroke.
  final heights = [
    for (final b in blobs)
      if (math.max(b.width, b.height) / math.max(1, math.min(b.width, b.height)) <= 10) b.height,
  ]..sort();
  final typical = heights.isEmpty ? 0.0 : heights[heights.length ~/ 2].toDouble();

  bool isStroke(Blob b) {
    final bw = b.width.toDouble(), bh = b.height.toDouble();
    final long = math.max(bw, bh), thin = math.max(1.0, math.min(bw, bh));
    final diag = math.sqrt(bw * bw + bh * bh);
    final fill = b.area / math.max(1.0, bw * bh);
    return (long / thin > 10 && long > typical * 3) || (diag > typical * 3.2 && fill < 0.15);
  }

  final out = ink.copy();
  // Pixels of the pieces that are characters (with a margin of one pixel). A stroke
  // is taken out around them, never through them.
  final protect = Uint8List(w * h);
  for (final b in blobs) {
    if (isStroke(b)) continue;
    for (var y = math.max(0, b.top - 1); y < math.min(h, b.bottom + 1); y++) {
      for (var x = math.max(0, b.left - 1); x < math.min(w, b.right + 1); x++) {
        protect[y * w + x] = 1;
      }
    }
  }
  void erase(Int32List labels, Blob b) {
    for (var y = math.max(0, b.top - 1); y < math.min(h, b.bottom + 1); y++) {
      for (var x = math.max(0, b.left - 1); x < math.min(w, b.right + 1); x++) {
        final i = y * w + x;
        if (protect[i] != 0) continue;
        // The stroke's own pixels and the one-pixel fringe next to them.
        var own = labels[i] == b.id;
        if (!own) {
          for (var dy = -1; dy <= 1 && !own; dy++) {
            for (var dx = -1; dx <= 1; dx++) {
              final nx = x + dx, ny = y + dy;
              if (nx >= 0 && ny >= 0 && nx < w && ny < h && labels[ny * w + nx] == b.id) {
                own = true;
                break;
              }
            }
          }
        }
        if (own) out.data[i] = 0;
      }
    }
  }

  // Strokes are looked for twice: among the strong ink, and among the faint ink
  // too. A pen strike-through is often pressed more lightly than the writing, so at
  // the writing's level it is a row of separate scraps, each too short to be a
  // stroke, and the scraps are then read as rows. Joined up at a lower level it is
  // one long, thin piece and is recognised as what it is.
  final low = math.max(10, (strong * 0.22).round());
  for (final level in [thr, if (low < thr) low]) {
    final labels = Int32List(w * h);
    final pieces = connectedComponents(level == thr ? mask : maskAt(level), minArea: 8, labelsOut: labels);
    for (final b in pieces) {
      if (!isStroke(b)) continue;
      removed?.add((left: b.left, top: b.top, right: b.right, bottom: b.bottom));
      erase(labels, b);
    }
  }
  // What is left may still hold a straight line broken into pieces (faint pen
  // draws a strike-through in dashes); a Hough transform finds those.
  final rest = Raster(ink.width, ink.height);
  for (var i = 0; i < out.data.length; i++) {
    rest.data[i] = out.data[i] >= thr ? 255 : 0;
  }
  final lines = LineFinder.find(rest, minLength: typical * 3.2);
  if (lines.isNotEmpty) {
    LineFinder.erase(out, lines);
    for (final l in lines) {
      removed?.add((
        left: math.max(0, math.min(l.x0, l.x1).floor()),
        top: math.max(0, math.min(l.y0, l.y1).floor()),
        right: math.min(ink.width, math.max(l.x0, l.x1).ceil() + 1),
        bottom: math.min(ink.height, math.max(l.y0, l.y1).ceil() + 1),
      ));
    }
  }
  return out;
}

/// The question number from a label cell such as "Q-4": the run of digits at
/// the right end. Anything that is not a digit ends the run, so the "Q" and the
/// dash are never mistaken for part of the number.
({String text, List<FieldCandidate> candidates})? _questionNumber(MarkReading r) {
  // The number is the digits at the right end that sit together. A gap wider
  // than about half a digit (where a dash or a circled "Q" was) ends the run, so
  // the label's own glyphs are never joined to the number. Digits of one number
  // are written side by side.
  // A question number is a whole number, so points after it are stray marks.
  var end = r.chars.length;
  while (end > 0 && r.chars[end - 1].text == '.') {
    end--;
  }
  final run = <MarkChar>[];
  for (var i = end - 1; i >= 0; i--) {
    final c = r.chars[i];
    if (c.text == '.' || c.text == '?') break;
    if (run.isNotEmpty) {
      final gap = run.first.box.left - c.box.right;
      final width = run.first.box.right - run.first.box.left;
      if (gap > math.max(2, width * 0.6)) break;
    }
    run.insert(0, c);
  }
  if (run.isEmpty || run.length > 2) return null;
  var beams = <({String text, double score})>[(text: '', score: 1)];
  for (final c in run) {
    final options = [(text: c.text, probability: c.confidence), ...c.alternatives.where((a) => a.text != '?')];
    final next = [
      for (final b in beams)
        for (final o in options) (text: b.text + o.text, score: b.score * o.probability),
    ]..sort((a, b) => b.score.compareTo(a.score));
    beams = next.take(4).toList();
  }
  final best = beams.first;
  return (
    text: best.text,
    candidates: [for (final b in beams) FieldCandidate(b.text, b.score, source: 'digit_net/${r.chars.length > 1 ? 'label' : 'cell'}')],
  );
}
