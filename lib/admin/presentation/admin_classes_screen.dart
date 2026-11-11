import 'package:deepfitness/admin/application/admin_controllers.dart';
import 'package:deepfitness/admin/data/admin_repository.dart';
import 'package:deepfitness/admin/presentation/admin_shell.dart';
import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/models/class_session.dart';
import 'package:deepfitness/core/models/group_class.dart';
import 'package:deepfitness/features/group_classes/presentation/classes_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bookings on one session, for the admin view.
final sessionBookingsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
      (ref, sessionId) async =>
          (await ref.watch(adminRepositoryProvider).sessionBookings(sessionId))
              .items,
    );

/// Classes, their sessions, and who is booked on each.
class AdminClassesScreen extends ConsumerStatefulWidget {
  const AdminClassesScreen({super.key});

  @override
  ConsumerState<AdminClassesScreen> createState() =>
      _AdminClassesScreenState();
}

class _AdminClassesScreenState extends ConsumerState<AdminClassesScreen> {
  String? _selectedClassId;

  Future<void> _addSession(GroupClass groupClass) async {
    final draft = await showDialog<({DateTime startsAt, String instructor, int capacity})>(
      context: context,
      builder: (context) => const _SessionDialog(),
    );
    if (draft == null) return;

    final saved = await ref
        .read(adminActionProvider.notifier)
        .run(
          (repository) => repository.saveClassSession(
            classId: groupClass.id,
            instructor: draft.instructor,
            startsAt: draft.startsAt,
            capacity: draft.capacity,
            authorId: ref.read(adminAuthorIdProvider),
          ),
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved ? 'Session added.' : 'Could not add that session.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(classesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AdminHeader(title: 'Classes'),
        Expanded(
          child: classes.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('$error')),
            data: (list) => list.isEmpty
                ? const Center(child: Text('No classes yet.'))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 280,
                        child: ListView(
                          padding: const EdgeInsets.only(left: 32),
                          children: [
                            for (final groupClass in list)
                              ListTile(
                                selected: _selectedClassId == groupClass.id,
                                title: Text(groupClass.title),
                                subtitle: Text(
                                  '${groupClass.durationMins} min',
                                ),
                                onTap: () => setState(
                                  () => _selectedClassId = groupClass.id,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const VerticalDivider(),
                      Expanded(
                        child: _selectedClassId == null
                            ? const Center(
                                child: Text('Pick a class to see its sessions.'),
                              )
                            : _SessionsPanel(
                                groupClass: list.firstWhere(
                                  (item) => item.id == _selectedClassId,
                                ),
                                onAddSession: _addSession,
                              ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _SessionsPanel extends ConsumerWidget {
  const _SessionsPanel({required this.groupClass, required this.onAddSession});

  final GroupClass groupClass;
  final ValueChanged<GroupClass> onAddSession;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(classSessionsProvider(groupClass.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 32, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  groupClass.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              FilledButton.icon(
                onPressed: () => onAddSession(groupClass),
                icon: const Icon(Icons.add),
                label: const Text('New session'),
              ),
            ],
          ),
        ),
        Expanded(
          child: sessions.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Center(child: Text('Could not load these.')),
            data: (list) => list.isEmpty
                ? const Center(child: Text('Nothing scheduled.'))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 32, 16),
                    children: [
                      for (final session in list)
                        _SessionTile(session: session),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _SessionTile extends ConsumerWidget {
  const _SessionTile({required this.session});

  final ClassSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final starts = session.startsAt;
    final bookings = ref.watch(sessionBookingsProvider(session.id));

    return ExpansionTile(
      title: Text(
        starts == null
            ? 'Time to be confirmed'
            : '${starts.day}/${starts.month} at '
                  '${starts.hour.toString().padLeft(2, '0')}:'
                  '${starts.minute.toString().padLeft(2, '0')}',
      ),
      subtitle: Text(
        '${session.bookedCount}/${session.capacity} booked'
        '${session.waitlistCount > 0 ? ' · ${session.waitlistCount} waiting' : ''}'
        '${session.instructor.isEmpty ? '' : ' · ${session.instructor}'}',
        style: TextStyle(
          color: session.isFull ? AppColors.gold : null,
        ),
      ),
      children: [
        bookings.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const Text('Could not load the bookings.'),
          data: (list) => list.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nobody booked yet.'),
                )
              : Column(
                  children: [
                    for (final booking in list)
                      ListTile(
                        dense: true,
                        leading: Icon(
                          booking['status'] == 'waitlisted'
                              ? Icons.hourglass_empty
                              : Icons.check_circle_outline,
                          size: 18,
                        ),
                        title: Text('${booking['memberId']}'),
                        subtitle: Text(
                          booking['status'] == 'waitlisted'
                              ? 'Waitlisted, number ${booking['position']}'
                              : 'Booked',
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _SessionDialog extends StatefulWidget {
  const _SessionDialog();

  @override
  State<_SessionDialog> createState() => _SessionDialogState();
}

class _SessionDialogState extends State<_SessionDialog> {
  final _instructor = TextEditingController();
  final _capacity = TextEditingController(text: '12');
  DateTime? _startsAt;

  @override
  void dispose() {
    _instructor.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (!mounted) return;

    setState(() {
      _startsAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 0,
        time?.minute ?? 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final starts = _startsAt;

    return AlertDialog(
      title: const Text('New session'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _instructor,
              decoration: const InputDecoration(labelText: 'Instructor'),
            ),
            TextField(
              controller: _capacity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Capacity'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                starts == null
                    ? 'No time set'
                    : '${starts.day}/${starts.month} at '
                          '${starts.hour.toString().padLeft(2, '0')}:'
                          '${starts.minute.toString().padLeft(2, '0')}',
              ),
              trailing: TextButton(
                onPressed: _pickDateTime,
                child: const Text('Pick time'),
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
            final capacity = int.tryParse(_capacity.text) ?? 0;
            // A session with no capacity would waitlist everyone who
            // tapped Book, so it is refused here rather than confusing
            // members later.
            if (_startsAt == null || capacity <= 0) return;
            Navigator.of(context).pop((
              startsAt: _startsAt!,
              instructor: _instructor.text.trim(),
              capacity: capacity,
            ));
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
