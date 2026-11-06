import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:deepfitness/core/widgets/brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Destinations in the dashboard, in the order the guide lists them.
enum AdminSection {
  overview('/admin', 'Overview', Icons.dashboard_outlined),
  members('/admin/members', 'Members', Icons.people_outline_rounded),
  library('/admin/library', 'Exercises', Icons.fitness_center_outlined),
  events('/admin/events', 'Events', Icons.celebration_outlined),
  classes('/admin/classes', 'Classes', Icons.ondemand_video_outlined),
  announcements(
    '/admin/announcements',
    'Announcements',
    Icons.campaign_outlined,
  );

  const AdminSection(this.path, this.label, this.icon);

  final String path;
  final String label;
  final IconData icon;

  static AdminSection forPath(String path) {
    // Longest match first, so /admin/members does not resolve to /admin.
    final ordered = values.toList()
      ..sort((a, b) => b.path.length.compareTo(a.path.length));
    return ordered.firstWhere(
      (section) => path.startsWith(section.path),
      orElse: () => AdminSection.overview,
    );
  }
}

/// The dashboard frame: a rail on a wide window, a drawer on a narrow one.
///
/// Access is enforced by the Firestore rules and the route guard; this only
/// decides what is worth drawing.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final current = AdminSection.forPath(location);
    final wide = MediaQuery.sizeOf(context).width >= 1000;

    return Scaffold(
      appBar: wide
          ? null
          : AppBar(
              title: Text(current.label),
              actions: [_SignOutButton(ref: ref)],
            ),
      drawer: wide
          ? null
          : Drawer(
              child: SafeArea(
                child: _AdminMenu(
                  current: current,
                  onTap: (section) {
                    Navigator.pop(context);
                    context.go(section.path);
                  },
                ),
              ),
            ),
      body: Row(
        children: [
          if (wide)
            SizedBox(
              width: 248,
              child: ColoredBox(
                color: AppColors.surface(context),
                child: SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: _AdminMenu(
                          current: current,
                          onTap: (section) => context.go(section.path),
                        ),
                      ),
                      _SignOutTile(ref: ref),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMenu extends StatelessWidget {
  const _AdminMenu({required this.current, required this.onTap});

  final AdminSection current;
  final void Function(AdminSection section) onTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(10, 4, 10, 22),
          child: Row(
            children: [
              BrandMark(size: 38),
              SizedBox(width: 12),
              Text(
                'Dashboard',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        for (final section in AdminSection.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              leading: Icon(section.icon),
              title: Text(section.label),
              selected: section == current,
              selectedTileColor: AppColors.gold.withValues(alpha: .12),
              selectedColor: AppColors.goldBright,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () => onTap(section),
            ),
          ),
      ],
    );
  }
}

class _SignOutTile extends StatelessWidget {
  const _SignOutTile({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListTile(
        leading: const Icon(Icons.logout_rounded),
        title: const Text('Sign out'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: () => ref.read(authControllerProvider.notifier).signOut(),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Sign out',
      onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
      icon: const Icon(Icons.logout_rounded),
    );
  }
}

/// Page title plus an optional primary action, used by every admin screen.
class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryText(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ?action,
          ],
        ),
        const SizedBox(height: 20),
        Expanded(child: child),
      ],
    );
  }
}
