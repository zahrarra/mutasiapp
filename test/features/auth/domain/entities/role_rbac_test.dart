// test/features/auth/domain/entities/role_rbac_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/app/router/route_guards.dart';
import 'package:mutasiku/app/router/route_names.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_permission.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';

void main() {
  group('Authentication + RBAC tests for 6 roles', () {
    test('All 6 roles have unique default routes and prefixes', () {
      expect(UserRole.admin.defaultRoute, RouteNames.adminDashboardPath);
      expect(UserRole.pemohon.defaultRoute, RouteNames.pemohonDashboardPath);
      expect(UserRole.operator.defaultRoute, RouteNames.operatorDashboardPath);
      expect(UserRole.kabagAset.defaultRoute, RouteNames.kabagDashboardPath);
      expect(UserRole.kadiv.defaultRoute, RouteNames.kadivDashboardPath);
      expect(UserRole.staffAset.defaultRoute, RouteNames.staffDashboardPath);
    });

    test('Role permissions check', () {
      const adminUser = User(
        id: 'u1',
        username: 'admin',
        name: 'Admin User',
        role: UserRole.admin,
      );

      const pemohonUser = User(
        id: 'u2',
        username: 'pemohon',
        name: 'Pemohon User',
        role: UserRole.pemohon,
      );

      const operatorUser = User(
        id: 'u3',
        username: 'operator',
        name: 'Operator User',
        role: UserRole.operator,
      );

      expect(adminUser.hasPermission(UserPermission.manageMasterData), true);
      expect(adminUser.hasPermission(UserPermission.approveKabag), false);

      expect(pemohonUser.hasPermission(UserPermission.submitMutation), true);
      expect(pemohonUser.hasPermission(UserPermission.manageMasterData), false);

      expect(operatorUser.hasPermission(UserPermission.verifyMutation), true);
      expect(operatorUser.hasPermission(UserPermission.approveKadiv), false);
    });

    test('RouteGuards prevents cross-role access', () {
      // Pemohon attempting to access /admin/dashboard -> denied
      expect(
        RouteGuards.canAccessRoute(UserRole.pemohon, RouteNames.adminDashboardPath),
        false,
      );

      // Pemohon accessing /pemohon/dashboard -> allowed
      expect(
        RouteGuards.canAccessRoute(UserRole.pemohon, RouteNames.pemohonDashboardPath),
        true,
      );

      // Operator attempting to access /kabag/dashboard -> denied
      expect(
        RouteGuards.canAccessRoute(UserRole.operator, RouteNames.kabagDashboardPath),
        false,
      );

      // Staff Aset accessing /staff-aset/dashboard -> allowed
      expect(
        RouteGuards.canAccessRoute(UserRole.staffAset, RouteNames.staffDashboardPath),
        true,
      );
    });

    test('RouteGuards redirects logged-in user to default role route from /login', () {
      final redirectAdmin = RouteGuards.handleRedirect(
        isAuthenticated: true,
        role: UserRole.admin,
        currentLocation: RouteNames.loginPath,
      );
      expect(redirectAdmin, RouteNames.adminDashboardPath);

      final redirectKadiv = RouteGuards.handleRedirect(
        isAuthenticated: true,
        role: UserRole.kadiv,
        currentLocation: RouteNames.loginPath,
      );
      expect(redirectKadiv, RouteNames.kadivDashboardPath);
    });
  });
}
