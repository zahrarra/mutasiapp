// test/app/router/route_guards_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/app/router/route_guards.dart';
import 'package:mutasiku/app/router/route_names.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';

void main() {
  group('RouteGuards redirect handler tests', () {
    test('Redirects unauthenticated user to /login', () {
      final redirect = RouteGuards.handleRedirect(
        isAuthenticated: false,
        role: null,
        currentLocation: RouteNames.dashboardPath,
      );

      expect(redirect, RouteNames.loginPath);
    });

    test('Does not redirect unauthenticated user who is already on /login', () {
      final redirect = RouteGuards.handleRedirect(
        isAuthenticated: false,
        role: null,
        currentLocation: RouteNames.loginPath,
      );

      expect(redirect, isNull);
    });

    test(
      'Redirects authenticated user from /login to role default dashboard',
      () {
        final redirect = RouteGuards.handleRedirect(
          isAuthenticated: true,
          role: UserRole.pemohon,
          currentLocation: RouteNames.loginPath,
        );

        expect(redirect, RouteNames.pemohonDashboardPath);
      },
    );

    test('Allows authenticated user to remain on dashboard', () {
      final redirect = RouteGuards.handleRedirect(
        isAuthenticated: true,
        role: UserRole.pemohon,
        currentLocation: RouteNames.pemohonDashboardPath,
      );

      expect(redirect, isNull);
    });

    test('Redirects authenticated user with mustChangePassword to /change-password', () {
      final redirect = RouteGuards.handleRedirect(
        isAuthenticated: true,
        mustChangePassword: true,
        role: UserRole.pemohon,
        currentLocation: RouteNames.loginPath,
      );

      expect(redirect, RouteNames.changePasswordPath);
    });

    test('Blocks dashboard and redirects to /change-password when mustChangePassword is true', () {
      final redirect = RouteGuards.handleRedirect(
        isAuthenticated: true,
        mustChangePassword: true,
        role: UserRole.pemohon,
        currentLocation: RouteNames.pemohonDashboardPath,
      );

      expect(redirect, RouteNames.changePasswordPath);
    });

    test('Blocks dashboard for all 5 roles and redirects to /change-password when mustChangePassword is true', () {
      final roleDashboardPairs = [
        (UserRole.admin, RouteNames.adminDashboardPath),
        (UserRole.pemohon, RouteNames.pemohonDashboardPath),
        (UserRole.operator, RouteNames.operatorDashboardPath),
        (UserRole.bagianAset, RouteNames.bagianAsetDashboardPath),
        (UserRole.kadiv, RouteNames.kadivDashboardPath),
      ];

      for (final (role, dashboardPath) in roleDashboardPairs) {
        final redirect = RouteGuards.handleRedirect(
          isAuthenticated: true,
          mustChangePassword: true,
          role: role,
          currentLocation: dashboardPath,
        );

        expect(
          redirect,
          RouteNames.changePasswordPath,
          reason: 'Role ${role.name} should be blocked from dashboard and redirected to /change-password',
        );
      }
    });

    test('Allows user on /change-password when mustChangePassword is true', () {
      final redirect = RouteGuards.handleRedirect(
        isAuthenticated: true,
        mustChangePassword: true,
        role: UserRole.pemohon,
        currentLocation: RouteNames.changePasswordPath,
      );

      expect(redirect, isNull);
    });

    test('Redirects user away from /change-password to dashboard when mustChangePassword is false', () {
      final redirect = RouteGuards.handleRedirect(
        isAuthenticated: true,
        mustChangePassword: false,
        role: UserRole.pemohon,
        currentLocation: RouteNames.changePasswordPath,
      );

      expect(redirect, RouteNames.pemohonDashboardPath);
    });
  });
}
