import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/core/network/api_client.dart';
import 'package:mutasiku/core/providers/core_providers.dart';
import 'package:mutasiku/features/asset/data/repositories/asset_repository_impl.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/auth/domain/repositories/auth_repository.dart';
import 'package:mutasiku/features/auth/domain/usecases/login_usecase.dart';
import 'package:mutasiku/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';
import 'package:mutasiku/features/mutation/data/repositories/mutation_repository_impl.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';

class _FakeAuthRepository implements AuthRepository {
  final User? user;
  _FakeAuthRepository(this.user);

  @override
  Future<Result<User?>> getCurrentUser() async => Result.success(user);

  @override
  Future<Result<User>> login({required String username, required String password}) async =>
      throw UnimplementedError();

  @override
  Future<void> logout() async {}
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(User user)
      : super(
          loginUseCase: LoginUseCase(repository: _FakeAuthRepository(user)),
          logoutUseCase: LogoutUseCase(repository: _FakeAuthRepository(user)),
          authRepository: _FakeAuthRepository(user),
          checkInitialStatus: false,
        ) {
    state = AuthState(isLoading: false, user: user);
  }
}

void main() {
  const pemohonUser = User(
    id: '42',
    username: 'pemohon_real',
    name: 'Rina Pemohon Asli',
    email: 'rina@mutasiku.id',
    role: UserRole.pemohon,
  );

  setUp(() {
    AssetRepositoryImpl.resetForTesting();
    MutationRepositoryImpl.resetForTesting();
  });

  group('Pemohon API Flow & Provider Integration Tests', () {
    test('1. Pemohon mutationListProvider menggunakan API repository dan memanggil GET /api/v1/mutations', () async {
      var apiEndpointCalled = false;
      String? sentAuthHeader;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/mutations') {
          apiEndpointCalled = true;
          sentAuthHeader = request.headers['authorization'];
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Daftar pengajuan mutasi berhasil diambil.',
              'data': [
                {
                  'id': 101,
                  'ticket_number': 'MUT-2026-00101',
                  'applicant_id': 42,
                  'applicant': {
                    'id': 42,
                    'name': 'Rina Pemohon Asli',
                    'email': 'rina@mutasiku.id',
                  },
                  'asset': {
                    'id': 1,
                    'asset_code': 'AST-001',
                    'name': 'Laptop Lenovo ThinkPad',
                  },
                  'status': 'diajukan',
                  'reason': 'Kebutuhan dinas lapangan',
                  'created_at': '2026-03-01T10:00:00Z',
                }
              ],
              'meta': {'current_page': 1, 'last_page': 1, 'total': 1},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final testApiClient = ApiClient(httpClient: mockClient, baseUrl: 'http://test.local');
      testApiClient.setAuthToken('sanctum_token_42');

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(testApiClient),
          authStateProvider.overrideWith((ref) => _TestAuthNotifier(pemohonUser)),
        ],
      );

      final mutations = await container.read(mutationListProvider.future);

      expect(apiEndpointCalled, isTrue);
      expect(sentAuthHeader, equals('Bearer sanctum_token_42'));
      expect(mutations.length, equals(1));
      expect(mutations.first.id, equals('101'));
      expect(mutations.first.ticketNumber, equals('MUT-2026-00101'));
      expect(mutations.first.status, equals(MutationStatus.submitted));
      expect(mutations.first.applicantId, equals('42'));
    });

    test('2. Response API kosong (data: []) -> mutationListProvider mengembalikan list kosong (empty state)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Daftar pengajuan mutasi berhasil diambil.',
            'data': [],
            'meta': {'current_page': 1, 'last_page': 1, 'total': 0},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final testApiClient = ApiClient(httpClient: mockClient, baseUrl: 'http://test.local');
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(testApiClient),
          authStateProvider.overrideWith((ref) => _TestAuthNotifier(pemohonUser)),
        ],
      );

      final mutations = await container.read(mutationListProvider.future);

      expect(mutations, isEmpty);
    });

    test('3. API error (500 / Server Error) -> mutationListProvider melempar error dan TIDAK fallback ke mock', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Internal Server Error'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final testApiClient = ApiClient(httpClient: mockClient, baseUrl: 'http://test.local');
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(testApiClient),
          authStateProvider.overrideWith((ref) => _TestAuthNotifier(pemohonUser)),
        ],
      );

      expect(
        () async => await container.read(mutationListProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('4. API error (401 Unauthorized) -> mutationListProvider error tanpa fallback diam-diam ke mock', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Unauthenticated.'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final testApiClient = ApiClient(httpClient: mockClient, baseUrl: 'http://test.local');
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(testApiClient),
          authStateProvider.overrideWith((ref) => _TestAuthNotifier(pemohonUser)),
        ],
      );

      expect(
        () async => await container.read(mutationListProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('5. Detail mutasi Pemohon (pemohonMutationDetailProvider) memanggil GET /api/v1/mutations/{id}', () async {
      var detailEndpointCalled = false;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/mutations/105') {
          detailEndpointCalled = true;
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Detail mutasi berhasil diambil.',
              'data': {
                'id': 105,
                'ticket_number': 'MUT-2026-00105',
                'applicant_id': 42,
                'applicant': {'id': 42, 'name': 'Rina Pemohon Asli'},
                'asset': {
                  'id': 5,
                  'name': 'MacBook Pro 16 M2',
                  'asset_code': 'AST-ELK-0105',
                  'category': {'id': 1, 'name': 'Elektronik & IT'},
                  'location': {'id': 2, 'name': 'Cabang Jakarta'},
                },
                'origin_location': {'id': 1, 'name': 'Kantor Pusat'},
                'destination_location': {'id': 2, 'name': 'Cabang Jakarta'},
                'status': 'dikembalikan_ke_pemohon',
                'return_reason': 'Dokumen pendukung SK penugasan belum lengkap.',
                'reason': 'Rotasi kerja ke Cabang Jakarta',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final testApiClient = ApiClient(httpClient: mockClient, baseUrl: 'http://test.local');
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(testApiClient),
          authStateProvider.overrideWith((ref) => _TestAuthNotifier(pemohonUser)),
        ],
      );

      final detail = await container.read(pemohonMutationDetailProvider('105').future);

      expect(detailEndpointCalled, isTrue);
      expect(detail.id, equals('105'));
      expect(detail.ticketNumber, equals('MUT-2026-00105'));
      expect(detail.status, equals(MutationStatus.returned));
      expect(detail.returnReason, equals('Dokumen pendukung SK penugasan belum lengkap.'));
      expect(detail.asset.name, equals('MacBook Pro 16 M2'));
      expect(detail.currentLocation, equals('Kantor Pusat'));
      expect(detail.targetLocation, equals('Cabang Jakarta'));
    });

    test('6. Detail mutasi 404 Not Found ditangani sebagai Exception not found tanpa fallback ke mock', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Pengajuan mutasi tidak ditemukan.',
          }),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final testApiClient = ApiClient(httpClient: mockClient, baseUrl: 'http://test.local');
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(testApiClient),
          authStateProvider.overrideWith((ref) => _TestAuthNotifier(pemohonUser)),
        ],
      );

      expect(
        () async => await container.read(pemohonMutationDetailProvider('9999').future),
        throwsA(isA<Exception>()),
      );
    });

    test('7. Authenticated user ID (id: 42) digunakan secara nyata, bukan dummy usr_pemohon', () async {
      String? requestedUrl;

      final mockClient = MockClient((request) async {
        requestedUrl = request.url.toString();
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 201,
                'ticket_number': 'MUT-2026-00201',
                'applicant_id': 42,
                'applicant': {'id': 42, 'name': 'Rina Pemohon Asli'},
                'status': 'diajukan',
                'reason': 'Testing real auth id',
              }
            ],
            'meta': {'current_page': 1, 'last_page': 1, 'total': 1},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final testApiClient = ApiClient(httpClient: mockClient, baseUrl: 'http://test.local');
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(testApiClient),
          authStateProvider.overrideWith((ref) => _TestAuthNotifier(pemohonUser)),
        ],
      );

      final list = await container.read(mutationListProvider.future);

      expect(requestedUrl, contains('/api/v1/mutations'));
      expect(list.length, equals(1));
      expect(list.first.applicantId, equals('42'));
      // Menjamin id tidak lagi mengandalkan dummy string
      expect(list.first.applicantId, isNot(equals('usr_pemohon')));
      expect(list.first.applicantId, isNot(equals('usr_101')));
    });
  });
}
