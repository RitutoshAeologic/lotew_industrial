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
                      Text('17-Sensor Telemetry Simulator & Real-Time Stream', style: AppTextStyles.headingSmall),
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

            // Real-Time 60-Second Machine Execution Simulation Box
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.xs,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, size: 18, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.xs),
                          Text('PHYSICAL 60-SECOND STREAMING', style: AppTextStyles.labelCaps),
                        ],
                      ),
                      // Speed Multiplier Selector
                      Obx(() => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Speed: ', style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                              ChoiceChip(
                                label: const Text('1x Real (60s)', style: TextStyle(fontSize: 10)),
                                selected: controller.streamSpeedMultiplier.value == 1,
                                onSelected: (_) => controller.streamSpeedMultiplier.value = 1,
                                visualDensity: VisualDensity.compact,
                              ),
                              const SizedBox(width: 4),
                              ChoiceChip(
                                label: const Text('6x Demo (10s)', style: TextStyle(fontSize: 10)),
                                selected: controller.streamSpeedMultiplier.value == 6,
                                onSelected: (_) => controller.streamSpeedMultiplier.value = 6,
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          )),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Active Stream Status & Progress Bar
                  Obx(() {
                    final isStreaming = controller.isStreamingLiveCycle.value;
                    final elapsed = controller.streamElapsedSeconds.value;
                    final progress = elapsed / 60.0;
                    final phase = controller.currentLivePhase.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isStreaming ? 'STREAMING: $phase' : (elapsed == 60 ? 'CYCLE SEALED & COMMITTED' : 'READY TO STREAM 60s CYCLE'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isStreaming ? AppColors.primaryDark : AppColors.slate700,
                              ),
                            ),
                            Text('${elapsed}s / 60s', style: AppTextStyles.monoSmall.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        LinearProgressIndicator(
                          value: isStreaming || elapsed > 0 ? progress : 0.0,
                          backgroundColor: AppColors.borderLight,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            elapsed == 60 ? AppColors.success : AppColors.primary,
                          ),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Dual Live Telemetry Digital Gauges
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('LIVE PS1:', style: TextStyle(fontSize: 11, color: AppColors.slate600)),
                                    Text(
                                      '${controller.currentLivePressure.value.toStringAsFixed(1)} bar',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.sensorPressure),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('LIVE FS1:', style: TextStyle(fontSize: 11, color: AppColors.slate600)),
                                    Text(
                                      '${controller.currentLiveFlow.value.toStringAsFixed(1)} L/min',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.sensorFlow),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Ingest Action Buttons (Real-time Stream vs Instant Batch)
            Obx(() {
              final isStreaming = controller.isStreamingLiveCycle.value;
              final isUploading = controller.isUploading.value;
              final cycleNum = controller.cycleId.value;

              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: (isStreaming || isUploading)
                            ? (isStreaming ? controller.cancelLiveStream : null)
                            : controller.startLiveCycleStream,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isStreaming ? AppColors.verdictAct : AppColors.primaryDark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isStreaming ? Icons.stop_rounded : Icons.sensors_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: AppSpacing.xs),
                            Flexible(
                              child: Text(
                                isStreaming ? 'Stop Stream' : 'Live 60s Stream (#$cycleNum)',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: (isStreaming || isUploading) ? null : controller.ingestTelemetryCycle,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.borderLight),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: isUploading
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Instant Batch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              );
            }),
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
