import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/models/group_class.dart';
import 'package:deepfitness/features/group_classes/presentation/classes_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The on-demand class library.
class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(classesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Classes')),
      body: SafeArea(
        child: classes.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const _Message(
            'Could not load classes. Check your connection.',
          ),
          data: (list) => list.isEmpty
              ? const _Message('No classes just yet.')
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) =>
                      _ClassCard(groupClass: list[index]),
                ),
        ),
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
                    groupClass.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (groupClass.durationMins > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${groupClass.durationMins} min',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
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

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.onSurfaceVariant),
        ),
      ),
    );
  }
}
