// test/features/mutation/manual_testing_findings_prd_v1_1_test.dart
//
// Regression & Verification tests for 8 manual testing findings per PRD V1.1:
// 1. Upload SK SDM: tampilkan file + previewable ("bisa dilihat") + "PDF wajib, maksimal 30 MB".
// 2. Cabang Tujuan gunakan dropdown (DropdownButtonFormField), tidak boleh input manual.
// 3. Hapus pesan tambahan "(WAJIB DIUNGGAH)" karena dari awal memang wajib.
// 4. Simpan Draf benar-benar tersimpan dan bisa dilanjutkan kembali.
// 5. Form Pemohon bersih dari pertanyaan/kriteria approval Kadiv.
// 6. Operator selesai verifikasi menampilkan feedback hijau: "Pengajuan berhasil diteruskan ke Bagian Aset."
// 7. Jika aset ditinggalkan, Bagian Aset menentukan PIC baru melalui sistem.
// 8. Halaman Pemimpin Divisi tombol Approve/Setujui bisa digunakan & setelah approve masuk waitingConfirmation.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mutasiku/core/errors/failures.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/core/services/document_picker_service.dart';
import 'package:mutasiku/core/services/mutation_draft_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mutasiku/features/asset/domain/entities/asset.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_category.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_status.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/auth/domain/repositories/auth_repository.dart';
import 'package:mutasiku/features/auth/domain/usecases/login_usecase.dart';
import 'package:mutasiku/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';
import 'package:mutasiku/features/bagian_aset/presentation/screens/bagian_aset_verification_detail_screen.dart';
import 'package:mutasiku/features/kadiv/presentation/screens/kadiv_approval_detail_screen.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';
import 'package:mutasiku/features/operator/presentation/screens/operator_verification_detail_screen.dart';
import 'package:mutasiku/features/pemohon/presentation/screens/pemohon_create_mutation_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  final User? user;
  _FakeAuthRepository({this.user});

  @override
  Future<Result<User?>> getCurrentUser() async => Result.success(user);

  @override
  Future<Result<User>> login({
    required String username,
    required String password,
  }) async {
    throw UnimplementedError();
  }

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

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(User user)
    : super(
        loginUseCase: LoginUseCase(repository: _FakeAuthRepository(user: user)),
        logoutUseCase: LogoutUseCase(
          repository: _FakeAuthRepository(user: user),
        ),
        authRepository: _FakeAuthRepository(user: user),
        checkInitialStatus: false,
      ) {
    state = AuthState(isLoading: false, user: user);
  }
}

class _MockMutationRepository implements MutationRepository {
  final Map<String, Mutation> _mutations = {};

