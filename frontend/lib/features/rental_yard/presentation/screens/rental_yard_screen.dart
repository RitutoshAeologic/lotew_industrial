import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../claim_replay/presentation/controllers/claim_replay_controller.dart';

class RentalYardDashboardScreen extends StatelessWidget {
  const RentalYardDashboardScreen({super.key});

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
                            color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.25)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.domain_rounded, size: 14, color: Color(0xFF0284C7)),
                              SizedBox(width: 6),
                              Text(
                                'EQUIPMENT LESSOR PORTAL',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0284C7),
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
                            color: AppColors.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '1 UNRESOLVED DAMAGE DISPUTE',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Titan Rentals Heavy • Rental Yard Fleet Portal',
                      style: AppTextStyles.headingLarge.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Equipment Owner & Lessor Workspace • Handover Checkout Baselines & Damage Loss Recovery',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.slate600),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: replayCtrl.downloadDossier,
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Export Dispute Dossier (ZIP)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.slate900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Top 4 KPI Metrics Row ─────────────────────────────────────────
            const _YardKpiMetricsRow(),
            const SizedBox(height: AppSpacing.lg),

            // ── Active Damage Dispute Card (Primary Financial Concern) ────────
            _ActiveDisputeCard(replayCtrl: replayCtrl),
            const SizedBox(height: AppSpacing.lg),

            // ── Handover Nominal Baseline Certificate (#1665) ─────────────────
            const _CertifiedHandoverCard(),
            const SizedBox(height: AppSpacing.lg),

            // ── Titan Rentals 14-Rig Fleet Table ──────────────────────────────
            const _YardFleetTableCard(),
          ],
        ),
      ),
    );
  }
}

