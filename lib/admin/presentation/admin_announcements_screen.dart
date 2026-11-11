import 'package:deepfitness/admin/application/admin_controllers.dart';
import 'package:deepfitness/admin/presentation/admin_shell.dart';
import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/features/notifications/presentation/announcements_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compose and send a broadcast.
class AdminAnnouncementsScreen extends ConsumerStatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  ConsumerState<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState
    extends ConsumerState<AdminAnnouncementsScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  String _audience = 'all';

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_title.text.trim().isEmpty) return;

    // Sending reaches every member's phone and cannot be recalled, so it
    // is confirmed rather than fired on one tap.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send to everyone?'),
        content: Text(
          'This pushes "${_title.text.trim()}" to every member in the '
          '$_audience audience. It cannot be unsent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final sent = await ref
        .read(adminActionProvider.notifier)
        .run(
          (repository) => repository.sendAnnouncement(
            title: _title.text.trim(),
            body: _body.text.trim(),
            audience: _audience,
          ),
          refresh: [announcementsProvider],
        );

    if (!mounted) return;
    if (sent) {
      _title.clear();
      _body.clear();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(sent ? 'Sent.' : 'Could not send that.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sending = ref.watch(adminActionProvider).isLoading;
    final past = ref.watch(announcementsProvider);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const AdminHeader(title: 'Notices'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _body,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Audience:'),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _audience,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Everyone')),
                      DropdownMenuItem(
                        value: 'members',
                        child: Text('Members'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _audience = value ?? 'all'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: sending ? null : _send,
                    icon: const Icon(Icons.send),
                    label: Text(sending ? 'Sending…' : 'Send'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text('Sent before', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              past.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Could not load past notices.'),
                data: (list) => list.isEmpty
                    ? Text(
                        'Nothing sent yet.',
                        style: TextStyle(
                          color: AppColors.secondaryText(context),
                        ),
                      )
                    : Column(
                        children: [
                          for (final announcement in list)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(announcement.title),
                              subtitle: Text(announcement.body),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
