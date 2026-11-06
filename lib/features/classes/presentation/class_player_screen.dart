import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/features/classes/data/classes_repository.dart';
import 'package:deepfitness/core/widgets/async_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Plays a class video inside the app.
///
/// The guide is specific that a member is never thrown out to YouTube, so the
/// provider's embed URL is loaded in a webview rather than handed to
/// url_launcher. Only the provider and video id are ever stored; the URL is
/// built from them.
class ClassPlayerScreen extends ConsumerStatefulWidget {
  const ClassPlayerScreen({super.key});

  @override
  ConsumerState<ClassPlayerScreen> createState() => _ClassPlayerScreenState();
}

class _ClassPlayerScreenState extends ConsumerState<ClassPlayerScreen> {
  WebViewController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // The provider is read once: swapping the selected class while a video is
    // playing would otherwise reload the player underneath the member.
    final groupClass = ref.read(selectedClassProvider);
    if (groupClass == null) return;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.night)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _error = 'That video could not be loaded.';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(groupClass.embedUrl));
  }

  @override
  Widget build(BuildContext context) {
    final groupClass = ref.watch(selectedClassProvider);

    if (groupClass == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Class')),
        body: Center(
          child: AppEmptyState(
            icon: Icons.ondemand_video_rounded,
            title: 'No class selected',
            message: 'Pick a class to watch.',
            action: TextButton(
              onPressed: () => context.pop(),
              child: const Text('Go back'),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(groupClass.title)),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_controller != null)
                  WebViewWidget(controller: _controller!),
                if (_loading && _error == null)
                  const ColoredBox(
                    color: AppColors.night,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (_error != null)
                  ColoredBox(
                    color: AppColors.night,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.danger),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    groupClass.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${groupClass.durationMins} min',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText(context),
                    ),
                  ),
                  if (groupClass.description.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      groupClass.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
