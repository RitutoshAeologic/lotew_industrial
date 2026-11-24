import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/network/dio_client.dart';
import '../router/app_routes.dart';

class PersonaModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String scope;
  final String portalTitle;
  final String portalSubtitle;
  final String defaultRoute;
  final IconData icon;
  final Color badgeColor;

  const PersonaModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.scope,
    required this.portalTitle,
    required this.portalSubtitle,
    required this.defaultRoute,
    required this.icon,
    required this.badgeColor,
  });
}

class PersonaController extends GetxController {
  static PersonaController get to => Get.find();

  // 5 Commercial Personas
  final personas = const [
    PersonaModel(
      id: 'lotew_admin',
      name: '👑 Lotew Super Admin',
      email: 'admin@lotew.io',
      role: 'SUPER_ADMIN',
      scope: 'Platform Core Supervisor (Multi-Tenant)',
      portalTitle: 'Lotew Industrial Assurance Core',
      portalSubtitle: 'Multi-Tenant Fleet Governance',
      defaultRoute: AppRoutes.admin,
      icon: Icons.admin_panel_settings_rounded,
      badgeColor: Color(0xFF6366F1), // Indigo
    ),
    PersonaModel(
      id: 'rental_yard_manager',
      name: '🏗️ Rental Yard Manager',
      email: 'manager@titan.com',
      role: 'RENTAL_MANAGER',
      scope: 'Titan Rentals Heavy (Equipment Owner)',
      portalTitle: 'Titan Rentals • Equipment Fleet Manager',
      portalSubtitle: 'Owner View • Fleet Assets & Dispute Filing',
      defaultRoute: AppRoutes.rentalYard,
      icon: Icons.domain_rounded,
      badgeColor: Color(0xFF0284C7), // Sky Blue
    ),
    PersonaModel(
      id: 'fleet_operator',
      name: '👷 Fleet Operator',
      email: 'operator@dealer.com',
      role: 'FLEET_OPERATOR',
      scope: 'ABC Infrastructure (Job-Site Renter)',
      portalTitle: 'ABC Infrastructure • Job-Site Operator',
      portalSubtitle: 'Excavator Rig #01 • In-Cab Telematics & Alarms',
      defaultRoute: AppRoutes.console,
      icon: Icons.engineering_rounded,
      badgeColor: Color(0xFFD97706), // Amber
    ),
    PersonaModel(
      id: 'insurer_allianz',
      name: '🛡️ Allianz Claims Adjuster',
      email: 'claims@allianz.com',
      role: 'INSURER_ADJUSTER',
      scope: 'Allianz SE (Claim Decision Maker)',
      portalTitle: 'Allianz Industrial Claims Portal',
      portalSubtitle: 'Dispute Investigation • Claim CLM-2026-9042',
      defaultRoute: AppRoutes.claimReplay,
      icon: Icons.verified_user_rounded,
      badgeColor: Color(0xFF0F766E), // Deep Teal
    ),
    PersonaModel(
      id: 'external_auditor',
      name: '🏛️ External Auditor',
      email: 'auditor@tuv.com',
      role: 'AUDITOR',
      scope: 'TÜV SÜD (Compliance / ISO-13374)',
      portalTitle: 'TÜV SÜD • Cryptographic Audit Console',
      portalSubtitle: 'Independent Hash Ledger • RFC 8785 Proofs',
      defaultRoute: AppRoutes.auditor,
      icon: Icons.account_balance_rounded,
      badgeColor: Color(0xFF2563EB), // Blue
    ),
  ];

  late final Rx<PersonaModel> currentPersona;

  // Operational Negligence Simulation State
  final isAlertDismissed = true.obs; // Default: Operator neglected alert
  final isServiceDispatched = false.obs;
  final alertActionFeedback = '⚠️ ALERT DISMISSED: Operator clicked [ Dismiss & Run ] at 14:02 UTC. Negligence recorded to ledger.'.obs;
  final isSubmittingAlertAction = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Default to Super Admin on the platform directory home
    currentPersona = personas[0].obs;
  }

  bool get isAdmin => currentPersona.value.role == 'SUPER_ADMIN';
  bool get isRentalManager => currentPersona.value.role == 'RENTAL_MANAGER';
  bool get isOperator => currentPersona.value.role == 'FLEET_OPERATOR';
  bool get isInsurer => currentPersona.value.role == 'INSURER_ADJUSTER';
  bool get isAuditor => currentPersona.value.role == 'AUDITOR';

  void switchPersona(String personaId) {
    final match = personas.firstWhere((p) => p.id == personaId, orElse: () => personas[0]);
    currentPersona.value = match;

    // Dynamically navigate to the persona's dedicated console
    if (Get.currentRoute != match.defaultRoute) {
      Get.toNamed(match.defaultRoute);
    }
  }

  void dismissAlert() => recordOperatorAlertAction('DISMISS_AND_RUN');
  void dispatchService() => recordOperatorAlertAction('DISPATCH_SERVICE');

  Future<void> recordOperatorAlertAction(String action) async {
    isSubmittingAlertAction.value = true;
    try {
      final dioClient = Get.find<DioClient>();
      await dioClient.dio.post(
        '/api/v1/industrial/operations/alert-action',
        data: {
          'alert_id': 'ALT-20240101-211',
          'cycle_id': 211,
          'asset_id': 'hydraulic_rig_01',
          'action': action,
          'technician_id': action == 'DISPATCH_SERVICE' ? 'TECH-904' : null,
          'notes': action == 'DISPATCH_SERVICE'
              ? 'Emergency work order #WO-9912 generated. Field crew en route.'
              : 'Operator bypassed alarm to meet daily excavation quota.',
        },
      );
    } catch (_) {
      // Offline fallback
    } finally {
      if (action == 'DISPATCH_SERVICE') {
        isAlertDismissed.value = false;
        isServiceDispatched.value = true;
        alertActionFeedback.value = '🛠️ SERVICE DISPATCHED: Work order #WO-9912 generated. Rig parked safely. Warranty preserved!';
      } else {
        isAlertDismissed.value = true;
        isServiceDispatched.value = false;
        alertActionFeedback.value = '⚠️ ALERT DISMISSED: Operator clicked [ Dismiss & Run ]. Negligence recorded to SHA-256 ledger!';
      }
      isSubmittingAlertAction.value = false;
    }
  }
}
