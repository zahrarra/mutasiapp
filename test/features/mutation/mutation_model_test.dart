// test/features/mutation/mutation_model_test.dart
//
// Unit test komprehensif untuk MutationModel dan mapping status/nested-object
// dari response API Laravel (/api/v1/mutations).

import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/features/mutation/data/models/mutation_model.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';

void main() {
  group('MutationModel & Mapper Unit Tests', () {
    // ─── 1. Response Mutation Lengkap -> Menjadi Entity ─────────────────────
    test('1. Response mutation lengkap dari Laravel API berhasil dipetakan ke entity Mutation', () {
      final fullJson = {
        'id': 101,
        'ticket_number': 'MUT-2026-00101',
        'asset_id': 15,
        'applicant_id': 2,
        'origin_location_id': 1,
        'destination_location_id': 2,
        'current_pic_id': 2,
        'target_pic_id': 3,
        'is_asset_moves_with_applicant': true,
        'reason': 'Mutasi penugasan baru di Cabang Surabaya',
        'sk_document': 'documents/sk_mutasi_101.pdf',
        'status': 'menunggu_verifikasi_bagian_aset',
        'return_reason': null,
        'rejection_reason': null,
        'created_at': '2026-10-06T10:30:00.000000Z',
        'updated_at': '2026-10-06T10:30:00.000000Z',
        'asset': {
          'id': 15,
          'asset_code': 'AST-2026-0015',
          'name': 'MacBook Pro 16 M3',
          'asset_category_id': 1,
          'category': {'id': 1, 'name': 'Elektronik & IT', 'code': 'ELK'},
          'location_id': 1,
          'location': {
            'id': 1,
            'name': 'Lantai 1 - Divisi IT',
            'code': 'L1-IT',
          },
          'pic_id': 2,
          'pic': {
            'id': 2,
            'name': 'Ahmad Fauzi',
            'email': 'ahmad@mutasiku.test',
          },
          'condition': 'Baik',
          'serial_number': 'C02G1234MD6R',
          'acquisition_year': 2024,
          'usage_year': 2,
          'estimated_value': 35000000.0,
          'is_active': true,
        },
        'applicant': {
          'id': 2,
          'name': 'Ahmad Fauzi',
          'email': 'ahmad@mutasiku.test',
          'nip': '199501012020121001',
          'role_id': 2,
          'role': 'pemohon',
        },
        'origin_location': {
          'id': 1,
          'name': 'Lantai 1 - Divisi IT',
          'code': 'L1-IT',
        },
        'destination_location': {
          'id': 2,
          'name': 'Lantai 3 - Ruang Operasional',
          'code': 'L3-OPS',
        },
        'current_pic': {
          'id': 2,
          'name': 'Ahmad Fauzi',
          'email': 'ahmad@mutasiku.test',
        },
        'target_pic': {
          'id': 3,
          'name': 'Siti Rahma',
          'email': 'siti@mutasiku.test',
        },
      };

      final model = MutationModel.fromJson(fullJson);

      // Verifikasi instance & tipe
      expect(model, isA<Mutation>());
      expect(model.id, equals('101'));
      expect(model.ticketNumber, equals('MUT-2026-00101'));
      expect(model.assetId, equals('15'));
      expect(model.applicantId, equals('2'));
      expect(model.applicantName, equals('Ahmad Fauzi'));
      expect(model.currentLocation, equals('Lantai 1 - Divisi IT'));
      expect(model.targetLocation, equals('Lantai 3 - Ruang Operasional'));
      expect(model.currentPic, equals('Ahmad Fauzi'));
      expect(model.targetPic, equals('Siti Rahma'));
      expect(model.reason, equals('Mutasi penugasan baru di Cabang Surabaya'));
      expect(model.documentPath, equals('documents/sk_mutasi_101.pdf'));
      expect(model.documentName, equals('sk_mutasi_101.pdf'));
      expect(model.status, equals(MutationStatus.waitingAssetVerification));
      expect(model.isAssetMovingWithApplicant, isTrue);
      expect(model.returnReason, isNull);
      expect(model.rejectionReason, isNull);
      expect(model.createdAt.year, equals(2026));

      // Verifikasi nested asset
      final asset = model.asset;
      expect(asset.id, equals('15'));
      expect(asset.assetCode, equals('AST-2026-0015'));
      expect(asset.name, equals('MacBook Pro 16 M3'));
      expect(asset.category.name, equals('Elektronik & IT'));
      expect(asset.category.code, equals('ELK'));
      expect(asset.serialNumber, equals('C02G1234MD6R'));
      expect(asset.acquisitionYear, equals(2024));
      expect(asset.estimatedValue, equals(35000000.0));

      // Verifikasi toEntity()
      final entity = model.toEntity();
      expect(entity, isA<Mutation>());
      expect(entity.id, equals(model.id));
    });

    // ─── 2. Pemetaan Seluruh Status Backend yang Valid ───────────────────────
    test('2. Semua status API backend yang valid terpetakan ke enum Flutter dengan benar', () {
      final statusMap = {
        'diajukan': MutationStatus.submitted,
        'menunggu_verifikasi_bagian_aset':
            MutationStatus.waitingAssetVerification,
        'dikembalikan_ke_pemohon': MutationStatus.returned,
        'menunggu_approval_pemimpin_divisi':
            MutationStatus.waitingDivisionHeadApproval,
        'ditolak': MutationStatus.rejected,
        'menunggu_konfirmasi_pemohon': MutationStatus.waitingConfirmation,
        'selesai': MutationStatus.completed,
      };

      for (final entry in statusMap.entries) {
        final parsed = MutationStatus.fromApiValue(entry.key);
        expect(
          parsed,
          equals(entry.value),
          reason: 'Backend status "${entry.key}" gagal dipetakan',
        );

        // Pastikan apiValue round-trip konsisten
        expect(
          parsed.apiValue,
          equals(entry.key),
          reason:
              'apiValue dari ${entry.value} tidak sesuai dengan ${entry.key}',
        );

        // Test melalui MutationModel.fromJson
        final model = MutationModel.fromJson({
          'id': 1,
          'ticket_number': 'T-001',
          'status': entry.key,
          'reason': 'Test',
        });
        expect(model.status, equals(entry.value));
      }

      // Status unknown atau null aman -> fallback ke submitted
      expect(
        MutationStatus.fromApiValue(null),
        equals(MutationStatus.submitted),
      );
      expect(
        MutationStatus.fromApiValue('unknown_status_xyz'),
        equals(MutationStatus.submitted),
      );
      expect(MutationStatus.fromApiValue(''), equals(MutationStatus.submitted));
    });

    // ─── 3. Pemetaan Nested Object (origin_location & current_pic) ───────────
    test('3. Nested origin_location, destination_location, current_pic, target_pic (.name) terbaca benar', () {
      final json = {
        'id': 201,
        'ticket_number': 'T-201',
        'status': 'diajukan',
        'reason': 'Test mapping',
        'origin_location': {
          'id': 10,
          'name': 'Gedung Pusat Lantai 2',
          'code': 'GP-02',
        },
        'destination_location': {
          'id': 20,
          'name': 'Kantor Cabang Bandung',
          'code': 'KC-BDG',
        },
        'current_pic': {
          'id': 4,
          'name': 'Budi Santoso',
          'email': 'budi@test.com',
        },
        'target_pic': {
          'id': 5,
          'name': 'Citra Dewi',
          'email': 'citra@test.com',
        },
        'applicant': {'id': 4, 'name': 'Budi Santoso'},
      };

      final model = MutationModel.fromJson(json);

      expect(model.currentLocation, equals('Gedung Pusat Lantai 2'));
      expect(model.targetLocation, equals('Kantor Cabang Bandung'));
      expect(model.currentPic, equals('Budi Santoso'));
      expect(model.targetPic, equals('Citra Dewi'));
      expect(model.applicantName, equals('Budi Santoso'));
    });

    // ─── 4. Nested Object Null Tidak Menyebabkan Crash ──────────────────────
    test('4. Nested objects bernilai null tidak menyebabkan crash dan memiliki fallback aman', () {
      final jsonWithNulls = {
        'id': 301,
        'ticket_number': 'T-301',
        'status': 'diajukan',
        'reason': 'Aset ditinggalkan tanpa PIC tujuan',
        'origin_location': null,
        'destination_location': null,
        'current_pic': null,
        'target_pic': null,
        'applicant': null,
        'asset': null,
      };

      final model = MutationModel.fromJson(jsonWithNulls);

      expect(model.id, equals('301'));
      expect(model.currentLocation, equals('Lokasi Asal'));
      expect(model.targetLocation, equals('Lokasi Tujuan'));
      expect(model.currentPic, equals('-'));
      expect(model.targetPic, equals('-'));
      expect(model.applicantName, equals('Pemohon'));

      // Asset getter fallback aman tanpa crash
      final asset = model.asset;
      expect(asset.name, equals('Aset Tidak Terdaftar'));
      expect(asset.category.name, equals('Tidak Terdaftar'));
    });

    // ─── 5. Field Nullable Tidak Menyebabkan Crash ─────────────────────────
    test('5. Seluruh field opsional / nullable ditoleransi tanpa crash', () {
      final minimalJson = {'id': 401, 'ticket_number': 'T-401'};

      final model = MutationModel.fromJson(minimalJson);

      expect(model.id, equals('401'));
      expect(model.ticketNumber, equals('T-401'));
      expect(model.reason, isEmpty);
      expect(model.status, equals(MutationStatus.submitted));
      expect(model.documentPath, isNull);
      expect(model.documentName, isNull);
      expect(model.returnReason, isNull);
      expect(model.rejectionReason, isNull);
      expect(model.confirmationReason, isNull);
      expect(model.verifiedAt, isNull);
      expect(model.approvedAt, isNull);
      expect(model.rejectedAt, isNull);
      expect(model.kadivApprovedAt, isNull);
      expect(model.staffUpdatedAt, isNull);
      expect(model.isAssetMovingWithApplicant, isTrue);
    });

    // ─── 6. Toleran Terhadap Unknown / Extra Fields ─────────────────────────
    test('6. Response dengan field tak dikenal atau ekstra ditoleransi tanpa error', () {
      final jsonWithExtraFields = {
        'id': 501,
        'ticket_number': 'T-501',
        'status': 'dikembalikan_ke_pemohon',
        'reason': 'Perbaikan dokumen',
        'return_reason': 'Foto bukti buram',
        'unexpected_backend_flag': 12345,
        'debug_info': {'server': 'ip-10-0-1', 'node': 3},
        'metadata_custom': ['tag1', 'tag2'],
      };

      final model = MutationModel.fromJson(jsonWithExtraFields);

      expect(model.id, equals('501'));
      expect(model.status, equals(MutationStatus.returned));
      expect(model.returnReason, equals('Foto bukti buram'));
      expect(model.reason, equals('Perbaikan dokumen'));
    });

    // ─── 7. Parsing Response Pagination List ────────────────────────────────
    test('7. Pagination response dari backend Laravel (/api/v1/mutations) dipetakan sebagai list & metadata', () {
      final paginatedPayload = {
        'success': true,
        'message': 'Daftar pengajuan mutasi berhasil diambil.',
        'data': [
          {
            'id': 1,
            'ticket_number': 'MUT-2026-0001',
            'status': 'diajukan',
            'reason': 'Alasan 1',
            'origin_location': {'id': 1, 'name': 'Lantai 1'},
            'destination_location': {'id': 2, 'name': 'Lantai 2'},
            'current_pic': {'id': 1, 'name': 'User 1'},
            'target_pic': {'id': 2, 'name': 'User 2'},
            'applicant': {'id': 1, 'name': 'User 1'},
          },
          {
            'id': 2,
            'ticket_number': 'MUT-2026-0002',
            'status': 'selesai',
            'reason': 'Alasan 2',
            'origin_location': {'id': 2, 'name': 'Lantai 2'},
            'destination_location': {'id': 3, 'name': 'Lantai 3'},
            'current_pic': {'id': 2, 'name': 'User 2'},
            'target_pic': {'id': 3, 'name': 'User 3'},
            'applicant': {'id': 2, 'name': 'User 2'},
          },
        ],
        'meta': {
          'current_page': 1,
          'last_page': 5,
          'per_page': 15,
          'total': 72,
        },
        'links': {
          'first': 'http://localhost/api/v1/mutations?page=1',
          'last': 'http://localhost/api/v1/mutations?page=5',
          'prev': null,
          'next': 'http://localhost/api/v1/mutations?page=2',
        },
      };

      // Test MutationModel.listFromJson
      final list = MutationModel.listFromJson(paginatedPayload);
      expect(list.length, equals(2));
      expect(list[0].id, equals('1'));
      expect(list[0].status, equals(MutationStatus.submitted));
      expect(list[1].id, equals('2'));
      expect(list[1].status, equals(MutationStatus.completed));

      // Test PaginatedMutationResponse.fromJson
      final paginated = PaginatedMutationResponse.fromJson(paginatedPayload);
      expect(paginated.success, isTrue);
      expect(
        paginated.message,
        equals('Daftar pengajuan mutasi berhasil diambil.'),
      );
      expect(paginated.data.length, equals(2));
      expect(paginated.meta.currentPage, equals(1));
      expect(paginated.meta.lastPage, equals(5));
      expect(paginated.meta.perPage, equals(15));
      expect(paginated.meta.total, equals(72));

      // Test listFromJson dari direct List
      final directList = MutationModel.listFromJson(paginatedPayload['data']);
      expect(directList.length, equals(2));

      // Test listFromJson dari payload kosong / null
      expect(MutationModel.listFromJson(null), isEmpty);
      expect(MutationModel.listFromJson({}), isEmpty);
      expect(MutationModel.listFromJson([]), isEmpty);
    });

    // ─── 8. Preservasi Nama Berkas Asli PDF (sk_document_name & document_name) ───
    test('8. Nama berkas asli PDF dipertahankan dari sk_document_name meskipun path fisik di server ter-hash', () {
      const hashedServerPath = 'documents/sk_sdm/a8f09d7c6b5e4321fedcba.pdf';
      const originalFileName = 'sk_mutasi_resmi_divisi_ti.pdf';

      final jsonWithOriginalDocName = {
        'id': 202,
        'ticket_number': 'MUT-2026-00202',
        'status': 'diajukan',
        'reason': 'Pindah unit',
        'sk_document': hashedServerPath,
        'sk_document_name': originalFileName,
        'document_name': originalFileName,
      };

      final model = MutationModel.fromJson(jsonWithOriginalDocName);

      // Pastikan documentPath menyimpan path server untuk download/streaming
      expect(model.documentPath, equals(hashedServerPath));

      // Pastikan documentName menyimpan NAMA ASLI untuk tampilan UI, BUKAN hash server
      expect(model.documentName, equals(originalFileName));
      expect(model.documentName, isNot(equals('a8f09d7c6b5e4321fedcba.pdf')));

      // Verifikasi serialisasi toJson mempertahankan nama asli
      final serialized = model.toJson();
      expect(serialized['sk_document_name'], equals(originalFileName));
      expect(serialized['document_name'], equals(originalFileName));
    });

    test('9. Fallback aman ekstraksi nama dokumen jika backend hanya mengirim sk_document tanpa metadata nama', () {
      const legacyPath = 'documents/sk_sdm/dokumen_legacy.pdf';
      final jsonLegacy = {
        'id': 203,
        'ticket_number': 'MUT-2026-00203',
        'status': 'diajukan',
        'reason': 'Tes fallback',
        'sk_document': legacyPath,
      };

      final model = MutationModel.fromJson(jsonLegacy);
      expect(model.documentPath, equals(legacyPath));
      expect(model.documentName, equals('dokumen_legacy.pdf'));
    });
  });
}
