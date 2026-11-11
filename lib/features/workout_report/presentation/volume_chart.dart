import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/features/workout_report/domain/workout_report.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Sets completed per day.
///
/// One series, so there is no legend: the heading names it. Skips are not
/// a second series here — a second hue on the same axis would invite the
/// reader to compare two different things. They are in the tiles above.
class VolumeChart extends StatelessWidget {
  const VolumeChart({super.key, required this.report});

  final WorkoutReport report;

  @override
  Widget build(BuildContext context) {
    final days = report.daily;
    final peak = days.fold<int>(0, (max, day) => day.sets > max ? day.sets : max);

    // A flat zero would otherwise draw a chart with no vertical extent.
    final maxY = (peak == 0 ? 1 : peak) * 1.2;

    // With a month on screen there is no room for a label under every
    // bar, so they thin out rather than overlap.
    final labelEvery = (days.length / 7).ceil();

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceBetween,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.surfaceContainerHigh,
              getTooltipItem: (group, _, rod, _) {
                final day = days[group.x];
                return BarTooltipItem(
                  '${rod.toY.toInt()} sets\n',
                  const TextStyle(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  children: [
                    TextSpan(
                      text: '${day.day.day}/${day.day.month}'
                          '${day.skipped > 0 ? ' · ${day.skipped} skipped' : ''}',
                      style: const TextStyle(color: AppColors.outline),
                    ),
                  ],
                );
              },
            ),
          ),
          // Recessive: horizontal guides only, no vertical rules, no box.
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.surfaceContainerHigh, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 28),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= days.length) {
                    return const SizedBox.shrink();
                  }
                  if (index % labelEvery != 0) return const SizedBox.shrink();
                  final day = days[index].day;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${day.day}/${day.month}',
                      style: const TextStyle(
                        color: AppColors.outline,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < days.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: days[i].sets.toDouble(),
                    width: days.length > 14 ? 6 : 12,
                    // Rounded at the data end, square on the baseline.
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                    color: days[i].sets > 0
                        ? AppColors.primaryContainer
                        : AppColors.surfaceContainerHigh,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
