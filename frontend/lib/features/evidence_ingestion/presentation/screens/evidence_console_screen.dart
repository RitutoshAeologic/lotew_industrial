import 'package:flutter/material.dart';
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
// import '../widgets/csv_upload_card.dart';
import '../widgets/live_forensic_card.dart';
// import '../widgets/pdf_upload_card.dart';
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
                      Row(
                        children: [
                          Text('Industrial Evidence Ingestion Console', style: AppTextStyles.headingLarge),
                          const SizedBox(width: AppSpacing.sm),
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
                    const SizedBox(width: AppSpacing.md),

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

            // Responsive Layout: Ingestion Card on Left, Live Inspector on Right
            Obx(() {
              final latestTelemetry = controller.latestTelemetryEvidence.value;
              final isStreaming = controller.isStreamingLiveCycle.value;
              final isUploading = controller.isUploading.value;

              // Only 17-Sensor Hydraulic Rig Telemetry is active
              Widget rightColumn;
              if (isUploading) {
                rightColumn = _SealingUploadCard(
                  cycleId: controller.cycleId.value,
                  isSequential: controller.isSequentialMode.value,
                  currentStep: controller.sequentialCurrentCycle.value,
                  totalSteps: controller.sequentialTargetCycle.value,
                );
              } else if (isStreaming) {
                rightColumn = _StreamingLiveMonitorCard(
                  cycleId: controller.cycleId.value,
                  phase: controller.currentLivePhase.value,
                  elapsed: controller.streamElapsedSeconds.value,
                  pressure: controller.currentLivePressure.value,
                  flow: controller.currentLiveFlow.value,
                  isSequential: controller.isSequentialMode.value,
                  currentStep: controller.sequentialCurrentCycle.value,
                  totalSteps: controller.sequentialTargetCycle.value,
                );
              } else if (latestTelemetry != null) {
                final selectedTab = controller.inspectionTab.value;
                rightColumn = Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encapsulated Header Bar: Verdict + Key Metrics + Retest
                      _InspectionHeader(
                        evidence: latestTelemetry,
                        cycleId: controller.cycleId.value,
                        onRetest: controller.resetRetestSession,
                      ),
                      const Divider(height: 1),

                      // Segmented Inspection Tabs
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                        color: AppColors.bgLight,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _InspectionSegmentButton(
                                label: 'Waveforms & Dynamics',
                                icon: Icons.show_chart_rounded,
                                isSelected: selectedTab == 0,
                                onTap: () => controller.setInspectionTab(0),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              _InspectionSegmentButton(
                                label: 'Cryptographic Ledger & Audit',
                                icon: Icons.verified_user_rounded,
                                isSelected: selectedTab == 1,
                                onTap: () => controller.setInspectionTab(1),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              _InspectionSegmentButton(
                                label: 'Canonical Observation JSON',
                                icon: Icons.code_rounded,
                                isSelected: selectedTab == 2,
                                onTap: () => controller.setInspectionTab(2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1),

                      // Encapsulated Content Body
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: selectedTab == 0
                            ? TelemetryWaveformChart(
                                cycleId: controller.cycleId.value,
                                isSevereLeak: controller.cycleId.value >= 211,
                                evidence: latestTelemetry,
                              )
                            : (selectedTab == 1
                                ? LiveForensicCard(evidence: latestTelemetry)
                                : CanonicalJsonViewer(data: latestTelemetry.canonicalData)),
                      ),
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

              /*
              // CSV and PDF inspection cards temporarily commented out
              if (activeTab == 1) {
                // CSV Inspection
                if (latestCsv != null) { ... }
              } else if (activeTab == 2) {
                // PDF Inspection
                if (latestPdf != null) { ... }
              }
              */

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
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          )
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
    final progress = (elapsed / 60.0).clamp(0.0, 1.0);
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
                      isSequential
                          ? 'CONTINUOUS RUN • CYCLE #$cycleId OF #$totalSteps'
                          : 'PHYSICAL TEST RIG EXECUTION • CYCLE #$cycleId',
                      style: AppTextStyles.labelCaps.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  isSequential
                      ? '${elapsed}s/60s (Batch $currentStep/$totalSteps)'
                      : '${elapsed}s / 60s (${(progress * 100).toInt()}%)',
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
                  Text('ACTIVE STROKE PHASE:', style: AppTextStyles.labelCaps.copyWith(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text(phase, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  const Divider(color: Colors.white24, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('PS1 Pressure', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            '${pressure.toStringAsFixed(1)} bar',
                            style: const TextStyle(color: AppColors.sensorPressure, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 30, color: Colors.white24),
                      Column(
                        children: [
                          const Text('FS1 Flow Rate', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            '${flow.toStringAsFixed(1)} L/min',
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
                    'Streaming 43,680 data points across 17 synchronized channels. Automatic Parquet sealing will trigger at 60s.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

class _EvidenceHistoryTable extends StatelessWidget {
  const _EvidenceHistoryTable();

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
