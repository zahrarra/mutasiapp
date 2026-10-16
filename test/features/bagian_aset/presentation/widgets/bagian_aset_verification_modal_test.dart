// test/features/bagian_aset/presentation/widgets/bagian_aset_verification_modal_test.dart

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
import 'package:mutasiku/features/bagian_aset/presentation/widgets/bagian_aset_verification_modal.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';

class FakeAuthRepository implements AuthRepository {
  final User? user;
  FakeAuthRepository({this.user});

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
  }) async => throw UnimplementedError();
}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(User user)
      : super(
          loginUseCase: LoginUseCase(repository: FakeAuthRepository(user: user)),
          logoutUseCase: LogoutUseCase(repository: FakeAuthRepository(user: user)),
          authRepository: FakeAuthRepository(user: user),
          checkInitialStatus: false,
        ) {
          state = AuthState(isLoading: false, user: user);
        }
}

class _FakeBagianAsetRepo implements MutationRepository {
  String? lastForwardedId;
  String? lastForwardedPic;
  String? lastForwardedNotes;

  String? lastReturnedId;
  String? lastReturnedReason;

  String? lastRejectedId;
  String? lastRejectedReason;

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
    return Result.success(_dummyMutation(id: mutationId));
  }

  @override
  Future<Result<Mutation>> assetSectionReject({
    required String mutationId,
    required String reason,
    required String verifierName,
  }) async {
    lastRejectedId = mutationId;
    lastRejectedReason = reason;
    return Result.success(_dummyMutation(id: mutationId).copyWith(
      status: MutationStatus.rejected,
      rejectionReason: reason,
    ));
  }

  @override
  Future<Result<Mutation>> returnMutation({
    required String mutationId,
    required String reason,
    required String operatorName,
  }) async {
    lastReturnedId = mutationId;
    lastReturnedReason = reason;
    return Result.success(_dummyMutation(id: mutationId));
  }

  @override
  Future<Result<Mutation>> getMutationById(String id) async {
    return Result.success(_dummyMutation(id: id));
  }

  @override
  Future<Result<Mutation>> assetSectionReturn({
    required String mutationId,
    required String reason,
    required String verifierName,
  }) async {
    lastReturnedId = mutationId;
    lastReturnedReason = reason;
    return Result.success(_dummyMutation(id: mutationId));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Mutation _dummyMutation({
  String id = 'mut-201',
  String ticketNumber = 'MUT-2026-0002',
  bool isAssetMovingWithApplicant = true,
  String targetPic = 'Budi Santoso',
}) {
  return Mutation(
    id: id,
    ticketNumber: ticketNumber,
    isUnregisteredAsset: false,
    applicantId: 'usr-pemohon',
    applicantName: 'Budi Santoso',
    currentLocation: 'Kantor Cabang A',
    targetLocation: 'Kantor Cabang B',
    currentPic: 'Budi Santoso',
    targetPic: targetPic,
    reason: 'Pindah tugas',
    isAssetMovingWithApplicant: isAssetMovingWithApplicant,
    status: MutationStatus.waitingAssetVerification,
    requiresKadivApproval: false,
    createdAt: DateTime.now(),
  );
}

void main() {
  late _FakeBagianAsetRepo fakeRepo;

  const testUser = User(
    id: 'ba-01',
    username: 'bagianaset1',
    name: 'Staf Aset',
    email: 'aset@mutasiku.id',
    role: UserRole.bagianAset,
  );

  setUp(() {
    fakeRepo = _FakeBagianAsetRepo();
  });

  Widget createWidget(Mutation mutation) {
    return ProviderScope(
      overrides: [
        apiMutationRepositoryProvider.overrideWithValue(fakeRepo),
        mutationRepositoryProvider.overrideWithValue(fakeRepo),
        authStateProvider.overrideWith((ref) => FakeAuthNotifier(testUser)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: BagianAsetVerificationModal(mutation: mutation),
        ),
      ),
    );
  }

  testWidgets(
      'Menampilkan modal verifikasi Bagian Aset dengan opsi Setujui dan Tolak',
      (tester) async {
    final mutation = _dummyMutation();
    await tester.pumpWidget(createWidget(mutation));
    await tester.pumpAndSettle();

    expect(find.text('Verifikasi Bagian Aset'), findsOneWidget);
    expect(find.text('MUT-2026-0002'), findsOneWidget);
    // Verifikasi opsi Setujui dan Tolak tetap tersedia di dalam modal
    expect(find.byKey(const Key('card_decision_approve')), findsOneWidget);
    expect(find.byKey(const Key('card_decision_reject')), findsOneWidget);
    expect(find.text('Setujui'), findsOneWidget);
    expect(find.text('Tolak'), findsOneWidget);
    expect(find.text('Simpan Verifikasi Bagian Aset'), findsOneWidget);
    expect(find.byKey(const Key('btn_batal_verifikasi_modal')), findsOneWidget);
  });

  testWidgets(
      'Memilih opsi Tolak mengubah label tombol menjadi Konfirmasi Penolakan dan mewajibkan catatan',
      (tester) async {
    final mutation = _dummyMutation();
    await tester.pumpWidget(createWidget(mutation));
    await tester.pumpAndSettle();

    // Pilih Tolak
    await tester.tap(find.byKey(const Key('card_decision_reject')));
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi Penolakan'), findsOneWidget);

    // Klik Konfirmasi Penolakan tanpa mengisi catatan
    await tester
        .tap(find.byKey(const Key('btn_simpan_verifikasi_bagian_aset')));
    await tester.pump();

    // Repository forward/return tidak boleh dieksekusi
    expect(fakeRepo.lastForwardedId, isNull);
    expect(fakeRepo.lastReturnedId, isNull);
  });

  testWidgets(
      'Catatan verifikasi bersifat opsional dan tersimpan saat verifikasi Setujui',
      (tester) async {
    final mutation = _dummyMutation();
    await tester.pumpWidget(createWidget(mutation));
    await tester.pumpAndSettle();

    final notesField = find.byKey(const Key('input_catatan_bagian_aset'));
    await tester.enterText(
        notesField, 'Aset dalam kondisi baik dan nomor seri sesuai.');
    await tester.pump();

    expect(find.text('Aset dalam kondisi baik dan nomor seri sesuai.'),
        findsOneWidget);

    final saveBtn = find.byKey(const Key('btn_simpan_verifikasi_bagian_aset'));
    await tester.tap(saveBtn);
    await tester.pump();

    expect(fakeRepo.lastForwardedId, 'mut-201');
    expect(fakeRepo.lastForwardedNotes,
        'Aset dalam kondisi baik dan nomor seri sesuai.');
    expect(fakeRepo.lastReturnedId, isNull);
  });

  testWidgets(
      'Konfirmasi Tolak dengan alasan mengeksekusi penolakan Bagian Aset (status ditolak) dan tidak menghubungkan ke return-by-asset',
      (tester) async {
    final mutation = _dummyMutation();
    await tester.pumpWidget(createWidget(mutation));
    await tester.pumpAndSettle();

    // Pilih Tolak
    await tester.tap(find.byKey(const Key('card_decision_reject')));
    await tester.pumpAndSettle();

    // Isi alasan penolakan
    final notesField = find.byKey(const Key('input_catatan_bagian_aset'));
    await tester.enterText(notesField, 'Fisik aset rusak berat di lokasi.');
    await tester.pump();

    // Klik Konfirmasi Penolakan
    await tester
        .tap(find.byKey(const Key('btn_simpan_verifikasi_bagian_aset')));
    await tester.pump();

    // Berhasil menolak via assetSectionReject
    expect(fakeRepo.lastRejectedId, 'mut-201');
    expect(fakeRepo.lastRejectedReason, 'Fisik aset rusak berat di lokasi.');
    expect(fakeRepo.lastReturnedId, isNull);
    expect(fakeRepo.lastForwardedId, isNull);
  });

  testWidgets(
      'Konfirmasi Verifikasi meneruskan pengajuan ke antrean Pemimpin Divisi',
      (tester) async {
    final mutation = _dummyMutation();
    await tester.pumpWidget(createWidget(mutation));
    await tester.pumpAndSettle();

    // Isi instruksi opsional
    final notesField = find.byKey(const Key('input_catatan_bagian_aset'));
    await tester.enterText(notesField, 'Sudah diverifikasi fisik di gudang.');
    await tester.pump();

    // Klik Simpan Verifikasi Bagian Aset
    await tester
        .tap(find.byKey(const Key('btn_simpan_verifikasi_bagian_aset')));
    await tester.pump();

    expect(fakeRepo.lastForwardedId, 'mut-201');
    expect(fakeRepo.lastForwardedNotes, 'Sudah diverifikasi fisik di gudang.');
    expect(fakeRepo.lastReturnedId, isNull);
  });
}
