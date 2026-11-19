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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.speed_rounded, color: AppColors.primaryDark),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('17-Sensor Telemetry Simulator', style: AppTextStyles.headingSmall),
                      Text(
                        'Simultaneous multi-rate ingestion across 100 Hz, 10 Hz, and 1 Hz sensor arrays',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            // Multi-Rate Sensor Badges
            const Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _RateBadge(
                  rate: '100 Hz (10 ms)',
                  count: '7 Sensors',
                  names: 'PS1–PS6, EPS1',
                  color: AppColors.sensorPressure,
                ),
                _RateBadge(
                  rate: '10 Hz (100 ms)',
                  count: '2 Sensors',
                  names: 'FS1, FS2',
                  color: AppColors.sensorFlow,
                ),
                _RateBadge(
                  rate: '1 Hz (1,000 ms)',
                  count: '8 Sensors',
                  names: 'TS1–TS4, VS1, CE, CP, SE',
                  color: AppColors.sensorTemp,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Quick Presets
            Text('TEST RIG CONDITION PRESETS', style: AppTextStyles.labelCaps),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Obx(() {
                    final isC1 = controller.selectedPreset.value == 'CYCLE_1';
                    return InkWell(
                      onTap: () => controller.setCyclePreset(1),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isC1 ? AppColors.success.withValues(alpha: 0.12) : AppColors.bgLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isC1 ? AppColors.success : AppColors.borderLight,
                            width: isC1 ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle_outline_rounded, size: 16, color: isC1 ? AppColors.success : AppColors.slate600),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  'Cycle 1: Baseline',
                                  style: AppTextStyles.headingSmall.copyWith(
                                    fontSize: 13,
                                    color: isC1 ? AppColors.success : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('Normal pressure (~156 bar), 0 leakage', style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Obx(() {
                    final isC211 = controller.selectedPreset.value == 'CYCLE_211';
                    return InkWell(
                      onTap: () => controller.setCyclePreset(211),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isC211 ? AppColors.verdictAct.withValues(alpha: 0.12) : AppColors.bgLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isC211 ? AppColors.verdictAct : AppColors.borderLight,
                            width: isC211 ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, size: 16, color: isC211 ? AppColors.verdictAct : AppColors.slate600),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  'Cycle 211: Severe Leak',
                                  style: AppTextStyles.headingSmall.copyWith(
                                    fontSize: 13,
                                    color: isC211 ? AppColors.verdictAct : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('Abrupt pressure drop to 110 bar', style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Number Input & Slider Combo
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SLIDER RANGE (1 TO 2,205 CYCLES)', style: AppTextStyles.labelCaps),
                      Obx(() => Slider(
                            value: controller.cycleId.value.toDouble(),
                            min: 1,
                            max: 2205,
                            divisions: 2204,
                            activeColor: AppColors.primary,
                            onChanged: controller.onSliderChanged,
                          )),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                SizedBox(
                  width: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DIRECT INPUT', style: AppTextStyles.labelCaps),
                      const SizedBox(height: AppSpacing.xs),
                      Obx(() => TextFormField(
                            controller: controller.cycleTextController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              hintText: '1..2205',
                              errorText: controller.cycleError.value,
                              errorMaxLines: 2,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onChanged: controller.onCycleInputChanged,
                          )),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // Tiered Storage Notice
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.archive_outlined, size: 20, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Obx(() => Text(
                          'Destination: Object Storage bucket industrial-raw/telemetry/cycle_${controller.cycleId.value.toString().padLeft(4, '0')}.parquet (Polars ZSTD)',
                          style: AppTextStyles.monoSmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                        )),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Ingest Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Obx(() {
                final isUploading = controller.isUploading.value;
                final cycleNum = controller.cycleId.value;
                return ElevatedButton(
                  onPressed: isUploading ? null : controller.ingestTelemetryCycle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.slate900,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isUploading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            SizedBox(width: AppSpacing.md),
                            Text('Aligning 17 Multi-Rate Sensors in Lockstep...', style: TextStyle(color: Colors.white)),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow_rounded, color: AppColors.primary),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Ingest Cycle #$cycleNum Telemetry Batch',
                              style: AppTextStyles.headingSmall.copyWith(color: Colors.white, fontSize: 14),
                            ),
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

class _RateBadge extends StatelessWidget {
  final String rate;
  final String count;
  final String names;
  final Color color;

  const _RateBadge({
    required this.rate,
    required this.count,
    required this.names,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: AppSpacing.xs),
              Text(rate, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(width: AppSpacing.xs),
              Text('($count)', style: const TextStyle(fontSize: 10, color: AppColors.slate600)),
            ],
          ),
          Text(names, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.slate700)),
        ],
      ),
    );
  }
}
