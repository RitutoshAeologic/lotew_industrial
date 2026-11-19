import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/responsive/responsive_controller.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final rc = ResponsiveController.to;

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      centerTitle: false,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          IconButton(
            icon: Icon(rc.isSidebarExpanded.value ? Icons.menu_open_rounded : Icons.menu_rounded),
            color: AppColors.slate900,
            onPressed: () {
              if (rc.isMobile) {
                Scaffold.of(context).openDrawer();
              } else {
                rc.toggleSidebar();
              }
            },
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              'Lotew Industrial Evidentiary Assurance',
              style: AppTextStyles.headingSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        if (rc.isDesktop) ...[
          // Active Tenant & Rig Scope Badge (Replaced dead-click dropdown with crisp multi-tenant status)
          Tooltip(
            message: 'Active Multi-Tenant Scope: ${AppConstants.defaultTenantName}\nRig ID: ${AppConstants.defaultAssetId} (Physical Test Bench)',
            waitDuration: const Duration(milliseconds: 200),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'TENANT: ${AppConstants.defaultTenantId}',
                    style: AppTextStyles.monoSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate900,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Text('|', style: TextStyle(color: AppColors.borderLight, fontSize: 11)),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'RIG: ${AppConstants.defaultAssetId}',
                    style: AppTextStyles.monoSmall.copyWith(
                      color: AppColors.slate600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Live Forensic Status Indicator
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.slate900,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'SHA-256 LEDGER ACTIVE',
                  style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ],
    );
  }
}
