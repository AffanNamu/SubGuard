import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/data/database/app_database.dart';
import 'package:unimarkly/data/repositories/review_draft_repository.dart';
import 'package:unimarkly/domain/review_draft.dart';

/// Unconfirmed entries are kept so an interrupted review is not lost, and are
/// kept apart from everything the score grid and the exports read.
void main() {
  group('ReviewDraft', () {
    const full = ReviewDraft(
      examNumber: 'FWM/24U/0538',
      serial: '292011',
      marks: {1: 5.5, 2: null, 4: 0},
      editedMarks: {1, 4},
      writtenTotal: 12.5,
      addExtra: true,
      allowDuplicate: true,
      dismissedRows: {'mark_row_3', 'mark_row_1'},
      runId: 'run-1',
      chosenText: 'FWM/24U/0538',
      chosenSource: 'class list',
      chosenNote: 'the only class-list number within 1 character of what was read',
    );

    test('survives being written and read back, including a mark cleared to nothing', () {
      final back = ReviewDraft.decode(full.encode())!;
      expect(back.examNumber, 'FWM/24U/0538');
      expect(back.serial, '292011');
      expect(back.marks, {1: 5.5, 2: null, 4: 0.0});
      expect(back.marks.containsKey(2), isTrue, reason: 'a cleared mark is different from a mark never entered');
      expect(back.editedMarks, {1, 4});
      expect(back.writtenTotal, 12.5);
      expect(back.addExtra, isTrue);
      expect(back.allowDuplicate, isTrue);
      expect(back.dismissedRows, {'mark_row_1', 'mark_row_3'});
      expect(back.runId, 'run-1');
      expect(back.chosenText, 'FWM/24U/0538');
      expect(back.chosenSource, 'class list');
      expect(back.chosenNote, contains('within 1 character'));
    });

    test('is written the same way every time, so an unchanged draft compares equal', () {
      final a = const ReviewDraft(marks: {2: 1, 1: 2}, editedMarks: {2, 1});
      final b = const ReviewDraft(marks: {2: 1, 1: 2}, editedMarks: {1, 2});
      expect(a.encode(), b.encode());
    });

    test('damaged, empty or unknown-version text is no draft, never half a draft', () {
      expect(ReviewDraft.decode(null), isNull);
      expect(ReviewDraft.decode(''), isNull);
      expect(ReviewDraft.decode('{not json'), isNull);
      expect(ReviewDraft.decode('[]'), isNull);
      expect(ReviewDraft.decode('{"v":3,"examNumber":"X"}'), isNull);
      expect(ReviewDraft.decode('{"v":1,"marks":{"one":3}}'), isNull);
    });
  });

  group('ReviewDraftRepository', () {
    late AppDatabase db;
    late ReviewDraftRepository drafts;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      drafts = ReviewDraftRepository(db);
      await db.customStatement("INSERT INTO course (id, updated_at, code) VALUES ('c1', '2026-09-01T10:00:00.000Z', 'AGR 114')");
      await db.customStatement("INSERT INTO upload_batch (id, updated_at, course_id, created_at) VALUES ('b1', '2026-09-01T10:00:00.000Z', 'c1', '2026-09-01T10:00:00.000Z')");
      for (final id in ['sc1', 'sc2']) {
        await db.customStatement("INSERT INTO scan (id, updated_at, course_id, kind, photo_path, page_no, status, created_at, batch_id, content_hash) "
            "VALUES ('$id', '2026-09-01T10:00:00.000Z', 'c1', 'booklet_cover', 'scans/$id.jpg', 1, 'needs_review', '2026-09-01T10:00:00.000Z', 'b1', 'h$id')");
      }
    });
    tearDown(() => db.close());

    test('keeps one draft per booklet and replaces it when saved again', () async {
      expect(await drafts.load('sc1'), isNull);
      await drafts.save('sc1', const ReviewDraft(examNumber: 'FWM/24U/0538'));
      await drafts.save('sc1', const ReviewDraft(examNumber: 'FWM/24U/0539', marks: {1: 3}));
      await drafts.save('sc2', const ReviewDraft(examNumber: 'FWM/24U/0540'));

      final one = (await drafts.load('sc1'))!;
      expect(one.draft.examNumber, 'FWM/24U/0539');
      expect(one.draft.marks, {1: 3.0});
      expect(one.savedAt.difference(DateTime.now()).inMinutes.abs(), lessThan(2));
      expect((await drafts.load('sc2'))!.draft.examNumber, 'FWM/24U/0540');
      expect(await db.select(db.reviewDrafts).get(), hasLength(2));
      expect(await drafts.count(), 2);
    });

    test('delete removes it from view and keeps the row, like every other record', () async {
      await drafts.save('sc1', const ReviewDraft(examNumber: 'FWM/24U/0538'));
      await drafts.delete('sc1');
      expect(await drafts.load('sc1'), isNull);
      expect(await drafts.count(), 0);
      expect(await db.select(db.reviewDrafts).get(), hasLength(1), reason: 'soft-deleted');
      // A fresh draft after a delete is a new live row.
      await drafts.save('sc1', const ReviewDraft(examNumber: 'FWM/24U/0539'));
      expect((await drafts.load('sc1'))!.draft.examNumber, 'FWM/24U/0539');
    });

    test('a damaged stored draft loads as no draft', () async {
      await db.into(db.reviewDrafts).insert(ReviewDraftsCompanion.insert(scanId: 'sc1', draftJson: '{oops', id: const Value('d1')));
      expect(await drafts.load('sc1'), isNull);
    });

    test('two live rows for one booklet (a save race) load as the newer one', () async {
      await db.into(db.reviewDrafts).insert(ReviewDraftsCompanion.insert(
          scanId: 'sc1', draftJson: const ReviewDraft(examNumber: 'OLD').encode(), id: const Value('d1'), updatedAt: Value(DateTime.utc(2026, 10, 1))));
      await db.into(db.reviewDrafts).insert(ReviewDraftsCompanion.insert(
          scanId: 'sc1', draftJson: const ReviewDraft(examNumber: 'NEW').encode(), id: const Value('d2'), updatedAt: Value(DateTime.utc(2026, 10, 2))));
      expect((await drafts.load('sc1'))!.draft.examNumber, 'NEW');
    });

    test('a draft writes nothing to the booklet, mark or score tables', () async {
      await drafts.save('sc1', const ReviewDraft(examNumber: 'FWM/24U/0538', marks: {1: 5.5}));
      expect(await db.select(db.booklets).get(), isEmpty);
      expect(await db.select(db.questionMarks).get(), isEmpty);
      expect(await db.select(db.partScores).get(), isEmpty);
      expect(await db.select(db.fieldReviews).get(), isEmpty);
    });
  });
}
