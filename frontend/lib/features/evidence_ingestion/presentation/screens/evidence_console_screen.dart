import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/responsive/responsive_controller.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../domain/models/evidence_item_model.dart';
import '../controllers/evidence_controller.dart';
import '../widgets/canonical_json_viewer.dart';
import '../widgets/forensic_detail_dialog.dart';
// import '../widgets/csv_upload_card.dart';
import '../widgets/live_forensic_card.dart';
// import '../widgets/pdf_upload_card.dart';
import '../widgets/telemetry_live_bar_chart.dart';
import '../widgets/telemetry_simulator_card.dart';
import '../widgets/telemetry_waveform_chart.dart';

class EvidenceConsoleScreen extends StatelessWidget {
  const EvidenceConsoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = EvidenceController.to;
    final rc = ResponsiveController.to;

    return AppScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar / Status Header
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.sm,
                        runSpacing: 4,
                        children: [
                          Text('Industrial Evidence Ingestion Console', style: AppTextStyles.headingLarge),
                          Tooltip(
                            message: 'Active Physical Asset: Hydraulic Test Bench (hydraulic_rig_01)\nTenant: hydraulic_lab • Discrete 60s Cycles @ 100 Hz',
                            waitDuration: const Duration(milliseconds: 200),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.help,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'RIG: hydraulic_rig_01',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Discrete 60-Second Operational Cycles & Technician Documentary Logs Ingestion',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Action Controls: Retest, Refresh & Live API Switch
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Retest / Reset Session Button
                    Tooltip(
                      message: 'Reset current inspection session and re-arm for a fresh test cycle',
                      waitDuration: const Duration(milliseconds: 200),
                      child: OutlinedButton.icon(
                        onPressed: controller.resetRetestSession,
                        icon: const Icon(Icons.restart_alt_rounded, size: 16),
                        label: const Text('Reset / Retest'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                          foregroundColor: AppColors.slate900,
                          side: const BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // Refresh Ledger Button
                    Tooltip(
                      message: 'Fetch latest synchronized cycle records from Supabase database',
                      waitDuration: const Duration(milliseconds: 200),
                      child: OutlinedButton.icon(
                        onPressed: controller.refreshLedger,
                        icon: const Icon(Icons.sync_rounded, size: 16),
                        label: const Text('Refresh'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                          foregroundColor: AppColors.slate900,
                          side: const BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                    ),
                    // const SizedBox(width: AppSpacing.md),

                    // COMMENTED OUT AS REQUESTED: Live API container at the top
                    /*
                    // Live API vs Mock Mode Switch
                    Obx(() => Tooltip(
                          message: controller.isMockMode.value
                              ? 'Offline Demo Mode: Local simulation with mock SHA-256 and latency measurements. Click switch to connect to live FastAPI backend at localhost:8000.'
                              : 'Live Backend Mode: Connected to FastAPI backend at http://localhost:8000 with real Supabase Object Storage & Database persistence.',
                          waitDuration: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                            decoration: BoxDecoration(
                              color: controller.isMockMode.value ? AppColors.sensorTemp.withValues(alpha: 0.12) : AppColors.success.withValues(alpha: 0.12),
                              borderRadius: const BorderRadius.all(Radius.circular(20)),
                              border: Border.all(
                                color: controller.isMockMode.value ? AppColors.sensorTemp : AppColors.success,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  controller.isMockMode.value ? Icons.offline_bolt_rounded : Icons.cloud_done_rounded,
                                  size: 16,
                                  color: controller.isMockMode.value ? AppColors.sensorTemp : AppColors.success,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  controller.isMockMode.value ? 'OFFLINE DEMO MODE' : 'LIVE API (localhost:8000)',
                                  style: AppTextStyles.labelCaps.copyWith(
                                    color: controller.isMockMode.value ? AppColors.sensorTemp : AppColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Switch(
                                  value: controller.isMockMode.value,
                                  onChanged: (_) => controller.toggleMockMode(),
                                  activeThumbColor: AppColors.sensorTemp,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ],
                            ),
                          ),
                        )),
                    */
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Dataset Architecture & Temporal Context Banner (Explaining 2,205 Cycles = ~36.8 Hours)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.primaryDark, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.slate900, fontSize: 12),
                        children: const [
                          TextSpan(
                            text: 'UCI Hydraulic Bench Dataset Architecture: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: 'Contains ',
                          ),
                          TextSpan(
                            text: '2,205 discrete operational cycles (~36.8 total hours of physical machine execution)',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                          ),
                          TextSpan(
                            text: '. Each line in the 17 raw text files represents ',
                          ),
                          TextSpan(
                            text: '1 full 60-second machine cycle (43,680 synchronized data points)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: '. Select any cycle (1 to 2,205) on the left to inspect its health condition, run forensic sealing, or retest.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Ingestion Mode Header (Hydraulic Rig Stream)
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderLight),
              ),
              padding: const EdgeInsets.all(4),
              child: const _ConsoleTabButton(
                label: '17-Sensor Hydraulic Rig Stream',
                badge: 'PRIMARY RIG • 100 Hz (43,680 SAMPLES / CYCLE)',
                tooltip: 'Discrete 60-second machine cycles from UCI Hydraulic Test Bench across 17 synchronized sensors (PS1..PS6, FS1..FS2, TS1..TS4, etc.).',
                icon: Icons.speed_rounded,
                isSelected: true,
                activeColor: AppColors.primary,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── 17-Sensor Telemetry Simulator (Full-Width Console Mode) ────────────────
            const TelemetrySimulatorCard(),

            /* PREVIOUS SPLIT LAYOUT (SIMULATOR ON LEFT + INSPECTOR ON RIGHT) PRESERVED:
            Obx(() {
              final latestTelemetry = controller.latestTelemetryEvidence.value;
              final isStreaming = controller.isStreamingLiveCycle.value;
              final isRangeStreaming = controller.isRangeStreaming.value;
              final isUploading = controller.isUploading.value;

              Widget rightColumn;
              if (isUploading) {
                rightColumn = _SealingUploadCard(
                  cycleId: controller.cycleId.value,
                  isSequential: controller.isSequentialMode.value,
                  currentStep: controller.sequentialCurrentCycle.value,
                  totalSteps: controller.sequentialTargetCycle.value,
                );
              } else if (isStreaming || isRangeStreaming) {
                rightColumn = _StreamingLiveMonitorCard(
                  cycleId: controller.cycleId.value,
                  phase: controller.currentLivePhase.value,
                  elapsed: controller.streamElapsedSeconds.value,
                  pressure: controller.currentLivePressure.value,
                  flow: controller.currentLiveFlow.value,
                  isSequential: controller.isSequentialMode.value || isRangeStreaming,
                  currentStep: isRangeStreaming ? controller.rangeStreamCurrent.value : controller.sequentialCurrentCycle.value,
                  totalSteps: isRangeStreaming ? controller.rangeStreamEnd.value : controller.sequentialTargetCycle.value,
                );
              } else if (latestTelemetry != null) {
                final selectedTab = controller.inspectionTab.value;
                rightColumn = Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InspectionHeader(
                        evidence: latestTelemetry,
                        cycleId: controller.cycleId.value,
                        onRetest: controller.resetRetestSession,
                      ),
                      const Divider(height: 1),
                      // Segmented inspection tabs...
                    ],
                  ),
                );
              } else {
                rightColumn = _AwaitingEvidenceCard(
                  title: 'No Telemetry Ingested in Current Session',
                  description: 'Select Cycle #1 (Baseline) or Cycle #211 (Severe Leakage) on the left and click "Start Live 60s Stream" or "Instant Batch".',
                  actionLabel: 'Quick Ingest Cycle 1',
                  icon: Icons.speed_rounded,
                  onAction: () {
                    controller.setCyclePreset(1);
                    controller.ingestTelemetryCycle();
                  },
                );
              }

              if (rc.isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(flex: 5, child: TelemetrySimulatorCard()),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(flex: 6, child: rightColumn),
                  ],
                );
              } else {
                return Column(
                  children: [
                    const TelemetrySimulatorCard(),
                    const SizedBox(height: AppSpacing.lg),
                    rightColumn,
                  ],
                );
              }
            }),
            */

            // ── Live Ingestion Spectrum Bar Chart Card (Conditional: Shown ONLY when Full Rig is streaming) ──
            Obx(() {
              final isFullRigActive = controller.isRangeStreaming.value;
              if (!isFullRigActive) {
                return const SizedBox.shrink();
              }
              return const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSpacing.xl),
                  _TelemetrySpectrumOverviewCard(),
                ],
              );
            }),

            const SizedBox(height: AppSpacing.xl),

            // Evidence History Ledger
            const _EvidenceHistoryTable(),
          ],
        ),
      ),
    );
  }
}

