import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:deepfitness/shared/widgets/pressable_scale.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MemberShell extends StatelessWidget {
  const MemberShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .06),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Today',
                  active: location == '/',
                  onTap: () => context.go('/'),
                ),
                _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Progress',
                  active: location == '/progress',
                  onTap: () => context.go('/progress'),
                ),
                _NavItem(
                  icon: Icons.restaurant_rounded,
                  label: 'Diet',
                  active: location == '/diet',
                  onTap: () => context.go('/diet'),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  active: location == '/profile',
                  onTap: () => context.go('/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                width: 38,
                height: 34,
                decoration: BoxDecoration(
                  color: active ? AppColors.text(context) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: active ? AppColors.goldBright : AppColors.muted,
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                style:
                    Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: active
                          ? AppColors.text(context)
                          : AppColors.secondaryText(context),
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ) ??
                    const TextStyle(),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
