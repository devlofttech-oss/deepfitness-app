import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/models/group_class.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// The class video, embedded in the page.
///
/// The document is explicit that the member is not thrown out to YouTube,
/// so the provider's embed player is loaded in a web view rather than the
/// video URL being handed to the system browser.
class VideoPlayerView extends StatefulWidget {
  const VideoPlayerView({super.key, required this.groupClass});

  final GroupClass groupClass;

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.surface)
      // The embed itself is the only thing this view may load. A tap on
      // a related video or a channel link must not turn the player into
      // a browser inside the app.
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) =>
              request.url.startsWith(widget.groupClass.embedUrl)
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
        ),
      )
      ..loadRequest(Uri.parse(widget.groupClass.embedUrl));
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ColoredBox(
        color: AppColors.surface,
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
