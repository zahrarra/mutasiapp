// test/features/auth/user_department_api_persistence_test.dart
//
// Pengujian integrasi API UserRepositoryImpl untuk memastikan:
// 1. Tambah user (createUser) mengirim field 'department' ke backend API dan membaca responsnya.
// 2. Edit user (updateUser) mengirim field 'department' ke backend API dan membaca responsnya.
// 3. Pembacaan user (getAllUsers, getUserById) mengutamakan field 'department' dari backend API.
// 4. Kompatibilitas mundur akun warisan (legacy) jika 'department' dari backend masih bernilai null.

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mutasiku/core/constants/master_departments.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/core/network/api_client.dart';
import 'package:mutasiku/features/auth/data/repositories/user_repository_impl.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';

void main() {
  group('UserRepositoryImpl Department Backend Persistence Tests', () {
    test('1. createUser mengirim field "department" ke backend API dan membaca kembali dari response', () async {
      Map<String, dynamic>? capturedBody;

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/v1/admin/roles')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {'id': 1, 'name': 'admin'},
                {'id': 2, 'name': 'kadiv'},
                {'id': 3, 'name': 'bagian_aset'},
                {'id': 4, 'name': 'operator'},
                {'id': 5, 'name': 'pemohon'},
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path == '/api/v1/admin/users' && request.method == 'POST') {
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 15,
                'nip': '199001012026101001',
                'name': 'Dewi Sartika',
                'email': 'dewi.sartika@mutasiku.id',
                'department': capturedBody!['department'],
                'role': 'operator',
                'is_active': true,
                'must_change_password': false,
              }
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response(jsonEncode({'message': 'Not Found'}), 404);
      });

      final apiClient = ApiClient(baseUrl: 'http://127.0.0.1:8000', httpClient: mockClient);
      final repository = UserRepositoryImpl(apiClient: apiClient);

      const newUser = User(
        id: '',
        username: '199001012026101001',
        name: 'Dewi Sartika',
        email: 'dewi.sartika@mutasiku.id',
        role: UserRole.operator,
        department: 'Divisi SDM',
        isActive: true,
      );

      final result = await repository.createUser(newUser, password: 'password123');

      expect(result.isSuccess, isTrue);
      // Verifikasi payload yang dikirim ke backend via HTTP POST
      expect(capturedBody, isNotNull);
      expect(capturedBody!['department'], 'Divisi SDM');
      expect(capturedBody!['name'], 'Dewi Sartika');
      expect(capturedBody!['nip'], '199001012026101001');

      // Verifikasi objek user yang dikembalikan membaca department dari backend
      final createdUser = (result as Success<User>).data;
      expect(createdUser.id, '15');
      expect(createdUser.department, 'Divisi SDM');
      expect(MasterDepartments.contains(createdUser.department), isTrue);
    });

    test('2. updateUser mengirim field "department" ke backend API dan membaca kembali hasil pembaruan', () async {
      Map<String, dynamic>? capturedBody;

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/v1/admin/roles')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {'id': 1, 'name': 'admin'},
                {'id': 2, 'name': 'kadiv'},
                {'id': 3, 'name': 'bagian_aset'},
                {'id': 4, 'name': 'operator'},
                {'id': 5, 'name': 'pemohon'},
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path == '/api/v1/admin/users/15' && request.method == 'PUT') {
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 15,
                'nip': '199001012026101001',
                'name': 'Dewi Sartika',
                'email': 'dewi.sartika@mutasiku.id',
                'department': capturedBody!['department'],
                'role': 'operator',
                'is_active': true,
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response(jsonEncode({'message': 'Not Found'}), 404);
      });

      final apiClient = ApiClient(baseUrl: 'http://127.0.0.1:8000', httpClient: mockClient);
      final repository = UserRepositoryImpl(apiClient: apiClient);

      const existingUser = User(
        id: '15',
        username: '199001012026101001',
        name: 'Dewi Sartika',
        email: 'dewi.sartika@mutasiku.id',
        role: UserRole.operator,
        department: 'Divisi SDM',
        isActive: true,
      );

      final updatedUser = existingUser.copyWith(department: 'Divisi Hukum');
      final result = await repository.updateUser(updatedUser);

      expect(result.isSuccess, isTrue);
      // Verifikasi payload HTTP PUT
      expect(capturedBody, isNotNull);
      expect(capturedBody!['department'], 'Divisi Hukum');

      // Verifikasi user hasil update
      final savedUser = (result as Success<User>).data;
      expect(savedUser.department, 'Divisi Hukum');
      expect(MasterDepartments.contains(savedUser.department), isTrue);
    });

    test('3. getAllUsers membaca langsung nilai "department" dari response backend API', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/admin/users' && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 1,
                  'name': 'Admin IT',
                  'email': 'admin@mutasiku.id',
                  'department': 'Divisi TI',
                  'role': 'admin',
                  'is_active': true,
                },
                {
                  'id': 2,
                  'name': 'Staff Treasury',
                  'email': 'treasury@mutasiku.id',
                  'department': 'Divisi Treasury',
                  'role': 'pemohon',
                  'is_active': true,
                },
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(jsonEncode({'message': 'Not Found'}), 404);
      });

      final apiClient = ApiClient(baseUrl: 'http://127.0.0.1:8000', httpClient: mockClient);
      final repository = UserRepositoryImpl(apiClient: apiClient);

      final result = await repository.getAllUsers();
      expect(result.isSuccess, isTrue);

      final users = (result as Success<List<User>>).data;
      expect(users.length, 2);
      expect(users[0].department, 'Divisi TI');
      expect(users[1].department, 'Divisi Treasury');
    });

    test('4. Kompatibel dengan akun legacy di mana "department" di database backend masih null', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/admin/users' && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 99,
                  'name': 'Legacy User Aset',
                  'email': 'legacy.aset@mutasiku.id',
                  'department': null, // Nilai legacy null di DB
                  'role': 'bagian_aset',
                  'is_active': true,
                },
                {
                  'id': 100,
                  'name': 'Legacy User Pemohon',
                  'email': 'legacy.pemohon@mutasiku.id',
                  'department': null, // Nilai legacy null di DB
                  'role': 'pemohon',
                  'is_active': true,
                },
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(jsonEncode({'message': 'Not Found'}), 404);
      });

      final apiClient = ApiClient(baseUrl: 'http://127.0.0.1:8000', httpClient: mockClient);
      final repository = UserRepositoryImpl(apiClient: apiClient);

      final result = await repository.getAllUsers();
      expect(result.isSuccess, isTrue);

      final users = (result as Success<List<User>>).data;
      expect(users.length, 2);

      // Verifikasi tidak crash dan fallback resmi aktif sesuai role pengguna
      expect(users[0].department, 'Divisi Umum dan Aset');
      expect(users[1].department, 'Divisi Operasional');
      expect(MasterDepartments.contains(users[0].department), isTrue);
      expect(MasterDepartments.contains(users[1].department), isTrue);
    });

    test('5. getUserById membaca department dari API dan fallback aman jika null', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/admin/users/88' && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 88,
                'name': 'Kadiv User',
                'email': 'kadiv@mutasiku.id',
                'department': null,
                'role': 'kadiv',
                'is_active': true,
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(jsonEncode({'message': 'Not Found'}), 404);
      });

      final apiClient = ApiClient(baseUrl: 'http://127.0.0.1:8000', httpClient: mockClient);
      final repository = UserRepositoryImpl(apiClient: apiClient);

      final result = await repository.getUserById('88');
      expect(result.isSuccess, isTrue);

      final user = (result as Success<User>).data;
      expect(user.department, 'Divisi TI'); // Fallback kadiv
      expect(MasterDepartments.contains(user.department), isTrue);
    });
  });
}
