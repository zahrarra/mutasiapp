// lib/app/router/route_guards.dart
//
// Route guards & RBAC authorization helper.
// Sumber: SKILLS.md §6 (rbac), TECHNICAL-DESIGN.md §6,
// PROJECT-SETUP.md §8, ROLE-FLOW.md §10.

import 'package:flutter/foundation.dart';

import '../../features/auth/domain/entities/user_role.dart';
import 'route_names.dart';

/// Navigation guard & RBAC evaluation.
abstract final class RouteGuards {
  /// Memeriksa apakah [role] berhak mengakses route [location].
  static bool canAccessRoute(UserRole? role, String location) {
    // User belum memiliki role.
    if (role == null) {
      return location == RouteNames.loginPath ||
          location == RouteNames.landingPath;
    }

    // Common routes yang tersedia untuk semua role yang sudah login.
    if (location == RouteNames.dashboardPath ||
        location == RouteNames.unauthorizedPath ||
        location == RouteNames.assetsPath ||
        location == RouteNames.profilePath ||
        location.startsWith('/assets/')) {
      return true;
    }

    // Role-based prefix validation.
    // Admin, Pemohon, Operator, Kabag, Kadiv, Staff Aset.
    if (location.startsWith(role.routePrefix)) {
      return true;
    }

    // Menolak akses lintas role.
    // Contoh: Pemohon mencoba membuka /kabag atau /admin.
    return false;
  }

  /// Redirect handler untuk go_router.
  static String? handleRedirect({
    required bool isAuthenticated,
    required UserRole? role,
    required String currentLocation,
  }) {
    // Route yang dapat diakses tanpa login.
    final isPublic =
        currentLocation == RouteNames.loginPath ||
        currentLocation == RouteNames.landingPath;

    // 1. Belum login dan mencoba mengakses route protected.
    if (!isAuthenticated && !isPublic) {
      debugPrint(
        '[RouteGuard] Unauthenticated user redirected to '
        '${RouteNames.landingPath}',
      );

      return RouteNames.landingPath;
    }

    // 2. Sudah login tetapi mencoba membuka Landing/Login.
    if (isAuthenticated &&
        (currentLocation == RouteNames.loginPath ||
            currentLocation == RouteNames.landingPath)) {
      final defaultTarget = role?.defaultRoute ?? RouteNames.dashboardPath;

      debugPrint(
        '[RouteGuard] Authenticated user redirected to $defaultTarget',
      );

      return defaultTarget;
    }

    // 3. Memeriksa RBAC untuk route yang terproteksi.
    if (isAuthenticated && !canAccessRoute(role, currentLocation)) {
      debugPrint(
        '[RouteGuard] Access denied for role '
        '${role?.displayName} on route $currentLocation',
      );

      return RouteNames.unauthorizedPath;
    }

    // 4. Tidak perlu redirect.
    return null;
  }
}
