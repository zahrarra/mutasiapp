// test/features/admin/admin_audit_log_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mutasiku/app/router/route_names.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/features/admin/domain/entities/location_item.dart';
import 'package:mutasiku/features/admin/domain/repositories/location_repository.dart';
import 'package:mutasiku/features/admin/presentation/screens/admin_audit_log_screen.dart';
import 'package:mutasiku/features/asset/domain/entities/asset.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_category.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_status.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/auth/domain/repositories/auth_repository.dart';
import 'package:mutasiku/features/auth/domain/repositories/user_repository.dart';
import 'package:mutasiku/features/auth/domain/usecases/login_usecase.dart';
import 'package:mutasiku/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_form_provider.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';

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
    return Result.success(user!);
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

class _FakeUserRepository implements UserRepository {
  final List<User> users;
  _FakeUserRepository(this.users);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<Result<List<User>>> getAllUsers() async => Result.success(users);
}

class _FakeLocationRepository implements LocationRepository {
  final List<LocationItem> locations;
  _FakeLocationRepository(this.locations);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  List<LocationItem> get currentLocations => locations;
  @override
  Future<Result<List<LocationItem>>> getAllLocations() async => Result.success(locations);
  @override
  Future<Result<List<LocationItem>>> getActiveLocations() async => Result.success(locations);
}

class _TestMasterUsersNotifier extends MasterUsersNotifier {
  _TestMasterUsersNotifier(List<User> users) : super(_FakeUserRepository(users)) {
    state = AsyncValue.data(users);
  }
}

class _TestMasterLocationsNotifier extends MasterLocationsNotifier {
  _TestMasterLocationsNotifier(List<LocationItem> locations) : super(_FakeLocationRepository(locations)) {
    state = AsyncValue.data(locations);
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

  const testUser = User(
    id: 'usr_1',
    name: 'Pegawai Testing',
    username: 'pegawai',
    role: UserRole.operator,
    email: 'pegawai@mutasiku.id',
    department: 'Divisi Operasional',
    isActive: true,
  );

  const testLocation = LocationItem(
    id: 'loc_1',
    name: 'KCU Palu',
    description: 'CAB-PLU-KCU',
    isBranch: true,
    isActive: true,
  );

  final testMutation = Mutation(
    id: 'mut_1',
    ticketNumber: 'TI-2026-001',
    applicantId: 'usr_1',
    applicantName: 'Pegawai Testing',
    asset: const Asset(
      id: 'ast_1',
      assetCode: 'AST-001',
      name: 'Laptop Lenovo',
      category: AssetCategory(id: '1', code: 'TI', name: 'Aset TI'),
      location: 'KCU Palu',
      pic: 'Pegawai Testing',
      status: AssetStatus.available,
      condition: 'Baik',
      serialNumber: 'SN-001',
      acquisitionYear: 2024,
    ),
    currentLocation: 'KCU Palu',
    targetLocation: 'Cabang Donggala',
    currentPic: 'Pegawai Testing',
    targetPic: 'Pegawai Testing',
    reason: 'Kebutuhan tugas',
    isAssetMovingWithApplicant: true,
    status: MutationStatus.submitted,
    createdAt: DateTime.now(),
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
        adminMutationsProvider.overrideWith((ref) async => [testMutation]),
        masterUsersProvider.overrideWith((ref) => _TestMasterUsersNotifier([testUser])),
        masterLocationsProvider.overrideWith((ref) => _TestMasterLocationsNotifier([testLocation])),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('AdminAuditLogScreen Tests', () {
    testWidgets('renders page header, search, filter chips, and log cards', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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

      // Verify dynamic audit log cards from providers are present
      expect(find.text('Pengajuan Mutasi TI-2026-001'), findsOneWidget);
      expect(find.text('Penugasan Akun Pegawai Testing'), findsOneWidget);
      expect(find.text('Unit Lokasi KCU Palu'), findsOneWidget);
      expect(find.text('Sinkronisasi Backend MutasiKu'), findsOneWidget);

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

      await tester.enterText(searchField, 'KCU Palu');
      await tester.pumpAndSettle();

      expect(find.text('Unit Lokasi KCU Palu'), findsOneWidget);
      expect(find.text('Penugasan Akun Pegawai Testing'), findsNothing);
    });

    testWidgets('filters log items when category chip is selected', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('User & Role'));
      await tester.pumpAndSettle();

      expect(find.text('Penugasan Akun Pegawai Testing'), findsOneWidget);
      expect(find.text('Unit Lokasi KCU Palu'), findsNothing);
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
