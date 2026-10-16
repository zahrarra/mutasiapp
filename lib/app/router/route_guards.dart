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
    if (role == null) {
      return location == RouteNames.loginPath ||
          location == RouteNames.landingPath;
    }

    // Route bersama untuk semua role yang sudah login.
    if (location == RouteNames.dashboardPath ||
        location == RouteNames.unauthorizedPath ||
        location == RouteNames.profilePath ||
        location == RouteNames.changePasswordPath ||
        location == RouteNames.assetsPath ||
        location.startsWith('/assets/')) {
      return true;
    }

    // Boleh mengakses path sesuai role sendiri.
    if (location.startsWith(role.routePrefix)) {
      return true;
    }

    return false;
  }

  /// Memetakan path legacy /kabag atau /staff-aset ke rute resmi /bagian-aset PRD V1.1.
  static String mapLegacyToBagianAset(String location) {
    if (location.startsWith('/kabag/approvals') ||
        location.startsWith('/staff-aset/mutations')) {
      return RouteNames.bagianAsetVerificationsPath;
    }
    return RouteNames.bagianAsetDashboardPath;
  }

  /// Redirect handler untuk go_router.
  static String? handleRedirect({
    required bool isAuthenticated,
    required UserRole? role,
    bool mustChangePassword = false,
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
        '${RouteNames.loginPath}',
      );

      return RouteNames.loginPath;
    }

    // 2. User wajib mengganti password saat first login.
    if (isAuthenticated && mustChangePassword) {
      if (currentLocation != RouteNames.changePasswordPath) {
        debugPrint(
          '[RouteGuard] First login must change password -> redirected to '
          '${RouteNames.changePasswordPath}',
        );

        return RouteNames.changePasswordPath;
      }

      return null;
    }

    // 3. User sudah ganti password mencoba akses route change password lagi.
    if (isAuthenticated &&
        !mustChangePassword &&
        currentLocation == RouteNames.changePasswordPath) {
      final defaultTarget = role?.defaultRoute ?? RouteNames.dashboardPath;
      return defaultTarget;
    }

    // 4. Sudah login tetapi mencoba membuka Landing/Login.
    if (isAuthenticated &&
        (currentLocation == RouteNames.loginPath ||
            currentLocation == RouteNames.landingPath)) {
      final defaultTarget = role?.defaultRoute ?? RouteNames.dashboardPath;

      debugPrint(
        '[RouteGuard] Authenticated user redirected to $defaultTarget',
      );

      return defaultTarget;
    }

    // 3. Pengalihan otomatis rute legacy /kabag atau /staff-aset ke /bagian-aset resmi V1.1
    if (isAuthenticated &&
        (currentLocation.startsWith('/kabag') ||
            currentLocation.startsWith('/staff-aset'))) {
      final target = mapLegacyToBagianAset(currentLocation);
      debugPrint('[RouteGuard] Redirecting legacy $currentLocation to $target');
      return target;
    }

    // 4. Memeriksa RBAC untuk route yang terproteksi.
    if (isAuthenticated && !canAccessRoute(role, currentLocation)) {
      debugPrint(
        '[RouteGuard] Access denied for role '
        '${role?.displayName} on route $currentLocation',
      );

      return RouteNames.unauthorizedPath;
    }

    // 5. Tidak perlu redirect.
    return null;
  }
}
