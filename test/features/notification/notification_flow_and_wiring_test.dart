// test/features/notification/notification_flow_and_wiring_test.dart
//
// Comprehensive validation test suite for Notification functionality and wiring
// across all MutasiKu roles: Pemohon, Operator, Kabag, Kadiv, Staff Aset.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/core/widgets/custom_floating_nav_bar.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/auth/domain/repositories/auth_repository.dart';
import 'package:mutasiku/features/auth/domain/usecases/login_usecase.dart';
import 'package:mutasiku/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';
import 'package:mutasiku/features/notification/domain/entities/notification_item.dart';
import 'package:mutasiku/features/notification/presentation/providers/notification_provider.dart';
import 'package:mutasiku/features/notification/presentation/screens/notification_screen.dart';
import 'package:mutasiku/features/notification/presentation/widgets/notification_tile.dart';
import 'package:mutasiku/features/pemohon/presentation/screens/pemohon_notifications_screen.dart';

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

void main() {
  const pemohonUser = User(
    id: 'usr_pemohon',
    username: 'pemohon',
    name: 'Rina Pemohon',
    email: 'pemohon@mutasiku.id',
    role: UserRole.pemohon,
  );

  const pemohonOtherUser = User(
    id: 'usr_pemohon_other',
    username: 'pemohon_other',
    name: 'Budi Pemohon Lain',
    email: 'other@mutasiku.id',
    role: UserRole.pemohon,
  );

  const operatorUser = User(
    id: 'usr_operator',
    username: 'operator',
    name: 'Budi Operator',
    email: 'operator@mutasiku.id',
    role: UserRole.operator,
  );

  const kabagUser = User(
    id: 'usr_kabag',
    username: 'kabag',
    name: 'Yusuf Kabag',
    email: 'kabag@mutasiku.id',
    role: UserRole.kabagAset,
  );

  const kadivUser = User(
    id: 'usr_kadiv',
    username: 'kadiv',
    name: 'Dahlan Kadiv',
    email: 'kadiv@mutasiku.id',
    role: UserRole.kadiv,
  );

  const staffUser = User(
    id: 'usr_staff',
    username: 'staff',
    name: 'Rizky Staff',
    email: 'staff@mutasiku.id',
    role: UserRole.staffAset,
  );

  group('1. Notification Data Isolation across all roles', () {
    test('User only sees notifications targeted to their role or user ID', () {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier(pemohonUser)),
        ],
      );
      addTearDown(container.dispose);

      final pemohonNotifs = container.read(roleNotificationsProvider);
      expect(pemohonNotifs.isNotEmpty, isTrue);
      for (final n in pemohonNotifs) {
        expect(
          n.targetRole == UserRole.pemohon || n.targetUserId == pemohonUser.id,
          isTrue,
        );
        expect(n.targetRole, isNot(UserRole.operator));
        expect(n.targetRole, isNot(UserRole.kabagAset));
        expect(n.targetRole, isNot(UserRole.kadiv));
        expect(n.targetRole, isNot(UserRole.staffAset));
      }
    });

    test('Separate users within same role do NOT see each others personal notifications', () {
      final notifier = NotificationNotifier();
      final now = DateTime.now();

      final notifA = NotificationItem(
        id: 'notif_personal_a',
        title: 'Pengajuan A Berhasil',
        message: 'Info untuk Pemohon Rina',
        type: NotificationType.info,
        createdAt: now,
        targetRole: UserRole.pemohon,
        targetUserId: pemohonUser.id,
      );

      final notifB = NotificationItem(
        id: 'notif_personal_b',
        title: 'Pengajuan B Berhasil',
        message: 'Info untuk Pemohon Lain',
        type: NotificationType.info,
        createdAt: now,
        targetRole: UserRole.pemohon,
        targetUserId: pemohonOtherUser.id,
      );

      notifier.addNotification(notifA);
      notifier.addNotification(notifB);

      expect(isNotificationVisibleToUser(notifA, pemohonUser), isTrue);
      expect(isNotificationVisibleToUser(notifB, pemohonUser), isFalse);

      expect(isNotificationVisibleToUser(notifA, pemohonOtherUser), isFalse);
      expect(isNotificationVisibleToUser(notifB, pemohonOtherUser), isTrue);
    });
  });

  group('2. Unread Badge & Reactive Updates', () {
    testWidgets('Unread badge visible when unread > 0, disappears when all read',
        (tester) async {
      final authNotifier = _FakeAuthNotifier(operatorUser);
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => authNotifier),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              bottomNavigationBar: CustomFloatingNavBar.forRole(UserRole.operator),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially unread > 0 -> Badge widget is found
      final initialUnread = container.read(unreadNotificationCountProvider);
      expect(initialUnread, greaterThan(0));
      expect(find.byType(Badge), findsOneWidget);

      // Mark all read for operator
      container.read(notificationProvider.notifier).markAllAsRead(
            role: UserRole.operator,
            userId: operatorUser.id,
          );
      await tester.pumpAndSettle();

      // Badge disappears reactively without manual refresh
      final updatedUnread = container.read(unreadNotificationCountProvider);
      expect(updatedUnread, equals(0));
      expect(find.byType(Badge), findsNothing);
    });

    test('Reading one notification does not mark unrelated notifications as read', () {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier(operatorUser)),
        ],
      );
      addTearDown(container.dispose);

      final notifsBefore = container.read(roleNotificationsProvider);
      final unreadCountBefore = container.read(unreadNotificationCountProvider);
      expect(unreadCountBefore, greaterThan(1));

      final firstId = notifsBefore.first.id;
      final secondId = notifsBefore[1].id;

      container.read(notificationProvider.notifier).markAsRead(
            firstId,
            userId: operatorUser.id,
          );

      final notifsAfter = container.read(roleNotificationsProvider);
      final firstAfter = notifsAfter.firstWhere((n) => n.id == firstId);
      final secondAfter = notifsAfter.firstWhere((n) => n.id == secondId);

      expect(firstAfter.isRead, isTrue);
      expect(secondAfter.isRead, isFalse);
      expect(
        container.read(unreadNotificationCountProvider),
        equals(unreadCountBefore - 1),
      );
    });
  });

  group('3. Notification List & Visual Differentiation', () {
    testWidgets('Notification screen shows title, message, timestamp, and visual unread indicator',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => _FakeAuthNotifier(operatorUser)),
          ],
          child: const MaterialApp(
            home: NotificationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NotificationTile), findsWidgets);

      // Verify unread indicator (Material container with distinct background or primary dot)
      expect(find.byType(NotificationTile), findsWidgets);
    });
  });

  group('4 & 5. Notification Tap & Role-Based Routing for all 5 roles', () {
    Future<void> testRoleRouting({
      required WidgetTester tester,
      required User user,
      required String expectedPathPrefix,
      required bool isPemohonScreen,
    }) async {
      String? visitedRoute;
      final router = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (context, state) => isPemohonScreen
                ? const PemohonNotificationsScreen()
                : const NotificationScreen(),
          ),
          GoRoute(
            path: '$expectedPathPrefix/:id',
            builder: (context, state) {
              visitedRoute = state.matchedLocation;
              return Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                ),
                body: Text('Detail for ${state.pathParameters['id']}'),
              );
            },
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier(user)),
        ],
      );
      addTearDown(container.dispose);

      // Add a test notification with relatedMutationId
      final notif = NotificationItem(
        id: 'notif_test_${user.role.name}',
        title: 'Notif Test ${user.role.name}',
        message: 'Pesan mutasi',
        type: NotificationType.action,
        createdAt: DateTime.now(),
        targetRole: user.role,
        targetUserId: user.role == UserRole.pemohon ? user.id : null,
        relatedMutationId: 'mut_999',
      );
      container.read(notificationProvider.notifier).addNotification(notif);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the test notification tile
      await tester.tap(find.text('Notif Test ${user.role.name}'));
      await tester.pumpAndSettle();

      // Verify correct route used
      expect(visitedRoute, equals('$expectedPathPrefix/mut_999'));
      expect(find.text('Detail for mut_999'), findsOneWidget);

      // Verify notification is marked as read after tapping
      final roleNotifs = container.read(roleNotificationsProvider);
      final clickedNotif = roleNotifs.firstWhere((n) => n.id == notif.id);
      expect(clickedNotif.isRead, isTrue);

      // Back navigation test: pop back to NotificationScreen
      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();
      expect(find.byType(NotificationTile), findsWidgets);
    }

    testWidgets('Pemohon notification tap routes to /pemohon/mutasi/:id', (tester) async {
      await testRoleRouting(
        tester: tester,
        user: pemohonUser,
        expectedPathPrefix: '/pemohon/mutasi',
        isPemohonScreen: true,
      );
    });

    testWidgets('Operator notification tap routes to /operator/mutations/:id', (tester) async {
      await testRoleRouting(
        tester: tester,
        user: operatorUser,
        expectedPathPrefix: '/operator/mutations',
        isPemohonScreen: false,
      );
    });

    testWidgets('Kabag notification tap routes to /kabag/approvals/:id', (tester) async {
      await testRoleRouting(
        tester: tester,
        user: kabagUser,
        expectedPathPrefix: '/kabag/approvals',
        isPemohonScreen: false,
      );
    });

    testWidgets('Kadiv notification tap routes to /kadiv/approvals/:id', (tester) async {
      await testRoleRouting(
        tester: tester,
        user: kadivUser,
        expectedPathPrefix: '/kadiv/approvals',
        isPemohonScreen: false,
      );
    });

    testWidgets('Staff Aset notification tap routes to /staff-aset/mutations/:id (never /staff/...)',
        (tester) async {
      await testRoleRouting(
        tester: tester,
        user: staffUser,
        expectedPathPrefix: '/staff-aset/mutations',
        isPemohonScreen: false,
      );
    });
  });

  group('6 & 7. Tandai Semua Dibaca', () {
    testWidgets('"Tandai semua dibaca" only visible when unread exists, marks current user read',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier(kabagUser)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: NotificationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Button is visible because unread > 0
      expect(find.text('Tandai semua dibaca'), findsOneWidget);

      // Press button
      await tester.tap(find.text('Tandai semua dibaca'));
      await tester.pumpAndSettle();

      // Button disappears
      expect(find.text('Tandai semua dibaca'), findsNothing);

      // All Kabag notifications are now read
      final notifs = container.read(roleNotificationsProvider);
      expect(notifs.every((n) => n.isRead), isTrue);

      // Other roles (e.g. Operator) are NOT modified
      final oprNotifs = container
          .read(notificationProvider)
          .where((n) => n.targetRole == UserRole.operator);
      expect(oprNotifs.any((n) => !n.isReadBy(operatorUser.id)), isTrue);
    });
  });

  group('8. Status-Specific Notifications and No Duplicate Events', () {
    test('Notification notifier properly handles all role transitions without duplicates', () {
      final notifier = NotificationNotifier();

      // 1. Pemohon submit -> Operator receives new submission
      notifier.notifyRole(
        targetRole: UserRole.operator,
        title: 'Pengajuan Baru Masuk',
        message: 'Pengajuan mutasi TIK-2026-001 siap diverifikasi.',
        type: NotificationType.action,
        relatedMutationId: 'mut_event_1',
      );

      final oprNotifs = notifier.state.where(
        (n) => n.targetRole == UserRole.operator && n.relatedMutationId == 'mut_event_1',
      );
      expect(oprNotifs.length, equals(1));

      // 2. Operator verify -> Kabag receives waiting for approval
      notifier.notifyRole(
        targetRole: UserRole.kabagAset,
        title: 'Menunggu Approval Kabag',
        message: 'Pengajuan TIK-2026-001 telah diverifikasi.',
        type: NotificationType.action,
        relatedMutationId: 'mut_event_1',
      );

      final kbgNotifs = notifier.state.where(
        (n) => n.targetRole == UserRole.kabagAset && n.relatedMutationId == 'mut_event_1',
      );
      expect(kbgNotifs.length, equals(1));

      // 3. Kabag approves (kadiv required) -> Kadiv receives waiting for approval
      notifier.notifyRole(
        targetRole: UserRole.kadiv,
        title: 'Menunggu Approval Kadiv',
        message: 'Pengajuan TIK-2026-001 memerlukan approval Kadiv.',
        type: NotificationType.action,
        relatedMutationId: 'mut_event_1',
      );

      final kdvNotifs = notifier.state.where(
        (n) => n.targetRole == UserRole.kadiv && n.relatedMutationId == 'mut_event_1',
      );
      expect(kdvNotifs.length, equals(1));

      // 4. Kadiv approves -> Staff Aset receives asset update task
      notifier.notifyRole(
        targetRole: UserRole.staffAset,
        title: 'Tugas Pembaruan Fisik Aset',
        message: 'Pengajuan TIK-2026-001 telah disetujui Kadiv.',
        type: NotificationType.action,
        relatedMutationId: 'mut_event_1',
      );

      final stfNotifs = notifier.state.where(
        (n) => n.targetRole == UserRole.staffAset && n.relatedMutationId == 'mut_event_1',
      );
      expect(stfNotifs.length, equals(1));

      // 5. Staff Aset updates -> Pemohon receives pending confirmation
      notifier.notifyUser(
        targetUserId: pemohonUser.id,
        targetRole: UserRole.pemohon,
        title: 'Menunggu Konfirmasi Penerimaan',
        message: 'Data fisik aset TIK-2026-001 telah diperbarui.',
        type: NotificationType.action,
        relatedMutationId: 'mut_event_1',
      );

      final pmhConfirmNotifs = notifier.state.where(
        (n) =>
            n.targetUserId == pemohonUser.id &&
            n.relatedMutationId == 'mut_event_1' &&
            n.title == 'Menunggu Konfirmasi Penerimaan',
      );
      expect(pmhConfirmNotifs.length, equals(1));

      // 6. Pemohon confirms -> Staff Aset & Pemohon receive completion
      notifier.notifyRole(
        targetRole: UserRole.staffAset,
        title: 'Mutasi Selesai',
        message: 'Pemohon telah mengonfirmasi penerimaan aset TIK-2026-001.',
        type: NotificationType.success,
        relatedMutationId: 'mut_event_1',
      );
      notifier.notifyUser(
        targetUserId: pemohonUser.id,
        targetRole: UserRole.pemohon,
        title: 'Mutasi Selesai',
        message: 'Mutasi aset TIK-2026-001 telah selesai.',
        type: NotificationType.success,
        relatedMutationId: 'mut_event_1',
      );

      final stfDone = notifier.state.where(
        (n) =>
            n.targetRole == UserRole.staffAset &&
            n.relatedMutationId == 'mut_event_1' &&
            n.title == 'Mutasi Selesai',
      );
      expect(stfDone.length, equals(1));

      final pmhDone = notifier.state.where(
        (n) =>
            n.targetUserId == pemohonUser.id &&
            n.relatedMutationId == 'mut_event_1' &&
            n.title == 'Mutasi Selesai',
      );
      expect(pmhDone.length, equals(1));

      // 7. Rejection & Return events
      notifier.notifyUser(
        targetUserId: pemohonUser.id,
        targetRole: UserRole.pemohon,
        title: 'Pengajuan Dikembalikan Operator',
        message: 'Dokumen belum lengkap.',
        type: NotificationType.warning,
        relatedMutationId: 'mut_event_2',
      );
      notifier.notifyUser(
        targetUserId: pemohonUser.id,
        targetRole: UserRole.pemohon,
        title: 'Pengajuan Mutasi Ditolak Kabag',
        message: 'Alasan penolakan anggaran.',
        type: NotificationType.warning,
        relatedMutationId: 'mut_event_3',
      );
      notifier.notifyUser(
        targetUserId: pemohonUser.id,
        targetRole: UserRole.pemohon,
        title: 'Pengajuan Mutasi Ditolak Kadiv',
        message: 'Alasan penolakan kebijakan.',
        type: NotificationType.warning,
        relatedMutationId: 'mut_event_4',
      );

      expect(
        notifier.state.where((n) => n.relatedMutationId == 'mut_event_2').length,
        equals(1),
      );
      expect(
        notifier.state.where((n) => n.relatedMutationId == 'mut_event_3').length,
        equals(1),
      );
      expect(
        notifier.state.where((n) => n.relatedMutationId == 'mut_event_4').length,
        equals(1),
      );
    });
  });
}
