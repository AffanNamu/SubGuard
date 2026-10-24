import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

import '../../data/repositories/score_repository.dart';
import '../../domain/models.dart';
import 'csv_writer.dart';
import 'docx_writer.dart';
import 'pdf_writer.dart';
import 'result_table.dart';
import 'xlsx_writer.dart';

enum ExportFormat {
  docx('Word', 'docx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'),
  xlsx('Excel', 'xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
  pdf('PDF', 'pdf', 'application/pdf'),
  csv('CSV', 'csv', 'text/csv');

  const ExportFormat(this.label, this.extension, this.mimeType);
  final String label;
  final String extension;
  final String mimeType;
}

/// One course's data, ready to export.
class CourseExportData {
  const CourseExportData({
    required this.course,
    required this.students,
    required this.scores,
  });

  final Course course;
  final List<Student> students;
  final ScoreMap scores;
}

class ExportedFile {
  const ExportedFile({required this.course, required this.format, required this.path});

  final Course course;
  final ExportFormat format;
  final String path;

  String get name => p.basename(path);
}

class ExportService {
  const ExportService();

  /// Builds the file bytes for one table.
  static Future<List<int>> encode(ExportFormat format, ResultTable table) async {
    switch (format) {
      case ExportFormat.docx:
        return DocxWriter.build(table);
      case ExportFormat.xlsx:
        return XlsxWriter.build(table);
      case ExportFormat.pdf:
        return PdfWriter.build(table);
      case ExportFormat.csv:
        return CsvWriter.build(table);
    }
  }

  /// "FWM_AGR-114_Full-result.docx". Characters that are not safe in a file
  /// name are replaced.
  static String fileName(Course course, ExportFormat format, {String? label}) {
    String clean(String s) =>
        s.trim().replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
    final parts = [
      if (course.department.trim().isNotEmpty) clean(course.department),
      clean(course.code),
      if (course.session.trim().isNotEmpty) clean(course.session),
      if (label != null && label.isNotEmpty) clean(label),
    ].where((s) => s.isNotEmpty);
    return '${parts.join('_')}.${format.extension}';
  }

  /// Writes one file per course into [directory]. A course that fails does
  /// not stop the others; the failure is reported with its course.
  Future<ExportResult> exportCourses({
    required List<CourseExportData> courses,
    required ExportFormat format,
    required ExportOptions options,
    required Directory directory,
    ExportHeader header = const ExportHeader(),
    String? label,
    bool inBackground = true,
  }) async {
    await directory.create(recursive: true);
    final files = <ExportedFile>[];
    final failures = <String, Object>{};

    for (final data in courses) {
      try {
        final table = ResultTableBuilder.build(
          course: data.course,
          students: data.students,
          scores: data.scores,
          options: options,
          header: header,
        );
        final bytes = inBackground
            ? await Isolate.run(() => encode(format, table))
            : await encode(format, table);
        final path = p.join(directory.path, fileName(data.course, format, label: label));
        await File(path).writeAsBytes(bytes, flush: true);
        files.add(ExportedFile(course: data.course, format: format, path: path));
      } catch (e) {
        failures[data.course.title] = e;
      }
    }
    return ExportResult(files: files, failures: failures);
  }
}

class ExportResult {
  const ExportResult({required this.files, required this.failures});

  final List<ExportedFile> files;

  /// Course title -> what went wrong.
  final Map<String, Object> failures;
}
