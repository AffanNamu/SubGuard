import 'package:drift/drift.dart';

import '../../domain/ids.dart';
import '../../domain/scoring.dart';
import '../database/app_database.dart';

typedef ScoreMap = Map<String, Map<String, PartValue>>;

/// One write to the score grid.
class ScoreWrite {
  const ScoreWrite({
    required this.studentId,
    required this.partId,
    this.value,
    this.status = ScoreStatus.entered,
    this.source = 'typed',
  });

  final String studentId;
  final String partId;
  final double? value;
  final ScoreStatus status;

  /// `typed`, `scanned` or `imported`.
  final String source;
}

class ScoreRepository {
  ScoreRepository(this._db);

  final AppDatabase _db;

  DateTime get _now => DateTime.now().toUtc();

  /// studentId -> partId -> value, for live rows only.
  Stream<ScoreMap> watch(String courseId) => (_db.select(_db.partScores)
        ..where((s) => s.courseId.equals(courseId) & s.deletedAt.isNull()))
      .watch()
      .map(_toMap);

  Future<ScoreMap> get(String courseId) async => _toMap(await (_db
          .select(_db.partScores)
        ..where((s) => s.courseId.equals(courseId) & s.deletedAt.isNull()))
      .get());

  ScoreMap _toMap(List<PartScoreRow> rows) {
    final out = <String, Map<String, PartValue>>{};
    for (final r in rows) {
      (out[r.studentId] ??= {})[r.partId] = PartValue(
        value: r.value,
        status: ScoreStatus.fromDb(r.status),
      );
    }
    return out;
  }

  /// The stored value of one cell and where it came from (`typed`, `scanned` or
  /// `imported`), or null if the cell is empty.
  Future<({double? value, ScoreStatus status, String source})?> cell(
      String studentId, String partId) async {
    final r = await (_db.select(_db.partScores)
          ..where((s) => s.studentId.equals(studentId) & s.partId.equals(partId) & s.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
    if (r == null) return null;
    return (value: r.value, status: ScoreStatus.fromDb(r.status), source: r.source);
  }

  /// Writes one cell. A cell with no value and a `missing` status is cleared.
  Future<void> set(String courseId, ScoreWrite w) =>
      _db.transaction(() => _write(courseId, w, _now));

  /// Writes many cells at once, for imports.
  Future<void> setMany(String courseId, Iterable<ScoreWrite> writes) =>
      _db.transaction(() async {
        final now = _now;
        for (final w in writes) {
          await _write(courseId, w, now);
        }
      });

  Future<void> _write(String courseId, ScoreWrite w, DateTime now) async {
    // One row per student per part, whether live or soft-deleted, so the same
    // cell never gets two rows.
    final existing = await (_db.select(_db.partScores)
          ..where((s) => s.studentId.equals(w.studentId) & s.partId.equals(w.partId))
          ..limit(1))
        .getSingleOrNull();

    final clear = w.status == ScoreStatus.missing && w.value == null;
    final value = w.status == ScoreStatus.entered ? w.value : null;

    if (existing == null) {
      if (clear) return;
      await _db.into(_db.partScores).insert(PartScoresCompanion.insert(
            courseId: courseId,
            studentId: w.studentId,
            partId: w.partId,
            id: Value(newId()),
            value: Value(value),
            status: Value(w.status.dbValue),
            source: Value(w.source),
            updatedAt: Value(now),
          ));
      return;
    }

    await (_db.update(_db.partScores)..where((s) => s.id.equals(existing.id))).write(
      PartScoresCompanion(
        value: Value(value),
        status: Value(clear ? ScoreStatus.missing.dbValue : w.status.dbValue),
        source: Value(w.source),
        updatedAt: Value(now),
        deletedAt: Value(clear ? now : null),
      ),
    );
  }
}
