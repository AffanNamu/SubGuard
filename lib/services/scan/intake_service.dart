import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../data/repositories/scan_repository.dart';
import '../../domain/ids.dart';
import '../../domain/scan.dart';
import 'image_source.dart';
import 'scan_files.dart';

class RejectedImage {
  const RejectedImage(this.name, this.reason);
  final String name;

  /// In plain words, with what to do about it.
  final String reason;
}

class DuplicateImage {
  const DuplicateImage(this.picked, this.existing);
  final PickedImage picked;

  /// The photo already stored with the same bytes.
  final ScanItem existing;
}

class IntakeReport {
  const IntakeReport({required this.added, required this.duplicates, required this.rejected});

  final List<ScanItem> added;
  final List<DuplicateImage> duplicates;
  final List<RejectedImage> rejected;

  bool get isEmpty => added.isEmpty && duplicates.isEmpty && rejected.isEmpty;
}

/// Takes the photos the examiner picked, checks each one, keeps the original,
/// and records it in the database as queued.
///
/// Every outcome is reported per photo: added, a duplicate to decide on, or
/// rejected with a reason. Nothing is dropped silently.
class IntakeService {
  IntakeService(this._scans, this._files);

  final ScanRepository _scans;
  final ScanFiles _files;

  static const int maxBytes = 10 * 1024 * 1024;
  static const Set<String> imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'};

  /// Adds [images] to [batchId]. A photo already stored in the same course is
  /// returned as a duplicate instead of being added, unless [addDuplicates].
  Future<IntakeReport> addImages({
    required String courseId,
    required String batchId,
    required List<PickedImage> images,
    bool addDuplicates = false,
  }) async {
    final added = <ScanItem>[];
    final duplicates = <DuplicateImage>[];
    final rejected = <RejectedImage>[];
    final seenInThisRun = <String, ScanItem>{};

    for (final image in images) {
      final rejection = await _check(image);
      if (rejection != null) {
        rejected.add(RejectedImage(image.name, rejection));
        continue;
      }

      final file = File(image.path);
      final hash = (await sha256.bind(file.openRead()).first).toString();

      if (!addDuplicates) {
        final existing = seenInThisRun[hash] ?? await _scans.findByHash(courseId, hash);
        if (existing != null) {
          duplicates.add(DuplicateImage(image, existing));
          continue;
        }
      }

      final size = await _dimensions(file);
      if (size == null) {
        rejected.add(RejectedImage(image.name,
            'This file could not be opened as an image. It may be damaged. Take the photo again.'));
        continue;
      }

      final scanId = newId();
      final extension = p.extension(image.name.isNotEmpty ? image.name : image.path).replaceFirst('.', '').toLowerCase();
      final relative = await _files.store(file, batchId: batchId, scanId: scanId, extension: extension);
      try {
        final item = await _scans.addScan(
          id: scanId,
          courseId: courseId,
          batchId: batchId,
          relativePath: relative,
          originalName: image.name,
          contentHash: hash,
          width: size.width,
          height: size.height,
        );
        added.add(item);
        seenInThisRun[hash] = item;
      } catch (_) {
        // The record could not be written: do not leave an orphan file behind.
        await _files.delete(relative);
        rejected.add(RejectedImage(image.name, 'It could not be saved. Please try again.'));
      }
    }
    return IntakeReport(added: added, duplicates: duplicates, rejected: rejected);
  }

  /// Why [image] cannot be used, or null if it can.
  Future<String?> _check(PickedImage image) async {
    final ext = p.extension(image.name.isNotEmpty ? image.name : image.path).replaceFirst('.', '').toLowerCase();
    if (ext == 'pdf') {
      return 'PDF files are not supported yet. Photograph the booklet, or save its pages as JPG or PNG.';
    }
    if (!imageExtensions.contains(ext)) {
      return 'This file type is not supported. Use a JPG or PNG photo.';
    }
    final file = File(image.path);
    if (!await file.exists()) {
      return 'The file could not be found. It may have been moved or deleted.';
    }
    final length = await file.length();
    if (length == 0) return 'The file is empty.';
    if (length > maxBytes) {
      final mb = (length / (1024 * 1024)).toStringAsFixed(1);
      return 'The file is $mb MB, over the 10 MB limit. Take the photo again at a lower quality setting.';
    }
    return null;
  }

  /// The photo's size in pixels, read without decoding every pixel; null if
  /// the file is not a readable image.
  Future<({int width, int height})?> _dimensions(File file) async {
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(await file.readAsBytes());
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final size = (width: descriptor.width, height: descriptor.height);
      descriptor.dispose();
      buffer.dispose();
      return size.width > 0 && size.height > 0 ? size : null;
    } catch (_) {
      return null;
    }
  }
}
