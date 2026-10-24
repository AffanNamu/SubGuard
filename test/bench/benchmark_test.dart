import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:unimarkly/domain/ocr.dart';
import 'package:unimarkly/domain/recognition.dart';
import 'package:unimarkly/domain/reg_no.dart';
import 'package:unimarkly/services/recognition/booklet_pipeline.dart';
import 'package:unimarkly/services/recognition/interfaces.dart';
import 'package:unimarkly/services/recognition/model_registry.dart';
import 'package:unimarkly/services/vision/photo_codec.dart';

import 'package:unimarkly/services/vision/geometry.dart';
import '../support/degrade.dart';
import '../support/process_ocr_engine.dart';

/// The recognition benchmark: runs the pipeline over every document in
/// `eval/dataset`, scores it against the ground truth, and writes a report with
/// the denominator behind every number.
///
///     tool/bench/run_benchmark.sh            # BENCH=1 flutter test test/bench
///
/// Without BENCH=1 this file does nothing, so ordinary test runs stay fast.
///
/// What the numbers mean depends entirely on the data. `eval/README.md` says how
/// many documents there are and how they were made. Degraded variants of one
/// photograph measure how the stages behave under known damage; they are NOT
/// independent documents and do not widen the evidence about handwriting.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final enabled = Platform.environment['BENCH'] == '1';

  test('benchmark', () async {
    final ocr = await ProcessOcrEngine.tryStart();
    if (ocr == null) {
      fail('The OCR stand-in is not installed (pip install rapidocr-onnxruntime opencv-python-headless).');
    }
    final digits = await ModelRegistry.loadDigits();
    final pipeline = BookletPipeline(ocr: ocr, digits: digits);
    final asTaken = BookletPipeline(ocr: ocr, digits: digits, straighten: false);
    final docs = _loadDataset();
    final work = Directory.systemTemp.createTempSync('unimarkly_bench_');
    addTearDown(() {
      work.deleteSync(recursive: true);
      ocr.stop();
    });

    final runs = <_Run>[];
    var peakRss = ProcessInfo.currentRss;
    for (final doc in docs) {
      final original = (await decodePhoto(File(doc.image), maxSide: 4000)).image;
      final variants = <_Variant>[_Variant('original', doc.image, doc.qualityCategory)];
      if (Platform.environment['BENCH_VARIANTS'] != '0') {
        final specs = <(String, String, dynamic)>[
          ('blur_mild', 'blur_mild', Degrade.blur(original, 1.2)),
          ('blur_heavy', 'blur_heavy', Degrade.blur(original, 3.0)),
          ('dark', 'underexposed', Degrade.exposure(original, 0.45)),
          ('noisy', 'noisy', Degrade.noise(original, 14)),
          ('low_contrast', 'faint_ink', Degrade.lowContrast(original, 0.5)),
          ('shadow', 'shadow', Degrade.shadow(original, 0.45)),
        ];
        for (final s in specs) {
          final f = File(p.join(work.path, '${doc.id}_${s.$1}.png'));
          await f.writeAsBytes(await encodeColorPng(s.$3));
          variants.add(_Variant(s.$1, f.path, s.$2));
        }
        // The booklet photographed at an angle: placed on a desk at known corners.
        // The annotated boxes follow it, so the ground truth stays exact.
        const w = 1500, h = 1800;
        final angles = <(String, List<Pt>)>[
          ('keystone', const [Pt(330, 130), Pt(1170, 100), Pt(1420, 1690), Pt(110, 1730)]),
          ('rotated_12deg', const [Pt(300, 120), Pt(1330, 330), Pt(1130, 1700), Pt(120, 1480)]),
        ];
        for (final a in angles) {
          final placed = Degrade.place(original, w, h, a.$2);
          final f = File(p.join(work.path, '${doc.id}_${a.$1}.png'));
          await f.writeAsBytes(await encodeColorPng(placed.image));
          Region map(Region b) {
            final pts = [
              placed.photoToCanvas.apply(Pt(b.left * original.width, b.top * original.height)),
              placed.photoToCanvas.apply(Pt(b.right * original.width, b.top * original.height)),
              placed.photoToCanvas.apply(Pt(b.right * original.width, b.bottom * original.height)),
              placed.photoToCanvas.apply(Pt(b.left * original.width, b.bottom * original.height)),
            ];
            final xs = pts.map((q) => q.x / w), ys = pts.map((q) => q.y / h);
            return Region(xs.reduce(math.min), ys.reduce(math.min), xs.reduce(math.max), ys.reduce(math.max));
          }

          variants.add(_Variant(a.$1, f.path, '${a.$1} (straightened)', mapBox: map));
          variants.add(_Variant('${a.$1}_as_taken', f.path, '${a.$1} (as taken)', mapBox: map, straighten: false));
        }
      }
      for (final v in variants) {
        final sw = Stopwatch()..start();
        final result = await (v.straighten ? pipeline : asTaken).run(File(v.path), classList: doc.classList);
        sw.stop();
        peakRss = math.max(peakRss, ProcessInfo.maxRss);
        runs.add(_Run(doc, v.name, v.category, result, sw.elapsedMilliseconds, mapBox: v.mapBox));
      }
    }

    final batch = await _batchReliability(pipeline, docs.first.image, work);
    final report = _report(runs, batch, peakRss, ocr.name, digits, docs);
    final out = Directory('docs/recognition/results')..createSync(recursive: true);
    File(p.join(out.path, 'benchmark_latest.json')).writeAsStringSync(const JsonEncoder.withIndent(' ').convert(report.json));
    File(p.join(out.path, 'benchmark_latest.md')).writeAsStringSync(report.markdown);
    // ignore: avoid_print
    print(report.markdown);
  }, skip: enabled ? false : 'set BENCH=1 to run the benchmark (tool/bench/run_benchmark.sh)', timeout: const Timeout(Duration(minutes: 20)));
}

