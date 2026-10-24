import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/ids.dart';
import '../../domain/ocr.dart';
import '../../services/recognition/interfaces.dart';
import '../database/app_database.dart';

/// One stored run of the recognition pipeline on a photo.
class StoredRun {
  const StoredRun({required this.id, required this.scanId, required this.at, required this.status, required this.durationMs, required this.result});

  final String id;
  final String scanId;
  final DateTime at;

  /// `complete`, or `partial` when a stage failed.
  final String status;
  final int durationMs;
  final RecognitionResult result;
}

/// What the examiner decided about one field when they confirmed a booklet.
class FieldReviewDraft {
  const FieldReviewDraft({
    required this.fieldKey,
    required this.kind,
    required this.decision,
    this.machineValue,
    this.machineState,
    this.finalValue,
    this.region,
  });

  final String fieldKey;
  final String kind;

  /// `accepted`, `suggestion`, `edited`, `entered`, `rejected` or `blank`.
  final String decision;
  final String? machineValue;
  final String? machineState;
  final String? finalValue;
  final Region? region;
}

/// A stored decision, as read back.
class FieldReview {
  const FieldReview({
    required this.scanId,
    required this.fieldKey,
    required this.kind,
    required this.decision,
    required this.reviewedAt,
    this.runId,
    this.machineValue,
    this.machineState,
    this.finalValue,
    this.region,
  });

  final String scanId;
  final String? runId;
  final String fieldKey;
  final String kind;
  final String decision;
  final String? machineValue;
  final String? machineState;
  final String? finalValue;
  final Region? region;
  final DateTime reviewedAt;
}

/// A piece of handwriting with the text the examiner confirmed for it: the
/// photo, where on it, and what it says. The raw material for measuring and
/// training the handwriting reader.
class LabelledExample {
  const LabelledExample({
    required this.scanId,
    required this.courseId,
    required this.photoPath,
    required this.fieldKey,
    required this.kind,
    required this.text,
    required this.region,
    required this.decision,
    required this.reviewedAt,
    this.machineValue,
  });

  final String scanId;
  final String courseId;

  /// Relative to the scan folder.
  final String photoPath;
  final String fieldKey;
  final String kind;
  final String text;
  final Region region;

  /// `accepted`, `suggestion`, `edited` or `entered`.
  final String decision;
  final String? machineValue;
  final DateTime reviewedAt;
}

/// Stores what the recognition pipeline found (kept exactly as produced) and
/// what the examiner decided about each field.
class RecognitionRepository {
  RecognitionRepository(this._db);

  final AppDatabase _db;

  DateTime get _now => DateTime.now().toUtc();

  /// Stores a run and returns its id. Earlier runs for the photo are kept.
  Future<String> saveRun(String scanId, RecognitionResult result) async {
    final id = newId();
    final total = result.timingsMs.values.fold<int>(0, (a, b) => a + b);
    await _db.into(_db.recognitionRuns).insert(RecognitionRunsCompanion.insert(
          scanId: scanId,
          pipelineVersion: result.pipelineVersion,
          resultJson: jsonEncode(result.toJson()),
          id: Value(id),
          status: Value(result.partial ? 'partial' : 'complete'),
          durationMs: Value(total),
          updatedAt: Value(_now),
        ));
    return id;
  }

  Future<StoredRun?> latestRun(String scanId) async {
    final row = await (_db.select(_db.recognitionRuns)
          ..where((r) => r.scanId.equals(scanId) & r.deletedAt.isNull())
          ..orderBy([(r) => OrderingTerm.desc(r.updatedAt), (r) => OrderingTerm.desc(r.id)])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    try {
      final json = jsonDecode(row.resultJson) as Map<String, dynamic>;
      return StoredRun(
        id: row.id,
        scanId: scanId,
        at: row.updatedAt,
        status: row.status,
        durationMs: row.durationMs,
        result: RecognitionResult.fromJson(json),
      );
    } catch (_) {
      // A damaged run is treated as no run: the booklet can still be reviewed
      // by hand, and nothing is invented from a result that cannot be read.
      return null;
    }
  }

  Future<int> runCount(String scanId) async {
    final rows = await (_db.select(_db.recognitionRuns)..where((r) => r.scanId.equals(scanId) & r.deletedAt.isNull())).get();
    return rows.length;
  }

  Future<List<FieldReview>> reviewsOf(String scanId) async {
    final rows = await (_db.select(_db.fieldReviews)
          ..where((r) => r.scanId.equals(scanId) & r.deletedAt.isNull())
          ..orderBy([(r) => OrderingTerm.asc(r.reviewedAt), (r) => OrderingTerm.asc(r.fieldKey)]))
        .get();
    return [
      for (final r in rows)
        FieldReview(
          scanId: r.scanId,
          runId: r.runId,
          fieldKey: r.fieldKey,
          kind: r.kind,
          decision: r.decision,
          machineValue: r.machineValue,
          machineState: r.machineState,
          finalValue: r.finalValue,
          region: Region.decode(r.region),
          reviewedAt: r.reviewedAt,
        ),
    ];
  }

  /// Every confirmed piece of writing that has a place on its photo. Only the
  /// latest decision for a field of a photo counts (a booklet confirmed twice
  /// is one example per field, not two).
  Future<List<LabelledExample>> labelledExamples({String? courseId}) async {
    final query = _db.select(_db.fieldReviews).join([
      innerJoin(_db.scans, _db.scans.id.equalsExp(_db.fieldReviews.scanId)),
    ])
      ..where(_db.fieldReviews.deletedAt.isNull() &
          _db.fieldReviews.decision.isIn(const ['accepted', 'suggestion', 'edited', 'entered']) &
          _db.fieldReviews.finalValue.isNotNull() &
          _db.fieldReviews.region.isNotNull() &
          (courseId == null ? const Constant(true) : _db.scans.courseId.equals(courseId)))
      ..orderBy([OrderingTerm.asc(_db.fieldReviews.reviewedAt)]);
    final latest = <String, LabelledExample>{};
    for (final row in await query.get()) {
      final r = row.readTable(_db.fieldReviews);
      final s = row.readTable(_db.scans);
      final region = Region.decode(r.region);
      final photo = s.photoPath;
      if (region == null || photo == null) continue;
      latest['${r.scanId}/${r.fieldKey}'] = LabelledExample(
        scanId: r.scanId,
        courseId: s.courseId,
        photoPath: photo,
        fieldKey: r.fieldKey,
        kind: r.kind,
        text: r.finalValue!,
        region: region,
        decision: r.decision,
        machineValue: r.machineValue,
        reviewedAt: r.reviewedAt,
      );
    }
    return latest.values.toList();
  }
}
