import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/models/event.dart';
import 'package:deepfitness/features/events/presentation/events_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Upcoming gym events, with an RSVP on each.
class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Asks for the next page a little before the end, so the list does not
  /// visibly stall at the bottom.
  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      ref.read(upcomingEventsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(upcomingEventsProvider);
    final rsvps = ref.watch(myRsvpsProvider).value ?? const <String>{};

    return Scaffold(
      backgroundColor: AppColors.canvas(context),
      appBar: AppBar(title: const Text('Events')),
      body: SafeArea(
        child: events.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const _EventsMessage(
            'Could not load events. Check your connection.',
          ),
          data: (list) => list.isEmpty
              ? const _EventsMessage('No events coming up just now.')
              : RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(upcomingEventsProvider),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) => _EventCard(
                      event: list[index],
                      going: rsvps.contains(list[index].id),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _EventCard extends ConsumerWidget {
  const _EventCard({required this.event, required this.going});

  final Event event;
  final bool going;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final starts = event.startsAt;

    return Material(
      color: AppColors.surface(context),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/events/${event.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (event.imageUrl != null)
              Image.network(
                event.imageUrl!,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    [
                      if (starts != null)
                        '${starts.day}/${starts.month} at '
                            '${starts.hour.toString().padLeft(2, '0')}:'
                            '${starts.minute.toString().padLeft(2, '0')}',
                      if (event.venue.isNotEmpty) event.venue,
                    ].join(' · '),
                    style: TextStyle(color: AppColors.secondaryText(context)),
                  ),
                  if (event.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      event.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonalIcon(
                      onPressed: () => ref
                          .read(rsvpControllerProvider.notifier)
                          .toggle(eventId: event.id, going: going),
                      icon: Icon(
                        going ? Icons.check_circle : Icons.add_circle_outline,
                      ),
                      label: Text(going ? "You're going" : 'Count me in'),
                      style: FilledButton.styleFrom(
                        backgroundColor: going
                            ? AppColors.success.withValues(alpha: 0.18)
                            : AppColors.chipBackground(context),
                        foregroundColor: going
                            ? AppColors.success
                            : AppColors.gold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventsMessage extends StatelessWidget {
  const _EventsMessage(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.secondaryText(context)),
        ),
      ),
    );
  }
}
