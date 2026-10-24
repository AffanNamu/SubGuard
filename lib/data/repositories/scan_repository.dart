import 'package:drift/drift.dart';

import '../../domain/ids.dart';
import '../../domain/scan.dart';
import '../database/app_database.dart';
import 'course_repository.dart';

/// Uploads (batches) and the photos in them.
class ScanRepository {
  ScanRepository(this._db, this._courses);

  final AppDatabase _db;
  final CourseRepository _courses;

  DateTime get _now => DateTime.now().toUtc();

  ScanItem _item(ScanRow r) => ScanItem(
        id: r.id,
        courseId: r.courseId,
        batchId: r.batchId,
        relativePath: r.photoPath ?? '',
        originalName: r.originalName,
        contentHash: r.contentHash,
        width: r.width,
        height: r.height,
        status: ScanStatus.fromDb(r.status),
        errorMessage: r.errorMessage,
        createdAt: r.createdAt,
      );

  Set<TableInfo> get _tables => {_db.batches, _db.scans, _db.courses};

  // ---- batches ----

  Future<String> createBatch(String courseId, {String? title}) async {
    final id = newId();
    await _db.into(_db.batches).insert(BatchesCompanion.insert(
          courseId: courseId,
          id: Value(id),
          title: Value(title?.trim().isEmpty ?? true ? null : title!.trim()),
          updatedAt: Value(_now),
        ));
    return id;
  }

  /// Newest first, with the course and counts of each status.
  Stream<List<BatchSummary>> watchBatches() => _db
      .customSelect('SELECT 1', readsFrom: {..._tables, _db.courseParts})
      .watch()
      .asyncMap((_) => batches());

  Future<List<BatchSummary>> batches() async {
    final rows = await (_db.select(_db.batches)
          ..where((b) => b.deletedAt.isNull())
          ..orderBy([(b) => OrderingTerm.desc(b.updatedAt)]))
        .get();
    if (rows.isEmpty) return const [];

    final scans = await (_db.select(_db.scans)
          ..where((s) => s.deletedAt.isNull() & s.batchId.isNotNull())
          ..orderBy([(s) => OrderingTerm.asc(s.createdAt)]))
        .get();
    final courses = {for (final c in await _courses.getAll()) c.id: c};

    final out = <BatchSummary>[];
    for (final b in rows) {
      final course = courses[b.courseId];
      if (course == null) continue; // its course is in the bin
      final mine = scans.where((s) => s.batchId == b.id).toList();
      int count(ScanStatus st) => mine.where((s) => ScanStatus.fromDb(s.status) == st).length;
      out.add(BatchSummary(
        id: b.id,
        course: course,
        title: b.title,
        createdAt: b.createdAt,
        coverPath: mine.isEmpty ? null : mine.first.photoPath,
        counts: BatchCounts(
          images: mine.length,
          queued: count(ScanStatus.queued),
          processing: count(ScanStatus.processing),
          needsReview: count(ScanStatus.needsReview),
          confirmed: count(ScanStatus.confirmed),
          failed: count(ScanStatus.failed),
        ),
      ));
    }
    return out;
  }

  Stream<ScanStats> watchStats() => watchBatches().map((list) {
        var records = 0, confirmed = 0, review = 0;
        for (final b in list) {
          records += b.counts.records;
          confirmed += b.counts.confirmed;
          review += b.counts.needsReview;
        }
        return ScanStats(batches: list.length, records: records, confirmed: confirmed, needReview: review);
      });

  // ---- scans ----

  Stream<List<ScanItem>> watchScans(String batchId) => (_db.select(_db.scans)
        ..where((s) => s.batchId.equals(batchId) & s.deletedAt.isNull())
        ..orderBy([(s) => OrderingTerm.asc(s.createdAt), (s) => OrderingTerm.asc(s.originalName)]))
      .watch()
      .map((rows) => rows.map(_item).toList());

