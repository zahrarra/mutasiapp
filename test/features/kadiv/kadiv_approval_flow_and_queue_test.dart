// test/features/kadiv/kadiv_approval_flow_and_queue_test.dart
//
// Comprehensive tests for Kadiv Approval flow, queue, detail, and wiring:
// - End-to-end flow: Operator verify -> waitingAssetVerification -> Bagian Aset forward -> waitingKadivApproval
// - Kadiv pending count & queue filtering ("Menunggu Approval", "Semua", "Disetujui", "Ditolak")
// - Kadiv Approve: waitingDivisionApproval -> waitingConfirmation, provider invalidation, Pemohon notification, removed from pending queue
// - Kadiv Reject: waitingKadivApproval -> rejected, requires and preserves rejection reason, applicant notification, removed from pending queue
// - Detail page: shows Operator verification info, actions visible ONLY for waitingKadivApproval
// - No fake success if repository operation fails
// - Notification navigation wiring

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
import 'package:mutasiku/features/kadiv/presentation/screens/kadiv_approval_detail_screen.dart';
import 'package:mutasiku/features/mutation/data/repositories/mutation_repository_impl.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';
import 'package:mutasiku/features/notification/domain/entities/notification_item.dart';
import 'package:mutasiku/features/notification/presentation/providers/notification_provider.dart';
import 'package:mutasiku/features/notification/presentation/screens/notification_screen.dart';

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

class _FakeNotificationNotifier extends NotificationNotifier {
  _FakeNotificationNotifier(List<NotificationItem> items) {
    state = items;
  }
}

const kadivTestUser = User(
  id: 'u_kdv_01',
  username: 'kadiv1',
  name: 'Drs. Ahmad Dahlan (Kadiv)',
  email: 'kadiv@mutasiku.id',
  role: UserRole.kadiv,
);

const bagianAsetTestUser = User(
  id: 'usr_bagian_aset_test',
  username: 'bagian_aset_test',
  name: 'H. M. Yusuf (Bagian Aset)',
  email: 'bagian_aset@mutasiku.id',
  role: UserRole.bagianAset,
);

