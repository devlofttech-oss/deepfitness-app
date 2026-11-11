import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/widgets/df_card.dart';
import 'package:deepfitness/features/workout_report/domain/report_range.dart';
import 'package:deepfitness/features/workout_report/domain/workout_report.dart';
import 'package:deepfitness/features/workout_report/presentation/report_controller.dart';
import 'package:deepfitness/features/workout_report/presentation/share_summary.dart';
import 'package:deepfitness/features/workout_report/presentation/volume_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Workout reports over a window the member chooses.
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _summaryKey = GlobalKey();

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    ref.read(reportRangeProvider.notifier).select(
      ReportRange.custom(from: picked.start, to: picked.end),
    );
  }

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(reportRangeProvider);
    final report = ref.watch(workoutReportProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('YOUR PROGRESS'),
        actions: [
          if (report.hasValue && !report.requireValue.isEmpty)
            IconButton(
              icon: const Icon(Icons.ios_share),
              tooltip: 'Share summary',
              onPressed: () => shareSummary(
                boundaryKey: _summaryKey,
                text: 'My Deep Fitness progress, ${range.label.toLowerCase()}.',
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _RangeSelector(
              range: range,
              onWeek: () => ref
                  .read(reportRangeProvider.notifier)
                  .select(ReportRange.week()),
              onMonth: () => ref
                  .read(reportRangeProvider.notifier)
                  .select(ReportRange.month()),
              onCustom: _pickCustomRange,
            ),
            const SizedBox(height: 20),
            report.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const DfMessage(
                icon: Icons.wifi_off,
                title: 'Could not load your progress',
                body: 'Check your connection and try again.',
              ),
              data: (data) => data.isEmpty
                  ? const DfMessage(
                      icon: Icons.insights,
                      title: 'Nothing logged in this period',
                      body: 'Finish an exercise and it will show up here.',
                    )
                  : RepaintBoundary(
                      key: _summaryKey,
                      child: ReportSummary(report: data),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The body of the report, and the part that becomes the shared image.
class ReportSummary extends StatelessWidget {
  const ReportSummary({super.key, required this.report});

  final WorkoutReport report;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Completed',
                  value: '${(report.completionRate * 100).round()}%',
                  caption: '${report.completed} of ${report.totalLogged}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Sets',
                  value: '${report.totalSets}',
                  caption: 'over ${report.activeDays} days',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Streak',
                  value: '${report.currentStreak}',
                  caption: 'best ${report.longestStreak}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'SETS COMPLETED PER DAY',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            report.range.label,
            style: TextStyle(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          VolumeChart(report: report),
          if (report.skipped > 0) ...[
            const SizedBox(height: 16),
            Text(
              '${report.skipped} exercise${report.skipped == 1 ? '' : 's'} '
              'skipped in this period.',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.range,
    required this.onWeek,
    required this.onMonth,
    required this.onCustom,
  });

  final ReportRange range;
  final VoidCallback onWeek;
  final VoidCallback onMonth;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    // Filters sit in one row above the chart, as the system asks.
    return Row(
      children: [
        DfChip(
          label: 'Week',
          selected: range.kind == ReportRangeKind.week,
          onTap: onWeek,
        ),
        const SizedBox(width: Insets.sm),
        DfChip(
          label: 'Month',
          selected: range.kind == ReportRangeKind.month,
          onTap: onMonth,
        ),
        const SizedBox(width: Insets.sm),
        DfChip(
          label: 'Custom',
          icon: Icons.calendar_month,
          selected: range.kind == ReportRangeKind.custom,
          onTap: onCustom,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return DfCard(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.sm,
        vertical: Insets.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DfLabel(label),
          const SizedBox(height: Insets.sm),
          Text(value, style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 2),
          Text(
            caption,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.outline),
          ),
        ],
      ),
    );
  }
}
