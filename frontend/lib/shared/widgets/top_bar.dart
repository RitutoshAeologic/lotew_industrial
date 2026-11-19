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
          // Tenant Selector Dropdown
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: AppConstants.defaultTenantId,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.slate600),
                style: AppTextStyles.monoSmall,
                items: AppConstants.tenants
                    .map((t) => DropdownMenuItem(value: t['id'], child: Text('${t['name']} (${t['id']})')))
                    .toList(),
                onChanged: (_) {},
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
