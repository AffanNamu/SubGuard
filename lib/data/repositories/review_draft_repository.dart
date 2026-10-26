import 'package:drift/drift.dart';

import '../../domain/ids.dart';
import '../../domain/review_draft.dart';
import '../database/app_database.dart';

/// Stores the examiner's unconfirmed entries, one draft per booklet.
class ReviewDraftRepository {
  ReviewDraftRepository(this._db);

  final AppDatabase _db;

  /// The newest live draft row (two saves racing can leave two; the newer wins).
  Future<ReviewDraftRow?> _row(String scanId) => (_db.select(_db.reviewDrafts)
        ..where((d) => d.scanId.equals(scanId) & d.deletedAt.isNull())
        ..orderBy([(d) => OrderingTerm.desc(d.updatedAt)])
        ..limit(1))
      .getSingleOrNull();

  /// The saved draft with when it was saved, or null.
  Future<({ReviewDraft draft, DateTime savedAt})?> load(String scanId) async {
    final row = await _row(scanId);
    final draft = ReviewDraft.decode(row?.draftJson);
    if (row == null || draft == null) return null;
    return (draft: draft, savedAt: row.updatedAt);
  }

  Future<void> save(String scanId, ReviewDraft draft) async {
    final now = DateTime.now().toUtc();
    final existing = await _row(scanId);
    if (existing == null) {
      await _db.into(_db.reviewDrafts).insert(ReviewDraftsCompanion.insert(
            scanId: scanId,
            draftJson: draft.encode(),
            id: Value(newId()),
            updatedAt: Value(now),
          ));
    } else {
      await (_db.update(_db.reviewDrafts)..where((d) => d.id.equals(existing.id)))
          .write(ReviewDraftsCompanion(draftJson: Value(draft.encode()), updatedAt: Value(now)));
    }
  }

  /// Removes the draft (the booklet was confirmed or rejected, or the examiner
  /// discarded it). Soft-deleted like every other row.
  Future<void> delete(String scanId) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.reviewDrafts)..where((d) => d.scanId.equals(scanId) & d.deletedAt.isNull()))
        .write(ReviewDraftsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
  }

  /// How many booklets have a draft waiting.
  Future<int> count() async => (await (_db.select(_db.reviewDrafts)..where((d) => d.deletedAt.isNull())).get()).length;
}
