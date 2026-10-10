import 'package:mutasiku/core/errors/failures.dart';
// test/features/pemohon/pemohon_create_mutation_asset_picker_test.dart
//
// Tests for Asset Picker in PemohonCreateMutationScreen:
// a. Daftar aset tampil
// b. User memilih aset
// c. _selectedAssetId terisi
// d. Nama / serial number terisi dari master aset & menjadi read-only
// e. Submit mengirim asset ID yang benar
// f. Submit tanpa memilih aset ditolak dengan validasi UI

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/core/services/document_picker_service.dart';
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
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';
import 'package:mutasiku/features/admin/domain/entities/location_item.dart';
import 'package:mutasiku/features/admin/domain/repositories/location_repository.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_form_provider.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';
import 'package:mutasiku/features/pemohon/presentation/screens/pemohon_create_mutation_screen.dart';

class _FakeLocationRepository implements LocationRepository {
  static const _locations = [
    LocationItem(id: '1', name: 'Kantor Pusat', isActive: true),
    LocationItem(id: '2', name: 'Gedung A', isActive: true),
    LocationItem(id: '3', name: 'Gedung B', isActive: true),
    LocationItem(id: '4', name: 'Ruang Divisi Umum', isActive: true),
    LocationItem(id: '7', name: 'Cabang Surabaya', isActive: true),
    LocationItem(id: '8', name: 'Cabang Bandung', isActive: true),
    LocationItem(id: '9', name: 'Cabang Semarang', isActive: true),
  ];

  @override
  List<LocationItem> get currentLocations => _locations;

  @override
  Future<Result<List<LocationItem>>> getAllLocations() async =>
      const Result.success(_locations);

  @override
  Future<Result<List<LocationItem>>> getActiveLocations() async =>
      const Result.success(_locations);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthRepository implements AuthRepository {
  final User user;
  _FakeAuthRepository(this.user);

  @override
  Future<Result<User?>> getCurrentUser() async => Result.success(user);

  @override
  Future<Result<User>> login({
    required String username,
    required String password,
  }) async => throw UnimplementedError();

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
    return Result.success(user.copyWith(mustChangePassword: false));
  }
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(User user)
    : super(
        loginUseCase: LoginUseCase(repository: _FakeAuthRepository(user)),
        logoutUseCase: LogoutUseCase(repository: _FakeAuthRepository(user)),
        authRepository: _FakeAuthRepository(user),
      ) {
    state = AuthState(isLoading: false, user: user);
  }
}

class _FakeMutationRepository implements MutationRepository {
  SubmitMutationParams? lastSubmittedParams;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Result<Mutation>> submitMutation(SubmitMutationParams params) async {
    lastSubmittedParams = params;
    final mutation = Mutation(
      id: 'mut_999',
      ticketNumber: 'MUT-TEST-999',
      asset: Asset(
        id: params.assetId ?? 'unknown',
        assetCode: 'AST-TEST-001',
        name: params.assetName,
        category: const AssetCategory(
          id: 'cat_1',
          code: 'ELK',
          name: 'Elektronik',
        ),
        location: params.sourceLocation,
        pic: params.currentPic ?? 'PIC',
        status: AssetStatus.inMutation,
        condition: 'Baik',
        acquisitionYear: 2024,
      ),
      applicantId: params.applicantId,
      applicantName: params.applicantName ?? 'Pemohon',
      currentLocation: params.sourceLocation,
      targetLocation: params.targetLocation,
      currentPic: params.currentPic ?? 'PIC',
      targetPic: params.targetPic,
      reason: params.reason,
      documentName: params.documentName,
      status: MutationStatus.submitted,
      createdAt: DateTime.now(),
    );
    return Result.success(mutation);
  }
}

class _ErrorSwallowingObserver extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {}
}

