import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimarkly/domain/scan.dart';

import 'harness.dart';

/// Scan & Extract: what the screen says is what is stored, and reading a
/// batch moves its photos on to review.
void main() {
  final h = AppHarness();
  const tall = Size(390, 2000);

  late String batchId;

  Future<void> seed() async {
    final course = await h.createCourse(code: 'AGR 114', regNos: ['FWM/24U/0538']);
    batchId = await h.seedBatch(course, states: [ScanStatus.queued, ScanStatus.queued, ScanStatus.failed]);
    final failed = (await h.scans.scansOf(batchId)).firstWhere((s) => s.status == ScanStatus.failed);
    await h.scans.setStatus(failed.id, ScanStatus.failed, error: 'This photo could not be opened. Choose it again.');
  }


  testWidgets('shows the real state of every photo, with the reason a photo failed', (tester) async {
    await h.start(
      tester,
      size: tall,
      tab: null,
      prefsValues: {'read_automatically': false},
      seed: seed,
    );
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await h.settle(tester);
    await h.tapText(tester, 'Open');

    expect(find.text('Scan & Extract'), findsWidgets);
    expect(find.text('IMG_1000.png'), findsWidgets);
    expect(find.text('This photo could not be opened. Choose it again.'), findsOneWidget);
    expect(find.text('Read 2 photos'), findsOneWidget);
    expect(find.textContaining('PDF is not supported yet'), findsOneWidget);
    await h.stop(tester);
  });

  testWidgets('with automatic reading off the photos wait until Read is pressed', (tester) async {
    await h.start(tester, size: tall, tab: null, prefsValues: {'read_automatically': false}, seed: seed);
    // Opening the app did not touch them.
    final before = await tester.runAsync(() => h.scans.batches());
    expect(before!.single.counts.queued, 2);

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await h.settle(tester);
    await h.tapText(tester, 'Open');
    await h.tapText(tester, 'Read 2 photos');
    // The real pipeline reads them (real isolates), so this waits in real time.
    await h.waitForReading(tester, untilQueueEmpty: true);
    await h.settle(tester);

    // The reader on this test phone is the "unavailable" one, which says so
    // and leaves every value for the examiner. Nothing is invented.
    final after = await tester.runAsync(() => h.scans.batches());
    expect(after!.single.counts.queued, 0);
    expect(after.single.counts.needsReview, 2);
    expect(after.single.counts.confirmed, 0);
    expect(find.text('Next: Review Results'), findsOneWidget);
    await h.stop(tester);
  });

  testWidgets('with automatic reading on, queued photos are read when the app opens', (tester) async {
    await h.start(tester, size: tall, tab: null, seed: seed);
    // The real pipeline reads the photos (real isolates), so this waits in real time.
    await h.waitForReading(tester);
    await h.settle(tester);
    final after = await tester.runAsync(() => h.scans.batches());
    expect(after!.single.counts.queued, 0);
    expect(after.single.counts.needsReview, 2);
    await h.stop(tester);
  });
}
