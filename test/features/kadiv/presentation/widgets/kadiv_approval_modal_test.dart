// test/features/kadiv/presentation/widgets/kadiv_approval_modal_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/auth/domain/repositories/auth_repository.dart';
import 'package:mutasiku/features/auth/domain/usecases/login_usecase.dart';
import 'package:mutasiku/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';
import 'package:mutasiku/features/kadiv/presentation/widgets/kadiv_approval_modal.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';

class _FakeKadivAuthRepository implements AuthRepository {
  final User? user;
  _FakeKadivAuthRepository({this.user});

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
  }) async => throw UnimplementedError();
}

class _FakeKadivAuthNotifier extends AuthNotifier {
  _FakeKadivAuthNotifier(User user)
      : super(
          loginUseCase:
              LoginUseCase(repository: _FakeKadivAuthRepository(user: user)),
          logoutUseCase:
              LogoutUseCase(repository: _FakeKadivAuthRepository(user: user)),
          authRepository: _FakeKadivAuthRepository(user: user),
          checkInitialStatus: false,
        ) {
    state = AuthState(isLoading: false, user: user);
  }
}

class _FakeKadivMutationRepo implements MutationRepository {
  String? lastApprovedId;
  String? lastApprovedApprover;
  String? lastApprovedNotes;

  String? lastRejectedId;
  String? lastRejectedReason;
  String? lastRejectedRejector;

  @override
  Future<Result<Mutation>> approveMutationKadiv({
    required String mutationId,
    required String kadivName,
  }) async {
    lastApprovedId = mutationId;
    lastApprovedApprover = kadivName;
    return Result.success(_dummyMutation(id: mutationId));
  }

  @override
  Future<Result<Mutation>> rejectMutationKadiv({
    required String mutationId,
    required String reason,
    required String kadivName,
  }) async {
    lastRejectedId = mutationId;
    lastRejectedReason = reason;
    lastRejectedRejector = kadivName;
    return Result.success(_dummyMutation(id: mutationId));
  }

