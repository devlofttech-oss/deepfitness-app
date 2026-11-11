import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/models/announcement.dart';
import 'package:deepfitness/features/notifications/presentation/announcements_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Everything the gym has sent.
///
/// This is why each push is mirrored into Firestore: a notification that
/// was swiped away or arrived while the phone was off is still here.
class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcements = ref.watch(announcementsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Notices')),
      body: SafeArea(
        child: announcements.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const _Message(
            'Could not load notices. Check your connection.',
          ),
          data: (list) => list.isEmpty
              ? const _Message('Nothing from the gym yet.')
              : RefreshIndicator(
                  onRefresh: () async => ref.invalidate(announcementsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _AnnouncementCard(announcement: list[index]),
                  ),
                ),
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final sent = announcement.sentAt;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            announcement.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (sent != null) ...[
            const SizedBox(height: 4),
            Text(
              '${sent.day}/${sent.month}/${sent.year}',
              style: TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
          if (announcement.body.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(announcement.body),
          ],
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.onSurfaceVariant),
        ),
      ),
    );
  }
}