// ---- dataset ----

class _Truth {
  _Truth(this.key, this.kind, this.text, this.box, this.question);
  final String key, kind;
  final String? text;
  final Region box;
  final int? question;
}

class _Doc {
  _Doc(this.id, this.image, this.split, this.qualityCategory, this.fields, this.classList);
  final String id, image, split, qualityCategory;
  final List<_Truth> fields;
  final List<String> classList;

  _Truth? field(String key) {
    for (final f in fields) {
      if (f.key == key) return f;
    }
    return null;
  }
}

List<_Doc> _loadDataset() {
  final root = Directory('eval/dataset');
  final docs = <_Doc>[];
  for (final d in root.listSync().whereType<Directory>().toList()..sort((a, b) => a.path.compareTo(b.path))) {
    final truthFile = File(p.join(d.path, 'truth.json'));
    if (!truthFile.existsSync()) continue;
    final j = jsonDecode(truthFile.readAsStringSync()) as Map<String, dynamic>;
    final fields = [
      for (final f in (j['fields'] as List).cast<Map<String, dynamic>>())
        _Truth(
          f['key'] as String,
          f['kind'] as String,
          f['text'] as String?,
          () {
            final b = (f['box'] as List).map((v) => (v as num).toDouble()).toList();
            return Region(b[0], b[1], b[2], b[3]);
          }(),
          (f['question'] as num?)?.toInt(),
        ),
    ];
    // A class list shaped like a real one: the sequence of numbers around the
    // truth, so a reading that is a digit or two off has real neighbours to
    // be confused with.
    final exam = fields.where((f) => f.key == 'exam_number').firstOrNull?.text;
    final classList = <String>[];
    if (exam != null) {
      final m = RegExp(r'^(.*/)(\d{4})$').firstMatch(exam);
      if (m != null) {
        final centre = int.parse(m.group(2)!);
        for (var n = math.max(1, centre - 30); n < centre + 30; n++) {
          classList.add('${m.group(1)}${n.toString().padLeft(4, '0')}');
        }
      }
    }
    docs.add(_Doc(j['doc_id'] as String, p.join(d.path, j['image'] as String), j['split'] as String? ?? 'dev', j['quality_category'] as String? ?? 'unknown', fields, classList));
  }
  return docs;
}

