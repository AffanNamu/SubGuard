import 'dart:async';

import '../../data/repositories/booklet_repository.dart';
import '../../data/repositories/course_repository.dart';
import '../../data/repositories/recognition_repository.dart';
import '../../data/repositories/scan_repository.dart';
import '../../data/repositories/student_repository.dart';
import '../../domain/models.dart';
import '../../domain/ocr.dart';
import '../../domain/scan.dart';
import '../recognition/interfaces.dart';
import '../recognition/validation.dart';
import '../scan/scan_files.dart';
import 'booklet_extractor.dart';

/// Works through the queued photos of a batch, one at a time: runs the
/// recognition pipeline on each, stores what it found (kept exactly as
/// produced), and hands it to the examiner. It never marks anything confirmed
/// and never fills in a value the pipeline did not read.
///
/// One photo at a time is deliberate: a phone cannot hold several full-size
/// photos in memory, and the pipeline already uses background isolates for its
/// heavy stages. Each photo is isolated from the others: one that fails is
/// marked failed with the reason and the batch carries on.
class ScanProcessor {
  ScanProcessor({
    required this._scans,
    required this._booklets,
    required this._files,
    required this._pipeline,
    this._recognitions,
    this._students,
    this._courses,
    this.perPhotoTimeout = const Duration(minutes: 3),
  });

  final ScanRepository _scans;
  final BookletRepository _booklets;
  final ScanFiles _files;

  /// Built on first use (it loads the handwriting model).
  final Future<RecognitionOrchestrator> Function() _pipeline;
  final RecognitionRepository? _recognitions;
  final StudentRepository? _students;
  final CourseRepository? _courses;

  /// A safety net for a photo that never finishes. The pipeline has its own,
  /// shorter limits on the text reader; this stops anything else that hangs.
  final Duration perPhotoTimeout;

  /// Reads every queued photo in [batchId]. Stops after the photo in hand when
  /// [shouldStop] returns true; the rest stay queued. [onProgress] gets the number finished and the number
  /// to do in this run.
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
      try {
        await processOne(scan);
      } on RecognitionCancelled {
        // Put back for the next run; nothing was stored for it.
        await _safely(() => _scans.setStatus(scan.id, ScanStatus.queued));
        break;
      } catch (_) {
        // Whatever went wrong with this photo does not stop the others.
        await _safely(() => _scans.setStatus(scan.id, ScanStatus.failed,
            error: 'This photo could not be read because of an unexpected problem. Try again, or remove it and add the photo again.'));
      }
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

    final classList = [for (final s in await _students?.getAll(scan.courseId) ?? const <Student>[]) s.regNo];
    final course = await _courses?.get(scan.courseId);
    final validator = course == null ? null : SchemeExaminationValidator(course.scheme);

    RecognitionResult result;
    var abandoned = false;
    try {
      final pipeline = await _pipeline();
      result = await pipeline
          .run(
            file,
            classList: classList,
            validator: validator,
            isCancelled: () => abandoned,
          )
          .timeout(perPhotoTimeout);
    } on RecognitionCancelled {
      rethrow;
    } on RecognitionException catch (e) {
      // The photo itself cannot be used: not a picture, too large, unreadable.
      await _scans.setStatus(scan.id, ScanStatus.failed, error: e.message);
      return;
    } catch (e) {
      // The photo is fine; the automatic reading failed or did not finish. The
      // examiner can still enter the values from it, so this is a review.
      abandoned = true;
      await _store(
        scan,
        null,
        OcrDocument(
          engine: 'none',
          lines: const [],
          note: e is TimeoutException
              ? 'Reading took too long. Enter the values from the photo.'
              : 'Automatic reading failed. Enter the values from the photo.',
        ),
      );
      return;
    }
    await _store(scan, result, result.printed);
  }

  /// Stores the result and moves the photo to review. [result] is null when
  /// there is none (the run failed or timed out): only the note is kept.
  Future<void> _store(ScanItem scan, RecognitionResult? result, OcrDocument printed) async {
    try {
      final reading = result?.layout ?? const BookletExtractor().extract(printed);
      await _booklets.saveReading(scanId: scan.id, courseId: scan.courseId, document: printed, reading: reading);
      if (result != null) await _recognitions?.saveRun(scan.id, result);
      await _scans.setStatus(scan.id, ScanStatus.needsReview);
    } catch (_) {
      // Nothing was stored for this photo; the batch marks it failed, with the
      // reason, and carries on with the others.
      rethrow;
    }
  }

  Future<void> _safely(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {}
  }
}
