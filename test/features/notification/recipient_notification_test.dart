// test/features/notification/recipient_notification_test.dart
//
// Test suite wajib untuk sistem notifikasi berbasis penerima (Recipient Filtering):
// 1. Login sebagai Pemohon → hanya notification Pemohon
// 2. Login sebagai Operator → hanya notification Operator
// 3. Login sebagai Kabag → hanya notification Kabag
// 4. Login sebagai Kadiv → hanya notification Kadiv
// 5. Login sebagai Staff Aset → hanya notification Staff Aset
// 6. Login sebagai Admin → hanya notification Admin jika ada
// 7. Notification user A tidak muncul pada user B dengan role yang sama
// 8. Badge unread setiap user independen
// 9. markAllAsRead tidak mengubah notification user lain
// 10. Klik notification membuka mutation yang benar

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mutasiku/app/router/route_names.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/auth/domain/repositories/auth_repository.dart';
import 'package:mutasiku/features/auth/domain/usecases/login_usecase.dart';
import 'package:mutasiku/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';
import 'package:mutasiku/features/notification/domain/entities/notification_item.dart';
import 'package:mutasiku/features/notification/presentation/providers/notification_provider.dart';
import 'package:mutasiku/features/notification/presentation/screens/notification_screen.dart';
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
  const pemohonA = User(
    id: 'usr_pemohon_a',
    username: 'pemohonA',
    name: 'Pemohon A',
    email: 'pemohonA@mutasiku.id',
    role: UserRole.pemohon,
  );

  const pemohonB = User(
    id: 'usr_pemohon_b',
    username: 'pemohonB',
    name: 'Pemohon B',
    email: 'pemohonB@mutasiku.id',
    role: UserRole.pemohon,
  );

  const operator1 = User(
    id: 'u_opr_01',
    username: 'operator1',
    name: 'Siti Operator',
    email: 'operator@mutasiku.id',
    role: UserRole.operator,
  );

  const operator2 = User(
    id: 'u_opr_02',
    username: 'operator2',
    name: 'Asep Operator',
    email: 'operator2@mutasiku.id',
    role: UserRole.operator,
  );

  const kabagUser = User(
    id: 'u_kbg_01',
    username: 'kabag1',
    name: 'Bambang Kabag',
    email: 'kabag@mutasiku.id',
    role: UserRole.kabagAset,
  );

  const kadivUser = User(
    id: 'u_kdv_01',
    username: 'kadiv1',
    name: 'Hendra Kadiv',
    email: 'kadiv@mutasiku.id',
    role: UserRole.kadiv,
  );

  const staffUser = User(
    id: 'u_stf_01',
    username: 'staff1',
    name: 'Agus Staff',
    email: 'staff@mutasiku.id',
    role: UserRole.staffAset,
  );

  const adminUser = User(
    id: 'u_adm_01',
    username: 'admin1',
    name: 'Super Admin',
    email: 'admin@mutasiku.id',
    role: UserRole.admin,
  );

  group('Recipient Notification Tests (1 - 6: Role Filtering)', () {
    test('1. Login sebagai Pemohon → hanya notification Pemohon', () {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier(pemohonA)),
        ],
      );
      addTearDown(container.dispose);

      // Tambahkan notifikasi personal pemohonA
      container.read(notificationProvider.notifier).notifyUser(
            targetUserId: pemohonA.id,
            targetRole: UserRole.pemohon,
            title: 'Notif Khusus Pemohon A',
            message: 'Status mutasi Anda',
            type: NotificationType.info,
          );

      final notifs = container.read(roleNotificationsProvider);
      expect(notifs.isNotEmpty, isTrue);
      for (final n in notifs) {
        expect(
          n.targetRole == UserRole.pemohon || n.targetUserId == pemohonA.id,
          isTrue,
        );
        expect(n.targetRole != UserRole.operator, isTrue);
        expect(n.targetRole != UserRole.kabagAset, isTrue);
        expect(n.targetRole != UserRole.kadiv, isTrue);
        expect(n.targetRole != UserRole.staffAset, isTrue);
        expect(n.targetRole != UserRole.admin, isTrue);
      }
    });

    test('2. Login sebagai Operator → hanya notification Operator', () {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier(operator1)),
        ],
      );
      addTearDown(container.dispose);

      final notifs = container.read(roleNotificationsProvider);
      expect(notifs.isNotEmpty, isTrue);
      for (final n in notifs) {
        expect(n.targetRole, equals(UserRole.operator));
      }
    });

    test('3. Login sebagai Kabag → hanya notification Kabag', () {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier(kabagUser)),
        ],
      );
      addTearDown(container.dispose);

      final notifs = container.read(roleNotificationsProvider);
      expect(notifs.isNotEmpty, isTrue);
      for (final n in notifs) {
        expect(n.targetRole, equals(UserRole.kabagAset));
      }
    });

    test('4. Login sebagai Kadiv → hanya notification Kadiv', () {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier(kadivUser)),
        ],
      );
      addTearDown(container.dispose);

      final notifs = container.read(roleNotificationsProvider);
      expect(notifs.isNotEmpty, isTrue);
      for (final n in notifs) {
        expect(n.targetRole, equals(UserRole.kadiv));
      }
    });

    test('5. Login sebagai Staff Aset → hanya notification Staff Aset', () {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier(staffUser)),
        ],
      );
      addTearDown(container.dispose);

      final notifs = container.read(roleNotificationsProvider);
      expect(notifs.isNotEmpty, isTrue);
      for (final n in notifs) {
        expect(n.targetRole, equals(UserRole.staffAset));
      }
    });

    test('6. Login sebagai Admin → hanya notification Admin jika ada', () {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier(adminUser)),
        ],
      );
      addTearDown(container.dispose);

      final notifs = container.read(roleNotificationsProvider);
      expect(notifs.isNotEmpty, isTrue);
      for (final n in notifs) {
        expect(n.targetRole, equals(UserRole.admin));
      }
    });
  });

  group('Recipient Notification Tests (7 - 9: User Isolation & Read Tracking)', () {
    test('7. Notification user A tidak muncul pada user B dengan role yang sama', () {
      final notifier = NotificationNotifier();
      final now = DateTime.now();

      // Buat notifikasi khusus untuk Pemohon A
      final notifA = NotificationItem(
        id: 'notif_khusus_pemohon_a',
        title: 'Rahasia Pemohon A',
        message: 'Pengajuan mutasi rahasia milik A',
        type: NotificationType.info,
        createdAt: now,
        targetRole: UserRole.pemohon,
        targetUserId: pemohonA.id,
      );

      // Buat notifikasi khusus untuk Pemohon B
      final notifB = NotificationItem(
        id: 'notif_khusus_pemohon_b',
        title: 'Rahasia Pemohon B',
        message: 'Pengajuan mutasi rahasia milik B',
        type: NotificationType.info,
        createdAt: now,
        targetRole: UserRole.pemohon,
        targetUserId: pemohonB.id,
      );

      notifier.addNotification(notifA);
      notifier.addNotification(notifB);

      // Verifikasi visibilitas Pemohon A
      expect(isNotificationVisibleToUser(notifA, pemohonA), isTrue);
      expect(isNotificationVisibleToUser(notifB, pemohonA), isFalse);

      // Verifikasi visibilitas Pemohon B
      expect(isNotificationVisibleToUser(notifA, pemohonB), isFalse);
      expect(isNotificationVisibleToUser(notifB, pemohonB), isTrue);
    });

    test('8. Badge unread setiap user independen', () {
      final authNotifier = _FakeAuthNotifier(operator1);
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => authNotifier),
        ],
      );
      addTearDown(container.dispose);

      // Ambil initial unread count untuk operator1
      final initialCount = container.read(unreadNotificationCountProvider);
      expect(initialCount, greaterThan(0));

      // Operator 1 membaca 1 notifikasi
      final firstOprNotif = container.read(roleNotificationsProvider).first;
      container.read(notificationProvider.notifier).markAsRead(
            firstOprNotif.id,
            userId: operator1.id,
          );

      // Unread count operator1 berkurang 1
      final newCountOpr1 = container.read(unreadNotificationCountProvider);
      expect(newCountOpr1, equals(initialCount - 1));

      // Switch auth state ke operator 2
      authNotifier.state = AuthState(isLoading: false, user: operator2);

      // Unread count operator 2 TETAP intak (independen)
      final countOpr2 = container.read(unreadNotificationCountProvider);
      expect(countOpr2, equals(initialCount));
    });

    test('9. markAllAsRead tidak mengubah notification user lain', () {
      final notifier = NotificationNotifier();
      final now = DateTime.now();

      // Tambahkan notifikasi role broadcast untuk Operator
      notifier.addNotification(
        NotificationItem(
          id: 'notif_opr_broadcast',
          title: 'Pengumuman Operator',
          message: 'Pembaruan prosedur verifikasi',
          type: NotificationType.info,
          createdAt: now,
          targetRole: UserRole.operator,
        ),
      );

      // Operator 1 mark all as read
      notifier.markAllAsRead(
        role: UserRole.operator,
        userId: operator1.id,
      );

      final state = notifier.state;
      final targetItem = state.firstWhere((n) => n.id == 'notif_opr_broadcast');

      // Operator 1 sudah membaca
      expect(targetItem.isReadBy(operator1.id), isTrue);

      // Operator 2 BELUM membaca (tidak terpengaruh)
      expect(targetItem.isReadBy(operator2.id), isFalse);
    });
  });

  group('Recipient Notification Tests (10: Navigation Deep Linking)', () {
    testWidgets('10. Klik notification di NotificationScreen membuka mutation yang benar',
        (tester) async {
      String? openedRoute;
      final router = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationScreen(),
          ),
          GoRoute(
            path: '/operator/mutations/:id',
            builder: (context, state) {
              openedRoute = state.matchedLocation;
              return Scaffold(body: Text('Detail ${state.pathParameters['id']}'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => _FakeAuthNotifier(operator1)),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap notification pertama
      await tester.tap(find.textContaining('FURNITUR-2026-00018').first);
      await tester.pumpAndSettle();

      expect(openedRoute, equals('/operator/mutations/mut_004'));
      expect(find.text('Detail mut_004'), findsOneWidget);
    });

    testWidgets('10. Klik notification di PemohonNotificationsScreen membuka mutation yang benar',
        (tester) async {
      String? openedRoute;
      final router = GoRouter(
        initialLocation: '/pemohon/notifications',
        routes: [
          GoRoute(
            path: '/pemohon/notifications',
            builder: (context, state) => const PemohonNotificationsScreen(),
          ),
          GoRoute(
            path: RouteNames.pemohonMutasiDetailPath,
            builder: (context, state) {
              openedRoute = state.matchedLocation;
              return Scaffold(body: Text('Pemohon Detail ${state.pathParameters['id']}'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => _FakeAuthNotifier(pemohonA)),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tambahkan notif pemohonA
      final container = ProviderScope.containerOf(tester.element(find.byType(PemohonNotificationsScreen)));
      container.read(notificationProvider.notifier).notifyUser(
            targetUserId: pemohonA.id,
            targetRole: UserRole.pemohon,
            title: 'Notif Mutasi Anda',
            message: 'Mutasi mut_007 telah diupdate',
            type: NotificationType.action,
            relatedMutationId: 'mut_007',
          );
      await tester.pumpAndSettle();

      // Tap notifikasi Pemohon A
      await tester.tap(find.text('Notif Mutasi Anda'));
      await tester.pumpAndSettle();

      expect(openedRoute, equals('/pemohon/mutasi/mut_007'));
      expect(find.text('Pemohon Detail mut_007'), findsOneWidget);
    });
  });
}
