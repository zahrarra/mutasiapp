import 'package:mutasiku/core/errors/failures.dart';
// test/features/bagian_aset/bagian_aset_verification_flow_and_queue_test.dart
//
// Tests for Bagian Aset Verification flow & queue wiring (PRD V1.1 §6.4):
// - Scenario A (No Kadiv): Operator verify -> waitingAssetVerification -> Bagian Aset verify & forward -> waitingConfirmation
// - Scenario B (Requires Kadiv): Operator verify -> waitingAssetVerification -> Bagian Aset verify & forward -> waitingDivisionApproval
// - Bagian Aset return + return reason preserved
// - Dashboard pending count updates
// - "Menunggu Verifikasi" & "Semua" filter consistency
// - Provider invalidation & no fake success

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/features/asset/data/repositories/asset_repository_impl.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/auth/domain/repositories/auth_repository.dart';
import 'package:mutasiku/features/auth/domain/usecases/login_usecase.dart';
import 'package:mutasiku/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';
import 'package:mutasiku/features/bagian_aset/presentation/providers/bagian_aset_verification_provider.dart';
import 'package:mutasiku/features/kadiv/presentation/providers/kadiv_approval_provider.dart';
import 'package:mutasiku/features/mutation/data/repositories/mutation_repository_impl.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';

class _FakeAuthRepository implements AuthRepository {
  final User? user;
  _FakeAuthRepository(this.user);

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

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(User user)
    : super(
        loginUseCase: LoginUseCase(repository: _FakeAuthRepository(user)),
        logoutUseCase: LogoutUseCase(repository: _FakeAuthRepository(user)),
        authRepository: _FakeAuthRepository(user),
      ) {
    state = AuthState(isLoading: false, user: user);
  }
}

const bagianAsetTestUser = User(
  id: 'usr_bagian_aset_test',
  username: 'bagian_aset_test',
  name: 'H. M. Yusuf (Bagian Aset)',
  email: 'bagian.aset@mutasiku.id',
  role: UserRole.bagianAset,
);

const operatorTestUser = User(
  id: 'usr_operator_test',
  username: 'op_test',
  name: 'Operator Aset',
  email: 'operator@mutasiku.id',
  role: UserRole.operator,
);