// ---- scoring ----

class _Variant {
  _Variant(this.name, this.path, this.category, {this.mapBox, this.straighten = true});
  final String name, path, category;

  /// Where an annotated box (fractions of the original) is on this picture.
  final Region Function(Region)? mapBox;
  final bool straighten;
}

class _Run {
  _Run(this.doc, this.variant, this.category, this.result, this.ms, {this.mapBox});
  Region box(Region b) => mapBox == null ? b : mapBox!(b);
  final Region Function(Region)? mapBox;
  final _Doc doc;
  final String variant, category;
  final RecognitionResult result;
  final int ms;
}

int _lev(String a, String b) {
  final d = List.generate(a.length + 1, (i) => List<int>.filled(b.length + 1, 0));
  for (var i = 0; i <= a.length; i++) {
    d[i][0] = i;
  }
  for (var j = 0; j <= b.length; j++) {
    d[0][j] = j;
  }
  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      d[i][j] = math.min(math.min(d[i - 1][j] + 1, d[i][j - 1] + 1), d[i - 1][j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1));
    }
  }
  return d[a.length][b.length];
}

bool _sameNumber(String? a, String? b) {
  if (a == null || b == null) return false;
  final x = double.tryParse(a), y = double.tryParse(b);
  return x != null && y != null && (x - y).abs() < 1e-9;
}

class _Counter {
  int right = 0, total = 0;
  void add(bool ok) {
    total++;
    if (ok) right++;
  }

  Map<String, Object?> get json => {'right': right, 'of': total, 'rate': total == 0 ? null : right / total};
  String get text => total == 0 ? 'n/a' : '$right/$total (${(100 * right / total).toStringAsFixed(0)}%)';
}

class _Report {
  _Report(this.json, this.markdown);
  final Map<String, Object?> json;
  final String markdown;
}

Future<Map<String, Object?>> _batchReliability(BookletPipeline pipeline, String goodImage, Directory work) async {
  final corrupt = File(p.join(work.path, 'corrupt.jpg'))..writeAsBytesSync(List.generate(5000, (i) => (i * 31) % 256));
  final empty = File(p.join(work.path, 'empty.jpg'))..writeAsBytesSync(const []);
  final text = File(p.join(work.path, 'notes.jpg'))..writeAsStringSync('not a picture');
  final inputs = [File(goodImage), corrupt, File('/no/such/file.jpg'), empty, File(goodImage), text];
  var completed = 0, failedWithReason = 0, crashed = 0;
  final reasons = <String>[];
  for (final f in inputs) {
    try {
      await pipeline.run(f);
      completed++;
    } on RecognitionException catch (e) {
      failedWithReason++;
      reasons.add(e.message);
    } catch (e) {
      crashed++;
      reasons.add('CRASH: $e');
    }
  }
  return {'inputs': inputs.length, 'completed': completed, 'failed_with_reason': failedWithReason, 'crashed': crashed, 'reasons': reasons};
}

