import 'package:deepfitness/admin/application/admin_controllers.dart';
import 'package:deepfitness/admin/presentation/admin_shell.dart';
import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/models/member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The member roll, with each member's workout history behind it.
class AdminMembersScreen extends ConsumerStatefulWidget {
  const AdminMembersScreen({super.key});

  @override
  ConsumerState<AdminMembersScreen> createState() =>
      _AdminMembersScreenState();
}

class _AdminMembersScreenState extends ConsumerState<AdminMembersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(adminMembersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AdminHeader(title: 'Members'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Search by name or phone',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _query = value.toLowerCase()),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: members.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('$error')),
            data: (list) {
              // Filtered on what is already loaded rather than re-querying:
              // Firestore has no substring search, and the roll is a page
              // at a time anyway.
              final filtered = _query.isEmpty
                  ? list
                  : list
                        .where(
                          (member) =>
                              member.name.toLowerCase().contains(_query) ||
                              (member.phone ?? '').contains(_query),
                        )
                        .toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('No members match that.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) =>
                    _MemberRow(member: filtered[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MemberRow extends ConsumerWidget {
  const _MemberRow({required this.member});

  final Member member;

  Future<void> _editMembership(BuildContext context, WidgetRef ref) async {
    final expiry = await showDatePicker(
      context: context,
      initialDate: member.expiryDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Membership runs until',
    );
    if (expiry == null) return;

    final saved = await ref
        .read(adminActionProvider.notifier)
        .run(
          (repository) => repository.setMembership(
            memberId: member.id,
            status: MembershipStatus.active,
            expiryDate: expiry,
          ),
          refresh: [adminMembersProvider],
        );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved ? 'Membership updated.' : 'Could not update it.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.surface(context),
        backgroundImage: member.photoUrl == null
            ? null
            : NetworkImage(member.photoUrl!),
        child: member.photoUrl == null
            ? Text(member.name.isEmpty ? '?' : member.name[0].toUpperCase())
            : null,
      ),
      title: Text(member.name.isEmpty ? 'Unnamed member' : member.name),
      subtitle: Text(
        [
          if (member.phone != null) member.phone!,
          member.isLapsed ? 'Lapsed' : 'Active',
        ].join(' · '),
        style: TextStyle(
          color: member.isLapsed ? AppColors.danger : null,
        ),
      ),
      trailing: TextButton(
        onPressed: () => _editMembership(context, ref),
        child: const Text('Membership'),
      ),
      children: [_MemberHistory(memberId: member.id)],
    );
  }
}

/// Loaded only when a member is expanded, so opening the roll does not
/// pull every member's whole history.
class _MemberHistory extends ConsumerWidget {
  const _MemberHistory({required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(memberHistoryProvider(memberId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(72, 0, 32, 16),
      child: history.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => const Text('Could not load the history.'),
        data: (logs) => logs.isEmpty
            ? const Text('Nothing logged yet.')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in logs.take(20))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${_date(entry.completedAt)} · '
                        '${entry.exerciseName} · '
                        '${entry.skipped ? 'skipped${entry.skipReason == null ? '' : ' (${entry.skipReason})'}' : '${entry.setsDone} sets'}',
                        style: TextStyle(
                          color: entry.skipped
                              ? AppColors.secondaryText(context)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  static String _date(DateTime? value) => value == null
      ? '—'
      : '${value.day}/${value.month}/${value.year}';
}
