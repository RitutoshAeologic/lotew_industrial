import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/models/evidence_item_model.dart';
import 'canonical_json_viewer.dart';

/// Modal dialog presenting the complete cryptographic forensic dossier
/// and Canonical Observation JSON for an ingested cycle.
class ForensicDetailDialog extends StatefulWidget {
  final EvidenceItemModel item;

  const ForensicDetailDialog({super.key, required this.item});

  @override
  State<ForensicDetailDialog> createState() => _ForensicDetailDialogState();
}

class _ForensicDetailDialogState extends State<ForensicDetailDialog> {
  int _activeTab = 0; // 0 = Canonical JSON, 1 = Cryptographic Proof, 2 = Sensor Measurements

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isNominal = item.qualityFlag == 'NOMINAL';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: 900,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        item.isTelemetry ? 'Telemetry Cycle #${item.cycleId} Forensic Dossier' : 'Documentary Evidence Dossier',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isNominal ? AppColors.success.withValues(alpha: 0.2) : AppColors.warning.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isNominal ? AppColors.success : AppColors.warning),
                        ),
                        child: Text(
                          item.qualityFlag,
                          style: TextStyle(
                            color: isNominal ? AppColors.success : AppColors.warning,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Tab Switcher
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
              color: AppColors.bgLight,
              child: Row(
                children: [
                  _TabButton(
                    label: 'Canonical Observation JSON',
                    icon: Icons.code_rounded,
                    isSelected: _activeTab == 0,
                    onTap: () => setState(() => _activeTab = 0),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _TabButton(
                    label: 'Cryptographic Ledger Proof',
                    icon: Icons.shield_rounded,
                    isSelected: _activeTab == 1,
                    onTap: () => setState(() => _activeTab = 1),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _TabButton(
                    label: '17-Sensor Physical Readings',
                    icon: Icons.speed_rounded,
                    isSelected: _activeTab == 2,
                    onTap: () => setState(() => _activeTab = 2),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _buildTabContent(item),
              ),
            ),

            // Footer
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              color: AppColors.bgLight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SHA-256: ${item.rawFileSha256.substring(0, 24)}...',
                    style: AppTextStyles.monoSmall.copyWith(color: AppColors.slate600),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.slate800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(EvidenceItemModel item) {
    switch (_activeTab) {
      case 0:
        return CanonicalJsonViewer(data: item.canonicalData);
      case 1:
        return _buildCryptographicProofTab(item);
      case 2:
        return _buildSensorsTab(item);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCryptographicProofTab(EvidenceItemModel item) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SHA-256 Box
          Text('CRYPTOGRAPHIC SHA-256 TAMPER-PROOF HASH', style: AppTextStyles.labelCaps),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.slate900,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.fingerprint_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SelectableText(
                    item.rawFileSha256,
                    style: AppTextStyles.monoSmall.copyWith(color: AppColors.primary, fontSize: 13),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: item.rawFileSha256));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('SHA-256 Hash copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Database & Storage IDs
          Row(
            children: [
              Expanded(
                child: _ForensicField(
                  label: 'DATABASE EVIDENCE ID (UUID)',
                  value: item.id,
                  icon: Icons.tag_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ForensicField(
                  label: 'SUPABASE STORAGE PATH',
                  value: item.rawStoragePath,
                  icon: Icons.cloud_done_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 3-Timestamp Rule
          Text('3-TIMESTAMP RULE FORENSIC BREAKDOWN', style: AppTextStyles.labelCaps),
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
                _TimestampTile(
                  label: 'T1: Physical Machine Execution Time',
                  value: item.eventTime != null ? '${item.eventTime!.toIso8601String()}Z' : 'N/A',
                  description: 'Deterministic 60-second cycle execution timestamp',
                ),
                const Divider(height: AppSpacing.md),
                _TimestampTile(
                  label: 'T2: Ingestion Time (API Gateway)',
                  value: '${item.ingestionTime.toIso8601String()}Z',
                  description: 'CLOCK_TIMESTAMP() when bytes arrived at API',
                ),
                const Divider(height: AppSpacing.md),
                _TimestampTile(
                  label: 'T3: Available Time (Memory & Database Commit)',
                  value: '${item.availableTime.toIso8601String()}Z',
                  description: 'Committed into industrial.evidence_streams',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Latency metrics
          Row(
            children: [
              Expanded(
                child: _LatencyBox(
                  label: 'Ingestion Latency (T2 - T1)',
                  // PREVIOUS VULNERABLE DIRECT DISPLAY:
                  // value: item.ingestionLatencyMs != null ? '${item.ingestionLatencyMs!.toStringAsFixed(1)} ms' : 'Historical Replay',
                  value: (item.isTelemetry || item.ingestionLatencyMs == null || item.ingestionLatencyMs! >= 86400000.0)
                      ? 'N/A (Bench Replay)'
                      : AppFormatters.formatDurationMs(item.ingestionLatencyMs),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _LatencyBox(
                  label: 'Processing Latency (T3 - T2)',
                  // PREVIOUS:
                  // value: item.processingLatencyMs != null ? '${item.processingLatencyMs!.toStringAsFixed(2)} ms' : 'N/A',
                  value: AppFormatters.formatDurationMs(item.processingLatencyMs),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSensorsTab(EvidenceItemModel item) {
    final measurements = item.canonicalData['measurements'] as Map<String, dynamic>?;
    final components = measurements?['components'] as Map<String, dynamic>?;

    if (components == null || components.isEmpty) {
      return Center(
        child: Text('No component sensor measurements available for this record.', style: AppTextStyles.bodyMedium),
      );
    }

    final List<Map<String, dynamic>> sensorRows = [];
    components.forEach((compName, sensorMap) {
      if (sensorMap is Map<String, dynamic>) {
        sensorMap.forEach((sensorId, stats) {
          if (stats is Map<String, dynamic>) {
            sensorRows.add({
              'component': compName,
              'sensor': sensorId,
              'rate_hz': stats['rate_hz'] ?? 1,
              'unit': stats['unit'] ?? '',
              'median': stats['median'] ?? 0.0,
              'mad': stats['mad'] ?? 0.0,
              'min': stats['min'] ?? 0.0,
              'max': stats['max'] ?? 0.0,
              'samples': stats['samples_count'] ?? 0,
            });
          }
        });
      }
    });

    return SingleChildScrollView(
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppColors.bgLight),
        columns: const [
          DataColumn(label: Text('COMPONENT')),
          DataColumn(label: Text('SENSOR')),
          DataColumn(label: Text('RATE')),
          DataColumn(label: Text('MEDIAN')),
          DataColumn(label: Text('MAD')),
          DataColumn(label: Text('MIN')),
          DataColumn(label: Text('MAX')),
          DataColumn(label: Text('UNIT')),
          DataColumn(label: Text('SAMPLES')),
        ],
        rows: sensorRows.map((s) {
          return DataRow(cells: [
            DataCell(Text(s['component'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(s['sensor'].toString(), style: AppTextStyles.monoSmall)),
            DataCell(Text('${s['rate_hz']} Hz')),
            DataCell(Text(s['median'].toString())),
            DataCell(Text(s['mad'].toString())),
            DataCell(Text(s['min'].toString())),
            DataCell(Text(s['max'].toString())),
            DataCell(Text(s['unit'].toString())),
            DataCell(Text(s['samples'].toString())),
          ]);
        }).toList(),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected ? Border.all(color: AppColors.borderLight) : null,
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.primary : AppColors.slate600),
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

class _ForensicField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ForensicField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.slate600),
              const SizedBox(width: 4),
              Text(label, style: AppTextStyles.labelCaps),
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: AppTextStyles.monoSmall.copyWith(color: AppColors.slate800),
          ),
        ],
      ),
    );
  }
}

class _TimestampTile extends StatelessWidget {
  final String label;
  final String value;
  final String description;

  const _TimestampTile({
    required this.label,
    required this.value,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(description, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
          ],
        ),
        SelectableText(value, style: AppTextStyles.monoSmall.copyWith(color: AppColors.primaryDark)),
      ],
    );
  }
}

class _LatencyBox extends StatelessWidget {
  final String label;
  final String value;

  const _LatencyBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelCaps),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.monoLarge.copyWith(fontSize: 16, color: AppColors.primaryDark)),
        ],
      ),
    );
  }
}
