import 'package:deepfitness/admin/application/admin_controllers.dart';
import 'package:deepfitness/admin/presentation/admin_shell.dart';
import 'package:deepfitness/admin/presentation/image_field.dart';
import 'package:deepfitness/core/models/base_fields.dart';
import 'package:deepfitness/core/models/exercise.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The exercise library. Plans are built from this.
class AdminExercisesScreen extends ConsumerWidget {
  const AdminExercisesScreen({super.key});

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, {
    Exercise? existing,
  }) async {
    final draft = await showDialog<Exercise>(
      context: context,
      builder: (context) => _ExerciseDialog(existing: existing),
    );
    if (draft == null) return;

    final saved = await ref
        .read(adminActionProvider.notifier)
        .run(
          (repository) => repository.saveExercise(
            draft,
            authorId: ref.read(adminAuthorIdProvider),
          ),
          refresh: [adminExercisesProvider],
        );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(saved ? 'Saved.' : 'Could not save that.')),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Exercise exercise,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${exercise.name}?'),
        // Soft delete, so this is reversible and nobody's finished
        // history changes. Worth saying plainly.
        content: const Text(
          'It stops appearing in the library. Plans already assigned keep '
          'their own copy and are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref
        .read(adminActionProvider.notifier)
        .run(
          (repository) => repository.deleteExercise(exercise.id),
          refresh: [adminExercisesProvider],
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(adminExercisesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminHeader(
          title: 'Exercise library',
          action: FilledButton.icon(
            onPressed: () => _edit(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('New exercise'),
          ),
        ),
        Expanded(
          child: exercises.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('$error')),
            data: (list) => list.isEmpty
                ? const Center(child: Text('The library is empty.'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    itemCount: list.length + 1,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index == list.length) {
                        return LoadMoreRow(
                          hasMore:
                              ref.read(adminExercisesProvider.notifier).hasMore,
                          onTap: () => ref
                              .read(adminExercisesProvider.notifier)
                              .loadMore(),
                        );
                      }
                      final exercise = list[index];
                      return ListTile(
                        title: Text(exercise.name),
                        subtitle: Text(
                          [
                            if (exercise.muscleGroup.isNotEmpty)
                              exercise.muscleGroup,
                            '${exercise.defaultSets} × ${exercise.defaultReps}',
                          ].join(' · '),
                        ),
                        onTap: () => _edit(context, ref, existing: exercise),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(context, ref, exercise),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _ExerciseDialog extends StatefulWidget {
  const _ExerciseDialog({this.existing});

  final Exercise? existing;

  @override
  State<_ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends State<_ExerciseDialog> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _description = TextEditingController(
    text: widget.existing?.description ?? '',
  );
  late final _muscleGroup = TextEditingController(
    text: widget.existing?.muscleGroup ?? '',
  );
  late final _sets = TextEditingController(
    text: '${widget.existing?.defaultSets ?? 3}',
  );
  late final _reps = TextEditingController(
    text: '${widget.existing?.defaultReps ?? 10}',
  );
  late List<String> _photoUrls = [...?widget.existing?.photoUrls];

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _muscleGroup.dispose();
    _sets.dispose();
    _reps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'New exercise' : 'Edit exercise'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ImageField(
                folder: 'exercises',
                id: widget.existing?.id ?? '',
                initialUrl: _photoUrls.isEmpty ? null : _photoUrls.first,
                // One image is what the member's plan shows, so a new
                // upload replaces rather than appends.
                onUploaded: (url) => setState(() => _photoUrls = [url]),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _muscleGroup,
                decoration: const InputDecoration(labelText: 'Muscle group'),
              ),
              TextField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sets,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Default sets',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _reps,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Default reps',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_name.text.trim().isEmpty) return;
            Navigator.of(context).pop(
              Exercise(
                base: BaseFields(id: widget.existing?.id ?? ''),
                name: _name.text.trim(),
                description: _description.text.trim(),
                muscleGroup: _muscleGroup.text.trim(),
                photoUrls: _photoUrls,
                defaultSets: int.tryParse(_sets.text) ?? 3,
                defaultReps: int.tryParse(_reps.text) ?? 10,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
