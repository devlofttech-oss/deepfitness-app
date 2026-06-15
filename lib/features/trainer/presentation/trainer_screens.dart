import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:deepfitness/services/app_data_repository.dart';
import 'package:deepfitness/shared/models/deepfitness_models.dart';
import 'package:deepfitness/shared/widgets/async_state.dart';
import 'package:deepfitness/shared/widgets/brand_mark.dart';
import 'package:deepfitness/shared/widgets/icon_tile.dart';
import 'package:deepfitness/shared/widgets/page_header.dart';
import 'package:deepfitness/shared/widgets/premium_card.dart';
import 'package:deepfitness/shared/widgets/premium_scaffold.dart';
import 'package:deepfitness/shared/widgets/primary_button.dart';
import 'package:deepfitness/shared/widgets/section_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

enum AssignmentKind { workout, diet }

enum TrainerPlanMode { saved, custom }

final selectedMemberProvider =
    NotifierProvider<SelectedMemberController, MemberSummary?>(
      SelectedMemberController.new,
    );

final trainerMembersProvider = FutureProvider<List<MemberSummary>>((ref) async {
  return ref.watch(membersProvider.future);
});

final assignmentDraftProvider =
    NotifierProvider<AssignmentDraftController, AssignmentDraft>(
      AssignmentDraftController.new,
    );

class SelectedMemberController extends Notifier<MemberSummary?> {
  @override
  MemberSummary? build() => null;

  void select(MemberSummary member) => state = member;
}

class AssignmentDraft {
  const AssignmentDraft({
    this.kind = AssignmentKind.workout,
    this.member,
    this.mode = TrainerPlanMode.saved,
    this.savedIndex = 0,
    this.exerciseIds = const {},
    this.mealNames = const {},
  });

  final AssignmentKind kind;
  final MemberSummary? member;
  final TrainerPlanMode mode;
  final int savedIndex;
  final Set<String> exerciseIds;
  final Set<String> mealNames;

  AssignmentDraft copyWith({
    AssignmentKind? kind,
    MemberSummary? member,
    TrainerPlanMode? mode,
    int? savedIndex,
    Set<String>? exerciseIds,
    Set<String>? mealNames,
  }) {
    return AssignmentDraft(
      kind: kind ?? this.kind,
      member: member ?? this.member,
      mode: mode ?? this.mode,
      savedIndex: savedIndex ?? this.savedIndex,
      exerciseIds: exerciseIds ?? this.exerciseIds,
      mealNames: mealNames ?? this.mealNames,
    );
  }
}

class AssignmentDraftController extends Notifier<AssignmentDraft> {
  @override
  AssignmentDraft build() => const AssignmentDraft();

  void start(AssignmentKind kind) {
    state = AssignmentDraft(kind: kind);
  }

  void setMember(MemberSummary member) {
    ref.read(selectedMemberProvider.notifier).select(member);
    state = state.copyWith(member: member);
  }

  void setMode(TrainerPlanMode mode) {
    state = state.copyWith(mode: mode, savedIndex: 0);
  }

  void setSavedIndex(int index) => state = state.copyWith(savedIndex: index);

  void toggleExercise(String id) {
    final ids = {...state.exerciseIds};
    if (!ids.add(id)) ids.remove(id);
    state = state.copyWith(exerciseIds: ids);
  }

  void toggleMeal(String name) {
    final names = {...state.mealNames};
    if (!names.add(name)) names.remove(name);
    state = state.copyWith(mealNames: names);
  }
}

class TrainerDashboardScreen extends ConsumerWidget {
  const TrainerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(trainerStatsProvider);

