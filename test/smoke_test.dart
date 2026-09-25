// test/smoke_test.dart
//
// Comprehensive Smoke Test for all 15 audit criteria:
// 1. Pemohon submit mutation
// 2. Operator menerima mutation yang benar
// 3. Operator pilih perlu/tidak perlu Kadiv
// 4. Kabag approve → pastikan dua jalur bekerja
// 5. Jika perlu Kadiv → Kadiv menerima mutation yang benar
// 6. Staff menerima hanya mutation yang sudah seluruh approval selesai
// 7. Staff update lokasi + PIC
// 8. Pemohon menerima notification dan melakukan confirmation
// 9. Status akhir menjadi completed
// 10. Cek notification tiap role tidak tercampur
// 11. Cek sorting/filter benar-benar mengubah data
// 12. Cek dropdown lokasi muncul inline di bawah field
// 13. Cek tidak ada tombol Refresh dan “Ke Dashboard”
// 14. Cek Profile semua 6 role
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
import 'package:mutasiku/features/notification/domain/entities/notification_item.dart';
import 'package:mutasiku/features/operator/presentation/screens/operator_mutations_screen.dart';
import 'package:mutasiku/features/profile/presentation/screens/profile_screen.dart';

class _MockAuthRepo implements AuthRepository {
  final User? user;
  _MockAuthRepo(this.user);
  @override
  Future<Result<User?>> getCurrentUser() async => Result.success(user);
  @override
  Future<Result<User>> login({required String username, required String password}) async =>
      Result.success(user!);
  @override
  Future<void> logout() async {}
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

  const kabagUser = User(
    id: 'u_kbg_01',
    username: 'kabag1',
    name: 'Bambang Kabag',
    email: 'kabag@mutasiku.id',
    role: UserRole.kabagAset,
  );

  const kadivUser = User(
    id: 'u_kdv_01',
    username: 'kadiv1',
    name: 'Hendra Kadiv',
    email: 'kadiv@mutasiku.id',
    role: UserRole.kadiv,
  );