void main() {
  const testUser = User(
    id: '2',
    username: 'pemohon',
    name: 'User Pemohon',
    email: 'pemohon@mutasiku.test',
    role: UserRole.pemohon,
    department: 'Teknologi Informasi',
  );

  final testAssets = [
    const Asset(
      id: '1',
      assetCode: 'AST-ELK-2024-001',
      name: 'Laptop Lenovo ThinkPad T14',
      category: AssetCategory(id: '1', code: 'ELK', name: 'Elektronik'),
      location: 'Gedung Utama Lt. 3 - Divisi TI',
      pic: 'User Pemohon',
      status: AssetStatus.available,
      condition: 'Baik',
      serialNumber: 'SN-TP-2024-001',
      acquisitionYear: 2024,
    ),
    const Asset(
      id: '2',
      assetCode: 'AST-ELK-2024-002',
      name: 'Monitor Dell UltraSharp 27"',
      category: AssetCategory(id: '1', code: 'ELK', name: 'Elektronik'),
      location: 'Gedung Utama Lt. 3 - Divisi TI',
      pic: 'User Pemohon',
      status: AssetStatus.available,
      condition: 'Baik',
      serialNumber: 'SN-MN-2024-002',
      acquisitionYear: 2024,
    ),
  ];

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

  Widget buildTestWidget({
    required _FakeMutationRepository mutationRepo,
    List<Asset>? userAssets,
    bool simulateError = false,
  }) {
    return ProviderScope(
      observers: [_ErrorSwallowingObserver()],
      overrides: [
        mutationRepositoryProvider.overrideWithValue(mutationRepo),
        apiMutationRepositoryProvider.overrideWithValue(mutationRepo),
        authStateProvider.overrideWith((ref) => _TestAuthNotifier(testUser)),
        userResponsibleAssetsProvider.overrideWith((ref) async {
          if (simulateError) {
            throw Exception('Gagal memuat master aset dari API');
          }
          return userAssets ?? testAssets;
        }),
        locationRepositoryProvider.overrideWithValue(_FakeLocationRepository()),
      ],
      child: const MaterialApp(home: PemohonCreateMutationScreen()),
    );
  }

  group('Pemohon Create Mutation Asset Picker Tests', () {
    testWidgets(
      'a & b & c & d: Daftar aset tampil, user memilih aset, _selectedAssetId dan field terisi read-only',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final mutationRepo = _FakeMutationRepository();
        await tester.pumpWidget(buildTestWidget(mutationRepo: mutationRepo));
        await tester.pumpAndSettle();

        // a. Verifikasi dropdown selector aset tersedia
        final assetDropdown = find.byKey(const Key('dropdown_select_asset'));
        expect(assetDropdown, findsOneWidget);

        // Buka dropdown
        await tester.ensureVisible(assetDropdown);
        await tester.tap(assetDropdown);
        await tester.pumpAndSettle();

        // Daftar aset tampil dengan nama dan kode aset
        expect(find.textContaining('Laptop Lenovo ThinkPad T14'), findsWidgets);
        expect(
          find.textContaining('Monitor Dell UltraSharp 27"'),
          findsWidgets,
        );

        // b. User memilih aset Laptop
        await tester.tap(
          find.textContaining('Laptop Lenovo ThinkPad T14').last,
        );
        await tester.pumpAndSettle();

        // c & d. Nama aset dan serial number / kode aset terisi dari master aset
        expect(find.text('Laptop Lenovo ThinkPad T14'), findsWidgets);
        expect(find.text('SN-TP-2024-001'), findsWidgets);

        // Badge aset terdaftar muncul
        expect(
          find.text('Aset terdaftar di SIMAK BMN / Master Data'),
          findsOneWidget,
        );

        // Lokasi asal dan PIC saat ini otomatis terisi dari aset
        expect(find.text('Gedung Utama Lt. 3 - Divisi TI'), findsWidgets);
        expect(find.text('User Pemohon'), findsWidgets);
      },
    );

    testWidgets('e: Submit mengirim asset ID database yang benar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mutationRepo = _FakeMutationRepository();
      await tester.pumpWidget(buildTestWidget(mutationRepo: mutationRepo));
      await tester.pumpAndSettle();

      // Pilih aset Monitor (ID: '2')
      final assetDropdown = find.byKey(const Key('dropdown_select_asset'));
      await tester.ensureVisible(assetDropdown);
      await tester.tap(assetDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Monitor Dell UltraSharp 27"').last);
      await tester.pumpAndSettle();

      // Pilih lokasi tujuan
      final targetLocationDropdown = find.byKey(
        const Key('dropdown_target_location'),
      );
      await tester.ensureVisible(targetLocationDropdown);
      await tester.tap(targetLocationDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cabang Bandung').last);
      await tester.pumpAndSettle();

      // Isi alasan
      final reasonField = find.widgetWithText(
        TextFormField,
        'Jelaskan alasan mutasi...',
      );
      await tester.ensureVisible(reasonField);
      await tester.enterText(
        reasonField,
        'Mutasi monitor kerja untuk penugasan cabang',
      );
      await tester.pumpAndSettle();

      // Unggah berkas SK
      final uploadBtn = find.text('Unggah Berkas');
      await tester.ensureVisible(uploadBtn);
      await tester.tap(uploadBtn);
      await tester.pumpAndSettle();

      // Tap Kirim Pengajuan
      final submitBtn = find.text('Kirim Pengajuan Mutasi');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Modal konfirmasi harus muncul
      expect(find.text('Kirim Pengajuan?'), findsOneWidget);

      // Konfirmasi pengajuan
      final confirmBtn = find.widgetWithText(ElevatedButton, 'Kirim Pengajuan');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // e. Verifikasi params yang dikirim ke repository mengandung assetId database yang benar ('2')
      expect(mutationRepo.lastSubmittedParams, isNotNull);
      expect(mutationRepo.lastSubmittedParams!.assetId, '2');
      expect(
        mutationRepo.lastSubmittedParams!.assetName,
        'Monitor Dell UltraSharp 27"',
      );
    });

    testWidgets(
      'f: Submit tanpa memilih aset ditolak dengan pesan validasi yang jelas',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final mutationRepo = _FakeMutationRepository();
        await tester.pumpWidget(buildTestWidget(mutationRepo: mutationRepo));
        await tester.pumpAndSettle();

        // Pilih lokasi tujuan dan alasan tanpa memilih aset
        final targetLocationDropdown = find.byKey(
          const Key('dropdown_target_location'),
        );
        await tester.ensureVisible(targetLocationDropdown);
        await tester.tap(targetLocationDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cabang Bandung').last);
        await tester.pumpAndSettle();

        final reasonField = find.widgetWithText(
          TextFormField,
          'Jelaskan alasan mutasi...',
        );
        await tester.ensureVisible(reasonField);
        await tester.enterText(reasonField, 'Alasan mutasi uji coba');
        await tester.pumpAndSettle();

        // Unggah berkas
        final uploadBtn = find.text('Unggah Berkas');
        await tester.ensureVisible(uploadBtn);
        await tester.tap(uploadBtn);
        await tester.pumpAndSettle();

        // Submit
        final submitBtn = find.text('Kirim Pengajuan Mutasi');
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        // f. Form ditolak dengan validasi pemilihan aset
        expect(find.text('Silakan pilih aset terlebih dahulu.'), findsWidgets);
        // Modal konfirmasi tidak boleh muncul
        expect(find.text('Kirim Pengajuan?'), findsNothing);
        // Tidak ada pengiriman ke repo
        expect(mutationRepo.lastSubmittedParams, isNull);
      },
    );

    testWidgets(
      'Empty state: Tampil saat user tidak memiliki aset tanggung jawab',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final mutationRepo = _FakeMutationRepository();
        await tester.pumpWidget(
          buildTestWidget(mutationRepo: mutationRepo, userAssets: []),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Tidak ada aset terdaftar yang terikat sebagai tanggung jawab Anda.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Error state: Tampil pesan error dan tombol coba lagi saat API aset gagal',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final mutationRepo = _FakeMutationRepository();
        await tester.pumpWidget(
          buildTestWidget(mutationRepo: mutationRepo, simulateError: true),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Gagal memuat master aset dari server.'),
          findsOneWidget,
        );
        expect(find.text('Coba lagi'), findsOneWidget);
      },
    );
  });
}
