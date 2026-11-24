import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/controllers/persona_controller.dart';
import '../../core/router/app_routes.dart';
import '../../features/claim_replay/presentation/controllers/claim_replay_controller.dart';

class SidebarNav extends StatelessWidget {
  final bool compact;

  const SidebarNav({super.key, required this.compact});

  @override
  Widget build(BuildContext context) {
    final personaCtrl = PersonaController.to;

    return Container(
      width: compact ? 72 : 250,
      color: AppColors.slate900,
      child: Obx(() {
        final p = personaCtrl.currentPersona.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Sidebar Header / Dynamic Role Logo ──────────────────────────
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              alignment: Alignment.centerLeft,
              child: compact
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: p.badgeColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(p.icon, color: p.badgeColor, size: 22),
                      ),
                    )
                  : Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: p.badgeColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(p.icon, color: p.badgeColor, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getHeaderTitle(p.role),
                                style: AppTextStyles.headingSmall.copyWith(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _getHeaderSubtitle(p.role),
                                style: AppTextStyles.labelCaps.copyWith(
                                  color: p.badgeColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            const Divider(height: 1, color: AppColors.slate800),

            // ── Strictly Role-Gated Navigation Items ────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: _buildRoleMenuItems(context, p.role, compact),
                ),
              ),
            ),

            // ── Dynamic Scope & Role Footer Card ─────────────────────────────
            if (!compact)
              Container(
                margin: const EdgeInsets.all(AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.slate800,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.slate700),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: p.badgeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _getFooterRoleLabel(p.role),
                          style: AppTextStyles.labelCaps.copyWith(
                            color: p.badgeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _getFooterMainText(p.role),
                      style: AppTextStyles.monoSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getFooterDetailText(p.role),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      }),
    );
  }

  String _getHeaderTitle(String role) {
    switch (role) {
      case 'SUPER_ADMIN':
        return 'LOTEW CORE';
      case 'RENTAL_MANAGER':
        return 'TITAN RENTALS';
      case 'FLEET_OPERATOR':
        return 'ABC INFRASTRUCTURE';
      case 'INSURER_ADJUSTER':
        return 'ALLIANZ PORTAL';
      case 'AUDITOR':
        return 'TÜV SÜD AUDIT';
      default:
        return 'LOTEW CORE';
    }
  }

  String _getHeaderSubtitle(String role) {
    switch (role) {
      case 'SUPER_ADMIN':
        return 'CROSS-TENANT SUPERVISOR';
      case 'RENTAL_MANAGER':
        return 'EQUIPMENT OWNER';
      case 'FLEET_OPERATOR':
        return 'JOB-SITE OPERATOR';
      case 'INSURER_ADJUSTER':
        return 'CLAIMS ADJUDICATION';
      case 'AUDITOR':
        return 'CRYPTOGRAPHIC ASSURANCE';
      default:
        return 'SYSTEM GOVERNANCE';
    }
  }

  String _getFooterRoleLabel(String role) {
    switch (role) {
      case 'SUPER_ADMIN':
        return 'SYSTEM ACTIVE';
      case 'RENTAL_MANAGER':
        return 'OWNER ACTIVE';
      case 'FLEET_OPERATOR':
        return 'RENTER ACTIVE';
      case 'INSURER_ADJUSTER':
        return 'POLICY ACTIVE';
      case 'AUDITOR':
        return 'AUDIT SEALED';
      default:
        return 'ACTIVE';
    }
  }

  String _getFooterMainText(String role) {
    switch (role) {
      case 'SUPER_ADMIN':
        return 'Lotew Multi-Tenant';
      case 'RENTAL_MANAGER':
        return 'Titan Heavy Fleet';
      case 'FLEET_OPERATOR':
        return 'Excavator Rig #01';
      case 'INSURER_ADJUSTER':
        return 'Policy #POL-ALLZ-8812';
      case 'AUDITOR':
        return 'RFC 8785 Hash Ledger';
      default:
        return 'Lotew Industrial';
    }
  }

  String _getFooterDetailText(String role) {
    switch (role) {
      case 'SUPER_ADMIN':
        return '4 Tenants Connected';
      case 'RENTAL_MANAGER':
        return '14 Rigs • 1 Active Claim';
      case 'FLEET_OPERATOR':
        return 'Contract #RNT-2024-88';
      case 'INSURER_ADJUSTER':
        return 'Claim CLM-2026-9042 • \$18.5k';
      case 'AUDITOR':
        return '42 Blocks Intact (0 Tamper)';
      default:
        return 'Operational';
    }
  }

