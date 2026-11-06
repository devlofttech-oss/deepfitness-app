import 'package:deepfitness/app/colors.dart';
import 'package:deepfitness/core/models/app_models.dart';
import 'package:deepfitness/core/widgets/premium_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Exercises completed per day over the selected range.
///
/// Drawn on the device from the completion log — the guide is explicit that
/// reports are derived in Dart, with no server round trip and nothing stored.
class ActivityChart extends StatelessWidget {
  const ActivityChart({super.key, required this.days});

  final List<DayCount> days;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }

    final busiest = days.fold<int>(
      0,
      (best, day) => day.count > best ? day.count : best,
    );
    // An all-zero range would otherwise divide by zero and draw nothing.
    final maxY = (busiest == 0 ? 1 : busiest).toDouble();
    final total = days.fold<int>(0, (sum, day) => sum + day.count);

    return PremiumCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$total exercise${total == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryText(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceBetween,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, _) {
                      final day = days[group.x];
                      return BarTooltipItem(
                        '${_shortDate(day.day)}\n${day.count} done',
                        TextStyle(
                          color: AppColors.text(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY <= 4 ? 1 : (maxY / 4).ceilToDouble(),
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.divider(context).withValues(alpha: .5),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: maxY <= 4 ? 1 : (maxY / 4).ceilToDouble(),
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondaryText(context),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= days.length) {
                          return const SizedBox.shrink();
                        }
                        // Labelling every bar is unreadable past a week, so
                        // only a handful are drawn.
                        final step = (days.length / 5).ceil();
                        if (index % step != 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _shortDate(days[index].day),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.secondaryText(context),
                                  fontSize: 10,
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
                          toY: days[i].count.toDouble(),
                          width: days.length > 14 ? 6 : 12,
                          borderRadius: BorderRadius.circular(4),
                          color: days[i].count == 0
                              ? AppColors.divider(context)
                              : AppColors.goldBright,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _shortDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

/// Week / month / custom, as the reports module calls for.
class RangePresets extends StatelessWidget {
  const RangePresets({
    super.key,
    required this.isCustom,
    required this.onWeek,
    required this.onMonth,
    required this.onCustom,
    required this.customLabel,
  });

  final bool isCustom;
  final VoidCallback onWeek;
  final VoidCallback onMonth;
  final VoidCallback onCustom;
  final String customLabel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Week'),
          selected: false,
          onSelected: (_) => onWeek(),
        ),
        ChoiceChip(
          label: const Text('Month'),
          selected: !isCustom,
          onSelected: (_) => onMonth(),
        ),
        ChoiceChip(
          avatar: const Icon(Icons.calendar_month_rounded, size: 16),
          label: Text(isCustom ? customLabel : 'Custom'),
          selected: isCustom,
          onSelected: (_) => onCustom(),
        ),
      ],
    );
  }
}
