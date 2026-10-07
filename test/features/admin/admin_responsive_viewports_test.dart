// test/features/admin/admin_responsive_viewports_test.dart
//
// Multi-viewport responsiveness test for Admin Screens:
// - AdminUsersScreen
// - AdminDashboardScreen
//
// Viewports:
// - Mobile: 360x800, 390x844, 430x932
// - Tablet: 768x1024, 820x1180, 1024x1366
// - Desktop: 1280x800, 1440x900, 1920x1080
//
// Asserts ZERO RenderFlex overflow and full visual layout integrity.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:mutasiku/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:mutasiku/features/asset/presentation/screens/asset_category_screen.dart';

void main() {
  const viewports = <String, Size>{
    'Mobile Small (360x800)': Size(360, 800),
    'Mobile Standard (390x844)': Size(390, 844),
    'Mobile Large (430x932)': Size(430, 932),
    'Tablet Portrait (768x1024)': Size(768, 1024),
    'Tablet Large (820x1180)': Size(820, 1180),
    'Tablet Landscape (1024x768)': Size(1024, 768),
    'Desktop HD (1280x800)': Size(1280, 800),
    'Desktop WXGA (1440x900)': Size(1440, 900),
    'Desktop FHD (1920x1080)': Size(1920, 1080),
  };

  group('AdminUsersScreen Responsive Multi-Viewport Tests', () {
    for (final entry in viewports.entries) {
      testWidgets('renders cleanly on ${entry.key} with 0 RenderFlex errors',
          (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: AdminUsersScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check header and content presence
        expect(find.text('User & Permission'), findsOneWidget);
        expect(find.text('Daftar Pengguna Aktif'), findsOneWidget);
        expect(find.text('Kelola Akses'), findsWidgets);

        // Verify no RenderFlex overflow
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('AdminDashboardScreen Responsive Multi-Viewport Tests', () {
    for (final entry in viewports.entries) {
      testWidgets('renders cleanly on ${entry.key} with 0 RenderFlex errors',
          (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: AdminDashboardScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check essential elements
        expect(find.textContaining('Administrator'), findsWidgets);
        expect(find.text('RINGKASAN MASTER DATA SISTEM'), findsOneWidget);
        expect(find.text('User & Permission'), findsWidgets);

        // Verify no RenderFlex overflow
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('AssetCategoryScreen (Master Data Admin) Responsive Multi-Viewport Tests', () {
    for (final entry in viewports.entries) {
      testWidgets('renders cleanly on ${entry.key} with 0 RenderFlex errors',
          (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: AssetCategoryScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check essential Stitch elements
        expect(find.text('MUTASIKU ADMIN'), findsOneWidget);
        expect(find.text('RINGKASAN MASTER DATA SISTEM'), findsOneWidget);
        expect(find.text('Daftar Modul Master Data'), findsOneWidget);
        expect(find.text('Kelola Pengguna (User Management)'), findsOneWidget);
        expect(find.text('Role & Hak Akses (RBAC)'), findsOneWidget);
        expect(find.text('Master Unit Kerja & Pool Cabang'), findsOneWidget);
        expect(find.text('Kategori Master Aset'), findsOneWidget);

        // Verify no RenderFlex overflow
        expect(tester.takeException(), isNull);
      });
    }
  });
}
