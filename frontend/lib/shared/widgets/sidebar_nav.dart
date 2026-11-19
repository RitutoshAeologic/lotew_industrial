import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/router/app_routes.dart';

class SidebarNav extends StatelessWidget {
  final bool compact;

  const SidebarNav({super.key, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 72 : 240,
      color: AppColors.slate900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header / Logo
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            alignment: Alignment.centerLeft,
            child: compact
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 24),
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LOTEW', style: AppTextStyles.headingSmall.copyWith(color: Colors.white, letterSpacing: 1.5)),
                          Text('INDUSTRIAL', style: AppTextStyles.labelCaps.copyWith(color: AppColors.primary, fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
          ),
          const Divider(height: 1, color: AppColors.slate800),

          // Nav Items
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              children: [
                _SidebarItem(
                  icon: Icons.input_rounded,
                  label: 'Evidence Ingestion',
                  route: AppRoutes.console,
                  compact: compact,
                ),
                _SidebarItem(
                  icon: Icons.timeline_rounded,
                  label: 'Machine Timeline',
                  route: AppRoutes.timeline,
                  compact: compact,
                ),
              ],
            ),
          ),

          const Spacer(),

          // Tenant Status Card
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
                        decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text('TENANT ACTIVE', style: AppTextStyles.labelCaps.copyWith(color: AppColors.success, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text('hydraulic_lab', style: AppTextStyles.monoSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('Asset: hydraulic_rig_01', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool compact;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final currentRoute = Get.currentRoute;
    final isActive = currentRoute == route || (route == AppRoutes.console && currentRoute.isEmpty);

    final itemColor = isActive ? AppColors.primary : AppColors.slate300;
    final bgColor = isActive ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent;

    return Tooltip(
      message: compact ? label : '',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: () {
            if (Get.currentRoute != route) {
              Get.toNamed(route);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: compact
                ? const EdgeInsets.symmetric(vertical: AppSpacing.md)
                : const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
            child: compact
                ? Center(child: Icon(icon, color: itemColor, size: 20))
                : Row(
                    children: [
                      Icon(icon, color: itemColor, size: 20),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          label,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isActive ? Colors.white : AppColors.slate300,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
