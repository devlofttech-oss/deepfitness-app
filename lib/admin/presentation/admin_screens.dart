import 'package:deepfitness/admin/data/admin_repository.dart';
import 'package:deepfitness/admin/presentation/admin_shell.dart';
import 'package:deepfitness/core/models/announcement.dart';
import 'package:deepfitness/core/models/completion_log.dart';
import 'package:deepfitness/core/models/group_class.dart';
import 'package:deepfitness/core/models/gym_event.dart';
import 'package:deepfitness/core/models/member.dart';
import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/repositories/app_data_repository.dart';
import 'package:deepfitness/core/models/app_models.dart';
import 'package:deepfitness/core/widgets/async_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --------------------------------------------------------------- overview

class AdminOverviewScreen extends ConsumerWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(adminMembersProvider);
    final events = ref.watch(adminEventsProvider);
    final sessions = ref.watch(adminSessionsProvider);

    return AdminPage(
      title: 'Overview',
      subtitle: 'What is happening at the gym',
      child: ListView(
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _StatCard(
                label: 'Members',
                icon: Icons.people_outline_rounded,
                value: members.whenOrNull(data: (items) => '${items.length}'),
              ),
              _StatCard(
                label: 'Lapsed',
                icon: Icons.lock_clock_rounded,
                value: members.whenOrNull(
                  data: (items) =>
                      '${items.where((member) => member.isLapsed).length}',
                ),
              ),
              _StatCard(
                label: 'Upcoming events',
                icon: Icons.celebration_outlined,
                value: events.whenOrNull(
                  data: (items) =>
                      '${items.where((event) => !event.isPast).length}',
                ),
              ),
              _StatCard(
                label: 'Upcoming classes',
                icon: Icons.ondemand_video_outlined,
                value: sessions.whenOrNull(
                  data: (items) =>
                      '${items.where((session) => !session.isPast).length}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.icon, this.value});

  final String label;
  final IconData icon;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: 220,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, color: AppColors.gold),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value ?? '—',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryText(context),
                      ),
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

// ---------------------------------------------------------------- members

class AdminMembersScreen extends ConsumerWidget {
  const AdminMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(adminMembersProvider);
    final selected = ref.watch(adminSelectedMemberProvider);

    return AdminPage(
      title: 'Members',
      subtitle: 'Membership state and workout history',
      child: AsyncStateView(
        value: members,
        onRetry: () => ref.invalidate(adminMembersProvider),
        data: (items) => items.isEmpty
            ? const AppEmptyState(
                icon: Icons.people_outline_rounded,
                title: 'No members yet',
                message: 'Members created by a trainer will show up here.',
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 320,
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final member = items[index];
                        return ListTile(
                          selected: member.id == selected?.id,
                          title: Text(member.name),
                          subtitle: Text(
                            member.email.isEmpty
                                ? (member.phone ?? '')
                                : member.email,
                          ),
                          trailing: member.isLapsed
                              ? const Icon(
                                  Icons.lock_clock_rounded,
                                  color: AppColors.gold,
                                  size: 18,
                                )
                              : null,
                          onTap: () => ref
                              .read(adminSelectedMemberProvider.notifier)
                              .select(member),
                        );
                      },
                    ),
                  ),
                  const VerticalDivider(width: 32),
                  Expanded(
                    child: selected == null
                        ? const AppEmptyState(
                            icon: Icons.touch_app_outlined,
                            title: 'Pick a member',
                            message: 'Their history will show here.',
                          )
                        : _MemberDetail(member: selected),
                  ),
                ],
              ),
      ),
    );
  }
}

