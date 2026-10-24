import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/ids.dart';
import '../../domain/ocr.dart';
import '../../domain/scan.dart';
import '../../services/reader/booklet_extractor.dart';
import '../database/app_database.dart';
import 'score_repository.dart';

/// What the reader found on one photo, as stored.
class StoredBooklet {
  const StoredBooklet({
    required this.id,
    required this.scanId,
    required this.courseId,
    required this.studentId,
    required this.serialNo,
    required this.reading,
    required this.engine,
    required this.confirmed,
    required this.marks,
  });

  final String id;
  final String scanId;
  final String courseId;
  final String? studentId;
  final String? serialNo;
  final BookletReading reading;
  final String engine;
  final bool confirmed;

  /// Question number -> mark, once confirmed.
  final Map<int, double> marks;
}

/// One value the examiner changed from what the reader suggested. Each one is a
/// labelled example for training the handwriting model later.
class CorrectionDraft {
  const CorrectionDraft({required this.field, required this.readValue, required this.confirmedValue, this.region});

  final String field;
  final String? readValue;
  final String confirmedValue;
  final Region? region;
}

class BookletRepository {
  BookletRepository(this._db, this._scores);

  final AppDatabase _db;
  final ScoreRepository _scores;

  DateTime get _now => DateTime.now().toUtc();

