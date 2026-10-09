// test/features/admin/admin_user_create_and_auth_test.dart
//
// Test suite untuk verifikasi pembuatan user baru oleh Admin dan integrasi dengan backend API:
// 1. UserRepositoryImpl mengirim payload lengkap (name, email, password, role_id, nip) ke POST /api/v1/admin/users
// 2. Response dari API diparsing dengan benar (termasuk must_change_password)
// 3. MasterUsersNotifier meneruskan password ke repository dan me-refresh daftar user
// 4. Fallback in-memory tetap berfungsi saat ApiClient bernilai null

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mutasiku/core/errors/failures.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/core/network/api_client.dart';
import 'package:mutasiku/features/auth/data/repositories/user_repository_impl.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';

void main() {
  group('ADMIN USER CREATION & API INTEGRATION', () {
    test('1. UserRepositoryImpl mengirim POST /api/v1/admin/users dengan password & data lengkap', () async {
      Map<String, dynamic>? capturedBody;
      String? capturedPath;
      String? capturedMethod;

      final mockClient = MockClient((request) async {
        capturedMethod = request.method;
        capturedPath = request.url.path;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'User berhasil dibuat.',
            'data': {
              'id': 42,
              'name': capturedBody!['name'],
              'email': capturedBody!['email'],
              'nip': capturedBody!['nip'],
              'role_id': capturedBody!['role_id'],
              'role': 'operator',
              'is_active': true,
              'must_change_password': true,
              'created_at': '2026-10-09T10:00:00Z',
              'updated_at': '2026-10-09T10:00:00Z',
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:8000',
        httpClient: mockClient,
      );

      final repo = UserRepositoryImpl(apiClient: apiClient);

      const newUser = User(
        id: '',
        name: 'Surya Saputra',
        username: 'surya_operator',
        email: 'surya@mutasiku.test',
        department: 'Operasional',
        role: UserRole.operator,
        isActive: true,
      );

      final result = await repo.createUser(newUser, password: 'password123');

      expect(result is Success<User>, isTrue);
      final created = (result as Success<User>).data;

      expect(capturedMethod, equals('POST'));
      expect(capturedPath, equals('/api/v1/admin/users'));
      expect(capturedBody, isNotNull);
      expect(capturedBody!['name'], equals('Surya Saputra'));
      expect(capturedBody!['email'], equals('surya@mutasiku.test'));
      expect(capturedBody!['password'], equals('password123'));
      expect(capturedBody!['role_id'], equals(UserRole.operator.roleId));
      expect(capturedBody!['nip'], equals('surya_operator'));
      expect(capturedBody!['is_active'], isTrue);

      expect(created.id, equals('42'));
      expect(created.email, equals('surya@mutasiku.test'));
      expect(created.role, equals(UserRole.operator));
      expect(created.mustChangePassword, isTrue);
    });

    test('2. UserRepositoryImpl menangani validasi gagal (HTTP 422) dari backend dengan benar', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'message': 'Email sudah digunakan.',
            'errors': {
              'email': ['Email sudah digunakan.'],
            },
          }),
          422,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:8000',
        httpClient: mockClient,
      );

      final repo = UserRepositoryImpl(apiClient: apiClient);

      const newUser = User(
        id: '',
        name: 'Duplikat User',
        username: 'duplikat',
        email: 'sudahada@mutasiku.test',
        role: UserRole.pemohon,
        isActive: true,
      );

      final result = await repo.createUser(newUser, password: 'password123');

      expect(result is AppFailure<User>, isTrue);
      final failure = (result as AppFailure<User>).failure;
      expect(failure is ValidationFailure, isTrue);
      expect(failure.message, contains('Email sudah digunakan'));
    });

    test('3. MasterUsersNotifier meneruskan password ke repository dan me-refresh daftar user', () async {
      int getAllCalls = 0;
      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/v1/admin/users') {
          getAllCalls++;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 1,
                  'name': 'Admin MutasiKu',
                  'email': 'admin@mutasiku.test',
                  'nip': '100001',
                  'role': 'admin',
                  'is_active': true,
                  'must_change_password': false,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.method == 'POST' && request.url.path == '/api/v1/admin/users') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 99,
                'name': 'User Baru',
                'email': 'userbaru@mutasiku.test',
                'nip': 'userbaru',
                'role': 'bagian_aset',
                'is_active': true,
                'must_change_password': true,
              },
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:8000',
        httpClient: mockClient,
      );

      final repo = UserRepositoryImpl(apiClient: apiClient);
      final notifier = MasterUsersNotifier(repo);

      // Tunggu inisialisasi loadUsers()
      await Future.delayed(Duration.zero);

      const newUser = User(
        id: '',
        name: 'User Baru',
        username: 'userbaru',
        email: 'userbaru@mutasiku.test',
        role: UserRole.bagianAset,
      );

      final createResult = await notifier.createUser(newUser, password: 'passwordAwal123');
      expect(createResult is Success<User>, isTrue);
      expect(getAllCalls, greaterThanOrEqualTo(2)); // Dipanggil saat inisialisasi & setelah create
    });

    test('4. In-memory fallback tetap bekerja saat ApiClient bernilai null', () async {
      final repo = UserRepositoryImpl(apiClient: null);

      const newUser = User(
        id: '',
        name: 'Offline User',
        username: 'offline_user_test',
        email: 'offline@mutasiku.test',
        role: UserRole.kadiv,
      );

      final result = await repo.createUser(newUser, password: 'password123');
      expect(result is Success<User>, isTrue);
      final created = (result as Success<User>).data;
      expect(created.name, equals('Offline User'));
      expect(created.username, equals('offline_user_test'));
    });

    test('5. Kegagalan HTTP 500 saat apiClient != null TIDAK diam-diam beralih ke in-memory', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:8000',
        httpClient: mockClient,
      );

      final repo = UserRepositoryImpl(apiClient: apiClient);

      const newUser = User(
        id: '',
        name: 'Gagal User',
        username: 'gagal_user',
        email: 'gagal@mutasiku.test',
        role: UserRole.pemohon,
        isActive: true,
      );

      final result = await repo.createUser(newUser, password: 'password123');

      expect(result is AppFailure<User>, isTrue);
      final failure = (result as AppFailure<User>).failure;
      expect(failure is ServerFailure, isTrue);
    });

    test('6. Pemetaan kelima role MutasiKu terverifikasi stabil terhadap database & dinamis', () async {
      // 5 Role MutasiKu
      expect(UserRole.admin.roleId, equals(1));
      expect(UserRole.pemohon.roleId, equals(2));
      expect(UserRole.operator.roleId, equals(3));
      expect(UserRole.bagianAset.roleId, equals(4));
      expect(UserRole.kadiv.roleId, equals(5));

      expect(UserRole.admin.apiValue, equals('admin'));
      expect(UserRole.pemohon.apiValue, equals('pemohon'));
      expect(UserRole.operator.apiValue, equals('operator'));
      expect(UserRole.bagianAset.apiValue, equals('bagian_aset'));
      expect(UserRole.kadiv.apiValue, equals('pemimpin_divisi'));

      expect(UserRole.fromRoleId(1), equals(UserRole.admin));
      expect(UserRole.fromRoleId(2), equals(UserRole.pemohon));
      expect(UserRole.fromRoleId(3), equals(UserRole.operator));
      expect(UserRole.fromRoleId(4), equals(UserRole.bagianAset));
      expect(UserRole.fromRoleId(5), equals(UserRole.kadiv));

      // Verifikasi resolusi dinamis role dari endpoint /api/v1/admin/roles
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/admin/roles') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {'id': 10, 'name': 'admin'},
                {'id': 20, 'name': 'pemohon'},
                {'id': 30, 'name': 'operator'},
                {'id': 40, 'name': 'bagian_aset'},
                {'id': 50, 'name': 'pemimpin_divisi'},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:8000',
        httpClient: mockClient,
      );

      final repo = UserRepositoryImpl(apiClient: apiClient);
      expect(await repo.resolveRoleId(UserRole.kadiv), equals(50));
      expect(await repo.resolveRoleId(UserRole.operator), equals(30));
    });

    test('7. MasterUsersNotifier menyegarkan daftar user setelah update dan delete', () async {
      int getAllCalls = 0;
      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/v1/admin/users') {
          getAllCalls++;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'PUT' && request.url.path.startsWith('/api/v1/admin/users/')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 12,
                'name': 'Updated User',
                'email': 'update@mutasiku.test',
                'nip': 'update_nip',
                'role': 'operator',
                'is_active': true,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'DELETE' && request.url.path.startsWith('/api/v1/admin/users/')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': null,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:8000',
        httpClient: mockClient,
      );

      final repo = UserRepositoryImpl(apiClient: apiClient);
      final notifier = MasterUsersNotifier(repo);
      await Future.delayed(Duration.zero);

      final initialCalls = getAllCalls;

      const editUser = User(
        id: '12',
        name: 'Updated User',
        username: 'update_nip',
        role: UserRole.operator,
      );

      final updateRes = await notifier.updateUser(editUser);
      expect(updateRes is Success<User>, isTrue);
      expect(getAllCalls, equals(initialCalls + 1));

      final deleteRes = await notifier.deleteUser('12');
      expect(deleteRes is Success<void>, isTrue);
      expect(getAllCalls, equals(initialCalls + 2));
    });

    test('8. Operasi deleteUser saat backend mengembalikan HTTP 409 Conflict mengembalikan ConflictFailure', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'User tidak dapat dihapus karena masih digunakan pada data lain.',
          }),
          409,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:8000',
        httpClient: mockClient,
      );

      final repo = UserRepositoryImpl(apiClient: apiClient);
      final result = await repo.deleteUser('99');

      expect(result is AppFailure<void>, isTrue);
      final failure = (result as AppFailure<void>).failure;
      expect(failure is ConflictFailure, isTrue);
      expect(failure.message, contains('masih digunakan pada data lain'));
    });
  });
}
