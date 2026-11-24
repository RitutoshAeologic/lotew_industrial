import 'package:get/get.dart';
import '../../features/claim_replay/bindings/claim_replay_binding.dart';
import '../../features/claim_replay/presentation/screens/claim_replay_screen.dart';
import '../../features/evidence_ingestion/bindings/evidence_binding.dart';
import '../../features/evidence_ingestion/presentation/screens/evidence_console_screen.dart';
import '../../features/machine_timeline/presentation/machine_timeline_screen.dart';
import '../../features/rental_yard/presentation/screens/rental_yard_screen.dart';
import '../../features/super_admin/presentation/screens/auditor_ledger_screen.dart';
import '../../features/super_admin/presentation/screens/super_admin_overview_screen.dart';
import 'app_routes.dart';
import 'role_guard.dart';

class AppPages {
  static const initial = AppRoutes.admin;

  static final pages = [
    GetPage(
      name: AppRoutes.admin,
      page: () => const SuperAdminOverviewScreen(),
      middlewares: [
        RoleGuardMiddleware(allowedRoles: ['SUPER_ADMIN']),
      ],
    ),
    GetPage(
      name: AppRoutes.rentalYard,
      page: () => const RentalYardDashboardScreen(),
      binding: ClaimReplayBinding(),
      middlewares: [
        RoleGuardMiddleware(allowedRoles: ['SUPER_ADMIN', 'RENTAL_MANAGER']),
      ],
    ),
    GetPage(
      name: AppRoutes.console,
      page: () => const EvidenceConsoleScreen(),
      binding: EvidenceBinding(),
      middlewares: [
        RoleGuardMiddleware(allowedRoles: ['SUPER_ADMIN', 'RENTAL_MANAGER', 'FLEET_OPERATOR']),
      ],
    ),
    GetPage(
      name: AppRoutes.timeline,
      page: () => const MachineTimelineScreen(),
      binding: EvidenceBinding(),
    ),
    GetPage(
      name: AppRoutes.claimReplay,
      page: () => const ClaimReplayScreen(),
      binding: ClaimReplayBinding(),
      middlewares: [
        RoleGuardMiddleware(allowedRoles: ['SUPER_ADMIN', 'RENTAL_MANAGER', 'INSURER_ADJUSTER', 'AUDITOR']),
      ],
    ),
    GetPage(
      name: AppRoutes.auditor,
      page: () => const AuditorLedgerScreen(),
      binding: ClaimReplayBinding(),
      middlewares: [
        RoleGuardMiddleware(allowedRoles: ['SUPER_ADMIN', 'INSURER_ADJUSTER', 'AUDITOR']),
      ],
    ),
  ];
}
