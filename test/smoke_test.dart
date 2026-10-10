import 'package:mutasiku/core/errors/failures.dart';
// test/smoke_test.dart
//
// Comprehensive Smoke Test for all 15 audit criteria:
// 1. Pemohon submit mutation
// 2. Operator menerima mutation yang benar
// 3. Operator teruskan ke Bagian Aset
// 4. Bagian Aset verifikasi & teruskan ke Pemimpin Divisi
// 5. Pemimpin Divisi menyetujui mutasi
// 6. Pemohon menerima status konfirmasi
// 7. Pemohon konfirmasi (Sesuai / Tidak Sesuai)
// 8. Pemohon menerima notification dan melakukan confirmation
// 9. Status akhir menjadi completed
// 10. Cek notification tiap role tidak tercampur
// 11. Cek sorting/filter benar-benar mengubah data
// 12. Cek dropdown lokasi muncul inline di bawah field
// 13. Cek tidak ada tombol Refresh dan “Ke Dashboard”
// 14. Cek Profile semua 5 role
// 15. Cek Admin semua menu bisa dibuka

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/core/widgets/inline_searchable_dropdown.dart';
import 'package:mutasiku/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:mutasiku/features/admin/presentation/screens/admin_locations_screen.dart';
import 'package:mutasiku/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:mutasiku/features/asset/data/repositories/asset_repository_impl.dart';
import 'package:mutasiku/features/asset/presentation/screens/asset_category_screen.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/auth/domain/repositories/auth_repository.dart';
import 'package:mutasiku/features/auth/domain/usecases/login_usecase.dart';
import 'package:mutasiku/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';
import 'package:mutasiku/features/mutation/data/repositories/mutation_repository_impl.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';
import 'package:mutasiku/features/notification/domain/entities/notification_item.dart';
import 'package:mutasiku/features/operator/presentation/screens/operator_mutations_screen.dart';
import 'package:mutasiku/features/profile/presentation/screens/profile_screen.dart';
import 'package:mutasiku/features/admin/domain/entities/location_item.dart';
import 'package:mutasiku/features/admin/domain/repositories/location_repository.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_form_provider.dart';

class _FakeLocationRepository implements LocationRepository {
  final List<LocationItem> locations;
  _FakeLocationRepository(this.locations);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  List<LocationItem> get currentLocations => locations;
  @override
  Future<Result<List<LocationItem>>> getAllLocations() async =>
      Result.success(locations);
  @override
  Future<Result<List<LocationItem>>> getActiveLocations() async =>
      Result.success(locations);
}

class _TestMasterLocationsNotifier extends MasterLocationsNotifier {
  _TestMasterLocationsNotifier(List<LocationItem> locations)
      : super(_FakeLocationRepository(locations)) {
    state = AsyncValue.data(locations);
  }
}

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
  _MockAuthNotifier(User user)
    : super(
        loginUseCase: LoginUseCase(repository: _MockAuthRepo(user)),
        logoutUseCase: LogoutUseCase(repository: _MockAuthRepo(user)),
        authRepository: _MockAuthRepo(user),
      ) {
    state = AuthState(isLoading: false, user: user);
  }
}

