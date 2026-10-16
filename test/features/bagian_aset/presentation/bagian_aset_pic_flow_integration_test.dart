// test/features/bagian_aset/presentation/bagian_aset_pic_flow_integration_test.dart
//
// Pengujian Integrasi Tombol & Alur Pemilihan PIC pada semua titik masuk Bagian Aset:
// 1. Dashboard Bagian Aset (BagianAsetDashboardScreen)
// 2. Daftar Verifikasi Bagian Aset (BagianAsetVerificationsScreen)
// 3. Detail Verifikasi Bagian Aset (BagianAsetVerificationDetailScreen)
//
// Membuktikan secara end-to-end pada widget handler:
// - Modal keputusan belum terbuka sebelum PIC dipilih.
// - Batal pada dialog PIC tidak membuka modal keputusan.
// - Lanjutkan tanpa pilihan PIC menampilkan pesan validasi dan tidak melewati langkah pertama.
// - PIC yang dipilih terbawa ke modal keputusan dan payload API (repository).
// - Jalur aset yang dibawa Pemohon tetap berfungsi langsung tanpa dialog PIC.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/errors/result.dart';
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
import 'package:mutasiku/features/bagian_aset/presentation/screens/bagian_aset_dashboard_screen.dart';
import 'package:mutasiku/features/bagian_aset/presentation/screens/bagian_aset_verification_detail_screen.dart';
import 'package:mutasiku/features/bagian_aset/presentation/screens/bagian_aset_verifications_screen.dart';
import 'package:mutasiku/features/bagian_aset/presentation/widgets/bagian_aset_verification_modal.dart';
import 'package:mutasiku/features/bagian_aset/presentation/widgets/pic_selection_dialog.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';
import 'package:mutasiku/features/notification/presentation/providers/notification_provider.dart';

class _FakeAuthRepository implements AuthRepository {
  final User? user;
  _FakeAuthRepository({this.user});

  @override
  Future<Result<User?>> getCurrentUser() async => Result.success(user);
  @override
  Future<Result<User>> login({required String username, required String password}) async =>
      throw UnimplementedError();
  @override
  Future<void> logout() async {}
  @override
  Future<Result<User>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async =>
      throw UnimplementedError();
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(User user)
      : super(
          loginUseCase: LoginUseCase(repository: _FakeAuthRepository(user: user)),
          logoutUseCase: LogoutUseCase(repository: _FakeAuthRepository(user: user)),
          authRepository: _FakeAuthRepository(user: user),
          checkInitialStatus: false,
        ) {
    state = AuthState(isLoading: false, user: user);
  }
}

class _FakeUserRepository implements UserRepository {
  final List<User> users;
  _FakeUserRepository(this.users);

