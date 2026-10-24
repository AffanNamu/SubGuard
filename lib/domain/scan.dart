import 'models.dart';

/// Where one photo is in the workflow:
/// Upload -> Read -> Review -> Confirm.
enum ScanStatus {
  /// Stored, waiting to be read.
  queued('queued'),

  /// Being read right now.
  processing('processing'),

  /// Read (or could not be read automatically) and waiting for the examiner.
  /// Nothing counts as a result until it is confirmed.
  needsReview('needs_review'),

  /// The examiner confirmed it; its marks are in the score grid.
  confirmed('confirmed'),

  /// The photo could not be used. [ScanItem.errorMessage] says why.
  failed('failed');

  const ScanStatus(this.dbValue);
  final String dbValue;

  static ScanStatus fromDb(String? value) => switch (value) {
        'queued' => queued,
        'processing' => processing,
        'confirmed' => confirmed,
        'failed' => failed,
        // 'scanned' is what version 1 of the app wrote.
        'needs_review' || 'scanned' => needsReview,
        _ => queued,
      };
}

/// The state of a whole upload, worked out from its photos, never stored, so
/// it can not disagree with them.
enum BatchStatus {
  empty('No images'),
  queued('Queued'),
  processing('Processing'),
  needsReview('Need review'),
  partial('Partly done'),
  completed('Completed'),
  failed('Failed');

  const BatchStatus(this.label);
  final String label;

  static BatchStatus from(BatchCounts c) {
    if (c.images == 0) return empty;
    if (c.processing > 0) return processing;
    if (c.queued > 0) return queued;
    if (c.failed == c.images) return failed;
    if (c.failed > 0 && c.needsReview == 0) return partial;
    if (c.needsReview > 0) return needsReview;
    return completed;
  }
}

class BatchCounts {
  const BatchCounts({
    this.images = 0,
    this.queued = 0,
    this.processing = 0,
    this.needsReview = 0,
    this.confirmed = 0,
    this.failed = 0,
  });

  final int images;
  final int queued;
  final int processing;
  final int needsReview;
  final int confirmed;
  final int failed;

  /// Photos that have produced, or will produce, a student record.
  int get records => images - failed;
}

class ScanItem {
  const ScanItem({
    required this.id,
    required this.courseId,
    required this.batchId,
    required this.relativePath,
    required this.originalName,
    required this.contentHash,
    required this.width,
    required this.height,
    required this.status,
    required this.errorMessage,
    required this.createdAt,
  });

  final String id;
  final String courseId;
  final String? batchId;

  /// Relative to the app's scan folder, so a backup restores to any phone.
  final String relativePath;
  final String? originalName;
  final String? contentHash;
  final int? width;
  final int? height;
  final ScanStatus status;
  final String? errorMessage;
  final DateTime createdAt;

  String get displayName => originalName ?? 'Image';
}

class BatchSummary {
  const BatchSummary({
    required this.id,
    required this.course,
    required this.title,
    required this.createdAt,
    required this.counts,
    this.coverPath,
  });

  final String id;
  final Course course;
  final String? title;
  final DateTime createdAt;
  final BatchCounts counts;

  /// The first photo of the batch, relative to the scan folder, for its thumbnail.
  final String? coverPath;

  BatchStatus get status => BatchStatus.from(counts);
}

/// Numbers for the home screen, all counted from stored records.
class ScanStats {
  const ScanStats({
    this.batches = 0,
    this.records = 0,
    this.confirmed = 0,
    this.needReview = 0,
  });

  /// Uploads made.
  final int batches;

  /// Booklet photos that were read or are waiting to be read.
  final int records;

  /// Booklets the examiner has confirmed.
  final int confirmed;

  /// Booklets waiting for the examiner.
  final int needReview;
}