  List<Widget> _buildRoleMenuItems(BuildContext context, String role, bool compact) {
    switch (role) {
      // ── 1. RENTAL YARD MANAGER (EQUIPMENT OWNER) ───────────────────────────
      case 'RENTAL_MANAGER':
        return [
          _SidebarItem(
            icon: Icons.domain_rounded,
            label: 'Yard Fleet Overview',
            badge: '14 RIGS',
            route: AppRoutes.rentalYard,
            compact: compact,
            onTap: () {
              if (Get.currentRoute != AppRoutes.rentalYard) {
                Get.toNamed(AppRoutes.rentalYard);
              }
            },
          ),
          _SidebarItem(
            icon: Icons.assignment_turned_in_rounded,
            label: 'Handover Baseline (#1665)',
            compact: compact,
            onTap: () => _showHandoverModal(context),
          ),
          _SidebarItem(
            icon: Icons.gavel_rounded,
            label: 'Active Claim (CLM-9042)',
            badge: r'$18.5k',
            route: AppRoutes.claimReplay,
            compact: compact,
            onTap: () {
              if (Get.currentRoute != AppRoutes.claimReplay) {
                Get.toNamed(AppRoutes.claimReplay);
              }
            },
          ),
          _SidebarItem(
            icon: Icons.precision_manufacturing_rounded,
            label: 'Rig #01 Telematics View',
            route: AppRoutes.console,
            compact: compact,
            onTap: () {
              if (Get.currentRoute != AppRoutes.console) {
                Get.toNamed(AppRoutes.console);
              }
            },
          ),
        ];

      // ── 2. FLEET OPERATOR (JOB-SITE RENTER) ────────────────────────────────
      case 'FLEET_OPERATOR':
        return [
          _SidebarItem(
            icon: Icons.notifications_active_rounded,
            label: 'In-Cab Alerts',
            badge: '1 ACTIVE',
            route: AppRoutes.console,
            compact: compact,
            onTap: () {
              if (Get.currentRoute != AppRoutes.console) {
                Get.toNamed(AppRoutes.console);
              }
            },
          ),
          _SidebarItem(
            icon: Icons.speed_rounded,
            label: 'Rig Telemetry Waveforms',
            route: AppRoutes.timeline,
            compact: compact,
            onTap: () {
              if (Get.currentRoute != AppRoutes.timeline) {
                Get.toNamed(AppRoutes.timeline);
              }
            },
          ),
          _SidebarItem(
            icon: Icons.build_circle_rounded,
            label: 'Maintenance Service Dispatch',
            compact: compact,
            onTap: () => _showWorkOrdersDialog(context),
          ),
        ];

      // ── 3. INSURER ADJUSTER (CLAIM DECISION MAKER) ─────────────────────────
      case 'INSURER_ADJUSTER':
        return [
          _SidebarItem(
            icon: Icons.gavel_rounded,
            label: 'Claim Adjudication',
            badge: 'CLM-9042',
            route: AppRoutes.claimReplay,
            compact: compact,
            onTap: () {
              if (Get.currentRoute != AppRoutes.claimReplay) {
                Get.toNamed(AppRoutes.claimReplay);
              }
            },
          ),
          _SidebarItem(
            icon: Icons.policy_rounded,
            label: 'Policy Terms & SLA',
            compact: compact,
            onTap: () => _showPolicyDialog(context),
          ),
          _SidebarItem(
            icon: Icons.download_for_offline_rounded,
            label: 'Export Forensic ZIP',
            compact: compact,
            onTap: () {
              if (Get.isRegistered<ClaimReplayController>()) {
                ClaimReplayController.to.downloadDossier();
              }
            },
          ),
        ];

      // ── 4. EXTERNAL AUDITOR (ISO / COMPLIANCE) ─────────────────────────────
      case 'AUDITOR':
        return [
          _SidebarItem(
            icon: Icons.account_balance_rounded,
            label: 'Cryptographic Ledger',
            badge: '42 BLOCKS',
            route: AppRoutes.auditor,
            compact: compact,
            onTap: () {
              if (Get.currentRoute != AppRoutes.auditor) {
                Get.toNamed(AppRoutes.auditor);
              }
            },
          ),
          _SidebarItem(
            icon: Icons.gavel_rounded,
            label: 'Point-in-Time Verifier',
            route: AppRoutes.claimReplay,
            compact: compact,
            onTap: () {
              if (Get.currentRoute != AppRoutes.claimReplay) {
                Get.toNamed(AppRoutes.claimReplay);
              }
            },
          ),
          _SidebarItem(
            icon: Icons.file_download_outlined,
            label: 'Export TÜV Evidence Pack',
            compact: compact,
            onTap: () {
              if (Get.isRegistered<ClaimReplayController>()) {
                ClaimReplayController.to.downloadDossier();
              }
            },
          ),
        ];

      // ── 5. LOTEW ADMIN (SUPERVISOR) ────────────────────────────────────────
      case 'SUPER_ADMIN':
      default:
        return [
          _SidebarItem(
            icon: Icons.dashboard_rounded,
            label: 'Platform Overview',
            badge: '48 RIGS',
            route: AppRoutes.admin,
            compact: compact,
            onTap: () {
              if (Get.currentRoute != AppRoutes.admin) {
                Get.toNamed(AppRoutes.admin);
              }
            },
          ),
          _SidebarItem(
            icon: Icons.precision_manufacturing_rounded,
            label: 'Rig #01 Console',
            route: AppRoutes.console,
            compact: compact,
            onTap: () {
              if (Get.currentRoute != AppRoutes.console) {
                Get.toNamed(AppRoutes.console);
              }
            },
          ),
          _SidebarItem(
            icon: Icons.gavel_rounded,
            label: 'Insurance Replay (CLM-9042)',
            badge: '\$18.5k',
            route: AppRoutes.claimReplay,
            compact: compact,
            onTap: () {
              if (Get.currentRoute != AppRoutes.claimReplay) {
                Get.toNamed(AppRoutes.claimReplay);
              }
            },
          ),
          _SidebarItem(
            icon: Icons.account_balance_rounded,
            label: 'Cryptographic Ledger',
            route: AppRoutes.auditor,
            compact: compact,
            onTap: () {
              if (Get.currentRoute != AppRoutes.auditor) {
                Get.toNamed(AppRoutes.auditor);
              }
            },
          ),
        ];
    }
  }

