import 'package:get/get.dart';
import '../../features/evidence_ingestion/bindings/evidence_binding.dart';
import '../../features/evidence_ingestion/presentation/screens/evidence_console_screen.dart';
import '../../features/machine_timeline/presentation/machine_timeline_screen.dart';
import 'app_routes.dart';

class AppPages {
  static const initial = AppRoutes.console;

  static final pages = [
    GetPage(
      name: AppRoutes.console,
      page: () => const EvidenceConsoleScreen(),
      binding: EvidenceBinding(),
    ),
    GetPage(
      name: AppRoutes.timeline,
      page: () => const MachineTimelineScreen(),
      binding: EvidenceBinding(),
    ),
  ];
}

