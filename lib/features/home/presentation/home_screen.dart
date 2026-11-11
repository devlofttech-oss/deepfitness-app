import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/models/assigned_plan.dart';
import 'package:deepfitness/core/widgets/df_button.dart';
import 'package:deepfitness/core/widgets/df_card.dart';
import 'package:deepfitness/core/widgets/df_chrome.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:deepfitness/features/events/presentation/events_controller.dart';
import 'package:deepfitness/features/workout_plan/application/assigned_plan_controller.dart';
import 'package:deepfitness/features/workout_report/domain/report_range.dart';
import 'package:deepfitness/features/workout_report/presentation/report_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The member's home: the greeting, today's assigned workout, the week's
/// consistency, and what is coming up at the gym.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(authControllerProvider).value?.member;
    final plan = ref.watch(currentPlanProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: DfBrandBar(
        photoUrl: member?.photoUrl,
        onNotices: () => context.push('/notices'),
        onProfile: () => context.go('/profile'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Insets.margin,
            Insets.md,
            Insets.margin,
            Insets.xl,
          ),
          children: [
            _Greeting(name: member?.name),
            const SizedBox(height: Insets.lg),
            plan.when(
              loading: () => const _LoadingCard(),
              error: (_, _) => const DfCard(
                child: Text('Could not load your plan right now.'),
              ),
              data: (data) => data == null || data.isEmpty
                  ? const _NoPlanCard()
                  : _WorkoutCard(plan: data),
            ),
            const SizedBox(height: Insets.xl),
            const _ConsistencySection(),
            const SizedBox(height: Insets.xl),
            const _EventsSection(),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final first = (name ?? '').trim().split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          first.isEmpty ? 'NAMASKARA' : 'NAMASKARA, $first'.toUpperCase(),
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: Insets.xs),
        Row(
          children: [
            const Icon(
              Icons.pin_drop_outlined,
              size: 14,
              color: AppColors.outline,
            ),
            const SizedBox(width: Insets.xs),
            Text(
              'Deep Fitness • Gokulam 3rd Stage',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.outline),
            ),
          ],
        ),
      ],
    );
  }
}

/// Today's assigned workout: the progress ring, what is next, and the
/// single primary action on the screen.
class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.plan});

  final AssignedPlan plan;

  @override
  Widget build(BuildContext context) {
    final next = plan.currentExercise;
    final theme = Theme.of(context).textTheme;

    return DfCard(
      padding: const EdgeInsets.all(Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Insets.sm,
                  vertical: Insets.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.fitness_center,
                      size: 14,
                      color: AppColors.primaryContainer,
                    ),
                    const SizedBox(width: Insets.xs),
                    DfLabel(plan.title, colour: AppColors.onSurface),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          Container(
            padding: const EdgeInsets.all(Insets.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(Radii.base),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const DfLabel('Progress'),
                      const SizedBox(height: Insets.xs),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${plan.currentIndex}',
                            style: theme.displayMedium,
                          ),
                          Text(
                            ' / ${plan.exercises.length}',
                            style: theme.headlineMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: Insets.xs),
                          const DfLabel('Done'),
                        ],
                      ),
                    ],
                  ),
                ),
                DfProgressRing(value: plan.progress),
              ],
            ),
          ),
          if (next != null) ...[
            const SizedBox(height: Insets.md),
            Container(
              padding: const EdgeInsets.all(Insets.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(Radii.base),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.play_circle_outline,
                    color: AppColors.onSurface,
                  ),
                  const SizedBox(width: Insets.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const DfLabel('Next movement'),
                        const SizedBox(height: 2),
                        Text(next.name, style: theme.bodyLarge),
                        Text(
                          '${next.sets} sets × ${next.reps} reps',
                          style: theme.bodySmall?.copyWith(
                            color: AppColors.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: Insets.md),
          DfPrimaryButton(
            label: plan.isComplete ? 'Review plan' : 'Continue workout',
            onPressed: () => context.go('/plan'),
          ),
        ],
      ),
    );
  }
}

class _NoPlanCard extends StatelessWidget {
  const _NoPlanCard();

  @override
  Widget build(BuildContext context) {
    return const DfCard(
      padding: EdgeInsets.all(Insets.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DfLabel('No plan assigned'),
          SizedBox(height: Insets.sm),
          Text('Your trainer will assign one soon.'),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const DfCard(
      padding: EdgeInsets.symmetric(vertical: Insets.xl),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

/// The week in three numbers, all derived from the completion log.
class _ConsistencySection extends ConsumerWidget {
  const _ConsistencySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(workoutReportProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DfSectionHeader(title: 'Weekly consistency'),
        report.when(
          loading: () => const _LoadingCard(),
          error: (_, _) => const SizedBox.shrink(),
          data: (data) => Row(
            children: [
              Expanded(
                child: DfCard(
                  child: DfStat(
                    value: '${data.currentStreak}',
                    caption: 'Day streak',
                    icon: Icons.local_fire_department_outlined,
                  ),
                ),
              ),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: DfCard(
                  child: DfStat(
                    value: '${data.activeDays}',
                    suffix: '/7',
                    caption: 'This week',
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
              ),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: DfCard(
                  child: DfStat(
                    value: '${data.totalLogged}',
                    caption: 'Total logs',
                    icon: Icons.task_alt,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// What is on at the gym, newest first, with a link to the full list.
class _EventsSection extends ConsumerWidget {
  const _EventsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(upcomingEventsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DfSectionHeader(
          title: 'Mysore club events',
          trailing: 'View all',
          onTrailingTap: () => context.go('/events'),
        ),
        events.when(
          loading: () => const _LoadingCard(),
          error: (_, _) => const SizedBox.shrink(),
          data: (list) => list.isEmpty
              ? const DfCard(child: Text('Nothing coming up just now.'))
              : Column(
                  children: [
                    for (final event in list.take(2))
                      Padding(
                        padding: const EdgeInsets.only(bottom: Insets.sm),
                        child: DfCard(
                          onTap: () => context.push('/events/${event.id}'),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.title,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge,
                                    ),
                                    if (event.venue.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        event.venue,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.outline,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (event.startsAt != null)
                                _DateBlock(date: event.startsAt!),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// The day-and-month block on an event row.
class _DateBlock extends StatelessWidget {
  const _DateBlock({required this.date});

  final DateTime date;

  static const _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: Insets.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Column(
        children: [
          Text(
            '${date.day}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          DfLabel(_months[date.month - 1]),
        ],
      ),
    );
  }
}
