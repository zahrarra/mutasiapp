// test/features/auth/login_form_validation_test.dart
//
// Widget test untuk verifikasi:
// 1. Kondisi awal field email dan password kosong
// 2. Input email format tidak valid (termasuk 'pemohon') ditolak
// 3. Input email valid diterima

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';
import 'package:mutasiku/features/auth/presentation/screens/login_screen.dart';

class FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  FakeAuthNotifier() : super(const AuthState(isLoading: false));

  @override
  Future<bool> login(String username, String password) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget createLoginTestWidget() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
      ],
    );

    return ProviderScope(
      overrides: [authStateProvider.overrideWith((ref) => FakeAuthNotifier())],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('LoginScreen Form Validation & Initial State Tests', () {
    testWidgets('field email dan password pada kondisi awal kosong', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createLoginTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final usernameField = tester.widget<TextFormField>(
        find.byKey(const Key('login_username_field')),
      );
      final passwordField = tester.widget<TextFormField>(
        find.byKey(const Key('login_password_field')),
      );

      expect(usernameField.controller?.text, isEmpty);
      expect(passwordField.controller?.text, isEmpty);
    });

    testWidgets(
      'input kosong ditolak oleh validasi saat tombol login ditekan',
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

        final submitBtn = find.byKey(const Key('login_submit_button'));
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Email tidak boleh kosong'), findsOneWidget);
        expect(find.text('Password wajib diisi'), findsOneWidget);
      },
    );

    testWidgets('input "pemohon" ditolak sebagai email format tidak valid', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createLoginTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.enterText(
        find.byKey(const Key('login_username_field')),
        'pemohon',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'password123',
      );

      final submitBtn = find.byKey(const Key('login_submit_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Format email tidak valid'), findsOneWidget);
      expect(find.text('Email tidak boleh kosong'), findsNothing);
      expect(find.text('Password wajib diisi'), findsNothing);
    });

    testWidgets('input format email tidak valid lainnya ditolak', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createLoginTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.enterText(
        find.byKey(const Key('login_username_field')),
        'pegawai_tanpa_domain',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'password123',
      );

      final submitBtn = find.byKey(const Key('login_submit_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Format email tidak valid'), findsOneWidget);
    });

    testWidgets('input email valid ("pemohon@example.com") lolos validasi', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createLoginTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.enterText(
        find.byKey(const Key('login_username_field')),
        'pemohon@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'password123',
      );

      final submitBtn = find.byKey(const Key('login_submit_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tidak ada error validasi format email atau required
      expect(find.text('Format email tidak valid'), findsNothing);
      expect(find.text('Email tidak boleh kosong'), findsNothing);
      expect(find.text('Password wajib diisi'), findsNothing);
    });
  });
}
