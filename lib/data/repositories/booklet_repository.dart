import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/ids.dart';
import '../../domain/ocr.dart';
import '../../domain/scan.dart';
import '../../services/reader/booklet_extractor.dart';
import '../database/app_database.dart';
import 'recognition_repository.dart';
import 'score_repository.dart';

/// One confirmed question-mark record: the question number and the mark the examiner
/// confirmed, with what the reader had returned for each (kept apart from them), the
/// maximum, how the examiner arrived at it, and where on the photograph it is.
class ConfirmedMark {
  const ConfirmedMark({
    required this.qNo,
    required this.mark,
    this.edited = false,
    this.status = 'entered',
    this.recognisedMark,
    this.recognisedQuestion,
    this.maxMark,
    this.region,
    this.questionRegion,
  });

  final int qNo;
  final double mark;
  final bool edited;

  /// `accepted`, `edited` or `entered` (see the `question_mark.status` column).
  final String status;
  final String? recognisedMark;
  final String? recognisedQuestion;
  final double? maxMark;
  final Region? region;
  final Region? questionRegion;
}

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
    this.records = const [],
    this.calculatedTotal,
    this.writtenTotal,
    this.maxTotal,
    this.totalNotes = const [],
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

  /// The same marks as separate records, with what was read, the maximum, status and place.
  final List<ConfirmedMark> records;

  /// The exam score worked out from the confirmed marks when the booklet was
  /// confirmed (derived), the total the examiner wrote in the booklet (null: none
  /// recorded), the most the questions could add, and what was assumed.
  final double? calculatedTotal;
  final double? writtenTotal;
  final double? maxTotal;
  final List<String> totalNotes;
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
      records: [
        for (final m in marks)
          ConfirmedMark(
            qNo: m.qNo,
            mark: m.mark,
            edited: m.edited,
            status: m.status,
            recognisedMark: m.recognisedMark,
            recognisedQuestion: m.recognisedQuestion,
            maxMark: m.maxMark,
            region: Region.decode(m.region),
            questionRegion: Region.decode(m.questionRegion),
          ),
      ]..sort((a, b) => a.qNo.compareTo(b.qNo)),
      calculatedTotal: row.calculatedTotal,
      writtenTotal: row.writtenTotal,
      maxTotal: row.maxTotal,
      totalNotes: _notes(row.totalNotes),
    );
  }

  static List<String> _notes(String? json) {
    if (json == null) return const [];
    try {
      return [for (final n in jsonDecode(json) as List) n as String];
    } catch (_) {
      return const [];
    }
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
    List<FieldReviewDraft> reviews = const [],
    String? runId,

    /// The marks as full records. When absent each entry of [marks] is stored as a
    /// record with nothing but its number, mark and whether it was edited.
    List<ConfirmedMark>? records,

    /// The calculated total (derived), the written total (null when none was
    /// recorded), the maximum and the assumptions. [examScore] is what goes in the grid.
    double? calculatedTotal,
    double? writtenTotal,
    double? maxTotal,
    List<String> totalNotes = const [],
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
          calculatedTotal: Value(calculatedTotal ?? examScore),
          writtenTotal: Value(writtenTotal),
          maxTotal: Value(maxTotal),
          totalNotes: Value(totalNotes.isEmpty ? null : jsonEncode(totalNotes)),
          updatedAt: Value(now),
        ));

        // Replace the question marks.
        await (_db.update(_db.questionMarks)..where((m) => m.bookletId.equals(bookletId) & m.deletedAt.isNull()))
            .write(QuestionMarksCompanion(deletedAt: Value(now), updatedAt: Value(now)));
        final toStore = records ??
            [
              for (final e in marks.entries)
                ConfirmedMark(qNo: e.key, mark: e.value, edited: editedMarks.contains(e.key), status: editedMarks.contains(e.key) ? 'edited' : 'entered'),
            ];
        for (final r in toStore) {
          await _db.into(_db.questionMarks).insert(QuestionMarksCompanion.insert(
                bookletId: bookletId,
                qNo: r.qNo,
                mark: r.mark,
                id: Value(newId()),
                edited: Value(r.edited),
                recognisedMark: Value(r.recognisedMark),
                recognisedQuestion: Value(r.recognisedQuestion),
                maxMark: Value(r.maxMark),
                status: Value(r.status),
                region: Value(r.region?.encode()),
                questionRegion: Value(r.questionRegion?.encode()),
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

        // The examiner's decision on every field, with when: the audit trail,
        // and a labelled example for each piece of writing that has a place on
        // the photo.
        for (final r in reviews) {
          await _db.into(_db.fieldReviews).insert(FieldReviewsCompanion.insert(
                scanId: scanId,
                fieldKey: r.fieldKey,
                kind: r.kind,
                decision: r.decision,
                reviewedAt: now,
                id: Value(newId()),
                runId: Value(runId),
                machineValue: Value(r.machineValue),
                machineState: Value(r.machineState),
                finalValue: Value(r.finalValue),
                region: Value(r.region?.encode()),
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
