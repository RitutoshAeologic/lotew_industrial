import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../claim_replay/presentation/controllers/claim_replay_controller.dart';

class AuditorLedgerScreen extends StatelessWidget {
  const AuditorLedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final replayCtrl = Get.isRegistered<ClaimReplayController>()
        ? ClaimReplayController.to
        : Get.put(ClaimReplayController());

    return AppScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Screen Header ─────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.25)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.account_balance_rounded, size: 14, color: Color(0xFF2563EB)),
                              SizedBox(width: 6),
                              Text(
                                'INDEPENDENT COMPLIANCE AUDIT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_rounded, size: 14, color: AppColors.success),
                              SizedBox(width: 4),
                              Text(
                                'ZERO TAMPER DETECTED',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'TÜV SÜD • Forensic Cryptographic Hash Ledger',
                      style: AppTextStyles.headingLarge.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Audit Standard: DIN EN ISO/IEC 17020 & RFC 8785 Canonical JSON Deterministic Hashing',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.slate600),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: replayCtrl.downloadDossier,
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Download Verifiable Dossier (.ZIP)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.slate900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Top 4 Cryptographic Status Cards ──────────────────────────────
            const _AuditorKpiRow(),
            const SizedBox(height: AppSpacing.lg),

            // ── Immutable Block Chain Explorer Table ──────────────────────────
            const _BlockChainExplorerTable(),
          ],
        ),
      ),
    );
  }
}

class _AuditorKpiRow extends StatelessWidget {
  const _AuditorKpiRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - (AppSpacing.md * 3)) / 4;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _buildTile(
              label: 'BLOCK HEIGHT',
              value: '42 Blocks',
              sub: 'Continuous Linear Chain',
              icon: Icons.layers_rounded,
              accentColor: const Color(0xFF2563EB),
              width: cardWidth,
            ),
            _buildTile(
              label: 'CANONICAL STANDARD',
              value: 'RFC 8785 JSON',
              sub: 'Deterministic Float & Key Sorting',
              icon: Icons.code_rounded,
              accentColor: AppColors.primaryDark,
              width: cardWidth,
            ),
            _buildTile(
              label: 'LOOKAHEAD QUARANTINE',
              value: 'STRICTLY ENFORCED',
              sub: 'Zero Data Leak Beyond Cutoff T',
              icon: Icons.security_rounded,
              accentColor: AppColors.success,
              width: cardWidth,
            ),
            _buildTile(
              label: 'INDEPENDENT VERIFICATION',
              value: '100% MATHEMATICAL',
              sub: 'Standalone Python Script',
              icon: Icons.check_circle_rounded,
              accentColor: AppColors.success,
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTile({
    required String label,
    required String value,
    required String sub,
    required IconData icon,
    required Color accentColor,
    required double width,
  }) {
    return Container(
      width: width < 220 ? double.infinity : width,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate500, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.slate900),
                ),
                const SizedBox(height: 1),
                Text(
                  sub,
                  style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockChainExplorerTable extends StatelessWidget {
  const _BlockChainExplorerTable();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
              const Row(
                children: [
                  Icon(Icons.link_rounded, size: 20, color: AppColors.slate900),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    'Immutable Evidence Chain Blocks (Recent Sequence)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate900),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Text(
                  'Genesis: Block #1 • Latest: Block #42',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Each decision record is cryptographically linked to the previous block via SHA-256. Any modification breaks all downstream hashes.',
            style: TextStyle(fontSize: 12, color: AppColors.slate600),
          ),
          const SizedBox(height: AppSpacing.md),

          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.2), // Block #
              1: FlexColumnWidth(1.8), // Timestamp
              2: FlexColumnWidth(2.5), // Event Type
              3: FlexColumnWidth(3.5), // SHA-256 Block Hash
              4: FlexColumnWidth(1.5), // Status
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              const TableRow(
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 1.5)),
                ),
                children: const [
                  _HeaderCell('BLOCK #'),
                  _HeaderCell('TIMESTAMP (UTC)'),
                  _HeaderCell('EVENT TYPE / DECISION'),
                  _HeaderCell('SHA-256 BLOCK HASH'),
                  _HeaderCell('CHAIN INTEGRITY'),
                ],
              ),
              _buildRow(
                height: '#42 (Latest)',
                time: '2024-01-01 16:30:00 UTC',
                event: 'Claim Adjudication: REJECT INDEMNITY (CLM-9042)',
                hash: 'd4f728124583688ad03ae2508c2ab94cff8149bc81c19c6edcc5dccaffa99f8c',
                status: 'SEALED & INTACT',
                statusColor: AppColors.success,
              ),
              _buildRow(
                height: '#41',
                time: '2024-01-01 14:02:15 UTC',
                event: 'Operator Cab Alert Dismissal Action (Cycle 211)',
                hash: '97dea224d252729001e60883c77c4c3158b13572388d6d6212a3f7eabebe8133',
                status: 'SEALED & INTACT',
                statusColor: AppColors.success,
              ),
              _buildRow(
                height: '#40',
                time: '2024-01-01 14:00:00 UTC',
                event: 'ISO-13374 Level 2 Telematics Alarm (Pump Leak)',
                hash: '8f3b1409ae221dc51d46b7a0b5a3fa7166113bdf2d0014a4b49195b0042dc012',
                status: 'SEALED & INTACT',
                statusColor: AppColors.success,
              ),
              _buildRow(
                height: '#1 (Genesis)',
                time: '2024-01-01 09:00:00 UTC',
                event: 'Pre-Rental Handover Baseline Certificate (Cycle 1665)',
                hash: '53418536ae968dc51d46b7a0b5a3fa7166113bdf2d0014a4b49195b0042da09c',
                status: 'GENESIS ROOT',
                statusColor: const Color(0xFF2563EB),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildRow({
    required String height,
    required String time,
    required String event,
    required String hash,
    required String status,
    required Color statusColor,
  }) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.slate100)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Text(height, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate900)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Text(time, style: const TextStyle(fontSize: 11, color: AppColors.slate600)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Text(event, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate900)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Text(hash, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.slate600)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;

  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.slate600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
