import 'dart:math' as math;

import '../../domain/ocr.dart';
import '../../domain/recognition.dart';
import '../../domain/reg_no.dart';

/// One reading of the exam-number area: which reader, on which picture
/// variant, and what it saw.
class ExamNumberReading {
  const ExamNumberReading({required this.reader, required this.readerVersion, required this.variant, required this.line});

  final String reader;
  final String readerVersion;
  final String variant;
  final OcrLine line;
}

/// Everything known about a handwritten registration number, with where each
/// possibility came from.
class ExamNumberEvidence {
  const ExamNumberEvidence({
    required this.candidates,
    required this.attempts,
    required this.suggestion,
    required this.raw,
    required this.variantsAgree,
    required this.warnings,
  });

  /// Every possibility, best first. Some are what a reader saw; some are class-list
  /// numbers the reading is close to. Each says which, in its source and note.
  final List<FieldCandidate> candidates;
  final List<ReadAttempt> attempts;

  /// The one number worth putting in front of the examiner first, chosen by the
  /// documented rule (see [ExamNumberResolver]), or null when nothing is clear
  /// enough. It is a suggestion and is never entered automatically.
  final ({String regNo, double confidence, bool onClassList})? suggestion;

  /// The best reading of what is written, tidied into DEPT/YYU/NNNN form, with
  /// no help from the class list. Null when nothing resembling one was read.
  final String? raw;

  /// Two or more different picture variants gave the same tidied reading.
  /// The variants are views of one photograph read by one engine, so this is
  /// evidence of stability, not an independent check.
  final bool variantsAgree;
  final List<String> warnings;
}

/// Turns readings of the handwritten registration number into candidates.
///
/// The class list is used as a *constraint on interpretation*, in the open: a
/// reading that is within two characters of exactly one class-list number, or
/// whose last digits match exactly one, is offered as that number, with a note
/// saying how close it was. It is a candidate beside what was actually read, not
/// a replacement for it. When the reading is close to two class-list numbers
/// equally, no class-list number is offered, because choosing one would be
/// inventing a certainty the handwriting does not have.
class ExamNumberResolver {
  const ExamNumberResolver._();

  /// A reading that matches no class-list number is offered as the suggestion
  /// only at or above this confidence, and only in the right pattern.
  static const double suggestionThreshold = 0.8;