_Report _report(List<_Run> runs, Map<String, Object?> batch, int peakRss, String ocrName, LoadedDigitModel digits, List<_Doc> docs) {
  final reg = _Counter(), regAny = _Counter(), regAssisted = _Counter(), regRead = _Counter();
  var regCharErrors = 0, regChars = 0;
  final markExact = _Counter(), markAssoc = _Counter(), markQuestion = _Counter(), markAny = _Counter();
  final serial = _Counter(), totalBlank = _Counter();
  final docExact = _Counter();
  final recognizedFields = _Counter(); // right = correctly accepted
  final needReviewFields = _Counter(); // right = needing review
  final docNeedsReview = _Counter();
  final byCategory = <String, Map<String, _Counter>>{};
  final perRun = <Map<String, Object?>>[];
  final times = <int>[];

  for (final run in runs) {
    final r = run.result;
    final cat = byCategory.putIfAbsent(run.category, () => {'reg': _Counter(), 'mark': _Counter(), 'doc': _Counter(), 'review': _Counter(), 'rows': _Counter()});
    var docOk = true;
    final detail = <String, Object?>{};

    // registration number
    final truthExam = run.doc.field('exam_number');
    final exam = r.field('exam_number');
    if (truthExam?.text != null) {
      final truth = RegNo.key(truthExam!.text!);
      final raw = exam?.value == null ? null : RegNo.key(exam!.value!);
      final ok = raw == truth;
      reg.add(ok);
      cat['reg']!.add(ok);
      regRead.add(exam?.value != null);
      regAny.add(exam != null && exam.candidates.any((c) => RegNo.key(c.text) == truth));
      final top = exam?.candidates.isEmpty ?? true ? null : exam!.candidates.first.text;
      regAssisted.add(top != null && RegNo.key(top) == truth);
      final reading = exam?.value ?? '';
      regChars += truth.length;
      regCharErrors += _lev(reading.toUpperCase(), truthExam.text!.toUpperCase());
      if (!ok) docOk = false;
      detail['exam_number'] = {'truth': truthExam.text, 'raw': exam?.value, 'top_candidate': top, 'state': exam?.state.dbValue, 'exact': ok};
    }

    // printed serial number
    final truthSerial = run.doc.field('serial_no');
    if (truthSerial?.text != null) {
      final f = r.field('serial_no');
      final ok = f?.value == truthSerial!.text;
      serial.add(ok);
      if (!ok) docOk = false;
      detail['serial_no'] = {'truth': truthSerial.text, 'machine': f?.value, 'state': f?.state.dbValue, 'exact': ok};
    }

    // marks
    final machineRows = [for (final f in r.fields) if (f.key.startsWith('mark_row_')) f];
    final marks = <Map<String, Object?>>[];
    for (final t in run.doc.fields.where((f) => f.key.startsWith('mark_q'))) {
      // A row is "found at the right place" when the centre of the annotated
      // box lies inside the cell the pipeline found, and that cell is not
      // absurdly taller than the writing (at most 2.5 times).
      ExtractedField? placed;
      for (final row in machineRows) {
        final cell = row.region;
        if (cell == null) continue;
        final tb = run.box(t.box);
        final inside = tb.centerX >= cell.left && tb.centerX <= cell.right && tb.centerY >= cell.top && tb.centerY <= cell.bottom;
        if (inside && cell.height <= tb.height * 2.5) {
          placed = row;
          break;
        }
      }
      final associated = placed != null;
      markAssoc.add(associated);
      cat['rows']!.add(associated);
      final qOk = associated && int.tryParse(placed.question ?? '') == t.question;
      markQuestion.add(qOk);
      final byQuestion = machineRows.where((row) => int.tryParse(row.question ?? '') == t.question).firstOrNull;
      final exact = byQuestion != null && _sameNumber(byQuestion.value, t.text);
      markExact.add(exact);
      markAny.add(machineRows.any((row) => int.tryParse(row.question ?? '') == t.question && row.candidates.any((c) => _sameNumber(c.text, t.text))));
      cat['mark']!.add(exact);
      if (!exact) docOk = false;
      marks.add({'question': t.question, 'truth': t.text, 'machine': byQuestion?.value, 'row_found': associated, 'question_read': placed?.question, 'exact': exact});
    }
    detail['marks'] = marks;

    // the written total: truth null means the box is blank
    final truthTotal = run.doc.field('total_written');
    if (truthTotal != null) {
      final f = r.field('total_written');
      final ok = truthTotal.text == null ? (f != null && f.value == null) : _sameNumber(f?.value, truthTotal.text);
      totalBlank.add(ok);
      if (!ok) docOk = false;
      detail['total_written'] = {'truth': truthTotal.text, 'machine': f?.value, 'state': f?.state.dbValue, 'correct': ok};
    }

    // trust: which fields were accepted, and were they right
    for (final f in r.fields) {
      if (f.key == 'mark_rows') continue;
      final isAccepted = f.state == FieldState.recognized;
      if (isAccepted) {
        bool? right;
        if (f.key == 'serial_no') right = f.value == run.doc.field('serial_no')?.text;
        if (f.key == 'total_written') right = (run.doc.field('total_written')?.text == null) == (f.value == null);
        if (right != null) recognizedFields.add(right);
      }
      needReviewFields.add(!isAccepted);
    }
    docNeedsReview.add(r.fields.any((f) => f.state != FieldState.recognized));
    cat['doc']!.add(docOk);
    cat['review']!.add(r.fields.any((f) => f.state != FieldState.recognized));
    docExact.add(docOk);
    times.add(run.ms);
    perRun.add({
      'doc': run.doc.id,
      'variant': run.variant,
      'category': run.category,
      'split': run.doc.split,
      'quality_verdict': r.quality?.verdict.name,
      'quality_issues': [for (final i in r.quality?.issues ?? const []) i.code],
      'ms': run.ms,
      'stage_ms': r.timingsMs,
      'document_exact': docOk,
      'fields': detail,
    });
  }

  times.sort();
  final median = times.isEmpty ? 0 : times[times.length ~/ 2];
  final original = runs.where((r) => r.variant == 'original').length;
  final json = <String, Object?>{
    'schema': 1,
    'generated': DateTime.now().toUtc().toIso8601String(),
    'pipeline_version': BookletPipelineInfo.version,
    'environment': {
      'platform': Platform.operatingSystem,
      'cpus': Platform.numberOfProcessors,
      'ocr_reader': ocrName,
      'note': 'A development machine with a PP-OCRv4 stand-in for the phone\'s PaddleOCR. NOT a phone: timings and memory are not phone figures.',
    },
    'models': [digits.info.toJson()],
    'data': {
      'documents': docs.length,
      'independent_photographs': docs.length,
      'runs': runs.length,
      'original_runs': original,
      'degraded_runs': runs.length - original,
      'splits': {for (final d in docs) d.id: d.split},
      'note': 'Degraded runs are derived from the original photographs by known damage; they test the stages, not handwriting variety.',
    },
    'metrics': {
      'registration_number_exact_raw': reg.json,
      'registration_number_read_at_all': regRead.json,
      'registration_number_in_candidates': regAny.json,
      'registration_number_top_candidate_exact_with_class_list': regAssisted.json,
      'registration_number_character_error_rate': {'edits': regCharErrors, 'chars': regChars, 'rate': regChars == 0 ? null : regCharErrors / regChars},
      'mark_exact_with_question_assigned': markExact.json,
      'mark_in_candidates_with_question': markAny.json,
      'mark_row_found_at_right_place': markAssoc.json,
      'mark_row_question_label_correct': markQuestion.json,
      'printed_serial_exact': serial.json,
      'written_total_correct_including_blank': totalBlank.json,
      'document_exact': docExact.json,
      'documents_needing_review': docNeedsReview.json,
      'fields_needing_review': needReviewFields.json,
      'false_acceptance': {
        'accepted_fields_with_ground_truth': recognizedFields.total,
        'accepted_and_wrong': recognizedFields.total - recognizedFields.right,
        'rate': recognizedFields.total == 0 ? null : (recognizedFields.total - recognizedFields.right) / recognizedFields.total,
      },
      'time_per_page_ms': {'median': median, 'min': times.isEmpty ? 0 : times.first, 'max': times.isEmpty ? 0 : times.last},
      'peak_resident_memory_mb': (peakRss / 1048576).round(),
      'batch_reliability': batch,
    },
    'by_category': {
      for (final e in byCategory.entries)
        e.key: {
          'runs': e.value['doc']!.total,
          'registration_number_exact': e.value['reg']!.json,
          'mark_rows_found_at_right_place': e.value['rows']!.json,
          'mark_exact': e.value['mark']!.json,
          'document_exact': e.value['doc']!.json,
          'needing_review': e.value['review']!.json,
        },
    },
    'runs': perRun,
  };

  final md = StringBuffer()
    ..writeln('# Benchmark (generated)')
    ..writeln()
    ..writeln('Pipeline ${BookletPipelineInfo.version}, digit model ${digits.info.version} (${digits.info.sha256.substring(0, 12)}…).')
    ..writeln('Reader: $ocrName. Platform: ${Platform.operatingSystem}, ${Platform.numberOfProcessors} CPUs. **Not a phone.**')
    ..writeln()
    ..writeln('**Data: ${docs.length} independent photograph(s), ${runs.length} runs (${runs.length - original} derived by known damage).** '
        'With this little data none of the rates below is statistically meaningful. Read the denominators.')
    ..writeln()
    ..writeln('| metric | result |')
    ..writeln('|---|---|')
    ..writeln('| registration number, exact (raw reading) | ${reg.text} |')
    ..writeln('| registration number, read at all | ${regRead.text} |')
    ..writeln('| registration number, right one among candidates | ${regAny.text} |')
    ..writeln('| registration number, top candidate right (class list of ${docs.isEmpty ? 0 : docs.first.classList.length}) | ${regAssisted.text} |')
    ..writeln('| registration number, character error rate | ${regChars == 0 ? 'n/a' : '$regCharErrors edits / $regChars chars (${(100 * regCharErrors / regChars).toStringAsFixed(0)}%)'} |')
    ..writeln('| marks, exact with the right question | ${markExact.text} |')
    ..writeln('| marks, right value among candidates with the right question | ${markAny.text} |')
    ..writeln('| mark rows found at the right place | ${markAssoc.text} |')
    ..writeln('| question labels read correctly | ${markQuestion.text} |')
    ..writeln('| printed booklet number, exact | ${serial.text} |')
    ..writeln('| written total correct (blank counts when blank) | ${totalBlank.text} |')
    ..writeln('| whole document exact | ${docExact.text} |')
    ..writeln('| documents needing review | ${docNeedsReview.text} |')
    ..writeln('| fields needing review | ${needReviewFields.text} |')
    ..writeln('| false acceptance (accepted and wrong) | ${recognizedFields.total - recognizedFields.right} of ${recognizedFields.total} accepted fields with ground truth |')
    ..writeln('| time per page | median $median ms (min ${times.isEmpty ? 0 : times.first}, max ${times.isEmpty ? 0 : times.last}) on this machine |')
    ..writeln('| peak resident memory | ${(peakRss / 1048576).round()} MB on this machine |')
    ..writeln('| batch reliability | ${batch['completed']} read, ${batch['failed_with_reason']} refused with a reason, ${batch['crashed']} crashed, of ${batch['inputs']} inputs |')
    ..writeln()
    ..writeln('## By picture quality')
    ..writeln()
    ..writeln('| category | runs | registration no. exact | mark rows found at the right place | marks exact | document exact | needing review |')
    ..writeln('|---|---|---|---|---|---|---|');
  for (final e in byCategory.entries) {
    md.writeln('| ${e.key} | ${e.value['doc']!.total} | ${e.value['reg']!.text} | ${e.value['rows']!.text} | ${e.value['mark']!.text} | ${e.value['doc']!.text} | ${e.value['review']!.text} |');
  }
  return _Report(json, md.toString());
}
