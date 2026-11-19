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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primaryDark),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Documentary Evidence Ingestion', style: AppTextStyles.headingSmall),
                      Text('Technician reports, maintenance logs, or repair invoices (PDF)', style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis),
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

              if (fileName == null) {
                return InkWell(
                  onTap: controller.pickPdfFile,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.bgLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderLight, width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.slate600),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Click to Browse or Drag & Drop PDF', style: AppTextStyles.headingSmall),
                        const SizedBox(height: AppSpacing.xxs),
                        Text('Supports standard inspection PDF documents up to 50MB', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                );
              }

              final kb = (fileSize / 1024).toStringAsFixed(1);
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description_rounded, color: AppColors.primaryDark),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fileName, style: AppTextStyles.headingSmall, overflow: TextOverflow.ellipsis),
                          Text('$kb KB • Ready for SHA-256 Hashing', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.slate600),
                      onPressed: controller.clearSelectedPdf,
                      tooltip: 'Remove selected file',
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: AppSpacing.lg),

            // Metadata Form
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TARGET ASSET', style: AppTextStyles.labelCaps),
                      const SizedBox(height: AppSpacing.xs),
                      Obx(() => DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: controller.selectedAsset.value,
                            items: const [
                              DropdownMenuItem(value: 'hydraulic_rig_01', child: Text('hydraulic_rig_01', overflow: TextOverflow.ellipsis)),
                            ],
                            onChanged: (val) {
                              if (val != null) controller.selectedAsset.value = val;
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
                      Text('COMPONENT AFFECTED', style: AppTextStyles.labelCaps),
                      const SizedBox(height: AppSpacing.xs),
                      Obx(() => DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: controller.selectedComponent.value,
                            items: AppConstants.hydraulicComponents
                                .map((c) => DropdownMenuItem(value: c['id'], child: Text(c['name']!, overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) controller.selectedComponent.value = val;
                            },
                          )),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PROPOSED OPERATIONAL ACTION', style: AppTextStyles.labelCaps),
                      const SizedBox(height: AppSpacing.xs),
                      Obx(() => DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: controller.selectedAction.value,
                            items: AppConstants.proposedActions
                                .map((a) => DropdownMenuItem(value: a, child: Text(a, overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) controller.selectedAction.value = val;
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
                      Text('INCIDENT / INSPECTION DATE', style: AppTextStyles.labelCaps),
                      const SizedBox(height: AppSpacing.xs),
                      Obx(() {
                        final formatted = DateFormat('yyyy-MM-dd HH:mm').format(controller.incidentDate.value);
                        return InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: controller.incidentDate.value,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              controller.incidentDate.value = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                controller.incidentDate.value.hour,
                                controller.incidentDate.value.minute,
                              );
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                            ),
                            child: Text(formatted, style: AppTextStyles.bodyMedium),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            Text('INSPECTION NOTES / SUMMARY', style: AppTextStyles.labelCaps),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: controller.notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. Pump seal inspection completed on site. Slight discolouration detected on secondary seal ring.',
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Ingest Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: Obx(() {
                final isUploading = controller.isUploading.value;
                return ElevatedButton(
                  onPressed: isUploading ? null : controller.uploadPdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.slate900,
                  ),
                  child: isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: Text(
                                'Compute SHA-256 & Ingest to Evidence Backbone',
                                style: AppTextStyles.headingSmall.copyWith(color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
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
