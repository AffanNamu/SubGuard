import 'dart:io';

import 'package:flutter/services.dart';

/// An asset bundle that reads the project's `assets/` folder straight from disk.
///
/// Widget tests run the app on a fake clock, and an asset request started in
/// one test's fake zone can be left pending for the next. Reading the files
/// with plain real I/O, once, outside that zone, keeps tests independent of
/// each other. Optionally [weights] replaces the model weight file, to test a
/// damaged, truncated or missing model.
class FileAssetBundle extends CachingAssetBundle {
  FileAssetBundle({this.replaceWeights = false, this.weights});

  final bool replaceWeights;
  final Uint8List? weights;

  @override
  Future<ByteData> load(String key) async {
    if (replaceWeights && key.endsWith('.bin')) {
      if (weights == null) throw Exception('missing: $key');
      return ByteData.sublistView(weights!);
    }
    return ByteData.sublistView(File(key).readAsBytesSync());
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async => File(key).readAsStringSync();
}
