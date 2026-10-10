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
import 'package:mutasiku/core/errors/failures.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';
import 'package:mutasiku/features/auth/presentation/screens/login_screen.dart';

class FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  FakeAuthNotifier([AuthState? initialState])
      : super(initialState ?? const AuthState(isLoading: false));

  @override
  Future<bool> login(String username, String password) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget createLoginTestWidget({AuthState? authState}) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
      ],
    );

    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => FakeAuthNotifier(authState)),
      ],
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

        expect(find.text('Silakan masukkan alamat email.'), findsOneWidget);
        expect(find.text('Silakan masukkan kata sandi.'), findsOneWidget);
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

      expect(find.text('Format alamat email tidak valid.'), findsOneWidget);
      expect(find.text('Silakan masukkan alamat email.'), findsNothing);
      expect(find.text('Silakan masukkan kata sandi.'), findsNothing);
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

      expect(find.text('Format alamat email tidak valid.'), findsOneWidget);
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
      expect(find.text('Format alamat email tidak valid.'), findsNothing);
      expect(find.text('Silakan masukkan alamat email.'), findsNothing);
      expect(find.text('Silakan masukkan kata sandi.'), findsNothing);
    });
  });

  group('LoginScreen Indonesian Error Banner & Feedback Tests', () {
    testWidgets('menampilkan pesan "Email atau kata sandi salah." saat kredensial ditolak', (
      tester,
    ) async {
      await tester.pumpWidget(
        createLoginTestWidget(
          authState: const AuthState(
            failure: UnauthorizedFailure(message: 'Email atau password salah.'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Email atau kata sandi salah.'), findsWidgets);
    });

    testWidgets('menampilkan pesan akun dinonaktifkan saat failure akun nonaktif', (
      tester,
    ) async {
      await tester.pumpWidget(
        createLoginTestWidget(
          authState: const AuthState(
            failure: ForbiddenFailure(
              message: 'Akun Anda telah dinonaktifkan oleh Administrator. Silakan hubungi Admin.',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.text('Akun Anda telah dinonaktifkan oleh Administrator. Silakan hubungi Admin.'),
        findsWidgets,
      );
    });

    testWidgets('menampilkan pesan "Koneksi ke server tidak tersedia..." saat kegagalan jaringan', (
      tester,
    ) async {
      await tester.pumpWidget(
        createLoginTestWidget(
          authState: const AuthState(
            failure: NetworkFailure(message: 'SocketException: connection refused'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.text('Koneksi ke server tidak tersedia. Periksa koneksi Anda, lalu coba lagi.'),
        findsWidgets,
      );
    });

    testWidgets('menampilkan pesan "Waktu permintaan habis..." saat network timeout', (
      tester,
    ) async {
      await tester.pumpWidget(
        createLoginTestWidget(
          authState: const AuthState(
            failure: NetworkFailure(message: 'Connection timeout'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.text('Waktu permintaan habis. Silakan periksa koneksi Anda dan coba lagi.'),
        findsWidgets,
      );
    });

    testWidgets('menampilkan pesan "Terjadi kesalahan pada server. Silakan coba lagi." saat server failure', (
      tester,
    ) async {
      await tester.pumpWidget(
        createLoginTestWidget(
          authState: const AuthState(
            failure: ServerFailure(message: 'Server error 500'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.text('Terjadi kesalahan pada server. Silakan coba lagi.'),
        findsWidgets,
      );
    });

    testWidgets('menampilkan indikator dan teks "Sedang masuk..." saat state loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        createLoginTestWidget(
          authState: const AuthState(isLoading: true),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Sedang masuk...'), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });
}
