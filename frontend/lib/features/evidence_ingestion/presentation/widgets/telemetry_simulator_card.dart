import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../controllers/evidence_controller.dart';

class TelemetrySimulatorCard extends StatelessWidget {
  const TelemetrySimulatorCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = EvidenceController.to;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.speed_rounded, color: AppColors.primaryDark),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('17-Sensor Hydraulic Telemetry Simulator', style: AppTextStyles.headingSmall),
                    Text('Simultaneous 60s cycle batch ingestion across 100 Hz, 10 Hz, and 1 Hz arrays', style: AppTextStyles.bodySmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            // Dataset info & Multi-Rate Sensor Badges
            const Row(
              children: [
                _SensorRateBadge(
                  rate: '100 Hz (10 ms step)',
                  samples: '6,000 floats',
                  sensors: 'PS1–PS6, EPS1',
                  color: AppColors.sensorPressure,
                ),
                SizedBox(width: AppSpacing.sm),
                _SensorRateBadge(
                  rate: '10 Hz (100 ms step)',
                  samples: '600 floats',
                  sensors: 'FS1, FS2',
                  color: AppColors.sensorFlow,
                ),
                SizedBox(width: AppSpacing.sm),
                _SensorRateBadge(
                  rate: '1 Hz (1,000 ms step)',
                  samples: '60 floats',
                  sensors: 'TS1–TS4, VS1, CE, CP, SE',
                  color: AppColors.sensorTemp,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Presets
            Text('QUICK RIG STATE PRESETS', style: AppTextStyles.labelCaps),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Obx(() {
                  final isC1 = controller.cycleId.value == 1;
                  return ChoiceChip(
                    label: const Text('Cycle 1: Baseline Healthy Rig (Nominal)'),
                    selected: isC1,
                    selectedColor: AppColors.success.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isC1 ? AppColors.success : AppColors.textPrimary,
                      fontWeight: isC1 ? FontWeight.w600 : FontWeight.normal,
                    ),
                    onSelected: (_) => controller.setCyclePreset(1, isSevereLeak: false),
                  );
                }),
                const SizedBox(width: AppSpacing.sm),
                Obx(() {
                  final isC211 = controller.cycleId.value == 211;
                  return ChoiceChip(
                    label: const Text('Cycle 211: Abrupt Severe Pump Leakage'),
                    selected: isC211,
                    selectedColor: AppColors.verdictAct.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isC211 ? AppColors.verdictAct : AppColors.textPrimary,
                      fontWeight: isC211 ? FontWeight.w600 : FontWeight.normal,
                    ),
                    onSelected: (_) => controller.setCyclePreset(211, isSevereLeak: true),
                  );
                }),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Cycle Selector Slider & Number Input
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('CYCLE NUMBER SELECTOR (1 to 2,205)', style: AppTextStyles.labelCaps),
                          Obx(() => Text(
                                'Cycle #${controller.cycleId.value}',
                                style: AppTextStyles.monoMedium.copyWith(color: AppColors.primaryDark),
                              )),
                        ],
                      ),
                      Obx(() => Slider(
                            value: controller.cycleId.value.toDouble(),
                            min: 1,
                            max: 2205,
                            divisions: 2204,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              controller.cycleId.value = val.toInt();
                            },
                          )),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // Storage & Compression Specs Box
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.compress_rounded, size: 20, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Obx(() => Text(
                          'Compresses 17 raw text arrays into: hydraulic_lab/raw files/telemetry/cycle_${controller.cycleId.value.toString().padLeft(4, '0')}.parquet (Polars)',
                          style: AppTextStyles.monoSmall.copyWith(color: AppColors.textSecondary),
                        )),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Ingest Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: Obx(() {
                final isUploading = controller.isUploading.value;
                return ElevatedButton(
                  onPressed: isUploading ? null : controller.ingestTelemetryCycle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.slate900,
                  ),
                  child: isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_circle_outline_rounded, size: 20, color: AppColors.primary),
                            const SizedBox(width: AppSpacing.sm),
                            Text('Ingest 60s Cycle Batch & Extract Median/MAD', style: AppTextStyles.headingSmall.copyWith(color: Colors.white)),
                          ],
                        ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorRateBadge extends StatelessWidget {
  final String rate;
  final String samples;
  final String sensors;
  final Color color;

  const _SensorRateBadge({
    required this.rate,
    required this.samples,
    required this.sensors,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rate, style: AppTextStyles.monoSmall.copyWith(fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text('$samples • $sensors', style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
