import 'package:mutasiku/core/errors/failures.dart';
// test/features/admin/admin_audit_log_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mutasiku/app/router/route_names.dart';
import 'package:mutasiku/features/admin/presentation/screens/admin_audit_log_screen.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';

import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/features/auth/domain/repositories/auth_repository.dart';
import 'package:mutasiku/features/auth/domain/usecases/login_usecase.dart';
import 'package:mutasiku/features/auth/domain/usecases/logout_usecase.dart';

class _MockAuthRepo implements AuthRepository {
  final User? user;
  _MockAuthRepo(this.user);
  @override
  Future<Result<User?>> getCurrentUser() async => Result.success(user);
  @override
  Future<Result<User>> login({
    required String username,
    required String password,
  }) async => Result.success(user!);
  @override
  Future<void> logout() async {}
    @override
  Future<Result<User>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword.length < 8) {
      return Result.failure(
        const ValidationFailure(message: 'Password baru minimal 8 karakter.'),
      );
    }
    if (newPassword != confirmPassword) {
      return Result.failure(
        const ValidationFailure(message: 'Konfirmasi password baru tidak cocok.'),
      );
    }
    if (newPassword == currentPassword) {
      return Result.failure(
        const ValidationFailure(
          message: 'Password baru harus berbeda dengan password lama.',
        ),
      );
    }
    if (user != null) {
      return Result.success(user!.copyWith(mustChangePassword: false));
    }
    return Result.failure(
      const UnauthorizedFailure(message: 'Pengguna tidak ditemukan.'),
    );
  }
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(User? user)
    : super(
        loginUseCase: LoginUseCase(repository: _MockAuthRepo(user)),
        logoutUseCase: LogoutUseCase(repository: _MockAuthRepo(user)),
        authRepository: _MockAuthRepo(user),
      ) {
    state = AuthState(isLoading: false, user: user);
  }
}

void main() {
  const adminUser = User(
    id: 'admin_1',
    username: 'admin',
    name: 'Administrator Utama',
    role: UserRole.admin,
    email: 'admin@mutasiku.id',
    isActive: true,
  );

  Widget createSubject({
    String initialLocation = RouteNames.adminAuditLogPath,
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: RouteNames.adminDashboardPath,
          builder: (context, state) =>
              const Scaffold(body: Text('Admin Dashboard Target')),
        ),
        GoRoute(
          path: RouteNames.adminAuditLogPath,
          builder: (context, state) => const AdminAuditLogScreen(),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => _FakeAuthNotifier(adminUser)),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('AdminAuditLogScreen Tests', () {
    testWidgets('renders page header, search, filter chips, and log cards', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Log Audit Sistem'), findsOneWidget);
      expect(
        find.text('Histori pembaruan konfigurasi & rekam jejak tata kelola'),
        findsOneWidget,
      );

      // Verify Category Chips
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('User & Role'), findsOneWidget);
      expect(find.text('Master Data'), findsNWidgets(2)); // Chip and navbar
      expect(find.text('Sistem'), findsOneWidget);

      // Verify default log cards are present
      expect(find.text('Pembaruan Node Cabang'), findsOneWidget);
      expect(find.text('Penugasan Role Pegawai'), findsOneWidget);
      expect(find.text('Sinkronisasi Basis Data Aset'), findsOneWidget);

      // Verify navbar rendered with 4 admin items
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Audit Log'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);

      // Verify Audit Log tab is active (font weight w700)
      final auditNavText = tester.widget<Text>(find.text('Audit Log'));
      expect(auditNavText.style?.fontWeight, FontWeight.w700);
      expect(auditNavText.style?.color, const Color(0xFF0F3D56));
    });

    testWidgets('filters log items when search query is entered', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'Node Cabang');
      await tester.pumpAndSettle();

      expect(find.text('Pembaruan Node Cabang'), findsOneWidget);
      expect(find.text('Penugasan Role Pegawai'), findsNothing);
    });

    testWidgets('filters log items when category chip is selected', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('User & Role'));
      await tester.pumpAndSettle();

      expect(find.text('Penugasan Role Pegawai'), findsOneWidget);
      expect(find.text('Pembaruan Node Cabang'), findsNothing);
    });

    testWidgets('back button returns to previous screen normally', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: RouteNames.adminDashboardPath,
        routes: [
          GoRoute(
            path: RouteNames.adminDashboardPath,
            builder: (context, state) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => context.push(RouteNames.adminAuditLogPath),
                  child: const Text('Ke Audit Log'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: RouteNames.adminAuditLogPath,
            builder: (context, state) => const AdminAuditLogScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => _FakeAuthNotifier(adminUser),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate from dashboard to audit log
      await tester.tap(find.text('Ke Audit Log'));
      await tester.pumpAndSettle();
      expect(find.text('Log Audit Sistem'), findsOneWidget);

      // Click back button in MutasiKuPageHeader
      final backButton = find.byIcon(Icons.arrow_back);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Back on dashboard
      expect(find.text('Ke Audit Log'), findsOneWidget);
    });
  });
}
