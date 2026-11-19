import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/responsive/responsive_controller.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_scaffold.dart';
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

            const SizedBox(height: AppSpacing.lg),

            // Ingestion Mode (Focused strictly on 17-Sensor Hydraulic Rig)
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderLight),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _ConsoleTabButton(
                      label: '17-Sensor Hydraulic Rig Stream',
                      badge: 'PRIMARY DEMO • 100 Hz',
                      tooltip: 'Discrete 60-second machine cycles from UCI Hydraulic Test Bench across 17 synchronized sensors (PS1..PS6, FS1..FS2, TS1..TS4, etc.).',
                      icon: Icons.speed_rounded,
                      isSelected: true,
                      activeColor: AppColors.primary,
                      onTap: () {},
                    ),
                  ),
                  /*
                  // CSV and PDF tabs temporarily commented out for focused QA experience
                  Expanded(
                    child: _ConsoleTabButton(
                      label: 'Continuous Fleet Logs (CSV)',
                      badge: 'Roadmap • MetroPT / SCANIA',
                      tooltip: 'Secondary continuous multi-sensor CSV streams for Metro do Porto train compressor & SCANIA heavy fleet (Phase 2 Roadmap).',
                      icon: Icons.table_chart_rounded,
                      isSelected: activeTab == 1,
                      activeColor: AppColors.slate600,
                      onTap: () => controller.switchTab(1),
                    ),
                  ),
                  Expanded(
                    child: _ConsoleTabButton(
                      label: 'Documentary Evidence (PDF)',
                      badge: 'Multimodal • SHA-256',
                      tooltip: 'Field technician maintenance records and work orders with PDF text extraction and cryptographic SHA-256 fingerprinting.',
                      icon: Icons.picture_as_pdf_rounded,
                      isSelected: activeTab == 2,
                      activeColor: AppColors.sensorTemp,
                      onTap: () => controller.switchTab(2),
                    ),
                  ),
                  */
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Responsive Layout: Ingestion Card on Left, Live Inspector on Right
            Obx(() {
              final latestTelemetry = controller.latestTelemetryEvidence.value;

              // Only 17-Sensor Hydraulic Rig Telemetry is active
              Widget rightColumn;
              if (latestTelemetry != null) {
                rightColumn = Column(
                  children: [
                    LiveForensicCard(evidence: latestTelemetry),
                    const SizedBox(height: AppSpacing.lg),
                    TelemetryWaveformChart(
                      cycleId: controller.cycleId.value,
                      isSevereLeak: controller.cycleId.value >= 211,
                      evidence: latestTelemetry,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    CanonicalJsonViewer(data: latestTelemetry.canonicalData),
                  ],
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

class _ConsoleTabButton extends StatelessWidget {
  final String label;
  final String badge;
  final String tooltip;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _ConsoleTabButton({
    required this.label,
    required this.badge,
    required this.tooltip,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 250),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: activeColor.withValues(alpha: 0.08),
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
                Obx(() => Text(
                      '${controller.evidenceHistory.where((e) => e.isTelemetry).length} Telemetry Cycles',
                      style: AppTextStyles.monoSmall.copyWith(color: AppColors.textSecondary),
                    )),
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
