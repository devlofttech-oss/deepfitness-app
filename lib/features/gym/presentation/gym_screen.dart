import 'package:deepfitness/core/models/group_class.dart';
import 'package:deepfitness/core/models/gym_event.dart';
import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:deepfitness/features/classes/data/classes_repository.dart';
import 'package:deepfitness/features/events/data/events_repository.dart';
import 'package:deepfitness/shared/widgets/async_state.dart';
import 'package:deepfitness/shared/widgets/page_header.dart';
import 'package:deepfitness/shared/widgets/premium_card.dart';
import 'package:deepfitness/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Classes and events share one tab: both are "what else is on at the gym",
/// and two more items would crowd the bottom bar.
class GymScreen extends ConsumerWidget {
  const GymScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: PageHeader(
                  title: 'At the gym',
                  subtitle: 'Classes to book and events to join',
                ),
              ),
              const TabBar(
                tabs: [
                  Tab(text: 'Classes'),
                  Tab(text: 'Events'),
                ],
              ),
              const Expanded(
                child: TabBarView(
                  children: [_ClassesTab(), _EventsTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------- classes

class _ClassesTab extends ConsumerWidget {
  const _ClassesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(upcomingSessionsProvider);
    final classes = ref.watch(groupClassesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(upcomingSessionsProvider);
        ref.invalidate(groupClassesProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        children: [
          Text(
            'Next sessions',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          AsyncStateView(
            value: sessions,
            onRetry: () => ref.invalidate(upcomingSessionsProvider),
            data: (items) => items.isEmpty
                ? const AppEmptyState(
                    icon: Icons.event_busy_rounded,
                    title: 'No class times yet',
                    message: 'Scheduled classes will show up here.',
                  )
                : Column(
                    children: [
                      for (final session in items)
                        _SessionCard(session: session),
                    ],
                  ),
          ),
          const SizedBox(height: 28),
          Text(
            'Watch any time',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          AsyncStateView(
            value: classes,
            onRetry: () => ref.invalidate(groupClassesProvider),
            data: (items) => items.isEmpty
                ? const AppEmptyState(
                    icon: Icons.ondemand_video_rounded,
                    title: 'No class videos yet',
                    message: 'On-demand classes will show up here.',
                  )
                : Column(
                    children: [
                      for (final item in items)
                        _ClassVideoCard(
                          groupClass: item,
                          onTap: () {
                            ref
                                .read(selectedClassProvider.notifier)
                                .select(item);
                            context.push('/classes/watch');
                          },
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends ConsumerStatefulWidget {
  const _SessionCard({required this.session});

  final ClassSession session;

  @override
  ConsumerState<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends ConsumerState<_SessionCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final booking = session.myBooking;
    final isBooked = booking?.status == BookingStatus.booked;
    final isWaitlisted = booking?.status == BookingStatus.waitlisted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.classTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatWhen(session.startsAt)}  •  ${session.instructor}',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(
                              color: AppColors.secondaryText(context),
                            ),
                      ),
                    ],
                  ),
                ),
                _PlacesBadge(session: session),
              ],
            ),
            if (isWaitlisted) ...[
              const SizedBox(height: 10),
              Text(
                'You are number ${booking!.position} on the waitlist.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 14),
            PrimaryButton(
              label: _label(isBooked, isWaitlisted, session),
              icon: isBooked || isWaitlisted
                  ? Icons.close_rounded
                  : Icons.event_available_rounded,
              outline: isBooked || isWaitlisted,
              onPressed: _busy ? null : () => _toggle(isBooked || isWaitlisted),
            ),
          ],
        ),
      ),
    );
  }

  String _label(bool isBooked, bool isWaitlisted, ClassSession session) {
    if (_busy) return 'Working...';
    if (isBooked) return 'Cancel my place';
    if (isWaitlisted) return 'Leave the waitlist';
    return session.isFull ? 'Join the waitlist' : 'Book a place';
  }

  Future<void> _toggle(bool hasPlace) async {
    setState(() => _busy = true);
    final repository = ref.read(classesRepositoryProvider);

    try {
      if (hasPlace) {
        await repository.cancelBooking(widget.session);
        _say('Your place has been given up.');
      } else {
        final outcome = await repository.book(widget.session);
        _say(
          outcome.isBooked
              ? 'Booked. See you there.'
              : 'Class is full — you are number ${outcome.position} on the '
                    'waitlist.',
        );
      }
      ref.invalidate(upcomingSessionsProvider);
    } catch (error) {
      _say(friendlyErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PlacesBadge extends StatelessWidget {
  const _PlacesBadge({required this.session});

  final ClassSession session;

  @override
  Widget build(BuildContext context) {
    final full = session.isFull;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (full ? AppColors.gold : AppColors.success).withValues(
          alpha: .14,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        full ? 'Full' : '${session.placesLeft} left',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: full ? AppColors.gold : AppColors.success,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ClassVideoCard extends StatelessWidget {
  const _ClassVideoCard({required this.groupClass, required this.onTap});

  final GroupClass groupClass;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 88,
                    height: 56,
                    child: groupClass.thumbnailUrl == null
                        ? Container(
                            color: AppColors.subtle(context),
                            child: Icon(
                              Icons.play_circle_outline_rounded,
                              color: AppColors.secondaryText(context),
                            ),
                          )
                        : Image.network(
                            groupClass.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, _, _) => Container(
                              color: AppColors.subtle(context),
                              child: Icon(
                                Icons.play_circle_outline_rounded,
                                color: AppColors.secondaryText(context),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupClass.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${groupClass.durationMins} min',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(
                              color: AppColors.secondaryText(context),
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------- events

class _EventsTab extends ConsumerWidget {
  const _EventsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(upcomingEventsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(upcomingEventsProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        children: [
          AsyncStateView(
            value: events,
            onRetry: () => ref.invalidate(upcomingEventsProvider),
            data: (items) => items.isEmpty
                ? const AppEmptyState(
                    icon: Icons.celebration_outlined,
                    title: 'Nothing coming up',
                    message: 'Gym events will show up here.',
                  )
                : Column(
                    children: [
                      for (final event in items) _EventCard(event: event),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends ConsumerStatefulWidget {
  const _EventCard({required this.event});

  final GymEvent event;

  @override
  ConsumerState<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends ConsumerState<_EventCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: PremiumCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  event.imageUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, _) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 14),
            ],
            Text(
              event.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              '${_formatWhen(event.startsAt)}  •  ${event.venue}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.secondaryText(context),
              ),
            ),
            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                event.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 14),
            PrimaryButton(
              label: _busy
                  ? 'Working...'
                  : (event.hasRsvped ? 'Cancel my RSVP' : "I'll be there"),
              icon: event.hasRsvped
                  ? Icons.close_rounded
                  : Icons.how_to_reg_rounded,
              outline: event.hasRsvped,
              onPressed: _busy ? null : _toggle,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggle() async {
    setState(() => _busy = true);
    final repository = ref.read(eventsRepositoryProvider);

    try {
      if (widget.event.hasRsvped) {
        await repository.cancelRsvp(widget.event);
      } else {
        await repository.rsvp(widget.event);
      }
      ref.invalidate(upcomingEventsProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

String _formatWhen(DateTime when) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final hour = when.hour % 12 == 0 ? 12 : when.hour % 12;
  final minute = when.minute.toString().padLeft(2, '0');
  final suffix = when.hour >= 12 ? 'pm' : 'am';
  return '${days[when.weekday - 1]} ${when.day} ${months[when.month - 1]}, '
      '$hour:$minute$suffix';
}
