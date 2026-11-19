import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../controllers/evidence_controller.dart';

class PdfUploadCard extends StatelessWidget {
  const PdfUploadCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = EvidenceController.to;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

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
                    color: AppColors.sensorTemp.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.sensorTemp),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Documentary Evidence Ingestion', style: AppTextStyles.headingSmall),
                      Text(
                        'Upload human engineering inspection reports, maintenance logs, or repair invoices',
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

            // Drop zone / File Picker
            Obx(() {
              final fileName = controller.pickedPdfName.value;
              final fileSize = controller.pickedPdfSizeBytes.value;
              final fileError = controller.pdfFileError.value;

              if (fileName == null) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tooltip(
                      message: 'Click or drop official technician inspection or repair work order PDF up to 25 MB',
                      waitDuration: const Duration(milliseconds: 200),
                      child: InkWell(
                        onTap: controller.pickPdfFile,
                        borderRadius: BorderRadius.circular(10),
                        hoverColor: AppColors.sensorTemp.withValues(alpha: 0.05),
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
                                Icons.cloud_upload_outlined,
                                size: 42,
                                color: fileError != null ? AppColors.error : AppColors.slate600,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text('Click to Browse or Choose PDF Document', style: AppTextStyles.headingSmall),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                'Supports official inspection PDF documents up to 25 MB',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
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
                  color: AppColors.sensorTemp.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.sensorTemp.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, color: AppColors.sensorTemp, size: 28),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fileName, style: AppTextStyles.headingSmall, overflow: TextOverflow.ellipsis),
                          Text(
                            '$sizeDisplay • Validated for Cryptographic SHA-256 Hashing',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.slate600),
                      tooltip: 'Remove file',
                      onPressed: controller.clearSelectedPdf,
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: AppSpacing.lg),

            // Form Fields: Component & Incident Date
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TARGET RIG COMPONENT', style: AppTextStyles.labelCaps),
                      const SizedBox(height: AppSpacing.xs),
                      Obx(() => DropdownButtonFormField<String>(
                            initialValue: controller.selectedComponent.value,
                            isExpanded: true,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: AppConstants.hydraulicComponents
                                .map((c) => DropdownMenuItem(
                                      value: c['id'],
                                      child: Text(c['name']!, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) controller.selectedComponent.value = val;
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
                      Text('INCIDENT RECORD DATE', style: AppTextStyles.labelCaps),
                      const SizedBox(height: AppSpacing.xs),
                      Obx(() => InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: controller.incidentDate.value,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(), // Enforce: cannot be future date
                              );
                              if (picked != null) {
                                controller.setIncidentDate(picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.borderLight),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dateFormat.format(controller.incidentDate.value),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.slate600),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Proposed Action Dropdown
            Text('TECHNICIAN PROPOSED ACTION', style: AppTextStyles.labelCaps),
            const SizedBox(height: AppSpacing.xs),
            Obx(() => DropdownButtonFormField<String>(
                  initialValue: controller.selectedAction.value,
                  isExpanded: true,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: AppConstants.proposedActions
                      .map((a) => DropdownMenuItem(
                            value: a,
                            child: Text(a, style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) controller.selectedAction.value = val;
                  },
                )),

            const SizedBox(height: AppSpacing.md),

            // Technician Notes
            Text('ENGINEERING COMMENTARY & REPAIR LOG', style: AppTextStyles.labelCaps),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: controller.notesController,
              maxLines: 2,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'e.g. Unusual audible cavitation observed during hold pressure phase...',
                hintStyle: AppTextStyles.bodySmall,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Ingest Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Obx(() {
                final isUploading = controller.isUploading.value;
                final hasFile = controller.pickedPdfBytes.value != null;
                return Tooltip(
                  message: hasFile
                      ? 'Upload PDF to FastAPI: extracts text via pypdf, computes SHA-256 fingerprint, stores binary in Supabase Object Storage, and commits to ledger'
                      : 'Please select a valid PDF file to upload',
                  waitDuration: const Duration(milliseconds: 200),
                  child: ElevatedButton(
                    onPressed: (isUploading || !hasFile) ? null : controller.uploadPdf,
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
                              Text('Extracting Text & Calculating SHA-256...', style: TextStyle(color: Colors.white)),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.fingerprint_rounded, color: AppColors.sensorTemp),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                'Ingest PDF Evidence & Register Fingerprint',
                                style: AppTextStyles.headingSmall.copyWith(color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
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
