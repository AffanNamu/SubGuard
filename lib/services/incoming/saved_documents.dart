import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

class SavedDocument {
  const SavedDocument({required this.name, required this.path, required this.size, required this.saved});

  final String name;
  final String path;
  final int size;
  final DateTime saved;
}

class SaveOutcome {
  const SaveOutcome(this.document, {required this.alreadySaved});

  final SavedDocument document;

  /// The same file (same bytes) was already kept, so nothing new was written.
  final bool alreadySaved;
}

/// Documents the person chose to keep in UniMarkLy ("Save a copy"). A folder
/// of files: the same bytes are never stored twice, and a different file with
/// the same name gets a new name instead of replacing the old one.
class SavedDocuments {
  SavedDocuments(this.root);

  final Directory root;

  Future<SaveOutcome> save(File source, {String? name}) async {
    await root.create(recursive: true);
    final fileName = name ?? p.basename(source.path);
    final hash = await _hash(source);

    // The same bytes under any name: already kept.
    await for (final e in root.list(followLinks: false)) {
      if (e is File && await e.length() == await source.length() && await _hash(e) == hash) {
        return SaveOutcome(await _describe(e), alreadySaved: true);
      }
    }

    final stem = p.basenameWithoutExtension(fileName);
    final ext = p.extension(fileName);
    var target = File(p.join(root.path, fileName));
    for (var n = 2; await target.exists(); n++) {
      target = File(p.join(root.path, '$stem ($n)$ext'));
    }
    await source.copy(target.path);
    return SaveOutcome(await _describe(target), alreadySaved: false);
  }

  Future<List<SavedDocument>> list() async {
    if (!await root.exists()) return const [];
    final out = <SavedDocument>[];
    await for (final e in root.list(followLinks: false)) {
      if (e is File) out.add(await _describe(e));
    }
    out.sort((a, b) => b.saved.compareTo(a.saved));
    return out;
  }

  Future<void> delete(SavedDocument doc) async {
    final f = File(doc.path);
    if (await f.exists() && p.isWithin(root.path, f.path)) await f.delete();
  }

  Future<SavedDocument> _describe(File f) async {
    final stat = await f.stat();
    return SavedDocument(name: p.basename(f.path), path: f.path, size: stat.size, saved: stat.modified);
  }

  static Future<String> _hash(File f) async => (await sha256.bind(f.openRead()).first).toString();
}
