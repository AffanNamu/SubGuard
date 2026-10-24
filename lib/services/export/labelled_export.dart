import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

import '../../data/repositories/recognition_repository.dart';
import '../scan/scan_files.dart';
import '../vision/photo_codec.dart';

/// What was written to the file, for telling the examiner.
class LabelledExportResult {
  const LabelledExportResult({required this.file, required this.examples, required this.skipped});

  final File file;
  final int examples;

  /// Examples left out because their photo is gone or could not be read.
  final int skipped;
}

/// Packs the examiner's confirmed values into a file for improving the reader:
/// for each piece of handwriting a cropped picture of it and the text the
/// examiner confirmed, with what the machine had read.
///
/// This is deliberate and manual. Nothing is sent anywhere and nothing is
/// retrained: the file is made only when the examiner asks, and then shared by
/// them. The crops are pictures of real handwriting and, for exam numbers, of
/// real candidates' numbers, so the screen asks for confirmation that the
/// people concerned agree before it makes the file.
class LabelledExport {
  const LabelledExport._();

  /// Room around each region, as a share of its size, so a stroke at the edge is not cut.
  static const padding = 0.08;

  /// Returns null when there is nothing to export.
  static Future<LabelledExportResult?> build({
    required List<LabelledExample> examples,
    required ScanFiles files,
    required Directory directory,
    DateTime? now,
  }) async {
    if (examples.isEmpty) return null;
    final archive = Archive();
    final labels = <Map<String, Object?>>[];
    var skipped = 0;

    // One photo is decoded once, however many examples come from it.
    final byPhoto = <String, List<LabelledExample>>{};
    for (final e in examples) {
      byPhoto.putIfAbsent(e.photoPath, () => []).add(e);
    }
    var n = 0;
    for (final entry in byPhoto.entries) {
      final photo = files.resolve(entry.key);
      DecodedPhoto decoded;
      try {
        decoded = await decodePhoto(photo, maxSide: 4000);
      } catch (_) {
        skipped += entry.value.length;
        continue;
      }
      for (final e in entry.value) {
        final r = e.region;
        final w = decoded.image.width, h = decoded.image.height;
        final px = (r.width * padding * w), py = (r.height * padding * h);
        final left = ((r.left * w) - px).floor().clamp(0, w - 1), top = ((r.top * h) - py).floor().clamp(0, h - 1);
        final right = ((r.right * w) + px).ceil().clamp(left + 1, w), bottom = ((r.bottom * h) + py).ceil().clamp(top + 1, h);
        if (right - left < 4 || bottom - top < 4) {
          skipped++;
          continue;
        }
        final png = await encodeColorPng(decoded.image.crop(left, top, right, bottom));
        n++;
        final name = 'crops/${n.toString().padLeft(5, '0')}_${e.fieldKey}.png';
        archive.addFile(ArchiveFile(name, png.length, png));
        labels.add({
          'file': name,
          'field': e.fieldKey,
          'kind': e.kind,
          'text': e.text,
          'decision': e.decision,
          'machine_value': e.machineValue,
          'region_on_photo': [r.left, r.top, r.right, r.bottom],
          'confirmed_at': e.reviewedAt.toUtc().toIso8601String(),
        });
      }
    }
    if (labels.isEmpty) return null;

    final stamp = (now ?? DateTime.now()).toUtc();
    final labelsBytes = utf8.encode(const JsonEncoder.withIndent(' ').convert({
      'schema': 1,
      'created': stamp.toIso8601String(),
      'examples': labels,
    }));
    archive.addFile(ArchiveFile('labels.json', labelsBytes.length, labelsBytes));
    final readme = utf8.encode('''UniMarkLy labelled examples
Created ${stamp.toIso8601String()}

crops/            a picture of each piece of handwriting, cut from the original photograph
labels.json       for each: the text the examiner confirmed, what the machine had read,
                  what the examiner decided (accepted, suggestion, edited, entered) and when

These are pictures of real handwriting and real registration numbers. Share them
only with the agreement of the people concerned, and only for improving the reader.
Nothing was sent anywhere when this file was made; it leaves the phone only if you share it.
''');
    archive.addFile(ArchiveFile('README.txt', readme.length, readme));

    await directory.create(recursive: true);
    final file = File('${directory.path}/unimarkly_examples_${stamp.millisecondsSinceEpoch}.zip');
    await file.writeAsBytes(ZipEncoder().encode(archive)!, flush: true);
    return LabelledExportResult(file: file, examples: labels.length, skipped: skipped);
  }
}
