// lib/app/router/route_guards.dart
//
// Route guards & RBAC authorization helper.
// Sumber: SKILLS.md §6 (rbac), TECHNICAL-DESIGN.md §6, PROJECT-SETUP.md §8, ROLE-FLOW.md §10.

import 'package:flutter/foundation.dart';
import '../../features/auth/domain/entities/user_role.dart';
import 'route_names.dart';

/// Navigation guard & RBAC evaluation.
abstract final class RouteGuards {
  /// Memeriksa apakah [role] berhak mengakses route [location].
  static bool canAccessRoute(UserRole? role, String location) {
    if (role == null) {
      // Unauthenticated users can only access login
      return location == RouteNames.loginPath;
    }

    // Common routes available for all authenticated roles
    if (location == RouteNames.dashboardPath ||
        location == RouteNames.unauthorizedPath ||
        location == RouteNames.assetsPath ||
        location.startsWith('/assets/')) {
      return true;
    }

    // Role-based prefix validation
    // Admin, Pemohon, Operator, Kabag, Kadiv, Staff Aset
    if (location.startsWith(role.routePrefix)) {
      return true;
    }

    // Restrict cross-role access (e.g., Pemohon trying to access /admin or /kabag)
    return false;
  }

  /// Redirect handler untuk go_router.
  static String? handleRedirect({
    required bool isAuthenticated,
    required UserRole? role,
    required String currentLocation,
  }) {
    final isLoggingIn = currentLocation == RouteNames.loginPath;

    // 1. Belum login & mencoba mengakses protected route -> redirect ke Login
    if (!isAuthenticated && !isLoggingIn) {
      debugPrint('[RouteGuard] Unauthenticated user redirected to Login');
      return RouteNames.loginPath;
    }

    // 2. Sudah login & berada di Login -> redirect ke default route rolenya
    if (isAuthenticated && isLoggingIn) {
      final defaultTarget = role?.defaultRoute ?? RouteNames.dashboardPath;
      debugPrint('[RouteGuard] Authenticated user redirected to $defaultTarget');
      return defaultTarget;
    }

    // 3. Memeriksa RBAC permission jika mengakses route terproteksi
    if (isAuthenticated && !canAccessRoute(role, currentLocation)) {
      debugPrint('[RouteGuard] Access denied for role ${role?.displayName} on route $currentLocation');
      return RouteNames.unauthorizedPath;
    }

    return null;
  }
}
