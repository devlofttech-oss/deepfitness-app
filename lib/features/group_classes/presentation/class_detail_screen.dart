import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/models/booking.dart';
import 'package:deepfitness/core/models/class_session.dart';
import 'package:deepfitness/core/repositories/repository_failure.dart';
import 'package:deepfitness/features/group_classes/presentation/classes_controller.dart';
import 'package:deepfitness/features/group_classes/presentation/video_player_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One class: the video, and the sessions a member can book a place in.
class ClassDetailScreen extends ConsumerWidget {
  const ClassDetailScreen({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupClass = ref.watch(groupClassProvider(classId));
    final sessions = ref.watch(classSessionsProvider(classId));
    final bookings = ref.watch(myBookingsProvider).value ?? const {};

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(groupClass.value?.title ?? 'Class')),
      body: SafeArea(
        child: groupClass.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('Could not load this class.')),
          data: (data) => data == null
              ? const Center(child: Text('That class is no longer listed.'))
              : ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if (data.hasVideo) VideoPlayerView(groupClass: data),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data.description.isNotEmpty) ...[
                            Text(data.description),
                            const SizedBox(height: 24),
                          ],
                          Text(
                            'LIVE SESSIONS',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          sessions.when(
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (_, _) => Text(
                              'Could not load the timetable.',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            data: (list) => list.isEmpty
                                ? Text(
                                    'Nothing scheduled right now.',
                                    style: TextStyle(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  )
                                : Column(
                                    children: [
                                      for (final session in list)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: _SessionTile(
                                            session: session,
                                            booking: bookings[session.id],
                                          ),
                                        ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SessionTile extends ConsumerWidget {
  const _SessionTile({required this.session, this.booking});

  final ClassSession session;
  final Booking? booking;

  Future<void> _book(BuildContext context, WidgetRef ref) async {
    final decision = await ref
        .read(bookingControllerProvider.notifier)
        .book(session.id);

    if (!context.mounted) return;

    final error = ref.read(bookingControllerProvider).error;
    final message = decision == null
        ? (error is RepositoryFailure
              ? error.message
              : 'Could not book that. Try again.')
        : decision.isWaitlisted
        ? "The class is full. You're number ${decision.position} on the waitlist."
        : "You're booked in.";

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(bookingControllerProvider.notifier)
        .cancel(session.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Your place has been given up.' : 'Could not cancel. Try again.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(bookingControllerProvider).isLoading;
    final starts = session.startsAt;
    final current = booking;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  starts == null
                      ? 'Time to be confirmed'
                      : '${starts.day}/${starts.month} at '
                            '${starts.hour.toString().padLeft(2, '0')}:'
                            '${starts.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitle(current),
                  style: TextStyle(
                    color: current?.status == BookingStatus.waitlisted
                        ? AppColors.primaryContainer
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (busy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (current != null)
            TextButton(
              onPressed: () => _cancel(context, ref),
              child: const Text('Cancel'),
            )
          else
            FilledButton(
              onPressed: () => _book(context, ref),
              // A full session still books: it joins the waitlist, which
              // the label says plainly rather than leaving a dead button.
              child: Text(session.isFull ? 'Join waitlist' : 'Book'),
            ),
        ],
      ),
    );
  }

  String _subtitle(Booking? current) {
    if (current?.status == BookingStatus.waitlisted) {
      return 'Waitlisted, number ${current!.position}';
    }
    if (current?.status == BookingStatus.booked) {
      return "You're booked in";
    }
    if (session.instructor.isNotEmpty && !session.isFull) {
      return '${session.instructor} · ${session.placesLeft} places left';
    }
    if (session.isFull) {
      return 'Full · ${session.waitlistCount} waiting';
    }
    return '${session.placesLeft} places left';
  }
}
