import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:deepfitness/core/theme/theme_controller.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:deepfitness/services/app_data_repository.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:deepfitness/shared/widgets/async_state.dart';
import 'package:deepfitness/shared/widgets/page_header.dart';
import 'package:deepfitness/shared/widgets/premium_card.dart';
import 'package:deepfitness/shared/widgets/premium_scaffold.dart';
import 'package:deepfitness/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  IconData _avatarIcon = Icons.person_rounded;
  Color _avatarColor = AppColors.black;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final progress = ref.watch(progressProvider);

    return PremiumScaffold(
      bottomPadding: 24,
      child: AsyncStateView(
        value: user,
        errorTitle: 'Could not load your profile',
        onRetry: () => ref.invalidate(currentUserProvider),
        data: (user) => AsyncStateView(
          value: progress,
          errorTitle: 'Could not load your stats',
          onRetry: () => ref.invalidate(progressProvider),
          data: (progress) => _ProfileContent(
            user: user,
            progress: progress,
            avatarIcon: _avatarIcon,
            avatarColor: _avatarColor,
            onChangeAvatar: _showAvatarPicker,
          ),
        ),
      ),
    );
  }

  void _showAvatarPicker() {
    final options = [
      (Icons.person_rounded, AppColors.black),
      (Icons.fitness_center_rounded, AppColors.gold),
      (Icons.local_fire_department_rounded, Colors.red.shade700),
      (Icons.self_improvement_rounded, AppColors.success),
    ];
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
              'Profile Picture',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (final option in options)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _avatarIcon = option.$1;
                          _avatarColor = option.$2;
                        });
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(100),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: option.$2,
                        child: Icon(option.$1, color: AppColors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({
    required this.user,
    required this.progress,
    required this.avatarIcon,
    required this.avatarColor,
    required this.onChangeAvatar,
  });

  final AppUser user;
  final MemberProgress progress;
  final IconData avatarIcon;
  final Color avatarColor;
  final VoidCallback onChangeAvatar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    final settings = ref
        .watch(appSettingsProvider)
        .maybeWhen(
          data: (settings) => settings,
          orElse: () => const AppSettings(
            notificationsEnabled: true,
            preferredUnit: 'kg',
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Profile',
          subtitle: 'Manage your fitness journey',
        ),
        const SizedBox(height: 24),
        PremiumCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: avatarColor,
                        child: Icon(
                          avatarIcon,
                          color: AppColors.goldBright,
                          size: 34,
                        ),
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: InkWell(
                          onTap: onChangeAvatar,
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.goldBright,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.surface(context),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Member since ${_formatMonthYear(user.createdAt)}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.secondaryText(context),
                              ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.workspace_premium_rounded,
                              color: AppColors.gold,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Deep Fitness Member',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: AppColors.gold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 18),
              Row(
                children: [
                  _ProfileMetric(
                    icon: Icons.monitor_weight_outlined,
                    value: '${progress.currentWeight.toStringAsFixed(1)} kg',
                    label: 'Current Weight',
                  ),
                  Container(
                    width: 1,
                    height: 58,
                    color: AppColors.divider(context),
                  ),
                  _ProfileMetric(
                    icon: Icons.fitness_center_rounded,
                    value: '${progress.workoutsThisMonth}',
                    label: 'Workouts This Month',
                  ),
                  Container(
                    width: 1,
                    height: 58,
                    color: AppColors.divider(context),
                  ),
                  _ProfileMetric(
                    icon: Icons.local_fire_department_outlined,
                    value: '${progress.dayStreak}',
                    label: 'Day Streak',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Text(
          'Personal Information',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 14),
        PremiumCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.person_outline_rounded,
                label: 'Age',
                value: user.age == null ? 'Not set' : '${user.age}',
              ),
              _InfoRow(
                icon: Icons.straighten_rounded,
                label: 'Height',
                value: user.heightCm == null
                    ? 'Not set'
                    : '${user.heightCm!.round()} cm',
              ),
              _InfoRow(
                icon: Icons.track_changes_rounded,
                label: 'Goal',
                value: _displayValue(user.goal),
              ),
              _InfoRow(
                icon: Icons.engineering_outlined,
                label: 'Trainer',
                value: _displayValue(user.trainerName),
                showDivider: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 14),
        PremiumCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              _SettingsSwitchRow(
                icon: Icons.dark_mode_outlined,
                label: 'Dark Mode',
                value: isDarkMode,
                onChanged: (value) =>
                    ref.read(themeModeProvider.notifier).setDarkMode(value),
              ),
              _SettingsSwitchRow(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                value: settings.notificationsEnabled,
                onChanged: (value) async {
                  await ref
                      .read(appDataRepositoryProvider)
                      .updateNotificationsEnabled(value);
                  ref.invalidate(appSettingsProvider);
                },
              ),
              _InfoRow(
                icon: Icons.monitor_weight_outlined,
                label: 'Units',
                value: settings.preferredUnit.toUpperCase(),
                onTap: () =>
                    _showUnitPicker(context, ref, settings.preferredUnit),
              ),
              _InfoRow(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                value: '',
                onTap: () => _showInfoSheet(
                  context,
                  title: 'Privacy Policy',
                  message:
                      'Your workout, diet, measurement, and note data is visible only to you and your assigned trainer.',
                ),
              ),
              _InfoRow(
                icon: Icons.support_agent_rounded,
                label: 'Help & Support',
                value: '',
                onTap: () => _showInfoSheet(
                  context,
                  title: 'Help & Support',
                  message:
                      'Contact deepfitnessgym2025@gmail.com for app or gym support.',
                ),
              ),
              _InfoRow(
                icon: Icons.info_outline_rounded,
                label: 'About Deep Fitness',
                value: '',
                showDivider: false,
                onTap: () => _showInfoSheet(
                  context,
                  title: 'About Deep Fitness',
                  message:
                      'Deep Fitness helps members follow trainer-assigned workouts, diets, progress tracking, and exercise logs.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: 'Log Out',
          icon: Icons.logout_rounded,
          outline: true,
          onPressed: () async {
            await ref.read(authControllerProvider.notifier).signOut();
            if (context.mounted) {
              context.go('/login');
            }
          },
        ),
      ],
    );
  }
}

String _displayValue(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? 'Not set' : trimmed;
}

String _formatMonthYear(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.gold, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.gold, size: 20),
                const SizedBox(width: 18),
                Expanded(
                  flex: 2,
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (value.isNotEmpty)
                  Flexible(
                    flex: 3,
                    child: Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.secondaryText(context),
                      ),
                    ),
                  ),
                if (value.isNotEmpty && onTap != null) const SizedBox(width: 4),
                if (onTap != null) const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 52,
          child: Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 20),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Switch(
                value: value,
                activeThumbColor: AppColors.goldBright,
                activeTrackColor: AppColors.gold.withValues(alpha: .38),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

void _showUnitPicker(BuildContext context, WidgetRef ref, String currentUnit) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Units',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          for (final unit in const ['kg', 'lb'])
            ListTile(
              leading: Icon(
                unit == currentUnit
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
              ),
              title: Text(unit.toUpperCase()),
              onTap: () async {
                await ref
                    .read(appDataRepositoryProvider)
                    .updatePreferredUnit(unit);
                ref.invalidate(appSettingsProvider);
                if (context.mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
    ),
  );
}

void _showInfoSheet(
  BuildContext context, {
  required String title,
  required String message,
}) {
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
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(message),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    ),
  );
}
