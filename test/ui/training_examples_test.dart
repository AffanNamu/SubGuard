import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/data/repositories/booklet_repository.dart';
import 'package:unimarkly/data/repositories/recognition_repository.dart';
import 'package:unimarkly/domain/models.dart';
import 'package:unimarkly/domain/ocr.dart';
import 'package:unimarkly/domain/scan.dart';

import 'harness.dart';

/// Settings -> Training examples: what has been kept, and a button that only
/// works once the examiner has said the people concerned agree.
void main() {
  final h = AppHarness();
  const tall = Size(390, 1800);

  testWidgets('with nothing confirmed there is nothing to export', (tester) async {
    await h.start(tester, size: tall, tab: 'Settings');
    await h.tapText(tester, 'Training examples');
    expect(find.text('No examples yet'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Export examples')).onPressed, isNull);
    await h.stop(tester);
  });

  testWidgets('confirmed values are counted, and export needs the agreement box ticked', (tester) async {
    late Course course;
    await h.start(tester, size: tall, tab: null, seed: () async {
      course = await h.createCourse(code: 'AGR 114');
      await h.seedBatch(course, states: [ScanStatus.needsReview]);
      final item = (await h.scans.scansOf((await h.scans.batches()).first.id)).single;
      final student = (await h.students.getAll(course.id)).first;
      await BookletRepository(h.db, h.scores).confirm(
        scanId: item.id,
        courseId: course.id,
        studentId: student.id,
        serialNo: null,
        marks: const {1: 5.5},
        editedMarks: const {1},
        examScore: 5.5,
        examPartId: course.scheme.examPart!.id,
        photoPath: item.relativePath,
        reviews: const [
          FieldReviewDraft(fieldKey: 'mark_q1', kind: 'mark', finalValue: '5.5', decision: 'entered', region: Region(0.7, 0.3, 0.9, 0.4)),
          // No place on the photo: not a usable example.
          FieldReviewDraft(fieldKey: 'serial_no', kind: 'printed_number', finalValue: '292011', decision: 'accepted'),
        ],
      );
    });
    await h.tapText(tester, 'Settings');
    expect(find.textContaining('1 confirmed values'), findsOneWidget);
    await h.tapText(tester, 'Training examples');
    expect(find.text('1 confirmed example'), findsOneWidget);
    Finder button() => find.widgetWithText(FilledButton, 'Export examples');
    expect(tester.widget<FilledButton>(button()).onPressed, isNull, reason: 'nothing is exported until the examiner says the people agree');
    await tester.tap(find.byType(CheckboxListTile));
    await h.settle(tester);
    expect(tester.widget<FilledButton>(button()).onPressed, isNotNull);
    await h.stop(tester);
  });
}
