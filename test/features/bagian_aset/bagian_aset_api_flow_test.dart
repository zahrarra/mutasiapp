import 'package:mutasiku/core/errors/failures.dart';
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
import 'package:mutasiku/features/mutation/presentation/models/mutation_tracking_step.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';

class _FakeAuthRepository implements AuthRepository {
  final User? user;
  _FakeAuthRepository(this.user);

  @override
  Future<Result<User?>> getCurrentUser() async => Result.success(user);

  @override
  Future<Result<User>> login({
    required String username,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<Result<void>> logout() async => const Result.success(null);

    @override
  Future<Result<User>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword.length < 8) {
      return Result.failure(
        const ValidationFailure(message: 'Password baru minimal 8 karakter.'),
      );
    }
    if (newPassword != confirmPassword) {
      return Result.failure(
        const ValidationFailure(message: 'Konfirmasi password baru tidak cocok.'),
      );
    }
    if (newPassword == currentPassword) {
      return Result.failure(
        const ValidationFailure(
          message: 'Password baru harus berbeda dengan password lama.',
        ),
      );
    }
    if (user != null) {
      return Result.success(user!.copyWith(mustChangePassword: false));
    }
    return Result.failure(
      const UnauthorizedFailure(message: 'Pengguna tidak ditemukan.'),
    );
  }
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
              'message':
                  'Daftar pengajuan mutasi untuk Bagian Aset berhasil diambil.',
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
                    'location': {'id': 1, 'name': 'Gedung A Lantai 1'},
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

      final apiClient = ApiClient(
        httpClient: mockClient,
        baseUrl: 'http://test.local',
      );
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

      final apiClient = ApiClient(
        httpClient: mockClient,
        baseUrl: 'http://test.local',
      );

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

      container.read(kabagStatusFilterProvider.notifier).state =
          KabagStatusFilter.waiting;
      final waitingList =
          container.read(filteredKabagApprovalsProvider).value ?? [];
      expect(waitingList.length, 1);
      expect(waitingList.first.ticketNumber, 'KBG-001');

      container.read(kabagStatusFilterProvider.notifier).state =
          KabagStatusFilter.all;
      final allList =
          container.read(filteredKabagApprovalsProvider).value ?? [];
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

      final apiClient = ApiClient(
        httpClient: mockClient,
        baseUrl: 'http://test.local',
      );

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

      final apiClient = ApiClient(
        httpClient: mockClient,
        baseUrl: 'http://test.local',
      );

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
                  'location': {'id': 1, 'name': 'Gedung A Lantai 1'},
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