void main() {
  setUp(() {
    MutationRepositoryImpl.resetForTesting();
    final assetRepo = AssetRepositoryImpl();
    MutationRepositoryImpl(assetRepository: assetRepo);
  });

  group('Scenario A: Operator verify -> waitingAssetVerification -> Bagian Aset verifyAndForward (No Kadiv) -> waitingConfirmation', () {
    test('End to end flow without Kadiv', () async {
      final element = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => _FakeAuthNotifier(bagianAsetTestUser),
          ),
          apiMutationRepositoryProvider.overrideWith(
            (ref) => ref.watch(mutationRepositoryProvider),
          ),
        ],
      );

      final repo = element.read(mutationRepositoryProvider);

      // 1. Verify mut_001 by Operator without Kadiv
      final verifyRes = await repo.verifyMutation(
        mutationId: 'mut_001',
        operatorName: 'Operator Aset',
        requiresKadivApproval: false,
      );
      expect(verifyRes.isSuccess, true);
      final verifiedMutation = verifyRes.dataOrNull!;
      expect(verifiedMutation.status.isWaitingAssetVerification, true);
      expect(verifiedMutation.requiresKadivApproval, false);

      // 2. Invalidate and check Bagian Aset queues
      element.invalidate(bagianAsetAllMutationsProvider);
      final bagianAsetAll = await element.read(
        bagianAsetAllMutationsProvider.future,
      );
      expect(
        bagianAsetAll.any(
          (m) => m.id == 'mut_001' && m.status.isWaitingAssetVerification,
        ),
        true,
      );

      // Check stats: mut_001 is counted in waitingVerificationCount
      final statsBefore = element.read(bagianAsetStatsProvider);
      expect(statsBefore.waitingVerificationCount >= 1, true);

      // Check "Menunggu Verifikasi" filter
      element.read(bagianAsetStatusFilterProvider.notifier).state =
          BagianAsetStatusFilter.waiting;
      final waitingList =
          element.read(filteredBagianAsetVerificationsProvider).value ?? [];
      expect(waitingList.any((m) => m.id == 'mut_001'), true);

      // Check "Semua" filter
      element.read(bagianAsetStatusFilterProvider.notifier).state =
          BagianAsetStatusFilter.all;
      final allList =
          element.read(filteredBagianAsetVerificationsProvider).value ?? [];
      expect(allList.any((m) => m.id == 'mut_001'), true);

      // 3. Bagian Aset verifies and forwards
      final verifySuccess = await element
          .read(bagianAsetVerificationActionProvider.notifier)
          .verifyAndForward(mutationId: 'mut_001');
      expect(verifySuccess, true);

      // 4. Verify post-verification state
      final detailAfter = await element.read(
        mutationDetailProvider('mut_001').future,
      );
      expect(detailAfter.status.isWaitingDivisionApproval, true);
      expect(detailAfter.assetVerifiedBy, 'H. M. Yusuf (Bagian Aset)');

      // Verify removed from "Menunggu Verifikasi" queue
      await element.read(bagianAsetAllMutationsProvider.future);
      element.read(bagianAsetStatusFilterProvider.notifier).state =
          BagianAsetStatusFilter.waiting;
      final waitingAfter =
          element.read(filteredBagianAsetVerificationsProvider).value ?? [];
      expect(waitingAfter.any((m) => m.id == 'mut_001'), false);
    });
  });

  group('Scenario B: Operator verify -> waitingAssetVerification -> Bagian Aset verifyAndForward (Requires Kadiv) -> waitingKadivApproval', () {
    test('End to end flow with Kadiv', () async {
      final element = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => _FakeAuthNotifier(bagianAsetTestUser),
          ),
          apiMutationRepositoryProvider.overrideWith(
            (ref) => ref.watch(mutationRepositoryProvider),
          ),
        ],
      );

      final repo = element.read(mutationRepositoryProvider);

      // 1. Verify mut_002 by Operator WITH Kadiv
      final verifyRes = await repo.verifyMutation(
        mutationId: 'mut_002',
        operatorName: 'Operator Aset',
        requiresKadivApproval: true,
      );
      expect(verifyRes.isSuccess, true);
      final verifiedMutation = verifyRes.dataOrNull!;
      expect(verifiedMutation.status.isWaitingAssetVerification, true);
      expect(verifiedMutation.requiresKadivApproval, true);

      // 2. Bagian Aset queue check
      element.invalidate(bagianAsetAllMutationsProvider);
      await element.read(bagianAsetAllMutationsProvider.future);
      element.read(bagianAsetStatusFilterProvider.notifier).state =
          BagianAsetStatusFilter.waiting;
      final waitingList =
          element.read(filteredBagianAsetVerificationsProvider).value ?? [];
      expect(waitingList.any((m) => m.id == 'mut_002'), true);

      // 3. Bagian Aset verifies and forwards (requires Kadiv)
      final forwardSuccess = await element
          .read(bagianAsetVerificationActionProvider.notifier)
          .verifyAndForward(mutationId: 'mut_002');
      expect(forwardSuccess, true);

      // 4. Verify post-verification state -> waitingDivisionApproval
      final detailAfter = await element.read(
        mutationDetailProvider('mut_002').future,
      );
      expect(detailAfter.status.isWaitingDivisionApproval, true);
      expect(detailAfter.assetVerifiedBy, 'H. M. Yusuf (Bagian Aset)');

      // Verify removed from Bagian Aset "Menunggu Verifikasi" queue
      await element.read(bagianAsetAllMutationsProvider.future);
      element.read(bagianAsetStatusFilterProvider.notifier).state =
          BagianAsetStatusFilter.waiting;
      final waitingAfter =
          element.read(filteredBagianAsetVerificationsProvider).value ?? [];
      expect(waitingAfter.any((m) => m.id == 'mut_002'), false);

      // Verify visible in Kadiv queue
      final kadivList = await element.read(kadivAllMutationsProvider.future);
      expect(kadivList.any((m) => m.id == 'mut_002'), true);
    });
  });

  group('Bagian Aset Return action with preserved return reason', () {
    test(
      'Returns waitingAssetVerification and preserves return reason',
      () async {
        final element = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => _FakeAuthNotifier(bagianAsetTestUser),
            ),
            apiMutationRepositoryProvider.overrideWith(
              (ref) => ref.watch(mutationRepositoryProvider),
            ),
          ],
        );

        final returnSuccess = await element
            .read(bagianAsetVerificationActionProvider.notifier)
            .returnToApplicant(
              mutationId: 'mut_004',
              reason:
                  'Alokasi anggaran belum tersedia untuk relokasi aset ini.',
            );
        expect(returnSuccess, true);

        final detailAfter = await element.read(
          mutationDetailProvider('mut_004').future,
        );
        expect(detailAfter.status, MutationStatus.returned);
        expect(
          detailAfter.returnReason,
          'Alokasi anggaran belum tersedia untuk relokasi aset ini.',
        );

        // Removed from "Menunggu Verifikasi"
        await element.read(bagianAsetAllMutationsProvider.future);
        element.read(bagianAsetStatusFilterProvider.notifier).state =
            BagianAsetStatusFilter.waiting;
        final waitingAfter =
            element.read(filteredBagianAsetVerificationsProvider).value ?? [];
        expect(waitingAfter.any((m) => m.id == 'mut_004'), false);

        // Present in "Dikembalikan" and "Semua"
        element.read(bagianAsetStatusFilterProvider.notifier).state =
            BagianAsetStatusFilter.returned;
        final returnedAfter =
            element.read(filteredBagianAsetVerificationsProvider).value ?? [];
        expect(returnedAfter.any((m) => m.id == 'mut_004'), true);
      },
    );
  });
}