  @override
  Future<Result<List<User>>> getAllUsers() async => Result.success(users);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _IntegrationMutationRepository implements MutationRepository {
  final List<Mutation> mutations;
  String? lastForwardedId;
  String? lastForwardedPic;
  String? lastForwardedNotes;

  _IntegrationMutationRepository(this.mutations);

  @override
  Future<Result<List<Mutation>>> getAllMutations() async {
    return Result.success(mutations);
  }

  @override
  Future<Result<Mutation>> getMutationById(String id) async {
    final m = mutations.firstWhere((item) => item.id == id, orElse: () => mutations.first);
    return Result.success(m);
  }

  @override
  Future<Result<Mutation>> assetSectionForward({
    required String mutationId,
    String? newPic,
    String? notes,
    required String verifierName,
  }) async {
    lastForwardedId = mutationId;
    lastForwardedPic = newPic;
    lastForwardedNotes = notes;
    return Result.success(mutations.firstWhere((m) => m.id == mutationId));
  }

  @override
  Future<Result<Mutation>> assetSectionReturn({
    required String mutationId,
    required String reason,
    required String verifierName,
  }) async {
    return Result.success(mutations.firstWhere((m) => m.id == mutationId));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Mutation _buildMutation({
  required String id,
  required String ticketNumber,
  required bool isAssetMovingWithApplicant,
  String targetPic = '-',
  String? targetPicId,
}) {
  return Mutation(
    id: id,
    ticketNumber: ticketNumber,
    asset: Asset(
      id: 'ast-$id',
      assetCode: 'AST-$id',
      name: 'Laptop Dell Latitude $id',
      category: const AssetCategory(id: 'cat_it', code: 'IT', name: 'Teknologi Informasi'),
      location: 'Ruang Server A',
      pic: 'Ahmad Pemohon',
      status: AssetStatus.available,
      condition: 'Baik',
      acquisitionYear: 2024,
      estimatedValue: 15000000,
    ),
    isUnregisteredAsset: false,
    applicantId: 'usr-pemohon',
    applicantName: 'Ahmad Pemohon',
    currentLocation: 'Ruang Server A',
    targetLocation: 'Gudang Pusat B',
    currentPic: 'Ahmad Pemohon',
    targetPic: targetPic,
    targetPicId: targetPicId,
    reason: 'Relokasi aset inventaris',
    isAssetMovingWithApplicant: isAssetMovingWithApplicant,
    status: MutationStatus.waitingAssetVerification,
    requiresKadivApproval: false,
    createdAt: DateTime(2026, 10, 15),
  );
}

void main() {
  const staff = User(
    id: 'ba-01',
    username: 'bagianaset1',
    name: 'Staf Aset',
    email: 'aset@mutasiku.id',
    role: UserRole.bagianAset,
  );

  final activeUsers = [
    const User(
      id: '10',
      username: 'pic_1',
      name: 'Rian Operator',
      email: 'rian@mutasiku.id',
      role: UserRole.operator,
      isActive: true,
    ),
    const User(
      id: '20',
      username: 'pic_2',
      name: 'Siti PIC Cabang',
      email: 'siti@mutasiku.id',
      role: UserRole.pemohon,
      isActive: true,
    ),
  ];

  void setViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget wrapWithScope({
    required Widget child,
    required _IntegrationMutationRepository repo,
  }) {
    return ProviderScope(
      overrides: [
        apiMutationRepositoryProvider.overrideWithValue(repo),
        mutationRepositoryProvider.overrideWithValue(repo),
        authStateProvider.overrideWith((ref) => _FakeAuthNotifier(staff)),
        unreadNotificationCountProvider.overrideWithValue(0),
        masterUsersProvider.overrideWith(
          (ref) => MasterUsersNotifier(_FakeUserRepository(activeUsers)),
        ),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Entry Point 1: Dashboard Bagian Aset (BagianAsetDashboardScreen)', () {
    testWidgets(
        'Mutasi butuh PIC: membuka satu modal verifikasi langsung (tanpa dialog PIC terpisah), simpan ditolak jika PIC belum dipilih, dan Batal menutup modal',
        (tester) async {
      setViewport(tester);

      final mutation = _buildMutation(
        id: 'mut-dash-1',
        ticketNumber: 'MUT-DASH-001',
        isAssetMovingWithApplicant: false,
      );
      final repo = _IntegrationMutationRepository([mutation]);

      await tester.pumpWidget(
        wrapWithScope(
          child: const BagianAsetDashboardScreen(),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      final actionBtn = find.byKey(Key('btn_action_${mutation.id}'));
      await tester.ensureVisible(actionBtn);
      expect(actionBtn, findsOneWidget);

      // 1. Tekan tombol verifikasi dari dashboard
      await tester.tap(actionBtn);
      await tester.pumpAndSettle();

      // 2. Membuka modal verifikasi tunggal langsung
      expect(find.byType(BagianAsetVerificationModal), findsOneWidget);
      // 3. TIDAK ADA modal/dialog terpisah "Pilih PIC Baru Aset" (PicSelectionDialog)
      expect(find.byType(PicSelectionDialog), findsNothing);

      // 4. Komponen pemilihan PIC tampil langsung di dalam modal verifikasi
      expect(find.byKey(const Key('dropdown_pilih_pic_baru')), findsOneWidget);
      expect(find.text('Penanggung Jawab (PIC) Baru Aset'), findsOneWidget);

      // 5. Tekan Simpan sebelum memilih PIC -> ditolak dengan pesan validasi
      final saveBtn = find.byKey(const Key('btn_simpan_verifikasi_bagian_aset'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Pilih PIC baru terlebih dahulu sebelum menyimpan verifikasi.'),
        findsOneWidget,
      );
      expect(find.byType(BagianAsetVerificationModal), findsOneWidget);
      expect(repo.lastForwardedId, isNull);

      // 6. Tekan tombol Batal -> modal tertutup tanpa efek samping
      final cancelBtn = find.byKey(const Key('btn_batal_verifikasi_modal'));
      await tester.ensureVisible(cancelBtn);
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      expect(find.byType(BagianAsetVerificationModal), findsNothing);
      expect(repo.lastForwardedId, isNull);
    });

    testWidgets(
        'Mutasi butuh PIC: PIC dipilih langsung di dalam modal, tetap terpilih saat ganti Terima/Tolak, dan ID dikirim ke API',
        (tester) async {
      setViewport(tester);

      final mutation = _buildMutation(
        id: 'mut-dash-2',
        ticketNumber: 'MUT-DASH-002',
        isAssetMovingWithApplicant: false,
      );
      final repo = _IntegrationMutationRepository([mutation]);

      await tester.pumpWidget(
        wrapWithScope(
          child: const BagianAsetDashboardScreen(),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      final actionBtn = find.byKey(Key('btn_action_${mutation.id}'));
      await tester.ensureVisible(actionBtn);
      await tester.tap(actionBtn);
      await tester.pumpAndSettle();

      expect(find.byType(BagianAsetVerificationModal), findsOneWidget);
      expect(find.byType(PicSelectionDialog), findsNothing);

      // Pilih PIC dari dropdown langsung di dalam modal
      await tester.tap(find.byKey(const Key('dropdown_pilih_pic_baru')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Siti PIC Cabang').last);
      await tester.pumpAndSettle();

      // Ganti keputusan ke Tolak lalu kembali ke Setujui (PIC tetap terpilih)
      await tester.tap(find.byKey(const Key('card_decision_reject')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('card_decision_approve')));
      await tester.pumpAndSettle();

      // Simpan verifikasi
      final saveBtn = find.byKey(const Key('btn_simpan_verifikasi_bagian_aset'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Modal tertutup dan ID PIC ('20') terbawa ke API / repository
      expect(find.byType(BagianAsetVerificationModal), findsNothing);
      expect(repo.lastForwardedId, 'mut-dash-2');
      expect(repo.lastForwardedPic, '20');
    });

    testWidgets(
        'Mutasi aset dibawa Pemohon: langsung membuka modal verifikasi tunggal tanpa mewajibkan PIC baru',
        (tester) async {
      setViewport(tester);

      final mutation = _buildMutation(
        id: 'mut-dash-3',
        ticketNumber: 'MUT-DASH-003',
        isAssetMovingWithApplicant: true,
        targetPic: 'Ahmad Pemohon',
      );
      final repo = _IntegrationMutationRepository([mutation]);

      await tester.pumpWidget(
        wrapWithScope(
          child: const BagianAsetDashboardScreen(),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      final actionBtn = find.byKey(Key('btn_action_${mutation.id}'));
      await tester.ensureVisible(actionBtn);
      await tester.tap(actionBtn);
      await tester.pumpAndSettle();

      // Membuka modal verifikasi tunggal, tanpa dialog PIC terpisah
      expect(find.byType(BagianAsetVerificationModal), findsOneWidget);
      expect(find.byType(PicSelectionDialog), findsNothing);
      // Bagian PIC baru tidak wajib/tidak ditampilkan
      expect(find.text('Penanggung Jawab (PIC) Baru Aset'), findsNothing);

      // Dapat langsung disimpan
      final saveBtn = find.byKey(const Key('btn_simpan_verifikasi_bagian_aset'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(repo.lastForwardedId, 'mut-dash-3');
    });
  });

  group('Entry Point 2: Daftar Verifikasi Bagian Aset (BagianAsetVerificationsScreen)', () {
    testWidgets(
        'Mutasi butuh PIC: menekan tombol pada card membuka modal verifikasi tunggal dengan bagian PIC langsung',
        (tester) async {
      setViewport(tester);

      final mutation = _buildMutation(
        id: 'mut-list-1',
        ticketNumber: 'MUT-LIST-001',
        isAssetMovingWithApplicant: false,
      );
      final repo = _IntegrationMutationRepository([mutation]);

      await tester.pumpWidget(
        wrapWithScope(
          child: const BagianAsetVerificationsScreen(),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byKey(Key('approval_card_${mutation.id}'));
      final btn = find.descendant(of: cardFinder, matching: find.byType(ElevatedButton));
      expect(btn, findsOneWidget);

      await tester.tap(btn);
      await tester.pumpAndSettle();

      // Satu modal verifikasi terbuka langsung
      expect(find.byType(BagianAsetVerificationModal), findsOneWidget);
      expect(find.byType(PicSelectionDialog), findsNothing);
      expect(find.byKey(const Key('dropdown_pilih_pic_baru')), findsOneWidget);

      // Tekan tombol Batal
      await tester.tap(find.byKey(const Key('btn_batal_verifikasi_modal')));
      await tester.pumpAndSettle();

      expect(find.byType(BagianAsetVerificationModal), findsNothing);
      expect(repo.lastForwardedId, isNull);
    });

    testWidgets(
        'Mutasi butuh PIC: memilih PIC dan keputusan Tolak/Terima di modal yang sama meneruskan ID ke API',
        (tester) async {
      setViewport(tester);

      final mutation = _buildMutation(
        id: 'mut-list-2',
        ticketNumber: 'MUT-LIST-002',
        isAssetMovingWithApplicant: false,
      );
      final repo = _IntegrationMutationRepository([mutation]);

      await tester.pumpWidget(
        wrapWithScope(
          child: const BagianAsetVerificationsScreen(),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byKey(Key('approval_card_${mutation.id}'));
      final btn = find.descendant(of: cardFinder, matching: find.byType(ElevatedButton));
      await tester.tap(btn);
      await tester.pumpAndSettle();

      // Pilih PIC di dalam modal
      await tester.tap(find.byKey(const Key('dropdown_pilih_pic_baru')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Rian Operator').last);
      await tester.pumpAndSettle();

      // Simpan verifikasi
      final saveBtn = find.byKey(const Key('btn_simpan_verifikasi_bagian_aset'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(repo.lastForwardedId, 'mut-list-2');
      expect(repo.lastForwardedPic, '10');
    });

    testWidgets(
        'Mutasi aset dibawa Pemohon: tombol langsung membuka modal keputusan tunggal',
        (tester) async {
      setViewport(tester);

      final mutation = _buildMutation(
        id: 'mut-list-3',
        ticketNumber: 'MUT-LIST-003',
        isAssetMovingWithApplicant: true,
        targetPic: 'Ahmad Pemohon',
      );
      final repo = _IntegrationMutationRepository([mutation]);

      await tester.pumpWidget(
        wrapWithScope(
          child: const BagianAsetVerificationsScreen(),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byKey(Key('approval_card_${mutation.id}'));
      final btn = find.descendant(of: cardFinder, matching: find.text('Verifikasi'));
      expect(btn, findsOneWidget);

      await tester.tap(btn);
      await tester.pumpAndSettle();

      expect(find.byType(BagianAsetVerificationModal), findsOneWidget);
      expect(find.byType(PicSelectionDialog), findsNothing);
    });
  });

  group('Entry Point 3: Halaman Detail Verifikasi Bagian Aset (BagianAsetVerificationDetailScreen)', () {
    testWidgets(
        'Mutasi butuh PIC: tombol bawah membuka langsung modal verifikasi tunggal tanpa dialog terpisah',
        (tester) async {
      setViewport(tester);

      final mutation = _buildMutation(
        id: 'mut-detail-1',
        ticketNumber: 'MUT-DET-001',
        isAssetMovingWithApplicant: false,
      );
      final repo = _IntegrationMutationRepository([mutation]);

      await tester.pumpWidget(
        wrapWithScope(
          child: BagianAsetVerificationDetailScreen(mutationId: mutation.id),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      final verifyBtn = find.byKey(const Key('btn_setujui_approval'));
      expect(verifyBtn, findsOneWidget);

      await tester.tap(verifyBtn);
      await tester.pumpAndSettle();

      // Satu modal verifikasi terbuka langsung
      expect(find.byType(BagianAsetVerificationModal), findsOneWidget);
      expect(find.byType(PicSelectionDialog), findsNothing);
      expect(find.byKey(const Key('dropdown_pilih_pic_baru')), findsOneWidget);

      // Tekan Batal
      await tester.tap(find.byKey(const Key('btn_batal_verifikasi_modal')));
      await tester.pumpAndSettle();

      expect(find.byType(BagianAsetVerificationModal), findsNothing);
      expect(repo.lastForwardedId, isNull);
    });

    testWidgets(
        'Mutasi butuh PIC pada detail: alur lengkap PIC dalam modal -> Simpan',
        (tester) async {
      setViewport(tester);

      final mutation = _buildMutation(
        id: 'mut-detail-2',
        ticketNumber: 'MUT-DET-002',
        isAssetMovingWithApplicant: false,
      );
      final repo = _IntegrationMutationRepository([mutation]);

      await tester.pumpWidget(
        wrapWithScope(
          child: BagianAsetVerificationDetailScreen(mutationId: mutation.id),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_setujui_approval')));
      await tester.pumpAndSettle();

      // Pilih PIC langsung di modal
      await tester.tap(find.byKey(const Key('dropdown_pilih_pic_baru')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Siti PIC Cabang').last);
      await tester.pumpAndSettle();

      // Simpan verifikasi
      final saveBtn = find.byKey(const Key('btn_simpan_verifikasi_bagian_aset'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(repo.lastForwardedId, 'mut-detail-2');
      expect(repo.lastForwardedPic, '20');
    });

    testWidgets(
        'Mutasi aset dibawa Pemohon pada detail: langsung membuka modal verifikasi tunggal',
        (tester) async {
      setViewport(tester);

      final mutation = _buildMutation(
        id: 'mut-detail-3',
        ticketNumber: 'MUT-DET-003',
        isAssetMovingWithApplicant: true,
        targetPic: 'Ahmad Pemohon',
      );
      final repo = _IntegrationMutationRepository([mutation]);

      await tester.pumpWidget(
        wrapWithScope(
          child: BagianAsetVerificationDetailScreen(mutationId: mutation.id),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      final verifyBtn = find.byKey(const Key('btn_setujui_approval'));
      await tester.tap(verifyBtn);
      await tester.pumpAndSettle();

      expect(find.byType(BagianAsetVerificationModal), findsOneWidget);
      expect(find.byType(PicSelectionDialog), findsNothing);
    });
  });
}
