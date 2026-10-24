import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../vision/digit_model.dart';

/// A recognition model shipped with the app, as its manifest describes it.
class ModelInfo {
  const ModelInfo({
    required this.id,
    required this.version,
    required this.file,
    required this.bytes,
    required this.sha256,
    required this.licence,
    required this.measured,
  });

  final String id;
  final String version;
  final String file;
  final int bytes;
  final String sha256;
  final String licence;

  /// What was measured when the model was built, copied from the manifest so
  /// a stored reading can say exactly which model produced it.
  final Map<String, dynamic> measured;

  Map<String, String> toJson() => {'id': id, 'version': version, 'sha256': sha256};

  static ModelInfo fromManifest(Map<String, dynamic> j) => ModelInfo(
        id: j['id'] as String,
        version: j['version'] as String,
        file: j['file'] as String,
        bytes: j['bytes'] as int,
        sha256: j['sha256'] as String,
        licence: j['licence'] as String? ?? '',
        measured: (j['measured'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}

/// A model that is missing, damaged or the wrong size. It carries words for the
/// examiner; the app shows them instead of quietly reading with something else.
class ModelException implements Exception {
  const ModelException(this.message);
  final String message;
  @override
  String toString() => 'ModelException($message)';
}

class LoadedDigitModel {
  const LoadedDigitModel(this.info, this.weights);
  final ModelInfo info;

  /// The verified weight file; the model is built from it where it is used
  /// (possibly in another isolate).
  final Uint8List weights;

  DigitModel build() => DigitModel.fromBytes(weights);
}

/// Loads the models in `assets/models` and checks each against its manifest
/// (size and SHA-256) before anything reads with it.
class ModelRegistry {
  const ModelRegistry._();

  static const digitsManifest = 'assets/models/digits_v1.manifest.json';

  static Future<LoadedDigitModel> loadDigits([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    final Map<String, dynamic> manifest;
    try {
      manifest = jsonDecode(await b.loadString(digitsManifest)) as Map<String, dynamic>;
    } catch (_) {
      throw const ModelException('The handwriting model is missing from this install of the app. Reinstall UniMarkLy, or enter the marks by hand.');
    }
    final info = ModelInfo.fromManifest(manifest);
    final Uint8List bytes;
    try {
      final data = await b.load('assets/models/${info.file}');
      bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } catch (_) {
      throw ModelException('The handwriting model file (${info.file}) is missing. Reinstall UniMarkLy, or enter the marks by hand.');
    }
    if (bytes.length != info.bytes) {
      throw ModelException('The handwriting model file is the wrong size (${bytes.length} bytes, expected ${info.bytes}). Reinstall UniMarkLy.');
    }
    final digest = sha256.convert(bytes).toString();
    if (digest != info.sha256) {
      throw const ModelException('The handwriting model file is damaged (its checksum does not match). Reinstall UniMarkLy.');
    }
    try {
      DigitModel.fromBytes(bytes);
    } on FormatException catch (e) {
      throw ModelException('The handwriting model could not be used: ${e.message}');
    }
    return LoadedDigitModel(info, bytes);
  }
}
