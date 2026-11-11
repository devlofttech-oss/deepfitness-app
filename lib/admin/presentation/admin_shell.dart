import 'package:deepfitness/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The dashboard frame: a navigation rail beside the current section.
///
/// Built for a wide window, because this runs on Flutter Web for staff at
/// a desk, not on a phone.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  static const _destinations = <({String path, IconData icon, String label})>[
    (path: '/admin/members', icon: Icons.people_outline, label: 'Members'),
    (
      path: '/admin/exercises',
      icon: Icons.fitness_center_outlined,
      label: 'Exercises',
    ),
    (path: '/admin/plans', icon: Icons.list_alt_outlined, label: 'Plans'),
    (path: '/admin/events', icon: Icons.event_outlined, label: 'Events'),
    (
      path: '/admin/classes',
      icon: Icons.self_improvement_outlined,
      label: 'Classes',
    ),
    (
      path: '/admin/announcements',
      icon: Icons.campaign_outlined,
      label: 'Notices',
    ),
  ];

  int get _selectedIndex {
    final index = _destinations.indexWhere(
      (destination) => location.startsWith(destination.path),
    );
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas(context),
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: AppColors.surface(context),
            extended: MediaQuery.sizeOf(context).width > 1100,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                context.go(_destinations[index].path),
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Icon(Icons.shield_outlined, color: AppColors.gold),
            ),
            destinations: [
              for (final destination in _destinations)
                NavigationRailDestination(
                  icon: Icon(destination.icon),
                  label: Text(destination.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// A section heading with an optional action, shared by every screen so
/// the dashboard reads as one thing.
class AdminHeader extends StatelessWidget {
  const AdminHeader({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
