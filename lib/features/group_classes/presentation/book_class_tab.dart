import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/models/booking.dart';
import 'package:deepfitness/core/models/class_session.dart';
import 'package:deepfitness/core/models/group_class.dart';
import 'package:deepfitness/core/repositories/repository_failure.dart';
import 'package:deepfitness/core/widgets/df_button.dart';
import 'package:deepfitness/core/widgets/df_card.dart';
import 'package:deepfitness/features/group_classes/presentation/classes_controller.dart';
import 'package:deepfitness/features/workout_report/domain/report_range.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The live timetable: pick a day, then book a place or join the queue.
class BookClassTab extends ConsumerWidget {
  const BookClassTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(upcomingSessionsProvider);
    final selectedDay = ref.watch(selectedSessionDayProvider);
    final bookings = ref.watch(myBookingsProvider).value ?? const {};
    final classes = ref.watch(classesProvider).value ?? const <GroupClass>[];
    final byClassId = {for (final item in classes) item.id: item};

    return sessions.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const DfMessage(
        icon: Icons.wifi_off,
        title: 'Could not load the timetable',
        body: 'Check your connection and try again.',
      ),
      data: (all) {
        if (all.isEmpty) {
          return const DfMessage(
            icon: Icons.event_busy,
            title: 'Nothing scheduled',
            body: 'New sessions will appear here as the gym adds them.',
          );
        }

        // The day strip is built from the sessions that exist, so it
        // never offers a day with nothing on it.
        final days = <DateTime>{
          for (final session in all)
            if (session.startsAt != null) startOfDay(session.startsAt!),
        }.toList()..sort();

        final showing = selectedDay == null
            ? all
            : all
                  .where(
                    (session) =>
                        session.startsAt != null &&
                        startOfDay(session.startsAt!) == selectedDay,
                  )
                  .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            Insets.margin,
            Insets.md,
            Insets.margin,
            Insets.xl,
          ),
          children: [
            _DayStrip(
              days: days,
              selected: selectedDay,
              onSelect: (day) =>
                  ref.read(selectedSessionDayProvider.notifier).select(day),
            ),
            const SizedBox(height: Insets.lg),
            Row(
              children: [
                const Expanded(child: DfLabel('Available sessions')),
                DfLabel('${showing.length} scheduled'),
              ],
            ),
            const SizedBox(height: Insets.sm),
            for (final session in showing)
              Padding(
                padding: const EdgeInsets.only(bottom: Insets.sm),
                child: _SessionCard(
                  session: session,
                  groupClass: byClassId[session.classId],
                  booking: bookings[session.id],
                ),
              ),
            const SizedBox(height: Insets.md),
            const _PolicyCard(),
          ],
        );
      },
    );
  }
}

/// The horizontal date picker along the top.
class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.days,
    required this.selected,
    required this.onSelect,
  });

  final List<DateTime> days;
  final DateTime? selected;
  final ValueChanged<DateTime?> onSelect;

  static const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  static const _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  @override
  Widget build(BuildContext context) {
    final today = startOfDay(DateTime.now());

    return SizedBox(
      height: 76,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: Insets.sm),
            child: _DayTile(
              top: 'ALL',
              middle: '•',
              bottom: 'DAYS',
              selected: selected == null,
              onTap: () => onSelect(null),
            ),
          ),
          for (final day in days)
            Padding(
              padding: const EdgeInsets.only(right: Insets.sm),
              child: _DayTile(
                top: day == today
                    ? 'TODAY'
                    : _weekdays[day.weekday - 1],
                middle: '${day.day}',
                bottom: _months[day.month - 1],
                selected: selected == day,
                onTap: () => onSelect(day),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.top,
    required this.middle,
    required this.bottom,
    required this.selected,
    required this.onTap,
  });

  final String top;
  final String middle;
  final String bottom;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // The selected day is the one place on this screen that takes a
    // solid fill, so it reads at a glance.
    final foreground = selected
        ? AppColors.onPrimaryContainer
        : AppColors.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: Insets.sm),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryContainer
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(Radii.base),
          border: Border.all(
            color: selected
                ? AppColors.primaryContainer
                : AppColors.surfaceContainerHigh,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DfLabel(top, colour: foreground),
            Text(
              middle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: selected
                    ? AppColors.onPrimaryContainer
                    : AppColors.onSurface,
              ),
            ),
            DfLabel(bottom, colour: foreground),
          ],
        ),
      ),
    );
  }
}