    return PremiumScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Trainer',
            subtitle: 'Manage members and plans',
            action: IconButton.filled(
              onPressed: () => context.push('/trainer/profile'),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.black,
              ),
              icon: const Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 24),
          AsyncStateView(
            value: stats,
            errorTitle: 'Could not load trainer stats',
            onRetry: () => ref.invalidate(trainerStatsProvider),
            loading: const AppLoadingState(rows: 1),
            data: (stats) => Row(
              children: [
                Expanded(
                  child: _TrainerStat(
                    icon: Icons.group_outlined,
                    value: '${stats.memberCount}',
                    label: 'Members',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TrainerStat(
                    icon: Icons.assignment_rounded,
                    value: '${stats.activePlanCount}',
                    label: 'Plans',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const SectionTitle(title: 'Quick Actions'),
          const SizedBox(height: 12),
          _ActionCard(
            title: 'Members',
            subtitle: 'View, add, and update members',
            icon: Icons.group_outlined,
            route: '/trainer/members',
          ),
          _ActionCard(
            title: 'Assign Plans',
            subtitle: 'Workout or diet, step by step',
            icon: Icons.send_rounded,
            route: '/trainer/assign',
          ),
          _ActionCard(
            title: 'Exercise Library',
            subtitle: 'Reusable exercise list',
            icon: Icons.menu_book_outlined,
            route: '/trainer/exercises',
          ),
          _ActionCard(
            title: 'Profile & Settings',
            subtitle: 'Account, settings, logout',
            icon: Icons.person_outline_rounded,
            route: '/trainer/profile',
          ),
        ],
      ),
    );
  }
}

class MembersListScreen extends ConsumerStatefulWidget {
  const MembersListScreen({super.key});

  @override
  ConsumerState<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends ConsumerState<MembersListScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(trainerMembersProvider);

    return PremiumScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackHeader(
            title: 'Members',
            subtitle: 'Assigned members',
            action: IconButton.filled(
              onPressed: () => context.push('/trainer/members/add'),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.goldBright,
                foregroundColor: AppColors.black,
              ),
              icon: const Icon(Icons.add_rounded),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search members',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 18),
          AsyncStateView(
            value: members,
            errorTitle: 'Could not load members',
            onRetry: () {
              ref.invalidate(membersProvider);
              ref.invalidate(trainerMembersProvider);
            },
            data: (members) {
              final query = _search.text.trim().toLowerCase();
              final filtered = query.isEmpty
                  ? members
                  : members
                        .where(
                          (member) =>
                              member.name.toLowerCase().contains(query) ||
                              member.goal.toLowerCase().contains(query) ||
                              member.email.toLowerCase().contains(query),
                        )
                        .toList();
              if (filtered.isEmpty) {
                return AppEmptyState(
                  title: query.isEmpty ? 'No members yet' : 'No matches found',
                  message: query.isEmpty
                      ? 'Add your first member to start assigning plans.'
                      : 'Try a different name, goal, or email.',
                  icon: Icons.group_outlined,
                  action: query.isEmpty
                      ? PrimaryButton(
                          label: 'Add Member',
                          icon: Icons.add_rounded,
                          onPressed: () => context.push('/trainer/members/add'),
                        )
                      : null,
                );
              }
              return Column(
                children: [
                  for (final member in filtered)
                    _MemberRow(
                      member: member,
                      onTap: () {
                        ref
                            .read(selectedMemberProvider.notifier)
                            .select(member);
                        context.push('/trainer/member');
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class AddMemberScreen extends ConsumerStatefulWidget {
  const AddMemberScreen({super.key});

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _goal = TextEditingController(text: 'Muscle Gain');
  final _height = TextEditingController(text: '175');
  final _weight = TextEditingController(text: '70');
  CreatedMemberInvite? _createdInvite;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _goal.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BackHeader(
            title: 'Add Member',
            subtitle: 'Trainer-created account',
          ),
          const SizedBox(height: 22),
          _LabeledField(label: 'Name', controller: _name),
          _LabeledField(
            label: 'Email',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
          ),
          _LabeledField(
            label: 'Phone',
            controller: _phone,
            keyboardType: TextInputType.phone,
          ),
          _LabeledField(
            label: 'Temporary Password',
            controller: _password,
            obscureText: true,
          ),
          _LabeledField(label: 'Goal', controller: _goal),
          _LabeledField(
            label: 'Height',
            controller: _height,
            keyboardType: TextInputType.number,
          ),
          _LabeledField(
            label: 'Weight',
            controller: _weight,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: _saving ? 'Creating...' : 'Create Member',
            icon: Icons.save_outlined,
            onPressed: _saving ? () {} : _save,
          ),
          if (_createdInvite != null) ...[
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Send WhatsApp Invite',
              icon: Icons.chat_outlined,
              outline: true,
              onPressed: _sendWhatsappInvite,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final phone = _normalizePhone(_phone.text.trim());
    final password = _password.text;
    if (name.isEmpty ||
        (email.isEmpty && phone == null) ||
        password.length < 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text('Enter name, email or phone, and 6+ character password.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final invite = await ref.read(appDataRepositoryProvider).createMember(
        name: name,
        email: email.isEmpty ? null : email,
        phone: phone,
        password: password,
        goal: _goal.text.trim().isEmpty ? 'Fitness' : _goal.text.trim(),
        heightCm: double.tryParse(_height.text.trim()) ?? 175,
        weight: double.tryParse(_weight.text.trim()) ?? 70,
      );
      ref.invalidate(membersProvider);
      ref.invalidate(trainerMembersProvider);
      ref.invalidate(trainerStatsProvider);
      ref.read(selectedMemberProvider.notifier).select(invite.member);
      setState(() => _createdInvite = invite);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${invite.member.name} created.')),
        );
      }
    } catch (error) {
      if (mounted) _showSnack(context, friendlyErrorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendWhatsappInvite() async {
    final invite = _createdInvite;
    if (invite == null) return;
    final phone = invite.member.phone ?? _normalizePhone(_phone.text.trim());
    if (phone == null) {
      _showSnack(context, 'Add a phone number to send WhatsApp invite.');
      return;
    }
    final uri = Uri.parse(
      'https://wa.me/${phone.replaceAll('+', '')}?text=${Uri.encodeComponent(invite.inviteText)}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) _showSnack(context, 'Could not open WhatsApp.');
    }
  }

  String? _normalizePhone(String value) {
    if (value.isEmpty) return null;
    final compact = value.replaceAll(RegExp(r'\s+'), '');
    return compact.startsWith('+') ? compact : '+91$compact';
  }
}

class MemberDetailScreen extends ConsumerWidget {
  const MemberDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedMemberProvider);
    final members = ref.watch(trainerMembersProvider).value ?? const [];
    final member = selected ?? (members.isNotEmpty ? members.first : null);

    if (member == null) {
      return const PremiumScaffold(
        child: AppEmptyState(
          title: 'No member selected',
          message: 'Open Members and choose someone to view their profile.',
          icon: Icons.person_search_rounded,
        ),
      );
    }

    return PremiumScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackHeader(title: member.name, subtitle: member.goal),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _TrainerStat(
                  icon: Icons.monitor_weight_outlined,
                  value: member.currentWeight.toStringAsFixed(1),
                  label: 'Weight',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TrainerStat(
                  icon: Icons.straighten_rounded,
                  value: '${member.heightCm.round()}',
                  label: 'Height cm',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Add Measurement',
            icon: Icons.monitor_weight_outlined,
            onPressed: () async {
              try {
                await ref
                    .read(appDataRepositoryProvider)
                    .addMeasurement(member.id, member.currentWeight + .2);
                ref.invalidate(membersProvider);
                ref.invalidate(trainerMembersProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Measurement added.')),
                  );
                }
              } catch (error) {
                if (context.mounted) {
                  _showSnack(context, friendlyErrorMessage(error));
                }
              }
            },
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: 'Assign Workout',
            icon: Icons.fitness_center_rounded,
            outline: true,
            onPressed: () {
              ref
                  .read(assignmentDraftProvider.notifier)
                  .start(AssignmentKind.workout);
              ref.read(assignmentDraftProvider.notifier).setMember(member);
              context.push('/trainer/assign/source');
            },
          ),
        ],
      ),
    );
  }
}

class AssignPlanScreen extends ConsumerWidget {
  const AssignPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PremiumScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BackHeader(
            title: 'Assign Plans',
            subtitle: 'Choose plan type',
          ),
          const SizedBox(height: 20),
          _ChoiceCard(
            title: 'Workout Plan',
            subtitle: 'Exercises and prescriptions',
            icon: Icons.fitness_center_rounded,
            onTap: () {
              ref
                  .read(assignmentDraftProvider.notifier)
                  .start(AssignmentKind.workout);
              context.push('/trainer/assign/member');
            },
          ),
          _ChoiceCard(
            title: 'Diet Plan',
            subtitle: 'Meals, calories, macros',
            icon: Icons.restaurant_rounded,
            onTap: () {
              ref
                  .read(assignmentDraftProvider.notifier)
                  .start(AssignmentKind.diet);
              context.push('/trainer/assign/member');
            },
          ),
        ],
      ),
    );
  }
}

class AssignMemberScreen extends ConsumerWidget {
  const AssignMemberScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(trainerMembersProvider);
    final draft = ref.watch(assignmentDraftProvider);

    return PremiumScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackHeader(
            title: 'Select Member',
            subtitle: _kindLabel(draft.kind),
            action: IconButton.filled(
              onPressed: () => context.push('/trainer/members/add'),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.goldBright,
                foregroundColor: AppColors.black,
              ),
              icon: const Icon(Icons.add_rounded),
            ),
          ),
          const SizedBox(height: 18),
          AsyncStateView(
            value: members,
            errorTitle: 'Could not load members',
            onRetry: () {
              ref.invalidate(membersProvider);
              ref.invalidate(trainerMembersProvider);
            },
            data: (members) {
              if (members.isEmpty) {
                return AppEmptyState(
                  title: 'No members yet',
                  message: 'Add a member before assigning a plan.',
                  icon: Icons.group_add_outlined,
                  action: PrimaryButton(
                    label: 'Add Member',
                    icon: Icons.add_rounded,
                    onPressed: () => context.push('/trainer/members/add'),
                  ),
                );
              }
              return Column(
                children: [
                  for (final member in members)
                    _MemberRow(
                      member: member,
                      selected: draft.member?.id == member.id,
                      onTap: () {
                        ref
                            .read(assignmentDraftProvider.notifier)
                            .setMember(member);
                        context.push('/trainer/assign/source');
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class AssignSourceScreen extends ConsumerWidget {
  const AssignSourceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(assignmentDraftProvider);
    final member = draft.member;

    return PremiumScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackHeader(
            title: 'Choose Source',
            subtitle: member == null ? _kindLabel(draft.kind) : member.name,
          ),
          const SizedBox(height: 20),
          _ChoiceCard(
            title: 'Saved Plan',
            subtitle: 'Use an existing template',
            icon: Icons.assignment_rounded,
            onTap: () {
              ref
                  .read(assignmentDraftProvider.notifier)
                  .setMode(TrainerPlanMode.saved);
              context.push('/trainer/assign/saved');
            },
          ),
          _ChoiceCard(
            title: 'Create On The Go',
            subtitle: draft.kind == AssignmentKind.workout
                ? 'Select exercises now'
                : 'Select meals now',
            icon: Icons.add_circle_outline_rounded,
            onTap: () {
              ref
                  .read(assignmentDraftProvider.notifier)
                  .setMode(TrainerPlanMode.custom);
              context.push(
                draft.kind == AssignmentKind.workout
                    ? '/trainer/assign/exercises'
                    : '/trainer/assign/meals',
              );
            },
          ),
        ],
      ),
    );
  }
}

class AssignSavedPlanScreen extends ConsumerWidget {
  const AssignSavedPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(assignmentDraftProvider);
    return draft.kind == AssignmentKind.workout
        ? _SavedWorkoutAssign(draft: draft)
        : _SavedDietAssign(draft: draft);
  }
}

class AssignExercisesScreen extends ConsumerWidget {
  const AssignExercisesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(assignmentDraftProvider);
    final exercises = ref.watch(exerciseLibraryProvider);

    return PremiumScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackHeader(
            title: 'Select Exercises',
            subtitle: draft.member?.name ?? 'Workout plan',
          ),
          const SizedBox(height: 18),
          AsyncStateView(
            value: exercises,
            errorTitle: 'Could not load exercises',
            onRetry: () => ref.invalidate(exerciseLibraryProvider),
            data: (items) {
              if (items.isEmpty) {
                return const AppEmptyState(
                  title: 'No exercises yet',
                  message: 'Add exercises to the library before building a workout.',
                  icon: Icons.fitness_center_rounded,
                );
              }
              return Column(
                children: [
                  for (final exercise in items)
                    _SelectableRow(
                      active: draft.exerciseIds.contains(exercise.id),
                      title: exercise.name,
                      subtitle:
                          '${exercise.muscleGroup} - ${exercise.sets} sets - ${exercise.reps} reps',
                      onTap: () => ref
                          .read(assignmentDraftProvider.notifier)
                          .toggleExercise(exercise.id),
                    ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Save Workout',
                    icon: Icons.save_outlined,
                    onPressed: () => _saveWorkout(context, ref, draft, items),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class AssignMealsScreen extends ConsumerStatefulWidget {
  const AssignMealsScreen({super.key});

  @override
  ConsumerState<AssignMealsScreen> createState() => _AssignMealsScreenState();
}

class _AssignMealsScreenState extends ConsumerState<AssignMealsScreen> {
  final List<DietMeal> _customMeals = [];

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(assignmentDraftProvider);
    final templates = ref.watch(mealTemplatesProvider);

    return PremiumScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackHeader(
            title: 'Select Meals',
            subtitle: draft.member?.name ?? 'Diet plan',
          ),
          const SizedBox(height: 18),
          AsyncStateView(
            value: templates,
            errorTitle: 'Could not load meal templates',
            onRetry: () => ref.invalidate(mealTemplatesProvider),
            data: (templates) {
              final meals = [...templates, ..._customMeals];
              return Column(
                children: [
                  if (meals.isEmpty)
                    const AppEmptyState(
                      title: 'No meal templates',
                      message: 'Add a custom meal below to create this diet plan.',
                      icon: Icons.restaurant_menu_rounded,
                    ),
                  for (final meal in meals)
                    _SelectableRow(
                      active: draft.mealNames.contains(meal.name),
                      title: meal.name,
                      subtitle: '${meal.time} - ${meal.calories} kcal',
                      onTap: () => ref
                          .read(assignmentDraftProvider.notifier)
                          .toggleMeal(meal.name),
                    ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Add Meal',
                    icon: Icons.add_rounded,
                    outline: true,
                    onPressed: _addMeal,
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: 'Save Diet',
                    icon: Icons.save_outlined,
                    onPressed: () => _saveDiet(context, ref, draft, meals),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addMeal() async {
    final name = TextEditingController();
    final time = TextEditingController(text: '08:00');
    final calories = TextEditingController();
    final description = TextEditingController();
    final meal = await showDialog<DietMeal>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Meal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Meal name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: time,
                decoration: const InputDecoration(labelText: 'Time'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: calories,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Calories'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: description,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty ||
                  int.tryParse(calories.text.trim()) == null) {
                return;
              }
              Navigator.pop(
                context,
                DietMeal(
                  name: name.text.trim(),
                  time: time.text.trim(),
                  description: description.text.trim(),
                  calories: int.parse(calories.text.trim()),
                  icon: name.text.trim().toLowerCase(),
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    name.dispose();
    time.dispose();
    calories.dispose();
    description.dispose();
    if (meal == null) return;
    setState(() => _customMeals.add(meal));
    ref.read(assignmentDraftProvider.notifier).toggleMeal(meal.name);
  }
}

class ExerciseLibraryScreen extends ConsumerWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(exerciseLibraryProvider);

    return PremiumScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BackHeader(title: 'Exercises', subtitle: 'Reusable library'),
          const SizedBox(height: 18),
          AsyncStateView(
            value: exercises,
            errorTitle: 'Could not load exercises',
            onRetry: () => ref.invalidate(exerciseLibraryProvider),
            data: (exercises) {
              if (exercises.isEmpty) {
                return const AppEmptyState(
                  title: 'No exercises yet',
                  message: 'Create exercises in Supabase to make them available here.',
                  icon: Icons.menu_book_outlined,
                );
              }
              return Column(
                children: [
                  for (final exercise in exercises)
                    PremiumCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const IconTile(
                            icon: Icons.fitness_center_rounded,
                            size: 42,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exercise.name,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  exercise.muscleGroup,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.secondaryText(context),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${exercise.restSeconds}s',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.secondaryText(context),
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class TrainerProfileScreen extends ConsumerWidget {
  const TrainerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final stats = ref.watch(trainerStatsProvider);

    return PremiumScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BackHeader(title: 'Profile', subtitle: 'Trainer account'),
          const SizedBox(height: 20),
          AsyncStateView(
            value: user,
            errorTitle: 'Could not load profile',
            loading: const AppLoadingState(rows: 1),
            onRetry: () => ref.invalidate(currentUserProvider),
            data: (user) => PremiumCard(
              child: Row(
                children: [
                  const BrandMark(size: 58),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.role == UserRole.trainer ? user.name : 'Trainer',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          user.email,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AsyncStateView(
            value: stats,
            errorTitle: 'Could not load stats',
            loading: const SizedBox.shrink(),
            onRetry: () => ref.invalidate(trainerStatsProvider),
            data: (stats) => Row(
              children: [
                Expanded(
                  child: _TrainerStat(
                    icon: Icons.group_outlined,
                    value: '${stats.memberCount}',
                    label: 'Members',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TrainerStat(
                    icon: Icons.assignment_rounded,
                    value: '${stats.activePlanCount}',
                    label: 'Plans',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle(title: 'Settings'),
          const SizedBox(height: 10),
          PremiumCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: const Column(
              children: [
                _SettingsRow(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifications',
                ),
                _SettingsRow(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                ),
                _SettingsRow(
                  icon: Icons.support_agent_rounded,
                  label: 'Help & Support',
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: 'Log Out',
            icon: Icons.logout_rounded,
            outline: true,
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class CreateWorkoutPlanScreen extends ConsumerWidget {
  const CreateWorkoutPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assignmentDraftProvider.notifier).start(AssignmentKind.workout);
      if (context.mounted) context.replace('/trainer/assign/member');
    });
    return const PremiumScaffold(
      child: AppLoadingState(rows: 2),
    );
  }
}

class CreateDietPlanScreen extends ConsumerWidget {
  const CreateDietPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assignmentDraftProvider.notifier).start(AssignmentKind.diet);
      if (context.mounted) context.replace('/trainer/assign/member');
    });
    return const PremiumScaffold(
      child: AppLoadingState(rows: 2),
    );
  }
}

class _SavedWorkoutAssign extends ConsumerWidget {
  const _SavedWorkoutAssign({required this.draft});

  final AssignmentDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(savedWorkoutPlansProvider);
    return PremiumScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackHeader(
            title: 'Saved Workout',
            subtitle: draft.member?.name ?? 'Select plan',
          ),
          const SizedBox(height: 18),
          AsyncStateView(
            value: plans,
            errorTitle: 'Could not load saved workouts',
            onRetry: () => ref.invalidate(savedWorkoutPlansProvider),
            data: (plans) {
              if (plans.isEmpty) {
                return const AppEmptyState(
                  title: 'No saved workouts',
                  message: 'Create a custom workout on the go for this member.',
                  icon: Icons.assignment_outlined,
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < plans.length; i++)
                    _SelectableRow(
                      active: draft.savedIndex == i,
                      title: plans[i].name,
                      subtitle: '${plans[i].exercises.length} exercises',
                      onTap: () => ref
                          .read(assignmentDraftProvider.notifier)
                          .setSavedIndex(i),
                    ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Save Workout',
                    icon: Icons.save_outlined,
                    onPressed: () {
                      final index = _safeIndex(draft.savedIndex, plans.length);
                      _saveWorkout(context, ref, draft, plans[index].exercises);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SavedDietAssign extends ConsumerWidget {
  const _SavedDietAssign({required this.draft});

  final AssignmentDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(savedDietPlansProvider);
    return PremiumScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackHeader(
            title: 'Saved Diet',
            subtitle: draft.member?.name ?? 'Select plan',
          ),
          const SizedBox(height: 18),
          AsyncStateView(
            value: plans,
            errorTitle: 'Could not load saved diets',
            onRetry: () => ref.invalidate(savedDietPlansProvider),
            data: (plans) {
              if (plans.isEmpty) {
                return const AppEmptyState(
                  title: 'No saved diets',
                  message: 'Create a custom diet on the go for this member.',
                  icon: Icons.restaurant_menu_rounded,
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < plans.length; i++)
                    _SelectableRow(
                      active: draft.savedIndex == i,
                      title: '${plans[i].goalCalories} kcal Diet',
                      subtitle: '${plans[i].meals.length} meals',
                      onTap: () => ref
                          .read(assignmentDraftProvider.notifier)
                          .setSavedIndex(i),
                    ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Save Diet',
                    icon: Icons.save_outlined,
                    onPressed: () {
                      final index = _safeIndex(draft.savedIndex, plans.length);
                      _saveDiet(context, ref, draft, plans[index].meals);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BackHeader extends StatelessWidget {
  const _BackHeader({required this.title, required this.subtitle, this.action});

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filled(
          onPressed: () => context.pop(),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.black,
          ),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PageHeader(title: title, subtitle: subtitle),
        ),
        ?action,
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return _ChoiceCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      onTap: () => context.push(route),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumCard(
        padding: const EdgeInsets.all(14),
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              IconTile(icon: icon, size: 42),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.onTap,
    this.selected = false,
  });

  final MemberSummary member;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumCard(
        padding: const EdgeInsets.all(14),
        color: selected ? AppColors.goldSoft : AppColors.white,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.black,
                child: Icon(
                  selected ? Icons.check_rounded : Icons.person_outline_rounded,
                  color: AppColors.goldBright,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${member.goal} - ${member.currentWeight.toStringAsFixed(1)} kg',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectableRow extends StatelessWidget {
  const _SelectableRow({
    required this.active,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool active;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumCard(
        padding: const EdgeInsets.all(14),
        color: active ? AppColors.goldSoft : AppColors.white,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              Icon(
                active
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: AppColors.gold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainerStat extends StatelessWidget {
  const _TrainerStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: icon, size: 42),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => _showTrainerSetting(context, label),
          child: SizedBox(
            height: 46,
            child: Row(
              children: [
                Icon(icon, color: AppColors.gold, size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
          ),
        ],
      ),
    );
  }
}

Future<void> _saveWorkout(
  BuildContext context,
  WidgetRef ref,
  AssignmentDraft draft,
  List<Exercise> available,
) async {
  final member = draft.member;
  if (member == null) {
    _showSnack(context, 'Select a member first.');
    return;
  }
  final exercises = draft.mode == TrainerPlanMode.saved
      ? available
      : available
            .where((exercise) => draft.exerciseIds.contains(exercise.id))
            .toList();
  if (exercises.isEmpty) {
    _showSnack(context, 'Select at least one exercise.');
    return;
  }
  try {
    await ref
        .read(appDataRepositoryProvider)
        .saveWorkoutPlan(
          memberId: member.id,
          name: draft.mode == TrainerPlanMode.saved
              ? 'Assigned Workout'
              : '${member.name} Custom Workout',
          focus: member.goal,
          exercises: exercises,
        );
    ref.invalidate(trainerStatsProvider);
    if (context.mounted) {
      _showSnack(context, 'Workout saved for ${member.name}.');
      context.go('/trainer');
    }
  } catch (error) {
    if (context.mounted) _showSnack(context, friendlyErrorMessage(error));
  }
}

Future<void> _saveDiet(
  BuildContext context,
  WidgetRef ref,
  AssignmentDraft draft,
  List<DietMeal> available,
) async {
  final member = draft.member;
  if (member == null) {
    _showSnack(context, 'Select a member first.');
    return;
  }
  final meals = draft.mode == TrainerPlanMode.saved
      ? available
      : available.where((meal) => draft.mealNames.contains(meal.name)).toList();
  if (meals.isEmpty) {
    _showSnack(context, 'Select at least one meal.');
    return;
  }
  final calories = meals.fold<int>(0, (sum, meal) => sum + meal.calories);
  try {
    await ref
        .read(appDataRepositoryProvider)
        .saveDietPlan(
          memberId: member.id,
          name: draft.mode == TrainerPlanMode.saved
              ? 'Assigned Diet'
              : '${member.name} Custom Diet',
          dailyCalories: calories + 400,
          protein: 160,
          carbs: 280,
          fats: 70,
          meals: meals,
        );
    if (context.mounted) {
      _showSnack(context, 'Diet saved for ${member.name}.');
      context.go('/trainer');
    }
  } catch (error) {
    if (context.mounted) _showSnack(context, friendlyErrorMessage(error));
  }
}

int _safeIndex(int index, int length) {
  if (length <= 1) return 0;
  return index.clamp(0, length - 1).toInt();
}

String _kindLabel(AssignmentKind kind) {
  return kind == AssignmentKind.workout ? 'Workout plan' : 'Diet plan';
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void _showTrainerSetting(BuildContext context, String label) {
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
            label,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(switch (label) {
            'Notifications' =>
              'Workout, meal, and member update alerts are enabled.',
            'Privacy Policy' =>
              'Member data stays private to assigned trainers and members.',
            'Help & Support' =>
              'Contact deepfitnessgym2025@gmail.com for support.',
            _ => 'Setting ready.',
          }),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    ),
  );
}
