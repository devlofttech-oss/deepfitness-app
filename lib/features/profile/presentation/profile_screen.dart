import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:deepfitness/core/theme/theme_controller.dart';
import 'package:deepfitness/services/app_data_repository.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:deepfitness/shared/widgets/async_state.dart';
import 'package:deepfitness/shared/widgets/page_header.dart';
import 'package:deepfitness/shared/widgets/premium_card.dart';
import 'package:deepfitness/shared/widgets/premium_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      bottomPadding: 16,
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
    final weight = _formatWeight(progress.currentWeight);
    final height = user.heightCm == null
        ? 'Not set'
        : '${user.heightCm!.round()} cm';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Profile',
          subtitle: 'Manage your fitness journey',
        ),
        const SizedBox(height: 24),
        _ProfileSummaryCard(
          user: user,
          progress: progress,
          avatarIcon: avatarIcon,
          avatarColor: avatarColor,
          onChangeAvatar: onChangeAvatar,
        ),
        const SizedBox(height: 14),
        const _FitnessLevelCard(),
        const SizedBox(height: 14),
        _SplitInfoCard(
          leading: _ProfileInfoTile(
            title: 'Weight',
            icon: Icons.monitor_weight_outlined,
            value: weight,
            caption: 'Current Weight',
          ),
          trailing: _ProfileInfoTile(
            title: 'Height',
            icon: Icons.straighten_rounded,
            value: height,
            caption: 'Current Height',
          ),
        ),
        const SizedBox(height: 14),
        _SplitInfoCard(
          leading: _ProfileInfoTile(
            title: 'Goal',
            icon: Icons.track_changes_rounded,
            value: _displayValue(user.goal),
          ),
          trailing: _ProfileInfoTile(
            title: 'Category',
            icon: _genderIcon(user.gender),
            value: _formatGender(user.gender),
          ),
        ),
        const SizedBox(height: 14),
        _PersonalDetailsCard(user: user),
        const SizedBox(height: 14),
        _SettingsCard(
          isDarkMode: isDarkMode,
          onChanged: (value) =>
              ref.read(themeModeProvider.notifier).setDarkMode(value),
        ),
      ],
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
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
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                      size: 32,
                    ),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Material(
                      color: AppColors.goldBright,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onChangeAvatar,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surface(context),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            size: 16,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontSize: 21, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Member since ${_formatMonthYear(user.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.secondaryText(context),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.workspace_premium_rounded,
                          color: AppColors.gold,
                          size: 21,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Deep Fitness Member',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.gold,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: AppColors.divider(context)),
          const SizedBox(height: 15),
          Row(
            children: [
              _ProfileMetric(
                icon: Icons.monitor_weight_outlined,
                value: _formatWeight(progress.currentWeight),
                label: 'Weight',
              ),
              _MetricDivider(),
              _ProfileMetric(
                icon: Icons.fitness_center_rounded,
                value: '${progress.workoutsCompleted}',
                label: 'Workouts',
              ),
              _MetricDivider(),
              _ProfileMetric(
                icon: Icons.local_fire_department_outlined,
                value: '${progress.dayStreak}',
                label: 'Streak',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FitnessLevelCard extends StatelessWidget {
  const _FitnessLevelCard();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fitness Level',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(
                child: _FitnessLevelOption(
                  icon: Icons.directions_walk_rounded,
                  label: 'Beginner',
                  selected: true,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _FitnessLevelOption(
                  icon: Icons.directions_run_rounded,
                  label: 'Intermediate',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _FitnessLevelOption(
                  icon: Icons.fitness_center_rounded,
                  label: 'Advanced',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FitnessLevelOption extends StatelessWidget {
  const _FitnessLevelOption({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.gold : AppColors.text(context);
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.goldSoft.withValues(alpha: .62)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? AppColors.gold.withValues(alpha: .32)
              : AppColors.divider(context),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: foreground),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 12.5,
                color: foreground,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitInfoCard extends StatelessWidget {
  const _SplitInfoCard({required this.leading, required this.trailing});

  final _ProfileInfoTile leading;
  final _ProfileInfoTile trailing;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: leading),
            VerticalDivider(
              width: 26,
              thickness: 1,
              color: AppColors.divider(context),
            ),
            Expanded(child: trailing),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.title,
    required this.icon,
    required this.value,
    this.caption,
  });

  final String title;
  final IconData icon;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _SoftIconBox(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: caption == null ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: title == 'Goal'
                          ? AppColors.secondaryText(context)
                          : AppColors.text(context),
                    ),
                  ),
                  if (caption != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      caption!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryText(context),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PersonalDetailsCard extends StatelessWidget {
  const _PersonalDetailsCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Details',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _DetailRow(
            icon: Icons.person_outline_rounded,
            label: 'Age',
            value: user.age == null ? 'Not set' : '${user.age}',
          ),
          _DetailRow(
            icon: Icons.phone_outlined,
            label: 'Contact',
            value: _displayValue(user.phone),
          ),
          _DetailRow(
            icon: Icons.person_add_alt_1_outlined,
            label: 'Trainer',
            value: _displayValue(user.trainerName),
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.isDarkMode, required this.onChanged});

  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: Row(
              children: [
                const Icon(
                  Icons.dark_mode_outlined,
                  color: AppColors.gold,
                  size: 22,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    'Dark Mode',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Transform.scale(
                  scale: .9,
                  child: Switch(
                    value: isDarkMode,
                    activeThumbColor: AppColors.goldBright,
                    activeTrackColor: AppColors.gold.withValues(alpha: .35),
                    inactiveThumbColor: AppColors.muted.withValues(alpha: .72),
                    inactiveTrackColor: Colors.transparent,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 22),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.secondaryText(context),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, color: AppColors.divider(context)),
      ],
    );
  }
}

class _SoftIconBox extends StatelessWidget {
  const _SoftIconBox({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.goldSoft.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold.withValues(alpha: .18)),
      ),
      child: Icon(icon, color: AppColors.gold, size: 22),
    );
  }
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
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText(context),
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 56, color: AppColors.divider(context));
  }
}

String _displayValue(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? 'Not set' : trimmed;
}

String _formatWeight(double value) {
  return value <= 0 ? 'Not set' : '${value.toStringAsFixed(1)} kg';
}

String _formatGender(String? value) {
  final gender = value?.trim().toLowerCase() ?? '';
  if (gender == 'female') return 'Female';
  if (gender == 'other') return 'Other';
  return 'Male';
}

IconData _genderIcon(String? value) {
  final gender = value?.trim().toLowerCase() ?? '';
  if (gender == 'female') return Icons.female_rounded;
  return Icons.male_rounded;
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
