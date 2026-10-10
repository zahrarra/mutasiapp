// test/features/auth/login_screen_responsive_test.dart
//
// Widget test untuk verifikasi responsiveness Halaman Login:
// - Mobile (< 600px)
// - Tablet (600px - 959px)
// - Desktop (>= 960px)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mutasiku/features/auth/presentation/screens/login_screen.dart';

void main() {
  Widget createLoginTestWidget() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
      ],
    );

    return ProviderScope(child: MaterialApp.router(routerConfig: router));
  }

  group('LoginScreen Responsive Layout Tests', () {
    testWidgets('renders properly on Mobile (375x812) without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createLoginTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Heading & branding
      expect(find.text('Masuk'), findsNWidgets(2)); // Heading dan Tombol Masuk
      expect(find.text('MutasiKu'), findsOneWidget);

      // Form elements
      expect(find.byKey(const Key('login_username_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Masuk'), findsOneWidget);

      // Ensure no desktop hero headline in mobile view
      expect(
        find.text('Tata Kelola Mutasi Aset\nCepat, Transparan & Akuntabel.'),
        findsNothing,
      );
    });

    testWidgets('renders properly on Tablet (768x1024) without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createLoginTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Masuk'), findsNWidgets(2));
      expect(find.byKey(const Key('login_username_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
    });

    testWidgets(
      'renders two-column split layout on Desktop (1440x900) without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createLoginTestWidget());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Desktop hero panel elements
        expect(
          find.text('Tata Kelola Mutasi Aset\nCepat, Transparan & Akuntabel.'),
          findsOneWidget,
        );
        expect(find.text('Otorisasi & Alur Berjenjang'), findsOneWidget);
        expect(find.text('Pelacakan Status Real-Time'), findsOneWidget);
        expect(find.text('Audit Trail Otomatis SIPA'), findsOneWidget);

        // Form elements on right side
        expect(find.text('Masuk'), findsNWidgets(2));
        expect(find.byKey(const Key('login_username_field')), findsOneWidget);
        expect(find.byKey(const Key('login_password_field')), findsOneWidget);
        expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
        expect(find.text('Sistem Terotentikasi & Terproteksi'), findsOneWidget);
      },
    );
  });
}