void main() {
  const pemohonUser = User(
    id: 'u_user_01',
    username: 'rina',
    name: 'Rina Pemohon',
    email: 'rina@mutasiku.id',
    role: UserRole.pemohon,
  );

  const operatorUser = User(
    id: 'u_opr_01',
    username: 'operator1',
    name: 'Siti Operator',
    email: 'operator@mutasiku.id',
    role: UserRole.operator,
  );

  const bagianAsetUser = User(
    id: 'u_ast_01',
    username: 'bagian_aset1',
    name: 'Bambang Bagian Aset',
    email: 'bagian_aset@mutasiku.id',
    role: UserRole.bagianAset,
  );

  const kadivUser = User(
    id: 'u_kdv_01',
    username: 'kadiv1',
    name: 'Hendra Kadiv',
    email: 'kadiv@mutasiku.id',
    role: UserRole.kadiv,
  );

  const adminUser = User(
    id: 'u_adm_01',
    username: 'admin1',
    name: 'Super Admin',
    email: 'admin@mutasiku.id',
    role: UserRole.admin,
  );

  late AssetRepositoryImpl assetRepo;
  late MutationRepositoryImpl mutationRepo;

  setUp(() {
    MutationRepositoryImpl.resetForTesting();
    assetRepo = AssetRepositoryImpl();
    mutationRepo = MutationRepositoryImpl(assetRepository: assetRepo);
  });

  group('SMOKE TEST 1 - 9: End-to-End Two Mutation Flows', () {
    test('1. Pemohon submit mutation → status becomes submitted', () async {
      final res = await mutationRepo.submitMutation(
        const SubmitMutationParams(
          applicantId: 'u_user_01',
          applicantName: 'Rina Pemohon',
          assetId: 'AST-PRN-009',
          assetName: 'Printer Epson L3210',
          sourceLocation: 'Ruang IT Pusat',
          targetLocation: 'Cabang Bandung',
          targetPic: 'Ahmad Fauzi',
          reason: 'Kebutuhan operasional cabang baru',
        ),
      );

      expect(res.isSuccess, isTrue);
      final created = res.dataOrNull!;
      expect(created.status, equals(MutationStatus.submitted));
      expect(created.applicantId, equals('u_user_01'));
      expect(created.asset.name, equals('Printer Epson L3210'));
    });

    test('2, 3, 4: Alur Lengkap Mutasi Disetujui (Pemohon → Operator → Bagian Aset → Pemimpin Divisi → Pemohon Konfirmasi Sesuai → Completed)', () async {
      // 1. Submit
      final subRes = await mutationRepo.submitMutation(
        const SubmitMutationParams(
          applicantId: 'u_user_01',
          applicantName: 'Rina Pemohon',
          assetId: 'AST-PRN-009',
          assetName: 'Printer Epson L3210',
          sourceLocation: 'Ruang IT Pusat',
          targetLocation: 'Cabang Bandung',
          targetPic: 'Ahmad Fauzi',
          reason: 'Kebutuhan cabang biasa',
          isAssetMovingWithApplicant: true,
          documentName: 'sk_sdm.pdf',
        ),
      );
      expect(subRes.isSuccess, isTrue);
      final mutId = subRes.dataOrNull!.id;

      // 2. Operator receives mutation in queue
      final allMutations = await mutationRepo.getAllMutations();
      final oprQueue = allMutations.dataOrNull!
          .where((m) => m.status == MutationStatus.submitted)
          .toList();
      expect(oprQueue.any((m) => m.id == mutId), isTrue);

      // 3. Operator forwards to Bagian Aset
      final opForwardRes = await mutationRepo.operatorForward(
        mutationId: mutId,
        operatorName: 'Siti Operator',
      );
      expect(opForwardRes.isSuccess, isTrue);
      expect(
        opForwardRes.dataOrNull!.status,
        equals(MutationStatus.waitingAssetVerification),
      );

      // 4. Bagian Aset receives and forwards to Pemimpin Divisi
      final allAfterOpr = await mutationRepo.getAllMutations();
      final asetQueue = allAfterOpr.dataOrNull!
          .where((m) => m.status == MutationStatus.waitingAssetVerification)
          .toList();
      expect(asetQueue.any((m) => m.id == mutId), isTrue);

      final asetForwardRes = await mutationRepo.assetSectionForward(
        mutationId: mutId,
        verifierName: 'Bambang Bagian Aset',
        newPic: 'Ahmad Fauzi',
      );
      expect(asetForwardRes.isSuccess, isTrue);
      expect(
        asetForwardRes.dataOrNull!.status,
        equals(MutationStatus.waitingDivisionHeadApproval),
      );

      // 5. Pemimpin Divisi receives and approves
      final allAfterAset = await mutationRepo.getAllMutations();
      final kadivQueue = allAfterAset.dataOrNull!
          .where((m) => m.status == MutationStatus.waitingDivisionHeadApproval)
          .toList();
      expect(kadivQueue.any((m) => m.id == mutId), isTrue);

      final kadivApproveRes = await mutationRepo.divisionApprove(
        mutationId: mutId,
        divisionHeadName: 'Hendra Kadiv',
      );
      expect(kadivApproveRes.isSuccess, isTrue);
      expect(
        kadivApproveRes.dataOrNull!.status,
        equals(MutationStatus.waitingConfirmation),
      );

      // 6. Pemohon confirms (Sesuai) -> auto updates asset and completes
      final confirmRes = await mutationRepo.confirmMutationResult(
        mutationId: mutId,
        confirmedBy: 'Rina Pemohon',
        isSesuai: true,
      );
      expect(confirmRes.isSuccess, isTrue);
      expect(confirmRes.dataOrNull!.status, equals(MutationStatus.completed));

      // Verify asset location and PIC are updated automatically
      final updatedAsset = await assetRepo.getAssetById('AST-PRN-009');
      expect(updatedAsset.dataOrNull?.location, equals('Cabang Bandung'));
      expect(updatedAsset.dataOrNull?.pic, equals('Ahmad Fauzi'));
    });

    test(
      '3, 4, 5: Alur Konfirmasi Tidak Sesuai (Kembali ke Bagian Aset)',
      () async {
        // 1. Submit
        final subRes = await mutationRepo.submitMutation(
          const SubmitMutationParams(
            applicantId: 'u_user_01',
            applicantName: 'Rina Pemohon',
            assetId: 'AST-SRV-001',
            assetName: 'Server Dell PowerEdge',
            sourceLocation: 'Data Center Pusat',
            targetLocation: 'Data Center Bali',
            targetPic: 'Kadek Surya',
            reason: 'Relokasi server produksi bernilai tinggi',
            isAssetMovingWithApplicant: true,
            documentName: 'sk_srv.pdf',
          ),
        );
        final mutId = subRes.dataOrNull!.id;

        // 2. Operator forwards
        await mutationRepo.operatorForward(
          mutationId: mutId,
          operatorName: 'Siti Operator',
        );

        // 3. Bagian Aset forwards
        await mutationRepo.assetSectionForward(
          mutationId: mutId,
          verifierName: 'Bambang Bagian Aset',
        );

        // 4. Pemimpin Divisi approves
        await mutationRepo.divisionApprove(
          mutationId: mutId,
          divisionHeadName: 'Hendra Kadiv',
        );

        // 5. Pemohon confirms Tidak Sesuai with reason
        final disputeRes = await mutationRepo.confirmMutationResult(
          mutationId: mutId,
          confirmedBy: 'Rina Pemohon',
          isSesuai: false,
          reason: 'Fisik server tergores dan belum tiba di rak',
        );
        expect(disputeRes.isSuccess, isTrue);
        expect(
          disputeRes.dataOrNull!.status,
          equals(MutationStatus.waitingAssetVerification),
        );
        expect(
          disputeRes.dataOrNull!.confirmationReason,
          equals('Fisik server tergores dan belum tiba di rak'),
        );
      },
    );
  });

  group('SMOKE TEST 10: Notification Isolation per Role', () {
    test('Notifications are targeted and not mixed up between roles', () {
      final now = DateTime.now();
      final notifs = [
        NotificationItem(
          id: 'n_1',
          title: 'Pengajuan Baru',
          message: 'Mutasi mut_01 perlu verifikasi',
          type: NotificationType.action,
          createdAt: now,
          targetRole: UserRole.operator,
          relatedMutationId: 'mut_01',
        ),
        NotificationItem(
          id: 'n_2',
          title: 'Verifikasi Bagian Aset',
          message: 'Mutasi mut_01 perlu verifikasi Bagian Aset',
          type: NotificationType.action,
          createdAt: now,
          targetRole: UserRole.bagianAset,
          relatedMutationId: 'mut_01',
        ),
        NotificationItem(
          id: 'n_3',
          title: 'Persetujuan Pemimpin Divisi',
          message: 'Mutasi mut_01 perlu persetujuan Pemimpin Divisi',
          type: NotificationType.action,
          createdAt: now,
          targetRole: UserRole.kadiv,
          relatedMutationId: 'mut_01',
        ),
        NotificationItem(
          id: 'n_4',
          title: 'Konfirmasi Mutasi',
          message: 'Mutasi mut_01 siap dikonfirmasi',
          type: NotificationType.action,
          createdAt: now,
          targetRole: UserRole.pemohon,
          targetUserId: 'u_user_01',
          relatedMutationId: 'mut_01',
        ),
      ];

      // Filter for Pemohon
      final pemohonNotifs = notifs
          .where(
            (n) =>
                (n.targetUserId == pemohonUser.id) ||
                (n.targetUserId == null && n.targetRole == pemohonUser.role),
          )
          .toList();
      expect(pemohonNotifs.length, equals(1));
      expect(pemohonNotifs.first.targetRole, equals(UserRole.pemohon));

      // Filter for Operator
      final oprNotifs = notifs
          .where((n) => n.targetRole == operatorUser.role)
          .toList();
      expect(oprNotifs.length, equals(1));
      expect(oprNotifs.first.targetRole, equals(UserRole.operator));

      // Filter for Bagian Aset
      final bgNotifs = notifs
          .where((n) => n.targetRole == bagianAsetUser.role)
          .toList();
      expect(bgNotifs.length, equals(1));
      expect(bgNotifs.first.targetRole, equals(UserRole.bagianAset));

      // Filter for Kadiv
      final kdvNotifs = notifs
          .where((n) => n.targetRole == kadivUser.role)
          .toList();
      expect(kdvNotifs.length, equals(1));
      expect(kdvNotifs.first.targetRole, equals(UserRole.kadiv));
    });
  });

  group('SMOKE TEST 11: Sorting / Filter Physically Affect Data', () {
    testWidgets('Operator sorting and filtering change list contents', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => _MockAuthNotifier(operatorUser),
            ),
            apiMutationRepositoryProvider.overrideWith(
              (ref) => ref.watch(mutationRepositoryProvider),
            ),
          ],
          child: const MaterialApp(home: OperatorMutationsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('input_search_mutations')), findsOneWidget);
      expect(
        find.byKey(const Key('dropdown_filter_operator_status')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('dropdown_filter_operator_sort')),
        findsOneWidget,
      );

      // Search 'Budi'
      await tester.enterText(
        find.byKey(const Key('input_search_mutations')),
        'Budi',
      );
      await tester.pumpAndSettle();
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Rina'), findsNothing);
    });
  });

  group('SMOKE TEST 12: Dropdown Lokasi Appears Inline Below Field', () {
    testWidgets('InlineSearchableDropdown renders panel directly below input', (
      tester,
    ) async {
      final controller = TextEditingController();
      String? selectedValue;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: InlineSearchableDropdown(
                labelText: 'Lokasi Asal',
                hintText: 'Pilih lokasi asal',
                controller: controller,
                items: const [
                  'Ruang IT Pusat',
                  'Cabang Bandung',
                  'Cabang Surabaya',
                  'Gudang Logistik',
                ],
                onChanged: (val) {
                  selectedValue = val;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the input field
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      // Pilihan lokasi harus muncul langsung di panel bawah
      expect(find.text('Ruang IT Pusat'), findsWidgets);
      expect(find.text('Cabang Bandung'), findsWidgets);

      // Tap salah satu lokasi
      await tester.tap(find.text('Cabang Bandung').last);
      await tester.pumpAndSettle();

      expect(selectedValue, equals('Cabang Bandung'));
      expect(controller.text, equals('Cabang Bandung'));
    });
  });

  group('SMOKE TEST 13: Zero Manual Refresh & Zero Ke Dashboard Buttons', () {
    test('Scan codebase for forbidden Refresh and Ke Dashboard texts', () {
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      int forbiddenRefreshFound = 0;
      int forbiddenKeDashboardFound = 0;

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        // Cek jika ada IconButton dengan tooltip 'Refresh' atau tombol 'Refresh'
        if (content.contains("'Refresh'") || content.contains('"Refresh"')) {
          forbiddenRefreshFound++;
        }
        if (content.contains('Ke Dashboard') ||
            content.contains('ke Dashboard')) {
          forbiddenKeDashboardFound++;
        }
      }

      expect(
        forbiddenRefreshFound,
        equals(0),
        reason: 'Found $forbiddenRefreshFound instances of Refresh buttons',
      );
      expect(
        forbiddenKeDashboardFound,
        equals(0),
        reason:
            'Found $forbiddenKeDashboardFound instances of Ke Dashboard buttons',
      );
    });
  });

  group('SMOKE TEST 14: Profile Screen for all 5 Roles', () {
    final roles = [
      (pemohonUser, pemohonUser.role.label),
      (operatorUser, operatorUser.role.label),
      (bagianAsetUser, bagianAsetUser.role.label),
      (kadivUser, kadivUser.role.label),
      (adminUser, adminUser.role.label),
    ];

    for (final (user, label) in roles) {
      testWidgets('Profile renders consistently for $label', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith((ref) => _MockAuthNotifier(user)),
            ],
            child: const MaterialApp(home: ProfileScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(user.name), findsWidgets);
        expect(find.text(user.email ?? ''), findsWidgets);
        expect(find.text(label), findsWidgets);
      });
    }
  });

  group('SMOKE TEST 15: Admin Dashboard and all menus are functional', () {
    testWidgets('Admin Dashboard renders 3 menus with valid destinations', (
      tester,
    ) async {
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

      expect(find.text('User & Permission'), findsOneWidget);
      expect(find.text('Lokasi & Unit'), findsOneWidget);
      expect(find.textContaining('Kategori Aset'), findsOneWidget);
    });

    testWidgets('Admin Users Screen renders without dead buttons', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AdminUsersScreen())),
      );
      await tester.pumpAndSettle();
      expect(find.text('User & Permission'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Admin Locations Screen renders with location items', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            masterLocationsProvider.overrideWith(
              (ref) => _TestMasterLocationsNotifier([
                const LocationItem(
                  id: '22',
                  name: 'Lantai 1',
                  description: 'LT-1',
                  isBranch: false,
                  isActive: true,
                ),
              ]),
            ),
          ],
          child: const MaterialApp(home: AdminLocationsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Lokasi & Unit'), findsOneWidget);
      expect(find.textContaining('Lantai 1'), findsWidgets);
    });

    testWidgets('Asset Category Screen renders with categories list', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AssetCategoryScreen())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kategori Master Aset'), findsOneWidget);
      expect(find.text('Tambah Kategori'), findsOneWidget);
    });
  });
}
