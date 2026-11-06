import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/models/app_models.dart';
import 'package:deepfitness/core/models/member.dart';
import 'package:deepfitness/core/repositories/app_data_repository.dart';
import 'package:deepfitness/core/widgets/async_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Builds a plan for one member and assigns it.
///
/// Assignment snapshots the exercises, so what is chosen here is frozen onto
/// the member's plan: editing the library afterwards cannot rewrite what they
/// were asked to do.
Future<void> showPlanBuilder(
  BuildContext context,
  WidgetRef ref,
  Member member,
) async {
  final assigned = await showDialog<bool>(
    context: context,
    builder: (context) => _PlanBuilderDialog(member: member),
  );

  if (assigned == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Plan assigned to ${member.name}.')),
    );
  }
}

class _PlanBuilderDialog extends ConsumerStatefulWidget {
  const _PlanBuilderDialog({required this.member});

  final Member member;

  @override
  ConsumerState<_PlanBuilderDialog> createState() => _PlanBuilderDialogState();
}

class _PlanBuilderDialogState extends ConsumerState<_PlanBuilderDialog> {
  final _title = TextEditingController(text: 'Training Day');
  final _focus = TextEditingController(text: 'Full Body');
  final _search = TextEditingController();

  /// Chosen exercises in the order they will be performed, which is also the
  /// order the member unlocks them in.
  final List<Exercise> _chosen = [];
  DateTime _scheduledFor = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _focus.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(exerciseLibraryProvider);
    final query = _search.text.trim().toLowerCase();

    return AlertDialog(
      title: Text('Assign a plan to ${widget.member.name}'),
      content: SizedBox(
        width: 720,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _focus,
                    decoration: const InputDecoration(labelText: 'Focus'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'For'),
                      child: Text(_dayLabel(_scheduledFor)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Search the library',
                            prefixIcon: Icon(Icons.search_rounded),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: AsyncStateView(
                            value: library,
                            onRetry: () =>
                                ref.invalidate(exerciseLibraryProvider),
                            data: (items) {
                              final matches = query.isEmpty
                                  ? items
                                  : items
                                        .where(
                                          (exercise) =>
                                              exercise.name
                                                  .toLowerCase()
                                                  .contains(query) ||
                                              exercise.muscleGroup
                                                  .toLowerCase()
                                                  .contains(query),
                                        )
                                        .toList();

                              if (matches.isEmpty) {
                                return const AppEmptyState(
                                  icon: Icons.search_off_rounded,
                                  title: 'Nothing matches',
                                  message: 'Try another search.',
                                );
                              }

                              return ListView.builder(
                                itemCount: matches.length,
                                itemBuilder: (context, index) {
                                  final exercise = matches[index];
                                  return ListTile(
                                    dense: true,
                                    title: Text(exercise.name),
                                    subtitle: Text(exercise.muscleGroup),
                                    trailing: const Icon(Icons.add_rounded),
                                    // The same exercise may be added twice,
                                    // which is a normal thing to program.
                                    onTap: () => setState(
                                      () => _chosen.add(exercise),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'In this plan (${_chosen.length})',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _chosen.isEmpty
                              ? const AppEmptyState(
                                  icon: Icons.playlist_add_rounded,
                                  title: 'Nothing added yet',
                                  message:
                                      'Pick exercises on the left, in the '
                                      'order they should be done.',
                                )
                              : ReorderableListView.builder(
                                  itemCount: _chosen.length,
                                  onReorderItem: _reorder,
                                  itemBuilder: (context, index) =>
                                      _ChosenRow(
                                        key: ValueKey(
                                          '${_chosen[index].id}-$index',
                                        ),
                                        position: index + 1,
                                        exercise: _chosen[index],
                                        onChanged: (updated) => setState(
                                          () => _chosen[index] = updated,
                                        ),
                                        onRemove: () => setState(
                                          () => _chosen.removeAt(index),
                                        ),
                                      ),
                                ),
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
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving || _chosen.isEmpty ? null : _assign,
          child: Text(_saving ? 'Assigning...' : 'Assign'),
        ),
      ],
    );
  }

  /// Order is not cosmetic here: it is the order the member unlocks the
  /// exercises in.
  ///
  /// onReorderItem already accounts for the moved row leaving the list, so
  /// newIndex needs no adjusting.
  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final moved = _chosen.removeAt(oldIndex);
      _chosen.insert(newIndex, moved);
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledFor,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _scheduledFor = picked);
  }

  Future<void> _assign() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(appDataRepositoryProvider)
          .saveWorkoutPlan(
            memberId: widget.member.id,
            name: _title.text.trim().isEmpty
                ? 'Training Day'
                : _title.text.trim(),
            focus: _focus.text.trim(),
            exercises: _chosen,
            scheduledFor: _scheduledFor,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
      }
    }
  }
}

/// One chosen exercise, with the sets and reps the member will see.
class _ChosenRow extends StatelessWidget {
  const _ChosenRow({
    super.key,
    required this.position,
    required this.exercise,
    required this.onChanged,
    required this.onRemove,
  });

  final int position;
  final Exercise exercise;
  final ValueChanged<Exercise> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: AppColors.chipBackground(context),
            child: Text(
              '$position',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              exercise.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 54,
            child: TextFormField(
              initialValue: '${exercise.sets}',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Sets',
                isDense: true,
              ),
              onChanged: (value) => onChanged(
                exercise.copyWith(sets: int.tryParse(value) ?? exercise.sets),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: TextFormField(
              initialValue: exercise.reps,
              decoration: const InputDecoration(
                labelText: 'Reps',
                isDense: true,
              ),
              onChanged: (value) => onChanged(exercise.copyWith(reps: value)),
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

String _dayLabel(DateTime date) {
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
  return '${date.day} ${months[date.month - 1]}';
}