class _MemberDetail extends ConsumerWidget {
  const _MemberDetail({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(adminMemberHistoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          member.name,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          member.isLapsed
              ? 'Membership lapsed'
              : 'Member since ${_date(member.joinedAt)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: member.isLapsed
                ? AppColors.gold
                : AppColors.secondaryText(context),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () => _setMembership(
                context,
                ref,
                member.isLapsed
                    ? MembershipStatus.active
                    : MembershipStatus.lapsed,
              ),
              icon: Icon(
                member.isLapsed
                    ? Icons.lock_open_rounded
                    : Icons.lock_clock_rounded,
                size: 18,
              ),
              label: Text(
                member.isLapsed ? 'Reactivate' : 'Mark lapsed',
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _promote(context, ref),
              icon: const Icon(Icons.shield_outlined, size: 18),
              label: const Text('Make trainer'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          'Workout history',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: AsyncStateView(
            value: history,
            onRetry: () => ref.invalidate(adminMemberHistoryProvider),
            data: (logs) => logs.isEmpty
                ? const AppEmptyState(
                    icon: Icons.history_rounded,
                    title: 'Nothing logged yet',
                    message: 'Completed exercises will show here.',
                  )
                : ListView.separated(
                    itemCount: logs.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        _HistoryRow(log: logs[index]),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _setMembership(
    BuildContext context,
    WidgetRef ref,
    MembershipStatus status,
  ) async {
    try {
      await ref
          .read(adminRepositoryProvider)
          .setMembership(memberId: member.id, status: status);
      ref.invalidate(adminMembersProvider);
      ref.read(adminSelectedMemberProvider.notifier).select(null);
      if (context.mounted) _say(context, 'Membership updated.');
    } catch (error) {
      if (context.mounted) _say(context, friendlyErrorMessage(error));
    }
  }

  Future<void> _promote(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Make ${member.name} a trainer?'),
        content: const Text(
          'They will get access to member records and plan assignment. '
          'This changes their role claim, so they will be signed out and have '
          'to sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Make trainer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(adminRepositoryProvider)
          .setUserRole(uid: member.id, role: UserRole.trainer);
      ref.invalidate(adminMembersProvider);
      if (context.mounted) _say(context, 'They are now a trainer.');
    } catch (error) {
      if (context.mounted) _say(context, friendlyErrorMessage(error));
    }
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.log});

  final CompletionLog log;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(
        log.skipped ? Icons.redo_rounded : Icons.check_circle_rounded,
        color: log.skipped ? AppColors.gold : AppColors.success,
        size: 20,
      ),
      title: Text(log.exerciseName),
      subtitle: Text(
        log.skipped
            ? 'Skipped — ${log.skipReason ?? 'no reason given'}'
            : '${log.setsDone} of ${log.setsPlanned} sets'
                  '${log.topWeight > 0 ? ' • best ${log.topWeight}kg' : ''}',
      ),
      trailing: Text(
        _date(log.completedAt),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.secondaryText(context),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- library

class AdminLibraryScreen extends ConsumerWidget {
  const AdminLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(exerciseLibraryProvider);

    return AdminPage(
      title: 'Exercise library',
      subtitle: 'What trainers can put in a plan',
      child: AsyncStateView(
        value: exercises,
        onRetry: () => ref.invalidate(exerciseLibraryProvider),
        data: (items) => items.isEmpty
            ? const AppEmptyState(
                icon: Icons.fitness_center_outlined,
                title: 'The library is empty',
                message: 'Import or add exercises to get started.',
              )
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final exercise = items[index];
                  return ListTile(
                    title: Text(exercise.name),
                    subtitle: Text(
                      '${exercise.muscleGroup} • ${exercise.sets} x '
                      '${exercise.reps}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Remove from the library',
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () async {
                        try {
                          await ref
                              .read(adminRepositoryProvider)
                              .deleteExercise(exercise.id);
                          ref.invalidate(exerciseLibraryProvider);
                          if (context.mounted) {
                            _say(context, 'Removed from the library.');
                          }
                        } catch (error) {
                          if (context.mounted) {
                            _say(context, friendlyErrorMessage(error));
                          }
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// ----------------------------------------------------------------- events

class AdminEventsScreen extends ConsumerWidget {
  const AdminEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(adminEventsProvider);

    return AdminPage(
      title: 'Events',
      subtitle: 'What members can RSVP to',
      action: FilledButton.icon(
        onPressed: () => _editEvent(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New event'),
      ),
      child: AsyncStateView(
        value: events,
        onRetry: () => ref.invalidate(adminEventsProvider),
        data: (items) => items.isEmpty
            ? const AppEmptyState(
                icon: Icons.celebration_outlined,
                title: 'No events yet',
                message: 'Create one and members will see it in the app.',
              )
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final event = items[index];
                  return ListTile(
                    title: Text(event.title),
                    subtitle: Text(
                      '${_date(event.startsAt)} • ${event.venue}'
                      '${event.isPast ? ' • past' : ''}',
                    ),
                    onTap: () => _editEvent(context, ref, event: event),
                    trailing: IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () async {
                        try {
                          await ref
                              .read(adminRepositoryProvider)
                              .deleteEvent(event.id);
                          ref.invalidate(adminEventsProvider);
                          if (context.mounted) _say(context, 'Event removed.');
                        } catch (error) {
                          if (context.mounted) {
                            _say(context, friendlyErrorMessage(error));
                          }
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}

Future<void> _editEvent(
  BuildContext context,
  WidgetRef ref, {
  GymEvent? event,
}) async {
  final title = TextEditingController(text: event?.title ?? '');
  final description = TextEditingController(text: event?.description ?? '');
  final venue = TextEditingController(text: event?.venue ?? '');
  final imageUrl = TextEditingController(text: event?.imageUrl ?? '');
  var startsAt = event?.startsAt ?? DateTime.now().add(const Duration(days: 7));

  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(event == null ? 'New event' : 'Edit event'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: venue,
                  decoration: const InputDecoration(labelText: 'Venue'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: imageUrl,
                  decoration: const InputDecoration(
                    labelText: 'Banner image URL (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Starts'),
                  subtitle: Text(_dateTime(startsAt)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: () async {
                    final picked = await _pickDateTime(context, startsAt);
                    if (picked != null) setState(() => startsAt = picked);
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );

  if (saved != true || !context.mounted) return;
  if (title.text.trim().isEmpty) {
    _say(context, 'An event needs a title.');
    return;
  }

  try {
    await ref.read(adminRepositoryProvider).saveEvent(
      GymEvent(
        id: event?.id ?? '',
        title: title.text.trim(),
        description: description.text.trim(),
        startsAt: startsAt,
        venue: venue.text.trim(),
        imageUrl: imageUrl.text.trim().isEmpty ? null : imageUrl.text.trim(),
      ),
      id: event?.id,
    );
    ref.invalidate(adminEventsProvider);
    if (context.mounted) _say(context, 'Event saved.');
  } catch (error) {
    if (context.mounted) _say(context, friendlyErrorMessage(error));
  }
}

// ---------------------------------------------------------------- classes

class AdminClassesScreen extends ConsumerWidget {
  const AdminClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(adminClassesProvider);
    final sessions = ref.watch(adminSessionsProvider);

    return AdminPage(
      title: 'Classes',
      subtitle: 'On-demand videos and scheduled sessions',
      action: FilledButton.icon(
        onPressed: () => _editClass(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New class'),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 340,
            child: AsyncStateView(
              value: classes,
              onRetry: () => ref.invalidate(adminClassesProvider),
              data: (items) => items.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.ondemand_video_outlined,
                      title: 'No classes yet',
                      message: 'Add one to schedule sessions for it.',
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          title: Text(item.title),
                          subtitle: Text(
                            '${item.videoProvider.name} • '
                            '${item.durationMins} min',
                          ),
                          onTap: () =>
                              _editClass(context, ref, groupClass: item),
                          trailing: IconButton(
                            tooltip: 'Schedule a session',
                            icon: const Icon(Icons.event_available_outlined),
                            onPressed: () =>
                                _scheduleSession(context, ref, item),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const VerticalDivider(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scheduled sessions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: AsyncStateView(
                    value: sessions,
                    onRetry: () => ref.invalidate(adminSessionsProvider),
                    data: (items) => items.isEmpty
                        ? const AppEmptyState(
                            icon: Icons.event_busy_rounded,
                            title: 'Nothing scheduled',
                            message:
                                'Use the calendar icon on a class to add a '
                                'time.',
                          )
                        : ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) =>
                                _SessionRow(session: items[index]),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionRow extends ConsumerWidget {
  const _SessionRow({required this.session});

  final ClassSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(adminSessionBookingsProvider(session.id));

    return ExpansionTile(
      title: Text(session.classTitle),
      subtitle: Text(
        '${_dateTime(session.startsAt)} • ${session.instructor} • '
        '${session.bookedCount}/${session.capacity} booked'
        '${session.waitlistCount > 0 ? ' • ${session.waitlistCount} waiting' : ''}',
      ),
      children: [
        AsyncStateView(
          value: bookings,
          onRetry: () =>
              ref.invalidate(adminSessionBookingsProvider(session.id)),
          data: (items) => items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nobody has booked yet.'),
                )
              : Column(
                  children: [
                    for (final booking in items)
                      ListTile(
                        dense: true,
                        leading: Icon(
                          booking.status.holdsAPlace
                              ? Icons.check_circle_rounded
                              : Icons.hourglass_bottom_rounded,
                          size: 18,
                          color: booking.status.holdsAPlace
                              ? AppColors.success
                              : AppColors.gold,
                        ),
                        title: Text(booking.memberName ?? booking.memberId),
                        subtitle: Text(
                          booking.status.holdsAPlace
                              ? 'Booked'
                              : 'Waitlist position ${booking.position}',
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

Future<void> _editClass(
  BuildContext context,
  WidgetRef ref, {
  GroupClass? groupClass,
}) async {
  final title = TextEditingController(text: groupClass?.title ?? '');
  final description = TextEditingController(
    text: groupClass?.description ?? '',
  );
  final videoId = TextEditingController(text: groupClass?.videoId ?? '');
  final thumbnail = TextEditingController(
    text: groupClass?.thumbnailUrl ?? '',
  );
  final duration = TextEditingController(
    text: '${groupClass?.durationMins ?? 30}',
  );
  var provider = groupClass?.videoProvider ?? VideoProvider.youtube;

  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(groupClass == null ? 'New class' : 'Edit class'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<VideoProvider>(
                  initialValue: provider,
                  decoration: const InputDecoration(labelText: 'Video host'),
                  items: [
                    for (final option in VideoProvider.values)
                      DropdownMenuItem(
                        value: option,
                        child: Text(option.name),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => provider = value ?? provider),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: videoId,
                  decoration: const InputDecoration(
                    labelText: 'Video ID',
                    helperText: 'Just the id, not the whole URL',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: thumbnail,
                  decoration: const InputDecoration(
                    labelText: 'Thumbnail URL (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: duration,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );

  if (saved != true || !context.mounted) return;
  if (title.text.trim().isEmpty || videoId.text.trim().isEmpty) {
    _say(context, 'A class needs a title and a video id.');
    return;
  }

  try {
    await ref.read(adminRepositoryProvider).saveClass(
      GroupClass(
        id: groupClass?.id ?? '',
        title: title.text.trim(),
        description: description.text.trim(),
        videoProvider: provider,
        videoId: videoId.text.trim(),
        durationMins: int.tryParse(duration.text.trim()) ?? 30,
        thumbnailUrl: thumbnail.text.trim().isEmpty
            ? null
            : thumbnail.text.trim(),
      ),
      id: groupClass?.id,
    );
    ref.invalidate(adminClassesProvider);
    if (context.mounted) _say(context, 'Class saved.');
  } catch (error) {
    if (context.mounted) _say(context, friendlyErrorMessage(error));
  }
}

Future<void> _scheduleSession(
  BuildContext context,
  WidgetRef ref,
  GroupClass groupClass,
) async {
  final instructor = TextEditingController();
  final capacity = TextEditingController(text: '12');
  var startsAt = DateTime.now().add(const Duration(days: 1));

  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Schedule ${groupClass.title}'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: instructor,
                decoration: const InputDecoration(labelText: 'Instructor'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: capacity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Places'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Starts'),
                subtitle: Text(_dateTime(startsAt)),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: () async {
                  final picked = await _pickDateTime(context, startsAt);
                  if (picked != null) setState(() => startsAt = picked);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Schedule'),
          ),
        ],
      ),
    ),
  );

  if (saved != true || !context.mounted) return;

  try {
    await ref.read(adminRepositoryProvider).createSession(
      groupClass: groupClass,
      instructor: instructor.text.trim(),
      startsAt: startsAt,
      capacity: int.tryParse(capacity.text.trim()) ?? 0,
    );
    ref.invalidate(adminSessionsProvider);
    if (context.mounted) _say(context, 'Class scheduled.');
  } catch (error) {
    if (context.mounted) _say(context, friendlyErrorMessage(error));
  }
}

// ---------------------------------------------------------- announcements

class AdminAnnouncementsScreen extends ConsumerStatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  ConsumerState<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState
    extends ConsumerState<AdminAnnouncementsScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  AnnouncementAudience _audience = AnnouncementAudience.all;
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sent = ref.watch(adminAnnouncementsProvider);

    return AdminPage(
      title: 'Announcements',
      subtitle: 'Push a message and keep it in the app',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 380,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _title,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _body,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Message'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AnnouncementAudience>(
                      initialValue: _audience,
                      decoration: const InputDecoration(labelText: 'Send to'),
                      items: [
                        for (final option in AnnouncementAudience.values)
                          DropdownMenuItem(
                            value: option,
                            child: Text(option.name),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _audience = value ?? _audience),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send_rounded),
                      label: Text(_sending ? 'Sending...' : 'Send'),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Everyone in the chosen group gets a push, and it is '
                      'kept in their notifications list.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryText(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Already sent',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: AsyncStateView(
                    value: sent,
                    onRetry: () => ref.invalidate(adminAnnouncementsProvider),
                    data: (items) => items.isEmpty
                        ? const AppEmptyState(
                            icon: Icons.campaign_outlined,
                            title: 'Nothing sent yet',
                            message: 'Announcements you send appear here.',
                          )
                        : ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return ListTile(
                                title: Text(item.title),
                                subtitle: Text(item.body),
                                trailing: Text(
                                  '${item.audience.name}\n'
                                  '${_date(item.sentAt)}',
                                  textAlign: TextAlign.right,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.secondaryText(
                                          context,
                                        ),
                                      ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      await ref.read(adminRepositoryProvider).sendAnnouncement(
        title: _title.text,
        body: _body.text,
        audience: _audience,
      );
      _title.clear();
      _body.clear();
      ref.invalidate(adminAnnouncementsProvider);
      if (mounted) _say(context, 'Sent.');
    } catch (error) {
      if (mounted) _say(context, friendlyErrorMessage(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

// ---------------------------------------------------------------- helpers

Future<DateTime?> _pickDateTime(BuildContext context, DateTime initial) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime.now().subtract(const Duration(days: 1)),
    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
  );
  if (date == null || !context.mounted) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null) return null;

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

void _say(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _date(DateTime when) =>
    '${when.day} ${_months[when.month - 1]} ${when.year}';

String _dateTime(DateTime when) {
  final hour = when.hour % 12 == 0 ? 12 : when.hour % 12;
  final minute = when.minute.toString().padLeft(2, '0');
  final suffix = when.hour >= 12 ? 'pm' : 'am';
  return '${_date(when)}, $hour:$minute$suffix';
}
