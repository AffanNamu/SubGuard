import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:unimarkly/data/database/app_database.dart';
import 'package:unimarkly/data/repositories/course_repository.dart';
import 'package:unimarkly/data/repositories/scan_repository.dart';
import 'package:unimarkly/domain/defaults.dart';
import 'package:unimarkly/domain/ids.dart';
import 'package:unimarkly/domain/models.dart';
import 'package:unimarkly/domain/scan.dart';
import 'package:unimarkly/services/scan/image_source.dart';
import 'package:unimarkly/services/scan/intake_service.dart';
import 'package:unimarkly/services/scan/scan_files.dart';

import '../support/images.dart';

void main() {
  late AppDatabase db;
  late CourseRepository courses;
  late ScanRepository scans;
  late IntakeService intake;
  late ScanFiles files;
  late Directory work;
  late Course course;
  late String batchId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    courses = CourseRepository(db);
    scans = ScanRepository(db, courses);
    work = Directory.systemTemp.createTempSync('unimarkly_intake_');
    files = ScanFiles(Directory(p.join(work.path, 'scans')));
    intake = IntakeService(scans, files);
    course = Course(id: newId(), code: 'AGR 114', department: 'FWM', scheme: Defaults.nigerianScheme());
    await courses.save(course);
    batchId = await scans.createBatch(course.id);
  });

  tearDown(() async {
    await db.close();
    work.deleteSync(recursive: true);
  });

  Future<PickedImage> pngFile(String name, {int w = 120, int h = 160, ui.Color color = const ui.Color(0xFF223344)}) async {
    final f = File(p.join(work.path, name));
    await f.writeAsBytes(await makePng(w, h, color));
    return PickedImage(name: name, path: f.path);
  }

  test('keeps the original, records its size and fingerprint, and queues it', () async {
    final pick = await pngFile('IMG_001.png', w: 300, h: 400);
    final report = await intake.addImages(courseId: course.id, batchId: batchId, images: [pick]);

    expect(report.rejected, isEmpty);
    expect(report.duplicates, isEmpty);
    final item = report.added.single;
    expect(item.status, ScanStatus.queued);
    expect(item.originalName, 'IMG_001.png');
    expect(item.width, 300);
    expect(item.height, 400);
    expect(item.contentHash, hasLength(64));
    expect(item.batchId, batchId);

    // The stored copy is byte-for-byte the original, under the batch folder.
    final stored = files.resolve(item.relativePath);
    expect(item.relativePath, startsWith(batchId));
    expect(await stored.readAsBytes(), await File(pick.path).readAsBytes());

    // And it is in the database, so it survives a restart.
    expect((await scans.scansOf(batchId)).single.id, item.id);
  });

  test('several photos are tracked independently in one batch', () async {
    final picks = [
      await pngFile('a.png', color: const ui.Color(0xFF111111)),
      await pngFile('b.png', color: const ui.Color(0xFF222222)),
      await pngFile('c.png', color: const ui.Color(0xFF333333)),
    ];
    final report = await intake.addImages(courseId: course.id, batchId: batchId, images: picks);
    expect(report.added, hasLength(3));
    expect(report.added.map((s) => s.id).toSet(), hasLength(3));

    await scans.setStatus(report.added[0].id, ScanStatus.needsReview);
    await scans.setStatus(report.added[1].id, ScanStatus.failed, error: 'Unreadable');
    final batch = (await scans.batches()).single;
    expect(batch.counts.images, 3);
    expect(batch.counts.needsReview, 1);
    expect(batch.counts.failed, 1);
    expect(batch.counts.queued, 1);
    expect(batch.status, BatchStatus.queued, reason: 'one photo still waits');
  });

  group('rejections say why', () {
    test('a PDF', () async {
      final f = File(p.join(work.path, 'booklet.pdf'))..writeAsBytesSync([37, 80, 68, 70]);
      final r = await intake.addImages(
          courseId: course.id, batchId: batchId, images: [PickedImage(name: 'booklet.pdf', path: f.path)]);
      expect(r.added, isEmpty);
      expect(r.rejected.single.reason, contains('PDF'));
      expect(r.rejected.single.reason, contains('not supported yet'));
    });

    test('an unsupported type', () async {
      final f = File(p.join(work.path, 'notes.docx'))..writeAsBytesSync([1, 2, 3]);
      final r = await intake.addImages(
          courseId: course.id, batchId: batchId, images: [PickedImage(name: 'notes.docx', path: f.path)]);
      expect(r.rejected.single.reason, contains('type is not supported'));
    });

    test('a damaged image', () async {
      final f = File(p.join(work.path, 'broken.jpg'))..writeAsBytesSync(List.generate(500, (i) => i % 251));
      final r = await intake.addImages(
          courseId: course.id, batchId: batchId, images: [PickedImage(name: 'broken.jpg', path: f.path)]);
      expect(r.added, isEmpty);
      expect(r.rejected.single.reason, contains('could not be opened'));
      expect(await scans.scansOf(batchId), isEmpty);
      expect(await files.bytesUsed(), 0, reason: 'a rejected file leaves nothing behind');
    });

    test('an empty file', () async {
      final f = File(p.join(work.path, 'empty.png'))..writeAsBytesSync([]);
      final r = await intake.addImages(
          courseId: course.id, batchId: batchId, images: [PickedImage(name: 'empty.png', path: f.path)]);
      expect(r.rejected.single.reason, 'The file is empty.');
    });

    test('a file over 10 MB', () async {
      final f = File(p.join(work.path, 'huge.jpg'))..writeAsBytesSync(Uint8List(IntakeService.maxBytes + 1));
      final r = await intake.addImages(
          courseId: course.id, batchId: batchId, images: [PickedImage(name: 'huge.jpg', path: f.path)]);
      expect(r.rejected.single.reason, contains('10 MB limit'));
    });

    test('a file that is not there', () async {
      final r = await intake.addImages(
          courseId: course.id, batchId: batchId, images: const [PickedImage(name: 'gone.png', path: '/no/such/gone.png')]);
      expect(r.rejected.single.reason, contains('could not be found'));
    });

    test('one bad photo does not stop the good ones', () async {
      final good = await pngFile('good.png');
      final bad = File(p.join(work.path, 'bad.pdf'))..writeAsBytesSync([1]);
      final r = await intake.addImages(
          courseId: course.id, batchId: batchId, images: [PickedImage(name: 'bad.pdf', path: bad.path), good]);
      expect(r.added.single.originalName, 'good.png');
      expect(r.rejected.single.name, 'bad.pdf');
    });
  });

  group('duplicates', () {
    test('the same photo twice in one pick is reported, not added twice', () async {
      final a = await pngFile('a.png');
      final copy = File(a.path).copySync(p.join(work.path, 'a_copy.png'));
      final r = await intake.addImages(
          courseId: course.id,
          batchId: batchId,
          images: [a, PickedImage(name: 'a_copy.png', path: copy.path)]);
      expect(r.added, hasLength(1));
      expect(r.duplicates.single.picked.name, 'a_copy.png');
      expect(r.duplicates.single.existing.originalName, 'a.png');
    });

    test('a photo added in an earlier upload is found, in any batch of the course', () async {
      final a = await pngFile('a.png');
      await intake.addImages(courseId: course.id, batchId: batchId, images: [a]);

      final second = await scans.createBatch(course.id);
      final r = await intake.addImages(courseId: course.id, batchId: second, images: [a]);
      expect(r.added, isEmpty);
      expect(r.duplicates, hasLength(1));
    });

    test('the examiner can add it anyway', () async {
      final a = await pngFile('a.png');
      await intake.addImages(courseId: course.id, batchId: batchId, images: [a]);
      final r = await intake.addImages(courseId: course.id, batchId: batchId, images: [a], addDuplicates: true);
      expect(r.added, hasLength(1));
      expect(await scans.scansOf(batchId), hasLength(2));
    });

    test('the same photo in a different course is not a duplicate', () async {
      final a = await pngFile('a.png');
      await intake.addImages(courseId: course.id, batchId: batchId, images: [a]);

      final other = Course(id: newId(), code: 'BIO 201', scheme: Defaults.nigerianScheme());
      await courses.save(other);
      final otherBatch = await scans.createBatch(other.id);
      final r = await intake.addImages(courseId: other.id, batchId: otherBatch, images: [a]);
      expect(r.added, hasLength(1));
    });
  });

  group('recovery and removal', () {
    test('photos left processing by a closed app go back to the queue', () async {
      final r = await intake.addImages(
          courseId: course.id, batchId: batchId, images: [await pngFile('a.png'), await pngFile('b.png', color: const ui.Color(0xFF999999))]);
      await scans.setStatus(r.added[0].id, ScanStatus.processing);
      await scans.setStatus(r.added[1].id, ScanStatus.needsReview);

      expect(await scans.requeueInterrupted(), 1);
      final now = await scans.scansOf(batchId);
      expect(now.firstWhere((s) => s.id == r.added[0].id).status, ScanStatus.queued);
      expect(now.firstWhere((s) => s.id == r.added[1].id).status, ScanStatus.needsReview,
          reason: 'finished work is left alone');
    });

    test('removing a photo takes it out of the batch and can be undone', () async {
      final r = await intake.addImages(courseId: course.id, batchId: batchId, images: [await pngFile('a.png')]);
      await scans.remove(r.added.single.id);
      expect(await scans.scansOf(batchId), isEmpty);
      await scans.restore(r.added.single.id);
      expect(await scans.scansOf(batchId), hasLength(1));
    });
  });

  group('batch status', () {
    BatchStatus of({int images = 0, int queued = 0, int processing = 0, int review = 0, int confirmed = 0, int failed = 0}) =>
        BatchStatus.from(BatchCounts(
            images: images, queued: queued, processing: processing, needsReview: review, confirmed: confirmed, failed: failed));

    test('is worked out from the photos', () {
      expect(of(), BatchStatus.empty);
      expect(of(images: 3, queued: 3), BatchStatus.queued);
      expect(of(images: 3, processing: 1, queued: 2), BatchStatus.processing);
      expect(of(images: 3, review: 2, confirmed: 1), BatchStatus.needsReview);
      expect(of(images: 3, confirmed: 3), BatchStatus.completed);
      expect(of(images: 3, failed: 3), BatchStatus.failed);
      expect(of(images: 3, confirmed: 2, failed: 1), BatchStatus.partial);
    });

    test('a batch is not completed just because reading finished', () {
      expect(of(images: 5, review: 5), isNot(BatchStatus.completed));
    });
  });

  test('a course in the bin takes its batches out of the list', () async {
    await intake.addImages(courseId: course.id, batchId: batchId, images: [await pngFile('a.png')]);
    expect(await scans.batches(), hasLength(1));
    await courses.softDelete(course.id);
    expect(await scans.batches(), isEmpty);
    await courses.restore(course.id);
    expect(await scans.batches(), hasLength(1));
  });
}
