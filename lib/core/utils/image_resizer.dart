
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// The longest edge a profile photo is stored at.
///
/// A member's photo is only ever shown in an avatar, so anything larger is
/// bytes the gym pays to store and the member pays to upload.
const int _maxEdge = 1024;

/// JPEG quality for the resized photo. 85 is the point where further
/// compression starts to show on a face.
const int _quality = 85;

/// Resizes an image to fit [_maxEdge] and re-encodes it as JPEG.
///
/// The document requires the resize to happen on the device, before the
/// upload: a modern phone camera produces several megabytes and the
/// storage rules reject anything over five.
///
/// Decoding runs on a background isolate, because a full resolution photo
/// takes long enough to drop frames on the main one.
Future<Uint8List> resizeForUpload(Uint8List original) {
  return compute(_resize, original);
}

Uint8List _resize(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    // Not an image this package understands. Hand the original back and
    // let the storage rules reject it rather than guessing at a repair.
    return bytes;
  }

  // An image already within the limit is re-encoded rather than returned
  // as-is, so a 4 MB PNG of modest dimensions still shrinks.
  final longestEdge = decoded.width > decoded.height
      ? decoded.width
      : decoded.height;

  final resized = longestEdge <= _maxEdge
      ? decoded
      : img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? _maxEdge : null,
          height: decoded.height > decoded.width ? _maxEdge : null,
          interpolation: img.Interpolation.average,
        );

  return img.encodeJpg(resized, quality: _quality);
}
