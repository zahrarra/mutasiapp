// test/features/kabag/kabag_approval_flow_and_queue_test.dart
//
// Tests for Kabag Approval flow & queue wiring:
// - Scenario A (No Kadiv): Operator verify -> waitingKabagApproval -> Kabag approve -> approvedWaitingAssetUpdate
// - Scenario B (Requires Kadiv): Operator verify -> waitingKabagApproval -> Kabag approve -> waitingKadivApproval
// - Kabag reject + rejection reason preserved
// - Dashboard pending count updates
// - "Menunggu Approval" & "Semua" filter consistency
// - Provider invalidation & no fake success

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/features/asset/data/repositories/asset_repository_impl.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/auth/domain/repositories/auth_repository.dart';
import 'package:mutasiku/features/auth/domain/usecases/login_usecase.dart';
import 'package:mutasiku/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';
import 'package:mutasiku/features/kadiv/presentation/providers/kadiv_approval_provider.dart';
import 'package:mutasiku/features/kabag/presentation/providers/kabag_approval_provider.dart';
import 'package:mutasiku/features/kabag/presentation/screens/kabag_dashboard_screen.dart';
import 'package:mutasiku/features/mutation/data/repositories/mutation_repository_impl.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';
import 'package:mutasiku/features/staff/presentation/providers/staff_mutation_provider.dart';

class _FakeAuthRepository implements AuthRepository {
  final User? user;
  _FakeAuthRepository(this.user);

  @override
  Future<Result<User?>> getCurrentUser() async => Result.success(user);
  @override
  Future<Result<User>> login({required String username, required String password}) async =>
      throw UnimplementedError();
  @override
  Future<void> logout() async {}
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

const kabagTestUser = User(
  id: 'usr_kabag_test',
  username: 'kabag_test',
  name: 'H. M. Yusuf (Kabag Aset)',
  email: 'kabag@mutasiku.id',
  role: UserRole.kabagAset,
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

  group('Scenario A: Operator verify -> waitingKabagApproval -> Kabag approve (No Kadiv) -> approved', () {
    test('End to end flow without Kadiv', () async {

      final element = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier(kabagTestUser)),
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
      expect(verifiedMutation.status, MutationStatus.waitingKabagApproval);
      expect(verifiedMutation.requiresKadivApproval, false);

      // 2. Invalidate and check Kabag queues
      element.invalidate(kabagAllMutationsProvider);
      final kabagAll = await element.read(kabagAllMutationsProvider.future);
      expect(kabagAll.any((m) => m.id == 'mut_001' && m.status == MutationStatus.waitingKabagApproval), true);

      // Check stats: mut_001 is counted in waitingApprovalCount
      final statsBefore = element.read(kabagStatsProvider);
      expect(statsBefore.waitingApprovalCount >= 1, true);

      // Check "Menunggu Approval" filter
      element.read(kabagStatusFilterProvider.notifier).state = KabagStatusFilter.waiting;
      final waitingList = element.read(filteredKabagApprovalsProvider).value ?? [];
      expect(waitingList.any((m) => m.id == 'mut_001'), true);

      // Check "Semua" filter
      element.read(kabagStatusFilterProvider.notifier).state = KabagStatusFilter.all;
      final allList = element.read(filteredKabagApprovalsProvider).value ?? [];
      expect(allList.any((m) => m.id == 'mut_001'), true);

      // 3. Kabag approves without Kadiv
      final approveSuccess = await element.read(kabagApprovalActionProvider.notifier).approve(
            mutationId: 'mut_001',
            requiresKadivApproval: false,
          );
      expect(approveSuccess, true);

      // 4. Verify post-approve state
      final detailAfter = await element.read(mutationDetailProvider('mut_001').future);
      expect(detailAfter.status, MutationStatus.approved);
      expect(detailAfter.approvedBy, 'H. M. Yusuf (Kabag Aset)');

      // Verify removed from "Menunggu Approval" queue
      await element.read(kabagAllMutationsProvider.future);
      element.read(kabagStatusFilterProvider.notifier).state = KabagStatusFilter.waiting;
      final waitingAfter = element.read(filteredKabagApprovalsProvider).value ?? [];
      expect(waitingAfter.any((m) => m.id == 'mut_001'), false);

      // Verify visible in Staff queue
      final staffList = await element.read(staffAllMutationsProvider.future);
      expect(staffList.any((m) => m.id == 'mut_001'), true);
    });
  });

