import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:unimarkly/data/repositories/recognition_repository.dart';
import 'package:unimarkly/domain/ocr.dart';
import 'package:unimarkly/services/export/labelled_export.dart';
import 'package:unimarkly/services/scan/scan_files.dart';

import '../support/booklet_photo.dart';

/// The export of confirmed values for improving the reader: pictures of the
/// handwriting and the text the examiner confirmed, made only on request.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory work;
  late ScanFiles files;

  setUp(() {
    work = Directory.systemTemp.createTempSync('unimarkly_labels_');
    files = ScanFiles(Directory(p.join(work.path, 'scans')));
    final target = files.resolve('b1/photo.jpg');
    target.parent.createSync(recursive: true);
    File(bookletPath).copySync(target.path);
  });
  tearDown(() => work.deleteSync(recursive: true));

  LabelledExample example(String field, String text, Region region, {String photo = 'b1/photo.jpg', String decision = 'accepted', String? machine}) => LabelledExample(
        scanId: 's1',
        courseId: 'c1',
        photoPath: photo,
        fieldKey: field,
        kind: 'mark',
        text: text,
        region: region,
        decision: decision,
        reviewedAt: DateTime.utc(2026, 10, 24, 12),
        machineValue: machine,
      );

  Future<ui.Image> decode(List<int> bytes) async => (await (await ui.instantiateImageCodec(bytes as dynamic)).getNextFrame()).image;

  test('nothing to export gives no file', () async {
    expect(await LabelledExport.build(examples: const [], files: files, directory: Directory(p.join(work.path, 'out'))), isNull);
  });

  test('each confirmed value becomes a cropped picture of where it was written, with its text', () async {
    final result = await LabelledExport.build(
      examples: [
        example('mark_q5', '5.5', const Region(0.775, 0.490, 0.880, 0.532), machine: '5.5'),
        example('mark_q4', '2.0', const Region(0.775, 0.434, 0.880, 0.472), decision: 'edited', machine: '2.61'),
      ],
      files: files,
      directory: Directory(p.join(work.path, 'out')),
      now: DateTime.utc(2026, 10, 24, 12),
    );
    expect(result, isNotNull);
    expect(result!.examples, 2);
    expect(result.skipped, 0);

    final zip = ZipDecoder().decodeBytes(result.file.readAsBytesSync());
    final names = zip.files.map((f) => f.name).toList();
    expect(names, containsAll(['labels.json', 'README.txt']));
    final crops = names.where((n) => n.startsWith('crops/')).toList();
    expect(crops, hasLength(2));

    final labels = jsonDecode(utf8.decode(zip.findFile('labels.json')!.content as List<int>)) as Map<String, dynamic>;
    final rows = (labels['examples'] as List).cast<Map<String, dynamic>>();
    expect(rows.map((r) => r['text']), ['5.5', '2.0']);
    expect(rows.map((r) => r['decision']), ['accepted', 'edited']);
    expect(rows[1]['machine_value'], '2.61', reason: 'what the reader got wrong is kept beside what was confirmed');
    expect(rows.every((r) => r['confirmed_at'] == '2026-10-24T12:00:00.000Z'), isTrue);

    // The crop is the region plus its padding, from the original photograph (810 x 1080).
    final image = await decode(zip.findFile(crops.first)!.content as List<int>);
    final expectedW = 0.105 * 810 * (1 + 2 * LabelledExport.padding), expectedH = 0.042 * 1080 * (1 + 2 * LabelledExport.padding);
    expect(image.width, closeTo(expectedW, 3));
    expect(image.height, closeTo(expectedH, 3));
  });

  test('an example whose photo is gone is left out and counted, not a failure', () async {
    final result = await LabelledExport.build(
      examples: [
        example('mark_q5', '5.5', const Region(0.775, 0.490, 0.880, 0.532)),
        example('mark_q1', '1.0', const Region(0.775, 0.340, 0.880, 0.378), photo: 'gone/missing.jpg'),
      ],
      files: files,
      directory: Directory(p.join(work.path, 'out')),
    );
    expect(result!.examples, 1);
    expect(result.skipped, 1);
  });

  test('when every photo is gone there is nothing to export', () async {
    final result = await LabelledExport.build(
      examples: [example('mark_q1', '1.0', const Region(0.775, 0.340, 0.880, 0.378), photo: 'gone/missing.jpg')],
      files: files,
      directory: Directory(p.join(work.path, 'out')),
    );
    expect(result, isNull);
  });

  test('the file says what it holds and that it is personal data', () async {
    final result = await LabelledExport.build(
      examples: [example('mark_q5', '5.5', const Region(0.775, 0.490, 0.880, 0.532))],
      files: files,
      directory: Directory(p.join(work.path, 'out')),
    );
    final zip = ZipDecoder().decodeBytes(result!.file.readAsBytesSync());
    final readme = utf8.decode(zip.findFile('README.txt')!.content as List<int>);
    expect(readme, contains('real handwriting'));
    expect(readme, contains('agreement of the people concerned'));
    expect(readme, contains('Nothing was sent anywhere'));
  });
}
