import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Renders the widget behind [key] to a PNG and opens the share sheet.
///
/// The document asks for the shareable summary to come from the widget
/// tree rather than a server: what the member shares is exactly what they
/// were looking at, and nothing leaves the device until they choose to
/// send it.
Future<void> shareSummary({
  required GlobalKey boundaryKey,
  required String text,
}) async {
  final boundary =
      boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return;

  // 3x so the image is still sharp when a messaging app scales it up.
  final image = await boundary.toImage(pixelRatio: 3);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) return;

  final directory = await getTemporaryDirectory();
  final file = File(
    '${directory.path}/deep-fitness-summary-'
    '${DateTime.now().millisecondsSinceEpoch}.png',
  );
  await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], text: text),
  );
}
