import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/core/widgets/score_keypad.dart';
import 'package:unimarkly/domain/models.dart';
import 'package:unimarkly/domain/scan.dart';

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
      await h.tapText(tester, 'Exports');
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

  for (final entry in configs.entries) {
    testWidgets('scan screens fit: ${entry.key}', (tester) async {
      final (size, scale) = entry.value;
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        _reports.add(details.toString());
        previous?.call(details);
      };
      addTearDown(() => FlutterError.onError = previous);

      await h.start(tester, size: size, textScale: scale, tab: null, prefsValues: {'header_examiner': 'Ada Okafor'}, seed: () async {
        final course = await h.createCourse(code: 'AGR 114', regNos: const ['FWM/24U/0538', 'FWM/24U/0539']);
        final other = await h.createCourse(code: 'BIO 201', department: 'FST', regNos: const ['FST/24U/0101']);
        await h.seedBatch(course, title: 'A very long upload name that has to wrap or be cut off safely', states: [
          ScanStatus.confirmed,
          ScanStatus.needsReview,
          ScanStatus.failed,
          ScanStatus.queued,
        ]);
        await h.seedBatch(other, states: [ScanStatus.confirmed, ScanStatus.confirmed]);
        for (var i = 0; i < 4; i++) {
          await h.seedBatch(course, states: [ScanStatus.confirmed]);
        }
      });

      Future<void> back() async {
        await tester.pageBack();
        await h.settle(tester);
      }

      // Home, top to bottom.
      final list = find.byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.vertical);
      expect(find.text('Start Scanning\nExam Scripts'), findsOneWidget);
      for (var i = 0; i < 12; i++) {
        await tester.drag(list.first, const Offset(0, -300), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await h.settle(tester);
      noErrors(tester);

      // View all batches, then one batch.
      await h.tapText(tester, 'View All');
      expect(find.text('Recent batches'), findsOneWidget);
      await h.tapText(tester, 'All courses');
      await h.tapText(tester, 'AGR 114');
      // The long-named upload is the one with a photo in every state.
      await h.tapText(tester, 'A very long upload name that has to wrap or be cut off safely');
      expect(find.text('Scan & Extract'), findsWidgets);
      for (var i = 0; i < 6; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -300), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await h.settle(tester);
      noErrors(tester);

      // Review: the screen, a number pad, the whole photo.
      await h.tapText(tester, 'Next: Review Results');
      await h.tapText(tester, 'Q-1');
      expect(find.text('Save'), findsOneWidget);
      await tester.tapAt(const Offset(4, 4));
      await h.settle(tester);
      for (var i = 0; i < 8; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -300), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await h.settle(tester);
      await tester.tap(find.byTooltip('See the whole photo'));
      await h.settle(tester);
      noErrors(tester);
      await back(); // photo
      await back(); // review
      await h.tapText(tester, 'Previous'); // Scan & Extract has its own bar
      await back(); // all batches

      // The raised upload button, the review queue and the settings group.
      await tester.tap(find.bySemanticsLabel('Add exam images').first, warnIfMissed: false);
      await h.settle(tester);
      noErrors(tester);
      await tester.tapAt(const Offset(4, 4));
      await h.settle(tester);
      await h.tapText(tester, 'Settings');
      await h.reveal(tester, find.text('Scanning & reading'));
      expect(find.text('Photo quality'), findsOneWidget);
      noErrors(tester);

      await h.stop(tester);
    });
  }
}

/// Fails with the full report (which widget, how far it overflows) rather than
/// just the one-line message.
void noErrors(WidgetTester tester) {
  final e = tester.takeException();
  expect(e, isNull, reason: _reports.isEmpty ? '$e' : _reports.join('\n---\n'));
  _reports.clear();
}

final _reports = <String>[];

