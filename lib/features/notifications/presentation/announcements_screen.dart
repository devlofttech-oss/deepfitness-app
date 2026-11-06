import 'package:deepfitness/core/models/announcement.dart';
import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/features/notifications/data/announcements_repository.dart';
import 'package:deepfitness/core/widgets/async_state.dart';
import 'package:deepfitness/core/widgets/page_header.dart';
import 'package:deepfitness/core/widgets/premium_card.dart';
import 'package:deepfitness/core/widgets/premium_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcements = ref.watch(announcementsProvider);

    return PremiumScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Notifications',
            subtitle: 'Everything the gym has sent you',
          ),
          const SizedBox(height: 18),
          AsyncStateView(
            value: announcements,
            onRetry: () => ref.invalidate(announcementsProvider),
            data: (items) => items.isEmpty
                ? const AppEmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: 'Nothing yet',
                    message: 'Gym announcements will show up here.',
                  )
                : Column(
                    children: [
                      for (final item in items)
                        _AnnouncementCard(announcement: item),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final link = announcement.deepLink;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    announcement.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _relative(announcement.sentAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              announcement.body,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (announcement.sentBy != null) ...[
              const SizedBox(height: 8),
              Text(
                'From ${announcement.sentBy}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.secondaryText(context),
                ),
              ),
            ],
            if (link != null && link.isNotEmpty) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  // The deep link comes from an admin-composed announcement,
                  // so it is only ever followed within the app.
                  onPressed: () => context.go(link),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Take me there'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _relative(DateTime when) {
    final difference = DateTime.now().difference(when);
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${when.day} ${months[when.month - 1]}';
  }
}
