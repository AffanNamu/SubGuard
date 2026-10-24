import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import 'incoming_file.dart';

/// Why a file can not be opened, in words for the person holding the phone.
enum FileProblem {
  missing('The file is no longer on this phone. Open it again from where you found it.'),
  empty('The file is empty.'),
  tooLarge('The file is too large to open here. Share it with another app, or save it and open it on a computer.'),
  unsupported('UniMarkLy cannot open this kind of file. It opens PDF, Word, Excel and CSV files, and photos.'),
  corrupt('The file is damaged or is not what its name says, so it cannot be read. Ask for it to be sent again.'),
  passwordProtected(
      'The file is protected with a password. Remove the password in the app that made it, then open it again.');

  const FileProblem(this.message);
  final String message;
}

class Inspection {
  const Inspection.ok(this.kind) : problem = null;
  const Inspection.problem(this.problem, [this.kind = IncomingKind.unknown]);

  final IncomingKind kind;
  final FileProblem? problem;

  bool get ok => problem == null;
}

/// Decides what a file really is, from its bytes and not only its name, and
/// whether it can be opened. A file renamed to `.pdf` that is not a PDF is
/// reported as damaged instead of being handed to a viewer that would show a
/// blank page.
class FileInspector {
  const FileInspector._();

  /// Largest file the app will try to show or import. Bigger files can still be
  /// shared on or saved.
  static const int maxViewBytes = 100 * 1024 * 1024;

  static const _imageExt = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'};

  static Future<Inspection> inspect(File file, {String? name, String? mime}) async {
    final fileName = name ?? p.basename(file.path);
    final ext = p.extension(fileName).toLowerCase().replaceFirst('.', '');

    final int size;
    try {
      if (!await file.exists()) return const Inspection.problem(FileProblem.missing);
      size = await file.length();
    } on FileSystemException {
      return const Inspection.problem(FileProblem.missing);
    }
    if (size == 0) return const Inspection.problem(FileProblem.empty);

    final head = await _read(file, 0, 8192);
    final kind = await _classify(file, head, ext, mime);

    if (kind == IncomingKind.unknown) return const Inspection.problem(FileProblem.unsupported);
    if (size > maxViewBytes && kind != IncomingKind.image) {
      return Inspection.problem(FileProblem.tooLarge, kind);
    }

    switch (kind) {
      case IncomingKind.pdf:
        if (!_isPdf(head)) return Inspection.problem(FileProblem.corrupt, kind);
        final tail = await _read(file, size > 8192 ? size - 8192 : 0, 8192);
        if (_contains(head, '/Encrypt') || _contains(tail, '/Encrypt')) {
          return Inspection.problem(FileProblem.passwordProtected, kind);
        }
        return Inspection.ok(kind);
      case IncomingKind.docx:
      case IncomingKind.xlsx:
        // A real .docx/.xlsx is a zip holding the part that makes it Word or
        // Excel. The old binary format under this name is what a file locked
        // with a password looks like from outside.
        if (_isOle(head)) return Inspection.problem(FileProblem.passwordProtected, kind);
        if (!_isZip(head)) return Inspection.problem(FileProblem.corrupt, kind);
        final inner = await _officeKind(file);
        if (inner != kind) return Inspection.problem(FileProblem.corrupt, kind);
        return Inspection.ok(kind);
      case IncomingKind.doc:
      case IncomingKind.xls:
        if (!_isOle(head)) return Inspection.problem(FileProblem.corrupt, kind);
        return Inspection.ok(kind);
      case IncomingKind.csv:
        // Text only: a NUL byte means a binary file with a text name.
        if (head.contains(0)) return Inspection.problem(FileProblem.corrupt, kind);
        return Inspection.ok(kind);
      case IncomingKind.image:
        return Inspection.ok(kind);
      case IncomingKind.unknown:
        return const Inspection.problem(FileProblem.unsupported);
    }
  }