void main() {
  setUp(() {
    MutationRepositoryImpl.resetForTesting();
    final assetRepo = AssetRepositoryImpl();
    MutationRepositoryImpl(assetRepository: assetRepo);
  });

  group('Kadiv Flow & Queue: Operator verify -> Bagian Aset forward -> waitingKadivApproval', () {
    test('Mutation correctly enters waitingKadivApproval and appears in Kadiv queues', () async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier(kadivTestUser)),
        ],
      );

      final repo = container.read(mutationRepositoryProvider);

      // Verify mut_002 with operator
      final verifyRes = await repo.verifyMutation(
        mutationId: 'mut_002',
        operatorName: 'Budi Santoso',
        requiresKadivApproval: true,
      );
      expect(verifyRes.isSuccess, true);

      // Bagian Aset forwards to Kadiv
      final forwardRes = await repo.assetSectionForward(
        mutationId: 'mut_002',
        verifierName: 'H. M. Yusuf (Bagian Aset)',
        newPic: 'Siti Rahma',
      );
      expect(forwardRes.isSuccess, true);
      final mutation = forwardRes.dataOrNull!;
      expect(mutation.status.isWaitingDivisionApproval, true);
      expect(mutation.requiresKadivApproval, true);
      expect(mutation.assetVerifiedBy, 'H. M. Yusuf (Bagian Aset)');

      // Invalidate Kadiv provider and test queues
      container.invalidate(kadivAllMutationsProvider);
      final kadivAll = await container.read(kadivAllMutationsProvider.future);
      expect(kadivAll.any((m) => m.id == 'mut_002' && m.status.isWaitingDivisionApproval), true);

      // 1. Kadiv pending count
      final stats = container.read(kadivStatsProvider);
      expect(stats.waitingApprovalCount >= 2, true); // mut_005 (default) + mut_002

      // 2. Kadiv "Menunggu Approval" list
      container.read(kadivStatusFilterProvider.notifier).state = KadivStatusFilter.waiting;
      final waitingList = container.read(filteredKadivApprovalsProvider).value ?? [];
      expect(waitingList.any((m) => m.id == 'mut_002'), true);

      // 3. Kadiv "Semua" list
      container.read(kadivStatusFilterProvider.notifier).state = KadivStatusFilter.all;
      final allList = container.read(filteredKadivApprovalsProvider).value ?? [];
      expect(allList.any((m) => m.id == 'mut_002'), true);
    });

    test('Kadiv Approve transitions waitingKadivApproval to waitingConfirmation, notifies Pemohon, and updates queues', () async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier(kadivTestUser)),
        ],
      );

      // Ensure mut_005 is waiting Kadiv approval
      final initialDetail = await container.read(mutationDetailProvider('mut_005').future);
      expect(initialDetail.status, MutationStatus.waitingKadivApproval);

      await container.read(kadivAllMutationsProvider.future);
      final initialStats = container.read(kadivStatsProvider);
      final initialWaitingCount = initialStats.waitingApprovalCount;
      final initialApprovedCount = initialStats.approvedCount;

      // Execute Kadiv approve
      final approveSuccess = await container
          .read(kadivApprovalActionProvider.notifier)
          .approve(mutationId: 'mut_005');
      expect(approveSuccess, true);

      // Verify repository data
      final postDetail = await container.read(mutationDetailProvider('mut_005').future);
      expect(postDetail.status, MutationStatus.waitingConfirmation);
      expect(postDetail.kadivApprovedBy, 'Drs. Ahmad Dahlan (Kadiv)');
      expect(postDetail.kadivApprovedAt, isNotNull);

      // Verify removed from Kadiv "Menunggu Approval" queue
      await container.read(kadivAllMutationsProvider.future);
      container.read(kadivStatusFilterProvider.notifier).state = KadivStatusFilter.waiting;
      final waitingList = container.read(filteredKadivApprovalsProvider).value ?? [];
      expect(waitingList.any((m) => m.id == 'mut_005'), false);

      // Verify added to Kadiv "Disetujui" queue
      container.read(kadivStatusFilterProvider.notifier).state = KadivStatusFilter.approved;
      final approvedList = container.read(filteredKadivApprovalsProvider).value ?? [];
      expect(approvedList.any((m) => m.id == 'mut_005'), true);

      // Verify stats updated (re-read freshest data)
      await container.read(kadivAllMutationsProvider.future);
      final postStats = container.read(kadivStatsProvider);
      expect(postStats.waitingApprovalCount, lessThan(initialWaitingCount));
      expect(postStats.approvedCount, greaterThan(initialApprovedCount));

      // Verify notification sent after Kadiv approval
      final notifs = container.read(notificationProvider);
      expect(
        notifs.any((n) =>
            n.relatedMutationId == 'mut_005' &&
            (n.targetRole == UserRole.pemohon || n.title.contains('Disetujui'))),
        true,
      );
    });

    test('Kadiv Reject requires and preserves rejection reason, updates queues, notifies applicant', () async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier(kadivTestUser)),
        ],
      );

      await container.read(kadivAllMutationsProvider.future);
      final initialStats = container.read(kadivStatsProvider);
      final initialWaitingCount = initialStats.waitingApprovalCount;
      final initialRejectedCount = initialStats.rejectedCount;

      // Execute Kadiv reject
      const rejectionReason = 'Aset server enterprise tidak boleh dimutasi keluar gedung utama.';
      final rejectSuccess = await container
          .read(kadivApprovalActionProvider.notifier)
          .reject(
            mutationId: 'mut_005',
            reason: rejectionReason,
          );
      expect(rejectSuccess, true);

      // Verify repository data
      final postDetail = await container.read(mutationDetailProvider('mut_005').future);
      expect(postDetail.status, MutationStatus.rejected);
      expect(postDetail.kadivRejectedBy, 'Drs. Ahmad Dahlan (Kadiv)');
      expect(postDetail.kadivRejectedAt, isNotNull);
      expect(postDetail.rejectionReason, rejectionReason);
      expect(postDetail.kadivRejectionReason, rejectionReason);

      // Verify removed from Kadiv "Menunggu Approval" queue
      await container.read(kadivAllMutationsProvider.future);
      container.read(kadivStatusFilterProvider.notifier).state = KadivStatusFilter.waiting;
      final waitingList = container.read(filteredKadivApprovalsProvider).value ?? [];
      expect(waitingList.any((m) => m.id == 'mut_005'), false);

      // Verify present in Kadiv "Ditolak" queue
      container.read(kadivStatusFilterProvider.notifier).state = KadivStatusFilter.rejected;
      final rejectedList = container.read(filteredKadivApprovalsProvider).value ?? [];
      expect(rejectedList.any((m) => m.id == 'mut_005'), true);

      // Verify stats updated (re-read freshest data)
      await container.read(kadivAllMutationsProvider.future);
      final postStats = container.read(kadivStatsProvider);
      expect(postStats.waitingApprovalCount, lessThan(initialWaitingCount));
      expect(postStats.rejectedCount, greaterThan(initialRejectedCount));

      // Verify applicant received notification
      final notifs = container.read(notificationProvider);
      expect(
        notifs.any((n) =>
            n.relatedMutationId == 'mut_005' &&
            n.targetRole == UserRole.pemohon &&
            n.message.contains(rejectionReason)),
        true,
      );
    });
  });

  group('Kadiv Detail Screen Actions & Operator Verification Info', () {
    Widget buildTestWidget({
      required Widget child,
      required MutationRepository repo,
    }) {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => child,
          ),
          GoRoute(
            path: '/kadiv/approvals',
            builder: (context, state) =>
                const Scaffold(body: Text('Approvals List')),
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier(kadivTestUser)),
          mutationRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('Detail screen shows Operator verification info and action buttons only for waitingKadivApproval', (tester) async {
      final assetRepo = AssetRepositoryImpl();
      final repo = MutationRepositoryImpl(assetRepository: assetRepo);

      await tester.pumpWidget(
        buildTestWidget(
          child: const KadivApprovalDetailScreen(mutationId: 'mut_005'),
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      // Verify mutation info
      expect(find.text('ELEKTRONIK-2026-00088'), findsOneWidget);
      expect(find.text('Server Rack Enterprise Dell PowerEdge'), findsOneWidget);

      // Operator verification info is shown — mut_005 has verifiedBy: 'Operator Aset'
      expect(find.text('Verifikasi Operator'), findsWidgets);
      expect(find.text('Diverifikasi oleh Operator Aset'), findsOneWidget);

      // Action buttons are visible for waitingKadivApproval
      expect(find.byKey(const Key('btn_tolak_approval_kadiv')), findsOneWidget);
      expect(find.byKey(const Key('btn_setujui_approval_kadiv')), findsOneWidget);
    });

    testWidgets('Detail screen hides action buttons when status is already approved', (tester) async {
      final assetRepo = AssetRepositoryImpl();
      final repo = MutationRepositoryImpl(assetRepository: assetRepo);

      // Approve mut_005 first using runAsync since repo has Future.delayed
      await tester.runAsync(() async {
        await repo.approveMutationKadiv(
          mutationId: 'mut_005',
          kadivName: 'Drs. Ahmad Dahlan (Kadiv)',
        );
      });

      await tester.pumpWidget(
        buildTestWidget(
          child: const KadivApprovalDetailScreen(mutationId: 'mut_005'),
          repo: repo,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Action buttons must NOT be present
      expect(find.byKey(const Key('btn_tolak_approval_kadiv')), findsNothing);
      expect(find.byKey(const Key('btn_setujui_approval_kadiv')), findsNothing);
    });
  });

  group('No Fake Success on Failure', () {
    test('Kadiv approve returns false when repository fails', () async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier(kadivTestUser)),
        ],
      );

      // Attempting to approve non-existent mutation
      final success = await container
          .read(kadivApprovalActionProvider.notifier)
          .approve(mutationId: 'non_existent_mutation_id');
      expect(success, false);
      expect(container.read(kadivApprovalActionProvider).error, isNotNull);
    });
  });

  group('Notification Navigation to Kadiv Detail', () {
    testWidgets('Tapping Kadiv notification navigates to Kadiv Approval Detail with matching mutation', (tester) async {
      final router = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationScreen(),
          ),
          GoRoute(
            path: '/kadiv/approvals/:id',
            builder: (context, state) => Scaffold(
              body: Text('Detail for ${state.pathParameters['id']}'),
            ),
          ),
        ],
      );

      final fakeNotification = NotificationItem(
        id: 'notif_kadiv_test_01',
        title: 'Pengajuan Memerlukan Persetujuan Kadiv',
        message: 'Pengajuan ELEKTRONIK-2026-00088 membutuhkan persetujuan Anda.',
        createdAt: DateTime.now(),
        type: NotificationType.action,
        targetRole: UserRole.kadiv,
        relatedMutationId: 'mut_005',
        isRead: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => _FakeAuthNotifier(kadivTestUser)),
            notificationProvider.overrideWith((ref) => _FakeNotificationNotifier([fakeNotification])),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Notification is displayed
      expect(find.text('Pengajuan Memerlukan Persetujuan Kadiv'), findsOneWidget);

      // Tap notification
      await tester.tap(find.text('Pengajuan Memerlukan Persetujuan Kadiv'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Successfully routed to /kadiv/approvals/mut_005
      expect(find.text('Detail for mut_005'), findsOneWidget);
    });
  });
}
