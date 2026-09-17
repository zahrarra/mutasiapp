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

    test('Redirects authenticated user from /login to role default dashboard', () {
      final redirect = RouteGuards.handleRedirect(
        isAuthenticated: true,
        role: UserRole.pemohon,
        currentLocation: RouteNames.loginPath,
      );

      expect(redirect, RouteNames.pemohonDashboardPath);
    });

    test('Allows authenticated user to remain on dashboard', () {
      final redirect = RouteGuards.handleRedirect(
        isAuthenticated: true,
        role: UserRole.pemohon,
        currentLocation: RouteNames.pemohonDashboardPath,
      );

      expect(redirect, isNull);
    });
  });
}