  /// Chooses the kind from the bytes first, then the name.
  static Future<IncomingKind> _classify(File file, Uint8List head, String ext, String? mime) async {
    if (_isPdf(head)) return IncomingKind.pdf;
    if (_isImage(head)) return IncomingKind.image;

    if (_isZip(head)) {
      final inner = await _officeKind(file);
      if (inner != null) return inner;
      // A zip that is not Word or Excel. If it was named like one, it is damaged
      // or has been renamed; otherwise it is simply not a supported file.
      return switch (ext) {
        'docx' => IncomingKind.docx,
        'xlsx' || 'xlsm' => IncomingKind.xlsx,
        _ => IncomingKind.unknown,
      };
    }

    if (_isOle(head)) {
      // The old binary Office formats, and also what a password-protected
      // .docx or .xlsx looks like from outside.
      return switch (ext) {
        'doc' || 'docx' => ext == 'doc' ? IncomingKind.doc : IncomingKind.docx,
        'xls' || 'xlsx' || 'xlsm' => ext == 'xls' ? IncomingKind.xls : IncomingKind.xlsx,
        _ => IncomingKind.unknown,
      };
    }

    // Named like a type but with the wrong bytes: let the named type decide so
    // the right message is shown.
    switch (ext) {
      case 'pdf':
        return IncomingKind.pdf;
      case 'docx':
        return IncomingKind.docx;
      case 'doc':
        return IncomingKind.doc;
      case 'xlsx':
      case 'xlsm':
        return IncomingKind.xlsx;
      case 'xls':
        return IncomingKind.xls;
      case 'csv':
      case 'tsv':
      case 'txt':
        return IncomingKind.csv;
    }
    if (_imageExt.contains(ext)) return IncomingKind.image;
    final m = mime?.toLowerCase() ?? '';
    if (m.contains('csv')) return IncomingKind.csv;
    return IncomingKind.unknown;
  }

  /// Lists the parts of an Office Open XML file to tell Word from Excel,
  /// without reading the whole file into memory.
  static Future<IncomingKind?> _officeKind(File file) async {
    final input = InputFileStream(file.path);
    try {
      final archive = ZipDecoder().decodeBuffer(input);
      for (final f in archive.files) {
        if (f.name == 'word/document.xml') return IncomingKind.docx;
        if (f.name == 'xl/workbook.xml') return IncomingKind.xlsx;
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      await input.close();
    }
  }

  static bool _isPdf(Uint8List b) {
    // The header may follow a few stray bytes.
    final n = b.length < 1024 ? b.length : 1024;
    for (var i = 0; i + 4 < n; i++) {
      if (b[i] == 0x25 && b[i + 1] == 0x50 && b[i + 2] == 0x44 && b[i + 3] == 0x46 && b[i + 4] == 0x2d) return true;
    }
    return false;
  }

  static bool _isZip(Uint8List b) => b.length >= 4 && b[0] == 0x50 && b[1] == 0x4b && (b[2] == 3 || b[2] == 5);

  static bool _isOle(Uint8List b) =>
      b.length >= 8 &&
      b[0] == 0xD0 &&
      b[1] == 0xCF &&
      b[2] == 0x11 &&
      b[3] == 0xE0 &&
      b[4] == 0xA1 &&
      b[5] == 0xB1 &&
      b[6] == 0x1A &&
      b[7] == 0xE1;

  static bool _isImage(Uint8List b) {
    if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) return true; // JPEG
    if (b.length >= 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) return true; // PNG
    if (b.length >= 12 && _ascii(b, 0, 4) == 'RIFF' && _ascii(b, 8, 4) == 'WEBP') return true;
    if (b.length >= 12 && _ascii(b, 4, 4) == 'ftyp') {
      final brand = _ascii(b, 8, 4);
      return const {'heic', 'heix', 'hevc', 'mif1', 'msf1', 'heim', 'heis'}.contains(brand);
    }
    return false;
  }

  static String _ascii(Uint8List b, int start, int len) => String.fromCharCodes(b.sublist(start, start + len));

  static bool _contains(Uint8List b, String needle) {
    final n = needle.codeUnits;
    for (var i = 0; i + n.length <= b.length; i++) {
      var hit = true;
      for (var j = 0; j < n.length; j++) {
        if (b[i + j] != n[j]) {
          hit = false;
          break;
        }
      }
      if (hit) return true;
    }
    return false;
  }

  static Future<Uint8List> _read(File file, int start, int length) async {
    final raf = await file.open();
    try {
      await raf.setPosition(start);
      return await raf.read(length);
    } finally {
      await raf.close();
    }
  }
}