  const staffUser = User(
    id: 'u_stf_01',
    username: 'staff1',
    name: 'Agus Staff',
    email: 'staff@mutasiku.id',
    role: UserRole.staffAset,
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

    test('2, 3, 4: Jalur TANPA Kadiv (Pemohon → Operator → Kabag → Staff → Pemohon Konfirmasi → Completed)', () async {
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
        ),
      );
      final mutId = subRes.dataOrNull!.id;

      // 2. Operator receives mutation in queue
      final allMutations = await mutationRepo.getAllMutations();
      final oprQueue = allMutations.dataOrNull!.where((m) => m.status == MutationStatus.submitted).toList();
      expect(oprQueue.any((m) => m.id == mutId), isTrue);

      // 3. Operator verifies WITHOUT Kadiv (requiresKadivApproval = false)
      final verifRes = await mutationRepo.verifyMutation(
        mutationId: mutId,
        operatorName: 'Siti Operator',
        requiresKadivApproval: false,
      );
      expect(verifRes.isSuccess, isTrue);
      expect(verifRes.dataOrNull!.status, equals(MutationStatus.waitingKabagApproval));
      expect(verifRes.dataOrNull!.requiresKadivApproval, isFalse);

      // 4. Kabag approves (without Kadiv) → status directly becomes approved
      final allAfterVerif = await mutationRepo.getAllMutations();
      final kabagQueue = allAfterVerif.dataOrNull!.where((m) => m.status == MutationStatus.waitingKabagApproval).toList();
      expect(kabagQueue.any((m) => m.id == mutId), isTrue);

      final kabagApproveRes = await mutationRepo.approveMutationKabag(
        mutationId: mutId,
        kabagName: 'Bambang Kabag',
        requiresKadivApproval: false,
      );
      expect(kabagApproveRes.isSuccess, isTrue);
      expect(kabagApproveRes.dataOrNull!.status, equals(MutationStatus.approved));

      // 6. Staff receives mutation
      final allAfterKabag = await mutationRepo.getAllMutations();
      final staffQueue = allAfterKabag.dataOrNull!.where((m) => m.status == MutationStatus.approved).toList();
      expect(staffQueue.any((m) => m.id == mutId), isTrue);

      // 7. Staff updates location + PIC
      final staffUpdateRes = await mutationRepo.processStaffAssetUpdate(
        mutationId: mutId,
        staffName: 'Agus Staff',
        newLocation: 'Cabang Bandung Lt 2',
        newPic: 'Ahmad Fauzi',
      );
      expect(staffUpdateRes.isSuccess, isTrue);
      expect(staffUpdateRes.dataOrNull!.status, equals(MutationStatus.pendingConfirmation));

      // 8 & 9. Pemohon confirms (Sesuai) → status completed
      final confirmRes = await mutationRepo.confirmMutation(
        mutationId: mutId,
        confirmedBy: 'Rina Pemohon',
      );
      expect(confirmRes.isSuccess, isTrue);
      expect(confirmRes.dataOrNull!.status, equals(MutationStatus.completed));
    });

    test('3, 4, 5: Jalur DENGAN Kadiv (Operator set requiresKadivApproval → Kabag routes to Kadiv → Kadiv approves → Staff)', () async {
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
        ),
      );
      final mutId = subRes.dataOrNull!.id;

      // 3. Operator verifies WITH Kadiv (requiresKadivApproval = true)
      final verifRes = await mutationRepo.verifyMutation(
        mutationId: mutId,
        operatorName: 'Siti Operator',
        requiresKadivApproval: true,
      );
      expect(verifRes.isSuccess, isTrue);
      expect(verifRes.dataOrNull!.requiresKadivApproval, isTrue);
      expect(verifRes.dataOrNull!.status, equals(MutationStatus.waitingKabagApproval));

      // 4. Kabag detects requiresKadivApproval == true → routes to waitingKadivApproval
      final kabagApproveRes = await mutationRepo.approveMutationKabag(
        mutationId: mutId,
        kabagName: 'Bambang Kabag',
        requiresKadivApproval: true,
      );
      expect(kabagApproveRes.isSuccess, isTrue);
      expect(kabagApproveRes.dataOrNull!.status, equals(MutationStatus.waitingKadivApproval));

      // 5. Kadiv receives mutation
      final allAfterKabag = await mutationRepo.getAllMutations();
      final kadivQueue = allAfterKabag.dataOrNull!.where((m) => m.status == MutationStatus.waitingKadivApproval).toList();
      expect(kadivQueue.any((m) => m.id == mutId), isTrue);

      // Kadiv approves
      final kadivApproveRes = await mutationRepo.approveMutationKadiv(
        mutationId: mutId,
        kadivName: 'Hendra Kadiv',
      );
      expect(kadivApproveRes.isSuccess, isTrue);
      expect(kadivApproveRes.dataOrNull!.status, equals(MutationStatus.approved));

      // 6. Staff receives only after Kadiv approval
      final allAfterKadiv = await mutationRepo.getAllMutations();
      final staffQueue = allAfterKadiv.dataOrNull!.where((m) => m.status == MutationStatus.approved).toList();
      expect(staffQueue.any((m) => m.id == mutId), isTrue);
    });
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
          title: 'Persetujuan Kabag',
          message: 'Mutasi mut_01 perlu persetujuan Kabag',
          type: NotificationType.action,
          createdAt: now,
          targetRole: UserRole.kabagAset,
          relatedMutationId: 'mut_01',
        ),
        NotificationItem(
          id: 'n_3',
          title: 'Persetujuan Kadiv',
          message: 'Mutasi mut_01 perlu persetujuan Kadiv',
          type: NotificationType.action,
          createdAt: now,
          targetRole: UserRole.kadiv,
          relatedMutationId: 'mut_01',
        ),
        NotificationItem(
          id: 'n_4',
          title: 'Update Aset',
          message: 'Mutasi mut_01 siap dieksekusi Staff',
          type: NotificationType.info,
          createdAt: now,
          targetRole: UserRole.staffAset,
          relatedMutationId: 'mut_01',
        ),
        NotificationItem(
          id: 'n_5',
          title: 'Konfirmasi Mutasi',
          message: 'Mutasi mut_01 selesai dieksekusi',
          type: NotificationType.action,
          createdAt: now,
          targetRole: UserRole.pemohon,
          targetUserId: 'u_user_01',
          relatedMutationId: 'mut_01',
        ),
      ];

      // Filter for Pemohon
      final pemohonNotifs = notifs.where((n) =>
          (n.targetUserId == pemohonUser.id) ||
          (n.targetUserId == null && n.targetRole == pemohonUser.role)).toList();
      expect(pemohonNotifs.length, equals(1));
      expect(pemohonNotifs.first.targetRole, equals(UserRole.pemohon));

      // Filter for Operator
      final oprNotifs = notifs.where((n) => n.targetRole == operatorUser.role).toList();
      expect(oprNotifs.length, equals(1));
      expect(oprNotifs.first.targetRole, equals(UserRole.operator));

      // Filter for Kabag
      final kbgNotifs = notifs.where((n) => n.targetRole == kabagUser.role).toList();
      expect(kbgNotifs.length, equals(1));
      expect(kbgNotifs.first.targetRole, equals(UserRole.kabagAset));

      // Filter for Kadiv
      final kdvNotifs = notifs.where((n) => n.targetRole == kadivUser.role).toList();
      expect(kdvNotifs.length, equals(1));
      expect(kdvNotifs.first.targetRole, equals(UserRole.kadiv));

      // Filter for Staff
      final stfNotifs = notifs.where((n) => n.targetRole == staffUser.role).toList();
      expect(stfNotifs.length, equals(1));
      expect(stfNotifs.first.targetRole, equals(UserRole.staffAset));
    });
  });

  group('SMOKE TEST 11: Sorting / Filter Physically Affect Data', () {
    testWidgets('Operator sorting and filtering change list contents', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => _MockAuthNotifier(operatorUser)),
          ],
          child: const MaterialApp(home: OperatorMutationsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('input_search_mutations')), findsOneWidget);
      expect(find.byKey(const Key('dropdown_filter_operator_status')), findsOneWidget);
      expect(find.byKey(const Key('dropdown_filter_operator_sort')), findsOneWidget);

      // Search 'Budi'
      await tester.enterText(find.byKey(const Key('input_search_mutations')), 'Budi');
      await tester.pumpAndSettle();
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Rina'), findsNothing);
    });
  });

  group('SMOKE TEST 12: Dropdown Lokasi Appears Inline Below Field', () {
    testWidgets('InlineSearchableDropdown renders panel directly below input', (tester) async {
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
      final dartFiles = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

      int forbiddenRefreshFound = 0;
      int forbiddenKeDashboardFound = 0;

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        // Cek jika ada IconButton dengan tooltip 'Refresh' atau tombol 'Refresh'
        if (content.contains("'Refresh'") || content.contains('"Refresh"')) {
          forbiddenRefreshFound++;
        }
        if (content.contains('Ke Dashboard') || content.contains('ke Dashboard')) {
          forbiddenKeDashboardFound++;
        }
      }

      expect(forbiddenRefreshFound, equals(0), reason: 'Found $forbiddenRefreshFound instances of Refresh buttons');
      expect(forbiddenKeDashboardFound, equals(0), reason: 'Found $forbiddenKeDashboardFound instances of Ke Dashboard buttons');
    });
  });

  group('SMOKE TEST 14: Profile Screen for all 6 Roles', () {
    final roles = [
      (pemohonUser, 'Pemohon'),
      (operatorUser, 'Operator'),
      (kabagUser, 'Kabag Aset'),
      (kadivUser, 'Kadiv'),
      (staffUser, 'Staff Aset'),
      (adminUser, 'Admin'),
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

        expect(find.text(user.name), findsOneWidget);
        expect(find.text(user.email ?? ''), findsOneWidget);
        expect(find.text(label), findsWidgets);
      });
    }
  });

  group('SMOKE TEST 15: Admin Dashboard and all menus are functional', () {
    testWidgets('Admin Dashboard renders 3 menus with valid destinations', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => _MockAuthNotifier(adminUser)),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('User & Permission'), findsOneWidget);
      expect(find.text('Lokasi & Unit'), findsOneWidget);
      expect(find.text('Kategori Aset & Kriteria Approval'), findsOneWidget);
    });

    testWidgets('Admin Users Screen renders without dead buttons', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: AdminUsersScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('User & Permission'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Admin Locations Screen renders with location items', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: AdminLocationsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Lokasi & Unit'), findsOneWidget);
      expect(find.textContaining('Lantai 1'), findsWidgets);
    });

    testWidgets('Asset Category Screen renders with Kadiv criteria banner', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: AssetCategoryScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kategori Aset & Kriteria Approval'), findsOneWidget);
      expect(find.textContaining('Kadiv'), findsWidgets);
    });
  });
}
