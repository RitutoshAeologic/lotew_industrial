import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/responsive/responsive_controller.dart';
import 'sidebar_nav.dart';
import 'top_bar.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final rc = ResponsiveController.to;

    return Obx(() {
      return Scaffold(
        drawer: rc.isMobile ? const Drawer(child: SidebarNav(compact: false)) : null,
        appBar: const TopBar(),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!rc.isMobile) ...[
              SidebarNav(compact: !rc.isSidebarExpanded.value),
              const VerticalDivider(width: 1),
            ],
            Expanded(child: child),
          ],
        ),
      );
    });
  }
}
