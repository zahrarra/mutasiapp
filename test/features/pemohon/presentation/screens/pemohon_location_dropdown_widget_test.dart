// test/features/pemohon/presentation/screens/pemohon_location_dropdown_widget_test.dart
//
// Widget test membuktikan bahwa nama lokasi dari respons API tampil pada
// widget dropdown formulir Pemohon (PemohonCreateMutationScreen), bukan hardcode,
// dan data lama tidak dipertahankan setelah provider selesai memuat.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/core/network/api_client.dart';
import 'package:mutasiku/core/providers/core_providers.dart';
import 'package:mutasiku/core/services/document_picker_service.dart';
import 'package:mutasiku/core/widgets/inline_searchable_dropdown.dart';
import 'package:mutasiku/features/asset/domain/entities/asset.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_category.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_status.dart';
import 'package:mutasiku/features/asset/presentation/providers/asset_provider.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/auth/domain/repositories/auth_repository.dart';
import 'package:mutasiku/features/auth/domain/usecases/login_usecase.dart';
import 'package:mutasiku/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';
import 'package:mutasiku/features/pemohon/presentation/screens/pemohon_create_mutation_screen.dart';

class _FakeAuthRepo implements AuthRepository {
  final User user;
  _FakeAuthRepo(this.user);

  @override
  Future<Result<User?>> getCurrentUser() async => Result.success(user);

  @override
  Future<Result<User>> login({
    required String username,
    required String password,
  }) async => Result.success(user);

  @override
  Future<void> logout() async {}

  @override
  Future<Result<User>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async => Result.success(user);
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(User user)
      : super(
          loginUseCase: LoginUseCase(repository: _FakeAuthRepo(user)),
          logoutUseCase: LogoutUseCase(repository: _FakeAuthRepo(user)),
          authRepository: _FakeAuthRepo(user),
        ) {
    state = AuthState(isLoading: false, user: user);
  }
}

