import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../evidence_ingestion/presentation/controllers/evidence_controller.dart';

class MachineTimelineScreen extends StatelessWidget {
  const MachineTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = EvidenceController.to;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

    return AppScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Physical Machine Chronological Timeline', style: AppTextStyles.headingLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Chronological Corroboration of Documentary & Telemetry Evidence for Asset: hydraulic_rig_01',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: controller.loadTimeline,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Refresh Timeline'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.slate900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.lg),

            Obx(() {
              final items = controller.evidenceHistory;
              if (items.isEmpty) {
                return Card(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    width: double.infinity,
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.hourglass_empty_rounded, size: 48, color: AppColors.slate300),
                          const SizedBox(height: AppSpacing.md),
                          Text('No Timeline Events Ingested Yet', style: AppTextStyles.headingMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text('Head to the Evidence Ingestion Console to upload a PDF or run telemetry cycles.', style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isLast = index == items.length - 1;

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timeline Bar & Node
                        SizedBox(
                          width: 48,
                          child: Column(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: item.isPdf ? AppColors.sensorTemp : AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (item.isPdf ? AppColors.sensorTemp : AppColors.primary).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  item.isPdf ? Icons.picture_as_pdf_rounded : Icons.sensors_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: AppColors.borderLight,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Timeline Event Content Card
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          item.isPdf ? 'DOCUMENTARY EVENT' : 'TELEMETRY CYCLE BATCH',
                                          style: AppTextStyles.labelCaps.copyWith(
                                            color: item.isPdf ? AppColors.sensorTemp : AppColors.primaryDark,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Text(item.rawFileName, style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
                                      ],
                                    ),
                                    Text(
                                      item.eventTime != null ? '${dateFormat.format(item.eventTime!)}Z' : 'Unrecorded Timestamp',
                                      style: AppTextStyles.monoSmall.copyWith(color: AppColors.slate600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'SHA-256: ${item.rawFileSha256} • Database ID: ${item.id}',
                                  style: AppTextStyles.monoSmall.copyWith(fontSize: 11, color: AppColors.slate500),
                                ),
                                if (item.extractedText != null) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  Container(
                                    padding: const EdgeInsets.all(AppSpacing.sm),
                                    decoration: BoxDecoration(
                                      color: AppColors.bgLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.extractedText!,
                                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
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