  group('Scenario B: Operator verify -> waitingKabagApproval -> Kabag approve (Requires Kadiv) -> waitingKadivApproval', () {
    test('End to end flow with Kadiv', () async {
      final element = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier(kabagTestUser)),
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
      expect(verifiedMutation.status, MutationStatus.waitingKabagApproval);
      expect(verifiedMutation.requiresKadivApproval, true);

      // 2. Kabag queue check
      element.invalidate(kabagAllMutationsProvider);
      await element.read(kabagAllMutationsProvider.future);
      element.read(kabagStatusFilterProvider.notifier).state = KabagStatusFilter.waiting;
      final waitingList = element.read(filteredKabagApprovalsProvider).value ?? [];
      expect(waitingList.any((m) => m.id == 'mut_002'), true);

      // 3. Kabag approves (requires Kadiv)
      final approveSuccess = await element.read(kabagApprovalActionProvider.notifier).approve(
            mutationId: 'mut_002',
            requiresKadivApproval: true,
          );
      expect(approveSuccess, true);

      // 4. Verify post-approve state -> waitingKadivApproval
      final detailAfter = await element.read(mutationDetailProvider('mut_002').future);
      expect(detailAfter.status, MutationStatus.waitingKadivApproval);
      expect(detailAfter.approvedBy, 'H. M. Yusuf (Kabag Aset)');

      // Verify removed from Kabag "Menunggu Approval" queue
      await element.read(kabagAllMutationsProvider.future);
      element.read(kabagStatusFilterProvider.notifier).state = KabagStatusFilter.waiting;
      final waitingAfter = element.read(filteredKabagApprovalsProvider).value ?? [];
      expect(waitingAfter.any((m) => m.id == 'mut_002'), false);

      // Verify visible in Kadiv queue
      final kadivList = await element.read(kadivAllMutationsProvider.future);
      expect(kadivList.any((m) => m.id == 'mut_002'), true);
    });
  });

  group('Kabag Reject action with preserved rejection reason', () {
    test('Rejects waitingKabagApproval and preserves rejection reason', () async {
      final element = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier(kabagTestUser)),
        ],
      );

      final rejectSuccess = await element.read(kabagApprovalActionProvider.notifier).reject(
            mutationId: 'mut_004',
            reason: 'Alokasi anggaran belum tersedia untuk relokasi aset ini.',
          );
      expect(rejectSuccess, true);

      final detailAfter = await element.read(mutationDetailProvider('mut_004').future);
      expect(detailAfter.status, MutationStatus.rejected);
      expect(detailAfter.rejectionReason, 'Alokasi anggaran belum tersedia untuk relokasi aset ini.');
      expect(detailAfter.rejectedBy, 'H. M. Yusuf (Kabag Aset)');

      // Removed from "Menunggu Approval"
      await element.read(kabagAllMutationsProvider.future);
      element.read(kabagStatusFilterProvider.notifier).state = KabagStatusFilter.waiting;
      final waitingAfter = element.read(filteredKabagApprovalsProvider).value ?? [];
      expect(waitingAfter.any((m) => m.id == 'mut_004'), false);

      // Present in "Ditolak" and "Semua"
      element.read(kabagStatusFilterProvider.notifier).state = KabagStatusFilter.rejected;
      final rejectedAfter = element.read(filteredKabagApprovalsProvider).value ?? [];
      expect(rejectedAfter.any((m) => m.id == 'mut_004'), true);

      element.read(kabagStatusFilterProvider.notifier).state = KabagStatusFilter.all;
      final allAfter = element.read(filteredKabagApprovalsProvider).value ?? [];
      expect(allAfter.any((m) => m.id == 'mut_004'), true);
    });
  });

  group('Dashboard pending count and filter wiring', () {
    testWidgets('Dashboard stat card Menunggu Approval sets filter to waiting', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier(kabagTestUser)),
        ],
      );

      // Start with filter as all
      container.read(kabagStatusFilterProvider.notifier).state = KabagStatusFilter.all;

      final router = GoRouter(
        initialLocation: '/kabag/dashboard',
        routes: [
          GoRoute(
            path: '/kabag/dashboard',
            builder: (context, state) => const KabagDashboardScreen(),
          ),
          GoRoute(
            path: '/kabag/approvals',
            builder: (context, state) => const Scaffold(body: Text('Approvals List')),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Menunggu Approval" card
      await tester.tap(find.text('Menunggu Approval'));
      await tester.pumpAndSettle();

      expect(container.read(kabagStatusFilterProvider), KabagStatusFilter.waiting);

      // Go back to dashboard
      router.go('/kabag/dashboard');
      await tester.pumpAndSettle();

      // Tap "Disetujui" card
      await tester.tap(find.text('Disetujui'));
      await tester.pumpAndSettle();

      expect(container.read(kabagStatusFilterProvider), KabagStatusFilter.approved);

      // Go back to dashboard
      router.go('/kabag/dashboard');
      await tester.pumpAndSettle();

      // Tap "Ditolak" card
      await tester.tap(find.text('Ditolak'));
      await tester.pumpAndSettle();

      expect(container.read(kabagStatusFilterProvider), KabagStatusFilter.rejected);

      // Go back to dashboard
      router.go('/kabag/dashboard');
      await tester.pumpAndSettle();

      // Tap "Lihat Semua"
      await tester.tap(find.text('Lihat Semua'));
      await tester.pumpAndSettle();

      expect(container.read(kabagStatusFilterProvider), KabagStatusFilter.all);
    });

    test('No fake success on failure in approve and reject', () async {
      final element = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier(kabagTestUser)),
        ],
      );

      // Approve unknown mutation -> fails
      final approveResult = await element.read(kabagApprovalActionProvider.notifier).approve(
            mutationId: 'unknown_mutation_999',
            requiresKadivApproval: false,
          );
      expect(approveResult, false);
      expect(element.read(kabagApprovalActionProvider).error, isNotNull);

      // Reject unknown mutation -> fails
      final rejectResult = await element.read(kabagApprovalActionProvider.notifier).reject(
            mutationId: 'unknown_mutation_999',
            reason: 'Alasan penolakan',
          );
      expect(rejectResult, false);
      expect(element.read(kabagApprovalActionProvider).error, isNotNull);

      // Reject without reason -> fails
      final rejectEmptyResult = await element.read(kabagApprovalActionProvider.notifier).reject(
            mutationId: 'mut_004',
            reason: '',
          );
      expect(rejectEmptyResult, false);
    });
  });
}
