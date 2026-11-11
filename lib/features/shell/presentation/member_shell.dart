import 'package:deepfitness/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The five member tabs from the designs.
enum MemberTab {
  home(path: '/', icon: Icons.home_outlined, label: 'Home'),
  workouts(path: '/plan', icon: Icons.fitness_center, label: 'Workouts'),
  classes(path: '/classes', icon: Icons.groups_outlined, label: 'Classes'),
  events(path: '/events', icon: Icons.confirmation_number_outlined, label: 'Events'),
  profile(path: '/profile', icon: Icons.person_outline, label: 'Profile');

  const MemberTab({
    required this.path,
    required this.icon,
    required this.label,
  });

  final String path;
  final IconData icon;
  final String label;
}

/// The frame every member screen sits in: the tab bar, pinned to the
/// lowest surface so it reads as part of the chrome rather than a card.
class MemberShell extends StatelessWidget {
  const MemberShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  /// Matches on the longest prefix, so `/plan/exercise` keeps Workouts
  /// lit rather than falling back to Home.
  MemberTab get _current {
    var best = MemberTab.home;
    var bestLength = 0;

    for (final tab in MemberTab.values) {
      if (tab.path == '/') continue;
      if (location.startsWith(tab.path) && tab.path.length > bestLength) {
        best = tab;
        bestLength = tab.path.length;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border(
            top: BorderSide(color: AppColors.surfaceContainerHigh),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (final tab in MemberTab.values)
                  Expanded(
                    child: _TabButton(
                      tab: tab,
                      selected: tab == current,
                      onTap: () => context.go(tab.path),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final MemberTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Active is the accent on both glyph and label; there is no pill or
    // underline, matching the designs.
    final colour = selected
        ? AppColors.primaryContainer
        : AppColors.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(tab.icon, size: 22, color: colour),
          const SizedBox(height: Insets.xs),
          Text(
            tab.label.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colour),
          ),
        ],
      ),
    );
  }
}
