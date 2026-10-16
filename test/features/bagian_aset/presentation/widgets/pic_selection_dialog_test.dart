// test/features/bagian_aset/presentation/widgets/pic_selection_dialog_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/auth/domain/repositories/auth_repository.dart';
import 'package:mutasiku/features/auth/domain/repositories/user_repository.dart';
import 'package:mutasiku/features/auth/domain/usecases/login_usecase.dart';
import 'package:mutasiku/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';
import 'package:mutasiku/features/bagian_aset/presentation/widgets/bagian_aset_verification_modal.dart';
import 'package:mutasiku/features/bagian_aset/presentation/widgets/pic_selection_dialog.dart';
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
  }) async =>
      throw UnimplementedError();
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

class FakeUserRepository implements UserRepository {
  final List<User> users;
  FakeUserRepository(this.users);

  @override
  Future<Result<List<User>>> getAllUsers() async => Result.success(users);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMutationRepository implements MutationRepository {
  String? lastForwardedId;
  String? lastForwardedPic;
  String? lastForwardedNotes;

  String? lastReturnedId;
  String? lastReturnedReason;

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
    return Result.success(_createMutation(id: mutationId));
  }

  @override
  Future<Result<Mutation>> assetSectionReturn({
    required String mutationId,
    required String reason,
    required String verifierName,
  }) async {
    lastReturnedId = mutationId;
    lastReturnedReason = reason;
    return Result.success(_createMutation(id: mutationId));
  }

