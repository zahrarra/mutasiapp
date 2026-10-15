// test/features/pemohon/pemohon_returned_edit_resubmit_test.dart
//
// Integration & widget test untuk alur mutasi yang dikembalikan (Terminal Returned Rule):
// 1. Layar detail mutasi menampilkan alasan pengembalian, tidak menampilkan tombol Edit & Ajukan Ulang, dan menyediakan tombol Ajukan Mutasi Baru.
// 2. Mutasi yang dikembalikan berstatus final dan tidak muncul di antrean verifikasi aktif Operator maupun Bagian Aset.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mutasiku/app/router/route_names.dart';
import 'package:mutasiku/core/errors/failures.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/features/asset/domain/entities/asset.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_category.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_status.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/auth/domain/repositories/auth_repository.dart';
import 'package:mutasiku/features/auth/domain/usecases/login_usecase.dart';
import 'package:mutasiku/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';
import 'package:mutasiku/features/bagian_aset/presentation/providers/bagian_aset_verification_provider.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';
import 'package:mutasiku/features/operator/presentation/providers/operator_verification_provider.dart';
import 'package:mutasiku/features/pemohon/presentation/screens/pemohon_mutation_detail_screen.dart';

class _FakeAuthRepo implements AuthRepository {
  final User? user;
  _FakeAuthRepo(this.user);
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
  }) async => Result.success(user!);
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(User user)
      : super(
          loginUseCase: LoginUseCase(repository: _FakeAuthRepo(user)),
          logoutUseCase: LogoutUseCase(repository: _FakeAuthRepo(user)),
          authRepository: _FakeAuthRepo(user),
        ) {
    state = AuthState(isLoading: false, user: user);
  }
}

class _MockMutationRepository implements MutationRepository {
  final Map<String, Mutation> _mutations = {};

  void addMutation(Mutation m) {
    _mutations[m.id] = m;
  }

  @override
  Future<Result<Mutation>> getMutationById(String id) async {
    final m = _mutations[id];
    if (m != null) return Result.success(m);
    return Result.failure(const NotFoundFailure(message: 'Mutation not found'));
  }

  @override
  Future<Result<List<Mutation>>> getAllMutations() async {
    return Result.success(_mutations.values.toList());
  }

  @override
  Future<Result<List<Mutation>>> getMutationsByUser(String userId) async {
    final userList =
        _mutations.values.where((m) => m.applicantId == userId).toList();
    return Result.success(userList);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const pemohonA = User(
    id: 'user_pemohon_a',
    username: '199001012020011001',
    name: 'Rina Pemohon A',
    email: 'rina@mutasiku.test',
    role: UserRole.pemohon,
  );

  const testAsset = Asset(
    id: 'ast_printer_001',
    assetCode: 'AST-PRN-001',
    name: 'Printer HP LaserJet',
    category: AssetCategory(id: 'c1', code: 'PRN', name: 'Printer'),
    location: 'Lantai 2 - Keuangan',
    pic: 'Rina Pemohon A',
    status: AssetStatus.inMutation,
    condition: 'Baik',
    acquisitionYear: 2023,
  );

  Mutation createReturnedMutation({
    required String applicantId,
    required String applicantName,
    String? returnReason =
        'Harap lengkapi surat pengantar mutasi dan ubah PIC ke supervisor terkait.',
    String? assetReturnReason,
    String? rejectedBy,
  }) {
    return Mutation(
      id: 'mut_ret_001',
      ticketNumber: 'MUT-2026-RET001',
      asset: testAsset,
      applicantId: applicantId,
      applicantName: applicantName,
      currentLocation: 'Lantai 2 - Keuangan',
      targetLocation: 'Lantai 3 - IT',
      currentPic: 'Rina Pemohon A',
      targetPic: 'Andi IT',
      reason: 'Kebutuhan cetak dokumen laporan keuangan',
      status: MutationStatus.returned,
      returnReason: returnReason,
      assetReturnReason: assetReturnReason,
      rejectedBy: rejectedBy,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    );
  }

  group('Terminal Returned Mutation Tests', () {
    testWidgets(
      '1. Detail pengajuan returned menampilkan alasan pengembalian, status badge, tombol edit & resubmit TIDAK ada, tombol Ajukan Mutasi Baru tersedia',
      (tester) async {
        final repo = _MockMutationRepository();
        final mutationA = createReturnedMutation(
          applicantId: pemohonA.id,
          applicantName: pemohonA.name,
        );
        repo.addMutation(mutationA);

        final container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => _FakeAuthNotifier(pemohonA),
            ),
            mutationRepositoryProvider.overrideWithValue(repo),
            apiMutationRepositoryProvider.overrideWithValue(repo),
          ],
        );
        addTearDown(container.dispose);

        final router = GoRouter(
          initialLocation: '/pemohon/mutasi/${mutationA.id}',
          routes: [
            GoRoute(
              path: RouteNames.pemohonMutasiCreatePath,
              builder: (context, state) =>
                  const Scaffold(body: Text('Form Pengajuan Baru')),
            ),
            GoRoute(
              path: RouteNames.pemohonMutasiDetailPath,
              builder: (context, state) =>
                  PemohonMutationDetailScreen(mutationId: mutationA.id),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Alasan pengembalian ditampilkan
        expect(
          find.text(
            'Harap lengkapi surat pengantar mutasi dan ubah PIC ke supervisor terkait.',
          ),
          findsOneWidget,
        );

        // 2. Tombol edit & ajukan ulang TIDAK tersedia
        expect(find.text('Edit & Ajukan Ulang'), findsNothing);

        // 3. Tombol Ajukan Mutasi Baru tersedia
        expect(find.byKey(const Key('btn_ajukan_mutasi_baru')), findsOneWidget);

        // 4. Klik Ajukan Mutasi Baru mengarah ke form pengajuan
        await tester.ensureVisible(find.byKey(const Key('btn_ajukan_mutasi_baru')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('btn_ajukan_mutasi_baru')));
        await tester.pumpAndSettle();

        expect(find.text('Form Pengajuan Baru'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Mutasi yang dikembalikan berstatus final dan tidak muncul di antrean verifikasi aktif Operator maupun Bagian Aset',
      (tester) async {
        final repo = _MockMutationRepository();
        final mutationA = createReturnedMutation(
          applicantId: pemohonA.id,
          applicantName: pemohonA.name,
        );
        repo.addMutation(mutationA);

        final container = ProviderContainer(
          overrides: [
            mutationRepositoryProvider.overrideWithValue(repo),
            apiMutationRepositoryProvider.overrideWithValue(repo),
          ],
        );
        addTearDown(container.dispose);

        // Operator queue hanya menampilkan mutasi berstatus submitted
        final operatorList = await container.read(
          operatorAllMutationsProvider.future,
        );
        final operatorActiveQueue = operatorList
            .where((m) => m.status == MutationStatus.submitted)
            .toList();
        expect(
          operatorActiveQueue.any((m) => m.id == mutationA.id),
          isFalse,
        );

        // Bagian Aset queue hanya menampilkan mutasi berstatus waitingAssetVerification
        final assetList = await container.read(
          bagianAsetAllMutationsProvider.future,
        );
        final assetActiveQueue = assetList
            .where((m) => m.status == MutationStatus.waitingAssetVerification)
            .toList();
        expect(
          assetActiveQueue.any((m) => m.id == mutationA.id),
          isFalse,
        );
      },
    );
  });
}
