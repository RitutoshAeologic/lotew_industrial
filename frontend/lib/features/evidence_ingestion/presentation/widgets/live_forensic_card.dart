import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/models/evidence_item_model.dart';

class LiveForensicCard extends StatelessWidget {
  final EvidenceItemModel evidence;

  const LiveForensicCard({super.key, required this.evidence});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: evidence.isPdf ? AppColors.sensorTemp.withValues(alpha: 0.15) : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            evidence.isPdf ? Icons.picture_as_pdf_rounded : Icons.sensors_rounded,
                            size: 16,
                            color: evidence.isPdf ? AppColors.sensorTemp : AppColors.primaryDark,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            evidence.evidenceType,
                            style: AppTextStyles.monoSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: evidence.isPdf ? AppColors.sensorTemp : AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Tooltip(
                      message: 'Quality Flag: ${evidence.qualityFlag}\n${evidence.qualityFlag == "NOMINAL" ? "All sensor channels within physical operating envelope." : "Data degraded or out-of-spec readings detected."}',
                      waitDuration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: evidence.qualityFlag == 'NOMINAL' ? AppColors.success.withValues(alpha: 0.15) : AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          evidence.qualityFlag,
                          style: AppTextStyles.monoSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: evidence.qualityFlag == 'NOMINAL' ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    'Tenant: ${evidence.tenantId} • Asset: ${evidence.assetId}',
                    style: AppTextStyles.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            // SHA-256 Cryptographic Hash Badge
            Text('CRYPTOGRAPHIC SHA-256 FILE HASH (TAMPER AUDIT)', style: AppTextStyles.labelCaps),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.hashBadgeBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fingerprint_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: SelectableText(
                      evidence.rawFileSha256,
                      style: AppTextStyles.monoHash,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white70),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: evidence.rawFileSha256));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('SHA-256 Hash copied to clipboard')),
                      );
                    },
                    tooltip: 'Copy full hash',
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Database UUID & Storage Path
            Row(
              children: [
                Expanded(
                  child: _ForensicMetaField(
                    label: 'DATABASE EVIDENCE ID (UUID)',
                    value: evidence.id,
                    isMono: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _ForensicMetaField(
                    label: 'SUPABASE STORAGE PATH',
                    value: evidence.rawStoragePath,
                    isMono: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // 3-Timestamp Forensic Breakdown (with Millisecond Precision)
            Text('3-TIMESTAMP RULE (STRICT FORENSIC TIMELINE WITH MILLISECOND RESOLUTION)', style: AppTextStyles.labelCaps),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  _TimestampRow(
                    label: 'T1: Event Time (Physical World)',
                    timeString: evidence.eventTime != null ? '${dateFormat.format(evidence.eventTime!)}Z' : 'NULL (Unrecorded Documentary Event)',
                    subtitle: evidence.isPdf ? 'Extracted from document / User input date' : 'Rig operational cycle physical timestamp',
                    icon: Icons.access_time_rounded,
                  ),
                  const Divider(height: AppSpacing.md),
                  _TimestampRow(
                    label: 'T2: Ingestion Time (API Gateway)',
                    timeString: '${dateFormat.format(evidence.ingestionTime)}Z',
                    subtitle: 'CLOCK_TIMESTAMP() when bytes arrived at Lotew API',
                    icon: Icons.input_rounded,
                  ),
                  const Divider(height: AppSpacing.md),
                  _TimestampRow(
                    label: 'T3: Available Time (Memory Commit)',
                    timeString: '${dateFormat.format(evidence.availableTime)}Z',
                    subtitle: 'CLOCK_TIMESTAMP() committed into evidence_streams',
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Latency Metrics
            Row(
              children: [
                Expanded(
                  child: _LatencyCard(
                    title: 'Ingestion Latency (T2 - T1)',
                    ms: evidence.ingestionLatencyMs,
                    description: 'Time elapsed between physical event and API arrival',
                    isBenchReplay: evidence.isTelemetry,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _LatencyCard(
                    title: 'Processing Latency (T3 - T2)',
                    ms: evidence.processingLatencyMs,
                    description: 'Time taken for SHA-256 hashing, Parquet & JSON parsing',
                    isBenchReplay: false,
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

class _ForensicMetaField extends StatelessWidget {
  final String label;
  final String value;
  final bool isMono;

  const _ForensicMetaField({
    required this.label,
    required this.value,
    this.isMono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelCaps),
        const SizedBox(height: AppSpacing.xs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.bgLight,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Expanded(
                child: Tooltip(
                  message: value,
                  waitDuration: const Duration(milliseconds: 200),
                  child: Text(
                    value,
                    style: isMono ? AppTextStyles.monoSmall : AppTextStyles.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Tooltip(
                message: 'Copy to clipboard',
                waitDuration: const Duration(milliseconds: 200),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied $label to clipboard', style: AppTextStyles.monoSmall.copyWith(color: Colors.white)),
                          duration: const Duration(milliseconds: 1500),
                          backgroundColor: AppColors.slate900,
                          behavior: SnackBarBehavior.floating,
                          width: 320,
                        ),
                      );
                    },
                    child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.slate600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimestampRow extends StatelessWidget {
  final String label;
  final String timeString;
  final String subtitle;
  final IconData icon;

  const _TimestampRow({
    required this.label,
    required this.timeString,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.headingSmall.copyWith(fontSize: 13)),
              Text(subtitle, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
            ],
          ),
        ),
        SelectableText(
          timeString,
          style: AppTextStyles.monoMedium.copyWith(fontSize: 13, color: AppColors.slate900),
        ),
      ],
    );
  }
}

class _LatencyCard extends StatelessWidget {
  final String title;
  final double? ms;
  final String description;
  final bool isBenchReplay;

  const _LatencyCard({
    required this.title,
    required this.ms,
    required this.description,
    this.isBenchReplay = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool showReplay = isBenchReplay || ms == null || (ms != null && ms! >= 86400000.0);
    final tooltipText = showReplay
        ? 'T1 is anchored to physical test bench run (2024). In live IoT production with real edge gateways, T2 - T1 represents physical edge-to-cloud transmission latency (~12-45 ms). For historical bench replay, physical transmission latency is N/A.'
        : AppFormatters.formatTooltipDuration(ms);

    return Tooltip(
      message: tooltipText,
      waitDuration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.bgLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.labelCaps),
            const SizedBox(height: AppSpacing.xs),
            if (showReplay)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'N/A',
                    style: AppTextStyles.monoLarge.copyWith(
                      color: AppColors.slate700,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'BENCH REPLAY',
                      style: AppTextStyles.monoSmall.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              )
            else
              Text(
                AppFormatters.formatDurationMs(ms),
                style: AppTextStyles.monoLarge.copyWith(
                  color: AppColors.primaryDark,
                  fontSize: 20,
                ),
              ),
            const SizedBox(height: 2),
            Text(
              showReplay
                  ? 'Historical dataset replay (UCI Rig Anchor: 2024) • Live edge latency ~15-45 ms'
                  : description,
              style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
