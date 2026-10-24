import 'dart:async';

import '../../data/repositories/booklet_repository.dart';
import '../../data/repositories/scan_repository.dart';
import '../../data/repositories/student_repository.dart';
import '../../domain/models.dart';
import '../../domain/ocr.dart';
import '../../domain/scan.dart';
import '../scan/scan_files.dart';
import 'booklet_extractor.dart';
import 'ocr_engine.dart';

/// Works through the queued photos of a batch, one at a time: reads each,
/// finds the printed labels, stores what was found, and hands it to the
/// examiner. It never marks anything confirmed and never fills in a value it
/// could not read.
class ScanProcessor {
  ScanProcessor({
    required ScanRepository scans,
    required BookletRepository booklets,
    required ScanFiles files,
    required OcrEngine engine,
    StudentRepository? students,
    BookletExtractor extractor = const BookletExtractor(),
    this.perPhotoTimeout = const Duration(seconds: 60),
  })  : _scans = scans,
        _booklets = booklets,
        _files = files,
        _engine = engine,
        _students = students,
        _extractor = extractor;

  final ScanRepository _scans;
  final BookletRepository _booklets;
  final ScanFiles _files;
  final OcrEngine _engine;
  final StudentRepository? _students;
  final BookletExtractor _extractor;
  final Duration perPhotoTimeout;

  /// Reads every queued photo in [batchId]. Stops after the current photo when
  /// [shouldStop] returns true; the rest stay queued. [onProgress] gets the
  /// number finished and the number to do in this run.
  Future<void> processBatch(
    String batchId, {
    bool Function()? shouldStop,
    void Function(int done, int total)? onProgress,
  }) async {
    final queued = (await _scans.scansOf(batchId)).where((s) => s.status == ScanStatus.queued).toList();
    var done = 0;
    onProgress?.call(0, queued.length);
    for (final scan in queued) {
      if (shouldStop?.call() ?? false) break;
      await processOne(scan);
      done++;
      onProgress?.call(done, queued.length);
    }
  }

  Future<void> processOne(ScanItem scan) async {
    await _scans.setStatus(scan.id, ScanStatus.processing);

    final file = _files.resolve(scan.relativePath);
    if (!await file.exists()) {
      await _scans.setStatus(scan.id, ScanStatus.failed,
          error: 'The photo file is missing from this phone, so it cannot be read. Remove it and add the photo again.');
      return;
    }

    OcrDocument document;
    try {
      document = await _engine
          .recognize(file, width: scan.width ?? 0, height: scan.height ?? 0)
          .timeout(perPhotoTimeout);
    } catch (e) {
      // The photo is fine; only the automatic reading failed. The examiner can
      // still enter the values from it, so this is a review, not a failure.
      document = OcrDocument(
        engine: _engine.name,
        lines: const [],
        note: e is TimeoutException
            ? 'Reading took too long. Enter the values from the photo.'
            : 'Automatic reading failed. Enter the values from the photo.',
      );
    }

    // First pass finds the printed labels and so where the exam number is;
    // second pass reads just that area, close up, and matches it to the class list.
    final classList = [for (final s in await _students?.getAll(scan.courseId) ?? const <Student>[]) s.regNo];
    var reading = _extractor.extract(document, classList: classList);
    final region = reading.examNumberRegion;
    final engine = _engine;
    if (region != null && engine is RegionOcrEngine) {
      try {
        final crop = await engine.recognizeRegion(file, region).timeout(perPhotoTimeout);
        reading = _extractor.extract(document, examNumberCrop: crop, classList: classList);
      } catch (_) {
        // The close-up failed; the whole-photo reading stands.
      }
    }
    try {
      await _booklets.saveReading(
        scanId: scan.id,
        courseId: scan.courseId,
        document: document,
        reading: reading,
      );
      await _scans.setStatus(scan.id, ScanStatus.needsReview);
    } catch (_) {
      // Nothing was stored for this photo, so put it back for another try.
      await _scans.setStatus(scan.id, ScanStatus.queued);
      rethrow;
    }
  }
}
