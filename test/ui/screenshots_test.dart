import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/domain/scan.dart';

import 'harness.dart';

/// Renders screens to PNG files so the design can be checked by eye against
/// the reference screenshots. Does nothing unless SHOT_DIR is set:
///
///   SHOT_DIR=/some/folder flutter test test/ui/screenshots_test.dart
///
/// Text uses the real Roboto and Material icon fonts from the Flutter SDK,
/// because flutter_test otherwise draws every glyph as a solid box.
void main() {
  final dir = Platform.environment['SHOT_DIR'];
  final h = AppHarness();

  Future<void> loadFonts() async {
    final root = Platform.environment['FLUTTER_ROOT'] ??
        File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
    Future<void> load(String family, List<String> files) async {
      final loader = FontLoader(family);
      for (final f in files) {
        final bytes = await File('$root/bin/cache/artifacts/material_fonts/$f').readAsBytes();
        loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      }
      await loader.load();
    }

    await load('Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']);
    await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await h.settle(tester);
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byType(RepaintBoundary).first);
    // Image encoding and file writes are real async work, so they run outside
    // the test's fake clock.
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$dir/$name.png').writeAsBytes(data!.buffer.asUint8List());
    });
  }

  Future<void> seed() async {
    final a = await h.createCourse(code: 'AGR 114', regNos: [
      for (var i = 538; i < 548; i++) 'FWM/24U/0$i',
      'FST/25U/244/5772',
    ]);
    final b = await h.createCourse(code: 'BIO 201', department: 'FST', regNos: [
      for (var i = 101; i < 108; i++) 'FST/24U/0$i',
    ]);
    final studentsA = await h.students.getAll(a.id);
    final marks = [58.0, 9.5, 72.0, 41.0, 66.5, 30.0];
    for (var i = 0; i < studentsA.length; i++) {
      await h.setMarks(a, studentsA[i], {
        0: marks[i % marks.length],
        if (i.isEven) 1: 8,
        if (i.isEven) 2: 7.5,
        if (i.isEven) 3: 9,
      });
    }
    final studentsB = await h.students.getAll(b.id);
    await h.setMarks(b, studentsB[0], {0: 55, 1: 9, 2: 8, 3: 7});

    await h.seedBatch(a, states: [
      ScanStatus.confirmed,
      ScanStatus.confirmed,
      ScanStatus.confirmed,
      ScanStatus.needsReview,
      ScanStatus.needsReview,
      ScanStatus.needsReview,
    ]);
    await h.seedBatch(b, states: [ScanStatus.confirmed, ScanStatus.confirmed, ScanStatus.confirmed, ScanStatus.confirmed]);
    await h.seedBatch(a, states: [ScanStatus.queued, ScanStatus.queued]);
  }

  Future<void> run(WidgetTester tester, Brightness brightness, String tag) async {
    await tester.runAsync(loadFonts); // real async: fonts load on the engine thread
    await h.start(
      tester,
      size: const Size(390, 844),
      prefsValues: {'theme_mode': brightness == Brightness.dark ? 'dark' : 'light'},
      seed: seed,
    );

    await shot(tester, '$tag-1-home');
    final lists = find.byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.vertical);
    await tester.drag(lists.first, const Offset(0, -520));
    await h.settle(tester);
    await shot(tester, '$tag-1b-home-scrolled');
    await tester.drag(lists.first, const Offset(0, 900));
    await h.settle(tester);

    await h.tapText(tester, 'Review Results');
    await shot(tester, '$tag-1c-review-queue');
    await h.tapText(tester, 'IMG_1003.png');
    await shot(tester, '$tag-1d-review');
    await tester.pageBack();
    await h.settle(tester);
    await tester.pageBack();
    await h.settle(tester);

    await h.tapText(tester, 'Courses');
    await shot(tester, '$tag-1e-courses');
    await h.tapText(tester, '(FWM) AGR 114');
    await shot(tester, '$tag-2-course');
    await h.tapText(tester, 'Enter scores');
    await shot(tester, '$tag-3-grid');
    await tester.pageBack();
    await h.settle(tester);
    await tester.pageBack();
    await h.settle(tester);
    await h.tapText(tester, 'Exports');
    await shot(tester, '$tag-4-export-tab');
    await h.tapText(tester, 'Settings');
    await shot(tester, '$tag-5-settings');
    await h.stop(tester);
  }

  testWidgets('screenshots (dark)', (tester) async => run(tester, Brightness.dark, 'dark'),
      skip: dir == null);
  testWidgets('screenshots (light)', (tester) async => run(tester, Brightness.light, 'light'),
      skip: dir == null);
}
