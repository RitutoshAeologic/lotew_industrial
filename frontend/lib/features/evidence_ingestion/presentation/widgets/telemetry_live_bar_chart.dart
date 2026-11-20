import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Real-time Bar Chart visualizing progressive ingestion across all 2,205 cycles.
/// Groups the 2,205 cycles into 45 dense bins (50 cycles each) with color-coded
/// health status (Green: Nominal, Amber: Degraded Leak, Cyan: Active Batch).
class TelemetryLiveBarChart extends StatelessWidget {
  final Map<int, String> cycleQualityMap;
  final int currentCycle;
  final int totalCycles;
  final bool isStreaming;
  final int throughput;

  const TelemetryLiveBarChart({
    super.key,
    required this.cycleQualityMap,
    required this.currentCycle,
    this.totalCycles = 2205,
    this.isStreaming = false,
    this.throughput = 0,
  });

  @override
  Widget build(BuildContext context) {
    const int binSize = 50;
    final int binCount = (totalCycles / binSize).ceil(); // 45 bins

    int nominalCount = 0;
    int degradedCount = 0;
    cycleQualityMap.forEach((_, flag) {
      if (flag == 'NOMINAL') {
        nominalCount++;
      } else {
        degradedCount++;
      }
    });

    final int ingestedTotal = cycleQualityMap.length;
    final double progressPct = totalCycles > 0 ? (ingestedTotal / totalCycles * 100).clamp(0.0, 100.0) : 0.0;

    // Build 45 bar groups
    final List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < binCount; i++) {
      final int binStart = i * binSize + 1;
      final int binEnd = (i + 1) * binSize > totalCycles ? totalCycles : (i + 1) * binSize;

      int ingestedInBin = 0;
      bool hasLeak = false;

      for (int c = binStart; c <= binEnd; c++) {
        if (cycleQualityMap.containsKey(c)) {
          ingestedInBin++;
          if (cycleQualityMap[c] != 'NOMINAL') {
            hasLeak = true;
          }
        }
      }

      final bool isCurrentBin = isStreaming && currentCycle >= binStart && currentCycle <= binEnd;

      Color barColor;
      if (isCurrentBin) {
        barColor = AppColors.primary; // Cyan active
      } else if (ingestedInBin == 0) {
        barColor = AppColors.slate300.withValues(alpha: 0.3); // Pending
      } else if (hasLeak) {
        barColor = AppColors.warning; // Amber leak detected
      } else {
        barColor = AppColors.success; // Emerald healthy
      }

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: ingestedInBin.toDouble(),
              color: barColor,
              width: 10,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: binSize.toDouble(),
                color: AppColors.borderLight,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header KPI Strip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isStreaming ? Icons.bolt_rounded : Icons.bar_chart_rounded,
                    size: 20,
                    color: isStreaming ? AppColors.primary : AppColors.slate800,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    isStreaming ? 'Live Rig Ingestion Spectrum' : '2,205-Cycle Ingestion Spectrum',
                    style: AppTextStyles.labelCaps.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  _MetricBadge(label: 'Nominal', count: nominalCount, color: AppColors.success),
                  const SizedBox(width: AppSpacing.xs),
                  _MetricBadge(label: 'Degraded', count: degradedCount, color: AppColors.warning),
                  if (throughput > 0) ...[
                    const SizedBox(width: AppSpacing.xs),
                    _MetricBadge(label: 'Rate', text: '$throughput cyc/s', color: AppColors.primary),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Progress text & mini progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressPct / 100.0,
                    backgroundColor: AppColors.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      degradedCount > 0 ? AppColors.warning : AppColors.primary,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$ingestedTotal / $totalCycles (${progressPct.toStringAsFixed(1)}%)',
                style: AppTextStyles.monoSmall.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // The Bar Chart
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: binSize.toDouble(),
                barGroups: barGroups,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx == 0) return const Text('1', style: TextStyle(fontSize: 10, color: AppColors.slate500));
                        if (idx == 10) return const Text('500', style: TextStyle(fontSize: 10, color: AppColors.slate500));
                        if (idx == 20) return const Text('1k', style: TextStyle(fontSize: 10, color: AppColors.slate500));
                        if (idx == 30) return const Text('1.5k', style: TextStyle(fontSize: 10, color: AppColors.slate500));
                        if (idx == 44) return const Text('2,205', style: TextStyle(fontSize: 10, color: AppColors.slate500));
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final binStart = groupIndex * binSize + 1;
                      final binEnd = (groupIndex + 1) * binSize > totalCycles ? totalCycles : (groupIndex + 1) * binSize;
                      final count = rod.toY.toInt();
                      return BarTooltipItem(
                        'Cycles $binStart–$binEnd\n$count / $binSize Ingested',
                        const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final String label;
  final int? count;
  final String? text;
  final Color color;

  const _MetricBadge({
    required this.label,
    this.count,
    this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text != null ? '$label: $text' : '$label: ${count ?? 0}',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
