import 'dart:convert';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

const _maxDimension = 900;
const _jpegQuality = 78;

/// Opens the gallery/file picker and returns the chosen photo downscaled and
/// re-encoded as base64 JPEG, ready to store in Hive. Returns null if the
/// user cancels or the file cannot be decoded.
///
/// Everything happens on-device: the photo never leaves local storage.
Future<String?> pickAndEncodeListingPhoto() async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1600,
    maxHeight: 1600,
  );
  if (picked == null) return null;

  final bytes = await picked.readAsBytes();
  var decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  // Respect EXIF rotation before resizing strips it.
  decoded = img.bakeOrientation(decoded);

  if (decoded.width > _maxDimension || decoded.height > _maxDimension) {
    decoded = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? _maxDimension : null,
      height: decoded.height > decoded.width ? _maxDimension : null,
    );
  }
  return base64Encode(img.encodeJpg(decoded, quality: _jpegQuality));
}
