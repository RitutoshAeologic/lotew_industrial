import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/persona_controller.dart';
import 'app_routes.dart';

class RoleGuardMiddleware extends GetMiddleware {
  final List<String> allowedRoles;

  RoleGuardMiddleware({required this.allowedRoles, int? priority}) : super(priority: priority ?? 1);

  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<PersonaController>()) {
      return null;
    }

    final currentRole = PersonaController.to.currentPersona.value.role;
    if (!allowedRoles.contains(currentRole) && currentRole != 'SUPER_ADMIN') {
      // 403 Forbidden Access Notification
      Future.microtask(() {
        Get.snackbar(
          'HTTP 403: Access Restricted',
          'Your active role ($currentRole) is not authorized to access $route. Enforcing tenant boundary.',
          backgroundColor: Colors.red.shade900,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.security_rounded, color: Colors.white),
          duration: const Duration(seconds: 4),
        );
      });

      // Redirect to persona default home route
      return RouteSettings(name: PersonaController.to.currentPersona.value.defaultRoute);
    }

    return null;
  }
}
