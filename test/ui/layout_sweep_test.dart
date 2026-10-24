import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/core/widgets/score_keypad.dart';
import 'package:unimarkly/domain/models.dart';

import 'harness.dart';

/// Walks through every screen at small phone sizes and large text. Flutter
/// reports any overflowing widget as an error, so a screen that clips or
/// overflows at these sizes fails the test.
void main() {
  final h = AppHarness();

  final configs = <String, (Size, double)>{
    'small phone 360x640, normal text': (const Size(360, 640), 1.0),
    'small phone 360x640, 1.5x text': (const Size(360, 640), 1.5),
    'very small phone 320x568, 1.3x text': (const Size(320, 568), 1.3),
    'phone 390x844, largest text (2x)': (const Size(390, 844), 2.0),
    'landscape phone 844x390': (const Size(844, 390), 1.0),
    'tablet 820x1180': (const Size(820, 1180), 1.0),
  };

  for (final entry in configs.entries) {
    testWidgets('every screen fits: ${entry.key}', (tester) async {
      final (size, scale) = entry.value;
      late Course course;

      await h.start(tester, size: size, textScale: scale, seed: () async {
        course = await h.createCourse(regNos: const [
          'FWM/24U/0538',
          'FWM/24U/0539',
          'FST/25U/244/5772',
          'ASR/25U/224/0937',
          'NOT A NUMBER',
        ]);
        final list = await h.students.getAll(course.id);
        await h.setMarks(course, list[0], {0: 58, 1: 9, 2: 8, 3: 9.5});
        await h.setMarks(course, list[1], {0: 75, 1: 4}); // above the Exam maximum
        await h.setMarks(course, list[2], {0: 9.5});
        await h.courses.saveTemplate('My 60 + 40', course.scheme);
      });

      Future<void> back() async {
        await tester.pageBack();
        await h.settle(tester);
      }

      Future<void> dismissSheet() async {
        await tester.tapAt(const Offset(4, 4));
        await h.settle(tester);
      }

      // Courses
      expect(find.text('(FWM) AGR 114'), findsWidgets);
      await h.tapText(tester, '(FWM) AGR 114');

      // Dashboard
      expect(find.text('Students'), findsWidgets);

      // Score grid, entry sheet, quick entry
      await h.tapText(tester, 'Enter scores');
      // In the wide table layout the first "Exam" is the column heading.
      await tester.tap(size.width >= 720 ? find.text('Exam').at(1) : find.text('Exam').first);
      await h.settle(tester);
      Future<void> pad(String key) => tester.tap(
          find.descendant(of: find.byType(ScoreKeypad), matching: find.text(key)));
      await pad('7');
      await pad('5');
      await h.settle(tester);
      expect(find.textContaining('above the maximum'), findsWidgets);
      await dismissSheet();
      await h.tapText(tester, 'Enter by number');
      await tester.enterText(find.byType(TextField).last, 'FWM/24U/0540');
      await h.settle(tester);
      await dismissSheet();
      await back();

      // Class list, student sheet, import
      await h.tapText(tester, 'Class list');
      await tester.tap(find.text('FWM/24U/0538').first);
      await h.settle(tester);
      await dismissSheet();
      await tester.tap(find.byTooltip('Import more students'));
      await h.settle(tester);
      await h.reveal(tester, find.byType(TextField));
      await tester.enterText(find.byType(TextField).first, 'FWM/24U/0600\nFWM/24U/0601');
      await tester.pump();
      await h.tapText(tester, 'Use this list');
      await h.reveal(tester, find.text('What will happen'));
      await back();
      await back();

      // Course setup, every step, and the part editor
      await h.tapText(tester, 'Marks and grades');
      await h.tapText(tester, 'Next');
      await h.tapText(tester, 'Exam');
      await h.reveal(tester, find.text('Done'));
      await h.tapText(tester, 'Done');
      await h.tapText(tester, 'Next');
      await h.reveal(tester, find.byTooltip('More questions'));
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byTooltip('More questions'));
        await tester.pump();
      }
      await h.settle(tester);
      await h.tapText(tester, 'Next');
      await h.reveal(tester, find.text('Save as a template'));
      await tester.pageBack(); // leave the wizard
      await h.settle(tester);
      if (find.text('Leave').evaluate().isNotEmpty) await h.tapText(tester, 'Leave');
      await back();

      // Export (tab and screen)
      await h.tapText(tester, 'Export');
      await h.tapText(tester, '(FWM) AGR 114');
      await h.tapText(tester, 'Choose columns and export');
      await h.reveal(tester, find.text('Preview'));
      await h.reveal(tester, find.textContaining('Export as'));
      await back();

      // Settings and its pages
      await h.tapText(tester, 'Settings');
      for (final page in ['Document header', 'New course defaults', 'Saved templates', 'Bin']) {
        await h.tapText(tester, page);
        await back();
      }
      expect(tester.takeException(), isNull);

      await h.stop(tester);
    });
  }
}
