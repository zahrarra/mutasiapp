import 'package:mutasiku/core/errors/failures.dart';
// test/features/admin/admin_dashboard_render_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/auth/domain/repositories/auth_repository.dart';
import 'package:mutasiku/features/auth/domain/usecases/login_usecase.dart';
import 'package:mutasiku/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';

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

class _MockAuthNotifier extends AuthNotifier {
  _MockAuthNotifier(User? user)
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
    name: 'Admin Master',
    role: UserRole.admin,
    email: 'admin@mutasiku.id',
    isActive: true,
  );

  group('AdminDashboardScreen Stitch 1:1 Rendering Tests', () {
    testWidgets('Renders on Chrome Desktop 1280x800 without null error', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => _MockAuthNotifier(adminUser),
            ),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Halo, Administrator! 👋'), findsOneWidget);
      expect(find.text('RINGKASAN MASTER DATA SISTEM'), findsOneWidget);
      expect(find.text('Kelola Master Data & Konfigurasi'), findsOneWidget);
      expect(find.text('Log Audit & Aktivitas Terkini'), findsOneWidget);
      expect(find.text('Tambah Master Data / Role Baru'), findsOneWidget);
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Master Data'), findsOneWidget);
      expect(find.text('Audit Log'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
    });

    testWidgets('Renders on Tablet 768x1024 without null error', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => _MockAuthNotifier(adminUser),
            ),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Halo, Administrator! 👋'), findsOneWidget);
      expect(find.text('RINGKASAN MASTER DATA SISTEM'), findsOneWidget);
      expect(find.text('Kelola Master Data & Konfigurasi'), findsOneWidget);
    });

    testWidgets('Renders on Mobile 360x640 without null error or overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => _MockAuthNotifier(adminUser),
            ),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Halo, Administrator! 👋'), findsOneWidget);
      expect(find.text('RINGKASAN MASTER DATA SISTEM'), findsOneWidget);
      expect(find.text('Tambah Master Data / Role Baru'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Renders on Ultra-wide/Large Desktop 1920x1080 without maxWidth clamp and without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith(
                (ref) => _MockAuthNotifier(adminUser),
              ),
            ],
            child: const MaterialApp(home: AdminDashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Halo, Administrator! 👋'), findsOneWidget);
        expect(find.text('RINGKASAN MASTER DATA SISTEM'), findsOneWidget);
        expect(find.text('Kelola Master Data & Konfigurasi'), findsOneWidget);
        expect(find.text('Log Audit & Aktivitas Terkini'), findsOneWidget);
        expect(find.text('Tambah Master Data / Role Baru'), findsOneWidget);

        // Verify that the top hero stretches to fill the 1920px viewport
        final heroFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color ==
                  const Color(0xFF0F3D56),
        );
        expect(heroFinder, findsWidgets);
        final heroSize = tester.getSize(heroFinder.first);
        expect(heroSize.width, equals(1920.0));

        // Verify action cards render in 3-column responsive layout
        expect(find.byKey(const Key('action_user_management')), findsOneWidget);
        final userCardSize = tester.getSize(
          find.byKey(const Key('action_user_management')),
        );
        // On 1920px with 48px padding and 3 columns, each card is ~590px (substantially wider than the old ~500px capped at 1040)
        expect(userCardSize.width, greaterThan(500.0));

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Renders safely with null/unauthenticated user fallback', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => _MockAuthNotifier(null)),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Halo, Administrator! 👋'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
