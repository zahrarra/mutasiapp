import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mutasiku/app/router/route_names.dart';
import 'package:mutasiku/features/notification/presentation/providers/notification_provider.dart';
import 'package:mutasiku/features/notification/presentation/widgets/notification_tile.dart';
import 'package:mutasiku/features/pemohon/presentation/screens/pemohon_notifications_screen.dart';

void main() {
  group('PemohonNotificationsScreen Tests', () {
    testWidgets('renders notifications list and notification tiles',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PemohonNotificationsScreen(),
          ),
        ),
      );

      // Verify AppBar title (and bottom nav item)
      expect(find.text('Notifikasi'), findsWidgets);

      // Verify notification tiles exist
      expect(find.byType(NotificationTile), findsWidgets);

      // Verify action to mark all as read
      expect(find.text('Tandai semua dibaca'), findsOneWidget);

      // Verify "Kembali" back button exists
      expect(find.byTooltip('Kembali'), findsOneWidget);
    });

    testWidgets('tapping notification marks it as read', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const PemohonNotificationsScreen(),
          ),
          GoRoute(
            path: RouteNames.pemohonMutasiDetailPath,
            builder: (context, state) => const Scaffold(),
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

      // Before clicking, notif_1 is unread
      final initialNotifs = container.read(notificationProvider);
      expect(initialNotifs.firstWhere((n) => n.id == 'notif_1').isRead, isFalse);

      // Tap first tile
      await tester.tap(find.text('Pengajuan Diverifikasi'));
      await tester.pumpAndSettle();

      // After clicking, notif_1 is marked as read
      final updatedNotifs = container.read(notificationProvider);
      expect(updatedNotifs.firstWhere((n) => n.id == 'notif_1').isRead, isTrue);
    });

    testWidgets(
        'tapping notification with relatedMutationId triggers navigation to mutation detail',
        (tester) async {
      String? navigatedLocation;

      final router = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const PemohonNotificationsScreen(),
          ),
          GoRoute(
            path: RouteNames.pemohonMutasiDetailPath,
            builder: (context, state) {
              navigatedLocation = state.matchedLocation;
              return const Scaffold(body: Text('Detail Screen'));
            },
          ),
          GoRoute(
            path: RouteNames.pemohonDashboardPath,
            builder: (context, state) {
              navigatedLocation = state.matchedLocation;
              return const Scaffold(body: Text('Dashboard Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Tap notification that has relatedMutationId: 'mut_004'
      await tester.tap(find.text('Pengajuan Diverifikasi'));
      await tester.pumpAndSettle();

      expect(navigatedLocation, '/pemohon/mutasi/mut_004');
    });

    testWidgets('tapping Kembali ke Dashboard navigates to dashboard route',
        (tester) async {
      String? navigatedLocation;

      final router = GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const PemohonNotificationsScreen(),
          ),
          GoRoute(
            path: RouteNames.pemohonDashboardPath,
            builder: (context, state) {
              navigatedLocation = state.matchedLocation;
              return const Scaffold(body: Text('Dashboard Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Tap Back button in AppBar
      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();

      expect(navigatedLocation, RouteNames.pemohonDashboardPath);
    });

    testWidgets('shows empty state when notifications list is empty',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationProvider.overrideWith(
              (ref) => _EmptyNotificationNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: PemohonNotificationsScreen(),
          ),
        ),
      );

      expect(find.text('Belum ada notifikasi.'), findsOneWidget);
      expect(find.byType(NotificationTile), findsNothing);
      expect(find.text('Tandai semua dibaca'), findsNothing);
      expect(find.byTooltip('Kembali'), findsOneWidget);
    });
  });
}

class _EmptyNotificationNotifier extends NotificationNotifier {
  _EmptyNotificationNotifier() {
    state = [];
  }
}
