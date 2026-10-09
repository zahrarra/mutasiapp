// test/features/auth/change_password_screen_test.dart
//
// Widget test untuk verifikasi:
// 1. Navigasi fokus keyboard Enter/Next berurutan:
//    current_password -> new_password -> confirm_password -> submit
// 2. TextInputAction.next pada current & new password
// 3. TextInputAction.done pada confirm password
// 4. Submisi form dan validasi saat Enter/Done ditekan

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';
import 'package:mutasiku/features/auth/presentation/screens/change_password_screen.dart';

class _FakeAuthNotifierForChangePassword extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeAuthNotifierForChangePassword({
    User? initialUser,
  }) : super(AuthState(isLoading: false, user: initialUser));

  int changePasswordCallCount = 0;
  String? lastCurrentPassword;
  String? lastNewPassword;
  String? lastConfirmPassword;

  @override
  Future<Result<User>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    changePasswordCallCount++;
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;
    lastConfirmPassword = confirmPassword;

    final updatedUser = (state.user ??
            const User(
              id: 'usr_test',
              name: 'Test User',
              username: 'testuser',
              role: UserRole.pemohon,
            ))
        .copyWith(mustChangePassword: false);

    state = state.copyWith(user: updatedUser);
    return Result.success(updatedUser);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const testUser = User(
    id: 'usr_test',
    name: 'Budi Tester',
    username: 'buditester',
    role: UserRole.pemohon,
    mustChangePassword: true,
  );

  Widget createTestWidget({
    _FakeAuthNotifierForChangePassword? notifier,
  }) {
    final fakeNotifier = notifier ??
        _FakeAuthNotifierForChangePassword(initialUser: testUser);

    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => fakeNotifier),
      ],
      child: const MaterialApp(
        home: ChangePasswordScreen(),
      ),
    );
  }

  group('ChangePasswordScreen — Enter / Next Keyboard Navigation', () {
    testWidgets(
      'Konfigurasi textInputAction tepat: current (next), new (next), confirm (done)',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final currentTextField = tester.widget<TextField>(
          find.descendant(
            of: find.byKey(const Key('current_password_input')),
            matching: find.byType(TextField),
          ),
        );
        final newTextField = tester.widget<TextField>(
          find.descendant(
            of: find.byKey(const Key('new_password_input')),
            matching: find.byType(TextField),
          ),
        );
        final confirmTextField = tester.widget<TextField>(
          find.descendant(
            of: find.byKey(const Key('confirm_password_input')),
            matching: find.byType(TextField),
          ),
        );

        expect(currentTextField.textInputAction, equals(TextInputAction.next));
        expect(newTextField.textInputAction, equals(TextInputAction.next));
        expect(confirmTextField.textInputAction, equals(TextInputAction.done));
      },
    );

    testWidgets(
      'Menekan Enter/Next memindahkan fokus berurutan dari current ke new ke confirm password',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final currentFinder = find.byKey(const Key('current_password_input'));
        final newFinder = find.byKey(const Key('new_password_input'));
        final confirmFinder = find.byKey(const Key('confirm_password_input'));

        // 1. Fokuskan ke input password saat ini
        await tester.tap(currentFinder);
        await tester.pumpAndSettle();
        await tester.enterText(currentFinder, 'passwordLama123');
        await tester.pumpAndSettle();

        // 2. Tekan aksi Next / Enter pada keyboard
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pumpAndSettle();

        // Fokus harus berpindah ke password baru
        final newEditable = tester.widget<EditableText>(
          find.descendant(of: newFinder, matching: find.byType(EditableText)),
        );
        expect(newEditable.focusNode.hasFocus, isTrue);

        // 3. Masukkan teks di password baru
        await tester.enterText(newFinder, 'passwordBaru@2026');
        await tester.pumpAndSettle();

        // 4. Tekan aksi Next / Enter lagi
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pumpAndSettle();

        // Fokus harus berpindah ke konfirmasi password baru
        final confirmEditable = tester.widget<EditableText>(
          find.descendant(of: confirmFinder, matching: find.byType(EditableText)),
        );
        expect(confirmEditable.focusNode.hasFocus, isTrue);
      },
    );

    testWidgets(
      'Menekan Enter/Done pada kolom konfirmasi password memicu submit formulir',
      (tester) async {
        final fakeNotifier =
            _FakeAuthNotifierForChangePassword(initialUser: testUser);

        await tester.pumpWidget(createTestWidget(notifier: fakeNotifier));
        await tester.pumpAndSettle();

        final currentFinder = find.byKey(const Key('current_password_input'));
        final newFinder = find.byKey(const Key('new_password_input'));
        final confirmFinder = find.byKey(const Key('confirm_password_input'));

        // Isi form dengan valid
        await tester.enterText(currentFinder, 'passwordLama123');
        await tester.enterText(newFinder, 'passwordBaru@2026');
        await tester.enterText(confirmFinder, 'passwordBaru@2026');
        await tester.pumpAndSettle();

        // Fokuskan kolom konfirmasi dan kirim aksi Done
        await tester.tap(confirmFinder);
        await tester.pumpAndSettle();
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // changePassword harus dipanggil
        expect(fakeNotifier.changePasswordCallCount, equals(1));
        expect(fakeNotifier.lastCurrentPassword, equals('passwordLama123'));
        expect(fakeNotifier.lastNewPassword, equals('passwordBaru@2026'));
        expect(fakeNotifier.lastConfirmPassword, equals('passwordBaru@2026'));
        expect(
          find.text('Password berhasil diperbarui. Selamat datang di MutasiKu!'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Menekan Enter/Done saat validasi gagal menampilkan pesan error tanpa submit',
      (tester) async {
        final fakeNotifier =
            _FakeAuthNotifierForChangePassword(initialUser: testUser);

        await tester.pumpWidget(createTestWidget(notifier: fakeNotifier));
        await tester.pumpAndSettle();

        final confirmFinder = find.byKey(const Key('confirm_password_input'));

        // Langsung tekan done saat semua field kosong
        await tester.tap(confirmFinder);
        await tester.pumpAndSettle();
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Tidak boleh memanggil API
        expect(fakeNotifier.changePasswordCallCount, equals(0));
        // Pesan error validasi harus muncul
        expect(find.text('Password saat ini wajib diisi'), findsOneWidget);
        expect(find.text('Password baru wajib diisi'), findsOneWidget);
        expect(find.text('Konfirmasi password wajib diisi'), findsOneWidget);
      },
    );
  });
}
