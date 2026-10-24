import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'raster.dart';

/// A photo read from disk for processing. The file itself is never changed.
class DecodedPhoto {
  const DecodedPhoto({
    required this.image,
    required this.originalWidth,
    required this.originalHeight,
  });

  /// Pixels at working size (at most `maxSide` on the long side).
  final ColorRaster image;

  /// Size of the stored file, in pixels, after the phone's rotation flag.
  final int originalWidth;
  final int originalHeight;

  /// Working pixels per original pixel.
  double get scale => image.width / originalWidth;
}

class PhotoDecodeException implements Exception {
  const PhotoDecodeException(this.message);
  final String message;
  @override
  String toString() => 'PhotoDecodeException($message)';
}

/// Reads [file] into RGBA, shrunk so the long side is at most [maxSide]. A
/// 12-megapixel photo is therefore never held at full size for analysis.
Future<DecodedPhoto> decodePhoto(File file, {int maxSide = 1600}) async {
  final Uint8List bytes;
  try {
    bytes = await file.readAsBytes();
  } on FileSystemException {
    throw const PhotoDecodeException('The photo file could not be read.');
  }
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  try {
    buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    final w = descriptor.width, h = descriptor.height;
    final long = math.max(w, h);
    final k = long > maxSide ? maxSide / long : 1.0;
    codec = await descriptor.instantiateCodec(
      targetWidth: k < 1 ? (w * k).round() : null,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final fw = image.width, fh = image.height;
    image.dispose();
    if (data == null) throw const PhotoDecodeException('The photo could not be decoded.');
    // If the codec turned the picture (a rotation flag), report the turned size.
    final swapped = (fw > fh) != (w > h) && w != h;
    return DecodedPhoto(
      image: ColorRaster(fw, fh, data.buffer.asUint8List()),
      originalWidth: swapped ? h : w,
      originalHeight: swapped ? w : h,
    );
  } on PhotoDecodeException {
    rethrow;
  } catch (_) {
    throw const PhotoDecodeException('This is not a photo UniMarkLy can read, or the file is damaged.');
  } finally {
    codec?.dispose();
    descriptor?.dispose();
    buffer?.dispose();
  }
}

/// Encodes grey pixels as a PNG, for showing or saving a processed copy.
Future<Uint8List> encodePng(Raster r) async {
  final rgba = Uint8List(r.width * r.height * 4);
  for (var i = 0, p = 0; i < r.data.length; i++, p += 4) {
    rgba[p] = rgba[p + 1] = rgba[p + 2] = r.data[i];
    rgba[p + 3] = 255;
  }
  return _encode(rgba, r.width, r.height);
}

Future<Uint8List> encodeColorPng(ColorRaster c) => _encode(c.rgba, c.width, c.height);

Future<Uint8List> _encode(Uint8List rgba, int w, int h) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
  final descriptor = ui.ImageDescriptor.raw(buffer, width: w, height: h, pixelFormat: ui.PixelFormat.rgba8888);
  final codec = await descriptor.instantiateCodec();
  final frame = await codec.getNextFrame();
  final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
  frame.image.dispose();
  codec.dispose();
  descriptor.dispose();
  buffer.dispose();
  return data!.buffer.asUint8List();
}
