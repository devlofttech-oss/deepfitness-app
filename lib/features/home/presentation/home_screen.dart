import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/models/member.dart';
import 'package:deepfitness/features/auth/application/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The member's home.
///
/// Module 01 only: it confirms who is signed in and the state of their
/// membership. The assigned plan, reports, events and classes land here as
/// modules 02 to 05 are built.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).value;
    final member = session?.member;

    return Scaffold(
      backgroundColor: AppColors.canvas(context),
      appBar: AppBar(
        title: const Text('Deep Fitness'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${member?.name ?? 'there'}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              if (member != null) _MembershipLine(member: member),
            ],
          ),
        ),
      ),
    );
  }
}

class _MembershipLine extends StatelessWidget {
  const _MembershipLine({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    // A lapsed membership is a state, not a sign-out: the member stays in
    // the app and keeps read access to their own history.
    final lapsed = member.isLapsed;
    final expiry = member.expiryDate;

    return Text(
      lapsed
          ? 'Your membership has lapsed. Speak to the gym to renew.'
          : expiry == null
          ? 'Membership active.'
          : 'Membership active until ${expiry.day}/${expiry.month}/${expiry.year}.',
      style: TextStyle(
        color: lapsed ? AppColors.danger : AppColors.secondaryText(context),
      ),
    );
  }
}
