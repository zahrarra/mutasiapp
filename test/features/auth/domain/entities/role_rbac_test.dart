// test/features/auth/domain/entities/role_rbac_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/app/router/route_guards.dart';
import 'package:mutasiku/app/router/route_names.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_permission.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';

void main() {
  group('Authentication + RBAC tests for 5 roles', () {
    test('All 5 roles have unique default routes and prefixes', () {
      expect(UserRole.admin.defaultRoute, RouteNames.adminDashboardPath);
      expect(UserRole.pemohon.defaultRoute, RouteNames.pemohonDashboardPath);
      expect(UserRole.operator.defaultRoute, RouteNames.operatorDashboardPath);
      expect(
        UserRole.bagianAset.defaultRoute,
        RouteNames.bagianAsetDashboardPath,
      );
      expect(UserRole.kadiv.defaultRoute, RouteNames.kadivDashboardPath);
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

      const bagianAsetUser = User(
        id: 'u4',
        username: 'bagian_aset',
        name: 'Bagian Aset User',
        role: UserRole.bagianAset,
      );

      const kadivUser = User(
        id: 'u5',
        username: 'kadiv',
        name: 'Kadiv User',
        role: UserRole.kadiv,
      );

      expect(adminUser.hasPermission(UserPermission.manageMasterData), true);
      expect(adminUser.hasPermission(UserPermission.verifyAssetData), false);

      expect(pemohonUser.hasPermission(UserPermission.submitMutation), true);
      expect(pemohonUser.hasPermission(UserPermission.manageMasterData), false);

      expect(operatorUser.hasPermission(UserPermission.verifyMutation), true);
      expect(operatorUser.hasPermission(UserPermission.approveKadiv), false);

      expect(
        bagianAsetUser.hasPermission(UserPermission.verifyAssetData),
        true,
      );
      expect(
        bagianAsetUser.hasPermission(UserPermission.manageMasterData),
        false,
      );

      expect(kadivUser.hasPermission(UserPermission.approveKadiv), true);
      expect(kadivUser.hasPermission(UserPermission.verifyAssetData), false);
    });

    test('RouteGuards prevents cross-role access', () {
      // Pemohon attempting to access /admin/dashboard -> denied
      expect(
        RouteGuards.canAccessRoute(
          UserRole.pemohon,
          RouteNames.adminDashboardPath,
        ),
        false,
      );

      // Pemohon accessing /pemohon/dashboard -> allowed
      expect(
        RouteGuards.canAccessRoute(
          UserRole.pemohon,
          RouteNames.pemohonDashboardPath,
        ),
        true,
      );

      // Operator attempting to access /bagian-aset/dashboard -> denied
      expect(
        RouteGuards.canAccessRoute(
          UserRole.operator,
          RouteNames.bagianAsetDashboardPath,
        ),
        false,
      );

      // Bagian Aset accessing /bagian-aset/dashboard -> allowed
      expect(
        RouteGuards.canAccessRoute(
          UserRole.bagianAset,
          RouteNames.bagianAsetDashboardPath,
        ),
        true,
      );
    });

    test(
      'RouteGuards redirects logged-in user to default role route from /login',
      () {
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
      },
    );
  });
}
