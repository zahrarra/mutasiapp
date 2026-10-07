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
import 'package:mutasiku/features/operator/presentation/providers/operator_verification_provider.dart';

class _FakeAuthRepository implements AuthRepository {
  final User? user;
  _FakeAuthRepository(this.user);

  @override
  Future<Result<User?>> getCurrentUser() async => Result.success(user);

  @override
  Future<Result<User>> login({required String username, required String password}) async =>
      throw UnimplementedError();

  @override
  Future<Result<void>> logout() async => const Result.success(null);
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
  const operatorUser = User(
    id: '15',
    username: 'operator_real',
    name: 'Siti Operator Asli',
    email: 'siti.operator@mutasiku.id',
    role: UserRole.operator,
  );

  setUp(() {
    AssetRepositoryImpl.resetForTesting();
    MutationRepositoryImpl.resetForTesting();
  });

  group('Operator READ Mutation API Flow Integration Tests', () {
    test('1. Operator list/queue menggunakan API repository dan memanggil GET /api/v1/mutations', () async {
      var apiEndpointCalled = false;
      String? sentAuthHeader;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/mutations') {
          apiEndpointCalled = true;
          sentAuthHeader = request.headers['authorization'];
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Daftar pengajuan mutasi untuk antrean Operator berhasil diambil.',
              'data': [
                {
                  'id': 201,
                  'ticket_number': 'TI-2026-00201',
                  'applicant_id': 42,
                  'applicant': {
                    'id': 42,
                    'name': 'Rina Pemohon',
                    'email': 'rina@mutasiku.id',
                  },
                  'asset': {
                    'id': 12,
                    'asset_code': 'AST-ELK-012',
                    'name': 'Laptop ThinkPad X1 Carbon',
                    'category': {
                      'id': 1,
                      'code': 'ELK',
                      'name': 'Elektronik & IT',
                    },
                    'location': {
                      'id': 2,
                      'name': 'Lantai 2 - Keuangan',
                    },
                  },
                  'status': 'diajukan',
                  'origin_location': {'name': 'Lantai 2 - Keuangan'},
                  'destination_location': {'name': 'Lantai 4 - HRD'},
                  'reason': 'Kebutuhan tim HRD baru',
                  'created_at': '2026-03-05T09:30:00Z',
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
      testApiClient.setAuthToken('sanctum_token_operator_15');

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(testApiClient),
          authStateProvider.overrideWith((ref) => _TestAuthNotifier(operatorUser)),
        ],
      );
      addTearDown(container.dispose);

      final mutations = await container.read(operatorAllMutationsProvider.future);

      expect(apiEndpointCalled, isTrue);
      expect(sentAuthHeader, equals('Bearer sanctum_token_operator_15'));
      expect(mutations.length, equals(1));
      expect(mutations.first.id, equals('201'));
      expect(mutations.first.ticketNumber, equals('TI-2026-00201'));
      expect(mutations.first.status, equals(MutationStatus.submitted));
      expect(mutations.first.applicantName, equals('Rina Pemohon'));
      expect(mutations.first.asset.name, equals('Laptop ThinkPad X1 Carbon'));

      // Verifikasi filteredIncomingMutationsProvider
      final incomingAsync = container.read(filteredIncomingMutationsProvider);
      expect(incomingAsync.hasValue, isTrue);
      expect(incomingAsync.value!.length, equals(1));
      expect(incomingAsync.value!.first.id, equals('201'));

      // Verifikasi verificationStatsProvider
      final stats = container.read(verificationStatsProvider);
      expect(stats.pendingCount, equals(1));
      expect(stats.tiCount, equals(1));
    });

    test('2. Response API kosong (data: []) menghasilkan empty queue state tanpa dummy fallback', () async {
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
          authStateProvider.overrideWith((ref) => _TestAuthNotifier(operatorUser)),
        ],
      );
      addTearDown(container.dispose);

      final mutations = await container.read(operatorAllMutationsProvider.future);
      expect(mutations, isEmpty);

      final incomingAsync = container.read(filteredIncomingMutationsProvider);
      expect(incomingAsync.hasValue, isTrue);
      expect(incomingAsync.value, isEmpty);

      final stats = container.read(verificationStatsProvider);
      expect(stats.pendingCount, equals(0));
    });