  _MockMutationRepository(List<Mutation> initial) {
    for (final m in initial) {
      _mutations[m.id] = m;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Result<Mutation>> getMutationById(String id) async {
    final m = _mutations[id];
    if (m == null) {
      return const Result.failure(NotFoundFailure(message: 'Not found'));
    }
    return Result.success(m);
  }

  @override
  Future<Result<List<Mutation>>> getAllMutations() async {
    return Result.success(_mutations.values.toList());
  }

  Future<Result<Mutation>> operatorVerify({
    required String mutationId,
    required String operatorName,
    bool requiresKadivApproval = false,
  }) async {
    final current = _mutations[mutationId]!;
    final updated = current.copyWith(
      status: MutationStatus.waitingAssetVerification,
      verifiedBy: operatorName,
      verifiedAt: DateTime.now(),
      requiresKadivApproval: requiresKadivApproval,
    );
    _mutations[mutationId] = updated;
    return Result.success(updated);
  }

  @override
  Future<Result<Mutation>> verifyMutation({
    required String mutationId,
    required String operatorName,
    bool requiresKadivApproval = false,
  }) async {
    return operatorVerify(
      mutationId: mutationId,
      operatorName: operatorName,
      requiresKadivApproval: requiresKadivApproval,
    );
  }

  @override
  Future<Result<Mutation>> assetSectionForward({
    required String mutationId,
    required String verifierName,
    String? newPic,
  }) async {
    final current = _mutations[mutationId]!;
    final updated = current.copyWith(
      targetPic: newPic ?? current.targetPic,
      status: MutationStatus.waitingDivisionHeadApproval,
      assetVerifiedBy: verifierName,
      assetVerifiedAt: DateTime.now(),
      approvedBy: verifierName,
      approvedAt: DateTime.now(),
    );
    _mutations[mutationId] = updated;
    return Result.success(updated);
  }

  @override
  Future<Result<Mutation>> divisionApprove({
    required String mutationId,
    required String divisionHeadName,
  }) async {
    final current = _mutations[mutationId]!;
    final updated = current.copyWith(
      status: MutationStatus.waitingConfirmation,
      kadivApprovedBy: divisionHeadName,
      kadivApprovedAt: DateTime.now(),
      approvedBy: divisionHeadName,
      approvedAt: DateTime.now(),
    );
    _mutations[mutationId] = updated;
    return Result.success(updated);
  }

  @override
  Future<Result<Mutation>> approveMutationKadiv({
    required String mutationId,
    required String kadivName,
  }) async {
    return divisionApprove(mutationId: mutationId, divisionHeadName: kadivName);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testPemohon = User(
    id: 'usr_pemohon',
    username: 'budi',
    name: 'Budi Santoso',
    email: 'budi@bankkalsel.co.id',
    role: UserRole.pemohon,
  );

  const testOperator = User(
    id: 'usr_operator',
    username: 'siti',
    name: 'Siti Operator',
    email: 'siti@bankkalsel.co.id',
    role: UserRole.operator,
  );

  const testBagianAset = User(
    id: 'usr_aset',
    username: 'andi',
    name: 'Andi Bagian Aset',
    email: 'andi@bankkalsel.co.id',
    role: UserRole.bagianAset,
  );

  const testKadiv = User(
    id: 'usr_kadiv',
    username: 'hendra',
    name: 'Drs. Hendra Kadiv',
    email: 'hendra@bankkalsel.co.id',
    role: UserRole.kadiv,
  );

  const catTI = AssetCategory(id: 'cat_ti', code: 'TI', name: 'Aset TI');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    MutationDraftService.resetForTesting();
    DocumentPickerService.testPicker = null;
  });

  tearDown(() {
    MutationDraftService.resetForTesting();
    DocumentPickerService.testPicker = null;
  });

  group('Temuan 1, 2, 3, 4, 5 — Form Pemohon', () {
    testWidgets(
      'Temuan 1 & 3: Upload SK SDM menampilkan berkas, tombol lihat dokumen, '
      'keterangan "PDF wajib, maksimal 30 MB", dan tanpa "(WAJIB DIUNGGAH)"',
      (tester) async {
        DocumentPickerService.testPicker = () async {
          return DocumentPickerResult.success(
            PickedDocument(
              name: 'SK_SDM_Mutasi_2026.pdf',
              size: 1024 * 500,
              bytes: Uint8List.fromList([1, 2, 3]),
            ),
          );
        };

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith(
                (ref) => _TestAuthNotifier(testPemohon),
              ),
            ],
            child: const MaterialApp(home: PemohonCreateMutationScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Temuan 3: Judul SK SDM tanpa teks "(WAJIB DIUNGGAH)"
        expect(find.text('SURAT KEPUTUSAN (SK) SDM *'), findsOneWidget);
        expect(find.textContaining('(WAJIB DIUNGGAH)'), findsNothing);

        // Temuan 1: Terdapat petunjuk PDF wajib, maksimal 30 MB
        expect(find.text('PDF wajib, maksimal 30 MB'), findsOneWidget);

        // Upload berkas
        await tester.ensureVisible(find.text('Unggah Berkas'));
        await tester.tap(find.text('Unggah Berkas'));
        await tester.pumpAndSettle();

        // Temuan 1: File yang sudah di-upload ditampilkan
        expect(find.text('SK_SDM_Mutasi_2026.pdf'), findsOneWidget);

        // Temuan 1: Tombol lihat dokumen tersedia
        expect(find.byTooltip('Lihat dokumen'), findsOneWidget);
      },
    );

    testWidgets(
      'Temuan 2: Cabang Tujuan menggunakan dropdown (DropdownButtonFormField)',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith(
                (ref) => _TestAuthNotifier(testPemohon),
              ),
            ],
            child: const MaterialApp(home: PemohonCreateMutationScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Temuan 2: Dropdown widget ditemukan
        final dropdownFinder = find.byKey(
          const Key('dropdown_target_location'),
        );
        expect(dropdownFinder, findsOneWidget);
        expect(find.byType(DropdownButtonFormField<String>), findsWidgets);

        // Buka dropdown dan pilih item
        await tester.ensureVisible(dropdownFinder);
        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();

        expect(find.text('Cabang Donggala'), findsWidgets);
        await tester.tap(find.text('Cabang Donggala').last);
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Temuan 4: Simpan Draf benar-benar tersimpan dan bisa dimuat kembali',
      (tester) async {
        final draft = MutationDraft(
          assetName: 'Laptop Lenovo ThinkPad',
          assetCode: 'AST-LNV-002',
          sourceLocation: 'Divisi Operasional',
          currentPic: 'Budi Santoso',
          targetLocation: 'Cabang Surabaya',
          room: 'Ruang Layanan Lantai 1',
          bringAsset: true,
          targetPic: 'Budi Santoso',
          reason: 'Pindah tugas sesuai SK',
          documentName: 'SK_Pindah.pdf',
          documentSize: 2048,
          savedAt: DateTime.now(),
        );
        await MutationDraftService.saveDraft(draft, userId: testPemohon.id);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith(
                (ref) => _TestAuthNotifier(testPemohon),
              ),
            ],
            child: const MaterialApp(home: PemohonCreateMutationScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Temuan 4: Nilai draft terisi otomatis kembali di form
        expect(find.text('Laptop Lenovo ThinkPad'), findsWidgets);
        expect(find.text('AST-LNV-002'), findsOneWidget);
        expect(find.text('Pindah tugas sesuai SK'), findsOneWidget);
        expect(find.text('SK_Pindah.pdf'), findsOneWidget);
      },
    );

    testWidgets(
      'Temuan 5: Form Pemohon bersih dari pertanyaan / kriteria approval Kadiv',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith(
                (ref) => _TestAuthNotifier(testPemohon),
              ),
            ],
            child: const MaterialApp(home: PemohonCreateMutationScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Kadiv'), findsNothing);
        expect(find.textContaining('Approval Kadiv'), findsNothing);
        expect(find.textContaining('Kriteria Approval'), findsNothing);
      },
    );

    testWidgets(
      'Form Pemohon: Aset ikut saya bawa -> PIC Tujuan otomatis terisi nama Pemohon tanpa input manual; Aset ditinggalkan -> PIC Tujuan dikosongkan',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith(
                (ref) => _TestAuthNotifier(testPemohon),
              ),
            ],
            child: const MaterialApp(home: PemohonCreateMutationScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Default "Ya, Aset Ikut Saya Pindah": PIC tujuan otomatis terisi nama Pemohon
        expect(
          find.byKey(const Key('card_pic_tujuan_otomatis')),
          findsOneWidget,
        );
        expect(find.text('Budi Santoso'), findsWidgets);
        expect(find.text('Otomatis Pemohon'), findsOneWidget);

        // 2. Ubah ke "Tidak, Aset Ditinggalkan di Unit Asal"
        final tinggalkanFinder = find.text(
          'Tidak, Aset Ditinggalkan di Unit Asal',
        );
        await tester.ensureVisible(tinggalkanFinder);
        await tester.tap(tinggalkanFinder);
        await tester.pumpAndSettle();

        // PIC Tujuan dikosongkan dan info bahwa Bagian Aset yang akan menentukan tampil
        expect(
          find.byKey(const Key('card_pic_tujuan_ditinggalkan')),
          findsOneWidget,
        );
        expect(find.text('Akan ditentukan oleh Bagian Aset'), findsOneWidget);
        expect(find.byKey(const Key('card_pic_tujuan_otomatis')), findsNothing);

        // 3. Ubah kembali ke "Ya, Aset Ikut Saya Pindah"
        final bawaFinder = find.text('Ya, Aset Ikut Saya Pindah');
        await tester.ensureVisible(bawaFinder);
        await tester.tap(bawaFinder);
        await tester.pumpAndSettle();

        // Otomatis terisi kembali dengan nama Pemohon
        expect(
          find.byKey(const Key('card_pic_tujuan_otomatis')),
          findsOneWidget,
        );
        expect(find.text('Budi Santoso'), findsWidgets);
      },
    );
  });

  group('Temuan 6 — Verifikasi Operator', () {
    testWidgets(
      'Temuan 6: Setelah Operator verifikasi, tampilkan feedback hijau '
      '"Pengajuan berhasil diteruskan ke Bagian Aset."',
      (tester) async {
        final dummyMutation = Mutation(
          id: 'mut_test_opr',
          ticketNumber: 'ELK-2026-000200',
          applicantId: 'usr_pemohon',
          applicantName: 'Budi Santoso',
          asset: const Asset(
            id: 'AST-001',
            assetCode: 'AST-001',
            name: 'Laptop HP EliteBook',
            category: catTI,
            location: 'Divisi Operasional',
            pic: 'Budi Santoso',
            status: AssetStatus.inMutation,
            condition: 'Baik',
            acquisitionYear: 2024,
          ),
          currentLocation: 'Divisi Operasional',
          targetLocation: 'Cabang Bandung',
          currentPic: 'Budi Santoso',
          targetPic: 'Budi Santoso',
          reason: 'Pindah tugas',
          status: MutationStatus.submitted,
          createdAt: DateTime.now(),
          requiresKadivApproval: true,
        );
        final repo = _MockMutationRepository([dummyMutation]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              mutationRepositoryProvider.overrideWithValue(repo),
              apiMutationRepositoryProvider.overrideWithValue(repo),
              authStateProvider.overrideWith(
                (ref) => _TestAuthNotifier(testOperator),
              ),
            ],
            child: const MaterialApp(
              home: OperatorVerificationDetailScreen(
                mutationId: 'mut_test_opr',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Buka dialog verifikasi
        await tester.ensureVisible(
          find.byKey(const Key('btn_verifikasi_valid')),
        );
        await tester.tap(find.byKey(const Key('btn_verifikasi_valid')));
        await tester.pumpAndSettle();

        // Temuan 6: Verifikasi teks feedback hijau muncul
        expect(
          find.text('Pengajuan berhasil diteruskan ke Bagian Aset.'),
          findsOneWidget,
        );
      },
    );
  });

  group('Temuan 7 — Bagian Aset Menentukan PIC Baru', () {
    testWidgets(
      'Temuan 7: Jika aset ditinggalkan, Bagian Aset menentukan PIC baru melalui sistem',
      (tester) async {
        final leftBehindMutation = Mutation(
          id: 'mut_test_aset',
          ticketNumber: 'ELK-2026-000201',
          applicantId: 'usr_pemohon',
          applicantName: 'Budi Santoso',
          asset: const Asset(
            id: 'AST-002',
            assetCode: 'AST-002',
            name: 'PC Desktop Dell',
            category: catTI,
            location: 'Divisi Operasional',
            pic: 'Budi Santoso',
            status: AssetStatus.inMutation,
            condition: 'Baik',
            acquisitionYear: 2024,
          ),
          currentLocation: 'Divisi Operasional',
          targetLocation: 'Cabang Bandung',
          currentPic: 'Budi Santoso',
          targetPic: '', // Ditinggalkan -> kosong
          isAssetMovingWithApplicant: false, // Ditinggalkan
          reason: 'Ditinggalkan di unit asal',
          status: MutationStatus.waitingAssetVerification,
          createdAt: DateTime.now(),
        );
        final repo = _MockMutationRepository([leftBehindMutation]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              mutationRepositoryProvider.overrideWithValue(repo),
              apiMutationRepositoryProvider.overrideWithValue(repo),
              authStateProvider.overrideWith(
                (ref) => _TestAuthNotifier(testBagianAset),
              ),
            ],
            child: const MaterialApp(
              home: BagianAsetVerificationDetailScreen(
                mutationId: 'mut_test_aset',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Buka dialog verifikasi data aset
        await tester.ensureVisible(
          find.byKey(const Key('btn_setujui_approval')),
        );
        await tester.tap(find.byKey(const Key('btn_setujui_approval')));
        await tester.pumpAndSettle();

        // Temuan 7: Input PIC baru wajib ada saat aset ditinggalkan
        expect(
          find.text('Penentuan PIC Baru (Aset Ditinggalkan) *'),
          findsOneWidget,
        );
        final inputPicFinder = find.byKey(
          const Key('input_pic_baru_bagian_aset'),
        );
        expect(inputPicFinder, findsOneWidget);

        // Input PIC baru melalui sistem
        await tester.enterText(
          inputPicFinder,
          'Ahmad Fauzi (PIC Baru Unit Asal)',
        );
        await tester.pumpAndSettle();

        // Konfirmasi teruskan
        await tester.tap(find.byKey(const Key('btn_confirm_setujui')));
        await tester.pumpAndSettle();

        // Verifikasi mutasi terupdate dengan PIC baru di repo
        final updatedResult = await repo.getMutationById('mut_test_aset');
        final updatedMutation = updatedResult.dataOrNull!;
        expect(updatedMutation.targetPic, 'Ahmad Fauzi (PIC Baru Unit Asal)');
        expect(
          updatedMutation.status,
          MutationStatus.waitingDivisionHeadApproval,
        );
      },
    );
  });

  group('Temuan 8 — Pemimpin Divisi Approval', () {
    testWidgets(
      'Temuan 8: Halaman Pemimpin Divisi tombol Approve/Setujui bisa digunakan '
      'dan setelah approve masuk waitingConfirmation',
      (tester) async {
        final waitingDivisionMutation = Mutation(
          id: 'mut_test_kadiv',
          ticketNumber: 'ELK-2026-000202',
          applicantId: 'usr_pemohon',
          applicantName: 'Budi Santoso',
          asset: const Asset(
            id: 'AST-003',
            assetCode: 'AST-003',
            name: 'Server Rack Dell',
            category: catTI,
            location: 'Divisi Operasional',
            pic: 'Budi Santoso',
            status: AssetStatus.inMutation,
            condition: 'Baik',
            acquisitionYear: 2024,
          ),
          currentLocation: 'Divisi Operasional',
          targetLocation: 'Cabang Bandung',
          currentPic: 'Budi Santoso',
          targetPic: 'Ahmad Fauzi',
          reason: 'Kebutuhan server',
          status: MutationStatus.waitingDivisionHeadApproval, // Status PRD V1.1
          createdAt: DateTime.now(),
        );
        final repo = _MockMutationRepository([waitingDivisionMutation]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              mutationRepositoryProvider.overrideWithValue(repo),
              apiMutationRepositoryProvider.overrideWithValue(repo),
              authStateProvider.overrideWith(
                (ref) => _TestAuthNotifier(testKadiv),
              ),
            ],
            child: const MaterialApp(
              home: KadivApprovalDetailScreen(mutationId: 'mut_test_kadiv'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Temuan 8: Tombol Setujui bisa digunakan
        final approveButtonFinder = find.byKey(
          const Key('btn_setujui_approval_kadiv'),
        );
        expect(approveButtonFinder, findsOneWidget);

        // Tap Setujui
        await tester.tap(approveButtonFinder);
        await tester.pumpAndSettle();

        // Konfirmasi di dialog
        final confirmApproveFinder = find.byKey(
          const Key('btn_confirm_setujui_kadiv'),
        );
        expect(confirmApproveFinder, findsOneWidget);
        await tester.tap(confirmApproveFinder);
        await tester.pumpAndSettle();

        // Temuan 8: Setelah approve masuk waitingConfirmation
        final updatedResult = await repo.getMutationById('mut_test_kadiv');
        final updatedMutation = updatedResult.dataOrNull!;
        expect(updatedMutation.status, MutationStatus.waitingConfirmation);
        expect(updatedMutation.kadivApprovedBy, 'Drs. Hendra Kadiv');
      },
    );
  });
}
