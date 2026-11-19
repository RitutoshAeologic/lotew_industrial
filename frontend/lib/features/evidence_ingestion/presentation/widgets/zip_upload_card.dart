import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../controllers/evidence_controller.dart';

class ZipUploadCard extends StatelessWidget {
  const ZipUploadCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = EvidenceController.to;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Architectural Callout Banner (Approach B)
        Tooltip(
          message: 'Direct HTTP Multipart Stream: Large ZIP archive streams directly to backend without client-side unzipping, preventing browser memory leaks and crashes on large datasets (500MB+).',
          waitDuration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.bolt_rounded, size: 20, color: AppColors.primaryDark),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Approach B: Direct HTTP Streaming (Zero Browser Parsing)',
                        style: AppTextStyles.labelCaps.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Raw 17-sensor ZIP archive streams directly to FastAPI backend without client-side decompression or JS memory overhead. Backend extracts files to mounted rig storage and verifies cryptographic SHA-256.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.slate700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Success Confirmation Banner (If previously mounted)
        Obx(() {
          final res = controller.zipUploadResult.value;
          if (res == null) return const SizedBox.shrink();

          final count = res['extracted_count'] ?? 17;
          final sha = (res['sha256'] as String?) ?? 'verified';
          final shaShort = sha.length > 20 ? '${sha.substring(0, 20)}...' : sha;

          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '17-Sensor Rig Package Mounted & Verified ($count Files)',
                        style: AppTextStyles.headingSmall.copyWith(
                          fontSize: 13,
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'SHA-256: $shaShort',
                        style: AppTextStyles.monoSmall.copyWith(fontSize: 11, color: AppColors.slate700),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    controller.isZipImportMode.value = false;
                    controller.zipUploadResult.value = null;
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('Return to Simulator', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }),

        // Upload Dropzone
        Obx(() {
          final hasFile = controller.pickedZipBytes.value != null;
          final fileName = controller.pickedZipName.value ?? '';
          final fileSizeMb = (controller.pickedZipSizeBytes.value / (1024 * 1024)).toStringAsFixed(1);

          if (!hasFile) {
            return Tooltip(
              message: 'Click or drop hydraulic_cycle_raw.zip archive containing all 17 sensors and profile.txt',
              waitDuration: const Duration(milliseconds: 250),
              child: InkWell(
                onTap: controller.isUploading.value ? null : controller.pickZipFile,
                borderRadius: BorderRadius.circular(10),
                hoverColor: AppColors.primary.withValues(alpha: 0.05),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.bgLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: controller.zipFileError.value != null ? AppColors.verdictAct : AppColors.borderLight,
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.archive_rounded, size: 36, color: AppColors.primary),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Select Raw 17-Sensor ZIP Package',
                        style: AppTextStyles.headingSmall.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'e.g. hydraulic_cycle_raw.zip (Max 500 MB)',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton.icon(
                        onPressed: controller.isUploading.value ? null : controller.pickZipFile,
                        icon: const Icon(Icons.file_upload_outlined, size: 18),
                        label: const Text('Browse ZIP Archive'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // File selected preview card
          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.folder_zip_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$fileSizeMb MB • Ready for Direct Stream Mounting',
                        style: AppTextStyles.monoSmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: 'Clear selected archive and pick another',
                  child: IconButton(
                    onPressed: controller.isUploading.value ? null : controller.clearSelectedZip,
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.slate600),
                  ),
                ),
              ],
            ),
          );
        }),

        // Error message if any
        Obx(() {
          final err = controller.zipFileError.value;
          if (err == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(err, style: const TextStyle(color: AppColors.verdictAct, fontSize: 12)),
          );
        }),

        const SizedBox(height: AppSpacing.lg),

        // Expected Sensor Manifest & Inventory
        Text('EXPECTED 17-SENSOR ARCHIVE MANIFEST', style: AppTextStyles.labelCaps),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.bgLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: const Column(
            children: [
              _ManifestRow(
                frequency: '100 Hz (6,000 pts/cycle)',
                count: '7 Sensors',
                sensors: 'PS1.txt, PS2.txt, PS3.txt, PS4.txt, PS5.txt, PS6.txt, EPS1.txt',
                color: AppColors.sensorPressure,
                description: 'High-frequency pressure transducers (PS1..PS6) sampling at 100 Hz to capture micro-second valve transitions, plus EPS1 electrical motor power.',
              ),
              Divider(height: 16),
              _ManifestRow(
                frequency: '10 Hz (600 pts/cycle)',
                count: '2 Sensors',
                sensors: 'FS1.txt, FS2.txt',
                color: AppColors.sensorFlow,
                description: 'Medium-frequency volume flow rate meters (FS1 primary loop & FS2 cooling loop) sampling at 10 Hz to quantify system leakage.',
              ),
              Divider(height: 16),
              _ManifestRow(
                frequency: '1 Hz (60 pts/cycle)',
                count: '8 Sensors',
                sensors: 'TS1.txt, TS2.txt, TS3.txt, TS4.txt, VS1.txt, CE.txt, CP.txt, SE.txt',
                color: AppColors.sensorTemp,
                description: 'Low-frequency condition sensors: 4 thermal probes (TS1..TS4), vibration sensor (VS1), cooler efficiency (CE), cooling power (CP), and efficiency factor (SE).',
              ),
              Divider(height: 16),
              _ManifestRow(
                frequency: 'Target Condition Labels',
                count: 'Target Data',
                sensors: 'profile.txt (Cooler, Valve, Pump, Accumulator degradation)',
                color: AppColors.slate700,
                description: 'Ground-truth degradation states for forensic verification: Cooler condition (3..100%), Valve lag (73..100%), Internal pump leakage (0..2), Accumulator pressure (90..130 bar).',
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Mount Action Button
        Obx(() {
          final isUploading = controller.isUploading.value;
          final hasFile = controller.pickedZipBytes.value != null;

          return Tooltip(
            message: hasFile
                ? 'Stream uploaded package to FastAPI backend; extracts and mounts to rig dataset volume'
                : 'Please select a valid .zip archive first',
            waitDuration: const Duration(milliseconds: 200),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (!hasFile || isUploading) ? null : controller.uploadRigZip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  disabledBackgroundColor: AppColors.borderLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isUploading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            'Streaming & Mounting 17 Sensors...',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 20),
                          SizedBox(width: AppSpacing.xs),
                          Text(
                            'Stream & Mount 17-Sensor Package to Rig',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ManifestRow extends StatelessWidget {
  final String frequency;
  final String count;
  final String sensors;
  final Color color;
  final String description;

  const _ManifestRow({
    required this.frequency,
    required this.count,
    required this.sensors,
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 4, right: AppSpacing.sm),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(frequency, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                      Text(count, style: const TextStyle(fontSize: 10, color: AppColors.slate600)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sensors,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.slate700),
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
