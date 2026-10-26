import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/core/widgets/score_keypad.dart';
import 'package:unimarkly/domain/scheme.dart';

import 'harness.dart';

/// Setting up the paper's questions: any question numbers, in any order; no list is made up.
void main() {
  final h = AppHarness();

  Future<void> toExamStep(WidgetTester tester, {Map<String, Object> prefs = const {}}) async {
    await h.start(tester, size: const Size(390, 2600), prefsValues: prefs);
    await h.tapText(tester, 'Create your first course');
    await tester.enterText(find.widgetWithText(TextField, 'Course code'), 'CHM 101');
    await h.tapText(tester, 'Next');
    await h.tapText(tester, 'Next'); // Exam paper
  }

  Future<void> addByNumber(WidgetTester tester, List<String> digits) async {
    await tester.tap(find.byKey(const ValueKey('add-question')));
    await h.settle(tester);
    for (final d in digits) {
      await tester.tap(find.descendant(of: find.byType(ScoreKeypad), matching: find.text(d)));
      await tester.pump();
    }
    await tester.tap(find.text('Save'));
    await h.settle(tester);
  }

  testWidgets('a paper starts with no questions, and questions are added by number: 1, 2, 4, 5 with no Q3', (tester) async {
    await toExamStep(tester);
    expect(find.text('None set'), findsOneWidget);
    for (final n in ['1', '2', '4', '5']) {
      await addByNumber(tester, [n]);
    }
    expect(find.text('Q1, Q2, Q4, Q5'), findsOneWidget);
    expect(find.text('Q3'), findsNothing);
    await h.tapText(tester, 'Next');
    await h.tapText(tester, 'Create course');
    final saved = (await tester.runAsync(() => h.courses.getAll()))!.single;
    expect(saved.scheme.questions.map((q) => q.qNo), [1, 2, 4, 5]);
    await h.stop(tester);
  });

  testWidgets('a number already on the paper is not added twice, and one above the limit is refused', (tester) async {
    await toExamStep(tester);
    await addByNumber(tester, ['4']);
    await addByNumber(tester, ['4']);
    expect(find.text('Q4 is already on the paper.'), findsOneWidget);
    await addByNumber(tester, ['7', '5']);
    expect(find.textContaining('Question numbers go from 1 to 60'), findsOneWidget);
    expect(find.text('Q4'), findsWidgets);
    expect(find.text('Q75'), findsNothing);
    await h.stop(tester);
  });

  testWidgets('the quick "more questions" button carries on after the highest number there, not from 1', (tester) async {
    await toExamStep(tester);
    await addByNumber(tester, ['4']);
    await addByNumber(tester, ['5']);
    await tester.tap(find.byTooltip('More questions'));
    await h.settle(tester);
    expect(find.text('Q4, Q5, Q6'), findsOneWidget);
    await tester.tap(find.byTooltip('Fewer questions'));
    await h.settle(tester);
    expect(find.text('Q4, Q5'), findsOneWidget);
    await h.stop(tester);
  });

  testWidgets('a question can be removed, given a weight, and the rule for a question with no mark chosen; all are saved', (tester) async {
    await toExamStep(tester);
    for (final n in ['1', '2', '3']) {
      await addByNumber(tester, [n]);
    }
    // Remove Q2.
    await h.reveal(tester, find.byTooltip('Remove Q2'));
    await tester.tap(find.byTooltip('Remove Q2'));
    await h.settle(tester);
    expect(find.text('Q1, Q3'), findsOneWidget);

    // Q3 counts double.
    final weight = find.widgetWithText(TextField, 'Weight').last;
    await h.reveal(tester, weight);
    await tester.enterText(weight, '2');
    await tester.pump();

    // Ask about each question with no mark.
    await h.reveal(tester, find.text('Ask me about each one'));
    await tester.tap(find.text('Ask me about each one'));
    await h.settle(tester);

    await h.tapText(tester, 'Next');
    await h.tapText(tester, 'Create course');
    final saved = (await tester.runAsync(() => h.courses.getAll()))!.single;
    expect(saved.scheme.questions.map((q) => (q.qNo, q.weight)), [(1, 1.0), (3, 2.0)]);
    expect(saved.scheme.unmarked, UnmarkedRule.ask);
    await h.stop(tester);
  });

  testWidgets('the highest question number is a setting: it limits what can be added, and Settings changes it', (tester) async {
    await h.start(tester, size: const Size(390, 2600), prefsValues: const {'max_question_number': 12}, tab: null);
    await h.tapText(tester, 'Settings');
    await h.reveal(tester, find.text('Highest question number'));
    expect(find.textContaining('Q12.'), findsOneWidget);
    await tester.tap(find.text('Highest question number'));
    await h.settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Highest question number'), '0');
    await tester.tap(find.text('Save'));
    await h.settle(tester);
    expect(find.textContaining('Enter a whole number from 1 to 999.'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Highest question number'), '80');
    await tester.tap(find.text('Save'));
    await h.settle(tester);
    expect(find.textContaining('Q80.'), findsOneWidget);
    expect(h.prefs.getInt('max_question_number'), 80);
    await h.stop(tester);
  });
}