  void _showHandoverModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: AppColors.success, size: 22),
            SizedBox(width: 8),
            Text('Pre-Rental Handover Baseline (Rig #01)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BASELINE CERTIFIED 100% NOMINAL', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                    SizedBox(height: 4),
                    Text('Cycle #1665 (Handover to ABC Infrastructure). Cooler: 100%, Pump Internal Leak: 0.0 L/min, PS1 Pressure: 156 bar.', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Legal Value for Equipment Owner:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate900),
              ),
              const SizedBox(height: 4),
              const Text(
                'This cryptographic baseline proves beyond doubt that the rig was undamaged when Titan Rentals delivered it to ABC Infrastructure. Any defect occurred during the renter\'s possession.',
                style: TextStyle(fontSize: 12, color: AppColors.slate700, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.policy_rounded, color: Color(0xFF0F766E), size: 22),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Allianz SE Policy #POL-ALLZ-8812', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Heavy Machinery Equipment Indemnity Coverage', style: TextStyle(fontSize: 12, color: AppColors.slate500)),
              ],
            ),
          ],
        ),
        content: SizedBox(
          width: 540,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClauseCard(
                'Clause 3.1: Mandatory Maintenance & Service Adherence',
                'The Insured agrees that any telemetry-delivered Level 2 alarm requires immediate cessation of heavy operational duty and certified technical inspection within 2.0 operating hours. Operating beyond this window voids mechanical damage coverage.',
                AppColors.danger,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildClauseCard(
                'Clause 4.2: Failure to Mitigate Loss Upon In-Cab Alert',
                'Willful dismissal of persistent cabin warning alerts without dispatching maintenance shall be deemed gross operational negligence. Any subsequent catastrophic component seizure directly resulting from unmitigated operation shall not be eligible for indemnity.',
                AppColors.danger,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildClauseCard(String title, String description, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: accentColor)),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(fontSize: 12, color: AppColors.slate700, height: 1.4)),
        ],
      ),
    );
  }

  void _showWorkOrdersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Titan Rentals • CMMS Work Orders (Rig #01)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ZERO work orders were dispatched between Cycle 211 (14:00 UTC) and Cycle 226 (16:30 UTC).',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Historical Maintenance Logs:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate700),
              ),
              const SizedBox(height: 6),
              _buildHistoricalOrder('WO-8801', 'Handover Certified Nominal', 'Cycle #1665', 'COMPLETED', AppColors.success),
              const Divider(height: 12),
              _buildHistoricalOrder('WO-9912', 'Emergency Hydraulic Field Service', 'Cycle #211', 'PENDING / MISSED', AppColors.danger),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildHistoricalOrder(String id, String desc, String cycle, String status, Color statusColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$id • $cycle', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate900)),
            Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.slate600)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final String? route;
  final bool compact;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.badge,
    this.route,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = route != null && Get.currentRoute == route;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.16) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: AppColors.primary.withValues(alpha: 0.35)) : null,
          ),
          child: compact
              ? Center(child: Icon(icon, color: isSelected ? AppColors.primary : AppColors.slate400, size: 20))
              : Row(
                  children: [
                    Icon(icon, color: isSelected ? AppColors.primary : AppColors.slate400, size: 20),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        label,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isSelected ? Colors.white : AppColors.slate300,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.slate800,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.slate700),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
