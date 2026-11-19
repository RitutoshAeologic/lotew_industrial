import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/responsive/responsive_controller.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../controllers/evidence_controller.dart';
import '../widgets/canonical_json_viewer.dart';
import '../widgets/live_forensic_card.dart';
import '../widgets/pdf_upload_card.dart';
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
            // Page Header with Title and Mode Switcher
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
                      Text('Industrial Evidence Ingestion Console', style: AppTextStyles.headingLarge),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Synchronized Documentary & High-Frequency Telemetry Ingestion for Rig: hydraulic_rig_01',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Mock Mode Toggle
                Obx(() => Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: controller.isMockMode.value ? AppColors.sensorTemp.withValues(alpha: 0.12) : AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: controller.isMockMode.value ? AppColors.sensorTemp : AppColors.success,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            controller.isMockMode.value ? Icons.offline_bolt_rounded : Icons.cloud_done_rounded,
                            size: 16,
                            color: controller.isMockMode.value ? AppColors.sensorTemp : AppColors.success,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            controller.isMockMode.value ? 'MOCK STANDALONE MODE' : 'LIVE API (localhost:8000)',
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
                    )),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Ingestion Mode Tab Switcher
            Obx(() {
              final activeTab = controller.activeTab.value;
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.cardLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: _ConsoleTabButton(
                        label: 'Documentary Evidence (PDF Inspection Reports)',
                        icon: Icons.picture_as_pdf_rounded,
                        isSelected: activeTab == 0,
                        onTap: () => controller.switchTab(0),
                      ),
                    ),
                    Expanded(
                      child: _ConsoleTabButton(
                        label: '17-Sensor Telemetry (60s Operational Cycles)',
                        icon: Icons.speed_rounded,
                        isSelected: activeTab == 1,
                        onTap: () => controller.switchTab(1),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: AppSpacing.lg),

            // Error Banner if any
            Obx(() {
              final error = controller.errorMessage.value;
              if (error == null) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(error, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
                      onPressed: () => controller.errorMessage.value = null,
                    ),
                  ],
                ),
              );
            }),

            // Responsive Layout: 2 Columns on Desktop, 1 Column on Tablet/Mobile
            Obx(() {
              final activeTab = controller.activeTab.value;
              final latest = controller.latestEvidence.value;

              final leftColumn = Column(
                children: [
                  activeTab == 0 ? const PdfUploadCard() : const TelemetrySimulatorCard(),
                  const SizedBox(height: AppSpacing.lg),
                  if (activeTab == 1)
                    TelemetryWaveformChart(
                      cycleId: controller.cycleId.value,
                      isSevereLeak: controller.cycleId.value >= 211,
                    )
                  else if (latest != null && latest.extractedText != null)
                    _ExtractedTextCard(text: latest.extractedText!),
                ],
              );

              final rightColumn = Column(
                children: [
                  if (latest != null) ...[
                    LiveForensicCard(evidence: latest),
                    const SizedBox(height: AppSpacing.lg),
                    CanonicalJsonViewer(data: latest.canonicalData),
                  ] else
                    _EmptyEvidencePlaceholder(),
                ],
              );

              if (rc.isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: leftColumn),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(flex: 6, child: rightColumn),
                  ],
                );
              } else {
                return Column(
                  children: [
                    leftColumn,
                    const SizedBox(height: AppSpacing.lg),
                    rightColumn,
                  ],
                );
              }
            }),

            const SizedBox(height: AppSpacing.xl),

            // Ingested Evidence Stream History (Forensic Audit Trail)
            _EvidenceHistoryTable(),
          ],
        ),
      ),
    );
  }
}

class _ConsoleTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConsoleTabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
              color: isSelected ? AppColors.primary : AppColors.slate600,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.headingSmall.copyWith(
                fontSize: 13,
                color: isSelected ? Colors.white : AppColors.slate600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExtractedTextCard extends StatelessWidget {
  final String text;

  const _ExtractedTextCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.text_snippet_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('Extracted Document Content (OCR / Parsed)', style: AppTextStyles.headingSmall),
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
                border: Border.all(color: AppColors.borderLight),
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

class _EmptyEvidencePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: 480,
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_outlined, size: 64, color: AppColors.slate300),
            const SizedBox(height: AppSpacing.md),
            Text('No Evidence Stream Selected', style: AppTextStyles.headingMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Upload a PDF inspection report or ingest a 60s telemetry cycle on the left to inspect its cryptographic SHA-256 hash, millisecond timestamps, and canonical observation structure.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EvidenceHistoryTable extends StatelessWidget {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.history_rounded, size: 20, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          'Machine Timeline: Ingested Evidence Stream History',
                          style: AppTextStyles.headingSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Obx(() => Text(
                      '${controller.evidenceHistory.length} Total Registered Records',
                      style: AppTextStyles.bodySmall,
                    )),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Obx(() {
              final items = controller.evidenceHistory;
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: Text('No evidence recorded yet.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = controller.latestEvidence.value?.id == item.id;

                  return ListTile(
                    dense: true,
                    selected: isSelected,
                    selectedTileColor: AppColors.primaryLight.withValues(alpha: 0.3),
                    onTap: () => controller.selectEvidence(item),
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: item.isPdf ? AppColors.sensorTemp.withValues(alpha: 0.15) : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        item.isPdf ? Icons.picture_as_pdf_rounded : Icons.speed_rounded,
                        size: 16,
                        color: item.isPdf ? AppColors.sensorTemp : AppColors.primaryDark,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(item.rawFileName, style: AppTextStyles.headingSmall.copyWith(fontSize: 13)),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.qualityFlag == 'NOMINAL' ? AppColors.success.withValues(alpha: 0.12) : AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.qualityFlag,
                            style: AppTextStyles.monoSmall.copyWith(
                              fontSize: 10,
                              color: item.qualityFlag == 'NOMINAL' ? AppColors.success : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      'SHA-256: ${item.rawFileSha256.substring(0, 16)}... • Proc Latency: ${item.processingLatencyMs?.toStringAsFixed(1) ?? "-"} ms',
                      style: AppTextStyles.monoSmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    trailing: Text(
                      item.eventTime != null ? item.eventTime!.toIso8601String().substring(0, 19) : 'Unrecorded',
                      style: AppTextStyles.monoSmall.copyWith(fontSize: 11),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
