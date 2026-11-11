import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/models/member.dart';
import 'package:deepfitness/core/widgets/df_card.dart';
import 'package:deepfitness/core/widgets/df_chrome.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:deepfitness/features/group_classes/presentation/classes_controller.dart';
import 'package:deepfitness/features/workout_report/presentation/report_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The athlete console: who the member is, their pass, and the way in to
/// everything else about their account.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(authControllerProvider).value?.member;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('PROFILE')),
      body: member == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Insets.margin,
                  Insets.md,
                  Insets.margin,
                  Insets.xl,
                ),
                children: [
                  _IdentityCard(member: member),
                  const SizedBox(height: Insets.md),
                  _PassCard(member: member),
                  const SizedBox(height: Insets.lg),
                  const DfLabel('Athlete console'),
                  const SizedBox(height: Insets.sm),
                  _ConsoleTile(
                    icon: Icons.manage_accounts_outlined,
                    title: 'Edit profile',
                    subtitle: 'Name, contact details and photo',
                    onTap: () => context.push('/profile/edit'),
                  ),
                  _ConsoleTile(
                    icon: Icons.notifications_none,
                    title: 'Notices',
                    subtitle: 'Announcements and reminders from the gym',
                    onTap: () => context.push('/notices'),
                  ),
                  const _BookingsTile(),
                  _ConsoleTile(
                    icon: Icons.insights_outlined,
                    title: 'Workout history',
                    subtitle: 'Completion rate, streaks and volume',
                    onTap: () => context.push('/reports'),
                  ),
                  _ConsoleTile(
                    icon: Icons.history,
                    title: 'Past plans',
                    subtitle: 'Every plan you have been assigned',
                    onTap: () => context.push('/plan/history'),
                  ),
                  const SizedBox(height: Insets.md),
                  _ConsoleTile(
                    icon: Icons.logout,
                    title: 'Log out',
                    subtitle: 'Sign out of Deep Fitness Mysore',
                    danger: true,
                    onTap: () =>
                        ref.read(authControllerProvider.notifier).signOut(),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Name, photo, and the three numbers worth seeing first.
class _IdentityCard extends ConsumerWidget {
  const _IdentityCard({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context).textTheme;
    final report = ref.watch(workoutReportProvider).value;
    final joined = member.joinedAt;

    return DfCard(
      padding: const EdgeInsets.all(Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.surfaceContainerHigh,
                backgroundImage: member.photoUrl == null
                    ? null
                    : NetworkImage(member.photoUrl!),
                child: member.photoUrl == null
                    ? const Icon(Icons.person, size: 28)
                    : null,
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (member.name.isEmpty ? 'Member' : member.name)
                          .toUpperCase(),
                      style: theme.headlineLarge,
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
                          'Gokulam Campus • Mysore',
                          style: theme.bodySmall?.copyWith(
                            color: AppColors.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          Container(
            padding: const EdgeInsets.symmetric(vertical: Insets.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(Radii.base),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    value: '${report?.currentStreak ?? 0}',
                    caption: 'Day streak',
                  ),
                ),
                const _StatDivider(),
                Expanded(
                  child: _MiniStat(
                    value: '${report?.completed ?? 0}',
                    caption: 'Logged this week',
                  ),
                ),
                const _StatDivider(),
                Expanded(
                  child: _MiniStat(
                    value: joined == null
                        ? '—'
                        : "${_month(joined.month)} '${joined.year % 100}",
                    caption: 'Member since',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _month(int month) => const [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ][month - 1];
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.caption});

  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: Insets.xs),
        DfLabel(caption),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.surfaceContainerHigh,
    );
  }
}

/// The membership pass: what it covers and how long is left on it.
class _PassCard extends StatelessWidget {
  const _PassCard({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final expiry = member.expiryDate;
    final joined = member.joinedAt;

    // How much of the term is behind them. Without both ends there is
    // nothing honest to draw, so the bar is left out rather than guessed.
    double? elapsed;
    if (expiry != null && joined != null && expiry.isAfter(joined)) {
      final total = expiry.difference(joined).inSeconds;
      final gone = DateTime.now().difference(joined).inSeconds;
      elapsed = (gone / total).clamp(0.0, 1.0);
    }

    final daysLeft = expiry == null
        ? null
        : expiry.difference(DateTime.now()).inDays;

    return DfCard(
      borderColour: member.isLapsed
          ? AppColors.error
          : AppColors.surfaceContainerHigh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: DfLabel('Membership pass')),
              Icon(
                member.isLapsed ? Icons.gpp_bad_outlined : Icons.verified,
                size: 18,
                color: member.isLapsed
                    ? AppColors.error
                    : AppColors.primaryContainer,
              ),
            ],
          ),
          const SizedBox(height: Insets.xs),
          Text(
            member.isLapsed ? 'LAPSED' : 'ACTIVE',
            style: theme.headlineLarge?.copyWith(
              color: member.isLapsed
                  ? AppColors.error
                  : AppColors.onSurface,
            ),
          ),
          const SizedBox(height: Insets.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DfLabel('Access scope'),
                    const SizedBox(height: 2),
                    Text('Gokulam Campus', style: theme.bodyMedium),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DfLabel('Valid through'),
                    const SizedBox(height: 2),
                    Text(
                      expiry == null
                          ? 'Not set'
                          : '${expiry.day}/${expiry.month}/${expiry.year}'
                                '${daysLeft != null && daysLeft >= 0 ? '  ($daysLeft d left)' : ''}',
                      style: theme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (elapsed != null) ...[
            const SizedBox(height: Insets.md),
            DfProgressBar(value: 1 - elapsed, height: 6),
          ],
          if (member.isLapsed) ...[
            const SizedBox(height: Insets.md),
            Text(
              'Speak to the gym to renew. Your history stays here.',
              style: theme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A row in the console list.
class _ConsoleTile extends StatelessWidget {
  const _ConsoleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final tint = danger ? AppColors.error : AppColors.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: DfCard(
        onTap: onTap,
        padding: const EdgeInsets.all(Insets.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(Radii.base),
              ),
              child: Icon(icon, size: 20, color: tint),
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: theme.headlineSmall?.copyWith(color: tint),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: Insets.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Insets.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(Radii.full),
                          ),
                          child: DfLabel(
                            badge!,
                            colour: AppColors.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// The bookings row, badged with how many places the member holds.
class _BookingsTile extends ConsumerWidget {
  const _BookingsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(myBookingsProvider).value ?? const {};

    return _ConsoleTile(
      icon: Icons.confirmation_number_outlined,
      title: 'My bookings',
      subtitle: bookings.isEmpty
          ? 'No class places held just now'
          : 'Places you are holding on upcoming sessions',
      badge: bookings.isEmpty ? null : '${bookings.length} active',
      onTap: () => context.go('/classes'),
    );
  }
}
