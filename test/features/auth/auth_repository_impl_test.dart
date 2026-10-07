// test/features/auth/auth_repository_impl_test.dart
//
// Unit & Integration Test untuk AuthRepositoryImpl:
// 1. User terdaftar + password benar -> BERHASIL
// 2. User terdaftar + password salah -> DITOLAK
// 3. Email tidak terdaftar + password benar -> DITOLAK
// 4. Email tidak terdaftar + password salah -> DITOLAK
// 5. Email valid format tetapi bukan user database -> DITOLAK
// 6. Email tanpa format valid -> DITOLAK

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mutasiku/core/errors/failures.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/core/network/api_client.dart';
import 'package:mutasiku/core/storage/secure_storage.dart';
import 'package:mutasiku/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';

class FakeSecureStorage implements SecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> saveAuthToken(String token) async => _storage['auth_token'] = token;

  @override
  Future<String?> getAuthToken() async => _storage['auth_token'];

  @override
  Future<bool> hasAuthToken() async => _storage.containsKey('auth_token');

  @override
  Future<void> deleteAuthToken() async => _storage.remove('auth_token');

  @override
  Future<void> saveUserId(String userId) async => _storage['user_id'] = userId;

  @override
  Future<String?> getUserId() async => _storage['user_id'];

  @override
  Future<void> deleteUserId() async => _storage.remove('user_id');

  @override
  Future<void> clearAll() async => _storage.clear();

  @override
  Future<void> deleteAll() async => _storage.clear();

  @override
  Future<String?> read(String key) async => _storage[key];

  @override
  Future<void> write(String key, String value) async => _storage[key] = value;

  @override
  Future<void> delete(String key) async => _storage.remove(key);

  @override
  Future<bool> containsKey(String key) async => _storage.containsKey(key);
}

void main() {
  group('AuthRepositoryImpl - Backend Integration Tests', () {
    late FakeSecureStorage secureStorage;

    // Database mock yang merefleksikan persis UserSeeder backend Laravel:
    // User terdaftar: pemohon@mutasiku.test dengan password 'password'
    final registeredUsers = <String, Map<String, dynamic>>{
      'pemohon@mutasiku.test': {
        'id': 2,
        'name': 'Pemohon MutasiKu',
        'email': 'pemohon@mutasiku.test',
        'nip': '100002',
        'role': 'pemohon',
        'is_active': true,
        'password': 'password',
      },
    };

    http.Client createMockBackendClient() {
      return MockClient((request) async {
        if (request.url.path == '/api/v1/auth/login') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final email = body['email'] as String? ?? '';
          final password = body['password'] as String? ?? '';

          // 1. Validasi format email (mirip Laravel FormRequest / Validator)
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!emailRegex.hasMatch(email)) {
            return http.Response(
              jsonEncode({
                'success': false,
                'status': 'error',
                'message': 'Validasi gagal.',
                'errors': {
                  'email': ['Format email tidak valid.'],
                },
              }),
              422,
              headers: {'content-type': 'application/json'},
            );
          }

          // 2. Pencarian user di database
          final user = registeredUsers[email];
          if (user == null || user['password'] != password) {
            return http.Response(
              jsonEncode({
                'success': false,
                'status': 'error',
                'message': 'Email atau password salah.',
                'errors': {
                  'credentials': ['Email atau password salah.'],
                },
              }),
              401,
              headers: {'content-type': 'application/json'},
            );
          }

          // 3. User terdaftar dan password benar
          final token = 'mock_sanctum_token_${user['id']}';
          return http.Response(
            jsonEncode({
              'success': true,
              'status': 'success',
              'message': 'Login berhasil.',
              'token': token,
              'role': user['role'],
              'user': user,
              'data': {
                'token': token,
                'token_type': 'Bearer',
                'role': user['role'],
                'user': user,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('Not Found', 404);
      });
    }

    setUp(() {
      secureStorage = FakeSecureStorage();
    });

    AuthRepositoryImpl createRepository(http.Client httpClient) {
      final apiClient = ApiClient(
        baseUrl: 'http://127.0.0.1:8000',
        httpClient: httpClient,
      );
      return AuthRepositoryImpl(
        secureStorage: secureStorage,
        apiClient: apiClient,
      );
    }

    test('1. User terdaftar + password benar -> BERHASIL', () async {
      final repo = createRepository(createMockBackendClient());

      final result = await repo.login(
        username: 'pemohon@mutasiku.test',
        password: 'password',
      );

      expect(result, isA<Success<User>>());
      final user = (result as Success<User>).data;
      expect(user.email, 'pemohon@mutasiku.test');
      expect(user.role, UserRole.pemohon);

      // Verifikasi token tersimpan di secure storage
      expect(await secureStorage.hasAuthToken(), isTrue);
      expect(await secureStorage.getAuthToken(), 'mock_sanctum_token_2');
    });

    test('2. User terdaftar + password salah -> DITOLAK', () async {
      final repo = createRepository(createMockBackendClient());

      final result = await repo.login(
        username: 'pemohon@mutasiku.test',
        password: 'salah_password',
      );

      expect(result, isA<AppFailure<User>>());
      final failure = (result as AppFailure<User>).failure;
      expect(failure, isA<UnauthorizedFailure>());
      expect(failure.userMessage, 'Email atau password salah.');
      expect(await secureStorage.hasAuthToken(), isFalse);
    });

    test('3. Email tidak terdaftar + password benar -> DITOLAK', () async {
      final repo = createRepository(createMockBackendClient());

      final result = await repo.login(
        username: 'bukanuser@mutasiku.test',
        password: 'password',
      );

      expect(result, isA<AppFailure<User>>());
      final failure = (result as AppFailure<User>).failure;
      expect(failure, isA<UnauthorizedFailure>());
      expect(failure.userMessage, 'Email atau password salah.');
      expect(await secureStorage.hasAuthToken(), isFalse);
    });

    test('4. Email tidak terdaftar + password salah -> DITOLAK', () async {
      final repo = createRepository(createMockBackendClient());

      final result = await repo.login(
        username: 'bukanuser@mutasiku.test',
        password: 'salah_password',
      );

      expect(result, isA<AppFailure<User>>());
      final failure = (result as AppFailure<User>).failure;
      expect(failure, isA<UnauthorizedFailure>());
      expect(failure.userMessage, 'Email atau password salah.');
      expect(await secureStorage.hasAuthToken(), isFalse);
    });

    test('5. Email valid format tetapi bukan user database -> DITOLAK', () async {
      final repo = createRepository(createMockBackendClient());

      final result = await repo.login(
        username: 'orangasing@gmail.com',
        password: 'password_apa_saja',
      );

      expect(result, isA<AppFailure<User>>());
      final failure = (result as AppFailure<User>).failure;
      expect(failure, isA<UnauthorizedFailure>());
      expect(failure.userMessage, 'Email atau password salah.');
      expect(await secureStorage.hasAuthToken(), isFalse);
    });

    test('6. Email tanpa format valid -> DITOLAK', () async {
      final repo = createRepository(createMockBackendClient());

      final result = await repo.login(
        username: 'pemohon',
        password: 'password',
      );

      expect(result, isA<AppFailure<User>>());
      final failure = (result as AppFailure<User>).failure;
      expect(failure, isA<ValidationFailure>());
      final valFailure = failure as ValidationFailure;
      expect(valFailure.fieldErrors?['email'], contains('Format email tidak valid.'));
      expect(await secureStorage.hasAuthToken(), isFalse);
    });
  });
}
