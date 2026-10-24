import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/domain/models.dart';

import 'harness.dart';

void main() {
  final h = AppHarness();

  testWidgets('first run: empty state, then a course made with the 70 + 30 default', (tester) async {
    await h.start(tester);

    expect(find.text('No courses yet'), findsOneWidget);
    await h.tapText(tester, 'Create your first course');

    // The running total is always at the top of the wizard.
    expect(find.text('Exam 70 + Attendance 10 + Assignment 10 + Test 10 = 100'), findsWidgets);

    await tester.enterText(find.widgetWithText(TextField, 'Course code'), 'AGR 114');
    await tester.enterText(find.widgetWithText(TextField, 'Department'), 'FWM');
    await tester.pump();

    await h.tapText(tester, 'Next'); // Marks
    expect(find.text('Exam'), findsWidgets);
    await h.reveal(tester, find.text('Add a part'));
    expect(find.text('Add a part'), findsOneWidget);

    await h.tapText(tester, 'Next'); // Exam paper
    await h.tapText(tester, 'Next'); // Grades
    await h.reveal(tester, find.text('Save as a template'));
    expect(find.text('Save as a template'), findsOneWidget);

    await h.tapText(tester, 'Create course');
    expect(find.text('(FWM) AGR 114'), findsWidgets);

    final saved = await tester.runAsync(() => h.courses.getAll());
    expect(saved!.single.code, 'AGR 114');
    expect(saved.single.scheme.partsTotal, 100);

    await h.stop(tester);
  });

  testWidgets('any number can be changed, and the running total follows with a warning', (tester) async {
    await h.start(tester);
    await h.tapText(tester, 'Create your first course');
    await tester.enterText(find.widgetWithText(TextField, 'Course code'), 'BIO 201');
    await h.tapText(tester, 'Next');

    // Open Exam and lower its maximum from 70 to 60.
    await h.tapText(tester, 'Exam');
    final max = find.widgetWithText(TextField, 'Highest mark allowed');
    expect(max, findsOneWidget);
    await tester.enterText(max, '60');
    await tester.pump();
    await h.tapText(tester, 'Done');

    expect(find.text('Exam 60 + Attendance 10 + Assignment 10 + Test 10 = 90'), findsOneWidget);
    expect(find.textContaining('The parts add up to 90, but you expect 100'), findsOneWidget);

    // Nothing is blocked: the course can still be created.
    await h.tapText(tester, 'Next');
    await h.tapText(tester, 'Next');
    await h.tapText(tester, 'Create course');
    final saved = await tester.runAsync(() => h.courses.getAll());
    expect(saved!.single.scheme.parts.first.max, 60);

    await h.stop(tester);
  });

  testWidgets('the exam paper warns when four questions of 15 cannot make 70', (tester) async {
    await h.start(tester);
    await h.tapText(tester, 'Create your first course');
    await tester.enterText(find.widgetWithText(TextField, 'Course code'), 'CHM 101');
    await h.tapText(tester, 'Next');
    await h.tapText(tester, 'Next'); // Exam paper

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byTooltip('More questions'));
      await tester.pump();
    }
    await tester.enterText(find.widgetWithText(TextField, 'Same maximum for every question'), '15');
    await tester.pump();

    expect(find.textContaining('can only reach 60'), findsOneWidget);
    await h.stop(tester);
  });

  testWidgets('class list from pasted text, tidied up and checked', (tester) async {
    late Course course;
    await h.start(tester, seed: () async => course = await h.createCourse(regNos: const []));

    await h.tapText(tester, '(FWM) AGR 114');
    expect(find.text('Add the class list'), findsWidgets);
    await h.tapText(tester, 'Add the class list');
    await h.tapText(tester, 'Import or paste a list');

    await tester.enterText(
      find.byType(TextField).first,
      'FWM/24U/0538\nfwm 244 0539\nFST/25U/244/5772\nFWM/24U/0538\nNOT A NUMBER\n',
    );
    await tester.pump();
    await h.tapText(tester, 'Use this list');

    expect(find.text('4 students will be added.'), findsOneWidget);
    expect(find.textContaining('1 skipped'), findsOneWidget);
    expect(find.textContaining('1 numbers were tidied up'), findsOneWidget);
    expect(find.textContaining('1 do not look like DEPT/YYU/NNNN'), findsOneWidget);

    await h.tapText(tester, 'Add to class list');
    final students = await tester.runAsync(() => h.students.getAll(course.id));
    expect(students!.map((s) => s.regNo),
        ['FWM/24U/0538', 'FWM/24U/0539', 'FST/25U/244/5772', 'NOT/A/NUMBER']);

    // The odd one is flagged on the class list.
    expect(find.textContaining('does not match DEPT/YYU/NNNN'), findsOneWidget);
    await h.stop(tester);
  });

  testWidgets('typing marks: totals add up, limits come from the scheme', (tester) async {
    late Course course;
    await h.start(tester, seed: () async => course = await h.createCourse());
    await h.tapText(tester, '(FWM) AGR 114');
    await h.tapText(tester, 'Enter scores');

    expect(find.text('1. FWM/24U/0538'), findsOneWidget);

    // Exam 9.5 using the .5 key.
    await tester.tap(find.text('Exam').first);
    await h.settle(tester);
    await tester.tap(find.text('9'));
    await tester.tap(find.text('.5'));
    await tester.pump();
    expect(find.text('9.5'), findsWidgets);
    await h.tapText(tester, 'Save and close');

    final exam = course.scheme.parts[0];
    final list = (await tester.runAsync(() => h.students.getAll(course.id)))!;
    var scores = await tester.runAsync(() => h.scores.get(course.id));
    expect(scores![list[0].id]![exam.id]!.value, 9.5);
    expect(find.text('9.5'), findsWidgets);

    // 75 is above the Exam maximum of 70: flagged, but still saved.
    await tester.tap(find.text('Exam').first);
    await h.settle(tester);
    await tester.tap(find.text('7'));
    await tester.tap(find.text('5'));
    await tester.pump();
    expect(find.textContaining('above the maximum of 70'), findsOneWidget);
    await h.tapText(tester, 'Save and close');

    scores = await tester.runAsync(() => h.scores.get(course.id));
    expect(scores![list[0].id]![exam.id]!.value, 75);
    expect(find.textContaining('above the maximum of 70'), findsWidgets);

    await h.stop(tester);
  });

  testWidgets('a full row shows the total and the grade', (tester) async {
    await h.start(tester, seed: () async {
      final course = await h.createCourse(regNos: const ['FWM/24U/0538']);
      final s = (await h.students.getAll(course.id)).single;
      await h.setMarks(course, s, {0: 58, 1: 9, 2: 8, 3: 9.5});
    });

    await h.tapText(tester, '(FWM) AGR 114');
    await h.tapText(tester, 'Enter scores');
    expect(find.text('84.5'), findsOneWidget);
    expect(find.text('Grade A'), findsOneWidget);
    await h.stop(tester);
  });

  testWidgets('export shows the three layouts and a preview of the real data', (tester) async {
    await h.start(tester, seed: () async {
      final course = await h.createCourse(regNos: const ['FWM/24U/0538']);
      final s = (await h.students.getAll(course.id)).single;
      await h.setMarks(course, s, {0: 9.5});
    });

    await h.tapText(tester, 'Export'); // bottom navigation
    await h.tapText(tester, '(FWM) AGR 114');
    await h.tapText(tester, 'Choose columns and export');

    expect(find.text('Exam sheet'), findsOneWidget);
    expect(find.text('Continuous assessment sheet'), findsOneWidget);
    expect(find.text('Full result'), findsOneWidget);
    await h.reveal(tester, find.text('9.5'));
    expect(find.text('9.5'), findsWidgets);

    await h.tapText(tester, 'Exam sheet');
    await h.reveal(tester, find.text('Export as Word'));
    expect(find.text('Export as Word'), findsOneWidget);
    await h.stop(tester);
  });

  testWidgets('dark and light themes switch from Settings', (tester) async {
    await h.start(tester);
    expect(Theme.of(tester.element(find.byType(Scaffold).first)).brightness, Brightness.light);

    await h.tapText(tester, 'Settings');
    await h.tapText(tester, 'Dark');
    expect(Theme.of(tester.element(find.byType(Scaffold).first)).brightness, Brightness.dark);
    expect(h.prefs.getString('theme_mode'), 'dark');

    await h.tapText(tester, 'Light');
    expect(Theme.of(tester.element(find.byType(Scaffold).first)).brightness, Brightness.light);
    await h.stop(tester);
  });

  testWidgets('deleting a course sends it to the bin and it can be restored', (tester) async {
    late Course course;
    await h.start(tester, seed: () async => course = await h.createCourse());
    await tester.tap(find.byTooltip('More for ${course.title}'));
    await h.settle(tester);
    await h.tapText(tester, 'Move to the bin');
    expect(find.text('No courses yet'), findsOneWidget);

    await h.tapText(tester, 'Settings');
    await h.tapText(tester, 'Bin');
    expect(find.text('(FWM) AGR 114'), findsOneWidget);
    await h.tapText(tester, 'Restore');
    final back = await tester.runAsync(() => h.courses.getAll());
    expect(back!.single.id, course.id);
    await h.stop(tester);
  });
}
