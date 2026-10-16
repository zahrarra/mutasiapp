// test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mutasiku/app/app.dart';
import 'package:mutasiku/core/providers/core_providers.dart';
import 'package:mutasiku/core/storage/secure_storage.dart';

class FakeSecureStorage extends SecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<String?> read(String key) async {
    return _data[key];
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _data.clear();
  }

  @override
  Future<bool> containsKey(String key) async {
    return _data.containsKey(key);
  }
}

void main() {
  testWidgets(
    'MutasiKuApp renders LandingPage when user is not authenticated',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      final pref = await SharedPreferences.getInstance();
      final fakeSecureStorage = FakeSecureStorage();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(pref),
            secureStorageProvider.overrideWithValue(fakeSecureStorage),
          ],
          child: const MutasiKuApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Aplikasi pertama kali dibuka → Landing Page.
      expect(find.text('MutasiKu'), findsOneWidget);
    },
  );

  testWidgets(
    'MutasiKuApp renders Pemohon dashboard when user is authenticated',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      final pref = await SharedPreferences.getInstance();
      final fakeSecureStorage = FakeSecureStorage();

      await fakeSecureStorage.saveAuthToken('dummy_token');
      await fakeSecureStorage.saveUserId('usr_101');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(pref),
            secureStorageProvider.overrideWithValue(fakeSecureStorage),
          ],
          child: const MutasiKuApp(),
        ),
      );

      await tester.pumpAndSettle();

      // User authenticated → diarahkan ke dashboard sesuai role.
      expect(find.text('Dashboard MutasiKu'), findsNothing);
    },
  );
}
