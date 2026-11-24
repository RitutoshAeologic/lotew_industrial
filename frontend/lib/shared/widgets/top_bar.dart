import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/controllers/persona_controller.dart';
import '../../core/responsive/responsive_controller.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final rc = ResponsiveController.to;
    final personaCtrl = PersonaController.to;

    return AppBar(
      elevation: 0.5,
      backgroundColor: Colors.white,
      centerTitle: false,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          IconButton(
            icon: Icon(rc.isSidebarExpanded.value ? Icons.menu_open_rounded : Icons.menu_rounded),
            color: AppColors.slate900,
            tooltip: 'Toggle Navigation',
            onPressed: () {
              if (rc.isMobile) {
                Scaffold.of(context).openDrawer();
              } else {
                rc.toggleSidebar();
              }
            },
          ),
          const SizedBox(width: AppSpacing.xs),

          // ── Clean Enterprise Portal Branding ───────────────────────────────
          Obx(() {
            final p = personaCtrl.currentPersona.value;
            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: p.badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(p.icon, color: p.badgeColor, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.portalTitle,
                      style: AppTextStyles.headingSmall.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                    Text(
                      p.portalSubtitle,
                      style: AppTextStyles.monoSmall.copyWith(
                        fontSize: 11,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
      actions: [
        if (rc.isDesktop) ...[
          // ── Clean Role / Account Switcher ──────────────────────────────────
          Obx(() {
            final current = personaCtrl.currentPersona.value;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: current.id,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: current.badgeColor, size: 18),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: current.badgeColor,
                    fontSize: 12,
                  ),
                  onChanged: (newId) {
                    if (newId != null) {
                      personaCtrl.switchPersona(newId);
                    }
                  },
                  items: personaCtrl.personas.map((p) {
                    return DropdownMenuItem<String>(
                      value: p.id,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(p.icon, size: 16, color: p.badgeColor),
                          const SizedBox(width: 8),
                          Text(p.name),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          }),
          const SizedBox(width: AppSpacing.md),

          // ── Active Rig Scope Indicator ─────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Text(
                  'RIG #01 • ONLINE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate900,
                    letterSpacing: 0.5,
                  ),
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
