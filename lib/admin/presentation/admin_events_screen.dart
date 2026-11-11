import 'package:deepfitness/admin/application/admin_controllers.dart';
import 'package:deepfitness/admin/presentation/admin_shell.dart';
import 'package:deepfitness/admin/presentation/image_field.dart';
import 'package:deepfitness/core/models/base_fields.dart';
import 'package:deepfitness/core/models/event.dart';
import 'package:deepfitness/features/events/presentation/events_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Gym events. The list is the same query the app runs, so staff see
/// exactly what a member sees.
class AdminEventsScreen extends ConsumerWidget {
  const AdminEventsScreen({super.key});

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, {
    Event? existing,
  }) async {
    final draft = await showDialog<Event>(
      context: context,
      builder: (context) => _EventDialog(existing: existing),
    );
    if (draft == null) return;

    final saved = await ref
        .read(adminActionProvider.notifier)
        .run(
          (repository) => repository.saveEvent(
            draft,
            authorId: ref.read(adminAuthorIdProvider),
          ),
          refresh: [upcomingEventsProvider],
        );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(saved ? 'Saved.' : 'Could not save that.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(upcomingEventsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminHeader(
          title: 'Events',
          action: FilledButton.icon(
            onPressed: () => _edit(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('New event'),
          ),
        ),
        Expanded(
          child: events.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('$error')),
            data: (list) => list.isEmpty
                ? const Center(child: Text('Nothing coming up.'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final event = list[index];
                      final starts = event.startsAt;
                      return ListTile(
                        title: Text(event.title),
                        subtitle: Text(
                          [
                            if (starts != null)
                              '${starts.day}/${starts.month}/${starts.year}',
                            if (event.venue.isNotEmpty) event.venue,
                          ].join(' · '),
                        ),
                        onTap: () => _edit(context, ref, existing: event),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _EventDialog extends StatefulWidget {
  const _EventDialog({this.existing});

  final Event? existing;

  @override
  State<_EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<_EventDialog> {
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _description = TextEditingController(
    text: widget.existing?.description ?? '',
  );
  late final _venue = TextEditingController(text: widget.existing?.venue ?? '');
  late DateTime? _startsAt = widget.existing?.startsAt;
  late String? _imageUrl = widget.existing?.imageUrl;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _venue.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt ?? DateTime.now()),
    );
    if (!mounted) return;

    setState(() {
      _startsAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 0,
        time?.minute ?? 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final starts = _startsAt;

    return AlertDialog(
      title: Text(widget.existing == null ? 'New event' : 'Edit event'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ImageField(
              folder: 'events',
              id: widget.existing?.id ?? '',
              initialUrl: _imageUrl,
              onUploaded: (url) => setState(() => _imageUrl = url),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _venue,
              decoration: const InputDecoration(labelText: 'Venue'),
            ),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                starts == null
                    ? 'No date set'
                    : '${starts.day}/${starts.month}/${starts.year} at '
                          '${starts.hour.toString().padLeft(2, '0')}:'
                          '${starts.minute.toString().padLeft(2, '0')}',
              ),
              trailing: TextButton(
                onPressed: _pickDateTime,
                child: const Text('Pick date'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            // An event with no start time would never appear in the app:
            // the members' list filters on startsAt.
            if (_title.text.trim().isEmpty || _startsAt == null) return;
            Navigator.of(context).pop(
              Event(
                base: BaseFields(id: widget.existing?.id ?? ''),
                title: _title.text.trim(),
                description: _description.text.trim(),
                venue: _venue.text.trim(),
                startsAt: _startsAt,
                imageUrl: _imageUrl,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
