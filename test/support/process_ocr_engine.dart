import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:unimarkly/domain/ocr.dart';
import 'package:unimarkly/services/reader/ocr_engine.dart';
import 'package:unimarkly/services/reader/region_crop.dart';

/// Runs the real PP-OCR model (through ONNX Runtime in Python) for tests, so
/// pipeline tests exercise an actual recogniser and not a canned answer. It
/// stands in for paddle_ocr_native, which only exists on a phone.
class ProcessOcrEngine implements RegionOcrEngine {
  ProcessOcrEngine._(this._process) {
    _lines = _process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(_onLine);
  }

  static ProcessOcrEngine? _shared;

  /// One shared process; model start-up takes a couple of seconds.
  static Future<ProcessOcrEngine> start() async {
    final existing = _shared;
    if (existing != null) return existing;
    final p = await Process.start('python3', ['tool/bench/ocr_server.py'], environment: {'PYTHONWARNINGS': 'ignore'});
    final engine = ProcessOcrEngine._(p);
    await engine._ready.future.timeout(const Duration(seconds: 60));
    return _shared = engine;
  }

  final Process _process;
  late final StreamSubscription<String> _lines;
  final _ready = Completer<void>();
  final _pending = <Completer<OcrDocument>>[];
  Future<void> _queue = Future.value();
  int calls = 0;

  @override
  String get name => 'PP-OCRv4 via ONNX Runtime (test stand-in for PaddleOCR)';

  void _onLine(String line) {
    if (!_ready.isCompleted && line.trim() == 'ready') {
      _ready.complete();
      return;
    }
    if (_pending.isEmpty) return;
    final j = jsonDecode(line) as Map<String, dynamic>;
    _pending.removeAt(0).complete(OcrDocument(
      engine: name,
      lines: [
        for (final l in (j['lines'] as List).cast<Map<String, dynamic>>())
          OcrLine(
            l['text'] as String,
            Region((l['left'] as num).toDouble(), (l['top'] as num).toDouble(), (l['right'] as num).toDouble(), (l['bottom'] as num).toDouble()),
            confidence: (l['confidence'] as num).toDouble(),
          ),
      ],
    ));
  }

  @override
  Future<OcrDocument> recognize(File image, {required int width, required int height}) {
    // The process answers one request at a time, in order.
    final next = _queue.then((_) {
      final c = Completer<OcrDocument>();
      _pending.add(c);
      calls++;
      _process.stdin.writeln(jsonEncode({'path': image.absolute.path}));
      return c.future;
    });
    _queue = next.then((_) {}, onError: (_) {});
    return next;
  }

  @override
  Future<OcrDocument> recognizeRegion(File image, Region region) async {
    // The same close-up the phone makes before reading a region.
    final crop = await cropForReading(image, region, boostContrast: false, maxWidth: 1280);
    if (crop == null) return OcrDocument(engine: name, lines: const []);
    try {
      return await recognize(crop.file, width: crop.width, height: crop.height);
    } finally {
      try {
        await crop.file.parent.delete(recursive: true);
      } catch (_) {}
    }
  }

  Future<void> stop() async {
    await _lines.cancel();
    _process.kill();
    _shared = null;
  }
}
