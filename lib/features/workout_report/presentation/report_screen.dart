import 'package:deepfitness/app/colors.dart';
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
    ref.read(reportRangeProvider.notifier).state = ReportRange.custom(
      from: picked.start,
      to: picked.end,
    );
  }

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(reportRangeProvider);
    final report = ref.watch(workoutReportProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas(context),
      appBar: AppBar(
        title: const Text('Your progress'),
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
              onWeek: () => ref.read(reportRangeProvider.notifier).state =
                  ReportRange.week(),
              onMonth: () => ref.read(reportRangeProvider.notifier).state =
                  ReportRange.month(),
              onCustom: _pickCustomRange,
            ),
            const SizedBox(height: 20),
            report.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const _ReportMessage(
                'Could not load your progress. Check your connection.',
              ),
              data: (data) => data.isEmpty
                  ? const _ReportMessage(
                      'Nothing logged in this period yet. '
                      'Finish an exercise and it will show up here.',
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
      color: AppColors.canvas(context),
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
            'Sets completed per day',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            report.range.label,
            style: TextStyle(color: AppColors.secondaryText(context)),
          ),
          const SizedBox(height: 16),
          VolumeChart(report: report),
          if (report.skipped > 0) ...[
            const SizedBox(height: 16),
            Text(
              '${report.skipped} exercise${report.skipped == 1 ? '' : 's'} '
              'skipped in this period.',
              style: TextStyle(color: AppColors.secondaryText(context)),
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
    return Row(
      children: [
        _RangeChip(
          label: 'Week',
          selected: range.kind == ReportRangeKind.week,
          onTap: onWeek,
        ),
        const SizedBox(width: 8),
        _RangeChip(
          label: 'Month',
          selected: range.kind == ReportRangeKind.month,
          onTap: onMonth,
        ),
        const SizedBox(width: 8),
        _RangeChip(
          label: 'Custom',
          selected: range.kind == ReportRangeKind.custom,
          onTap: onCustom,
        ),
      ],
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.gold : AppColors.surface(context),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.black : AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.secondaryText(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text(
            caption,
            style: TextStyle(
              color: AppColors.secondaryText(context),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportMessage extends StatelessWidget {
  const _ReportMessage(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.secondaryText(context)),
      ),
    );
  }
}
