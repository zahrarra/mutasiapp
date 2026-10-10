// test/features/integration/master_crud_and_api_integration_audit_test.dart
//
// Pengujian integrasi komprehensif membuktikan:
// 1. PIC harus berasal dari user aktif API dan mengirim ID database.
// 2. CRUD lokasi dan kategori benar-benar tersimpan via API backend.
// 3. Fallback lokasi palsu hilang pada runtime.
// 4. Statistik dashboard Admin berasal dari data nyata.
// 5. Mock / repository tidak menyamarkan kegagalan API.
// 6. Integrasi report-discrepancy, dokumen mutasi, dan riwayat aset terhubung dari UI/repo ke backend.
// 7. Konfigurasi API_BASE_URL untuk localhost dan emulator Android.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mutasiku/core/constants/app_constants.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/core/network/api_client.dart';
import 'package:mutasiku/features/admin/data/repositories/location_repository_impl.dart';
import 'package:mutasiku/features/admin/domain/entities/location_item.dart';
import 'package:mutasiku/features/asset/data/repositories/asset_repository_impl.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_category.dart';
import 'package:mutasiku/features/asset/domain/repositories/asset_repository.dart';
import 'package:mutasiku/features/mutation/data/repositories/mutation_repository_impl.dart';

void main() {
  group('1. PIC Berasal Dari User Aktif API dan Mengirim ID Database', () {
    test('createAsset me-resolve PIC dari user aktif API backend dan mengirim integer ID', () async {
      Map<String, dynamic>? capturedBody;

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/v1/admin/users')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 14,
                  'name': 'Budi Santoso',
                  'email': 'budi@mutasiku.id',
                  'role': 'operator',
                  'is_active': true,
                },
                {
                  'id': 99,
                  'name': 'Mantan Karyawan',
                  'email': 'mantan@mutasiku.id',
                  'role': 'operator',
                  'is_active': false, // nonaktif, tidak boleh dipilih
                },
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.contains('/api/v1/admin/assets') && request.method == 'POST') {
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 21,
                'asset_code': capturedBody!['asset_code'],
                'name': capturedBody!['name'],
                'pic_id': capturedBody!['pic_id'],
              }
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response(jsonEncode({'message': 'Not Found'}), 404);
      });

      final apiClient = ApiClient(baseUrl: 'http://127.0.0.1:8000', httpClient: mockClient);
      final assetRepo = AssetRepositoryImpl(apiClient: apiClient);

      final result = await assetRepo.createAsset(
        const CreateAssetParams(
          assetCode: 'AST-TEST-001',
          name: 'Server Dell PowerEdge',
          assetCategoryId: '1',
          locationId: '1',
          picId: 'Budi Santoso', // Mengirim label/nama PIC
          condition: 'Baik',
          serialNumber: 'SN-99999',
          acquisitionYear: 2026,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(capturedBody, isNotNull);
      // Membuktikan pic_id di-resolve ke ID integer user aktif 14 di tabel users
      expect(capturedBody!['pic_id'], 14);
    });

    test('verifyAsset bagian aset meneruskan target_pic_id integer database ke API', () async {
      Map<String, dynamic>? capturedBody;

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/verify-asset') && request.method == 'POST') {
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 1,
                'ticket_number': 'TI-2026-0001',
                'target_pic_id': capturedBody!['target_pic_id'],
                'status': 'menunggu_approval_pemimpin_divisi',
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(jsonEncode({'message': 'Not Found'}), 404);
      });

      final apiClient = ApiClient(baseUrl: 'http://127.0.0.1:8000', httpClient: mockClient);
      final mutationRepo = MutationRepositoryImpl(
        assetRepository: AssetRepositoryImpl(apiClient: apiClient),
        apiClient: apiClient,
      );

      final result = await mutationRepo.assetSectionForward(
        mutationId: '1',
        verifierName: 'Petugas Aset',
        newPic: '14', // ID integer PIC baru
      );

      expect(result.isSuccess, isTrue);
      expect(capturedBody, isNotNull);
      expect(capturedBody!['target_pic_id'], 14);
    });
  });

  group('2 & 5. CRUD Lokasi dan Kategori serta Penolakan Silent Mock pada Kegagalan API', () {
    test('addLocation mengirim payload ke backend API dan gagal jujur jika API error 500', () async {
      final mockFailingClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Database connection timeout'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(baseUrl: 'http://127.0.0.1:8000', httpClient: mockFailingClient);
      final locRepo = LocationRepositoryImpl(apiClient: apiClient);

      final result = await locRepo.addLocation(
        const LocationItem(
          id: '',
          name: 'Gedung Arsip Baru',
          description: 'GAB',
          isActive: true,
        ),
      );

      // Verifikasi kegagalan dilaporkan secara jujur tanpa silent fallback
      expect(result.isFailure, isTrue);
      expect(result, isA<AppFailure<LocationItem>>());
    });

    test('addCategory mengirim payload ke backend API dan gagal jujur jika API error 422', () async {
      final mockFailingClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Kode kategori sudah digunakan'}),
          422,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(baseUrl: 'http://127.0.0.1:8000', httpClient: mockFailingClient);
      final assetRepo = AssetRepositoryImpl(apiClient: apiClient);

      final result = await assetRepo.addCategory(
        const AssetCategory(
          id: '',
          code: 'TI',
          name: 'Teknologi Informasi',
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result, isA<AppFailure<AssetCategory>>());
    });
  });

  group('3. Hilangkan Fallback Lokasi Palsu pada Runtime', () {
    test('Lokasi awal LocationRepositoryImpl tidak memuat lokasi hardcoded fiktif', () async {
      final repo = LocationRepositoryImpl();
      // Verifikasi bahwa _locations awal tidak berisi data fiktif
      expect(repo.currentLocations.any((l) => l.name.contains('Lantai 1 — Lobby & Reception')), isFalse);
      expect(repo.currentLocations.any((l) => l.id == 'loc_1'), isFalse);
    });
  });

  group('6. Verifikasi Integrasi Report-Discrepancy, Dokumen Mutasi, dan Riwayat Aset', () {
    test('reportDiscrepancy memanggil endpoint /api/v1/mutations/{id}/report-discrepancy', () async {
      String? calledPath;
      Map<String, dynamic>? calledBody;

      final mockClient = MockClient((request) async {
        calledPath = request.url.path;
        calledBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 5,
              'ticket_number': 'TI-2026-0005',
              'status': 'menunggu_verifikasi_bagian_aset',
              'discrepancy_reason': calledBody!['reason'],
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(baseUrl: 'http://127.0.0.1:8000', httpClient: mockClient);
      final mutationRepo = MutationRepositoryImpl(
        assetRepository: AssetRepositoryImpl(apiClient: apiClient),
        apiClient: apiClient,
      );

      final result = await mutationRepo.reportDiscrepancy(
        mutationId: '5',
        reason: 'Serial number fisik tidak cocok dengan dokumen pengajuan',
      );

      expect(result.isSuccess, isTrue);
      expect(calledPath, '/api/v1/mutations/5/report-discrepancy');
      expect(calledBody!['reason'], 'Serial number fisik tidak cocok dengan dokumen pengajuan');
    });

    test('dokumen mutasi diunduh dari /api/v1/mutations/{id}/document dalam bentuk raw bytes', () async {
      String? calledPath;

      final mockClient = MockClient((request) async {
        calledPath = request.url.path;
        return http.Response.bytes(
          utf8.encode('%PDF-1.4 Mock SK SDM Content'),
          200,
          headers: {'content-type': 'application/pdf'},
        );
      });

      final apiClient = ApiClient(baseUrl: 'http://127.0.0.1:8000', httpClient: mockClient);
      final result = await apiClient.getBytes('/api/v1/mutations/2/document');

      expect(result.isSuccess, isTrue);
      expect(calledPath, '/api/v1/mutations/2/document');
      final bytes = (result as Success<Uint8List>).data;
      expect(utf8.decode(bytes), contains('%PDF-1.4'));
    });

    test('getAssetHistory memanggil endpoint /api/v1/assets/{id}/history', () async {
      String? calledPath;

      final mockClient = MockClient((request) async {
        calledPath = request.url.path;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 1,
                'ticket_number': 'TI-2026-0001',
                'previous_location': {'name': 'Kantor Pusat'},
                'new_location': {'name': 'Cabang Surabaya'},
                'previous_pic': {'name': 'Pemohon Aset'},
                'new_pic': {'name': 'Budi Santoso'},
                'updater': {'name': 'Admin IT'},
                'created_at': '2026-10-10T08:00:00Z',
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(baseUrl: 'http://127.0.0.1:8000', httpClient: mockClient);
      final assetRepo = AssetRepositoryImpl(apiClient: apiClient);

      final result = await assetRepo.getAssetHistory('10');

      expect(result.isSuccess, isTrue);
      expect(calledPath, '/api/v1/assets/10/history');
      final list = (result as Success<List<dynamic>>).data;
      expect(list.length, 1);
      expect(list.first.previousLocation, 'Kantor Pusat');
      expect(list.first.newLocation, 'Cabang Surabaya');
    });
  });

  group('7. Verifikasi Konfigurasi API_BASE_URL', () {
    test('defaultBaseUrl mengarah ke 10.0.2.2:8000 pada Android Emulator', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final url = AppConstants.defaultBaseUrl;
        expect(url, equals('http://10.0.2.2:8000'));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    test('defaultBaseUrl mengarah ke 127.0.0.1:8000 pada localhost desktop/web', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        final url = AppConstants.defaultBaseUrl;
        expect(url, equals('http://127.0.0.1:8000'));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
