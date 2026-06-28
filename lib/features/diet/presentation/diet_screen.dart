import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:deepfitness/services/app_data_repository.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:deepfitness/shared/widgets/async_state.dart';
import 'package:deepfitness/shared/widgets/icon_tile.dart';
import 'package:deepfitness/shared/widgets/metric_cell.dart';
import 'package:deepfitness/shared/widgets/page_header.dart';
import 'package:deepfitness/shared/widgets/premium_card.dart';
import 'package:deepfitness/shared/widgets/premium_scaffold.dart';
import 'package:deepfitness/shared/widgets/progress_ring.dart';
import 'package:deepfitness/shared/widgets/section_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DietScreen extends ConsumerWidget {
  const DietScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutrition = ref.watch(nutritionProvider);

    return PremiumScaffold(
      bottomPadding: 132,
      child: AsyncStateView(
        value: nutrition,
        errorTitle: 'Could not load your diet',
        onRetry: () => ref.invalidate(nutritionProvider),
        data: (nutrition) => _DietContent(nutrition: nutrition),
      ),
    );
  }
}

class _DietContent extends ConsumerStatefulWidget {
  const _DietContent({required this.nutrition});

  final NutritionPlan nutrition;

  @override
  ConsumerState<_DietContent> createState() => _DietContentState();
}

class _DietContentState extends ConsumerState<_DietContent> {
  @override
  Widget build(BuildContext context) {
    final nutrition = widget.nutrition;
    final percent = nutrition.goalCalories == 0
        ? 0.0
        : (nutrition.calories / nutrition.goalCalories).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Diet',
          subtitle: 'Fuel your body. Reach your goals.',
          action: IconButton(
            onPressed: () => showDatePicker(
              context: context,
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now().add(const Duration(days: 30)),
              initialDate: DateTime.now(),
            ),
            icon: const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.gold,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 26),
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
                          "Today's Nutrition",
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${nutrition.calories} kcal',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'of '),
                              TextSpan(
                                text: '${nutrition.goalCalories}',
                                style: const TextStyle(color: AppColors.gold),
                              ),
                              const TextSpan(text: ' kcal goal'),
                            ],
                          ),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  ProgressRing(value: percent, size: 82),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  MetricCell(
                    icon: Icons.inventory_2_outlined,
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
        const SizedBox(height: 24),
        const SectionTitle(title: "Today's Meals"),
        const SizedBox(height: 16),
        if (nutrition.meals.isEmpty)
          const AppEmptyState(
            title: 'No meals assigned',
            message: 'Your trainer has not assigned a diet plan for today yet.',
            icon: Icons.restaurant_menu_rounded,
          )
        else
          ...nutrition.meals.map(
            (meal) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MealCard(meal: meal),
            ),
          ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => _addWater(nutrition),
          child: PremiumCard(
            color: AppColors.goldSoft,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.goldBright,
                  child: Icon(
                    Icons.water_drop_outlined,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Tap to add water',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  nutrition.waterGoalLiters <= 0
                      ? '${nutrition.waterLiters.toStringAsFixed(2)}L'
                      : '${nutrition.waterLiters.toStringAsFixed(2)}L / ${nutrition.waterGoalLiters.toStringAsFixed(2)}L',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Icon(Icons.add_rounded),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addWater(NutritionPlan nutrition) async {
    final next = nutrition.waterGoalLiters <= 0
        ? nutrition.waterLiters + .25
        : (nutrition.waterLiters + .25)
              .clamp(0, nutrition.waterGoalLiters)
              .toDouble();
    await ref.read(appDataRepositoryProvider).addWater(next);
    ref.invalidate(nutritionProvider);
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal});

  final DietMeal meal;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showMealDetails(context, meal),
      child: PremiumCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            IconTile(icon: _mealIcon(meal.icon), size: 48),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meal.time,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    meal.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.charcoal,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${meal.calories} kcal',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  IconData _mealIcon(String icon) {
    return switch (icon) {
      'breakfast' => Icons.wb_twilight_rounded,
      'lunch' => Icons.wb_sunny_outlined,
      'snack' => Icons.apple_rounded,
      'dinner' => Icons.nightlight_round,
      _ => Icons.local_drink_outlined,
    };
  }
}

void _showMealDetails(BuildContext context, DietMeal meal) {
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
            meal.name,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(meal.time, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 12),
          Text(meal.description),
          const SizedBox(height: 12),
          Text(
            '${meal.calories} kcal',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 58, color: AppColors.divider(context));
}
