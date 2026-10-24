import 'dart:io';

import 'package:path/path.dart' as p;

/// The folder where the examiner's original photos are kept.
///
/// Paths in the database are relative to [root], so a backup restores on any
/// phone. Photos are never rewritten or resized after they are stored, so the
/// extracted values can always be checked against the real source.
class ScanFiles {
  ScanFiles(this.root);

  final Directory root;

  File resolve(String relativePath) => File(p.join(root.path, relativePath));

  /// Copies [source] to `<batchId>/<scanId>.<ext>` and returns that relative path.
  Future<String> store(File source, {required String batchId, required String scanId, required String extension}) async {
    final relative = p.join(batchId, '$scanId.$extension');
    final target = resolve(relative);
    await target.parent.create(recursive: true);
    await source.copy(target.path);
    return relative;
  }

  Future<void> delete(String relativePath) async {
    final f = resolve(relativePath);
    if (await f.exists()) await f.delete();
  }

  /// Bytes used by every stored photo.
  Future<int> bytesUsed() async {
    if (!await root.exists()) return 0;
    var total = 0;
    await for (final e in root.list(recursive: true, followLinks: false)) {
      if (e is File) total += await e.length();
    }
    return total;
  }
}
