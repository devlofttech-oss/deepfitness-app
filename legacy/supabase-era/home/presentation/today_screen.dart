import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:deepfitness/services/app_data_repository.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:deepfitness/shared/widgets/async_state.dart';
import 'package:deepfitness/shared/widgets/brand_mark.dart';
import 'package:deepfitness/shared/widgets/icon_tile.dart';
import 'package:deepfitness/shared/widgets/premium_card.dart';
import 'package:deepfitness/shared/widgets/premium_scaffold.dart';
import 'package:deepfitness/shared/widgets/section_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final workout = ref.watch(workoutProvider);

    return PremiumScaffold(
      bottomPadding: 132,
      child: AsyncStateView(
        value: user,
        errorTitle: 'Could not load your profile',
        onRetry: () => ref.invalidate(currentUserProvider),
        data: (userData) => AsyncStateView(
          value: workout,
          errorTitle: 'Could not load your workout',
          onRetry: () => ref.invalidate(workoutProvider),
          data: (workoutData) =>
              _TodayContent(user: userData, workout: workoutData),
        ),
      ),
    );
  }
}

class _TodayContent extends StatelessWidget {
  const _TodayContent({required this.user, required this.workout});

  final AppUser user;
  final WorkoutPlan workout;

  @override
  Widget build(BuildContext context) {
    final greeting = _greetingFor(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const BrandMark(size: 58),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting,',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.secondaryText(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () => _showNotifications(context, workout),
                  icon: Icon(
                    Icons.notifications_none_rounded,
                    size: 26,
                    color: AppColors.secondaryText(context),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.goldBright,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 34),
        const SectionTitle(title: "Today's Workout"),
        const SizedBox(height: 18),
        PremiumCard(
          color: AppColors.charcoal,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const IconTile(
                    icon: Icons.fitness_center_rounded,
                    background: Color(0xFF2F2F2F),
                    size: 58,
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.name,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Text(
                          '${workout.exercises.length} Exercises  •  ${workout.durationMinutes} min',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                '${(workout.completionPercent * 100).round()}% Completed',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: workout.completionPercent,
                        minHeight: 10,
                        color: AppColors.goldBright,
                        backgroundColor: const Color(0xFF3A3A3A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  FilledButton(
                    onPressed: workout.exercises.isEmpty
                        ? null
                        : () => context.push('/workout'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.goldBright,
                      foregroundColor: AppColors.black,
                      minimumSize: const Size(144, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          workout.exercises.isEmpty
                              ? 'Not Assigned'
                              : workout.completionPercent >= 1
                              ? 'Completed'
                              : workout.completionPercent > 0
                              ? 'Continue'
                              : 'Start Workout',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void _showNotifications(BuildContext context, WorkoutPlan workout) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(
              Icons.fitness_center_rounded,
              color: AppColors.gold,
            ),
            title: Text(
              workout.exercises.isEmpty ? 'No workout assigned' : workout.name,
            ),
            subtitle: Text(
              workout.exercises.isEmpty
                  ? 'Ask your trainer to assign a workout.'
                  : '${workout.exercises.length} exercises available.',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.pop(context);
              context.go('/workout');
            },
          ),
        ],
      ),
    ),
  );
}

String _greetingFor(DateTime now) {
  if (now.hour < 12) return 'Good Morning';
  if (now.hour < 17) return 'Good Afternoon';
  return 'Good Evening';
}
