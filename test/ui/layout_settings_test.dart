import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/domain/layout_profile.dart';
import 'package:unimarkly/providers/providers.dart';
import 'package:unimarkly/services/reader/ocr_engine.dart';
import 'package:unimarkly/services/recognition/booklet_pipeline.dart';
import 'package:unimarkly/services/reader/layout_engine.dart';
import 'package:unimarkly/features/settings/layout_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harness.dart';

/// Choosing which booklet cover the app reads: the built-in one, or a layout file the
/// administrator added. Every file is checked first and a refusal says what is wrong.
void main() {
  final h = AppHarness();
  final example = File('docs/recognition/layouts/example_left_table.json').readAsStringSync();

  /// What the file picker returns next, and what the sharer was given.
  ({String name, String text})? nextFile;
  final shared = <(String, String)>[];

  List<Override> fakes() => [
        layoutFilePickerProvider.overrideWithValue(() async => nextFile),
        layoutFileSharerProvider.overrideWithValue((name, text) async => shared.add((name, text))),
      ];

  Future<void> openLayouts(WidgetTester tester) async {
    await h.tapText(tester, 'Settings');
    await h.reveal(tester, find.text('Booklet layout'));
    await tester.tap(find.text('Booklet layout'));
    await h.settle(tester);
  }

  setUp(() {
    nextFile = null;
    shared.clear();
  });

  testWidgets('Settings names the layout in use, and the screen lists the built-in one as chosen', (tester) async {
    await h.start(tester, size: const Size(390, 2400), tab: null, overrides: fakes());
    await h.tapText(tester, 'Settings');
    await h.reveal(tester, find.text('Booklet layout'));
    expect(find.text('Modibbo Adama University exam booklet'), findsOneWidget);
    await tester.tap(find.text('Booklet layout'));
    await h.settle(tester);

    expect(find.byType(LayoutScreen), findsOneWidget);
    expect(find.textContaining('Built in'), findsOneWidget);
    expect(tester.widget<RadioGroup<String>>(find.byType(RadioGroup<String>)).groupValue, 'modibbo-adama-cover');
    await h.stop(tester);
  });

  testWidgets('adding a valid file lists it, choosing it is remembered, and Settings shows it', (tester) async {
    await h.start(tester, size: const Size(390, 2400), tab: null, overrides: fakes());
    await openLayouts(tester);

    nextFile = (name: 'left.json', text: example);
    await tester.tap(find.text('Add a layout file'));
    await h.settle(tester);
    expect(find.textContaining('was added'), findsOneWidget);
    expect(find.text('Example: marks table on the left'), findsOneWidget);
    expect(find.textContaining('Added by you · revision 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('layout-example-left-table')));
    await h.settle(tester);
    expect(tester.widget<RadioGroup<String>>(find.byType(RadioGroup<String>)).groupValue, 'example-left-table');
    expect(h.prefs.getString('layout_profile_id'), 'example-left-table');
    expect(h.prefs.getStringList('layout_profiles'), hasLength(1));
    expect(LayoutProfile.parse(h.prefs.getStringList('layout_profiles')!.single).id, 'example-left-table');

    await tester.pageBack();
    await h.settle(tester);
    expect(find.text('Example: marks table on the left'), findsOneWidget);
    await h.stop(tester);
  });

  testWidgets('a file that fails the checks is refused with what is wrong and where, and nothing changes', (tester) async {
    await h.start(tester, size: const Size(390, 2400), tab: null, overrides: fakes());
    await openLayouts(tester);

    final broken = jsonDecode(example) as Map<String, dynamic>;
    ((broken['regions'] as Map)['marks'] as Map)['variants'][0]['needs'] = ['score'];
    nextFile = (name: 'broken.json', text: jsonEncode(broken));
    await tester.tap(find.text('Add a layout file'));
    await h.settle(tester);
    expect(find.textContaining('That file was not added'), findsOneWidget);
    expect(find.textContaining('regions.marks.variants[0].bottom.ref: uses "grand", which is not in this variant\'s "needs"'), findsOneWidget);
    expect(find.byKey(const ValueKey('layout-example-left-table')), findsNothing);
    expect(h.prefs.getStringList('layout_profiles') ?? const [], isEmpty);

    nextFile = (name: 'notes.json', text: 'these are not layout settings');
    await tester.tap(find.text('Add a layout file'));
    await h.settle(tester);
    expect(find.textContaining('not valid JSON'), findsOneWidget);
    await h.stop(tester);
  });

  testWidgets('the built-in layout cannot be replaced by a file that borrows its id', (tester) async {
    await h.start(tester, size: const Size(390, 2400), tab: null, overrides: fakes());
    await openLayouts(tester);
    final clash = jsonDecode(example) as Map<String, dynamic>..['id'] = 'modibbo-adama-cover';
    nextFile = (name: 'clash.json', text: jsonEncode(clash));
    await tester.tap(find.text('Add a layout file'));
    await h.settle(tester);
    expect(find.textContaining('is the built-in layout'), findsOneWidget);
    expect(h.prefs.getStringList('layout_profiles') ?? const [], isEmpty);
    await h.stop(tester);
  });

  testWidgets('choosing nothing in the file picker changes nothing', (tester) async {
    await h.start(tester, size: const Size(390, 2400), tab: null, overrides: fakes());
    await openLayouts(tester);
    nextFile = null;
    await tester.tap(find.text('Add a layout file'));
    await h.settle(tester);
    expect(find.textContaining('was added'), findsNothing);
    expect(find.textContaining('not added'), findsNothing);
    await h.stop(tester);
  });

  testWidgets('the same id added again is a new revision, not a second layout', (tester) async {
    await h.start(tester, size: const Size(390, 2400), tab: null, overrides: fakes());
    await openLayouts(tester);
    nextFile = (name: 'a.json', text: example);
    await tester.tap(find.text('Add a layout file'));
    await h.settle(tester);
    final second = jsonDecode(example) as Map<String, dynamic>..['revision'] = 2;
    nextFile = (name: 'b.json', text: jsonEncode(second));
    await tester.tap(find.text('Add a layout file'));
    await h.settle(tester);
    expect(find.byKey(const ValueKey('layout-example-left-table')), findsOneWidget);
    expect(find.textContaining('Added by you · revision 2'), findsOneWidget);
    await h.stop(tester);
  });

  testWidgets('a copy of the built-in file can be shared as a starting point, and reads back as the built-in layout', (tester) async {
    await h.start(tester, size: const Size(390, 2400), tab: null, overrides: fakes());
    await openLayouts(tester);
    await tester.tap(find.byTooltip('More about Modibbo Adama University exam booklet'));
    await h.settle(tester);
    expect(find.text('Remove'), findsNothing, reason: 'the built-in layout cannot be removed');
    await tester.tap(find.text('Share a copy of this file'));
    await h.settle(tester);
    expect(shared, hasLength(1));
    expect(shared.single.$1, 'modibbo-adama-cover.json');
    expect(LayoutProfile.parse(shared.single.$2), LayoutProfile.modibboAdama);
    await h.stop(tester);
  });

  testWidgets('removing the layout in use goes back to the built-in one', (tester) async {
    await h.start(tester, size: const Size(390, 2400), tab: null, overrides: fakes(), prefsValues: {
      'layout_profiles': [example],
      'layout_profile_id': 'example-left-table',
    });
    await openLayouts(tester);
    expect(tester.widget<RadioGroup<String>>(find.byType(RadioGroup<String>)).groupValue, 'example-left-table');

    await tester.tap(find.byTooltip('More about Example: marks table on the left'));
    await h.settle(tester);
    await tester.tap(find.text('Remove'));
    await h.settle(tester);
    expect(find.text('Remove this layout?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await h.settle(tester);

    expect(find.byKey(const ValueKey('layout-example-left-table')), findsNothing);
    expect(h.prefs.getString('layout_profile_id'), 'modibbo-adama-cover');
    expect(h.prefs.getStringList('layout_profiles'), isEmpty);
    await h.stop(tester);
  });

  group('the layout in use reaches the pipeline', () {
    Future<ProviderContainer> container(Map<String, Object> prefs) async {
      SharedPreferences.setMockInitialValues(prefs);
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
        ocrEngineProvider.overrideWithValue(const UnavailableOcrEngine()),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    Future<String> layoutOfNextPhoto(ProviderContainer c) async {
      final pipeline = await c.read(recognitionPipelineProvider.future) as BookletPipeline;
      return (pipeline.layout as ProfileLayoutAnalyzer).profile.id;
    }

    test('the built-in layout until another is chosen; the choice applies from the next photo and is remembered', () async {
      var c = await container({});
      expect(await layoutOfNextPhoto(c), 'modibbo-adama-cover');

      await c.read(layoutChoiceProvider.notifier).add(example);
      expect(await layoutOfNextPhoto(c), 'modibbo-adama-cover', reason: 'adding a layout does not switch to it');
      await c.read(layoutChoiceProvider.notifier).select('example-left-table');
      expect(await layoutOfNextPhoto(c), 'example-left-table');

      // A new start of the app, over the same stored settings.
      final prefs = await SharedPreferences.getInstance();
      c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        ocrEngineProvider.overrideWithValue(const UnavailableOcrEngine()),
      ]);
      addTearDown(c.dispose);
      expect(await layoutOfNextPhoto(c), 'example-left-table');
      expect(c.read(layoutChoiceProvider).imported.single.revision, 1);
    });

    test('a stored file that no longer passes the checks is left out, and a missing selection falls back', () async {
      final c = await container({
        'layout_profiles': ['{this is damaged', example],
        'layout_profile_id': 'a-layout-that-was-removed',
      });
      expect(c.read(layoutChoiceProvider).imported.map((p) => p.id), ['example-left-table']);
      expect(await layoutOfNextPhoto(c), 'modibbo-adama-cover');
    });
  });
}
