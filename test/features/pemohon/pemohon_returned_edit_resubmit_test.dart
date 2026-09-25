// test/features/pemohon/pemohon_returned_edit_resubmit_test.dart
//
// Validation test suite for Edit + Ajukan Ulang:
// returned → edit → ajukan ulang → submitted → muncul di Operator

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
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';
import 'package:mutasiku/features/operator/presentation/providers/operator_verification_provider.dart';
import 'package:mutasiku/features/pemohon/presentation/screens/pemohon_edit_mutation_screen.dart';

class _FakeAuthRepo implements AuthRepository {
  final User? user;
  _FakeAuthRepo(this.user);
  @override
  Future<Result<User?>> getCurrentUser() async => Result.success(user);
  @override
  Future<Result<User>> login({required String username, required String password}) async =>
      Result.success(user!);
  @override
  Future<void> logout() async {}
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
  bool shouldFailUpdate = false;

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
    final userList = _mutations.values.where((m) => m.applicantId == userId).toList();
    return Result.success(userList);
  }

  @override
  Future<Result<Mutation>> updateMutation({
    required String mutationId,
    required String targetLocation,
    required String targetPic,
    required String reason,
    String? documentName,
  }) async {
    if (shouldFailUpdate) {
      return Result.failure(
        const ValidationFailure(message: 'Simulasi kegagalan saat menyimpan.'),
      );
    }

    final current = _mutations[mutationId];
    if (current == null) {
      return Result.failure(const NotFoundFailure(message: 'Mutation not found'));
    }

    // Keep ticket number and mutationId unchanged. Keep returnReason as history.
    final updated = current.copyWith(
      targetLocation: targetLocation,
      targetPic: targetPic,
      reason: reason,
      documentName: documentName,
      status: MutationStatus.submitted,
    );

    _mutations[mutationId] = updated;
    return Result.success(updated);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const pemohonA = User(
    id: 'usr_pemohon_a',
    username: 'pemohonA',
    name: 'Rina Pemohon A',
    email: 'rina@mutasiku.id',
    role: UserRole.pemohon,
  );

  const pemohonB = User(
    id: 'usr_pemohon_b',
    username: 'pemohonB',
    name: 'Budi Pemohon B',
    email: 'budi@mutasiku.id',
    role: UserRole.pemohon,
  );

  const testAsset = Asset(
    id: 'asset_prn_01',
    assetCode: 'PRN-2026-0001',
    name: 'Printer HP LaserJet',
    category: AssetCategory(id: 'cat_elk', code: 'ELK', name: 'Elektronik'),
    location: 'Lantai 2 - Keuangan',
    pic: 'Rina Pemohon A',
    status: AssetStatus.available,
    condition: 'Baik',
    acquisitionYear: 2024,
  );

  Mutation createReturnedMutation({required String applicantId, required String applicantName}) {
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
      returnReason: 'Harap lengkapi surat pengantar mutasi dan ubah PIC ke supervisor terkait.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    );
  }

  group('Edit + Ajukan Ulang Workflow Tests', () {
    testWidgets('1. Pemohon hanya bisa edit mutation miliknya sendiri (Akses Ditolak untuk user lain)',
        (tester) async {
      final repo = _MockMutationRepository();
      // Mutation belongs to Pemohon A
      final mutationA = createReturnedMutation(
        applicantId: pemohonA.id,
        applicantName: pemohonA.name,
      );
      repo.addMutation(mutationA);

      // Logged in as Pemohon B
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier(pemohonB)),
          mutationRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/pemohon/mutasi/${mutationA.id}/edit',
        routes: [
          GoRoute(
            path: RouteNames.pemohonMutasiEditPath,
            builder: (context, state) =>
                PemohonEditMutationScreen(mutationId: mutationA.id),
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

      // Access Denied view is displayed
      expect(find.text('Akses Ditolak'), findsOneWidget);
      expect(
        find.text('Anda hanya dapat mengedit pengajuan mutasi milik Anda sendiri.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('btn_ajukan_ulang')), findsNothing);
    });

    testWidgets(
        '2. Pemohon can edit own mutation, operator returnReason is shown, resubmit changes status to submitted and appears in Operator queue',
        (tester) async {
      final repo = _MockMutationRepository();
      // Mutation belongs to Pemohon A
      final mutationA = createReturnedMutation(
        applicantId: pemohonA.id,
        applicantName: pemohonA.name,
      );
      repo.addMutation(mutationA);

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier(pemohonA)),
          mutationRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/pemohon/mutasi/${mutationA.id}/edit',
        routes: [
          GoRoute(
            path: RouteNames.pemohonMutasiEditPath,
            builder: (context, state) =>
                PemohonEditMutationScreen(mutationId: mutationA.id),
          ),
          GoRoute(
            path: RouteNames.pemohonMutasiDetailPath,
            builder: (context, state) =>
                Scaffold(body: Text('Detail ${state.pathParameters['id']}')),
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

      // Verify operator returnReason is clearly displayed
      expect(find.text('Catatan dari Operator:'), findsOneWidget);
      expect(
        find.text('Harap lengkapi surat pengantar mutasi dan ubah PIC ke supervisor terkait.'),
        findsOneWidget,
      );

      // Verify initial status in repository is returned
      expect(repo._mutations[mutationA.id]!.status, equals(MutationStatus.returned));

      // Edit fields
      await tester.enterText(
        find.byKey(const Key('input_edit_target_location')),
        'Lantai 4 - Logistik Baru',
      );
      await tester.enterText(
        find.byKey(const Key('input_edit_target_pic')),
        'Dedi Supervisor',
      );
      await tester.enterText(
        find.byKey(const Key('input_edit_reason')),
        'Telah diperbaiki: PIC diubah ke Supervisor Dedi sesuai catatan Operator.',
      );

      // Scroll to and press "Ajukan Ulang"
      await tester.ensureVisible(find.byKey(const Key('btn_ajukan_ulang')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_ajukan_ulang')));
      await tester.pumpAndSettle();

      // Verify success feedback
      expect(
        find.text('Pengajuan berhasil diajukan ulang ke antrean verifikasi Operator.'),
        findsOneWidget,
      );

      // Verify status in repository is now SUBMITTED
      final updatedMutation = repo._mutations[mutationA.id]!;
      expect(updatedMutation.status, equals(MutationStatus.submitted));

      // Verify mutationId and ticketNumber did NOT change
      expect(updatedMutation.id, equals('mut_ret_001'));
      expect(updatedMutation.ticketNumber, equals('MUT-2026-RET001'));

      // Verify returnReason history is PRESERVED
      expect(
        updatedMutation.returnReason,
        equals('Harap lengkapi surat pengantar mutasi dan ubah PIC ke supervisor terkait.'),
      );

      // Verify updated values
      expect(updatedMutation.targetLocation, equals('Lantai 4 - Logistik Baru'));
      expect(updatedMutation.targetPic, equals('Dedi Supervisor'));
      expect(
        updatedMutation.reason,
        equals('Telah diperbaiki: PIC diubah ke Supervisor Dedi sesuai catatan Operator.'),
      );

      // Verify Operator queue now includes this mutation
      final operatorList = await container.read(operatorAllMutationsProvider.future);
      expect(
        operatorList.any((m) => m.id == 'mut_ret_001' && m.status == MutationStatus.submitted),
        isTrue,
      );
    });

    testWidgets('3. If resubmit fails, mutation remains returned and error is displayed',
        (tester) async {
      final repo = _MockMutationRepository();
      repo.shouldFailUpdate = true; // Server error simulation

      final mutationA = createReturnedMutation(
        applicantId: pemohonA.id,
        applicantName: pemohonA.name,
      );
      repo.addMutation(mutationA);

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier(pemohonA)),
          mutationRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/pemohon/mutasi/${mutationA.id}/edit',
        routes: [
          GoRoute(
            path: RouteNames.pemohonMutasiEditPath,
            builder: (context, state) =>
                PemohonEditMutationScreen(mutationId: mutationA.id),
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

      // Scroll and tap "Ajukan Ulang"
      await tester.ensureVisible(find.byKey(const Key('btn_ajukan_ulang')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_ajukan_ulang')));
      await tester.pumpAndSettle();

      // Error feedback is displayed
      expect(find.text('Simulasi kegagalan saat menyimpan.'), findsOneWidget);

      // Status in repository MUST remain returned
      expect(repo._mutations[mutationA.id]!.status, equals(MutationStatus.returned));
    });
  });
}
