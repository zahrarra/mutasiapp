// test/features/asset/create_asset_feature_test.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:mutasiku/core/network/api_client.dart';
import 'package:mutasiku/core/providers/core_providers.dart';
import 'package:mutasiku/features/admin/data/repositories/location_repository_impl.dart';
import 'package:mutasiku/features/asset/data/repositories/asset_repository_impl.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_category.dart';
import 'package:mutasiku/features/asset/domain/repositories/asset_repository.dart';
import 'package:mutasiku/features/asset/domain/usecases/create_asset_usecase.dart';
import 'package:mutasiku/features/asset/presentation/providers/asset_provider.dart';
import 'package:mutasiku/features/asset/presentation/widgets/admin_create_asset_dialog.dart';
import 'package:mutasiku/features/auth/data/repositories/user_repository_impl.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_form_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Create Asset Repository Tests', () {
    const testParams = CreateAssetParams(
      assetCode: 'AST-TEST-001',
      name: 'MacBook Pro M3 Test',
      assetCategoryId: '1',
      locationId: '2',
      picId: '3',
      condition: 'Baik',
      serialNumber: 'SN-TEST-8899',
      acquisitionYear: 2026,
      usageYear: 2026,
      isActive: true,
    );

    test('In-memory fallback createAsset returns newly created asset', () async {
      final repository = AssetRepositoryImpl();
      final result = await repository.createAsset(testParams);

      expect(result.isSuccess, isTrue);
      final asset = result.dataOrNull!;
      expect(asset.assetCode, equals('AST-TEST-001'));
      expect(asset.name, equals('MacBook Pro M3 Test'));
      expect(asset.condition, equals('Baik'));
      expect(asset.serialNumber, equals('SN-TEST-8899'));
      expect(asset.acquisitionYear, equals(2026));
    });

    test('HTTP API success response parses AssetModel correctly', () async {
      late String sentPath;
      late Map<String, dynamic> sentBody;

      final mockClient = MockClient((request) async {
        sentPath = request.url.path;
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Aset berhasil dibuat.',
            'data': {
              'id': 99,
              'asset_code': sentBody['asset_code'],
              'name': sentBody['name'],
              'category': {
                'id': 1,
                'code': 'ELK',
                'name': 'Elektronik & IT',
              },
              'location': {
                'id': 2,
                'name': 'Kantor Pusat - Lt. 3',
              },
              'pic': {
                'id': 3,
                'name': 'Budi Santoso',
              },
              'condition': 'Baik',
              'serial_number': 'SN-TEST-8899',
              'acquisition_year': 2026,
              'usage_year': 2026,
              'status': 'available',
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        baseUrl: 'http://test.local',
      );
      final repo = AssetRepositoryImpl(apiClient: apiClient);

      final result = await repo.createAsset(testParams);

      expect(result.isSuccess, isTrue);
      expect(sentPath, equals('/api/v1/admin/assets'));
      expect(sentBody['asset_code'], equals('AST-TEST-001'));
      expect(sentBody['asset_category_id'], equals(1));
      expect(sentBody['location_id'], equals(2));
      expect(sentBody['pic_id'], equals(3));

      final asset = result.dataOrNull!;
      expect(asset.id, equals('99'));
      expect(asset.assetCode, equals('AST-TEST-001'));
      expect(asset.name, equals('MacBook Pro M3 Test'));
      expect(asset.category.name, equals('Elektronik & IT'));
      expect(asset.location, equals('Kantor Pusat - Lt. 3'));
      expect(asset.pic, equals('Budi Santoso'));
    });

    test('HTTP API validation error returns AppFailure', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Nomor seri sudah terdaftar.',
            'errors': {
              'serial_number': ['Nomor seri sudah terdaftar.'],
            },
          }),
          422,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        baseUrl: 'http://test.local',
      );
      final repo = AssetRepositoryImpl(apiClient: apiClient);

      final result = await repo.createAsset(testParams);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.userMessage, contains('Nomor seri sudah terdaftar.'));
    });
  });

  group('Create Asset UseCase & Notifier Tests', () {
    const testParams = CreateAssetParams(
      assetCode: 'AST-TEST-002',
      name: 'Printer HP LaserJet',
      assetCategoryId: '1',
      locationId: '2',
      picId: '3',
      condition: 'Baik',
      serialNumber: 'HP-SN-1234',
      acquisitionYear: 2025,
      isActive: true,
    );

    test('CreateAssetUseCase calls repository successfully', () async {
      final repo = AssetRepositoryImpl();
      final useCase = CreateAssetUseCase(repository: repo);

      final result = await useCase(testParams);
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.assetCode, equals('AST-TEST-002'));
    });

    test('CreateAssetNotifier sets loading and success state, invalidates assetListProvider', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/admin/assets' && request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Aset berhasil dibuat.',
              'data': {
                'id': 105,
                'asset_code': 'AST-TEST-002',
                'name': 'Printer HP LaserJet',
                'category': {'id': 1, 'code': 'ELK', 'name': 'Elektronik'},
                'location': {'id': 2, 'name': 'Gudang Pusat'},
                'pic': {'id': 3, 'name': 'Staff IT'},
                'condition': 'Baik',
                'serial_number': 'HP-SN-1234',
                'acquisition_year': 2025,
                'status': 'available',
              },
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/v1/assets') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'OK',
              'data': [
                {
                  'id': 105,
                  'asset_code': 'AST-TEST-002',
                  'name': 'Printer HP LaserJet',
                  'category': {'id': 1, 'code': 'ELK', 'name': 'Elektronik'},
                  'location': {'id': 2, 'name': 'Gudang Pusat'},
                  'pic': {'id': 3, 'name': 'Staff IT'},
                  'condition': 'Baik',
                  'serial_number': 'HP-SN-1234',
                  'acquisition_year': 2025,
                  'status': 'available',
                }
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final testApiClient = ApiClient(
        httpClient: mockClient,
        baseUrl: 'http://test.local',
      );

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(testApiClient),
        ],
      );

      final notifier = container.read(createAssetNotifierProvider.notifier);
      final asset = await notifier.createAsset(testParams);

      expect(asset, isNotNull);
      expect(asset!.id, equals('105'));

      final state = container.read(createAssetNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.result?.assetCode, equals('AST-TEST-002'));

      // Verifikasi assetListProvider ter-refresh dengan data baru dari API
      final refreshedList = await container.read(assetListProvider.future);
      expect(refreshedList.any((a) => a.id == '105'), isTrue);
    });

    test('CreateAssetNotifier sets error state upon failure', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Kode aset sudah digunakan.',
          }),
          422,
          headers: {'content-type': 'application/json'},
        );
      });

      final testApiClient = ApiClient(
        httpClient: mockClient,
        baseUrl: 'http://test.local',
      );

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(testApiClient),
        ],
      );

      final notifier = container.read(createAssetNotifierProvider.notifier);
      final asset = await notifier.createAsset(testParams);

      expect(asset, isNull);
      final state = container.read(createAssetNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, contains('Kode aset sudah digunakan.'));
      expect(state.result, isNull);
    });
  });

  group('AdminCreateAssetDialog Widget & Validation Tests', () {
    const dummyCategory = AssetCategory(
      id: 'cat_1',
      code: 'ELK',
      name: 'Elektronik & IT',
      isActive: true,
    );

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          assetCategoriesProvider.overrideWith(
            (ref) => Future.value([dummyCategory]),
          ),
          masterLocationsProvider.overrideWith(
            (ref) => MasterLocationsNotifier(LocationRepositoryImpl.instance),
          ),
          masterUsersProvider.overrideWith(
            (ref) => MasterUsersNotifier(UserRepositoryImpl()),
          ),
          createAssetUseCaseProvider.overrideWith(
            (ref) => CreateAssetUseCase(repository: AssetRepositoryImpl()),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AdminCreateAssetDialog(),
          ),
        ),
      );
    }

    testWidgets('Renders all form fields and labels', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Tambah Aset Baru'), findsOneWidget);
      expect(find.text('Kode Aset *'), findsOneWidget);
      expect(find.text('Nomor Seri (SN) *'), findsOneWidget);
      expect(find.text('Nama Aset *'), findsOneWidget);
      expect(find.text('Kategori Aset *'), findsOneWidget);
      expect(find.text('Lokasi / Unit Kerja *'), findsOneWidget);
      expect(find.text('Penanggung Jawab (PIC) *'), findsOneWidget);
      expect(find.text('Kondisi Aset *'), findsOneWidget);
      expect(find.text('Tahun Perolehan *'), findsOneWidget);
      expect(find.text('Simpan Aset'), findsOneWidget);
    });

    testWidgets('Triggers validation error on empty required fields submit', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final saveButton = find.widgetWithText(ElevatedButton, 'Simpan Aset');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Kode aset wajib diisi'), findsOneWidget);
      expect(find.text('Nomor seri wajib diisi'), findsOneWidget);
      expect(find.text('Nama aset wajib diisi'), findsOneWidget);
    });

    testWidgets('Triggers invalid year error if acquisition year < 1900', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final currentYear = DateTime.now().year.toString();
      final yearFinder = find.widgetWithText(TextFormField, currentYear);
      await tester.enterText(yearFinder, '1850');
      await tester.pumpAndSettle();

      final saveButton = find.widgetWithText(ElevatedButton, 'Simpan Aset');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('1900 -'), findsOneWidget);
    });

    testWidgets('Full form submission flow execution', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Isi Kode Aset
      final codeField = find.byType(TextFormField).at(0);
      await tester.enterText(codeField, 'AST-ELK-999');

      // Isi Nomor Seri
      final snField = find.byType(TextFormField).at(1);
      await tester.enterText(snField, 'SN-999999');

      // Isi Nama Aset
      final nameField = find.byType(TextFormField).at(2);
      await tester.enterText(nameField, 'Monitor 4K Test');

      // Pilih Kategori Dropdown
      final catFinder = find.byWidgetPredicate(
        (w) => w is DropdownButtonFormField<String> && w.decoration.hintText == 'Pilih Kategori Aset',
      );
      final catDropdown = tester.widget<DropdownButtonFormField<String>>(catFinder);
      catDropdown.onChanged?.call('cat_1');
      await tester.pumpAndSettle();

      // Pilih Lokasi Dropdown
      final locFinder = find.byWidgetPredicate(
        (w) => w is DropdownButtonFormField<String> && w.decoration.hintText == 'Pilih Lokasi Penempatan',
      );
      final locDropdown = tester.widget<DropdownButtonFormField<String>>(locFinder);
      locDropdown.onChanged?.call('22');
      await tester.pumpAndSettle();

      // Pilih PIC Dropdown
      final picFinder = find.byWidgetPredicate(
        (w) => w is DropdownButtonFormField<String> && w.decoration.hintText == 'Pilih User PIC',
      );
      final picDropdown = tester.widget<DropdownButtonFormField<String>>(picFinder);
      picDropdown.onChanged?.call('usr_pemohon');
      await tester.pumpAndSettle();

      // Tap Simpan Aset
      final saveButton = find.widgetWithText(ElevatedButton, 'Simpan Aset');
      await tester.tap(saveButton);
      await tester.pump();
      await tester.pumpAndSettle();

      // Verifikasi dialog selesai
      expect(find.byType(AdminCreateAssetDialog), findsNothing);
    });
  });
}