      final apiClient = ApiClient(
        httpClient: mockClient,
        baseUrl: 'http://test.local',
      );

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          authStateProvider.overrideWith((ref) => _TestAuthNotifier(kabagUser)),
        ],
      );

      final detail = await container.read(
        kabagMutationDetailProvider('301').future,
      );

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

      final apiClient = ApiClient(
        httpClient: mockClient,
        baseUrl: 'http://test.local',
      );

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          authStateProvider.overrideWith((ref) => _TestAuthNotifier(kabagUser)),
        ],
      );

      expect(
        () => container.read(
          kabagMutationDetailProvider('non_existent_999').future,
        ),
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

      final apiClient = ApiClient(
        httpClient: mockClient,
        baseUrl: 'http://test.local',
      );

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

    test('8. Bagian Aset Verify Action: POST /api/v1/mutations/{id}/verify-asset dengan action: verify -> status transition ke menunggu_approval_pemimpin_divisi dan tracking step diperbarui', () async {
      String? verifyEndpoint;
      Map<String, dynamic>? verifyBody;
      var currentStatus = 'menunggu_verifikasi_bagian_aset';

      final baseJson = {
        'id': 301,
        'ticket_number': 'KBG-2026-00301',
        'applicant_id': 42,
        'applicant': {'id': 42, 'name': 'Rina Pemohon'},
        'asset': {
          'id': 15,
          'asset_code': 'AST-FUR-015',
          'name': 'Meja Kerja Ergonomis',
          'category': {'id': 2, 'code': 'FUR', 'name': 'Furnitur & Peralatan'},
          'location': {'id': 1, 'name': 'Gedung A Lantai 1'},
        },
        'origin_location': {'name': 'Gedung A Lantai 1'},
        'destination_location': {'name': 'Gedung B Lantai 3'},
        'current_pic': {'id': 42, 'name': 'Rina Pemohon'},
        'target_pic': {'id': 42, 'name': 'Rina Pemohon'},
        'is_asset_moves_with_applicant': true,
        'reason': 'Kebutuhan tim finance',
        'created_at': '2026-10-07T08:30:00Z',
      };

      final mockClient = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/api/v1/mutations/301/verify-asset') {
          verifyEndpoint = request.url.path;
          verifyBody = jsonDecode(request.body) as Map<String, dynamic>;
          currentStatus = 'menunggu_approval_pemimpin_divisi';
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Pengajuan mutasi berhasil diverifikasi dan diteruskan ke Pemimpin Divisi.',
              'data': {
                ...baseJson,
                'status': currentStatus,
                'asset_verified_at': '2026-10-07T11:00:00Z',
                'asset_verified_by': 'Yusuf Bagian Aset Asli',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET' &&
            request.url.path == '/api/v1/mutations/301') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                ...baseJson,
                'status': currentStatus,
                if (currentStatus == 'menunggu_approval_pemimpin_divisi') ...{
                  'asset_verified_at': '2026-10-07T11:00:00Z',
                  'asset_verified_by': 'Yusuf Bagian Aset Asli',
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final testApiClient = ApiClient(
        httpClient: mockClient,
        baseUrl: 'http://test.local',
      );
      final assetRepo = AssetRepositoryImpl();
      final mutationRepo = MutationRepositoryImpl(
        assetRepository: assetRepo,
        apiClient: testApiClient,
      );

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(testApiClient),
          apiMutationRepositoryProvider.overrideWithValue(mutationRepo),
          authStateProvider.overrideWith((ref) => _TestAuthNotifier(kabagUser)),
        ],
      );
      addTearDown(container.dispose);

      // Eksekusi aksi Bagian Aset verify & forward
      final success = await container
          .read(bagianAsetVerificationActionProvider.notifier)
          .verifyAndForward(mutationId: '301');

      expect(success, isTrue);
      expect(verifyEndpoint, equals('/api/v1/mutations/301/verify-asset'));
      expect(verifyBody, equals({'action': 'verify'}));

      // Pemohon / sistem membaca detail yang telah diperbarui
      final updatedDetail = await container.read(
        apiMutationDetailProvider('301').future,
      );

      expect(
        updatedDetail.status,
        equals(MutationStatus.waitingDivisionHeadApproval),
      );
      expect(
        updatedDetail.status.displayName,
        equals('Menunggu Approval Pemimpin Divisi'),
      );
      expect(updatedDetail.assetVerifiedBy, equals('Yusuf Bagian Aset Asli'));

      // Verifikasi timeline tracking
      final steps = MutationTrackingHelper.getStepsForMutation(
        updatedDetail.status,
        mutation: updatedDetail,
      );
      expect(steps[0].isCompleted, isTrue); // Step 1: Pengajuan Selesai
      expect(
        steps[1].isCompleted,
        isTrue,
      ); // Step 2: Pemeriksaan Operator Selesai (Lengkap)
      expect(steps[1].badgeText, equals('Lengkap'));
      expect(
        steps[2].isCompleted,
        isTrue,
      ); // Step 3: Verifikasi Bagian Aset Selesai (Valid)
      expect(steps[2].badgeText, equals('Valid'));
      expect(
        steps[3].isCurrent,
        isTrue,
      ); // Step 4: Approval Pemimpin Divisi Aktif
      expect(steps[3].badgeText, equals('Menunggu Approval'));
      expect(
        steps[4].isUpcoming,
        isTrue,
      ); // Step 5: Konfirmasi Pemohon Upcoming
    });

    test('9. Bagian Aset Return Action: POST /api/v1/mutations/{id}/verify-asset dengan action: return & reason -> status transition ke dikembalikan_ke_pemohon', () async {
      String? returnEndpoint;
      Map<String, dynamic>? returnBody;
      var currentStatus = 'menunggu_verifikasi_bagian_aset';

      const expectedReason =
          'Lokasi penempatan Gedung B belum siap secara fisik';
      final baseJson = {
        'id': 301,
        'ticket_number': 'KBG-2026-00301',
        'applicant_id': 42,
        'applicant': {'id': 42, 'name': 'Rina Pemohon'},
        'asset': {
          'id': 15,
          'asset_code': 'AST-FUR-015',
          'name': 'Meja Kerja Ergonomis',
          'category': {'id': 2, 'code': 'FUR', 'name': 'Furnitur & Peralatan'},
        },
        'origin_location': {'name': 'Gedung A Lantai 1'},
        'destination_location': {'name': 'Gedung B Lantai 3'},
        'current_pic': {'id': 42, 'name': 'Rina Pemohon'},
        'target_pic': {'id': 42, 'name': 'Rina Pemohon'},
        'is_asset_moves_with_applicant': true,
        'reason': 'Kebutuhan tim finance',
        'created_at': '2026-10-07T08:30:00Z',
      };

      final mockClient = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/api/v1/mutations/301/verify-asset') {
          returnEndpoint = request.url.path;
          returnBody = jsonDecode(request.body) as Map<String, dynamic>;
          currentStatus = 'dikembalikan_ke_pemohon';
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Pengajuan mutasi berhasil dikembalikan ke Pemohon.',
              'data': {
                ...baseJson,
                'status': currentStatus,
                'return_reason': expectedReason,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET' &&
            request.url.path == '/api/v1/mutations/301') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                ...baseJson,
                'status': currentStatus,
                if (currentStatus == 'dikembalikan_ke_pemohon') ...{
                  'return_reason': expectedReason,
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final testApiClient = ApiClient(
        httpClient: mockClient,
        baseUrl: 'http://test.local',
      );
      final assetRepo = AssetRepositoryImpl();
      final mutationRepo = MutationRepositoryImpl(
        assetRepository: assetRepo,
        apiClient: testApiClient,
      );

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(testApiClient),
          apiMutationRepositoryProvider.overrideWithValue(mutationRepo),
          authStateProvider.overrideWith((ref) => _TestAuthNotifier(kabagUser)),
        ],
      );
      addTearDown(container.dispose);

      // Eksekusi aksi Bagian Aset return
      final success = await container
          .read(bagianAsetVerificationActionProvider.notifier)
          .returnToApplicant(mutationId: '301', reason: expectedReason);

      expect(success, isTrue);
      expect(returnEndpoint, equals('/api/v1/mutations/301/verify-asset'));
      expect(
        returnBody,
        equals({'action': 'return', 'reason': expectedReason}),
      );

      // Pemohon membaca detail
      final returnedDetail = await container.read(
        apiMutationDetailProvider('301').future,
      );

      expect(returnedDetail.status, equals(MutationStatus.returned));
      expect(returnedDetail.returnReason, equals(expectedReason));
    });

    test('10. Kasus Pemohon Konfirmasi Fisik Tidak Sesuai: Mutasi kembali berstatus menunggu_verifikasi_bagian_aset dengan return_reason, muncul di queue dan terbaca di detail Bagian Aset', () async {
      var queueCalled = false;
      var detailCalled = false;
      const discrepancyReason = 'Serial number fisik berbeda dengan label sistem (SN fisik: SN-XYZ-999)';

      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/v1/mutations') {
          queueCalled = true;
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Daftar pengajuan mutasi untuk Bagian Aset berhasil diambil.',
              'data': [
                {
                  'id': 7,
                  'ticket_number': 'TI-2026-0007',
                  'applicant_id': 2,
                  'applicant': {'id': 2, 'name': 'Dirly Pemohon'},
                  'asset': {
                    'id': 1,
                    'asset_code': 'AST-ELK-2024-001',
                    'name': 'Laptop Lenovo ThinkPad T14',
                    'category': {'id': 1, 'code': 'ELK', 'name': 'Elektronik'},
                    'location': {'id': 1, 'name': 'Kantor Pusat'},
                  },
                  'status': 'menunggu_verifikasi_bagian_aset',
                  'return_reason': discrepancyReason,
                  'origin_location': {'name': 'Kantor Pusat'},
                  'destination_location': {'name': 'Gedung A'},
                  'is_asset_moves_with_applicant': true,
                  'reason': 'Rotasi unit kerja',
                  'created_at': '2026-10-08T03:00:00Z',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.method == 'GET' && request.url.path == '/api/v1/mutations/7') {
          detailCalled = true;
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Detail mutasi berhasil diambil.',
              'data': {
                'id': 7,
                'ticket_number': 'TI-2026-0007',
                'applicant_id': 2,
                'applicant': {'id': 2, 'name': 'Dirly Pemohon'},
                'asset': {
                  'id': 1,
                  'asset_code': 'AST-ELK-2024-001',
                  'name': 'Laptop Lenovo ThinkPad T14',
                  'category': {'id': 1, 'code': 'ELK', 'name': 'Elektronik'},
                  'location': {'id': 1, 'name': 'Kantor Pusat'},
                },
                'status': 'menunggu_verifikasi_bagian_aset',
                'return_reason': discrepancyReason,
                'origin_location': {'name': 'Kantor Pusat'},
                'destination_location': {'name': 'Gedung A'},
                'current_pic': {'id': 2, 'name': 'Dirly Pemohon'},
                'target_pic': {'id': 2, 'name': 'Dirly Pemohon'},
                'is_asset_moves_with_applicant': true,
                'reason': 'Rotasi unit kerja',
                'created_at': '2026-10-08T03:00:00Z',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('Not Found', 404);
      });

      final testApiClient = ApiClient(
        httpClient: mockClient,
        baseUrl: 'http://test.local',
      );
      final assetRepo = AssetRepositoryImpl();
      final mutationRepo = MutationRepositoryImpl(
        assetRepository: assetRepo,
        apiClient: testApiClient,
      );

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(testApiClient),
          apiMutationRepositoryProvider.overrideWithValue(mutationRepo),
          authStateProvider.overrideWith((ref) => _TestAuthNotifier(kabagUser)),
        ],
      );
      addTearDown(container.dispose);

      // 1. Ambil antrean Bagian Aset
      final queue = await container.read(bagianAsetAllMutationsProvider.future);
      expect(queueCalled, isTrue);
      expect(queue.length, 1);
      final item = queue.first;
      expect(item.id, equals('7'));
      expect(item.status, equals(MutationStatus.waitingAssetVerification));
      expect(item.returnReason, equals(discrepancyReason));

      // 2. Ambil detail Bagian Aset
      final detail = await container.read(
        bagianAsetMutationDetailProvider('7').future,
      );
      expect(detailCalled, isTrue);
      expect(detail.id, equals('7'));
      expect(detail.status, equals(MutationStatus.waitingAssetVerification));
      expect(detail.returnReason, equals(discrepancyReason));
      expect(detail.applicantName, equals('Dirly Pemohon'));
    });
  });
}
