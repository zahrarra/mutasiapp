import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mutasiku/core/errors/failures.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/core/network/api_client.dart';

void main() {
  group('ApiClient Authentication & Multipart Tests', () {
    test('postMultipart sends Authorization header when token is set directly', () async {
      String? capturedAuthHeader;
      String? capturedContentType;

      final mockClient = MockClient((request) async {
        if (request.method == 'POST' && request.url.path == '/api/v1/mutations') {
          capturedAuthHeader = request.headers['Authorization'];
          capturedContentType = request.headers['content-type'];
          return http.Response(
            jsonEncode({'success': true, 'data': {'id': '101'}}),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
        baseUrl: 'http://test.local',
        httpClient: mockClient,
      );

      apiClient.setAuthToken('valid_sanctum_token_123');
      expect(apiClient.hasAuthToken, isTrue);

      final result = await apiClient.postMultipart(
        '/api/v1/mutations',
        fields: {'asset_id': '1', 'reason': 'Testing'},
        files: [
          http.MultipartFile.fromString(
            'sk_document',
            'dummy pdf content',
            filename: 'sk_test.pdf',
          ),
        ],
      );

      expect(result, isA<Success<Map<String, dynamic>>>());
      expect(capturedAuthHeader, equals('Bearer valid_sanctum_token_123'));
      expect(capturedContentType, contains('multipart/form-data; boundary='));
    });

    test('postMultipart automatically resolves token via tokenGetter when _authToken is null', () async {
      String? capturedAuthHeader;
      var tokenGetterCalls = 0;

      final mockClient = MockClient((request) async {
        if (request.method == 'POST' && request.url.path == '/api/v1/mutations') {
          capturedAuthHeader = request.headers['Authorization'];
          return http.Response(
            jsonEncode({'success': true, 'data': {'id': '102'}}),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
        baseUrl: 'http://test.local',
        httpClient: mockClient,
        tokenGetter: () async {
          tokenGetterCalls++;
          return 'resolved_from_storage_token_abc';
        },
      );

      expect(apiClient.hasAuthToken, isFalse);

      final result = await apiClient.postMultipart(
        '/api/v1/mutations',
        fields: {'asset_id': '2'},
      );

      expect(result, isA<Success<Map<String, dynamic>>>());
      expect(tokenGetterCalls, equals(1));
      expect(capturedAuthHeader, equals('Bearer resolved_from_storage_token_abc'));
      expect(apiClient.hasAuthToken, isTrue);
    });

    test('postMultipart returns UnauthorizedFailure on HTTP 401 and calls onUnauthorized', () async {
      var unauthorizedCalled = false;

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Unauthenticated.'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'http://test.local',
        httpClient: mockClient,
        onUnauthorized: () {
          unauthorizedCalled = true;
        },
      );

      apiClient.setAuthToken('stale_token_xyz');

      final result = await apiClient.postMultipart(
        '/api/v1/mutations',
        fields: {'asset_id': '1'},
      );

      expect(result, isA<AppFailure<Map<String, dynamic>>>());
      final failure = (result as AppFailure<Map<String, dynamic>>).failure;
      expect(failure, isA<UnauthorizedFailure>());
      expect(failure.message, equals('Unauthenticated.'));
      expect(unauthorizedCalled, isTrue);
      expect(apiClient.hasAuthToken, isFalse);
    });

    test('get and post methods also resolve token via tokenGetter', () async {
      String? getAuthHeader;
      String? postAuthHeader;

      final mockClient = MockClient((request) async {
        if (request.method == 'GET') {
          getAuthHeader = request.headers['Authorization'];
          return http.Response(jsonEncode({'success': true}), 200);
        }
        if (request.method == 'POST') {
          postAuthHeader = request.headers['Authorization'];
          return http.Response(jsonEncode({'success': true}), 200);
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
        baseUrl: 'http://test.local',
        httpClient: mockClient,
        tokenGetter: () async => 'lazy_loaded_token_999',
      );

      final getResult = await apiClient.get('/api/v1/assets');
      expect(getResult, isA<Success<Map<String, dynamic>>>());
      expect(getAuthHeader, equals('Bearer lazy_loaded_token_999'));

      final postResult = await apiClient.post('/api/v1/mutations/1/verify');
      expect(postResult, isA<Success<Map<String, dynamic>>>());
      expect(postAuthHeader, equals('Bearer lazy_loaded_token_999'));
    });
  });

  group('ApiClient URL Builder & Login Path Normalization Tests', () {
    test('1. Normal baseUrl (http://127.0.0.1:8000) menghasilkan endpoint /api/v1/auth/login persis', () {
      final client = ApiClient(baseUrl: 'http://127.0.0.1:8000');
      expect(
        client.buildUri('/api/v1/auth/login').toString(),
        equals('http://127.0.0.1:8000/api/v1/auth/login'),
      );
    });

    test('2. Path /api/v1/login (tanpa segmen auth) otomatis dinormalisasi ke /api/v1/auth/login', () {
      final client = ApiClient(baseUrl: 'http://127.0.0.1:8000');
      expect(
        client.buildUri('/api/v1/login').toString(),
        equals('http://127.0.0.1:8000/api/v1/auth/login'),
      );
    });

    test('3. Path /login otomatis dinormalisasi ke /api/v1/auth/login', () {
      final client = ApiClient(baseUrl: 'http://127.0.0.1:8000');
      expect(
        client.buildUri('/login').toString(),
        equals('http://127.0.0.1:8000/api/v1/auth/login'),
      );
    });

    test('4. BaseUrl yang berakhiran /api/v1 TIDAK menghasilkan prefix ganda (/api/v1/api/v1/...)', () {
      final client = ApiClient(baseUrl: 'http://127.0.0.1:8000/api/v1');
      expect(
        client.buildUri('/api/v1/auth/login').toString(),
        equals('http://127.0.0.1:8000/api/v1/auth/login'),
      );
      expect(
        client.buildUri('/login').toString(),
        equals('http://127.0.0.1:8000/api/v1/auth/login'),
      );
    });

    test('5. Endpoint auth lainnya (/me, /logout, /change-password) dibangun dengan benar', () {
      final client = ApiClient(baseUrl: 'http://127.0.0.1:8000');
      expect(
        client.buildUri('/api/v1/auth/me').toString(),
        equals('http://127.0.0.1:8000/api/v1/auth/me'),
      );
      expect(
        client.buildUri('/api/v1/auth/logout').toString(),
        equals('http://127.0.0.1:8000/api/v1/auth/logout'),
      );
      expect(
        client.buildUri('/api/v1/auth/change-password').toString(),
        equals('http://127.0.0.1:8000/api/v1/auth/change-password'),
      );

      // Dengan baseUrl berakhiran /api/v1
      final clientWithPrefix = ApiClient(baseUrl: 'http://127.0.0.1:8000/api/v1');
      expect(
        clientWithPrefix.buildUri('/api/v1/auth/me').toString(),
        equals('http://127.0.0.1:8000/api/v1/auth/me'),
      );
      expect(
        clientWithPrefix.buildUri('/api/v1/auth/logout').toString(),
        equals('http://127.0.0.1:8000/api/v1/auth/logout'),
      );
      expect(
        clientWithPrefix.buildUri('/api/v1/auth/change-password').toString(),
        equals('http://127.0.0.1:8000/api/v1/auth/change-password'),
      );
    });

    test('6. Request POST login terkirim persis ke path /api/v1/auth/login via HTTP Client', () async {
      String? capturedPath;
      String? capturedMethod;

      final mockClient = MockClient((request) async {
        capturedMethod = request.method;
        capturedPath = request.url.path;
        return http.Response(
          jsonEncode({
            'success': true,
            'token': 'tok_xyz',
            'user': {'id': 1, 'email': 'admin@mutasiku.test', 'role': 'admin'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(
        baseUrl: 'http://127.0.0.1:8000',
        httpClient: mockClient,
      );

      final res = await client.post('/api/v1/auth/login', body: {'email': 'admin@mutasiku.test', 'password': 'password'});
      expect(res, isA<Success<Map<String, dynamic>>>());
      expect(capturedMethod, equals('POST'));
      expect(capturedPath, equals('/api/v1/auth/login'));
    });

    test('7. Path tanpa prefix (/locations, /admin/users) otomatis dinormalisasi ke /api/v1', () {
      final client = ApiClient(baseUrl: 'http://127.0.0.1:8000');
      expect(
        client.buildUri('/locations').toString(),
        equals('http://127.0.0.1:8000/api/v1/locations'),
      );
      expect(
        client.buildUri('/admin/users').toString(),
        equals('http://127.0.0.1:8000/api/v1/admin/users'),
      );
    });

    test('8. Android Emulator BaseUrl (http://10.0.2.2:8000) dan Physical IP dengan atau tanpa /api/v1', () {
      final clientEmulator = ApiClient(baseUrl: 'http://10.0.2.2:8000');
      expect(
        clientEmulator.buildUri('/api/v1/mutations').toString(),
        equals('http://10.0.2.2:8000/api/v1/mutations'),
      );
      expect(
        clientEmulator.buildUri('/mutations').toString(),
        equals('http://10.0.2.2:8000/api/v1/mutations'),
      );

      final clientPhysicalWithSlash = ApiClient(baseUrl: 'http://192.168.1.10:8000/api/v1/');
      expect(
        clientPhysicalWithSlash.buildUri('/api/v1/mutations').toString(),
        equals('http://192.168.1.10:8000/api/v1/mutations'),
      );
      expect(
        clientPhysicalWithSlash.buildUri('/mutations').toString(),
        equals('http://192.168.1.10:8000/api/v1/mutations'),
      );
    });
  });
}
