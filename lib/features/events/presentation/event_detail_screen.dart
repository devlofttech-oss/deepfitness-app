import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/models/event.dart';
import 'package:deepfitness/core/widgets/primary_button.dart';
import 'package:deepfitness/features/events/presentation/events_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One event in full, with the RSVP.
class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(eventProvider(eventId));
    final going = (ref.watch(myRsvpsProvider).value ?? const <String>{})
        .contains(eventId);
    final busy = ref.watch(rsvpControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.canvas(context),
      appBar: AppBar(title: Text(event.value?.title ?? 'Event')),
      body: SafeArea(
        child: event.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('Could not load it.')),
          data: (data) => data == null
              ? const Center(child: Text('That event is no longer listed.'))
              : _EventBody(event: data, going: going, busy: busy),
        ),
      ),
    );
  }
}

class _EventBody extends ConsumerWidget {
  const _EventBody({
    required this.event,
    required this.going,
    required this.busy,
  });

  final Event event;
  final bool going;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final starts = event.startsAt;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (event.imageUrl != null)
          Image.network(
            event.imageUrl!,
            height: 220,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(event.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              if (starts != null)
                _DetailRow(
                  icon: Icons.schedule,
                  text:
                      '${starts.day}/${starts.month}/${starts.year} at '
                      '${starts.hour.toString().padLeft(2, '0')}:'
                      '${starts.minute.toString().padLeft(2, '0')}',
                ),
              if (event.venue.isNotEmpty)
                _DetailRow(icon: Icons.place_outlined, text: event.venue),
              if (event.description.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(event.description),
              ],
              const SizedBox(height: 32),
              if (busy)
                const Center(child: CircularProgressIndicator())
              else
                PrimaryButton(
                  label: going ? "You're going · tap to withdraw" : 'Count me in',
                  outline: going,
                  onPressed: () => ref
                      .read(rsvpControllerProvider.notifier)
                      .toggle(eventId: event.id, going: going),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AppColors.secondaryText(context)),
            ),
          ),
        ],
      ),
    );
  }
}
