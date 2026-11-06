import 'package:deepfitness/core/constants/app_constants.dart';
import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:deepfitness/shared/widgets/page_header.dart';
import 'package:deepfitness/shared/widgets/premium_card.dart';
import 'package:deepfitness/shared/widgets/premium_scaffold.dart';
import 'package:deepfitness/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Shown when a membership has lapsed.
///
/// A lapsed membership is a state, not a sign-out. Training is closed off, but
/// the member keeps read access to their own history — losing sight of months
/// of logged work is not how you persuade someone to renew.
class RenewalScreen extends ConsumerWidget {
  const RenewalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).value;
    final expiry = session?.membershipExpiresAt;

    return PremiumScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Membership expired',
            subtitle: 'Renew at the front desk to start training again',
          ),
          const SizedBox(height: 20),
          PremiumCard(
            color: AppColors.gold.withValues(alpha: .10),
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.gold,
                  child: Icon(
                    Icons.lock_clock_rounded,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expiry == null
                            ? 'Your membership is no longer active'
                            : 'Your membership ended on ${_formatDate(expiry)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your workout history and progress are still here, '
                        'and your plan picks up where you left off.',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(
                              color: AppColors.secondaryText(context),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'View my progress',
            icon: Icons.insights_rounded,
            outline: true,
            onPressed: () => context.go('/progress'),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Back to home',
            icon: Icons.home_outlined,
            outline: true,
            onPressed: () => context.go('/'),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Speak to the team at ${AppConstants.appName} to renew.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.secondaryText(context),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
              child: const Text('Sign out'),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
