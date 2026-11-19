import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../controllers/evidence_controller.dart';

class CsvUploadCard extends StatelessWidget {
  const CsvUploadCard({super.key});

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
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.table_chart_rounded, color: AppColors.success),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Continuous CSV Telemetry Ingestion', style: AppTextStyles.headingSmall),
                      Text(
                        'Upload multi-channel sensor logs (Metro do Porto compressor, SCANIA fleet, SCADA CSVs)',
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

            // Drop zone / CSV File Picker
            Obx(() {
              final fileName = controller.pickedCsvName.value;
              final fileSize = controller.pickedCsvSizeBytes.value;
              final fileError = controller.csvFileError.value;

              if (fileName == null) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: controller.pickCsvFile,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: fileError != null ? AppColors.error.withValues(alpha: 0.04) : AppColors.bgLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: fileError != null ? AppColors.error : AppColors.borderLight,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.file_upload_outlined,
                              size: 42,
                              color: fileError != null ? AppColors.error : AppColors.slate600,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text('Click to Browse or Choose CSV Telemetry File', style: AppTextStyles.headingSmall),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              'Supports continuous timestamped CSV logs (MetroPT, SCANIA, etc.) up to 50 MB',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (fileError != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        fileError,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.error, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                );
              }

              final kb = (fileSize / 1024).toStringAsFixed(1);
              final mb = (fileSize / (1024 * 1024)).toStringAsFixed(2);
              final sizeDisplay = fileSize > 1024 * 1024 ? '$mb MB' : '$kb KB';

              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.table_chart_rounded, color: AppColors.success, size: 28),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fileName, style: AppTextStyles.headingSmall, overflow: TextOverflow.ellipsis),
                          Text(
                            '$sizeDisplay • Ready for Polars Extraction & ZSTD Parquet Compression',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.slate600),
                      tooltip: 'Remove CSV',
                      onPressed: controller.clearSelectedCsv,
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: AppSpacing.lg),

            // Target Domain / Tenant Selector
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TARGET INDUSTRY DOMAIN (TENANT)', style: AppTextStyles.labelCaps),
                      const SizedBox(height: AppSpacing.xs),
                      Obx(() => DropdownButtonFormField<String>(
                            initialValue: controller.selectedTenant.value,
                            isExpanded: true,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: AppConstants.tenants
                                .map((t) => DropdownMenuItem(
                                      value: t['id'],
                                      child: Text(t['name']!, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) controller.selectedTenant.value = val;
                            },
                          )),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ASSET IDENTIFIER', style: AppTextStyles.labelCaps),
                      const SizedBox(height: AppSpacing.xs),
                      Obx(() => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.borderLight),
                              borderRadius: BorderRadius.circular(8),
                              color: AppColors.bgLight,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(controller.selectedAsset.value, style: AppTextStyles.monoSmall),
                                const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.slate600),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Ingest CSV Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Obx(() {
                final isUploading = controller.isUploading.value;
                return ElevatedButton(
                  onPressed: isUploading ? null : controller.uploadCsv,
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
                            Text('Parsing CSV with Polars & Compressing to Parquet...', style: TextStyle(color: Colors.white)),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.compress_rounded, color: AppColors.success),
                            SizedBox(width: AppSpacing.xs),
                            Text(
                              'Ingest CSV Telemetry & Convert to Canonical Parquet',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
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

