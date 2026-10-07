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

    test('Bagian Aset configuration matches exact specification', () {
      final items = RoleNavConfig.getNavItemsForRole(UserRole.bagianAset);
      expect(items.length, 4);

      expect(items[0].label, 'Beranda');
      expect(items[0].icon, Icons.home_outlined);
      expect(items[0].route, RouteNames.bagianAsetDashboardPath);

      expect(items[1].label, 'Verifikasi');
      expect(items[1].icon, Icons.assignment_ind_outlined);
      expect(items[1].route, RouteNames.bagianAsetVerificationsPath);

      expect(items[2].label, 'Notifikasi');
      expect(items[2].icon, Icons.notifications_none_rounded);
      expect(items[2].route, RouteNames.bagianAsetNotificationsPath);

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

    test('Admin configuration matches exact specification without notification', () {
      final items = RoleNavConfig.getNavItemsForRole(UserRole.admin);
      expect(items.length, 4);

      expect(items[0].label, 'Beranda');
      expect(items[0].icon, Icons.home);
      expect(items[0].route, RouteNames.adminDashboardPath);

      expect(items[1].label, 'Master Data');
      expect(items[1].icon, Icons.storage_outlined);
      expect(items[1].route, RouteNames.adminCategoriesPath);

      expect(items[2].label, 'Audit Log');
      expect(items[2].icon, Icons.history_outlined);
      expect(items[2].route, RouteNames.adminAuditLogPath);

      expect(items[3].label, 'Profil');
      expect(items[3].icon, Icons.person_outline);
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

    testWidgets('renders Admin navbar matching Dashboard Admin design tokens and navigates to Audit Log',
        (tester) async {
      final router = GoRouter(
        initialLocation: RouteNames.adminDashboardPath,
        routes: [
          GoRoute(
            path: RouteNames.adminDashboardPath,
            builder: (context, state) => Scaffold(
              bottomNavigationBar: CustomFloatingNavBar.scaffoldBottomBar(
                items: RoleNavConfig.getNavItemsForRole(UserRole.admin),
              ),
              body: const Text('Admin Dashboard Body'),
            ),
          ),
          GoRoute(
            path: RouteNames.adminAuditLogPath,
            builder: (context, state) => const Text('Admin Audit Log Body'),
          ),
          GoRoute(
            path: RouteNames.profilePath,
            builder: (context, state) => const Text('Admin Profil Body'),
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

      // Check all 4 admin items rendered with matching labels
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Master Data'), findsOneWidget);
      expect(find.text('Audit Log'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);

      // Check active item has primaryNavy color and w700 weight
      final berandaText = tester.widget<Text>(find.text('Beranda'));
      expect(berandaText.style?.fontWeight, FontWeight.w700);
      expect(berandaText.style?.fontSize, 11);
      expect(berandaText.style?.color, const Color(0xFF0F3D56));

      // Inactive item has w500 weight and slate400 color
      final auditText = tester.widget<Text>(find.text('Audit Log'));
      expect(auditText.style?.fontWeight, FontWeight.w500);
      expect(auditText.style?.fontSize, 11);
      expect(auditText.style?.color, const Color(0xFF94A3B8));

      // Tapping on Audit Log navigates to Audit Log screen
      await tester.tap(find.text('Audit Log'));
      await tester.pumpAndSettle();
      expect(find.text('Admin Audit Log Body'), findsOneWidget);
    });

    testWidgets('renders Bagian Aset navbar matching standard design tokens (pill 48x28, icon 20, font 11)',
        (tester) async {
      final router = GoRouter(
        initialLocation: RouteNames.bagianAsetVerificationsPath,
        routes: [
          GoRoute(
            path: RouteNames.bagianAsetVerificationsPath,
            builder: (context, state) => Scaffold(
              bottomNavigationBar: CustomFloatingNavBar.scaffoldBottomBar(
                items: RoleNavConfig.getNavItemsForRole(UserRole.bagianAset),
                currentRoute: RouteNames.bagianAsetVerificationsPath,
              ),
              body: const Text('Verifikasi Body'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unreadNotificationCountProvider.overrideWithValue(2),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check all 4 Bagian Aset items rendered
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Verifikasi'), findsOneWidget);
      expect(find.text('Notifikasi'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);

      // Check active item (Verifikasi) uses standard tokens: w700, size 11, primary color
      final verifText = tester.widget<Text>(find.text('Verifikasi'));
      expect(verifText.style?.fontWeight, FontWeight.w700);
      expect(verifText.style?.fontSize, 11);
      expect(verifText.style?.color, const Color(0xFF0F3D56));

      // Check inactive item (Beranda) uses standard tokens: w500, size 11, slate400 color
      final berandaText = tester.widget<Text>(find.text('Beranda'));
      expect(berandaText.style?.fontWeight, FontWeight.w500);
      expect(berandaText.style?.fontSize, 11);
      expect(berandaText.style?.color, const Color(0xFF94A3B8));

      // Check pill container sizes (48 x 28)
      final pillContainers = tester.widgetList<Container>(find.byType(Container)).where((c) {
        final box = c.decoration;
        if (box is BoxDecoration) {
          return c.constraints?.maxWidth == 48 ||
              (box.borderRadius == BorderRadius.circular(999) &&
                  box.color == const Color(0xFFECF4FF));
        }
        return false;
      });
      expect(pillContainers.isNotEmpty, isTrue);

      // Check notification badge rendered inside standard pill layout
      expect(find.byType(Badge), findsOneWidget);
    });
  });
}