  @override
  Future<Result<Mutation>> getMutationById(String id) async {
    return Result.success(_createMutation(id: id));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Mutation _createMutation({
  String id = 'mut-101',
  String ticketNumber = 'MUT-2026-0001',
  bool isAssetMovingWithApplicant = false,
  String targetPic = '',
}) {
  return Mutation(
    id: id,
    ticketNumber: ticketNumber,
    isUnregisteredAsset: false,
    applicantId: 'usr-pemohon',
    applicantName: 'Ahmad Pemohon',
    currentLocation: 'Ruang Server A',
    targetLocation: 'Gudang Pusat B',
    currentPic: 'Ahmad Pemohon',
    targetPic: targetPic,
    reason: 'Pindah penempatan aset kantor',
    isAssetMovingWithApplicant: isAssetMovingWithApplicant,
    status: MutationStatus.waitingAssetVerification,
    requiresKadivApproval: false,
    createdAt: DateTime.now(),
  );
}

void main() {
  late FakeMutationRepository fakeMutationRepo;
  late List<User> masterUsersList;

  const testStaff = User(
    id: 'ba-01',
    username: 'bagianaset1',
    name: 'Staf Aset',
    email: 'aset@mutasiku.id',
    role: UserRole.bagianAset,
  );

  setUp(() {
    fakeMutationRepo = FakeMutationRepository();
    masterUsersList = [
      const User(
        id: '10',
        username: 'pic_aktif_1',
        name: 'Rian PIC Aktif',
        email: 'rian@mutasiku.id',
        role: UserRole.operator,
        isActive: true,
      ),
      const User(
        id: '20',
        username: 'pic_aktif_2',
        name: 'Siti PIC Cabang',
        email: 'siti@mutasiku.id',
        role: UserRole.pemohon,
        isActive: true,
      ),
      const User(
        id: '99',
        username: 'pic_nonaktif',
        name: 'Doni Nonaktif',
        email: 'doni@mutasiku.id',
        role: UserRole.operator,
        isActive: false,
      ),
    ];
  });

  Widget buildTestApp({required Widget home}) {
    return ProviderScope(
      overrides: [
        apiMutationRepositoryProvider.overrideWithValue(fakeMutationRepo),
        mutationRepositoryProvider.overrideWithValue(fakeMutationRepo),
        authStateProvider.overrideWith((ref) => FakeAuthNotifier(testStaff)),
        masterUsersProvider.overrideWith(
          (ref) => MasterUsersNotifier(FakeUserRepository(masterUsersList)),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(body: home),
      ),
    );
  }

  group('PicSelectionDialog Tests', () {
    testWidgets(
        'Menampilkan instruksi wajib dan data PIC dari pengguna aktif',
        (tester) async {
      final mutation = _createMutation();

      await tester.pumpWidget(
        buildTestApp(
          home: PicSelectionDialog(mutation: mutation),
        ),
      );
      await tester.pumpAndSettle();

      // Cek instruksi spesifik sesuai persyaratan
      expect(
        find.text(
          'Pemohon tidak membawa aset. Pilih PIC baru yang bertanggung jawab atas aset ini sebelum melanjutkan verifikasi.',
        ),
        findsOneWidget,
      );

      // Cek header dan ringkasan
      expect(find.text('Pilih PIC Baru Aset'), findsOneWidget);
      expect(find.text('MUT-2026-0001'), findsOneWidget);
      expect(find.byKey(const Key('btn_lanjutkan_verifikasi')), findsOneWidget);

      // Cek dropdown
      expect(find.byKey(const Key('dropdown_pilih_pic_baru')), findsOneWidget);
      expect(find.text('-- Pilih PIC Baru --'), findsOneWidget);
    });

    testWidgets(
        'Menekan Lanjutkan tanpa memilih PIC menampilkan pesan validasi dan tidak menutup dialog',
        (tester) async {
      final mutation = _createMutation();

      await tester.pumpWidget(
        buildTestApp(
          home: PicSelectionDialog(mutation: mutation),
        ),
      );
      await tester.pumpAndSettle();

      // Klik tombol Lanjutkan tanpa memilih PIC
      await tester.tap(find.byKey(const Key('btn_lanjutkan_verifikasi')));
      await tester.pumpAndSettle();

      // Pesan validasi muncul
      expect(
        find.text(
          'Pilih PIC baru terlebih dahulu sebelum melanjutkan verifikasi.',
        ),
        findsOneWidget,
      );

      // Dialog tetap terbuka
      expect(find.text('Pilih PIC Baru Aset'), findsOneWidget);
    });

    testWidgets(
        'Memilih PIC dan menekan Lanjutkan menutup dialog dan mengembalikan ID PIC',
        (tester) async {
      final mutation = _createMutation();
      String? returnedPicId;

      await tester.pumpWidget(
        buildTestApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                key: const Key('btn_trigger_dialog'),
                onPressed: () async {
                  returnedPicId = await showPicSelectionDialog(
                    context,
                    mutation: mutation,
                  );
                },
                child: const Text('Buka Dialog PIC'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Buka dialog
      await tester.tap(find.byKey(const Key('btn_trigger_dialog')));
      await tester.pumpAndSettle();

      expect(find.text('Pilih PIC Baru Aset'), findsOneWidget);

      // Buka dropdown
      await tester.tap(find.byKey(const Key('dropdown_pilih_pic_baru')));
      await tester.pumpAndSettle();

      // Pastikan pengguna nonaktif tidak muncul di daftar pilihan
      expect(find.textContaining('Doni Nonaktif'), findsNothing);

      // Pilih pengguna aktif 'Rian PIC Aktif'
      await tester.tap(find.textContaining('Rian PIC Aktif').last);
      await tester.pumpAndSettle();

      // Klik Lanjutkan
      await tester.tap(find.byKey(const Key('btn_lanjutkan_verifikasi')));
      await tester.pumpAndSettle();

      // Dialog tertutup dan returnedPicId berisi ID pengguna yang dipilih
      expect(find.text('Pilih PIC Baru Aset'), findsNothing);
      expect(returnedPicId, '10');
    });

    testWidgets(
        'Menekan Batal pada dialog PIC menutup dialog dan mengembalikan null',
        (tester) async {
      final mutation = _createMutation();
      String? returnedPicId = 'not-null';

      await tester.pumpWidget(
        buildTestApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                key: const Key('btn_trigger_dialog'),
                onPressed: () async {
                  returnedPicId = await showPicSelectionDialog(
                    context,
                    mutation: mutation,
                  );
                },
                child: const Text('Buka Dialog PIC'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_trigger_dialog')));
      await tester.pumpAndSettle();

      expect(find.text('Pilih PIC Baru Aset'), findsOneWidget);

      // Klik Batal
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih PIC Baru Aset'), findsNothing);
      expect(returnedPicId, isNull);
    });
  });

  group('Alur Verifikasi Bagian Aset (startBagianAsetVerificationFlow) Tests', () {
    testWidgets(
        'Kondisi A (Aset tidak dibawa pemohon): membuka modal verifikasi tunggal langsung, memilih PIC di dalam modal, dan Simpan meneruskan PIC terpilih',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mutation = _createMutation(
        isAssetMovingWithApplicant: false,
        targetPic: '',
      );

      await tester.pumpWidget(
        buildTestApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                key: const Key('btn_pilih_pic_dan_verifikasi'),
                onPressed: () => startBagianAsetVerificationFlow(
                  context,
                  mutation: mutation,
                ),
                child: const Text('Pilih PIC & Verifikasi'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Klik Pilih PIC & Verifikasi
      await tester.tap(find.byKey(const Key('btn_pilih_pic_dan_verifikasi')));
      await tester.pumpAndSettle();

      // Modal verifikasi tunggal langsung terbuka
      expect(find.text('Verifikasi Bagian Aset'), findsOneWidget);
      expect(find.text('Pilih PIC Baru Aset'), findsNothing);
      expect(find.byKey(const Key('dropdown_pilih_pic_baru')), findsOneWidget);

      // Pilih PIC dari dropdown di dalam modal
      await tester.tap(find.byKey(const Key('dropdown_pilih_pic_baru')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Siti PIC Cabang').last);
      await tester.pumpAndSettle();

      // Klik Simpan Verifikasi
      final saveBtn = find.byKey(const Key('btn_simpan_verifikasi_bagian_aset'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Repository dipanggil dengan PIC yang telah dipilih
      expect(fakeMutationRepo.lastForwardedId, 'mut-101');
      expect(fakeMutationRepo.lastForwardedPic, '20');
    });

    testWidgets(
        'Kondisi A: Membatalkan modal verifikasi tidak memanggil API dan tidak mengubah status',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mutation = _createMutation(
        isAssetMovingWithApplicant: false,
        targetPic: '',
      );

      await tester.pumpWidget(
        buildTestApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                key: const Key('btn_pilih_pic_dan_verifikasi'),
                onPressed: () => startBagianAsetVerificationFlow(
                  context,
                  mutation: mutation,
                ),
                child: const Text('Pilih PIC & Verifikasi'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Buka alur
      await tester.tap(find.byKey(const Key('btn_pilih_pic_dan_verifikasi')));
      await tester.pumpAndSettle();

      expect(find.text('Verifikasi Bagian Aset'), findsOneWidget);

      // Tekan Batal di modal verifikasi
      final cancelBtn = find.byKey(const Key('btn_batal_verifikasi_modal'));
      await tester.ensureVisible(cancelBtn);
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      // Modal tertutup
      expect(find.text('Verifikasi Bagian Aset'), findsNothing);
      expect(fakeMutationRepo.lastForwardedId, isNull);
      expect(fakeMutationRepo.lastReturnedId, isNull);
    });

    testWidgets(
        'Kondisi B (Aset dibawa pemohon): langsung membuka modal keputusan tanpa mewajibkan PIC baru',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mutation = _createMutation(
        isAssetMovingWithApplicant: true,
        targetPic: 'Ahmad Pemohon',
      );

      await tester.pumpWidget(
        buildTestApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                key: const Key('btn_verifikasi_langsung'),
                onPressed: () => startBagianAsetVerificationFlow(
                  context,
                  mutation: mutation,
                ),
                child: const Text('Verifikasi & Teruskan ke Kadiv'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Klik tombol verifikasi
      await tester.tap(find.byKey(const Key('btn_verifikasi_langsung')));
      await tester.pumpAndSettle();

      // Modal keputusan terbuka, bagian PIC baru tidak ditampilkan
      expect(find.text('Pilih PIC Baru Aset'), findsNothing);
      expect(find.text('Verifikasi Bagian Aset'), findsOneWidget);
      expect(find.byKey(const Key('dropdown_pilih_pic_baru')), findsNothing);
      expect(find.text('Simpan Verifikasi Bagian Aset'), findsOneWidget);
    });
  });
}
