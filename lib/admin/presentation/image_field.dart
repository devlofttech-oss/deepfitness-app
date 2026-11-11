import 'dart:typed_data';

import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Picks an image, uploads it and hands back the download URL.
///
/// The upload happens here rather than when the surrounding form is
/// saved, so a slow upload does not hold up the dialog and a failure is
/// shown against the picture rather than the whole record.
class ImageField extends ConsumerStatefulWidget {
  const ImageField({
    super.key,
    required this.folder,
    required this.id,
    required this.initialUrl,
    required this.onUploaded,
  });

  /// Storage folder, matching the rules: `exercises` or `events`.
  final String folder;

  /// Document id, or anything stable for a record not yet saved.
  final String id;

  final String? initialUrl;
  final ValueChanged<String> onUploaded;

  @override
  ConsumerState<ImageField> createState() => _ImageFieldState();
}

class _ImageFieldState extends ConsumerState<ImageField> {
  late String? _url = widget.initialUrl;
  Uint8List? _preview;
  bool _busy = false;
  String? _error;

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _preview = bytes;
      _busy = true;
      _error = null;
    });

    try {
      final url = await ref
          .read(storageServiceProvider)
          .uploadContentImage(
            folder: widget.folder,
            id: widget.id.isEmpty ? 'drafts' : widget.id,
            bytes: bytes,
          );
      if (!mounted) return;
      setState(() {
        _url = url;
        _busy = false;
      });
      widget.onUploaded(url);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not upload that image.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _busy ? null : _pick,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.canvas(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderDark),
              image: preview != null
                  ? DecorationImage(
                      image: MemoryImage(preview),
                      fit: BoxFit.cover,
                    )
                  : _url != null
                  ? DecorationImage(
                      image: NetworkImage(_url!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _busy
                ? const Center(child: CircularProgressIndicator())
                : (preview == null && _url == null)
                ? const Center(child: Icon(Icons.add_photo_alternate_outlined))
                : null,
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
