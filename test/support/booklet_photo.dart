import 'dart:io';

import 'package:unimarkly/services/vision/photo_codec.dart';
import 'package:unimarkly/services/vision/raster.dart';

/// The one real booklet photograph in the evaluation set (see eval/README.md).
const bookletPath = 'eval/dataset/booklet-001/image.jpg';

Future<ColorRaster> loadBooklet() async => (await decodePhoto(File(bookletPath), maxSide: 4000)).image;
