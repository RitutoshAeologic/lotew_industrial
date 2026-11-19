import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/models/evidence_item_model.dart';

class TelemetryWaveformChart extends StatelessWidget {
  final int cycleId;
  final bool isSevereLeak;
  final EvidenceItemModel? evidence;

  const TelemetryWaveformChart({
    super.key,
    required this.cycleId,
    this.isSevereLeak = false,
    this.evidence,
  });

  @override
  Widget build(BuildContext context) {
    // Extract real downsampled points from canonical observation if available
    List<FlSpot> pressureSpots = [];
    List<FlSpot> flowSpots = [];
    double medianPressure = isSevereLeak ? 110.4 : 156.25;
    double medianFlow = isSevereLeak ? 2.15 : 7.84;

    final measurements = evidence?.canonicalData['measurements'] as Map<String, dynamic>?;
    final waveform = measurements?['waveform_downsampled_60s'] as Map<String, dynamic>?;

    if (waveform != null &&
        waveform['PS1_pressure_bar'] is List &&
        waveform['FS1_flow_lmin'] is List) {
      final ps1List = waveform['PS1_pressure_bar'] as List;
      final fs1List = waveform['FS1_flow_lmin'] as List;

      pressureSpots = ps1List.asMap().entries.map((e) {
        final val = (e.value as num).toDouble();
        return FlSpot(e.key.toDouble(), val);
      }).toList();

      flowSpots = fs1List.asMap().entries.map((e) {
        final val = (e.value as num).toDouble();
        return FlSpot(e.key.toDouble(), val * 12); // Scaled for chart parity
      }).toList();

      // Retrieve actual medians if available
      final pump = (measurements?['components'] as Map<String, dynamic>?)?['pump'] as Map<String, dynamic>?;
      if (pump != null) {
        final ps1 = pump['PS1'] as Map<String, dynamic>?;
        final fs1 = pump['FS1'] as Map<String, dynamic>?;
        if (ps1 != null && ps1['median'] != null) {
          medianPressure = (ps1['median'] as num).toDouble();
        }
        if (fs1 != null && fs1['median'] != null) {
          medianFlow = (fs1['median'] as num).toDouble();
        }
      }
    } else {
      // Physical realistic simulation fallback
      final baseP = isSevereLeak ? 110.4 : 156.25;
      final baseF = isSevereLeak ? 2.15 : 7.84;

      pressureSpots = List.generate(60, (i) {
        double factor;
        if (i < 15) {
          factor = 0.88 + (i / 15) * 0.12;
        } else if (i < 35) {
          factor = 1.0;
        } else if (i < 45) {
          factor = 0.90;
        } else {
          factor = 0.78;
        }
        return FlSpot(i.toDouble(), baseP * factor);
      });

      flowSpots = List.generate(60, (i) {
        double factor = (i >= 15 && i <= 45) ? 1.0 : 0.35;
        return FlSpot(i.toDouble(), baseF * factor * 12);
      });
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chart Header with Live Metrics
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.show_chart_rounded, size: 20, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text('60-Second Multi-Rate Operational Waveform (Cycle #$cycleId)', style: AppTextStyles.headingSmall),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MetricChip(
                      label: 'PS1 Median',
                      value: '${medianPressure.toStringAsFixed(1)} bar',
                      color: AppColors.sensorPressure,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _MetricChip(
                      label: 'FS1 Median',
                      value: '${medianFlow.toStringAsFixed(1)} L/min',
                      color: AppColors.sensorFlow,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),

            // Waveform Legend
            const Row(
              children: [
                _ChartLegend(color: AppColors.sensorPressure, label: 'PS1 Pressure (100 Hz, bar)'),
                SizedBox(width: AppSpacing.lg),
                _ChartLegend(color: AppColors.sensorFlow, label: 'FS1 Flow (10 Hz, scaled L/min)'),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // FL Chart
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
                      axisNameWidget: Text('Time elapsed within 60s cycle (seconds)', style: AppTextStyles.bodySmall),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 10,
                        getTitlesWidget: (val, meta) => Text('${val.toInt()}s', style: AppTextStyles.monoSmall.copyWith(fontSize: 10)),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: Text('Sensor Amplitude', style: AppTextStyles.bodySmall),
                      sideTitles: const SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        interval: 40,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  minX: 0,
                  maxX: 59,
                  minY: 0,
                  maxY: 200,
                  lineBarsData: [
                    LineChartBarData(
                      spots: pressureSpots,
                      isCurved: true,
                      curveSmoothness: 0.2,
                      color: AppColors.sensorPressure,
                      barWidth: 2.2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.sensorPressure.withValues(alpha: 0.10),
                      ),
                    ),
                    LineChartBarData(
                      spots: flowSpots,
                      isCurved: true,
                      curveSmoothness: 0.2,
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

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 11, color: AppColors.slate600)),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
