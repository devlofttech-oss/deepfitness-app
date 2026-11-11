import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/constants/app_constants.dart';
import 'package:deepfitness/core/widgets/primary_button.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Shown when a membership has lapsed.
///
/// A lapse is a state on the member document, not a sign-out: the member
/// stays signed in and their own history stays readable, so this screen
/// offers a way through to it rather than being a dead end.
class RenewalScreen extends ConsumerWidget {
  const RenewalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(authControllerProvider).value?.member;
    final expiry = member?.expiryDate;

    return Scaffold(
      backgroundColor: AppColors.canvas(context),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.card_membership_outlined,
                  size: 56,
                  color: AppColors.gold,
                ),
                const SizedBox(height: 24),
                Text(
                  'Your membership has lapsed',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  expiry == null
                      ? 'Speak to the gym to renew and pick your plan back up.'
                      : 'It ran out on ${expiry.day}/${expiry.month}/${expiry.year}. '
                            'Speak to the gym to renew and pick your plan back up.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.secondaryText(context)),
                ),
                const SizedBox(height: 32),
                // Reports land here as module 03; until then the profile
                // is the way through rather than a promise of a screen
                // that does not exist.
                PrimaryButton(
                  label: 'My profile',
                  onPressed: () => context.go('/profile'),
                ),
                const SizedBox(height: 24),
                Text(
                  AppConstants.supportEmail,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.secondaryText(context)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
