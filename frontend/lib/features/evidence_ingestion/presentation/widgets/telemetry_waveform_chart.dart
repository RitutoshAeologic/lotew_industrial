import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class TelemetryWaveformChart extends StatelessWidget {
  final int cycleId;
  final bool isSevereLeak;

  const TelemetryWaveformChart({
    super.key,
    required this.cycleId,
    this.isSevereLeak = false,
  });

  @override
  Widget build(BuildContext context) {
    // Generate 60-second operational curve data points (1 sec interval for visualization)
    final pressureBase = isSevereLeak ? 110.0 : 151.0;
    final flowBase = isSevereLeak ? 2.1 : 6.2;

    final pressureSpots = List.generate(60, (i) {
      // Hydraulic cycle dynamic: Extension (0-15s), High Pressure Hold (15-35s), Retraction (35-45s), Rest (45-60s)
      double factor;
      if (i < 15) {
        factor = 0.85 + (i / 15) * 0.15;
      } else if (i < 35) {
        factor = 1.0;
      } else if (i < 45) {
        factor = 0.90;
      } else {
        factor = 0.75;
      }
      return FlSpot(i.toDouble(), pressureBase * factor);
    });

    final flowSpots = List.generate(60, (i) {
      double factor = (i >= 15 && i <= 45) ? 1.0 : 0.4;
      return FlSpot(i.toDouble(), flowBase * factor * 20); // Scaled for chart visual parity
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.show_chart_rounded, size: 20, color: AppColors.primary),
                    SizedBox(width: AppSpacing.sm),
                    Text('60-Second Cycle Telemetry Waveform Profile', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ChartLegend(color: AppColors.sensorPressure, label: 'PS1 Pressure (100 Hz, bar)'),
                    SizedBox(width: AppSpacing.md),
                    _ChartLegend(color: AppColors.sensorFlow, label: 'FS1 Flow (10 Hz, scaled L/min)'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 30,
                    verticalInterval: 10,
                    getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.borderLight, strokeWidth: 1),
                    getDrawingVerticalLine: (value) => const FlLine(color: AppColors.borderLight, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Text('Time within Cycle (0 to 60 Seconds)', style: AppTextStyles.bodySmall),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 10,
                        getTitlesWidget: (val, meta) => Text('${val.toInt()}s', style: AppTextStyles.monoSmall.copyWith(fontSize: 10)),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        interval: 40,
                        getTitlesWidget: (val, meta) => Text('${val.toInt()}', style: AppTextStyles.monoSmall.copyWith(fontSize: 10)),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  minX: 0,
                  maxX: 60,
                  minY: 0,
                  maxY: 180,
                  lineBarsData: [
                    LineChartBarData(
                      spots: pressureSpots,
                      isCurved: true,
                      color: AppColors.sensorPressure,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.sensorPressure.withValues(alpha: 0.08),
                      ),
                    ),
                    LineChartBarData(
                      spots: flowSpots,
                      isCurved: true,
                      color: AppColors.sensorFlow,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
