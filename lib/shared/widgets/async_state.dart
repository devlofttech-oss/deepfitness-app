import 'package:deepfitness/core/theme/app_colors.dart';
import 'package:deepfitness/shared/widgets/premium_card.dart';
import 'package:deepfitness/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncStateView<T> extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.value,
    required this.data,
    required this.onRetry,
    this.loading,
    this.errorTitle = 'Could not load this screen',
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback onRetry;
  final Widget? loading;
  final String errorTitle;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => loading ?? const AppLoadingState(),
      error: (error, _) => AppErrorState(
        title: errorTitle,
        message: friendlyErrorMessage(error),
        onRetry: onRetry,
      ),
      data: data,
    );
  }
}

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key, this.rows = 3});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < rows; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PremiumCard(
              child: Row(
                children: [
                  const SkeletonBox(width: 48, height: 48, radius: 14),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonBox(width: double.infinity, height: 14),
                        SizedBox(height: 10),
                        SkeletonBox(width: 150, height: 12),
                      ],
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

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.chipBackground(context),
            child: const Icon(Icons.cloud_off_rounded, color: AppColors.gold),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.secondaryText(context),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            outline: true,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.chipBackground(context),
            child: Icon(icon, color: AppColors.gold),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.secondaryText(context),
            ),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.divider(context).withValues(alpha: .7),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

String friendlyErrorMessage(Object error) {
  final raw = error.toString().replaceFirst('Bad state: ', '');
  final lower = raw.toLowerCase();
  final looksOffline =
      lower.contains('socket') ||
      lower.contains('network') ||
      lower.contains('connection') ||
      lower.contains('failed host') ||
      lower.contains('timed out') ||
      lower.contains('clientexception') ||
      lower.contains('xmlhttprequest');

  if (looksOffline) {
    return 'Check your internet connection and try again. Your screen is safe; we just could not reach the server.';
  }

  if (raw.contains('Supabase is not configured')) {
    return 'Supabase is not configured for this build. Add the project URL and anon key, then retry.';
  }

  return raw.isEmpty ? 'Something went wrong. Please try again.' : raw;
}