// ── Top 4 Yard KPI Cards ──────────────────────────────────────────────────────
class _YardKpiMetricsRow extends StatelessWidget {
  const _YardKpiMetricsRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _buildMetricTile(
              label: 'TITAN OWNED FLEET',
              value: '14 Heavy Rigs',
              subValue: '12 Deployed • 2 In Yard',
              icon: Icons.precision_manufacturing_rounded,
              accentColor: const Color(0xFF0284C7),
              width: (constraints.maxWidth - (AppSpacing.md * 3)) / 4,
            ),
            _buildMetricTile(
              label: 'CHECKOUT BASELINES',
              value: '100% Certified',
              subValue: 'Pre-Rental Telematics Sealed',
              icon: Icons.verified_rounded,
              accentColor: AppColors.success,
              width: (constraints.maxWidth - (AppSpacing.md * 3)) / 4,
            ),
            _buildMetricTile(
              label: 'ACTIVE DAMAGE CLAIM',
              value: 'CLM-2026-9042',
              subValue: 'Rig #01 • Seized Pump',
              icon: Icons.report_problem_rounded,
              accentColor: AppColors.danger,
              width: (constraints.maxWidth - (AppSpacing.md * 3)) / 4,
            ),
            _buildMetricTile(
              label: 'CLAIMED LOSS EXPOSURE',
              value: r'$18,500.00 USD',
              subValue: 'Allianz Policy #POL-ALLZ-8812',
              icon: Icons.attach_money_rounded,
              accentColor: const Color(0xFFD97706),
              width: (constraints.maxWidth - (AppSpacing.md * 3)) / 4,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subValue,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subValue,
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

// ── Active Damage Claim Card ──────────────────────────────────────────────────
class _ActiveDisputeCard extends StatelessWidget {
  final ClaimReplayController replayCtrl;

  const _ActiveDisputeCard({required this.replayCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.gavel_rounded, color: AppColors.danger, size: 22),
                  SizedBox(width: 8),
                  Text(
                    r'Active Damage Recovery Claim: CLM-2026-9042 ($18,500.00)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate900),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ADJUDICATION IN PROGRESS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.danger),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Lessor: Titan Rentals Heavy • Lessee / Operator: ABC Infrastructure • Monitored Machine: Excavator Rig #01.\n'
            'Machine returned with catastrophic hydraulic pump seizure. Contractor alleges pre-existing equipment fatigue. '
            'Titan Rentals has submitted telematics proving nominal handover baseline (Cycle 1665) and operator willful neglect (Cycle 211).',
            style: TextStyle(fontSize: 12, color: AppColors.slate700, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.claimReplay),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('View Allianz Claim Replay Portal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.console),
                icon: const Icon(Icons.speed_rounded, size: 16),
                label: const Text('Inspect Rig #01 Telematics'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.slate800,
                  side: const BorderSide(color: AppColors.borderLight),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Certified Handover Card ───────────────────────────────────────────────────
class _CertifiedHandoverCard extends StatelessWidget {
  const _CertifiedHandoverCard();

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
                  Icon(Icons.verified_rounded, color: AppColors.success, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Pre-Rental Handover Baseline Certificate (Proof of Healthy Delivery)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.slate900),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('100% NOMINAL', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            '• Certified Baseline Cycle: #1665 (Handover Date: 2024-01-01 09:00 UTC) • Asset: Excavator Rig #01\n'
            '• Verified Telematics: Cooler 100%, Pump Leak: 0.0 L/min, Flow FS1: 19.2 L/min, Pressure PS1: 155.0 bar, Temp: 34.0°C.\n'
            '• Cryptographic Baseline Seal: sha256:53418536ae968dc51d46b7a0b5a3fa7166113bdf2d0014a4b49195b0042da09c\n'
            '• Legal Effect: Eliminates contractor pre-existing defect claims under Rental Agreement Clause 1.4.',
            style: TextStyle(fontSize: 12, color: AppColors.slate700, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Titan Rentals 14-Rig Fleet Table ──────────────────────────────────────────
class _YardFleetTableCard extends StatelessWidget {
  const _YardFleetTableCard();

  @override
  Widget build(BuildContext context) {
    final rigs = [
      {'id': 'hydraulic_rig_01', 'name': 'Excavator Rig #01', 'renter': 'ABC Infrastructure', 'status': '🚨 DISPUTE', 'baseline': '100% Nominal', 'color': AppColors.danger},
      {'id': 'hydraulic_rig_02', 'name': 'Excavator Rig #02', 'renter': 'Metro Earthworks', 'status': '🟢 Active Nominal', 'baseline': '100% Nominal', 'color': AppColors.success},
      {'id': 'hydraulic_rig_03', 'name': 'Excavator Rig #03', 'renter': 'Apex Civil Works', 'status': '🟢 Active Nominal', 'baseline': '100% Nominal', 'color': AppColors.success},
      {'id': 'hydraulic_rig_04', 'name': 'Dozer Rig #04', 'renter': 'ABC Infrastructure', 'status': '🟢 Active Nominal', 'baseline': '100% Nominal', 'color': AppColors.success},
      {'id': 'hydraulic_rig_05', 'name': 'Dozer Rig #05', 'renter': 'Titan Yard Standby', 'status': '⚪ Standby', 'baseline': 'Pre-Inspected', 'color': AppColors.slate500},
    ];

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
          const Text(
            'Titan Rentals Heavy • Machinery Fleet Register (14 Assets)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate900),
          ),
          const SizedBox(height: AppSpacing.md),
          Table(
            border: TableBorder.all(color: AppColors.slate100),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2.5),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(2),
              4: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: AppColors.slate50),
                children: [
                  _headerCell('ASSET ID & NAME'),
                  _headerCell('ACTIVE LESSEE / CONTRACTOR'),
                  _headerCell('TELEMATICS STATUS'),
                  _headerCell('HANDOVER BASELINE'),
                  _headerCell('ACTION'),
                ],
              ),
              ...rigs.map((r) => TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(r['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(r['renter'] as String, style: const TextStyle(fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(r['status'] as String, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: r['color'] as Color)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(r['baseline'] as String, style: const TextStyle(fontSize: 11, color: AppColors.success)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: TextButton(
                          onPressed: () {
                            if (r['id'] == 'hydraulic_rig_01') {
                              Get.toNamed(AppRoutes.claimReplay);
                            } else {
                              Get.toNamed(AppRoutes.console);
                            }
                          },
                          child: Text(r['id'] == 'hydraulic_rig_01' ? 'View Claim' : 'Inspect', style: const TextStyle(fontSize: 11)),
                        ),
                      ),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String title) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate600, letterSpacing: 0.5),
      ),
    );
  }
}
