import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mutasiku/core/errors/failures.dart';
import 'package:mutasiku/core/network/api_client.dart';
import 'package:mutasiku/features/asset/data/repositories/asset_repository_impl.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_status.dart';
import 'package:mutasiku/features/mutation/data/repositories/mutation_repository_impl.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';

void main() {
  late AssetRepositoryImpl assetRepo;
  late MutationRepositoryImpl mutationRepo;

  setUp(() {
    AssetRepositoryImpl.resetForTesting();
    MutationRepositoryImpl.resetForTesting();
    assetRepo = AssetRepositoryImpl();
    mutationRepo = MutationRepositoryImpl(assetRepository: assetRepo);
  });

  group('MutationRepositoryImpl - Registered Asset Submissions', () {
    test(
      'fetches asset from AssetRepository and snapshots location and PIC',
      () async {
        // ast_1 in mock is 'Laptop Lenovo ThinkPad T14 Gen 3'
        // location: 'Lantai 3 — Ruang IT Developer', pic: 'Budi Santoso (IT Dept)'
        final submitResult = await mutationRepo.submitMutation(
          const SubmitMutationParams(
            applicantId: 'usr_pemohon_1',
            applicantName: 'Pemohon Test',
            assetId: 'ast_1',
            sourceLocation: '', // Empty to test snapshotting from master asset
            targetLocation: 'Cabang Medan',
            targetPic: 'PIC Baru Medan',
            reason: 'Peremajaan cabang Medan',
          ),
        );

        expect(submitResult.isSuccess, isTrue);
        final mutation = submitResult.dataOrNull!;
        expect(mutation.assetId, equals('ast_1'));
        expect(mutation.isUnregisteredAsset, isFalse);
        expect(mutation.asset.name, equals('Laptop Lenovo ThinkPad T14 Gen 3'));
        // Snapshot harus diambil dari master asset
        expect(
          mutation.currentLocation,
          equals('Lantai 3 — Ruang IT Developer'),
        );
        expect(mutation.currentPic, equals('Budi Santoso (IT Dept)'));
        expect(mutation.status, equals(MutationStatus.submitted));
      },
    );

    test('master asset in AssetRepository location and pic remain unchanged during submission, status locked to inMutation', () async {
      final initialAsset = (await assetRepo.getAssetById('ast_1')).dataOrNull!;
      expect(initialAsset.location, equals('Lantai 3 — Ruang IT Developer'));
      expect(initialAsset.status, equals(AssetStatus.available));

      await mutationRepo.submitMutation(
        const SubmitMutationParams(
          applicantId: 'usr_pemohon_1',
          applicantName: 'Pemohon Test',
          assetId: 'ast_1',
          sourceLocation: 'Lantai 3 — Ruang IT Developer',
          targetLocation: 'Cabang Medan',
          targetPic: 'PIC Baru',
          reason: 'Kebutuhan mutasi',
        ),
      );

      // Verify master asset in asset repository location and pic are UNCHANGED during submission,
      // but asset is locked to inMutation per PRD V1.1 §8 Rule 5
      final afterAsset = (await assetRepo.getAssetById('ast_1')).dataOrNull!;
      expect(afterAsset.location, equals('Lantai 3 — Ruang IT Developer'));
      expect(afterAsset.pic, equals(initialAsset.pic));
      expect(afterAsset.status, equals(AssetStatus.inMutation));
      expect(afterAsset.hasActiveMutation, isTrue);
    });

    test('prevents duplicate active mutation for the same asset', () async {
      // First submission
      final firstResult = await mutationRepo.submitMutation(
        const SubmitMutationParams(
          applicantId: 'usr_pemohon_1',
          assetId: 'ast_1',
          sourceLocation: 'Lantai 3',
          targetLocation: 'Cabang A',
          targetPic: 'PIC A',
          reason: 'Mutasi pertama',
        ),
      );
      expect(firstResult.isSuccess, isTrue);

      // Second submission for the same asset while first is active (submitted)
      final secondResult = await mutationRepo.submitMutation(
        const SubmitMutationParams(
          applicantId: 'usr_pemohon_2',
          assetId: 'ast_1',
          sourceLocation: 'Lantai 3',
          targetLocation: 'Cabang B',
          targetPic: 'PIC B',
          reason: 'Mutasi kedua aset sama',
        ),
      );

      expect(secondResult.isFailure, isTrue);
      expect(
        secondResult.failureOrNull?.userMessage,
        contains('sedang memiliki pengajuan mutasi aktif'),
      );
    });
  });

  group('MutationRepositoryImpl - Unregistered Asset Submissions (PRD V1.1 §8 Rule 3)', () {
    test(
      'rejects unregistered asset with isUnregisteredAsset == true',
      () async {
        final submitResult = await mutationRepo.submitMutation(
          const SubmitMutationParams(
            applicantId: 'usr_pemohon_1',
            applicantName: 'Pemohon Test',
            assetId: null,
            isUnregisteredAsset: true,
            customAssetName: 'Printer Epson L3210 (Manual)',
            customSerialNumber: 'SN-UNREG-8821',
            sourceLocation: 'Gudang Lama',
            targetLocation: 'Cabang Semarang',
            currentPic: 'Pak Slamet',
            targetPic: 'Bu Siti',
            reason: 'Aset tidak terdaftar dari kantor cabang lama',
          ),
        );

        expect(submitResult.isFailure, isTrue);
        expect(submitResult.failureOrNull, isA<ValidationFailure>());
        expect(
          submitResult.failureOrNull?.userMessage,
          contains('Aset yang dimutasi harus merupakan aset terdaftar'),
        );
      },
    );

    test('rejects submission when assetId is null or empty', () async {
      final submitResult = await mutationRepo.submitMutation(
        const SubmitMutationParams(
          applicantId: 'usr_pemohon_1',
          applicantName: 'Pemohon Test',
          assetId: '',
          isUnregisteredAsset: false,
          sourceLocation: 'Lantai 2',
          targetLocation: 'Lantai 5',
          targetPic: 'Staff Umum',
          reason: 'Pindah ruang rapat',
        ),
      );

      expect(submitResult.isFailure, isTrue);
      expect(submitResult.failureOrNull, isA<ValidationFailure>());
    });
  });

  group(
    'MutationRepositoryImpl - API Integration Tests (/api/v1/mutations)',
    () {
      final sampleMutationJson = {
        'id': 101,
        'ticket_number': 'MUT-2026-00101',
        'asset_id': 15,
        'applicant_id': 2,
        'origin_location_id': 1,
        'destination_location_id': 2,
        'current_pic_id': 2,
        'target_pic_id': 3,
        'is_asset_moves_with_applicant': true,
        'reason': 'Pindah kantor cabang Surabaya',
        'sk_document': 'documents/sk_101.pdf',
        'status': 'diajukan',
        'return_reason': null,
        'rejection_reason': null,
        'created_at': '2026-10-06T10:00:00.000000Z',
        'updated_at': '2026-10-06T10:00:00.000000Z',
        'asset': {
          'id': 15,
          'asset_code': 'AST-0015',
          'name': 'MacBook Pro 16 M3',
          'category': {'id': 1, 'name': 'Elektronik', 'code': 'ELK'},
          'location': {'id': 1, 'name': 'Lantai 1 IT'},
          'pic': {'id': 2, 'name': 'Budi Santoso'},
          'condition': 'Baik',
          'serial_number': 'SN123456',
          'acquisition_year': 2024,
        },
        'applicant': {'id': 2, 'name': 'Budi Santoso'},
        'origin_location': {'id': 1, 'name': 'Lantai 1 IT'},
        'destination_location': {'id': 2, 'name': 'Lantai 2 Operasional'},
        'current_pic': {'id': 2, 'name': 'Budi Santoso'},
        'target_pic': {'id': 3, 'name': 'Siti Rahma'},
      };

      test('1. API mengembalikan list mutation -> berhasil dipetakan ke List<Mutation>', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.path, equals('/api/v1/mutations'));
          expect(request.method, equals('GET'));
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Daftar pengajuan mutasi berhasil diambil.',
              'data': [sampleMutationJson],
              'meta': {
                'current_page': 1,
                'last_page': 1,
                'per_page': 15,
                'total': 1,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(
          httpClient: mockClient,
          baseUrl: 'http://test.local',
        );
        final repoWithApi = MutationRepositoryImpl(
          assetRepository: assetRepo,
          apiClient: apiClient,
        );

        final result = await repoWithApi.getAllMutations();

        expect(result.isSuccess, isTrue);
        final list = result.dataOrNull!;
        expect(list.length, equals(1));
        expect(list[0].id, equals('101'));
        expect(list[0].ticketNumber, equals('MUT-2026-00101'));
        expect(list[0].status, equals(MutationStatus.submitted));
        expect(list[0].currentLocation, equals('Lantai 1 IT'));
        expect(list[0].targetLocation, equals('Lantai 2 Operasional'));
        expect(list[0].currentPic, equals('Budi Santoso'));
        expect(list[0].targetPic, equals('Siti Rahma'));
      });

      test('2. Response paginated berhasil diparse sebagai list', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                sampleMutationJson,
                {
                  ...sampleMutationJson,
                  'id': 102,
                  'ticket_number': 'MUT-2026-00102',
                  'status': 'selesai',
                },
              ],
              'meta': {
                'current_page': 2,
                'last_page': 4,
                'per_page': 15,
                'total': 50,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(
          httpClient: mockClient,
          baseUrl: 'http://test.local',
        );
        final repoWithApi = MutationRepositoryImpl(
          assetRepository: assetRepo,
          apiClient: apiClient,
        );

        final result = await repoWithApi.getAllMutations();

        expect(result.isSuccess, isTrue);
        final list = result.dataOrNull!;
        expect(list.length, equals(2));
        expect(list[0].id, equals('101'));
        expect(list[1].id, equals('102'));
        expect(list[1].status, equals(MutationStatus.completed));
      });

      test(
        '3. Response list kosong (data: []) berhasil ditangani tanpa error',
        () async {
          final mockClient = MockClient((request) async {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': [],
                'meta': {'current_page': 1, 'last_page': 1, 'total': 0},
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          });

          final apiClient = ApiClient(
            httpClient: mockClient,
            baseUrl: 'http://test.local',
          );
          final repoWithApi = MutationRepositoryImpl(
            assetRepository: assetRepo,
            apiClient: apiClient,
          );

          final result = await repoWithApi.getAllMutations();

          expect(result.isSuccess, isTrue);
          expect(result.dataOrNull, isEmpty);
        },
      );

      test('4. 401 Unauthorized menghasilkan UnauthorizedFailure', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({'success': false, 'message': 'Unauthenticated.'}),
            401,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(
          httpClient: mockClient,
          baseUrl: 'http://test.local',
        );
        apiClient.setAuthToken('expired_or_invalid_token');

        final repoWithApi = MutationRepositoryImpl(
          assetRepository: assetRepo,
          apiClient: apiClient,
        );
        final result = await repoWithApi.getAllMutations();

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<UnauthorizedFailure>());
      });

      test('5. 403 Forbidden menghasilkan ForbiddenFailure', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': false,
              'message': 'Anda tidak memiliki hak akses untuk mutasi ini.',
            }),
            403,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(
          httpClient: mockClient,
          baseUrl: 'http://test.local',
        );
        final repoWithApi = MutationRepositoryImpl(
          assetRepository: assetRepo,
          apiClient: apiClient,
        );

        final result = await repoWithApi.getMutationById('101');

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ForbiddenFailure>());
        expect(result.failureOrNull?.message, contains('hak akses'));
      });

      test('6. 500 / Network Error tidak menghapus token auth', () async {
        final mockClient500 = MockClient((request) async {
          return http.Response(
            jsonEncode({'message': 'Internal Server Error'}),
            500,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(
          httpClient: mockClient500,
          baseUrl: 'http://test.local',
        );
        apiClient.setAuthToken('valid_token_123');

        final repoWithApi = MutationRepositoryImpl(
          assetRepository: assetRepo,
          apiClient: apiClient,
        );
        final result = await repoWithApi.getAllMutations();

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ServerFailure>());

        // Token TIDAK boleh dihapus oleh ServerFailure (500)
        // Buktikan dengan request berikutnya header authorization tetap menyertakan token
        late String capturedAuthHeader;
        final mockClientEcho = MockClient((request) async {
          capturedAuthHeader = request.headers['Authorization'] ?? '';
          return http.Response(
            jsonEncode({'success': true, 'data': []}),
            200,
            headers: {'content-type': 'application/json'},
          );
        });
        final apiClientEcho = ApiClient(
          httpClient: mockClientEcho,
          baseUrl: 'http://test.local',
        );
        apiClientEcho.setAuthToken('valid_token_123');
        final repoEcho = MutationRepositoryImpl(
          assetRepository: assetRepo,
          apiClient: apiClientEcho,
        );
        await repoEcho.getAllMutations();
        expect(capturedAuthHeader, equals('Bearer valid_token_123'));
      });

      test('7. Malformed / schema-incompatible JSON response ditangani dengan aman tanpa crash', () async {
        final mockClientMalformed = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': 'invalid_string_instead_of_list_or_map',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(
          httpClient: mockClientMalformed,
          baseUrl: 'http://test.local',
        );
        final repoWithApi = MutationRepositoryImpl(
          assetRepository: assetRepo,
          apiClient: apiClient,
        );

        final result = await repoWithApi.getAllMutations();

        // listFromJson menghasilkan [] untuk format string tidak kompatibel
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, isEmpty);
      });

      test('8. Detail mutation (getMutationById) berhasil dipetakan dari GET /api/v1/mutations/{id}', () async {
        final mockClient = MockClient((request) async {
          if (request.url.path == '/api/v1/mutations/101') {
            return http.Response(
              jsonEncode({
                'success': true,
                'message': 'Detail pengajuan mutasi berhasil diambil.',
                'data': sampleMutationJson,
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode({
              'success': false,
              'message': 'Pengajuan mutasi tidak ditemukan.',
            }),
            404,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(
          httpClient: mockClient,
          baseUrl: 'http://test.local',
        );
        final repoWithApi = MutationRepositoryImpl(
          assetRepository: assetRepo,
          apiClient: apiClient,
        );

        // Detail sukses
        final detailResult = await repoWithApi.getMutationById('101');
        expect(detailResult.isSuccess, isTrue);
        final mutation = detailResult.dataOrNull!;
        expect(mutation.id, equals('101'));
        expect(mutation.ticketNumber, equals('MUT-2026-00101'));
        expect(mutation.applicantName, equals('Budi Santoso'));

        // 404 Not Found
        final notFoundResult = await repoWithApi.getMutationById('999');
        expect(notFoundResult.isFailure, isTrue);
        expect(notFoundResult.failureOrNull, isA<NotFoundFailure>());
      });

      test('9. getMutationsByUser memanggil GET /api/v1/mutations dan menyaring berdasarkan applicantId', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                sampleMutationJson, // applicant_id: 2
                {
                  ...sampleMutationJson,
                  'id': 105,
                  'ticket_number': 'MUT-2026-00105',
                  'applicant_id': 99,
                  'applicant': {'id': 99, 'name': 'User Lain'},
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(
          httpClient: mockClient,
          baseUrl: 'http://test.local',
        );
        final repoWithApi = MutationRepositoryImpl(
          assetRepository: assetRepo,
          apiClient: apiClient,
        );

        final result = await repoWithApi.getMutationsByUser('2');
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull!.length, equals(1));
        expect(result.dataOrNull!.first.id, equals('101'));
      });

      test('10. submitMutation memanggil POST /api/v1/mutations dan mengembalikan ID dari backend', () async {
        final mockClient = MockClient((request) async {
          expect(request.method, equals('POST'));
          expect(request.url.path, equals('/api/v1/mutations'));

          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Pengajuan mutasi berhasil dibuat.',
              'data': {
                ...sampleMutationJson,
                'id': 202,
                'mutation_id': 202,
                'ticket_number': 'MUT-2026-00202',
              },
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(
          httpClient: mockClient,
          baseUrl: 'http://test.local',
        );
        final repoWithApi = MutationRepositoryImpl(
          assetRepository: assetRepo,
          apiClient: apiClient,
        );

        final submitResult = await repoWithApi.submitMutation(
          const SubmitMutationParams(
            applicantId: '2',
            assetId: '1',
            sourceLocation: 'Kantor Pusat',
            targetLocation: '2',
            targetPic: 'Pemohon MutasiKu',
            reason: 'Pindah penugasan cabang',
          ),
        );

        expect(submitResult.isSuccess, isTrue);
        final created = submitResult.dataOrNull!;
        expect(created.id, equals('202'));
        expect(created.ticketNumber, equals('MUT-2026-00202'));
        expect(created.status, equals(MutationStatus.submitted));
      });

      test('11. submitMutation memetakan response 422 Unprocessable Entity ke ValidationFailure', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'message': 'Aset ini sedang dalam proses mutasi aktif.',
              'errors': {
                'asset_id': ['Aset ini sedang dalam proses mutasi aktif.'],
              },
            }),
            422,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(
          httpClient: mockClient,
          baseUrl: 'http://test.local',
        );
        final repoWithApi = MutationRepositoryImpl(
          assetRepository: assetRepo,
          apiClient: apiClient,
        );

        final submitResult = await repoWithApi.submitMutation(
          const SubmitMutationParams(
            applicantId: '2',
            assetId: '1',
            sourceLocation: 'Kantor Pusat',
            targetLocation: '2',
            targetPic: 'Pemohon MutasiKu',
            reason: 'Alasan mutasi',
          ),
        );

        expect(submitResult.isFailure, isTrue);
        expect(submitResult.failureOrNull, isA<ValidationFailure>());
        expect(
          submitResult.failureOrNull?.userMessage,
          contains('Aset ini sedang dalam proses mutasi aktif'),
        );
      });

      test('12. operatorForward memanggil POST /api/v1/mutations/{id}/verify dengan action verify', () async {
        final mockClient = MockClient((request) async {
          expect(request.method, equals('POST'));
          expect(request.url.path, equals('/api/v1/mutations/101/verify'));
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['action'], equals('verify'));

          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Pengajuan mutasi berhasil diverifikasi dan diteruskan ke Bagian Aset.',
              'data': {
                ...sampleMutationJson,
                'id': 101,
                'status': 'menunggu_verifikasi_bagian_aset',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(
          httpClient: mockClient,
          baseUrl: 'http://test.local',
        );
        final repoWithApi = MutationRepositoryImpl(
          assetRepository: assetRepo,
          apiClient: apiClient,
        );

        final result = await repoWithApi.operatorForward(
          mutationId: '101',
          operatorName: 'Operator MutasiKu',
        );

        expect(result.isSuccess, isTrue);
        final updated = result.dataOrNull!;
        expect(updated.id, equals('101'));
        expect(updated.status, equals(MutationStatus.waitingAssetVerification));
      });

      test('13. operatorReturn memanggil POST /api/v1/mutations/{id}/verify dengan action return dan reason', () async {
        final mockClient = MockClient((request) async {
          expect(request.method, equals('POST'));
          expect(request.url.path, equals('/api/v1/mutations/101/verify'));
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['action'], equals('return'));
          expect(body['reason'], equals('Dokumen SK tidak terbaca'));

          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Pengajuan mutasi berhasil dikembalikan ke Pemohon.',
              'data': {
                ...sampleMutationJson,
                'id': 101,
                'status': 'dikembalikan_ke_pemohon',
                'return_reason': 'Dokumen SK tidak terbaca',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(
          httpClient: mockClient,
          baseUrl: 'http://test.local',
        );
        final repoWithApi = MutationRepositoryImpl(
          assetRepository: assetRepo,
          apiClient: apiClient,
        );

        final result = await repoWithApi.operatorReturn(
          mutationId: '101',
          reason: 'Dokumen SK tidak terbaca',
          operatorName: 'Operator MutasiKu',
        );

        expect(result.isSuccess, isTrue);
        final updated = result.dataOrNull!;
        expect(updated.id, equals('101'));
        expect(updated.status, equals(MutationStatus.returned));
        expect(updated.returnReason, equals('Dokumen SK tidak terbaca'));
      });

      test('14. assetSectionForward memanggil POST /api/v1/mutations/{id}/verify-asset dengan action verify', () async {
        final mockClient = MockClient((request) async {
          expect(request.method, equals('POST'));
          expect(
            request.url.path,
            equals('/api/v1/mutations/101/verify-asset'),
          );
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['action'], equals('verify'));

          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Pengajuan mutasi berhasil diverifikasi dan diteruskan ke Pemimpin Divisi.',
              'data': {
                ...sampleMutationJson,
                'id': 101,
                'status': 'menunggu_approval_pemimpin_divisi',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(
          httpClient: mockClient,
          baseUrl: 'http://test.local',
        );
        final repoWithApi = MutationRepositoryImpl(
          assetRepository: assetRepo,
          apiClient: apiClient,
        );

        final result = await repoWithApi.assetSectionForward(
          mutationId: '101',
          verifierName: 'Staff Bagian Aset',
        );

        expect(result.isSuccess, isTrue);
        final updated = result.dataOrNull!;
        expect(updated.id, equals('101'));
        expect(
          updated.status,
          equals(MutationStatus.waitingDivisionHeadApproval),
        );
      });

      test('15. assetSectionReturn memanggil POST /api/v1/mutations/{id}/verify-asset dengan action return dan reason', () async {
        final mockClient = MockClient((request) async {
          expect(request.method, equals('POST'));
          expect(
            request.url.path,
            equals('/api/v1/mutations/101/verify-asset'),
          );
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['action'], equals('return'));
          expect(
            body['reason'],
            equals('Kondisi fisik aset rusak dan perlu perbaikan'),
          );

          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Pengajuan mutasi berhasil dikembalikan ke Pemohon.',
              'data': {
                ...sampleMutationJson,
                'id': 101,
                'status': 'dikembalikan_ke_pemohon',
                'return_reason': 'Kondisi fisik aset rusak dan perlu perbaikan',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(
          httpClient: mockClient,
          baseUrl: 'http://test.local',
        );
        final repoWithApi = MutationRepositoryImpl(
          assetRepository: assetRepo,
          apiClient: apiClient,
        );

        final result = await repoWithApi.assetSectionReturn(
          mutationId: '101',
          reason: 'Kondisi fisik aset rusak dan perlu perbaikan',
          verifierName: 'Staff Bagian Aset',
        );

        expect(result.isSuccess, isTrue);
        final updated = result.dataOrNull!;
        expect(updated.id, equals('101'));
        expect(updated.status, equals(MutationStatus.returned));
        expect(
          updated.returnReason,
          equals('Kondisi fisik aset rusak dan perlu perbaikan'),
        );
      });

      test('16. divisionApprove memanggil POST /api/v1/mutations/{id}/approve dengan action approve', () async {
        final mockClient = MockClient((request) async {
          expect(request.method, equals('POST'));
          expect(request.url.path, equals('/api/v1/mutations/101/approve'));
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['action'], equals('approve'));

          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Pengajuan mutasi berhasil disetujui dan menunggu konfirmasi fisik Pemohon.',
              'data': {
                ...sampleMutationJson,
                'id': 101,
                'status': 'menunggu_konfirmasi_pemohon',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(
          httpClient: mockClient,
          baseUrl: 'http://test.local',
        );
        final repoWithApi = MutationRepositoryImpl(
          assetRepository: assetRepo,
          apiClient: apiClient,
        );

        final result = await repoWithApi.divisionApprove(
          mutationId: '101',
          divisionHeadName: 'Kepala Divisi Operasional',
        );

        expect(result.isSuccess, isTrue);
        final updated = result.dataOrNull!;
        expect(updated.id, equals('101'));
        expect(updated.status, equals(MutationStatus.waitingConfirmation));
      });

      test('17. divisionReject memanggil POST /api/v1/mutations/{id}/reject dengan reason', () async {
        final mockClient = MockClient((request) async {
          expect(request.method, equals('POST'));
          expect(request.url.path, equals('/api/v1/mutations/101/reject'));
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(
            body['reason'],
            equals('Anggaran operasional tidak mencukupi untuk rotasi ini'),
          );

          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Pengajuan mutasi telah ditolak oleh Pemimpin Divisi.',
              'data': {
                ...sampleMutationJson,
                'id': 101,
                'status': 'ditolak',
                'rejection_reason':
                    'Anggaran operasional tidak mencukupi untuk rotasi ini',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = ApiClient(
          httpClient: mockClient,
          baseUrl: 'http://test.local',
        );
        final repoWithApi = MutationRepositoryImpl(
          assetRepository: assetRepo,
          apiClient: apiClient,
        );

        final result = await repoWithApi.divisionReject(
          mutationId: '101',
          reason: 'Anggaran operasional tidak mencukupi untuk rotasi ini',
          divisionHeadName: 'Kepala Divisi Operasional',
        );

        expect(result.isSuccess, isTrue);
        final updated = result.dataOrNull!;
        expect(updated.id, equals('101'));
        expect(updated.status, equals(MutationStatus.rejected));
        expect(
          updated.rejectionReason,
          equals('Anggaran operasional tidak mencukupi untuk rotasi ini'),
        );
      });
    },
  );
}
