import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/models/assigned_plan.dart';
import 'package:deepfitness/core/widgets/primary_button.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:deepfitness/features/workout_plan/application/assigned_plan_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The member's home: who they are, and what is next in their plan.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(authControllerProvider).value?.member;
    final plan = ref.watch(currentPlanProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas(context),
      appBar: AppBar(
        title: const Text('Deep Fitness'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Hello, ${member?.name ?? 'there'}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              plan.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, _) => const _PlanCard.message(
                  'Could not load your plan right now.',
                ),
                data: (data) => data == null || data.isEmpty
                    ? const _PlanCard.message(
                        'Your trainer has not assigned a plan yet.',
                      )
                    : _PlanCard(plan: data),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan}) : text = null;

  const _PlanCard.message(this.text) : plan = null;

  final AssignedPlan? plan;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final current = plan;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: current == null
          ? Text(
              text!,
              style: TextStyle(color: AppColors.secondaryText(context)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  current.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  current.isComplete
                      ? 'Every exercise is done. Well done.'
                      : 'Next up: ${current.currentExercise?.name ?? ''}',
                  style: TextStyle(color: AppColors.secondaryText(context)),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: current.progress,
                    minHeight: 8,
                    backgroundColor: AppColors.canvas(context),
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: current.isComplete ? 'Review plan' : 'Start training',
                  onPressed: () => context.push('/plan'),
                ),
              ],
            ),
    );
  }
}