/// One session: when, who, how full, and the action it affords.
class _SessionCard extends ConsumerWidget {
  const _SessionCard({
    required this.session,
    this.groupClass,
    this.booking,
  });

  final ClassSession session;
  final GroupClass? groupClass;
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
        ? 'The class is full. You are number ${decision.position} '
              'on the waitlist.'
        : 'Booked in.';

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
    final theme = Theme.of(context).textTheme;
    final busy = ref.watch(bookingControllerProvider).isLoading;
    final starts = session.startsAt;
    final current = booking;
    final isBooked = current?.status == BookingStatus.booked;
    final isWaitlisted = current?.status == BookingStatus.waitlisted;

    return DfCard(
      // A session the member holds a place on is outlined in the accent,
      // so their own bookings stand out of a long timetable.
      borderColour: isBooked
          ? AppColors.primaryContainer
          : AppColors.surfaceContainerHigh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isBooked) ...[
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 14,
                  color: AppColors.primaryContainer,
                ),
                const SizedBox(width: Insets.xs),
                const DfLabel(
                  'Booked',
                  colour: AppColors.primaryContainer,
                ),
                const Spacer(),
                const DfLabel('Confirmed'),
              ],
            ),
            const SizedBox(height: Insets.sm),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (groupClass != null &&
                        groupClass!.durationMins > 0) ...[
                      const Icon(
                        Icons.schedule,
                        size: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: Insets.xs),
                      DfLabel('${groupClass!.durationMins} min'),
                    ],
                  ],
                ),
              ),
              if (starts != null)
                Text(
                  _time(starts),
                  style: theme.headlineSmall,
                ),
            ],
          ),
          const SizedBox(height: Insets.xs),
          Text(
            (groupClass?.title ?? 'Class').toUpperCase(),
            style: theme.headlineMedium,
          ),
          if (session.instructor.isNotEmpty) ...[
            const SizedBox(height: Insets.sm),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: Insets.xs),
                Text(
                  session.instructor,
                  style: theme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: Insets.md),
          _CapacityBar(session: session),
          const SizedBox(height: Insets.md),
          if (isBooked || isWaitlisted)
            DfSecondaryButton(
              label: isWaitlisted
                  ? 'Leave waitlist (number ${current!.position})'
                  : 'Cancel spot',
              icon: Icons.cancel_outlined,
              onPressed: busy ? null : () => _cancel(context, ref),
            )
          else if (session.isFull)
            DfSecondaryButton(
              label: 'Join waitlist (position '
                  '${session.waitlistCount + 1})',
              icon: Icons.hourglass_empty,
              onPressed: busy ? null : () => _book(context, ref),
            )
          else
            DfPrimaryButton(
              label: 'Book class',
              busy: busy,
              onPressed: () => _book(context, ref),
            ),
        ],
      ),
    );
  }

  static String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

/// How full the session is, as a bar and a count.
class _CapacityBar extends StatelessWidget {
  const _CapacityBar({required this.session});

  final ClassSession session;

  @override
  Widget build(BuildContext context) {
    final fraction = session.capacity == 0
        ? 1.0
        : (session.bookedCount / session.capacity).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: DfLabel(
                'Capacity: ${session.bookedCount} of ${session.capacity}',
              ),
            ),
            DfLabel(
              session.isFull
                  ? '${session.waitlistCount} on waitlist'
                  : '${session.placesLeft} left',
              // The last few places are called out, because that is the
              // moment the member needs to decide.
              colour: session.isFull
                  ? AppColors.outline
                  : session.placesLeft <= 3
                  ? AppColors.primaryContainer
                  : AppColors.onSurfaceVariant,
            ),
          ],
        ),
        const SizedBox(height: Insets.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.sm),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: AppColors.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation(
              session.isFull
                  ? AppColors.outline
                  : AppColors.primaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard();

  @override
  Widget build(BuildContext context) {
    return DfCard(
      colour: AppColors.surfaceContainerLowest,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 18,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DfLabel('Studio booking policy'),
                const SizedBox(height: Insets.xs),
                Text(
                  'Cancel free up to two hours before the session starts. '
                  'Cancelling frees your place for the first person on '
                  'the waitlist.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