  @override
  Future<Result<Mutation>> getMutationById(String id) async {
    return Result.success(_dummyMutation(id: id));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Mutation _dummyMutation({
  String id = 'mut_kadiv_01',
  String ticketNumber = 'MUT-KDV-2026-001',
  String applicantName = 'Budi Santoso',
  String targetPic = 'Ahmad Fauzi',
  String currentLocation = 'Gedung TI Lt. 2',
  String targetLocation = 'Kantor Cabang Surabaya',
}) {
  return Mutation(
    id: id,
    ticketNumber: ticketNumber,
    isUnregisteredAsset: false,
    applicantId: 'usr-pemohon',
    applicantName: applicantName,
    currentLocation: currentLocation,
    targetLocation: targetLocation,
    currentPic: applicantName,
    targetPic: targetPic,
    reason: 'Kebutuhan server operasional cabang',
    isAssetMovingWithApplicant: false,
    status: MutationStatus.waitingKadivApproval,
    requiresKadivApproval: true,
    assetVerifiedBy: 'H. M. Yusuf (Bagian Aset)',
    assetVerifiedAt: DateTime.now().subtract(const Duration(hours: 2)),
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  );
}

void main() {
  late _FakeKadivMutationRepo fakeRepo;

  const testKadivUser = User(
    id: 'kdv-01',
    username: 'kadiv1',
    name: 'Drs. Ahmad Dahlan (Kadiv)',
    email: 'kadiv@mutasiku.id',
    role: UserRole.kadiv,
  );

  setUp(() {
    fakeRepo = _FakeKadivMutationRepo();
  });

  Widget createWidget(
    Mutation mutation, {
    KadivDecision initialDecision = KadivDecision.approve,
  }) {
    return ProviderScope(
      overrides: [
        apiMutationRepositoryProvider.overrideWithValue(fakeRepo),
        mutationRepositoryProvider.overrideWithValue(fakeRepo),
        authStateProvider.overrideWith(
          (ref) => _FakeKadivAuthNotifier(testKadivUser),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: KadivApprovalModal(
            mutation: mutation,
            initialDecision: initialDecision,
          ),
        ),
      ),
    );
  }

  testWidgets(
    'Menampilkan modal tunggal persetujuan Kadiv dengan ringkasan, radio Setujui dan Tolak',
    (tester) async {
      final mutation = _dummyMutation();
      await tester.pumpWidget(createWidget(mutation));
      await tester.pumpAndSettle();

      // Header label persetujuan final Kadiv
      expect(find.text('Persetujuan Pemimpin Divisi'), findsOneWidget);
      expect(find.text('Konfirmasi Approval Kadiv'), findsOneWidget);

      // Ringkasan tiket, aset, dan verifikasi Bagian Aset
      expect(find.text('MUT-KDV-2026-001'), findsOneWidget);
      expect(
        find.textContaining('Lolos Verifikasi Bagian Aset', findRichText: true),
        findsOneWidget,
      );

      // Pilihan keputusan radio cards
      expect(
        find.textContaining('Keputusan Pemimpin Divisi', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Setujui'), findsOneWidget);
      expect(find.text('Tolak'), findsOneWidget);

      // Tombol Batal dan Simpan
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Simpan Persetujuan'), findsOneWidget);
    },
  );

  testWidgets(
    'Peralihan radio Setujui ke Tolak mengubah teks subtitle, status wajib catatan, dan label tombol',
    (tester) async {
      final mutation = _dummyMutation();
      await tester.pumpWidget(createWidget(mutation));
      await tester.pumpAndSettle();

      // Awalnya Setujui aktif
      expect(find.text('Konfirmasi Approval Kadiv'), findsOneWidget);
      expect(find.text('Simpan Persetujuan'), findsOneWidget);

      // Masukkan catatan
      final inputNotes = find.byKey(const Key('input_catatan_kadiv'));
      expect(inputNotes, findsOneWidget);
      await tester.enterText(inputNotes, 'Catatan arahan awal.');
      await tester.pump();

      // Klik radio Tolak
      await tester.tap(find.byKey(const Key('card_decision_kadiv_reject')));
      await tester.pumpAndSettle();

      // UI berubah ke mode Tolak
      expect(find.text('Konfirmasi Penolakan Kadiv'), findsOneWidget);
      expect(find.text('Simpan Penolakan'), findsOneWidget);
      expect(
        find.textContaining(
          'Catatan Persetujuan / Alasan Penolakan',
          findRichText: true,
        ),
        findsOneWidget,
      );

      // Catatan yang sudah diketik tetap ada
      expect(find.text('Catatan arahan awal.'), findsOneWidget);

      // Klik kembali ke Setujui
      await tester.tap(find.byKey(const Key('card_decision_kadiv_approve')));
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi Approval Kadiv'), findsOneWidget);
      expect(find.text('Simpan Persetujuan'), findsOneWidget);
      expect(find.text('Catatan arahan awal.'), findsOneWidget);
    },
  );

  testWidgets(
    'Validasi penolakan: catatan kosong atau kurang dari 5 karakter menampilkan error dan membatalkan submit',
    (tester) async {
      final mutation = _dummyMutation();
      await tester.pumpWidget(
        createWidget(mutation, initialDecision: KadivDecision.reject),
      );
      await tester.pumpAndSettle();

      final btnSubmit = find.byKey(const Key('btn_confirm_tolak_kadiv_dialog'));
      expect(btnSubmit, findsOneWidget);

      // 1. Submit tanpa catatan
      await tester.tap(btnSubmit);
      await tester.pumpAndSettle();

      expect(find.text('Alasan penolakan tidak boleh kosong.'), findsOneWidget);
      expect(fakeRepo.lastRejectedId, isNull);

      // 2. Submit dengan catatan < 5 karakter
      final inputNotes = find.byKey(
        const Key('input_alasan_penolakan_kadiv'),
      );
      await tester.enterText(inputNotes, 'xyz');
      await tester.tap(btnSubmit);
      await tester.pumpAndSettle();

      expect(find.text('Alasan penolakan minimal 5 karakter.'), findsOneWidget);
      expect(fakeRepo.lastRejectedId, isNull);
    },
  );

  testWidgets(
    'Konfirmasi Tolak dengan alasan valid memanggil rejectMutationKadiv pada repository',
    (tester) async {
      final mutation = _dummyMutation();
      await tester.pumpWidget(
        createWidget(mutation, initialDecision: KadivDecision.reject),
      );
      await tester.pumpAndSettle();

      final inputNotes = find.byKey(
        const Key('input_alasan_penolakan_kadiv'),
      );
      await tester.enterText(
        inputNotes,
        'Alokasi anggaran relokasi server belum disetujui divisi.',
      );
      await tester.pump();

      final btnSubmit = find.byKey(const Key('btn_confirm_tolak_kadiv_dialog'));
      await tester.tap(btnSubmit);
      await tester.pump();

      expect(fakeRepo.lastRejectedId, 'mut_kadiv_01');
      expect(
        fakeRepo.lastRejectedReason,
        'Alokasi anggaran relokasi server belum disetujui divisi.',
      );
      expect(fakeRepo.lastRejectedRejector, 'Drs. Ahmad Dahlan (Kadiv)');
      expect(fakeRepo.lastApprovedId, isNull);
    },
  );

  testWidgets(
    'Konfirmasi Setujui memanggil approveMutationKadiv pada repository dengan catatan opsional',
    (tester) async {
      final mutation = _dummyMutation();
      await tester.pumpWidget(
        createWidget(mutation, initialDecision: KadivDecision.approve),
      );
      await tester.pumpAndSettle();

      final inputNotes = find.byKey(const Key('input_catatan_kadiv'));
      await tester.enterText(
        inputNotes,
        'Disetujui untuk mendukung operasional cabang.',
      );
      await tester.pump();

      final btnSubmit = find.byKey(const Key('btn_confirm_setujui_kadiv'));
      await tester.tap(btnSubmit);
      await tester.pump();

      expect(fakeRepo.lastApprovedId, 'mut_kadiv_01');
      expect(fakeRepo.lastApprovedApprover, 'Drs. Ahmad Dahlan (Kadiv)');
      expect(fakeRepo.lastRejectedId, isNull);
    },
  );
}
