// test/features/operator/presentation/widgets/operator_verification_modal_test.dart

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
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';
import 'package:mutasiku/features/operator/presentation/widgets/operator_verification_modal.dart';

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

class _FakeModalMutationRepository implements MutationRepository {
  String? lastForwardedId;
  String? lastForwardedNotes;

  @override
  Future<Result<Mutation>> operatorForward({
    required String mutationId,
    required String operatorName,
    String? notes,
  }) async {
    lastForwardedId = mutationId;
    lastForwardedNotes = notes;
    return Result.success(_dummyMutation(id: mutationId));
  }

  @override
  Future<Result<Mutation>> verifyMutation({
    required String mutationId,
    String? notes,
    required String operatorName,
    bool requiresKadivApproval = false,
  }) async {
    lastForwardedId = mutationId;
    lastForwardedNotes = notes;
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
  String id = 'mut-101',
  String ticketNumber = 'MUT-2026-0001',
  bool hasDocument = true,
  String targetLocation = 'Kantor Cabang Denpasar',
  String reason = 'Kebutuhan operasional unit kerja',
}) {
  return Mutation(
    id: id,
    ticketNumber: ticketNumber,
    isUnregisteredAsset: false,
    applicantId: 'usr-pemohon',
    applicantName: 'Budi Santoso',
    currentLocation: 'Kantor Pusat',
    targetLocation: targetLocation,
    currentPic: 'Budi Santoso',
    targetPic: 'Budi Santoso',
    reason: reason,
    documentName: hasDocument ? 'SK_SDM_2026.pdf' : null,
    documentPath: hasDocument ? '/documents/SK_SDM_2026.pdf' : null,
    status: MutationStatus.submitted,
    requiresKadivApproval: false,
    createdAt: DateTime.now(),
  );
}

void main() {
  late _FakeModalMutationRepository fakeRepo;

  const testUser = User(
    id: 'opr-01',
    username: 'operator1',
    name: 'Operator 1',
    email: 'operator@mutasiku.id',
    role: UserRole.operator,
  );

  setUp(() {
    fakeRepo = _FakeModalMutationRepository();
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
          body: OperatorVerificationModal(mutation: mutation),
        ),
      ),
    );
  }

  testWidgets(
      'Menampilkan judul Verifikasi Pengajuan, ringkasan pengajuan, dan Catatan Hasil Pemeriksaan (Opsional)',
      (tester) async {
    final mutation = _dummyMutation();
    await tester.pumpWidget(createWidget(mutation));
    await tester.pumpAndSettle();

    // 1. Header dengan judul Verifikasi Pengajuan & Tiket
    expect(find.text('Verifikasi Pengajuan'), findsOneWidget);
    expect(find.textContaining('MUT-2026-0001'), findsOneWidget);

    // 2. Ringkasan pengajuan dipertahankan
    expect(find.textContaining('Budi Santoso'), findsOneWidget);
    expect(find.textContaining('Tujuan: Kantor Cabang Denpasar'), findsOneWidget);

    // 3. Langsung label Catatan Hasil Pemeriksaan (Opsional)
    expect(find.text('Catatan Hasil Pemeriksaan (Opsional)'), findsOneWidget);
    expect(find.byKey(const Key('input_catatan_operator')), findsOneWidget);

    // 4. TIDAK ADA tulisan "Laporan", tab Catatan/Verifikasi, atau card checklist
    expect(find.text('Laporan'), findsNothing);
    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(TabBarView), findsNothing);
    expect(find.text('Checklist Kelengkapan Berkas & Data'), findsNothing);
    expect(find.text('Dokumen SK SDM Terlampir'), findsNothing);

    // 5. Tombol aksi Batal dan Teruskan ke Bagian Aset
    expect(find.text('Batal'), findsOneWidget);
    expect(find.text('Teruskan ke Bagian Aset'), findsOneWidget);

    // 6. Pastikan TIDAK ADA opsi Tolak / Terima untuk Operator
    expect(find.text('Tolak'), findsNothing);
    expect(find.text('Ditolak'), findsNothing);
    expect(find.text('Setujui'), findsNothing);
    expect(find.text('Kembalikan'), findsNothing);
  });

  testWidgets(
      'Operator dapat meneruskan pengajuan tanpa mengisi catatan (catatan opsional)',
      (tester) async {
    final mutation = _dummyMutation();
    await tester.pumpWidget(createWidget(mutation));
    await tester.pumpAndSettle();

    // Pastikan input catatan kosong
    final inputField = find.byKey(const Key('input_catatan_operator'));
    expect(inputField, findsOneWidget);

    // Langsung klik Teruskan ke Bagian Aset
    final forwardBtn = find.byKey(const Key('btn_teruskan_ke_bagian_aset'));
    await tester.tap(forwardBtn);
    await tester.pump();

    expect(fakeRepo.lastForwardedId, 'mut-101');
    expect(fakeRepo.lastForwardedNotes, isNull);
  });

  testWidgets(
      'Mengirim verifikasi dan catatan ke backend ketika catatan diisi',
      (tester) async {
    final mutation = _dummyMutation();
    await tester.pumpWidget(createWidget(mutation));
    await tester.pumpAndSettle();

    // Masukkan catatan
    final inputField = find.byKey(const Key('input_catatan_operator'));
    await tester.enterText(
        inputField, 'Dokumen SK SDM asli telah diperiksa dan sah.');
    await tester.pump();

    // Klik Teruskan ke Bagian Aset
    final forwardBtn = find.byKey(const Key('btn_teruskan_ke_bagian_aset'));
    await tester.tap(forwardBtn);
    await tester.pump();

    expect(fakeRepo.lastForwardedId, 'mut-101');
    expect(
        fakeRepo.lastForwardedNotes, 'Dokumen SK SDM asli telah diperiksa dan sah.');
  });
}