  Future<StoredBooklet?> forScan(String scanId) async {
    final row = await (_db.select(_db.booklets)
          ..where((b) => b.scanId.equals(scanId) & b.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    final marks = await (_db.select(_db.questionMarks)
          ..where((m) => m.bookletId.equals(row.id) & m.deletedAt.isNull()))
        .get();

    Map<String, dynamic> json = const {};
    try {
      json = jsonDecode(row.readJson ?? '{}') as Map<String, dynamic>;
    } catch (_) {}
    return StoredBooklet(
      id: row.id,
      scanId: scanId,
      courseId: row.courseId,
      studentId: row.studentId,
      serialNo: row.serialNo,
      reading: BookletReading.fromJson((json['reading'] as Map?)?.cast<String, dynamic>() ?? const {}),
      engine: json['engine'] as String? ?? 'unknown',
      confirmed: row.status == 'confirmed',
      marks: {for (final m in marks) m.qNo: m.mark},
    );
  }

  /// The booklet confirmed for [studentId] in [courseId], if any, other than
  /// the one for [exceptScanId]. Used to stop the same student being scanned twice.
  Future<StoredBooklet?> confirmedFor(String courseId, String studentId, {String? exceptScanId}) async {
    final rows = await (_db.select(_db.booklets)
          ..where((b) =>
              b.courseId.equals(courseId) &
              b.studentId.equals(studentId) &
              b.status.equals('confirmed') &
              b.deletedAt.isNull()))
        .get();
    for (final r in rows) {
      if (r.scanId != null && r.scanId != exceptScanId) return forScan(r.scanId!);
    }
    return null;
  }

  /// Another confirmed booklet in the course with the same printed number.
  Future<StoredBooklet?> confirmedWithSerial(String courseId, String serialNo, {String? exceptScanId}) async {
    final rows = await (_db.select(_db.booklets)
          ..where((b) =>
              b.courseId.equals(courseId) &
              b.serialNo.equals(serialNo) &
              b.status.equals('confirmed') &
              b.deletedAt.isNull()))
        .get();
    for (final r in rows) {
      if (r.scanId != null && r.scanId != exceptScanId) return forScan(r.scanId!);
    }
    return null;
  }

  /// Stores what the reader found. Never touches a booklet the examiner has
  /// already confirmed, so reading a photo again can not undo a correction.
  Future<void> saveReading({
    required String scanId,
    required String courseId,
    required OcrDocument document,
    required BookletReading reading,
  }) async {
    final existing = await (_db.select(_db.booklets)
          ..where((b) => b.scanId.equals(scanId) & b.deletedAt.isNull()))
        .getSingleOrNull();
    if (existing?.status == 'confirmed') return;

    final json = jsonEncode({
      'engine': document.engine,
      'reading': reading.toJson(),
      'ocr': document.toJson(),
    });
    final now = _now;
    if (existing == null) {
      await _db.into(_db.booklets).insert(BookletsCompanion.insert(
            courseId: courseId,
            id: Value(newId()),
            scanId: Value(scanId),
            serialNo: Value(reading.serialNo),
            readJson: Value(json),
            status: const Value('needs_review'),
            updatedAt: Value(now),
          ));
    } else {
      await (_db.update(_db.booklets)..where((b) => b.id.equals(existing.id))).write(BookletsCompanion(
        serialNo: Value(reading.serialNo),
        readJson: Value(json),
        updatedAt: Value(now),
      ));
    }
  }

  /// Confirms a booklet: stores the examiner's values and puts the exam score
  /// in the score grid, all or nothing.
  Future<void> confirm({
    required String scanId,
    required String courseId,
    required String studentId,
    required String? serialNo,
    required Map<int, double> marks,
    required Set<int> editedMarks,
    required double examScore,
    required String examPartId,
    required String photoPath,
    List<CorrectionDraft> corrections = const [],
  }) =>
      _db.transaction(() async {
        final now = _now;
        var booklet = await (_db.select(_db.booklets)
              ..where((b) => b.scanId.equals(scanId) & b.deletedAt.isNull()))
            .getSingleOrNull();
        String bookletId;
        if (booklet == null) {
          bookletId = newId();
          await _db.into(_db.booklets).insert(BookletsCompanion.insert(
                courseId: courseId,
                id: Value(bookletId),
                scanId: Value(scanId),
                updatedAt: Value(now),
              ));
        } else {
          bookletId = booklet.id;
        }
        await (_db.update(_db.booklets)..where((b) => b.id.equals(bookletId))).write(BookletsCompanion(
          studentId: Value(studentId),
          serialNo: Value(serialNo),
          status: const Value('confirmed'),
          confirmedAt: Value(now),
          updatedAt: Value(now),
        ));

        // Replace the question marks.
        await (_db.update(_db.questionMarks)..where((m) => m.bookletId.equals(bookletId) & m.deletedAt.isNull()))
            .write(QuestionMarksCompanion(deletedAt: Value(now), updatedAt: Value(now)));
        for (final e in marks.entries) {
          await _db.into(_db.questionMarks).insert(QuestionMarksCompanion.insert(
                bookletId: bookletId,
                qNo: e.key,
                mark: e.value,
                id: Value(newId()),
                edited: Value(editedMarks.contains(e.key)),
                updatedAt: Value(now),
              ));
        }

        for (final c in corrections) {
          await _db.into(_db.corrections).insert(CorrectionsCompanion.insert(
                cropPath: photoPath,
                field: c.field,
                id: Value(newId()),
                readValue: Value(c.readValue),
                confirmedValue: Value(c.confirmedValue),
                region: Value(c.region?.encode()),
                updatedAt: Value(now),
              ));
        }

        await _scores.set(
          courseId,
          ScoreWrite(studentId: studentId, partId: examPartId, value: examScore, source: 'scanned'),
        );

        await (_db.update(_db.scans)..where((s) => s.id.equals(scanId))).write(ScansCompanion(
          status: Value(ScanStatus.confirmed.dbValue),
          errorMessage: const Value(null),
          updatedAt: Value(now),
        ));
      });

  /// Sends a confirmed booklet back for editing. Its score stays in the grid
  /// until the examiner confirms again.
  Future<void> reopen(String scanId) async {
    final now = _now;
    await (_db.update(_db.booklets)..where((b) => b.scanId.equals(scanId) & b.deletedAt.isNull()))
        .write(BookletsCompanion(status: const Value('needs_review'), updatedAt: Value(now)));
    await (_db.update(_db.scans)..where((s) => s.id.equals(scanId)))
        .write(ScansCompanion(status: Value(ScanStatus.needsReview.dbValue), updatedAt: Value(now)));
  }
}
