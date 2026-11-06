import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:deepfitness/shared/widgets/async_state.dart';
import 'package:deepfitness/shared/widgets/page_header.dart';
import 'package:deepfitness/shared/widgets/premium_card.dart';
import 'package:deepfitness/shared/widgets/premium_scaffold.dart';
import 'package:deepfitness/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Shown when an account exists in Auth but has no member document.
///
/// That happens after a phone sign-up, where the only thing Firebase knows is
/// the number. The router sends these accounts here rather than into an app
/// whose every screen would read an empty profile.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _goals = <String>[
    'Build muscle',
    'Lose weight',
    'Get stronger',
    'Stay fit',
  ];
  static const _genders = <String>['Male', 'Female', 'Other'];

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  String _goal = _goals.first;
  String? _gender;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return PremiumScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Tell us about you',
            subtitle: 'Your trainer uses this to build your first plan',
          ),
          const SizedBox(height: 20),
          PremiumCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Label('Full name'),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Your name',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                const _Label('Your goal'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final goal in _goals)
                      ChoiceChip(
                        label: Text(goal),
                        selected: _goal == goal,
                        onSelected: (_) => setState(() => _goal = goal),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const _Label('Gender'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final gender in _genders)
                      ChoiceChip(
                        label: Text(gender),
                        selected: _gender == gender,
                        onSelected: (selected) => setState(
                          () => _gender = selected ? gender : null,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Label('Age'),
                          TextField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Years',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Label('Height'),
                          TextField(
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'cm',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (authState.hasError) ...[
            const SizedBox(height: 16),
            Text(
              friendlyErrorMessage(authState.error!),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            label: isLoading ? 'Saving...' : 'Finish Setup',
            icon: Icons.arrow_forward_rounded,
            onPressed: isLoading ? null : () => _submit(context),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: isLoading
                  ? null
                  : () => ref.read(authControllerProvider.notifier).signOut(),
              child: const Text('Sign out'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter your name.')));
      return;
    }

    final saved = await ref
        .read(authControllerProvider.notifier)
        .completeOnboarding(
          name: name,
          goal: _goal,
          gender: _gender,
          age: int.tryParse(_ageController.text.trim()),
          heightCm: double.tryParse(_heightController.text.trim()),
        );

    if (saved && context.mounted) context.go('/');
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.secondaryText(context),
        ),
      ),
    );
  }
}
