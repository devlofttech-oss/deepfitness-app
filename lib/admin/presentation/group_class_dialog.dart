import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/models/base_fields.dart';
import 'package:deepfitness/core/models/group_class.dart';
import 'package:flutter/material.dart';

/// Creates or edits a class in the library.
///
/// The video is a provider plus an id, never an upload: the document is
/// explicit that class videos are linked, not hosted.
class GroupClassDialog extends StatefulWidget {
  const GroupClassDialog({super.key, this.existing});

  final GroupClass? existing;

  @override
  State<GroupClassDialog> createState() => _GroupClassDialogState();
}

class _GroupClassDialogState extends State<GroupClassDialog> {
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _description = TextEditingController(
    text: widget.existing?.description ?? '',
  );
  late final _videoId = TextEditingController(
    text: widget.existing?.videoId ?? '',
  );
  late final _duration = TextEditingController(
    text: '${widget.existing?.durationMins ?? 30}',
  );
  late VideoProvider _provider =
      widget.existing?.videoProvider ?? VideoProvider.youtube;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _videoId.dispose();
    _duration.dispose();
    super.dispose();
  }

  /// Accepts a whole URL as well as a bare id, because that is what gets
  /// pasted in practice.
  String _extractVideoId(String input) {
    final value = input.trim();
    if (!value.contains('/') && !value.contains('?')) return value;

    final uri = Uri.tryParse(value);
    if (uri == null) return value;

    final fromQuery = uri.queryParameters['v'];
    if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;

    final segments = uri.pathSegments.where((part) => part.isNotEmpty);
    return segments.isEmpty ? value : segments.last;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'New class' : 'Edit class'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  DropdownButton<VideoProvider>(
                    value: _provider,
                    items: const [
                      DropdownMenuItem(
                        value: VideoProvider.youtube,
                        child: Text('YouTube'),
                      ),
                      DropdownMenuItem(
                        value: VideoProvider.vimeo,
                        child: Text('Vimeo'),
                      ),
                    ],
                    onChanged: (value) => setState(
                      () => _provider = value ?? VideoProvider.youtube,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _videoId,
                      decoration: const InputDecoration(
                        labelText: 'Video id or link',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Paste the whole link if that is easier; the id is pulled '
                'out of it. The video stays on the provider and is '
                'embedded, never uploaded here.',
                style: TextStyle(
                  color: AppColors.secondaryText(context),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _duration,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration in minutes',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_title.text.trim().isEmpty) return;
            Navigator.of(context).pop(
              GroupClass(
                base: BaseFields(id: widget.existing?.id ?? ''),
                title: _title.text.trim(),
                description: _description.text.trim(),
                videoProvider: _provider,
                videoId: _extractVideoId(_videoId.text),
                thumbnailUrl: widget.existing?.thumbnailUrl,
                durationMins: int.tryParse(_duration.text) ?? 0,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
