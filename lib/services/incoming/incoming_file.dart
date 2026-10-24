/// A document another app handed to UniMarkLy.
///
/// [path] is a private copy made by the operating-system layer as soon as the
/// file arrived (a content URI is only readable for a short time and may not
/// be a path at all). The original is never touched.
class IncomingFile {
  const IncomingFile({
    required this.id,
    required this.path,
    required this.name,
    this.mime,
    required this.size,
  });

  /// Unique per arrival, so a repeated delivery of the same event is noticed.
  final String id;
  final String path;
  final String name;
  final String? mime;
  final int size;

  factory IncomingFile.fromMap(Map<Object?, Object?> m) => IncomingFile(
        id: m['id'] as String,
        path: m['path'] as String,
        name: m['name'] as String,
        mime: m['mime'] as String?,
        size: (m['size'] as num).toInt(),
      );
}

/// A file that arrived but could not be copied, with the reason in plain words.
class IncomingFailure {
  const IncomingFailure({required this.name, required this.message});

  final String name;
  final String message;

  factory IncomingFailure.fromMap(Map<Object?, Object?> m) =>
      IncomingFailure(name: m['name'] as String? ?? 'A file', message: m['message'] as String? ?? 'It could not be opened.');
}

/// What the operating system layer reports.
sealed class IncomingEvent {
  const IncomingEvent();
}

/// Files are being copied; the screen can show that something is happening.
class IncomingStarted extends IncomingEvent {
  const IncomingStarted(this.count);
  final int count;
}

class IncomingArrived extends IncomingEvent {
  const IncomingArrived({this.files = const [], this.failures = const []});
  final List<IncomingFile> files;
  final List<IncomingFailure> failures;
}

/// The kinds of document UniMarkLy handles.
enum IncomingKind {
  pdf('PDF document'),
  docx('Word document'),
  doc('Word document (old format)'),
  xlsx('Excel workbook'),
  xls('Excel workbook (old format)'),
  csv('CSV table'),
  image('Photo'),
  unknown('Unknown file');

  const IncomingKind(this.label);
  final String label;

  /// Tables that can be shown and imported.
  bool get isTable => this == xlsx || this == csv;
}