class _InspectionHeader extends StatelessWidget {
  final EvidenceItemModel evidence;
  final int cycleId;
  final VoidCallback onRetest;

  const _InspectionHeader({
    required this.evidence,
    required this.cycleId,
    required this.onRetest,
  });

  @override
  Widget build(BuildContext context) {
    final isNominal = evidence.qualityFlag == 'NOMINAL';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isNominal ? AppColors.success.withValues(alpha: 0.12) : AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isNominal ? AppColors.success : AppColors.warning,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isNominal ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                  size: 16,
                  color: isNominal ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  isNominal ? 'NOMINAL BASELINE (HEALTHY)' : 'DEGRADED LEAK DETECTED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isNominal ? AppColors.success : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Active Cycle #$cycleId',
            style: AppTextStyles.headingSmall.copyWith(fontSize: 15),
          ),
          const Spacer(),
          // Quick Retest button
          OutlinedButton.icon(
            onPressed: onRetest,
            icon: const Icon(Icons.restart_alt_rounded, size: 15),
            label: const Text('Retest Cycle'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
              textStyle: AppTextStyles.labelCaps.copyWith(fontSize: 11),
              foregroundColor: AppColors.slate900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectionSegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _InspectionSegmentButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected ? Border.all(color: AppColors.borderLight) : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.primary : AppColors.slate600,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.slate900 : AppColors.slate600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsoleTabButton extends StatelessWidget {
  final String label;
  final String badge;
  final String tooltip;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;

  const _ConsoleTabButton({
    required this.label,
    required this.badge,
    required this.tooltip,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 250),
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.slate900 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? activeColor : AppColors.slate600,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      badge,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? activeColor : AppColors.slate600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}

class _AwaitingEvidenceCard extends StatelessWidget {
  final String title;
  final String description;
  final String actionLabel;
  final IconData icon;
  final VoidCallback onAction;

  const _AwaitingEvidenceCard({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.icon,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.bgLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.slate600),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: AppTextStyles.headingSmall, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.slate900,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SealingUploadCard extends StatelessWidget {
  final int cycleId;
  final bool isSequential;
  final int currentStep;
  final int totalSteps;

  const _SealingUploadCard({
    required this.cycleId,
    this.isSequential = false,
    this.currentStep = 1,
    this.totalSteps = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 45, horizontal: AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isSequential
                  ? 'Sealing Cycle #$cycleId (Batch $currentStep of $totalSteps)'
                  : 'Sealing 60s Telemetry Cycle #$cycleId',
              style: AppTextStyles.headingMedium.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Text(
                'Compressing 43,680 multi-rate data points into ZSTD Parquet & committing forensic SHA-256 ledger to Supabase...',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              constraints: const BoxConstraints(maxWidth: 460),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  const _StepStatusRow(label: '1. Lockstep 17-Sensor Alignment (100Hz/10Hz/1Hz)', isDone: true),
                  const SizedBox(height: 8),
                  const _StepStatusRow(label: '2. ZSTD Parquet Compression & SHA-256 Hashing', isDone: true),
                  const SizedBox(height: 8),
                  _StepStatusRow(
                    label: isSequential && currentStep < totalSteps
                        ? '3. Persisting to Supabase (Next: Cycle #${currentStep + 1})'
                        : '3. Persisting to Supabase (industrial.evidence_streams)',
                    isPending: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepStatusRow extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isPending;

  const _StepStatusRow({
    required this.label,
    this.isDone = false,
    this.isPending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isDone)
          const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success)
        else if (isPending)
          const Icon(Icons.sync_rounded, size: 16, color: AppColors.primary)
        else
          const Icon(Icons.radio_button_unchecked_rounded, size: 16, color: AppColors.slate500),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isPending ? FontWeight.bold : FontWeight.w500,
              color: isPending ? AppColors.primaryDark : (isDone ? AppColors.textPrimary : AppColors.slate600),
            ),
          ),
        ),
      ],
    );
  }
}

class _StreamingLiveMonitorCard extends StatelessWidget {
  final int cycleId;
  final String phase;
  final int elapsed;
  final double pressure;
  final double flow;
  final bool isSequential;
  final int currentStep;
  final int totalSteps;

  const _StreamingLiveMonitorCard({
    required this.cycleId,
    required this.phase,
    required this.elapsed,
    required this.pressure,
    required this.flow,
    this.isSequential = false,
    this.currentStep = 1,
    this.totalSteps = 1,
  });

  @override
  Widget build(BuildContext context) {
    final controller = EvidenceController.to;
    return Obx(() {
      final isRange = controller.isRangeStreaming.value;
      final rangeCur = controller.rangeStreamCurrent.value;
      final rangeEnd = controller.rangeStreamEnd.value;
      final throughput = controller.streamingThroughput.value;
      final progress = isRange ? controller.streamProgress.value : (elapsed / 60.0).clamp(0.0, 1.0);

      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.primaryDark, width: 1.5),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        isRange
                            ? 'CONTINUOUS INDUSTRIAL RUN • CYCLE #$rangeCur OF #$rangeEnd'
                            : (isSequential
                                ? 'CONTINUOUS RUN • CYCLE #$cycleId OF #$totalSteps'
                                : 'PHYSICAL TEST RIG EXECUTION • CYCLE #$cycleId'),
                        style: AppTextStyles.labelCaps.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text(
                    isRange
                        ? '${(progress * 100).toInt()}% ($rangeCur / $rangeEnd) • $throughput cyc/s'
                        : (isSequential
                            ? '${elapsed}s/60s (Batch $currentStep/$totalSteps)'
                            : '${elapsed}s / 60s (${(progress * 100).toInt()}%)'),
                    style: AppTextStyles.monoSmall.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                backgroundColor: AppColors.borderLight,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.slate900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRange ? 'LIVE INDUSTRIAL RANGE EXECUTION:' : 'ACTIVE STROKE PHASE:',
                      style: AppTextStyles.labelCaps.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isRange
                          ? 'Streaming Cycles ${(rangeCur - 50 + 1).clamp(1, rangeEnd)} → $rangeCur • Multi-Rate 17-Sensor Synchronization'
                          : phase,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Divider(color: Colors.white24, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(isRange ? 'Throughput' : 'PS1 Pressure', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(
                              isRange ? '$throughput cyc/s' : '${pressure.toStringAsFixed(1)} bar',
                              style: const TextStyle(color: AppColors.sensorPressure, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(width: 1, height: 30, color: Colors.white24),
                        Column(
                          children: [
                            Text(isRange ? 'Rig Pressure' : 'FS1 Flow Rate', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(
                              isRange ? '${controller.currentLivePressure.value.toStringAsFixed(1)} bar' : '${flow.toStringAsFixed(1)} L/min',
                              style: const TextStyle(color: AppColors.sensorFlow, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      isRange
                          ? 'Continuous multi-cycle ingestion active. Live progress and condition flags are updating dynamically on the 2,205-Cycle Spectrum below.'
                          : 'Streaming 43,680 data points across 17 synchronized channels. Automatic Parquet sealing will trigger at 60s.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

/*
class _ExtractedTextCard extends StatelessWidget {
  final String text;

  const _ExtractedTextCard({required this.text});

  @override
  Widget build(BuildContext context) {
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
            Row(
              children: [
                const Icon(Icons.text_snippet_rounded, size: 20, color: AppColors.sensorTemp),
                const SizedBox(width: AppSpacing.sm),
                Text('Extracted OCR & Technician Text Preview', style: AppTextStyles.headingSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                text,
                style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/

/// Real-time Ingestion Spectrum Overview Card displaying 45 dense bins across 2,205 cycles
class _TelemetrySpectrumOverviewCard extends StatelessWidget {
  const _TelemetrySpectrumOverviewCard();

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bar_chart_rounded, size: 20, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Live Ingestion Spectrum (Cycles 1 – 2,205)', style: AppTextStyles.headingSmall),
                  ],
                ),
                Obx(() {
                  final count = controller.cycleQualityMap.length;
                  final isStreaming = controller.isRangeStreaming.value;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isStreaming) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'LIVE STREAM: ${controller.streamingThroughput.value} cyc/s',
                          style: AppTextStyles.monoSmall.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        '$count / 2,205 Cycles Ingested',
                        style: AppTextStyles.monoSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                }),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Continuous multi-sensor hydraulic test rig cycle distribution across 45 bins (50 cycles/bin). Green: Nominal Baseline • Amber: Degraded Leak • Cyan: Actively Streaming Batch.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            Obx(() {
              final map = Map<int, String>.from(controller.cycleQualityMap);
              return TelemetryLiveBarChart(
                cycleQualityMap: map,
                currentCycle: controller.rangeStreamCurrent.value,
                totalCycles: 2205,
                isStreaming: controller.isRangeStreaming.value,
                throughput: controller.streamingThroughput.value,
              );
            }),
          ],
        ),
      ),
    );
  }
}

/* PREVIOUS UNPAGINATED TABLE IMPLEMENTATION PRESERVED:
class _EvidenceHistoryTableLegacy extends StatelessWidget {
  const _EvidenceHistoryTableLegacy();

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_rounded, size: 20, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Forensic Evidence Ledger (Audit Trail)', style: AppTextStyles.headingSmall),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(() => Text(
                          '${controller.evidenceHistory.where((e) => e.isTelemetry).length} Telemetry Cycles',
                          style: AppTextStyles.monoSmall.copyWith(color: AppColors.textSecondary),
                        )),
                    const SizedBox(width: AppSpacing.xs),
                    IconButton(
                      icon: const Icon(Icons.sync_rounded, size: 16, color: AppColors.slate600),
                      tooltip: 'Refresh Ledger from Supabase',
                      onPressed: controller.refreshLedger,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            Obx(() {
              final list = controller.evidenceHistory.where((e) => e.isTelemetry).toList();
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: Text('No evidence ingested yet.', style: AppTextStyles.bodySmall),
                  ),
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppColors.bgLight),
                  columns: const [
                    DataColumn(label: Text('TYPE')),
                    DataColumn(label: Text('TARGET')),
                    DataColumn(label: Text('SHA-256 HASH')),
                    DataColumn(label: Text('EVENT TIME')),
                    DataColumn(label: Text('LATENCY')),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('ACTION')),
                  ],
                  rows: list.map((item) {
                    final isPdf = item.isPdf;
                    return DataRow(
                      cells: [
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPdf ? Icons.picture_as_pdf_rounded : Icons.speed_rounded,
                              size: 16,
                              color: isPdf ? AppColors.sensorTemp : AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(isPdf ? 'PDF' : 'TELEMETRY', style: AppTextStyles.monoSmall.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        )),
                        DataCell(Text(isPdf ? (item.componentId ?? 'system') : 'Cycle #${item.cycleId}')),
                        DataCell(Text('${item.rawFileSha256.substring(0, 16)}...', style: AppTextStyles.monoSmall)),
                        DataCell(Text(item.eventTime != null ? item.eventTime!.toIso8601String().substring(0, 19) : '-')),
                        DataCell(Tooltip(
                          message: AppFormatters.formatTooltipDuration(item.processingLatencyMs),
                          child: Text(AppFormatters.formatDurationMs(item.processingLatencyMs), style: AppTextStyles.monoSmall),
                        )),
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.qualityFlag == 'NOMINAL' ? AppColors.success.withValues(alpha: 0.15) : AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.qualityFlag,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: item.qualityFlag == 'NOMINAL' ? AppColors.success : AppColors.warning,
                            ),
                          ),
                        )),
                        DataCell(TextButton(
                          onPressed: () => controller.selectEvidence(item),
                          child: const Text('Inspect'),
                        )),
                      ],
                    );
                  }).toList(),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
*/

/// Upgraded High-Capacity Paginated Forensic Evidence Ledger (Audit Trail)
/// Smoothly renders all 2,205 cycles with search, filters, pagination, and "View JSON" modal dossiers.
class _EvidenceHistoryTable extends StatefulWidget {
  const _EvidenceHistoryTable();

  @override
  State<_EvidenceHistoryTable> createState() => _EvidenceHistoryTableState();
}

class _EvidenceHistoryTableState extends State<_EvidenceHistoryTable> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  int _rowsPerPage = 50;
  String _selectedCondition = 'ALL'; // 'ALL', 'NOMINAL', 'DEGRADED_LEAK'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
            // Ledger Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_rounded, size: 20, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Forensic Evidence Ledger (Audit Trail)', style: AppTextStyles.headingSmall),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(() {
                      final totalCycles = controller.evidenceHistory.where((e) => e.isTelemetry).length;
                      return Text(
                        '$totalCycles Telemetry Cycles Registered',
                        style: AppTextStyles.monoSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                      );
                    }),
                    const SizedBox(width: AppSpacing.xs),
                    IconButton(
                      icon: const Icon(Icons.sync_rounded, size: 16, color: AppColors.slate600),
                      tooltip: 'Refresh Ledger from Supabase',
                      onPressed: controller.refreshLedger,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Clear / Delete Ingested Data Button
                    OutlinedButton.icon(
                      onPressed: () {
                        Get.dialog(
                          AlertDialog(
                            title: const Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, color: AppColors.verdictAct, size: 22),
                                SizedBox(width: 8),
                                Text('Delete All Telemetry Data?'),
                              ],
                            ),
                            content: const Text(
                              'This will permanently delete all ingested telemetry cycles from the Supabase database and purge local memory. This action cannot be undone.',
                              style: TextStyle(fontSize: 13),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Get.back();
                                  controller.clearAllTelemetry();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.verdictAct,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Delete Data'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_sweep_rounded, size: 15, color: AppColors.verdictAct),
                      label: const Text(
                        'Clear Data',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.verdictAct),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        side: BorderSide(color: AppColors.verdictAct.withValues(alpha: 0.5)),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            // Controls Bar: Search + Filter Chips + Rows Per Page
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Quick Cycle Search
                SizedBox(
                  width: 240,
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() => _currentPage = 0),
                    decoration: InputDecoration(
                      hintText: 'Search Cycle # or SHA...',
                      hintStyle: const TextStyle(fontSize: 12, color: AppColors.slate500),
                      prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppColors.slate500),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 14),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _currentPage = 0);
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      filled: true,
                      fillColor: AppColors.bgLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderLight)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderLight)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),

                // Condition Filter Chips
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FilterChipButton(
                      label: 'All Cycles',
                      isSelected: _selectedCondition == 'ALL',
                      onTap: () => setState(() {
                        _selectedCondition = 'ALL';
                        _currentPage = 0;
                      }),
                    ),
                    const SizedBox(width: 6),
                    _FilterChipButton(
                      label: 'Nominal',
                      color: AppColors.success,
                      isSelected: _selectedCondition == 'NOMINAL',
                      onTap: () => setState(() {
                        _selectedCondition = 'NOMINAL';
                        _currentPage = 0;
                      }),
                    ),
                    const SizedBox(width: 6),
                    _FilterChipButton(
                      label: 'Rig Faults',
                      color: AppColors.warning,
                      isSelected: _selectedCondition == 'FAULTS',
                      onTap: () => setState(() {
                        _selectedCondition = 'FAULTS';
                        _currentPage = 0;
                      }),
                    ),
                    const SizedBox(width: 6),
                    _FilterChipButton(
                      label: 'Signal Anomalies',
                      color: const Color(0xFFEF4444),
                      isSelected: _selectedCondition == 'ANOMALIES',
                      onTap: () => setState(() {
                        _selectedCondition = 'ANOMALIES';
                        _currentPage = 0;
                      }),
                    ),
                  ],
                ),

                // Rows Per Page Selector
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Rows per page:', style: TextStyle(fontSize: 12, color: AppColors.slate600)),
                    const SizedBox(width: 6),
                    DropdownButton<int>(
                      value: _rowsPerPage,
                      isDense: true,
                      underline: const SizedBox(),
                      style: const TextStyle(fontSize: 12, color: AppColors.slate900, fontWeight: FontWeight.bold),
                      items: const [
                        DropdownMenuItem(value: 25, child: Text('25')),
                        DropdownMenuItem(value: 50, child: Text('50')),
                        DropdownMenuItem(value: 100, child: Text('100')),
                        DropdownMenuItem(value: 250, child: Text('250')),
                        DropdownMenuItem(value: 2205, child: Text('All (2,205)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _rowsPerPage = val;
                            _currentPage = 0;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Paginated Table Body
            Obx(() {
              final allTelemetry = controller.evidenceHistory.where((e) => e.isTelemetry).toList();

              if (allTelemetry.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.inbox_rounded, size: 40, color: AppColors.slate500),
                        const SizedBox(height: 8),
                        Text('No evidence ingested yet.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.slate600)),
                        const SizedBox(height: 4),
                        const Text('Click "Live Stream (1 → 2205)" to ingest cycles 1 to 2,205.', style: TextStyle(fontSize: 12, color: AppColors.slate500)),
                      ],
                    ),
                  ),
                );
              }

              // Apply filtering
              final query = _searchController.text.trim().toLowerCase();
              final filtered = allTelemetry.where((item) {
                // PREVIOUS DIRECT EQUALITY:
                // if (_selectedCondition != 'ALL' && item.qualityFlag != _selectedCondition) {
                //   return false;
                // }
                if (_selectedCondition == 'NOMINAL' && item.qualityFlag != 'NOMINAL') {
                  return false;
                } else if (_selectedCondition == 'FAULTS' && !item.qualityFlag.startsWith('DEGRADED_')) {
                  return false;
                } else if (_selectedCondition == 'ANOMALIES' && (item.qualityFlag == 'NOMINAL' || item.qualityFlag.startsWith('DEGRADED_'))) {
                  return false;
                } else if (_selectedCondition != 'ALL' && _selectedCondition != 'NOMINAL' && _selectedCondition != 'FAULTS' && _selectedCondition != 'ANOMALIES' && item.qualityFlag != _selectedCondition) {
                  return false;
                }

                if (query.isNotEmpty) {
                  final matchCycle = item.cycleId?.toString().contains(query) ?? false;
                  final matchSha = item.rawFileSha256.toLowerCase().contains(query);
                  final matchFlag = item.qualityFlag.toLowerCase().contains(query);
                  return matchCycle || matchSha || matchFlag;
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                    child: Text('No telemetry records match "$query".', style: AppTextStyles.bodySmall),
                  ),
                );
              }

              final totalItems = filtered.length;
              final maxPage = ((totalItems - 1) / _rowsPerPage).floor();
              final safePage = _currentPage.clamp(0, maxPage);
              final startIndex = safePage * _rowsPerPage;
              final endIndex = (startIndex + _rowsPerPage > totalItems) ? totalItems : (startIndex + _rowsPerPage);
              final pageItems = filtered.sublist(startIndex, endIndex);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth;
                      // Dynamic column spacing to guarantee table spans 100% width across cards
                      final dynamicSpacing = ((availableWidth - 950) / 8).clamp(10.0, 36.0);

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: availableWidth),
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(AppColors.bgLight),
                            horizontalMargin: 16,
                            columnSpacing: dynamicSpacing,
                            columns: const [
                              DataColumn(label: Text('TYPE')),
                              DataColumn(label: Text('TARGET')),
                              DataColumn(label: Text('SHA-256 FILE HASH')),
                              DataColumn(label: Text('CANONICAL PARQUET')),
                              DataColumn(label: Text('EVENT TIME')),
                              DataColumn(label: Text('INGESTION TIME')),
                              DataColumn(label: Text('LATENCY')),
                              DataColumn(label: Text('STATUS')),
                              DataColumn(label: Text('ACTIONS (POP-UP / VIEW)')),
                            ],
                            rows: pageItems.map((item) {
                              final flag = item.qualityFlag;
                              Color flagColor;
                              if (flag == 'NOMINAL') {
                                flagColor = AppColors.success;
                              } else if (flag.startsWith('DEGRADED_')) {
                                flagColor = AppColors.warning;
                              } else if (flag.startsWith('DATA_LOSS_')) {
                                flagColor = const Color(0xFFF97316);
                              } else if (flag == 'SENSOR_FLATLINE') {
                                flagColor = const Color(0xFFA855F7);
                              } else {
                                flagColor = const Color(0xFFEF4444);
                              }
                              return DataRow(
                                cells: [
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.speed_rounded, size: 16, color: AppColors.primary),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text('TELEMETRY', style: AppTextStyles.monoSmall.copyWith(fontWeight: FontWeight.bold)),
                                    ],
                                  )),
                                  DataCell(Text('Cycle #${item.cycleId}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('${item.rawFileSha256.substring(0, 16)}...', style: AppTextStyles.monoSmall),
                                      const SizedBox(width: 4),
                                      InkWell(
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(text: item.rawFileSha256));
                                          Get.snackbar('Hash Copied', 'Copied full SHA-256 to clipboard', snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
                                        },
                                        borderRadius: BorderRadius.circular(4),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          child: Icon(Icons.copy_rounded, size: 13, color: AppColors.slate500),
                                        ),
                                      ),
                                    ],
                                  )),
                                  DataCell(Text(
                                    item.rawStoragePath.split('/').last,
                                    style: AppTextStyles.monoSmall.copyWith(fontSize: 11, color: AppColors.slate600),
                                  )),
                                  DataCell(Text(
                                    item.eventTime != null ? item.eventTime!.toIso8601String().replaceAll('T', ' ').substring(0, 19) : '-',
                                    style: AppTextStyles.monoSmall.copyWith(fontSize: 11, color: AppColors.slate700),
                                  )),
                                  DataCell(Text(
                                    item.ingestionTime.toIso8601String().replaceAll('T', ' ').substring(0, 19),
                                    style: AppTextStyles.monoSmall.copyWith(fontSize: 11, color: AppColors.slate700),
                                  )),
                                  DataCell(Tooltip(
                                    message: AppFormatters.formatTooltipDuration(item.processingLatencyMs),
                                    child: Text(AppFormatters.formatDurationMs(item.processingLatencyMs), style: AppTextStyles.monoSmall),
                                  )),
                                  DataCell(Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: flagColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: flagColor, width: 0.8),
                                    ),
                                    child: Text(
                                      item.qualityFlag,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: flagColor,
                                      ),
                                    ),
                                  )),
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Lightweight View JSON PopUp Action Button
                                      _TableActionButton(
                                        label: 'View JSON',
                                        icon: Icons.code_rounded,
                                        isPrimary: true,
                                        onTap: () => showDialog(
                                          context: context,
                                          barrierDismissible: true,
                                          builder: (_) => ForensicDetailDialog(item: item),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      // Lightweight Inspect Dossier Action Button
                                      _TableActionButton(
                                        label: 'Inspect',
                                        isPrimary: false,
                                        onTap: () => showDialog(
                                          context: context,
                                          barrierDismissible: true,
                                          builder: (_) => ForensicDetailDialog(item: item),
                                        ),
                                      ),
                                    ],
                                  )),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),

                  // Pagination Footer Navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing ${startIndex + 1} – $endIndex of $totalItems cycles',
                        style: const TextStyle(fontSize: 12, color: AppColors.slate600),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.first_page_rounded, size: 18),
                            tooltip: 'First Page',
                            onPressed: safePage > 0 ? () => setState(() => _currentPage = 0) : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded, size: 18),
                            tooltip: 'Previous Page',
                            onPressed: safePage > 0 ? () => setState(() => _currentPage = safePage - 1) : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'Page ${safePage + 1} of ${maxPage + 1}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded, size: 18),
                            tooltip: 'Next Page',
                            onPressed: safePage < maxPage ? () => setState(() => _currentPage = safePage + 1) : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.last_page_rounded, size: 18),
                            tooltip: 'Last Page',
                            onPressed: safePage < maxPage ? () => setState(() => _currentPage = maxPage) : null,
                          ),
                        ],
                      ),
                    ],
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

class _TableActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _TableActionButton({
    required this.label,
    this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? AppColors.slate900 : Colors.white,
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: isPrimary ? null : Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: isPrimary ? Colors.white : AppColors.slate700),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? Colors.white : AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? effectiveColor.withValues(alpha: 0.15) : AppColors.bgLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? effectiveColor : AppColors.borderLight,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? effectiveColor : AppColors.slate700,
          ),
        ),
      ),
    );
  }
}
