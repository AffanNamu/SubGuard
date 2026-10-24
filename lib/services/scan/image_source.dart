import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart' as ip;

/// A photo the examiner picked, still in the phone's own storage.
class PickedImage {
  const PickedImage({required this.name, required this.path});

  final String name;
  final String path;
}

/// How much to shrink a photo when it is picked. Phone cameras make 12 MP
/// files; the booklet cover is readable well below that, and smaller files
/// are faster to read and to store.
enum PhotoQuality {
  standard('Standard', 'Smaller files, fastest', 85, 2400),
  high('High', 'Best for handwriting (recommended)', 92, 3200);

  const PhotoQuality(this.label, this.description, this.jpegQuality, this.maxEdge);
  final String label;
  final String description;
  final int jpegQuality;
  final int maxEdge;

  static PhotoQuality fromName(String? n) =>
      PhotoQuality.values.firstWhere((q) => q.name == n, orElse: () => PhotoQuality.high);
}

/// Where photos come from. A class, not static calls, so tests can supply
/// their own.
abstract class ImageSource {
  /// One photo from the camera. Empty if the examiner cancelled.
  Future<List<PickedImage>> takePhoto(PhotoQuality quality);

  /// Several photos from the gallery.
  Future<List<PickedImage>> chooseImages(PhotoQuality quality);

  /// Image files from the phone's file storage.
  Future<List<PickedImage>> chooseFiles();
}

class DeviceImageSource implements ImageSource {
  final ip.ImagePicker _picker = ip.ImagePicker();

  @override
  Future<List<PickedImage>> takePhoto(PhotoQuality quality) async {
    final x = await _picker.pickImage(
      source: ip.ImageSource.camera,
      imageQuality: quality.jpegQuality,
      maxWidth: quality.maxEdge.toDouble(),
      maxHeight: quality.maxEdge.toDouble(),
    );
    return x == null ? const [] : [PickedImage(name: _nameOf(x), path: x.path)];
  }

  @override
  Future<List<PickedImage>> chooseImages(PhotoQuality quality) async {
    final xs = await _picker.pickMultiImage(
      imageQuality: quality.jpegQuality,
      maxWidth: quality.maxEdge.toDouble(),
      maxHeight: quality.maxEdge.toDouble(),
    );
    return [for (final x in xs) PickedImage(name: _nameOf(x), path: x.path)];
  }

  @override
  Future<List<PickedImage>> chooseFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif', 'pdf'],
    );
    if (result == null) return const [];
    return [
      for (final f in result.files)
        if (f.path != null) PickedImage(name: f.name, path: f.path!),
    ];
  }

  static String _nameOf(ip.XFile x) => x.name.isNotEmpty ? x.name : x.path.split('/').last;
}
