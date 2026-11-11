import 'package:deepfitness/admin/application/admin_controllers.dart';
import 'package:deepfitness/admin/presentation/admin_shell.dart';
import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/models/base_fields.dart';
import 'package:deepfitness/core/models/exercise.dart';
import 'package:deepfitness/core/models/member.dart';
import 'package:deepfitness/core/models/workout_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Plan templates, and assigning one to a member.
class AdminPlansScreen extends ConsumerWidget {
  const AdminPlansScreen({super.key});

  Future<void> _build(
    BuildContext context,
    WidgetRef ref, {
    WorkoutPlan? existing,
  }) async {
    final library = ref.read(adminExercisesProvider).value ?? const [];
    final draft = await showDialog<WorkoutPlan>(
      context: context,
      builder: (context) =>
          _PlanBuilderDialog(existing: existing, library: library),
    );
    if (draft == null) return;

    await ref
        .read(adminActionProvider.notifier)
        .run(
          (repository) =>
              repository.savePlan(draft, authorId: ref.read(adminAuthorIdProvider)),
          refresh: [adminPlansProvider],
        );
  }

  Future<void> _assign(
    BuildContext context,
    WidgetRef ref,
    WorkoutPlan plan,
  ) async {
    final members = ref.read(adminMembersProvider).value ?? const <Member>[];
    final memberId = await showDialog<String>(
      context: context,
      builder: (context) => _PickMemberDialog(members: members),
    );
    if (memberId == null) return;

    final assigned = await ref
        .read(adminActionProvider.notifier)
        .run(
          (repository) => repository.assignPlan(
            plan: plan,
            library: ref.read(adminExercisesProvider).value ?? const [],
            memberId: memberId,
            authorId: ref.read(adminAuthorIdProvider),
          ),
        );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          assigned
              ? 'Assigned. The member sees it on their home screen.'
              : 'Could not assign that plan.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(adminPlansProvider);
    // Loaded here so the builder dialog has the library to hand.
    ref.watch(adminExercisesProvider);
    ref.watch(adminMembersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminHeader(
          title: 'Workout plans',
          action: FilledButton.icon(
            onPressed: () => _build(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('New plan'),
          ),
        ),
        Expanded(
          child: plans.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('$error')),
            data: (list) => list.isEmpty
                ? const Center(child: Text('No plans yet.'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    itemCount: list.length + 1,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index == list.length) {
                        return LoadMoreRow(
                          hasMore:
                              ref.read(adminPlansProvider.notifier).hasMore,
                          onTap: () =>
                              ref.read(adminPlansProvider.notifier).loadMore(),
                        );
                      }
                      final plan = list[index];
                      return ListTile(
                        title: Text(plan.title),
                        subtitle: Text(
                          '${plan.exerciseRefs.length} exercises',
                        ),
                        onTap: () => _build(context, ref, existing: plan),
                        trailing: FilledButton.tonal(
                          onPressed: () => _assign(context, ref, plan),
                          child: const Text('Assign'),
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

/// Builds a plan: a title, and exercises picked in the order a member
/// will work through them.
class _PlanBuilderDialog extends StatefulWidget {
  const _PlanBuilderDialog({this.existing, required this.library});

  final WorkoutPlan? existing;
  final List<Exercise> library;

  @override
  State<_PlanBuilderDialog> createState() => _PlanBuilderDialogState();
}

class _PlanBuilderDialogState extends State<_PlanBuilderDialog> {
  late final _title = TextEditingController(
    text: widget.existing?.title ?? '',
  );
  late final List<String> _picked = [...?widget.existing?.exerciseRefs];

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final byId = {for (final exercise in widget.library) exercise.id: exercise};

    return AlertDialog(
      title: Text(widget.existing == null ? 'New plan' : 'Edit plan'),
      content: SizedBox(
        width: 560,
        height: 480,
        child: Column(
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Plan title'),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Order matters: a member unlocks these one at a time.',
                style: TextStyle(color: AppColors.secondaryText(context)),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  // Left: the library. Right: the plan, in order.
                  Expanded(
                    child: ListView(
                      children: [
                        for (final exercise in widget.library)
                          CheckboxListTile(
                            dense: true,
                            value: _picked.contains(exercise.id),
                            title: Text(exercise.name),
                            onChanged: (checked) => setState(() {
                              if (checked ?? false) {
                                _picked.add(exercise.id);
                              } else {
                                _picked.remove(exercise.id);
                              }
                            }),
                          ),
                      ],
                    ),
                  ),
                  const VerticalDivider(),
                  Expanded(
                    child: _picked.isEmpty
                        ? const Center(child: Text('Nothing picked yet.'))
                        : ReorderableListView(
                            onReorder: (oldIndex, newIndex) => setState(() {
                              // ReorderableListView reports the target
                              // index before the removal, so it shifts by
                              // one when moving an item downwards.
                              final target = newIndex > oldIndex
                                  ? newIndex - 1
                                  : newIndex;
                              _picked.insert(
                                target,
                                _picked.removeAt(oldIndex),
                              );
                            }),
                            children: [
                              for (var i = 0; i < _picked.length; i++)
                                ListTile(
                                  key: ValueKey(_picked[i]),
                                  dense: true,
                                  leading: Text('${i + 1}'),
                                  title: Text(
                                    byId[_picked[i]]?.name ?? 'Removed',
                                  ),
                                  trailing: const Icon(Icons.drag_handle),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_title.text.trim().isEmpty || _picked.isEmpty) return;
            Navigator.of(context).pop(
              WorkoutPlan(
                base: BaseFields(id: widget.existing?.id ?? ''),
                title: _title.text.trim(),
                description: widget.existing?.description ?? '',
                exerciseRefs: List.unmodifiable(_picked),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _PickMemberDialog extends StatelessWidget {
  const _PickMemberDialog({required this.members});

  final List<Member> members;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign to'),
      content: SizedBox(
        width: 400,
        height: 420,
        child: members.isEmpty
            ? const Center(child: Text('No members loaded.'))
            : ListView(
                children: [
                  for (final member in members)
                    ListTile(
                      title: Text(
                        member.name.isEmpty ? 'Unnamed member' : member.name,
                      ),
                      subtitle: Text(member.phone ?? member.email ?? ''),
                      onTap: () => Navigator.of(context).pop(member.id),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
