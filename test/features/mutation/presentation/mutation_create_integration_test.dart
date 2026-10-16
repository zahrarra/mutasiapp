import 'package:mutasiku/core/errors/failures.dart';
// test/features/mutation/presentation/mutation_create_integration_test.dart
//
// Integration & Provider Tests:
// Memverifikasi flow CREATE -> Response mutation_id -> Diteruskan ke Detail Mutasi.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:mutasiku/app/router/route_names.dart';
import 'package:mutasiku/core/network/api_client.dart';
import 'package:mutasiku/core/providers/core_providers.dart';
import 'package:mutasiku/features/asset/data/repositories/asset_repository_impl.dart';
import 'package:mutasiku/features/auth/domain/entities/user.dart';
import 'package:mutasiku/features/auth/domain/entities/user_role.dart';
import 'package:mutasiku/features/auth/presentation/providers/auth_provider.dart';
import 'package:mutasiku/features/mutation/data/repositories/mutation_repository_impl.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';
import 'package:mutasiku/features/mutation/presentation/widgets/mutation_submit_success_dialog.dart';
import 'package:mutasiku/features/pemohon/presentation/screens/pemohon_mutation_detail_screen.dart';

import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/features/auth/domain/repositories/auth_repository.dart';
import 'package:mutasiku/features/auth/domain/usecases/login_usecase.dart';
import 'package:mutasiku/features/auth/domain/usecases/logout_usecase.dart';

class _MockAuthRepo implements AuthRepository {
  final User? user;
  _MockAuthRepo(this.user);
  @override
  Future<Result<User?>> getCurrentUser() async => Result.success(user);
  @override
  Future<Result<User>> login({
    required String username,
    required String password,
  }) async => Result.success(user!);
  @override
  Future<void> logout() async {}
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

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(User? user)
    : super(
        loginUseCase: LoginUseCase(repository: _MockAuthRepo(user)),
        logoutUseCase: LogoutUseCase(repository: _MockAuthRepo(user)),
        authRepository: _MockAuthRepo(user),
      ) {
    state = AuthState(isLoading: false, user: user);
  }
}

