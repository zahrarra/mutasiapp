import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mutasiku/app/router/route_names.dart';
import 'package:mutasiku/core/widgets/custom_floating_nav_bar.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/notification/presentation/providers/notification_provider.dart';

void main() {
  group('RoleNavConfig Unit Tests', () {
    test('Pemohon configuration matches exact specification', () {
      final items = RoleNavConfig.getNavItemsForRole(UserRole.pemohon);
      expect(items.length, 4);

      expect(items[0].label, 'Beranda');
      expect(items[0].icon, Icons.home_outlined);
      expect(items[0].route, RouteNames.pemohonDashboardPath);

      expect(items[1].label, 'Mutasi Saya');
      expect(items[1].icon, Icons.swap_horiz_rounded);
      expect(items[1].route, RouteNames.pemohonMutasiPath);

      expect(items[2].label, 'Notifikasi');
      expect(items[2].icon, Icons.notifications_none_rounded);
      expect(items[2].route, RouteNames.pemohonNotificationsPath);

      expect(items[3].label, 'Profil');
      expect(items[3].icon, Icons.person_outline_rounded);
      expect(items[3].route, RouteNames.pemohonProfilePath);
    });

    test('Operator configuration matches exact specification', () {
      final items = RoleNavConfig.getNavItemsForRole(UserRole.operator);
      expect(items.length, 4);

      expect(items[0].label, 'Home');
      expect(items[0].icon, Icons.home_outlined);
      expect(items[0].route, RouteNames.operatorDashboardPath);

      expect(items[1].label, 'Pengajuan');
      expect(items[1].icon, Icons.fact_check_outlined);
      expect(items[1].route, RouteNames.operatorMutationsPath);

      expect(items[2].label, 'Notifikasi');
      expect(items[2].icon, Icons.notifications_none_rounded);
      expect(items[2].route, RouteNames.operatorNotificationsPath);

      expect(items[3].label, 'Profil');
      expect(items[3].icon, Icons.person_outline_rounded);
      expect(items[3].route, RouteNames.profilePath);
    });

    test('Kabag configuration matches exact specification', () {
      final items = RoleNavConfig.getNavItemsForRole(UserRole.kabagAset);
      expect(items.length, 4);

      expect(items[0].label, 'Home');
      expect(items[0].icon, Icons.home_outlined);
      expect(items[0].route, RouteNames.kabagDashboardPath);

      expect(items[1].label, 'Approval');
      expect(items[1].icon, Icons.assignment_ind_outlined);
      expect(items[1].route, RouteNames.kabagApprovalsPath);

      expect(items[2].label, 'Notifikasi');
      expect(items[2].icon, Icons.notifications_none_rounded);
      expect(items[2].route, RouteNames.kabagNotificationsPath);

      expect(items[3].label, 'Profil');
      expect(items[3].icon, Icons.person_outline_rounded);
      expect(items[3].route, RouteNames.profilePath);
    });

    test('Kadiv configuration matches exact specification', () {
      final items = RoleNavConfig.getNavItemsForRole(UserRole.kadiv);
      expect(items.length, 4);

      expect(items[0].label, 'Home');
      expect(items[0].icon, Icons.home_outlined);
      expect(items[0].route, RouteNames.kadivDashboardPath);

      expect(items[1].label, 'Approval');
      expect(items[1].icon, Icons.assignment_ind_outlined);
      expect(items[1].route, RouteNames.kadivApprovalsPath);

      expect(items[2].label, 'Notifikasi');
      expect(items[2].icon, Icons.notifications_none_rounded);
      expect(items[2].route, RouteNames.kadivNotificationsPath);

      expect(items[3].label, 'Profil');
      expect(items[3].icon, Icons.person_outline_rounded);
      expect(items[3].route, RouteNames.profilePath);
    });

    test('Staf Aset configuration matches exact specification with /staff-aset/ prefix', () {
      final items = RoleNavConfig.getNavItemsForRole(UserRole.staffAset);
      expect(items.length, 4);

      expect(items[0].label, 'Home');
      expect(items[0].icon, Icons.home_outlined);
      expect(items[0].route, RouteNames.staffDashboardPath);
      expect(items[0].route.startsWith('/staff-aset/'), isTrue);

      expect(items[1].label, 'Update Aset');
      expect(items[1].icon, Icons.edit_location_alt_outlined);
      expect(items[1].route, RouteNames.staffMutationsPath);
      expect(items[1].route.startsWith('/staff-aset/'), isTrue);

      expect(items[2].label, 'Notifikasi');
      expect(items[2].icon, Icons.notifications_none_rounded);
      expect(items[2].route, RouteNames.staffNotificationsPath);

      expect(items[3].label, 'Profil');
      expect(items[3].icon, Icons.person_outline_rounded);
      expect(items[3].route, RouteNames.profilePath);

      // Verify no /staff/ prefix
      for (final item in items) {
        if (item.route.contains('staff')) {
          expect(item.route.contains('/staff/'), isFalse);
          expect(item.route.contains('/staff-aset/'), isTrue);
        }
      }
    });

    test('Admin configuration matches exact specification without notification', () {
      final items = RoleNavConfig.getNavItemsForRole(UserRole.admin);
      expect(items.length, 4);

      expect(items[0].label, 'Home');
      expect(items[0].icon, Icons.grid_view_rounded);
      expect(items[0].route, RouteNames.adminDashboardPath);

      expect(items[1].label, 'Master Data');
      expect(items[1].icon, Icons.dns_outlined);
      expect(items[1].route, RouteNames.adminCategoriesPath);

      expect(items[2].label, 'Users');
      expect(items[2].icon, Icons.group_outlined);
      expect(items[2].route, RouteNames.adminUsersPath);

      expect(items[3].label, 'Profil');
      expect(items[3].icon, Icons.person_outline_rounded);
      expect(items[3].route, RouteNames.profilePath);

      // Verify Admin has NO notification item
      expect(items.any((item) => item.label == 'Notifikasi'), isFalse);
    });
  });

  group('CustomFloatingNavBar Widget Tests', () {
    testWidgets('renders all items and shows active pill container for matched route',
        (tester) async {
      final router = GoRouter(
        initialLocation: RouteNames.pemohonDashboardPath,
        routes: [
          GoRoute(
            path: RouteNames.pemohonDashboardPath,
            builder: (context, state) => Scaffold(
              bottomNavigationBar: CustomFloatingNavBar.scaffoldBottomBar(
                items: RoleNavConfig.getNavItemsForRole(UserRole.pemohon),
              ),
              body: const Text('Dashboard Body'),
            ),
          ),
          GoRoute(
            path: RouteNames.pemohonMutasiPath,
            builder: (context, state) => const Text('Mutasi Body'),
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
      await tester.pumpAndSettle();

      // Check all 4 items rendered
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Mutasi Saya'), findsOneWidget);
      expect(find.text('Notifikasi'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);

      // Check active item has primary color and w600 weight
      final berandaText = tester.widget<Text>(find.text('Beranda'));
      expect(berandaText.style?.fontWeight, FontWeight.w600);

      final mutasiSayaText = tester.widget<Text>(find.text('Mutasi Saya'));
      expect(mutasiSayaText.style?.fontWeight, FontWeight.w500);

      // Tapping on another item navigates
      await tester.tap(find.text('Mutasi Saya'));
      await tester.pumpAndSettle();
      expect(find.text('Mutasi Body'), findsOneWidget);
    });

    testWidgets('renders notification badge when unread notifications exist',
        (tester) async {
      final router = GoRouter(
        initialLocation: RouteNames.operatorDashboardPath,
        routes: [
          GoRoute(
            path: RouteNames.operatorDashboardPath,
            builder: (context, state) => Scaffold(
              bottomNavigationBar: CustomFloatingNavBar.scaffoldBottomBar(
                items: RoleNavConfig.getNavItemsForRole(UserRole.operator),
              ),
              body: const Text('Operator Body'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unreadNotificationCountProvider.overrideWithValue(3),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Badge widget exists for notification icon
      expect(find.byType(Badge), findsOneWidget);
    });

    testWidgets('no notification badge shown when unread count is 0',
        (tester) async {
      final router = GoRouter(
        initialLocation: RouteNames.operatorDashboardPath,
        routes: [
          GoRoute(
            path: RouteNames.operatorDashboardPath,
            builder: (context, state) => Scaffold(
              bottomNavigationBar: CustomFloatingNavBar.scaffoldBottomBar(
                items: RoleNavConfig.getNavItemsForRole(UserRole.operator),
              ),
              body: const Text('Operator Body'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unreadNotificationCountProvider.overrideWithValue(0),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final badgeContainers = tester.widgetList<Container>(find.byType(Container)).where((container) {
        final decoration = container.decoration;
        if (decoration is BoxDecoration) {
          return decoration.color == const Color(0xFFB42318);
        }
        return false;
      });
      expect(badgeContainers.isEmpty, isTrue);
    });
  });
}