  static ExamNumberEvidence resolve(List<ExamNumberReading> readings, List<String> classList) {
    final roster = {for (final r in classList) RegNo.key(r): r}..remove('');
    final byText = <String, _Cand>{};
    final attempts = <ReadAttempt>[];
    final warnings = <String>[];
    ({String regNo, double confidence, bool onClassList})? suggestion;
    final tidied = <String, Set<String>>{}; // tidied reading -> variants that gave it

    void offerSuggestion(String regNo, double confidence, bool onClassList) {
      if (suggestion == null || confidence > suggestion!.confidence) {
        suggestion = (regNo: regNo, confidence: confidence, onClassList: onClassList);
      }
    }

    void add(String text, double score, String source, {String? note}) {
      final c = byText.putIfAbsent(text, () => _Cand(text));
      c.score = math.max(c.score, score);
      if (!c.sources.contains(source)) c.sources.add(source);
      if (note != null && !c.notes.contains(note)) c.notes.add(note);
    }

    for (final r in readings) {
      final line = r.line;
      final conf = line.confidence;
      final src = '${r.reader}/${r.variant}';
      attempts.add(ReadAttempt(reader: r.reader, readerVersion: r.readerVersion, variant: r.variant, text: line.text, confidence: conf));

      final reg = RegNo.normalise(line.text);
      if (reg.canonical.isEmpty) continue;

      // What the reader saw, tidied into the registration-number form. The
      // corrections (O read as 0 and so on) are listed with the candidate.
      final base = conf ?? 0.3;
      if (reg.isValid) {
        tidied.putIfAbsent(reg.canonical, () => {}).add(r.variant);
        add(reg.canonical, base, src,
            note: reg.corrections.isEmpty ? null : 'Tidied from "${line.text.trim()}": ${reg.corrections.join('; ')}.');
      } else {
        add(line.text.trim(), base * 0.5, src, note: 'Does not fit DEPT/YYU/NNNN.');
      }

      final near = RegNo.nearest(reg.canonical, roster.keys, maxDistance: 2, limit: 2);
      final unique = near.isNotEmpty && (near.length == 1 || near[0].distance < near[1].distance);
      if (unique) {
        final d = near[0].distance;
        final accept = switch (d) {
          0 => true,
          1 => conf == null || conf >= 0.4,
          _ => conf != null && conf >= 0.7,
        };
        if (accept) {
          final score = d == 0 ? math.max(base, 0.9) : base * (1 - 0.15 * d);
          final listed = roster[near[0].regNo]!;
          add(listed, score, 'class_list($src)',
              note: d == 0
                  ? 'Matches a class-list number exactly.'
                  : 'The only class-list number within $d character${d == 1 ? '' : 's'} of what was read ("${reg.canonical}").');
          offerSuggestion(listed, score, true);
          continue;
        }
      }

      // The department and year prefix is the hard part to read in handwriting;
      // the sequence number is mostly digits and is read better. If its digits
      // match exactly one class-list number, that student is a candidate.
      final seq = RegExp(r'(\d{3,5})\D*$').firstMatch(line.text.trim())?.group(1);
      if (seq != null && roster.isNotEmpty) {
        final hits = [
          for (final k in roster.keys)
            if (RegExp(r'(\d{3,5})$').firstMatch(k)?.group(1) == seq) k,
        ];
        if (hits.length == 1 && (conf == null || conf >= 0.4)) {
          final score = (conf ?? 0.5) * 0.85;
          add(roster[hits.single]!, score, 'class_list($src)',
              note: 'The only class-list number ending in $seq. The prefix was not read clearly.');
          offerSuggestion(roster[hits.single]!, score, true);
          continue;
        }
      }

      // Close to two class-list numbers equally: the writing is ambiguous, so no
      // class-list number is offered.
      final ambiguous = near.length > 1 && near[0].distance == near[1].distance;
      if (ambiguous) {
        warnings.add('"${reg.canonical}" is equally close to ${near[0].regNo} and ${near[1].regNo}. Check the photo.');
      }
      if (!ambiguous && reg.isValid && conf != null && conf >= suggestionThreshold) {
        offerSuggestion(reg.canonical, conf, false);
      }
    }

    final candidates = [
      for (final c in byText.values)
        FieldCandidate(c.text, c.score, source: c.sources.join(', '), note: c.notes.isEmpty ? null : c.notes.join(' ')),
    ]..sort((a, b) => b.score.compareTo(a.score));

    // The best reading from the picture alone: highest-scoring tidied reading.
    String? raw;
    var rawScore = -1.0;
    for (final c in byText.values) {
      if (c.sources.every((s) => s.startsWith('class_list'))) continue;
      if (!RegNo.isValid(c.text)) continue;
      if (c.score > rawScore) {
        rawScore = c.score;
        raw = c.text;
      }
    }

    if (candidates.length > 1) {
      final distinct = {for (final c in candidates.where((c) => !c.source.startsWith('class_list'))) c.text};
      if (distinct.length > 1) warnings.add('The readings disagree: ${distinct.take(3).join(', ')}.');
    }

    return ExamNumberEvidence(
      candidates: candidates,
      attempts: attempts,
      suggestion: suggestion,
      raw: raw,
      variantsAgree: tidied.values.any((v) => v.length >= 2),
      warnings: warnings,
    );
  }
}

class _Cand {
  _Cand(this.text);
  final String text;
  double score = 0;
  final List<String> sources = [];
  final List<String> notes = [];
}