void main() {
  const pemohonUser = User(
    id: '2',
    username: 'pemohon',
    name: 'Pemohon MutasiKu',
    role: UserRole.pemohon,
    email: 'pemohon@mutasiku.test',
    isActive: true,
  );

  final sampleCreatedJson = {
    'id': 77,
    'mutation_id': 77,
    'ticket_number': 'TI-2026-00077',
    'asset_id': 1,
    'applicant_id': 2,
    'origin_location_id': 1,
    'destination_location_id': 2,
    'current_pic_id': 2,
    'target_pic_id': 2,
    'is_asset_moves_with_applicant': true,
    'reason': 'Pindah tugas ke divisi baru',
    'sk_document': 'documents/sk_sdm/sk77.pdf',
    'status': 'diajukan',
    'created_at': '2026-10-07T12:00:00.000Z',
    'asset': {
      'id': 1,
      'asset_code': 'AST-ELK-2024-001',
      'name': 'Laptop Lenovo ThinkPad T14',
      'category': {'id': 1, 'code': 'TI', 'name': 'Aset TI'},
      'location': {'id': 1, 'name': 'Kantor Pusat'},
      'pic': {'id': 2, 'name': 'Pemohon MutasiKu'},
    },
    'applicant': {'id': 2, 'name': 'Pemohon MutasiKu'},
    'origin_location': {'id': 1, 'name': 'Kantor Pusat'},
    'destination_location': {'id': 2, 'name': 'Gedung A'},
    'current_pic': {'id': 2, 'name': 'Pemohon MutasiKu'},
    'target_pic': {'id': 2, 'name': 'Pemohon MutasiKu'},
  };

  group('Mutation CREATE to Detail Integration Tests', () {
    test(
      'submit mutation returns backend ID and passes it to detail screen',
      () async {
        String? requestedDetailId;

        final mockClient = MockClient((request) async {
          if (request.method == 'POST' &&
              request.url.path == '/api/v1/mutations') {
            return http.Response(
              jsonEncode({
                'success': true,
                'message': 'Pengajuan mutasi berhasil dibuat.',
                'data': sampleCreatedJson,
              }),
              201,
              headers: {'content-type': 'application/json'},
            );
          }

          if (request.method == 'GET' &&
              request.url.path == '/api/v1/mutations/77') {
            requestedDetailId = '77';
            return http.Response(
              jsonEncode({'success': true, 'data': sampleCreatedJson}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          return http.Response('Not Found', 404);
        });

        final apiClient = ApiClient(
          httpClient: mockClient,
          baseUrl: 'http://test.local',
        );
        final assetRepo = AssetRepositoryImpl();
        final realRepo = MutationRepositoryImpl(
          assetRepository: assetRepo,
          apiClient: apiClient,
        );

        final container = ProviderContainer(
          overrides: [
            apiClientProvider.overrideWithValue(apiClient),
            apiMutationRepositoryProvider.overrideWithValue(realRepo),
            authStateProvider.overrideWith(
              (ref) => _FakeAuthNotifier(pemohonUser),
            ),
          ],
        );
        addTearDown(container.dispose);

        // 1. Submit mutation through SubmitMutationNotifier
        final submitNotifier = container.read(submitMutationProvider.notifier);

        final submitted = await submitNotifier.submit(
          const SubmitMutationParams(
            applicantId: '2',
            assetId: '1',
            sourceLocation: 'Kantor Pusat',
            targetLocation: '2',
            targetPic: 'Pemohon MutasiKu',
            reason: 'Pindah tugas ke divisi baru',
            documentName: 'SK-SDM-2026-001.pdf',
          ),
        );

        // Verify ID returned from backend
        expect(submitted, isNotNull);
        expect(submitted!.id, equals('77'));
        expect(submitted.ticketNumber, equals('TI-2026-00077'));
        expect(submitted.status, equals(MutationStatus.submitted));

        // 2. Lookup detail using pemohonMutationDetailProvider with the returned ID '77'
        final detail = await container.read(
          pemohonMutationDetailProvider('77').future,
        );

        expect(requestedDetailId, equals('77'));
        expect(detail.id, equals('77'));
        expect(detail.ticketNumber, equals('TI-2026-00077'));
        expect(detail.reason, equals('Pindah tugas ke divisi baru'));
        expect(detail.targetLocation, equals('Gedung A'));
      },
    );

    testWidgets(
      'Detail Mutasi Screen renders correctly when navigated with mutationId from CREATE',
      (tester) async {
        final mockClient = MockClient((request) async {
          if (request.url.path == '/api/v1/mutations/77') {
            return http.Response(
              jsonEncode({'success': true, 'data': sampleCreatedJson}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('Not Found', 404);
        });

        final apiClient = ApiClient(
          httpClient: mockClient,
          baseUrl: 'http://test.local',
        );
        final assetRepo = AssetRepositoryImpl();
        final realRepo = MutationRepositoryImpl(
          assetRepository: assetRepo,
          apiClient: apiClient,
        );

        final router = GoRouter(
          initialLocation: RouteNames.pemohonMutasiDetailPath.replaceFirst(
            ':id',
            '77',
          ),
          routes: [
            GoRoute(
              path: RouteNames.pemohonMutasiDetailPath,
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? '77';
                return PemohonMutationDetailScreen(mutationId: id);
              },
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              apiClientProvider.overrideWithValue(apiClient),
              apiMutationRepositoryProvider.overrideWithValue(realRepo),
              authStateProvider.overrideWith(
                (ref) => _FakeAuthNotifier(pemohonUser),
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.pumpAndSettle();

        // Verify detail screen loads data of mutation 77
        expect(find.text('TI-2026-00077'), findsOneWidget);
        expect(find.text('Laptop Lenovo ThinkPad T14'), findsWidgets);
        expect(find.text('Pindah tugas ke divisi baru'), findsWidgets);
        expect(find.text('Kantor Pusat'), findsWidgets);
      },
    );

    testWidgets(
      'Full UI flow: Success dialog button "Lihat Status Tracking" navigates to Detail Screen with exact CREATE mutationId and shows Step 1 done & Step 2 active',
      (tester) async {
        final mockClient = MockClient((request) async {
          if (request.url.path == '/api/v1/mutations/77') {
            return http.Response(
              jsonEncode({'success': true, 'data': sampleCreatedJson}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('Not Found', 404);
        });

        final apiClient = ApiClient(
          httpClient: mockClient,
          baseUrl: 'http://test.local',
        );
        final assetRepo = AssetRepositoryImpl();
        final realRepo = MutationRepositoryImpl(
          assetRepository: assetRepo,
          apiClient: apiClient,
        );

        final router = GoRouter(
          initialLocation: '/pemohon/create-modal-test',
          routes: [
            GoRoute(
              path: '/pemohon/create-modal-test',
              builder: (context, state) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      key: const Key('trigger_dialog_btn'),
                      onPressed: () {
                        // Simulasi pemanggilan dialog seperti pada PemohonCreateMutationScreen
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const MutationSubmitSuccessDialog(
                            ticketNumber: 'TI-2026-00077',
                            mutationId: '77',
                          ),
                        );
                      },
                      child: const Text('Buka Dialog'),
                    ),
                  ),
                );
              },
            ),
            GoRoute(
              path: RouteNames.pemohonMutasiDetailPath,
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                return PemohonMutationDetailScreen(mutationId: id);
              },
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              apiClientProvider.overrideWithValue(apiClient),
              apiMutationRepositoryProvider.overrideWithValue(realRepo),
              authStateProvider.overrideWith(
                (ref) => _FakeAuthNotifier(pemohonUser),
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Trigger success dialog
        await tester.tap(find.byKey(const Key('trigger_dialog_btn')));
        await tester.pumpAndSettle();

        // 2. Verify dialog is open and displays ticket TI-2026-00077
        expect(find.text('Pengajuan Berhasil Dikirim'), findsOneWidget);
        expect(find.text('TI-2026-00077'), findsOneWidget);

        // 3. Tap "Lihat Status Tracking"
        final viewTrackingBtn = find.byKey(
          const Key('btn_success_view_tracking'),
        );
        expect(viewTrackingBtn, findsOneWidget);
        await tester.tap(viewTrackingBtn);
        await tester.pumpAndSettle();

        // 4. Verify we navigated to Detail screen for ID 77
        expect(find.byType(PemohonMutationDetailScreen), findsOneWidget);
        expect(find.text('TI-2026-00077'), findsOneWidget);

        // 5. Verify status and timeline tracking: Step 1 completed, Step 2 active
        expect(find.text('Pelacakan Alur Kerja'), findsOneWidget);
        expect(find.textContaining('Pengajuan Mutasi'), findsWidgets);
        expect(
          find.textContaining('Pemeriksaan Kelengkapan Operator'),
          findsWidgets,
        );
        expect(find.text('Menunggu Pemeriksaan'), findsWidgets);
      },
    );

    test('submitMutation carries Authorization: Bearer <token> in multipart request', () async {
      String? capturedAuthHeader;

      final mockClient = MockClient((request) async {
        if (request.method == 'POST' && request.url.path == '/api/v1/mutations') {
          capturedAuthHeader = request.headers['Authorization'];
          return http.Response(
            jsonEncode({'success': true, 'data': sampleCreatedJson}),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        baseUrl: 'http://test.local',
        tokenGetter: () async => 'test_bearer_token_xyz',
      );
      final assetRepo = AssetRepositoryImpl();
      final realRepo = MutationRepositoryImpl(
        assetRepository: assetRepo,
        apiClient: apiClient,
      );

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          apiMutationRepositoryProvider.overrideWithValue(realRepo),
          authStateProvider.overrideWith(
            (ref) => _FakeAuthNotifier(pemohonUser),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(submitMutationProvider.notifier);
      final result = await notifier.submit(
        const SubmitMutationParams(
          applicantId: '2',
          assetId: '1',
          sourceLocation: 'Kantor Pusat',
          targetLocation: '2',
          targetPic: 'Pemohon Test',
          reason: 'Pindah kantor',
          documentName: 'sk_dokumen_resmi.pdf',
        ),
      );

      expect(result, isNotNull);
      expect(capturedAuthHeader, equals('Bearer test_bearer_token_xyz'));
      expect(result!.id, equals('77'));
    });

    test('submitMutation gracefully handles 401 Unauthorized Failure from backend', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'POST' && request.url.path == '/api/v1/mutations') {
          return http.Response(
            jsonEncode({'message': 'Unauthenticated.'}),
            401,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
        httpClient: mockClient,
        baseUrl: 'http://test.local',
      );
      final assetRepo = AssetRepositoryImpl();
      final realRepo = MutationRepositoryImpl(
        assetRepository: assetRepo,
        apiClient: apiClient,
      );

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          apiMutationRepositoryProvider.overrideWithValue(realRepo),
          authStateProvider.overrideWith(
            (ref) => _FakeAuthNotifier(pemohonUser),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(submitMutationProvider.notifier);
      final result = await notifier.submit(
        const SubmitMutationParams(
          applicantId: '2',
          assetId: '1',
          sourceLocation: 'Kantor Pusat',
          targetLocation: '2',
          targetPic: 'Pemohon Test',
          reason: 'Pindah kantor',
          documentName: 'sk_dokumen_resmi.pdf',
        ),
      );

      expect(result, isNull);
      final state = container.read(submitMutationProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, contains('Unauthenticated'));
    });
  });
}