  Future<List<ScanItem>> scansOf(String batchId) async {
    final rows = await (_db.select(_db.scans)
          ..where((s) => s.batchId.equals(batchId) & s.deletedAt.isNull())
          ..orderBy([(s) => OrderingTerm.asc(s.createdAt)]))
        .get();
    return rows.map(_item).toList();
  }

  Future<ScanItem?> scan(String id) async {
    final r = await (_db.select(_db.scans)..where((s) => s.id.equals(id) & s.deletedAt.isNull()))
        .getSingleOrNull();
    return r == null ? null : _item(r);
  }

  /// Photos waiting for the examiner, newest batch first, across all courses.
  Stream<List<ScanItem>> watchNeedingReview() => (_db.select(_db.scans)
        ..where((s) => s.deletedAt.isNull() & s.status.isIn(['needs_review', 'scanned']))
        ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
      .watch()
      .map((rows) => rows.map(_item).toList());

  /// The photo already stored in this course with the same bytes, if any.
  Future<ScanItem?> findByHash(String courseId, String hash) async {
    final r = await (_db.select(_db.scans)
          ..where((s) => s.courseId.equals(courseId) & s.contentHash.equals(hash) & s.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
    return r == null ? null : _item(r);
  }

  Future<ScanItem> addScan({
    required String id,
    required String courseId,
    required String batchId,
    required String relativePath,
    required String originalName,
    required String contentHash,
    required int width,
    required int height,
  }) async {
    final now = _now;
    await _db.transaction(() async {
      await _db.into(_db.scans).insert(ScansCompanion.insert(
            courseId: courseId,
            kind: 'booklet_cover',
            id: Value(id),
            batchId: Value(batchId),
            photoPath: Value(relativePath),
            originalName: Value(originalName),
            contentHash: Value(contentHash),
            width: Value(width),
            height: Value(height),
            status: Value(ScanStatus.queued.dbValue),
            createdAt: Value(now),
            updatedAt: Value(now),
          ));
      await _touchBatch(batchId, now);
    });
    return (await scan(id))!;
  }

  Future<void> setStatus(String scanId, ScanStatus status, {String? error}) async {
    await (_db.update(_db.scans)..where((s) => s.id.equals(scanId))).write(ScansCompanion(
      status: Value(status.dbValue),
      errorMessage: Value(error),
      updatedAt: Value(_now),
    ));
  }

  /// Takes a photo out of its batch. The file stays on disk until the batch is
  /// cleared, so the removal can be undone.
  Future<void> remove(String scanId) async {
    final now = _now;
    await (_db.update(_db.scans)..where((s) => s.id.equals(scanId)))
        .write(ScansCompanion(deletedAt: Value(now), updatedAt: Value(now)));
  }

  Future<void> restore(String scanId) async {
    await (_db.update(_db.scans)..where((s) => s.id.equals(scanId)))
        .write(ScansCompanion(deletedAt: const Value(null), updatedAt: Value(_now)));
  }

  /// Photos left "processing" by an app that closed part-way through go back to
  /// the queue, so nothing is lost and nothing is silently skipped.
  Future<int> requeueInterrupted() => (_db.update(_db.scans)
        ..where((s) => s.status.equals(ScanStatus.processing.dbValue) & s.deletedAt.isNull()))
      .write(ScansCompanion(status: Value(ScanStatus.queued.dbValue), updatedAt: Value(_now)));

  Future<void> _touchBatch(String batchId, DateTime now) async {
    await (_db.update(_db.batches)..where((b) => b.id.equals(batchId)))
        .write(BatchesCompanion(updatedAt: Value(now)));
  }

  Future<void> softDeleteBatch(String batchId) async {
    final now = _now;
    await (_db.update(_db.batches)..where((b) => b.id.equals(batchId)))
        .write(BatchesCompanion(deletedAt: Value(now), updatedAt: Value(now)));
  }

  Future<void> restoreBatch(String batchId) async {
    await (_db.update(_db.batches)..where((b) => b.id.equals(batchId)))
        .write(BatchesCompanion(deletedAt: const Value(null), updatedAt: Value(_now)));
  }
}
