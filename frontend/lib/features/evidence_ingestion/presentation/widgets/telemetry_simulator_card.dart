import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../controllers/evidence_controller.dart';
import 'zip_upload_card.dart';

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

            // Sub-Mode Switcher: Operational Cycle Simulator vs Raw ZIP Package Import
            Obx(() {
              final isZip = controller.isZipImportMode.value;
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Tooltip(
                        message: 'Operational Cycle Simulator: Replay and audit 60-second machine cycles (1 to 2,205) with live streaming gauges and condition presets.',
                        waitDuration: const Duration(milliseconds: 250),
                        child: InkWell(
                          onTap: () => controller.isZipImportMode.value = false,
                          borderRadius: BorderRadius.circular(6),
                          hoverColor: AppColors.primary.withValues(alpha: 0.08),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !isZip ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: !isZip
                                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.tune_rounded, size: 16, color: !isZip ? AppColors.primary : AppColors.textSecondary),
                                const SizedBox(width: AppSpacing.xs),
                                Flexible(
                                  child: Text(
                                    'Cycle Simulator (60s Stream)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: !isZip ? FontWeight.bold : FontWeight.w500,
                                      color: !isZip ? AppColors.primary : AppColors.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Tooltip(
                        message: 'Approach B (UI Batch Upload): Directly stream a raw hydraulic_cycle_raw.zip archive to FastAPI without browser-side parsing or memory leaks.',
                        waitDuration: const Duration(milliseconds: 250),
                        child: InkWell(
                          onTap: () => controller.isZipImportMode.value = true,
                          borderRadius: BorderRadius.circular(6),
                          hoverColor: AppColors.primary.withValues(alpha: 0.08),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isZip ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: isZip
                                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.archive_rounded, size: 16, color: isZip ? AppColors.primary : AppColors.textSecondary),
                                const SizedBox(width: AppSpacing.xs),
                                Flexible(
                                  child: Text(
                                    'Import Raw 17-Sensor ZIP',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isZip ? FontWeight.bold : FontWeight.w500,
                                      color: isZip ? AppColors.primary : AppColors.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Dynamic Body: ZIP Import vs Simulator
            Obx(() {
              if (controller.isZipImportMode.value) {
                return const ZipUploadCard();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        description: 'High-Frequency Arrays (6,000 pts/cycle)\nSensors: PS1..PS6 (Pressure transducers) & EPS1 (Motor electrical power). Detects millisecond pressure spikes and valve transitions.',
                      ),
                      _RateBadge(
                        rate: '10 Hz (100 ms)',
                        count: '2 Sensors',
                        names: 'FS1, FS2',
                        color: AppColors.sensorFlow,
                        description: 'Medium-Frequency Arrays (600 pts/cycle)\nSensors: FS1 (Primary hydraulic circuit flow) & FS2 (Cooling loop flow). Measures system flow rate and internal fluid leakage.',
                      ),
                      _RateBadge(
                        rate: '1 Hz (1,000 ms)',
                        count: '8 Sensors',
                        names: 'TS1–TS4, VS1, CE, CP, SE',
                        color: AppColors.sensorTemp,
                        description: 'Low-Frequency Condition Arrays (60 pts/cycle)\nSensors: TS1..TS4 (Temperatures), VS1 (Vibration), CE (Cooler efficiency), CP (Cooling power), SE (Efficiency factor).',
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
                          return Tooltip(
                            message: 'Cycle 1 (Healthy Baseline)\nCommissioning state: 100% cooler efficiency, zero valve lag, normal system pressure peak at ~156 bar.',
                            waitDuration: const Duration(milliseconds: 200),
                            child: InkWell(
                              onTap: () => controller.setCyclePreset(1),
                              borderRadius: BorderRadius.circular(8),
                              hoverColor: AppColors.success.withValues(alpha: 0.08),
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
                            ),
                          );
                        }),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Obx(() {
                          final isC211 = controller.selectedPreset.value == 'CYCLE_211';
                          return Tooltip(
                            message: 'Cycle 211 (Severe Internal Leakage)\nCatastrophic failure: Severe internal piston leakage causing abrupt pressure collapse down to 110 bar.',
                            waitDuration: const Duration(milliseconds: 200),
                            child: InkWell(
                              onTap: () => controller.setCyclePreset(211),
                              borderRadius: BorderRadius.circular(8),
                              hoverColor: AppColors.verdictAct.withValues(alpha: 0.08),
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
                            Tooltip(
                              message: 'Slide to select test bench cycle (1 = Jan 1, 2024; 2205 = End of wear testing)',
                              waitDuration: const Duration(milliseconds: 300),
                              child: Obx(() => Slider(
                                    value: controller.cycleId.value.toDouble(),
                                    min: 1,
                                    max: 2205,
                                    divisions: 2204,
                                    activeColor: AppColors.primary,
                                    onChanged: controller.onSliderChanged,
                                  )),
                            ),
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
                            Tooltip(
                              message: 'Type any valid integer cycle ID between 1 and 2,205',
                              waitDuration: const Duration(milliseconds: 300),
                              child: Obx(() => TextFormField(
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
                            ),
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
                                    Tooltip(
                                      message: '1x Real Machine Speed: Replays the 60-second cycle in genuine real time (60s).',
                                      waitDuration: const Duration(milliseconds: 200),
                                      child: ChoiceChip(
                                        label: const Text('1x Real (60s)', style: TextStyle(fontSize: 10)),
                                        selected: controller.streamSpeedMultiplier.value == 1,
                                        onSelected: (_) => controller.streamSpeedMultiplier.value = 1,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Tooltip(
                                      message: '6x Fast Demo Speed: Replays the full 60-second cycle in 10 seconds for rapid testing.',
                                      waitDuration: const Duration(milliseconds: 200),
                                      child: ChoiceChip(
                                        label: const Text('6x Demo (10s)', style: TextStyle(fontSize: 10)),
                                        selected: controller.streamSpeedMultiplier.value == 6,
                                        onSelected: (_) => controller.streamSpeedMultiplier.value = 6,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Tooltip(
                                      message: '12x Ultra Speed: Replays the 60-second cycle in 5 seconds (great for sequential 1 to N runs).',
                                      waitDuration: const Duration(milliseconds: 200),
                                      child: ChoiceChip(
                                        label: const Text('12x Ultra (5s)', style: TextStyle(fontSize: 10)),
                                        selected: controller.streamSpeedMultiplier.value == 12,
                                        onSelected: (_) => controller.streamSpeedMultiplier.value = 12,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ],
                                )),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Active Stream Status & Progress Bar
                        Obx(() {
                          final isStreaming = controller.isStreamingLiveCycle.value;
                          final isUploading = controller.isUploading.value;
                          final isSequential = controller.isSequentialMode.value;
                          final seqCur = controller.sequentialCurrentCycle.value;
                          final seqTarget = controller.sequentialTargetCycle.value;
                          final elapsed = controller.streamElapsedSeconds.value;
                          final progress = elapsed / 60.0;
                          final phase = controller.currentLivePhase.value;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      isUploading
                                          ? (isSequential ? 'SEALING CYCLE #$seqCur OF $seqTarget...' : 'SEALING PARQUET & COMMITTING TO SUPABASE...')
                                          : (isStreaming
                                              ? (isSequential ? 'RUNNING CYCLE #$seqCur OF $seqTarget: $phase' : 'STREAMING: $phase')
                                              : (elapsed == 60 ? 'CYCLE SEALED & COMMITTED' : 'READY TO STREAM 60s CYCLE')),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isUploading
                                            ? AppColors.sensorTemp
                                            : (isStreaming ? AppColors.primaryDark : AppColors.slate700),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    isUploading ? 'SEALING...' : (isSequential ? '${elapsed}s/60s (Cycle $seqCur/$seqTarget)' : '${elapsed}s / 60s'),
                                    style: AppTextStyles.monoSmall.copyWith(fontWeight: FontWeight.bold),
                                  ),
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
                                    child: Tooltip(
                                      message: 'PS1: Primary Circuit Pressure Transmitter (0 to 250 bar)\nSamples at 100 Hz (6,000 readings per cycle)',
                                      waitDuration: const Duration(milliseconds: 200),
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.help,
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
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Tooltip(
                                      message: 'FS1: Primary Circuit Flow Transmitter (0 to 10 L/min)\nSamples at 10 Hz (600 readings per cycle)',
                                      waitDuration: const Duration(milliseconds: 200),
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.help,
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

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Tooltip(
                                message: isStreaming
                                    ? 'Click to halt machine stream execution'
                                    : (isUploading
                                        ? 'Sealing Parquet & committing to Supabase...'
                                        : (cycleNum > 1
                                            ? 'Continuous Industrial Run: Streams and seals Cycles 1 through $cycleNum in real-time sequence.'
                                            : 'Start 60-second machine simulation for Cycle #1 with active sensor streaming.')),
                                waitDuration: const Duration(milliseconds: 200),
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: isStreaming
                                        ? controller.cancelLiveStream
                                        : (isUploading
                                            ? null
                                            : (cycleNum > 1
                                                ? controller.startSequentialStream
                                                : controller.startLiveCycleStream)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isStreaming
                                          ? AppColors.verdictAct
                                          : AppColors.primaryDark,
                                      disabledBackgroundColor: AppColors.slate300,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isStreaming ? Icons.stop_rounded : (cycleNum > 1 ? Icons.fast_forward_rounded : Icons.sensors_rounded),
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Flexible(
                                          child: Text(
                                            isStreaming
                                                ? 'Stop Stream'
                                                : (cycleNum > 1 ? 'Live Stream (1 → $cycleNum)' : 'Live 60s Stream (#1)'),
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              flex: 2,
                              child: Tooltip(
                                message: 'Instant Batch Mode: Compresses the 17 sensor streams to Parquet, calculates SHA-256, and commits to ledger immediately (~35 ms)',
                                waitDuration: const Duration(milliseconds: 200),
                                child: SizedBox(
                                  height: 48,
                                  child: OutlinedButton(
                                    onPressed: (isStreaming || isUploading) ? null : controller.ingestTelemetryCycle,
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.borderLight),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: Text(cycleNum > 1 ? 'Batch #$cycleNum' : 'Instant Batch', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (cycleNum > 1 && !isStreaming && !isUploading) ...[
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: InkWell(
                              onTap: controller.startLiveCycleStream,
                              borderRadius: BorderRadius.circular(4),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Text(
                                  'Or stream only selected cycle without sequence (single 60s cycle)',
                                  style: TextStyle(fontSize: 11, color: AppColors.primaryDark, decoration: TextDecoration.underline),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  }),
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
  final String description;

  const _RateBadge({
    required this.rate,
    required this.count,
    required this.names,
    required this.color,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: description,
      waitDuration: const Duration(milliseconds: 200),
      child: MouseRegion(
        cursor: SystemMouseCursors.help,
        child: Container(
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
        ),
      ),
    );
  }
}
