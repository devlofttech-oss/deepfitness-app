import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/widgets/df_card.dart';
import 'package:deepfitness/core/models/group_class.dart';
import 'package:deepfitness/features/group_classes/presentation/book_class_tab.dart';
import 'package:deepfitness/features/group_classes/presentation/classes_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The on-demand class library.
/// Which half of the Classes tab is showing.
final classesTabProvider = NotifierProvider<ClassesTabController, ClassesTab>(
  ClassesTabController.new,
);

enum ClassesTab { videos, booking }

class ClassesTabController extends Notifier<ClassesTab> {
  @override
  ClassesTab build() => ClassesTab.videos;

  void select(ClassesTab tab) => state = tab;
}

/// Classes: on-demand videos, and the live timetable to book a place in.
class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(classesTabProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('CLASSES')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.margin,
                Insets.sm,
                Insets.margin,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SegmentButton(
                      label: 'Workout videos',
                      icon: Icons.play_circle_outline,
                      selected: tab == ClassesTab.videos,
                      onTap: () => ref
                          .read(classesTabProvider.notifier)
                          .select(ClassesTab.videos),
                    ),
                  ),
                  const SizedBox(width: Insets.sm),
                  Expanded(
                    child: _SegmentButton(
                      label: 'Book a class',
                      icon: Icons.calendar_month_outlined,
                      selected: tab == ClassesTab.booking,
                      onTap: () => ref
                          .read(classesTabProvider.notifier)
                          .select(ClassesTab.booking),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: tab == ClassesTab.videos
                  ? const _VideoLibrary()
                  : const BookClassTab(),
            ),
          ],
        ),
      ),
    );
  }
}

/// One half of the segmented control at the top of the tab.
class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? AppColors.onPrimaryContainer
        : AppColors.onSurfaceVariant;

    return Material(
      color: selected
          ? AppColors.primaryContainer
          : AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(Radii.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.full),
        child: Container(
          height: kMinTouchTarget,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.full),
            border: Border.all(
              color: selected
                  ? AppColors.primaryContainer
                  : AppColors.surfaceContainerHigh,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: Insets.xs),
              DfLabel(label, colour: foreground),
            ],
          ),
        ),
      ),
    );
  }
}

/// The on-demand video library.
class _VideoLibrary extends ConsumerWidget {
  const _VideoLibrary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(classesProvider);

    return classes.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const DfMessage(
        icon: Icons.wifi_off,
        title: 'Could not load classes',
        body: 'Check your connection and try again.',
      ),
      data: (list) => list.isEmpty
          ? const DfMessage(
              icon: Icons.self_improvement,
              title: 'No classes yet',
              body: 'The gym has not published any class videos.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                Insets.margin,
                Insets.md,
                Insets.margin,
                Insets.xl,
              ),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: Insets.sm),
              itemBuilder: (context, index) =>
                  _ClassCard(groupClass: list[index]),
            ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.groupClass});

  final GroupClass groupClass;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/classes/${groupClass.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (groupClass.thumbnailUrl != null)
              Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    groupClass.thumbnailUrl!,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                  if (groupClass.hasVideo)
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.play_arrow, color: Colors.white),
                    ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    groupClass.title.toUpperCase(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (groupClass.durationMins > 0) ...[
                    const SizedBox(height: 4),
                    DfLabel('${groupClass.durationMins} min'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