class _DummyMutationRepo implements MutationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testUser = User(
    id: 'user_1',
    name: 'Pemohon MutasiKu',
    username: 'pemohon',
    email: 'pemohon@mutasiku.test',
    role: UserRole.pemohon,
    department: 'Kantor Pusat',
  );

  final testAsset = Asset(
    id: 'ast_1',
    assetCode: 'AST-TI-2026-001',
    name: 'Laptop Lenovo ThinkPad L14 Gen 4',
    category: const AssetCategory(id: '1', code: 'TI', name: 'Teknologi Informasi'),
    location: 'Kantor Pusat',
    pic: 'Pemohon MutasiKu',
    status: AssetStatus.available,
    condition: 'Baik',
    serialNumber: 'PF-2024-001',
    acquisitionYear: 2024,
  );

  setUp(() {
    DocumentPickerService.testPicker = () async {
      return const DocumentPickerResult.success(
        PickedDocument(name: 'SK_SDM.pdf', size: 1024 * 50),
      );
    };
  });

  tearDown(() {
    DocumentPickerService.testPicker = null;
  });

  Widget createWidgetUnderTest({required ApiClient apiClient}) {
    return ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        authStateProvider.overrideWith((ref) => _TestAuthNotifier(testUser)),
        userResponsibleAssetsProvider.overrideWith((ref) async => [testAsset]),
        mutationRepositoryProvider.overrideWithValue(_DummyMutationRepo()),
        apiMutationRepositoryProvider.overrideWithValue(_DummyMutationRepo()),
      ],
      child: const MaterialApp(
        home: PemohonCreateMutationScreen(),
      ),
    );
  }

  group('PEMOHON LOCATION DROPDOWN WIDGET AUDIT', () {
    testWidgets(
      '1. Nama lokasi resmi acuan pengguna (KCU Palu, Cabang Donggala, dsb.) tampil pada dropdown tujuan formulir Pemohon, dan 7 lokasi lama TIDAK tampil',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        // Mock API response dengan daftar lokasi resmi acuan pengguna
        final mockClient = MockClient((request) async {
          if (request.url.path == '/api/v1/locations' ||
              request.url.path == '/api/v1/admin/locations') {
            return http.Response(
              jsonEncode({
                'success': true,
                'message': 'Daftar lokasi aktif berhasil diambil',
                'data': [
                  {'id': 37, 'name': 'KCU Palu', 'code': 'CAB-PLU-KCU', 'is_active': true},
                  {'id': 38, 'name': 'Cabang Tawaeli', 'code': 'CAB-TWL', 'is_active': true},
                  {'id': 39, 'name': 'Cabang Sigi', 'code': 'CAB-SIGI', 'is_active': true},
                  {'id': 40, 'name': 'Cabang Donggala', 'code': 'CAB-DGL', 'is_active': true},
                  {'id': 41, 'name': 'Cabang Palu Barat', 'code': 'CAB-PLUBAR', 'is_active': true},
                  {'id': 42, 'name': 'Cabang Tinombala', 'code': 'CAB-TNM', 'is_active': true},
                  {'id': 43, 'name': 'Cabang Poso', 'code': 'CAB-POSO', 'is_active': true},
                  {'id': 44, 'name': 'Cabang Luwuk', 'code': 'CAB-LWK', 'is_active': true},
                  {'id': 45, 'name': 'Cabang Jakarta', 'code': 'CAB-JKT', 'is_active': true},
                  {'id': 46, 'name': 'Cabang Makassar', 'code': 'CAB-MKS', 'is_active': true},
                  {'id': 12, 'name': 'Lobby', 'code': 'UMUM-LOBBY', 'is_active': true},
                  {'id': 26, 'name': 'Ruang Divisi TI', 'code': 'RG-TI', 'is_active': true},
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('Not Found', 404);
        });

        final apiClient = ApiClient(
          baseUrl: 'http://127.0.0.1:8000',
          httpClient: mockClient,
        );
        apiClient.setAuthToken('valid_test_token');

        await tester.pumpWidget(createWidgetUnderTest(apiClient: apiClient));
        await tester.pumpAndSettle();

        // Cari widget dropdown lokasi tujuan
        final targetLocFinder = find.byKey(const Key('dropdown_target_location'));
        expect(targetLocFinder, findsOneWidget);

        // Scroll agar terlihat dan tap dropdown untuk membuka menu popup
        await tester.ensureVisible(targetLocFinder);
        await tester.tap(targetLocFinder);
        await tester.pumpAndSettle();

        // BUKTI 1: Nama lokasi acuan pengguna tampil di dropdown menu
        expect(find.text('KCU Palu').hitTestable(), findsOneWidget);
        expect(find.text('Cabang Donggala').hitTestable(), findsOneWidget);
        expect(find.text('Cabang Sigi').hitTestable(), findsOneWidget);
        expect(find.text('Cabang Poso').hitTestable(), findsOneWidget);
        expect(find.text('Cabang Luwuk').hitTestable(), findsOneWidget);
        expect(find.text('Cabang Makassar').hitTestable(), findsOneWidget);

        // BUKTI 2: 7 lokasi lama yang ditolak TIDAK ADA dalam pilihan dropdown
        expect(find.text('Kantor Pusat'), findsNothing);
        expect(find.text('Gedung A'), findsNothing);
        expect(find.text('Gedung B'), findsNothing);
        expect(find.text('Ruang Divisi Umum'), findsNothing);
        expect(find.text('Cabang Surabaya'), findsNothing);
        expect(find.text('Cabang Bandung'), findsNothing);
        expect(find.text('Cabang Semarang'), findsNothing);

        // Pilih salah satu lokasi: 'Cabang Donggala'
        await tester.tap(find.text('Cabang Donggala').hitTestable());
        await tester.pumpAndSettle();

        // Verifikasi bahwa 'Cabang Donggala' kini terpilih pada widget dropdown
        expect(find.text('Cabang Donggala'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Widget dropdown lokasi asal (dropdown_source_location) menyajikan lokasi acuan pengguna dan tidak menyajikan lokasi lama',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final mockClient = MockClient((request) async {
          if (request.url.path == '/api/v1/locations' ||
              request.url.path == '/api/v1/admin/locations') {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': [
                  {'id': 37, 'name': 'KCU Palu', 'code': 'CAB-PLU-KCU', 'is_active': true},
                  {'id': 39, 'name': 'Cabang Sigi', 'code': 'CAB-SIGI', 'is_active': true},
                  {'id': 40, 'name': 'Cabang Donggala', 'code': 'CAB-DGL', 'is_active': true},
                  {'id': 43, 'name': 'Cabang Poso', 'code': 'CAB-POSO', 'is_active': true},
                  {'id': 46, 'name': 'Cabang Makassar', 'code': 'CAB-MKS', 'is_active': true},
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('Not Found', 404);
        });

        final apiClient = ApiClient(
          baseUrl: 'http://127.0.0.1:8000',
          httpClient: mockClient,
        );
        apiClient.setAuthToken('valid_test_token');

        await tester.pumpWidget(createWidgetUnderTest(apiClient: apiClient));
        await tester.pumpAndSettle();

        // Buka dropdown lokasi asal melalui icon dropdown
        final sourceLocFinder = find.byKey(const Key('dropdown_source_location'));
        expect(sourceLocFinder, findsOneWidget);

        await tester.ensureVisible(sourceLocFinder);
        final dropDownIcon = find.byIcon(Icons.arrow_drop_down).last;
        await tester.tap(dropDownIcon);
        await tester.pumpAndSettle();

        // Verifikasi opsi dari respons API tersedia di list inline dropdown (item awal)
        expect(find.text('KCU Palu'), findsWidgets);
        expect(find.text('Cabang Sigi'), findsWidgets);

        // Verifikasi 7 lokasi lama tidak muncul
        expect(find.text('Cabang Surabaya'), findsNothing);
        expect(find.text('Cabang Bandung'), findsNothing);
        expect(find.text('Cabang Semarang'), findsNothing);

        // Cari 'Donggala' melalui text field pencarian dropdown
        final searchField = find.descendant(
          of: find.byType(InlineSearchableDropdown).last,
          matching: find.byType(TextField),
        );
        if (searchField.evaluate().isNotEmpty) {
          await tester.enterText(searchField.last, 'Donggala');
          await tester.pumpAndSettle();
        }

        expect(find.text('Cabang Donggala'), findsWidgets);

        // Pilih 'Cabang Donggala'
        await tester.tap(find.text('Cabang Donggala').first);
        await tester.pumpAndSettle();

        // Verifikasi teks controller lokasi asal terisi 'Cabang Donggala'
        expect(find.text('Cabang Donggala'), findsWidgets);
      },
    );

    testWidgets(
      '3. Data lokasi usang/lama tidak dipertahankan setelah provider selesai memuat lokasi baru dari API',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        // API merespons dengan lokasi acuan pengguna saja
        final mockClient = MockClient((request) async {
          if (request.url.path == '/api/v1/locations' ||
              request.url.path == '/api/v1/admin/locations') {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': [
                  {'id': 37, 'name': 'KCU Palu', 'code': 'CAB-PLU-KCU', 'is_active': true},
                  {'id': 40, 'name': 'Cabang Donggala', 'code': 'CAB-DGL', 'is_active': true},
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('Not Found', 404);
        });

        final apiClient = ApiClient(
          baseUrl: 'http://127.0.0.1:8000',
          httpClient: mockClient,
        );
        apiClient.setAuthToken('valid_test_token');

        await tester.pumpWidget(createWidgetUnderTest(apiClient: apiClient));
        await tester.pumpAndSettle();

        final targetLocFinder = find.byKey(const Key('dropdown_target_location'));
        await tester.ensureVisible(targetLocFinder);
        await tester.tap(targetLocFinder);
        await tester.pumpAndSettle();

        // Hanya KCU Palu dan Cabang Donggala yang muncul
        expect(find.text('KCU Palu').hitTestable(), findsOneWidget);
        expect(find.text('Cabang Donggala').hitTestable(), findsOneWidget);
        // Lokasi lama tidak muncul
        expect(find.text('Kantor Pusat'), findsNothing);
        expect(find.text('Cabang Surabaya'), findsNothing);
        expect(find.text('Cabang Bandung'), findsNothing);
        expect(find.text('Cabang Semarang'), findsNothing);
      },
    );
  });
}
