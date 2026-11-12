import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// Renders the widget behind [boundaryKey] to a PNG and opens the share
/// sheet.
///
/// The document asks for the shareable summary to come from the widget
/// tree rather than a server: what the member shares is exactly what
/// they were looking at, and nothing leaves the device until they choose
/// to send it.
///
/// The bytes are handed to the share sheet directly rather than written
/// to a temporary file. A file would mean `dart:io`, which does not
/// exist on the web, and the dashboard is a web build of this same
/// codebase — one import would stop it compiling.
Future<void> shareSummary({
  required GlobalKey boundaryKey,
  required String text,
}) async {
  final boundary =
      boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return;

  // 3x so the image is still sharp when a messaging app scales it up.
  final image = await boundary.toImage(pixelRatio: 3);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  if (data == null) return;

  await SharePlus.instance.share(
    ShareParams(
      text: text,
      files: [
        XFile.fromData(
          data.buffer.asUint8List(),
          mimeType: 'image/png',
          name: 'deep-fitness-progress.png',
        ),
      ],
    ),
  );
}
