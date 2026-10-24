import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:unimarkly/core/widgets/ui_kit.dart';
import 'package:unimarkly/domain/scan.dart';
import 'package:unimarkly/services/scan/image_source.dart';

import '../support/images.dart';
import 'harness.dart';

/// The Home screen: its numbers come from stored uploads, and each control
/// does what its label says.
void main() {
  final h = AppHarness();

  // Tall, so the whole of the home screen is built and can be found.
  const tall = Size(390, 2200);

  Future<void> seedTwoCourses() async {
    final a = await h.createCourse(code: 'AGR 114');
    final b = await h.createCourse(code: 'BIO 201', department: 'FST', regNos: ['FST/24U/0101']);
    await h.seedBatch(a, states: [ScanStatus.confirmed, ScanStatus.confirmed, ScanStatus.needsReview]);
    await h.seedBatch(b, states: [ScanStatus.confirmed, ScanStatus.failed]);
  }

  /// The number shown in the card with this caption.
  Finder stat(String label, int value) => find.descendant(
        of: find.ancestor(of: find.text(label), matching: find.byType(GlowCard)).first,
        matching: find.text('$value'),
      );

  testWidgets('with no uploads: zeros, an explanation, and no review badge', (tester) async {
    await h.start(tester, size: tall, tab: null);

    expect(find.text('Start Scanning\nExam Scripts'), findsOneWidget);
    expect(find.text('No uploads yet'), findsOneWidget);
    for (final label in ['Batches Scanned', 'Students Extracted', 'Completed', 'Need Review']) {
      expect(stat(label, 0), findsOneWidget, reason: label);
    }
    expect(find.byTooltip('Review queue'), findsOneWidget);
    await h.stop(tester);
  });

  testWidgets('the numbers are counted from the stored uploads', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: seedTwoCourses);

    // 2 uploads; 5 photos, 1 of them failed, so 4 booklets; 3 confirmed; 1 waiting.
    expect(stat('Batches Scanned', 2), findsOneWidget);
    expect(stat('Students Extracted', 4), findsOneWidget);
    expect(stat('Completed', 3), findsOneWidget);
    expect(stat('Need Review', 1), findsOneWidget);
    expect(find.byTooltip('Review queue, 1 waiting'), findsOneWidget);
    await h.stop(tester);
  });

  testWidgets('recent batches show their counts and status, and can be filtered by course', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: seedTwoCourses);

    await h.reveal(tester, find.text('Recent Batches'));
    expect(find.textContaining('3 images | 2 confirmed'), findsOneWidget);
    expect(find.textContaining('2 images | 1 confirmed'), findsOneWidget);

    await h.tapText(tester, 'All courses');
    await h.tapText(tester, 'BIO 201');
    expect(find.textContaining('3 images | 2 confirmed'), findsNothing);
    expect(find.textContaining('2 images | 1 confirmed'), findsOneWidget);
    await h.stop(tester);
  });

  testWidgets('a batch can be deleted, and the delete undone', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: seedTwoCourses);

    await h.reveal(tester, find.text('Recent Batches'));
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await h.settle(tester);
    await h.tapText(tester, 'Delete');
    expect(find.text('Delete this upload?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await h.settle(tester);
    expect(find.textContaining('images |'), findsOneWidget);

    await h.tapText(tester, 'Undo');
    expect(find.textContaining('images |'), findsNWidgets(2));
    await h.stop(tester);
  });

  testWidgets('Review Results opens the booklets that wait, and the bell does too', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: seedTwoCourses);

    await h.tapText(tester, 'Review Results');
    expect(find.text('Review results'), findsOneWidget);
    expect(find.text('IMG_1002.png'), findsOneWidget);
    await tester.pageBack();
    await h.settle(tester);

    await tester.tap(find.byTooltip('Review queue, 1 waiting'));
    await h.settle(tester);
    expect(find.text('Review results'), findsOneWidget);
    await h.stop(tester);
  });

  testWidgets('Export File and Manage Courses switch to those tabs', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: seedTwoCourses);

    await h.tapText(tester, 'Manage Courses');
    expect(find.text('(FWM) AGR 114'), findsWidgets);
    await h.tapText(tester, 'Home');
    await h.tapText(tester, 'Export File');
    expect(find.text('Export'), findsWidgets);
    await h.stop(tester);
  });

  testWidgets('Choose Images stores the photos, queues them and opens Scan & Extract', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () async {
      await h.createCourse(code: 'AGR 114');
    });
    final dir = Directory(p.join(h.work.path, 'picked'))..createSync(recursive: true);
    final names = <PickedImage>[];
    await tester.runAsync(() async {
      for (var i = 0; i < 2; i++) {
        final f = File(p.join(dir.path, 'cover_$i.png'));
        await f.writeAsBytes(await makePng(300, 400, ui.Color(0xFF304050 + i * 0x101010)));
        names.add(PickedImage(name: 'cover_$i.png', path: f.path));
      }
    });
    h.imageSource.next = names;

    await h.tapText(tester, 'Choose Images');
    for (var i = 0; i < 20 && find.byType(BackButton).evaluate().isEmpty; i++) {
      await h.settle(tester);
    }

    expect(h.imageSource.calls, ['gallery']);
    // On the Scan & Extract screen for the new upload, with both photos in it.
    expect(find.text('cover_0.png'), findsWidgets);
    expect(find.text('cover_1.png'), findsWidgets);
    await h.stop(tester);
  });

  testWidgets('a refused camera says what to do and creates nothing', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: () async {
      await h.createCourse(code: 'AGR 114');
    });
    h.imageSource.error = Exception('camera_access_denied');

    await h.tapText(tester, 'Take Photo');
    expect(find.textContaining('Allow camera access'), findsOneWidget);
    expect(find.text('No uploads yet'), findsOneWidget);
    await h.stop(tester);
  });
}
