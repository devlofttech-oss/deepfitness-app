import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:deepfitness/services/app_data_repository.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:deepfitness/shared/widgets/async_state.dart';
import 'package:deepfitness/shared/widgets/brand_mark.dart';
import 'package:deepfitness/shared/widgets/icon_tile.dart';
import 'package:deepfitness/shared/widgets/metric_cell.dart';
import 'package:deepfitness/shared/widgets/premium_card.dart';
import 'package:deepfitness/shared/widgets/premium_scaffold.dart';
import 'package:deepfitness/shared/widgets/progress_ring.dart';
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
    final nutrition = ref.watch(nutritionProvider);

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
          data: (workoutData) => AsyncStateView(
            value: nutrition,
            errorTitle: 'Could not load your nutrition',
            onRetry: () => ref.invalidate(nutritionProvider),
            data: (nutritionData) => _TodayContent(
              user: userData,
              workout: workoutData,
              nutrition: nutritionData,
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayContent extends StatelessWidget {
  const _TodayContent({
    required this.user,
    required this.workout,
    required this.nutrition,
  });

  final AppUser user;
  final WorkoutPlan workout;
  final NutritionPlan nutrition;

  @override
  Widget build(BuildContext context) {
    final nutritionPercent = nutrition.goalCalories == 0
        ? 0.0
        : (nutrition.calories / nutrition.goalCalories).clamp(0.0, 1.0);

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
                    'Good Morning,',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.muted,
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
                  onPressed: () => _showNotifications(context),
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    size: 26,
                    color: AppColors.muted,
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
          color: AppColors.black,
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
                '0% Completed',
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
                      child: const LinearProgressIndicator(
                        value: .02,
                        minHeight: 10,
                        color: AppColors.goldBright,
                        backgroundColor: Color(0xFF3A3A3A),
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
        const SizedBox(height: 26),
        const SectionTitle(title: "Today's Nutrition"),
        const SizedBox(height: 18),
        PremiumCard(
          child: Column(
            children: [
              Row(
                children: [
                  const IconTile(icon: Icons.restaurant_rounded, size: 58),
                  const SizedBox(width: 22),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${nutrition.calories} kcal',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${nutrition.meals.length} Meals Planned',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  ProgressRing(value: nutritionPercent, size: 82),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  MetricCell(
                    icon: Icons.fitness_center_rounded,
                    value: '${nutrition.protein} g',
                    label: 'Protein',
                  ),
                  const _Divider(),
                  MetricCell(
                    icon: Icons.grass_rounded,
                    value: '${nutrition.carbs} g',
                    label: 'Carbs',
                  ),
                  const _Divider(),
                  MetricCell(
                    icon: Icons.water_drop_outlined,
                    value: '${nutrition.fats} g',
                    label: 'Fats',
                  ),
                  const _Divider(),
                  MetricCell(
                    icon: Icons.local_fire_department_outlined,
                    value: '${nutrition.caloriesLeft}',
                    label: 'Calories Left',
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

void _showNotifications(BuildContext context) {
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
          const ListTile(
            leading: Icon(Icons.fitness_center_rounded, color: AppColors.gold),
            title: Text('Workout ready'),
            subtitle: Text('Your plan is available for today.'),
          ),
          const ListTile(
            leading: Icon(Icons.restaurant_rounded, color: AppColors.gold),
            title: Text('Nutrition reminder'),
            subtitle: Text('Log water and complete your meals.'),
          ),
        ],
      ),
    ),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 58, color: AppColors.divider(context));
  }
}
