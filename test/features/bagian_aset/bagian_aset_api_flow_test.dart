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
import 'package:mutasiku/features/bagian_aset/presentation/providers/bagian_aset_verification_provider.dart';
import 'package:mutasiku/features/mutation/data/repositories/mutation_repository_impl.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';

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
  const kabagUser = User(
    id: '16',
    username: 'bagian_aset_real',
    name: 'Yusuf Bagian Aset Asli',
    email: 'yusuf.aset@mutasiku.id',
    role: UserRole.bagianAset,
  );

  setUp(() {
    AssetRepositoryImpl.resetForTesting();
    MutationRepositoryImpl.resetForTesting();
  });

  group('Kabag/Bagian Aset READ Mutation API Flow Integration Tests', () {
    test('1. Kabag list/queue memanggil GET /api/v1/mutations dan data masuk ke kabagAllMutationsProvider', () async {
      var apiEndpointCalled = false;
      String? sentAuthHeader;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/mutations') {
          apiEndpointCalled = true;
          sentAuthHeader = request.headers['authorization'];
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Daftar pengajuan mutasi untuk Bagian Aset berhasil diambil.',
              'data': [
                {
                  'id': 301,
                  'ticket_number': 'KBG-2026-00301',
                  'applicant_id': 42,
                  'applicant': {
                    'id': 42,
                    'name': 'Rina Pemohon',
                    'email': 'rina@mutasiku.id',
                  },
                  'asset': {
                    'id': 15,
                    'asset_code': 'AST-FUR-015',
                    'name': 'Meja Kerja Ergonomis',
                    'category': {
                      'id': 2,
                      'code': 'FUR',
                      'name': 'Furnitur & Peralatan',
                    },
                    'location': {
                      'id': 1,
                      'name': 'Gedung A Lantai 1',
                    },
                  },
                  'status': 'menunggu_verifikasi_bagian_aset',
                  'origin_location': {'name': 'Gedung A Lantai 1'},
                  'destination_location': {'name': 'Gedung B Lantai 3'},
                  'description': 'Relokasi staf antar gedung',
                  'notes': null,
                  'created_at': '2026-10-07T08:30:00.000000Z',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(jsonEncode({'message': 'Not Found'}), 404);
      });

      final apiClient = ApiClient(httpClient: mockClient, baseUrl: 'http://test.local');
      apiClient.setAuthToken('test_sanctum_token_kabag');

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          authStateProvider.overrideWith((ref) => _TestAuthNotifier(kabagUser)),
        ],
      );

      final mutations = await container.read(kabagAllMutationsProvider.future);

      expect(apiEndpointCalled, true);
      expect(sentAuthHeader, 'Bearer test_sanctum_token_kabag');
      expect(mutations.length, 1);
      expect(mutations.first.id, '301');
      expect(mutations.first.ticketNumber, 'KBG-2026-00301');
      expect(mutations.first.status, MutationStatus.waitingAssetVerification);
      expect(mutations.first.asset.name, 'Meja Kerja Ergonomis');
    });

    test('2. Response status API menunggu_verifikasi_bagian_aset dipetakan ke status waiting dan statistik Kabag', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/mutations') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 301,
                  'ticket_number': 'KBG-001',
                  'status': 'menunggu_verifikasi_bagian_aset',
                  'asset': {
                    'id': 1,
                    'name': 'Laptop Dell Latitude',
                    'category': {'code': 'TI', 'name': 'Teknologi Informasi'},
                  },
                  'applicant': {'name': 'Ahmad Pemohon'},
                  'origin_location': {'name': 'Lantai 1'},
                  'destination_location': {'name': 'Lantai 2'},
                  'created_at': '2026-10-07T09:00:00Z',
                },
                {
                  'id': 302,
                  'ticket_number': 'KBG-002',
                  'status': 'menunggu_approval_pemimpin_divisi',
                  'asset': {
                    'id': 2,
                    'name': 'Kursi Kerja Staff',
                    'category': {'code': 'FUR', 'name': 'Furnitur'},
                  },
                  'applicant': {'name': 'Budi Pemohon'},
                  'origin_location': {'name': 'Lantai 2'},
                  'destination_location': {'name': 'Lantai 3'},
                  'created_at': '2026-10-07T09:15:00Z',
                },
                {
                  'id': 303,
                  'ticket_number': 'KBG-003',
                  'status': 'ditolak',
                  'asset': {
                    'id': 3,
                    'name': 'Printer Laserjet',
                    'category': {'code': 'TI', 'name': 'Teknologi Informasi'},
                  },
                  'applicant': {'name': 'Citra Pemohon'},
                  'origin_location': {'name': 'Lantai 1'},
                  'destination_location': {'name': 'Lantai 4'},
                  'created_at': '2026-10-07T09:30:00Z',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(jsonEncode({'message': 'Not Found'}), 404);
      });

      final apiClient = ApiClient(httpClient: mockClient, baseUrl: 'http://test.local');

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          authStateProvider.overrideWith((ref) => _TestAuthNotifier(kabagUser)),
        ],
      );

      await container.read(kabagAllMutationsProvider.future);

      final stats = container.read(kabagStatsProvider);
      expect(stats.waitingApprovalCount, 1);
      expect(stats.approvedCount, 1);
      expect(stats.rejectedCount, 1);

      container.read(kabagStatusFilterProvider.notifier).state = KabagStatusFilter.waiting;
      final waitingList = container.read(filteredKabagApprovalsProvider).value ?? [];
      expect(waitingList.length, 1);
      expect(waitingList.first.ticketNumber, 'KBG-001');

      container.read(kabagStatusFilterProvider.notifier).state = KabagStatusFilter.all;
      final allList = container.read(filteredKabagApprovalsProvider).value ?? [];
      expect(allList.length, 3);
    });

    test('3. API mengembalikan empty list -> UI state empty murni tanpa data dummy fallback', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Tidak ada data pengajuan mutasi.',
            'data': [],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(httpClient: mockClient, baseUrl: 'http://test.local');

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          authStateProvider.overrideWith((ref) => _TestAuthNotifier(kabagUser)),
        ],
      );

      final list = await container.read(kabagAllMutationsProvider.future);
      expect(list, isEmpty);

      final stats = container.read(kabagStatsProvider);
      expect(stats.waitingApprovalCount, 0);
      expect(stats.approvedCount, 0);
      expect(stats.rejectedCount, 0);
    });

    test('4. API mengembalikan error 500 -> provider melempar exception murni tanpa fallback ke mock', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Internal Server Error pada database mutasi.',
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(httpClient: mockClient, baseUrl: 'http://test.local');

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          authStateProvider.overrideWith((ref) => _TestAuthNotifier(kabagUser)),
        ],
      );

      expect(
        () => container.read(kabagAllMutationsProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('5. Detail mutasi Kabag memanggil GET /api/v1/mutations/{id} menggunakan kabagMutationDetailProvider', () async {
      var detailEndpointCalled = false;
      String? requestedPath;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/mutations/301') {
          detailEndpointCalled = true;
          requestedPath = request.url.path;
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Detail mutasi ditemukan.',
              'data': {
                'id': 301,
                'ticket_number': 'KBG-2026-00301',
                'applicant_id': 42,
                'applicant': {
                  'id': 42,
                  'name': 'Rina Pemohon',
                  'email': 'rina@mutasiku.id',
                },
                'asset': {
                  'id': 15,
                  'asset_code': 'AST-FUR-015',
                  'name': 'Meja Kerja Ergonomis',
                  'category': {
                    'id': 2,
                    'code': 'FUR',
                    'name': 'Furnitur & Peralatan',
                  },
                  'location': {
                    'id': 1,
                    'name': 'Gedung A Lantai 1',
                  },
                },
                'status': 'menunggu_verifikasi_bagian_aset',
                'origin_location': {'name': 'Gedung A Lantai 1'},
                'destination_location': {'name': 'Gedung B Lantai 3'},
                'description': 'Kebutuhan workstation baru tim finance',
                'notes': null,
                'created_at': '2026-10-07T08:30:00.000000Z',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(jsonEncode({'message': 'Not Found'}), 404);
      });

      final apiClient = ApiClient(httpClient: mockClient, baseUrl: 'http://test.local');

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          authStateProvider.overrideWith((ref) => _TestAuthNotifier(kabagUser)),
        ],
      );

      final detail = await container.read(kabagMutationDetailProvider('301').future);

      expect(detailEndpointCalled, true);
      expect(requestedPath, '/api/v1/mutations/301');
      expect(detail.id, '301');
      expect(detail.ticketNumber, 'KBG-2026-00301');
      expect(detail.asset.name, 'Meja Kerja Ergonomis');
      expect(detail.status, MutationStatus.waitingAssetVerification);
    });

    test('6. Detail mutasi ID tidak ada (404) -> kabagMutationDetailProvider melempar exception 404 tanpa fallback mock', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Data mutasi tidak ditemukan.',
          }),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(httpClient: mockClient, baseUrl: 'http://test.local');

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          authStateProvider.overrideWith((ref) => _TestAuthNotifier(kabagUser)),
        ],
      );

      expect(
        () => container.read(kabagMutationDetailProvider('non_existent_999').future),
        throwsA(isA<Exception>()),
      );
    });

    test('7. Role scoping backend dipatuhi dan frontend tidak memfilter berdasarkan dummy ID', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/mutations') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 310,
                  'ticket_number': 'TKT-SCOPED-01',
                  'applicant_id': 99,
                  'status': 'menunggu_verifikasi_bagian_aset',
                  'asset': {
                    'id': 10,
                    'name': 'Proyektor Epson',
                    'category': {'code': 'TI', 'name': 'TI'},
                  },
                  'applicant': {'name': 'Pemohon Acak'},
                  'origin_location': {'name': 'Ruang Rapat 1'},
                  'destination_location': {'name': 'Ruang Rapat 2'},
                  'created_at': '2026-10-07T10:00:00Z',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(jsonEncode({'message': 'Not Found'}), 404);
      });

      final apiClient = ApiClient(httpClient: mockClient, baseUrl: 'http://test.local');

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          authStateProvider.overrideWith((ref) => _TestAuthNotifier(kabagUser)),
        ],
      );

      final list = await container.read(kabagAllMutationsProvider.future);
      expect(list.length, 1);
      expect(list.first.ticketNumber, 'TKT-SCOPED-01');
    });
  });
}