    test('3. API 500 Server Error menghasilkan error state dan TIDAK fallback ke mock', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Server database sedang bermasalah.'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final testApiClient = ApiClient(httpClient: mockClient, baseUrl: 'http://test.local');
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(testApiClient),
          authStateProvider.overrideWith((ref) => _TestAuthNotifier(operatorUser)),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () async => await container.read(operatorAllMutationsProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('4. API 401/403 Unauthorized ditangani dengan error state tanpa fallback ke mock', () async {
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
          authStateProvider.overrideWith((ref) => _TestAuthNotifier(operatorUser)),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () async => await container.read(operatorAllMutationsProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('5. Detail Operator (operatorMutationDetailProvider) memanggil GET /api/v1/mutations/{id}', () async {
      var detailEndpointCalled = false;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/mutations/205') {
          detailEndpointCalled = true;
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Detail mutasi berhasil diambil.',
              'data': {
                'id': 205,
                'ticket_number': 'TI-2026-00205',
                'applicant_id': 33,
                'applicant': {'id': 33, 'name': 'Ahmad Pemohon'},
                'asset': {
                  'id': 50,
                  'name': 'PC All-in-One Dell OptiPlex',
                  'asset_code': 'AST-ELK-0050',
                  'category': {'id': 1, 'name': 'Elektronik & IT'},
                },
                'origin_location': {'name': 'Lantai 1 - CS'},
                'destination_location': {'name': 'Lantai 3 - Akuntansi'},
                'current_pic': {'name': 'Staff CS 1'},
                'target_pic': {'name': 'Supervisor Akuntansi'},
                'status': 'diajukan',
                'reason': 'Kebutuhan workstation akuntansi',
                'created_at': '2026-03-06T08:00:00Z',
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
          authStateProvider.overrideWith((ref) => _TestAuthNotifier(operatorUser)),
        ],
      );
      addTearDown(container.dispose);

      final detail = await container.read(operatorMutationDetailProvider('205').future);

      expect(detailEndpointCalled, isTrue);
      expect(detail.id, equals('205'));
      expect(detail.ticketNumber, equals('TI-2026-00205'));
      expect(detail.status, equals(MutationStatus.submitted));
      expect(detail.asset.name, equals('PC All-in-One Dell OptiPlex'));
      expect(detail.applicantName, equals('Ahmad Pemohon'));
      expect(detail.currentLocation, equals('Lantai 1 - CS'));
      expect(detail.targetLocation, equals('Lantai 3 - Akuntansi'));
      expect(detail.targetPic, equals('Supervisor Akuntansi'));
    });

    test('6. Detail Operator 404 Not Found melempar Exception tanpa fallback ke mock', () async {
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
          authStateProvider.overrideWith((ref) => _TestAuthNotifier(operatorUser)),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () async => await container.read(operatorMutationDetailProvider('9999').future),
        throwsA(isA<Exception>()),
      );
    });

    test('7. Role scoping: Data berasal dari response API backend tanpa filter ID dummy frontend', () async {
      String? requestedPath;

      final mockClient = MockClient((request) async {
        requestedPath = request.url.path;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 301,
                'ticket_number': 'TI-2026-00301',
                'applicant_id': 99,
                'applicant': {'id': 99, 'name': 'Pemohon dari Divisi Lain'},
                'status': 'diajukan',
                'reason': 'Scoped by backend',
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
          authStateProvider.overrideWith((ref) => _TestAuthNotifier(operatorUser)),
        ],
      );
      addTearDown(container.dispose);

      final list = await container.read(operatorAllMutationsProvider.future);

      expect(requestedPath, equals('/api/v1/mutations'));
      expect(list.length, equals(1));
      // Pemohon ID tidak dibatasi atau difilter oleh dummy ID frontend
      expect(list.first.applicantId, equals('99'));
      expect(list.first.applicantName, equals('Pemohon dari Divisi Lain'));
    });
  });
}
