import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/controllers/persona_controller.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/app_scaffold.dart';

class SuperAdminOverviewScreen extends StatefulWidget {
  const SuperAdminOverviewScreen({super.key});

  @override
  State<SuperAdminOverviewScreen> createState() => _SuperAdminOverviewScreenState();
}

class _SuperAdminOverviewScreenState extends State<SuperAdminOverviewScreen> {
  String _activeFilter = 'ALL'; // 'ALL', 'CRITICAL', 'WARNING', 'NOMINAL', 'DISPUTES'

  @override
  Widget build(BuildContext context) {
    final personaCtrl = PersonaController.to;

    return AppScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Platform Executive Header ─────────────────────────────────────
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
                            color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.25)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.admin_panel_settings_rounded, size: 14, color: Color(0xFF6366F1)),
                              SizedBox(width: 6),
                              Text(
                                'GLOBAL MULTI-TENANT CORE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6366F1),
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
                              Icon(Icons.shield_rounded, size: 14, color: AppColors.success),
                              SizedBox(width: 4),
                              Text(
                                '42 BLOCKS VERIFIED INTACT',
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
                      'Multi-Tenant Fleet & Assurance Directory',
                      style: AppTextStyles.headingLarge.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cross-Tenant Supervision across 3 Rental Companies, 12 Contractor Lessees, and 48 Active Heavy Machinery Rigs',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.slate600),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    personaCtrl.switchPersona('insurer_allianz');
                    Get.toNamed(AppRoutes.claimReplay);
                  },
                  icon: const Icon(Icons.gavel_rounded, size: 16),
                  label: const Text(r'Open Active Dispute ($18,500.00)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Top 4 Global KPI Cards ────────────────────────────────────────
            const _GlobalKpiRow(),
            const SizedBox(height: AppSpacing.lg),

            // ── Quick Role Portal Launchers (Presentation Helpers) ────────────
            _RolePortalsLauncher(personaCtrl: personaCtrl),
            const SizedBox(height: AppSpacing.xl),

            // ── Multi-Entity Equipment Fleet Directory (The Core Table) ──────
            _FleetDirectorySection(
              activeFilter: _activeFilter,
              onFilterChanged: (filter) {
                setState(() {
                  _activeFilter = filter;
                });
              },
              personaCtrl: personaCtrl,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top 4 Global KPI Cards ────────────────────────────────────────────────────
class _GlobalKpiRow extends StatelessWidget {
  const _GlobalKpiRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - (AppSpacing.md * 3)) / 4;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _buildKpiCard(
              title: 'CONNECTED RENTAL YARDS',
              value: '3 Companies',
              sub: 'Titan, Sunbelt, United Rentals',
              icon: Icons.domain_rounded,
              accentColor: const Color(0xFF0284C7),
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'CONTRACTORS & LESSEES',
              value: '12 Construction Firms',
              sub: 'ABC Infra, Metro, Apex Civil',
              icon: Icons.badge_rounded,
              accentColor: const Color(0xFFD97706),
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'MONITORED HEAVY FLEET',
              value: '48 Heavy Rigs',
              sub: '42 Nominal • 5 Warning • 1 Critical',
              icon: Icons.precision_manufacturing_rounded,
              accentColor: AppColors.success,
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'ACTIVE DISPUTES AT RISK',
              value: '\$18,500.00 USD',
              sub: 'Claim CLM-2026-9042 (Allianz SE)',
              icon: Icons.gavel_rounded,
              accentColor: AppColors.danger,
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
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
                  title,
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  sub,
                  style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 4 Dedicated Role Portals Launcher Cards ───────────────────────────────────
class _RolePortalsLauncher extends StatelessWidget {
  final PersonaController personaCtrl;

  const _RolePortalsLauncher({required this.personaCtrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DEDICATED STAKEHOLDER PORTAL VIEWS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.slate700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - (AppSpacing.md * 3)) / 4;

            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                _buildPortalTile(
                  roleName: 'Equipment Owner Portal',
                  entity: 'Titan Rentals Heavy',
                  badge: '14 RIGS',
                  desc: 'Inspect fleet baseline, rental contracts, and file damaged asset claims.',
                  icon: Icons.domain_rounded,
                  accentColor: const Color(0xFF0284C7),
                  width: cardWidth,
                  onTap: () {
                    personaCtrl.switchPersona('rental_yard_manager');
                    Get.toNamed(AppRoutes.rentalYard);
                  },
                ),
                _buildPortalTile(
                  roleName: 'Job-Site Operator Cab',
                  entity: 'ABC Infrastructure',
                  badge: 'RIG #01 ACTIVE',
                  desc: 'In-cab telematics screen with Level 2 pump alert dispatch/dismiss action.',
                  icon: Icons.engineering_rounded,
                  accentColor: const Color(0xFFD97706),
                  width: cardWidth,
                  onTap: () {
                    personaCtrl.switchPersona('fleet_operator');
                    Get.toNamed(AppRoutes.console);
                  },
                ),
                _buildPortalTile(
                  roleName: 'Insurance Claims Portal',
                  entity: 'Allianz Global Claims',
                  badge: 'DISPUTE: \$18.5k',
                  desc: 'Retrospective Cutoff Replay, policy clause breach audit & 2 action buttons.',
                  icon: Icons.verified_user_rounded,
                  accentColor: const Color(0xFF0F766E),
                  width: cardWidth,
                  onTap: () {
                    personaCtrl.switchPersona('insurer_allianz');
                    Get.toNamed(AppRoutes.claimReplay);
                  },
                ),
                _buildPortalTile(
                  roleName: 'Cryptographic Auditor',
                  entity: 'TÜV SÜD Compliance',
                  badge: '42 BLOCKS INTACT',
                  desc: 'Independent RFC 8785 hash ledger inspection and ZIP package download.',
                  icon: Icons.account_balance_rounded,
                  accentColor: const Color(0xFF2563EB),
                  width: cardWidth,
                  onTap: () {
                    personaCtrl.switchPersona('external_auditor');
                    Get.toNamed(AppRoutes.claimReplay);
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPortalTile({
    required String roleName,
    required String entity,
    required String badge,
    required String desc,
    required IconData icon,
    required Color accentColor,
    required double width,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: width < 220 ? double.infinity : width,
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
                    Icon(icon, size: 18, color: accentColor),
                    const SizedBox(width: 6),
                    Text(
                      roleName,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: accentColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              entity,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.slate900),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: const TextStyle(fontSize: 11, color: AppColors.slate600, height: 1.3),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Launch Portal',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentColor),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 13, color: accentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Multi-Entity Equipment Fleet Directory Section ────────────────────────────
class _FleetDirectorySection extends StatelessWidget {
  final String activeFilter;
  final ValueChanged<String> onFilterChanged;
  final PersonaController personaCtrl;

  const _FleetDirectorySection({
    required this.activeFilter,
    required this.onFilterChanged,
    required this.personaCtrl,
  });

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
                  Icon(Icons.table_chart_rounded, size: 20, color: AppColors.slate900),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    'Multi-Tenant Heavy Machinery Fleet Directory',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate900),
                  ),
                ],
              ),
              Row(
                children: [
                  _FilterChip(label: 'All Assets (48)', isSelected: activeFilter == 'ALL', onTap: () => onFilterChanged('ALL')),
                  const SizedBox(width: 6),
                  _FilterChip(label: '🔴 Critical Alarms (1)', isSelected: activeFilter == 'CRITICAL', onTap: () => onFilterChanged('CRITICAL')),
                  const SizedBox(width: 6),
                  _FilterChip(label: '⚖️ Active Claims (1)', isSelected: activeFilter == 'DISPUTES', onTap: () => onFilterChanged('DISPUTES')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Interactive fleet registry. Click any asset to inspect live physical telematics, or launch its dispute claim replay.',
            style: TextStyle(fontSize: 12, color: AppColors.slate600),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── The Fleet Table ────────────────────────────────────────────────
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.2), // Rental Yard
              1: FlexColumnWidth(2.2), // Contractor
              2: FlexColumnWidth(2.4), // Asset Rig
              3: FlexColumnWidth(2.5), // Condition Status
              4: FlexColumnWidth(2.6), // Insurance / Dispute
              5: FlexColumnWidth(2.4), // Actions
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              // Header Row
              const TableRow(
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 1.5)),
                ),
                children: const [
                  _TableHeaderCell('RENTAL YARD (OWNER)'),
                  _TableHeaderCell('CONTRACTOR (LESSEE)'),
                  _TableHeaderCell('EQUIPMENT ASSET'),
                  _TableHeaderCell('OPERATIONAL CONDITION'),
                  _TableHeaderCell('INSURANCE POLICY & CLAIM'),
                  _TableHeaderCell('QUICK LAUNCH'),
                ],
              ),

              // Row 1: The Star Incident Rig (Excavator Rig #01)
              _buildFleetRow(
                yard: 'Titan Rentals Heavy',
                renter: 'ABC Infrastructure',
                assetName: 'Excavator Rig #01',
                assetId: 'hydraulic_rig_01',
                statusLabel: '🔴 PUMP INTERNAL LEAK',
                statusDetail: 'Flow collapsed to 2.15 L/min',
                statusColor: AppColors.danger,
                policyInfo: 'Allianz #POL-ALLZ-8812',
                claimInfo: 'Claim CLM-2026-9042 (\$18,500)',
                hasDispute: true,
                onOpenRig: () {
                  personaCtrl.switchPersona('fleet_operator');
                  Get.toNamed(AppRoutes.console);
                },
                onOpenClaim: () {
                  personaCtrl.switchPersona('insurer_allianz');
                  Get.toNamed(AppRoutes.claimReplay);
                },
              ),

              // Row 2: Crane Rig #02
              _buildFleetRow(
                yard: 'Titan Rentals Heavy',
                renter: 'ABC Infrastructure',
                assetName: 'Crane Rig #02',
                assetId: 'hydraulic_rig_02',
                statusLabel: '🟢 100% NOMINAL',
                statusDetail: 'Pressure 156 bar • 0 leaks',
                statusColor: AppColors.success,
                policyInfo: 'Allianz #POL-ALLZ-8812',
                claimInfo: 'No Active Disputes',
                hasDispute: false,
                onOpenRig: () {
                  personaCtrl.switchPersona('rental_yard_manager');
                  Get.toNamed(AppRoutes.console);
                },
              ),

              // Row 3: Dozer Rig #03
              _buildFleetRow(
                yard: 'Titan Rentals Heavy',
                renter: 'Apex Civil Works',
                assetName: 'Dozer Rig #03',
                assetId: 'hydraulic_rig_03',
                statusLabel: '🟢 100% NOMINAL',
                statusDetail: 'Pressure 158 bar • 0 leaks',
                statusColor: AppColors.success,
                policyInfo: 'Allianz #POL-ALLZ-8812',
                claimInfo: 'No Active Disputes',
                hasDispute: false,
                onOpenRig: () {
                  personaCtrl.switchPersona('rental_yard_manager');
                  Get.toNamed(AppRoutes.console);
                },
              ),

              // Row 4: Excavator Rig #08
              _buildFleetRow(
                yard: 'Sunbelt Equipment',
                renter: 'Metro Earthworks',
                assetName: 'Excavator Rig #08',
                assetId: 'hydraulic_rig_08',
                statusLabel: '🟡 TEMP WARNING',
                statusDetail: 'Cooler Temp 52°C (Monitor)',
                statusColor: AppColors.warning,
                policyInfo: 'Zurich #POL-ZUR-4419',
                claimInfo: 'Routine Service Scheduled',
                hasDispute: false,
                onOpenRig: () {
                  personaCtrl.switchPersona('rental_yard_manager');
                  Get.toNamed(AppRoutes.console);
                },
              ),

              // Row 5: Loader Rig #12
              _buildFleetRow(
                yard: 'United Rentals',
                renter: 'Delta Heavy Works',
                assetName: 'Loader Rig #12',
                assetId: 'hydraulic_rig_12',
                statusLabel: '🟢 100% NOMINAL',
                statusDetail: 'Pressure 155 bar • 0 leaks',
                statusColor: AppColors.success,
                policyInfo: 'Chubb #POL-CHB-9021',
                claimInfo: 'No Active Disputes',
                hasDispute: false,
                onOpenRig: () {
                  personaCtrl.switchPersona('rental_yard_manager');
                  Get.toNamed(AppRoutes.console);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildFleetRow({
    required String yard,
    required String renter,
    required String assetName,
    required String assetId,
    required String statusLabel,
    required String statusDetail,
    required Color statusColor,
    required String policyInfo,
    required String claimInfo,
    required bool hasDispute,
    required VoidCallback onOpenRig,
    VoidCallback? onOpenClaim,
  }) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.slate100)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(yard, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate900)),
              const Text('Active Yard Account', style: TextStyle(fontSize: 10, color: AppColors.slate500)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(renter, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate800)),
              const Text('Contract #RNT-2024-88', style: TextStyle(fontSize: 10, color: AppColors.slate500)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(assetName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate900)),
              Text(assetId, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.slate500)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
              const SizedBox(height: 2),
              Text(statusDetail, style: const TextStyle(fontSize: 10, color: AppColors.slate600)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(policyInfo, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slate800)),
              Text(
                claimInfo,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: hasDispute ? FontWeight.bold : FontWeight.normal,
                  color: hasDispute ? AppColors.danger : AppColors.slate500,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              OutlinedButton.icon(
                onPressed: onOpenRig,
                icon: const Icon(Icons.precision_manufacturing_rounded, size: 12),
                label: const Text('Rig Console'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.slate900,
                  side: const BorderSide(color: AppColors.borderLight),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              if (hasDispute && onOpenClaim != null) ...[
                ElevatedButton.icon(
                  onPressed: onOpenClaim,
                  icon: const Icon(Icons.gavel_rounded, size: 12),
                  label: const Text('Replay Claim'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;

  const _TableHeaderCell(this.text);

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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.slate900 : AppColors.bgLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? AppColors.slate900 : AppColors.borderLight),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.slate700,
          ),
        ),
      ),
    );
  }
}
