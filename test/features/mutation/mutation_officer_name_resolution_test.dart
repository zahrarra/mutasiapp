// test/features/mutation/mutation_officer_name_resolution_test.dart
//
// Pengujian resolusi nama petugas verifikasi:
// - Memastikan angka/ID dari backend tidak pernah ditampilkan sebagai nama petugas.
// - Memastikan nama asli yang di-resolve dari relasi & riwayat tindakan ditampilkan dengan benar.

import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/features/mutation/data/models/mutation_model.dart';
import 'package:mutasiku/features/mutation/presentation/models/mutation_tracking_step.dart';

void main() {
  group('Mutation Officer Name Resolution Tests', () {
    test('1. Parsed correctly when backend sends real names', () {
      final json = <String, dynamic>{
        'id': 101,
        'ticket_number': 'MUT-2026-0001',
        'asset_id': 'AST-001',
        'applicant_name': 'Ahmad Pemohon',
        'origin_location': 'Gedung A',
        'destination_location': 'Gedung B',
        'current_pic': 'Ahmad Pemohon',
        'target_pic': 'Ahmad Pemohon',
        'reason': 'Pindah tugas',
        'status': 'diajukan',
        'created_at': '2026-10-10T08:00:00Z',
        'verified_by': 'Dirly Dwi Operator',
        'asset_verified_by': 'Siti Bagian Aset',
        'approved_by': 'Budi Kadiv',
        'kadiv_approved_by': 'Budi Kadiv',
      };

      final model = MutationModel.fromJson(json);

      expect(model.verifiedBy, equals('Dirly Dwi Operator'));
      expect(model.assetVerifiedBy, equals('Siti Bagian Aset'));
      expect(model.approvedBy, equals('Budi Kadiv'));
      expect(model.kadivApprovedBy, equals('Budi Kadiv'));
    });

    test('2. Numeric IDs are sanitized and never exposed as officer names', () {
      final legacyJson = <String, dynamic>{
        'id': 102,
        'ticket_number': 'MUT-2026-0002',
        'asset_id': 'AST-002',
        'applicant_name': 'Zahra Rara',
        'origin_location': 'Kantor Pusat',
        'destination_location': 'Cabang Donggala',
        'current_pic': 'Zahra Rara',
        'target_pic': 'Zahra Rara',
        'reason': 'Pindah tugas',
        'status': 'menunggu_verifikasi_bagian_aset',
        'created_at': '2026-10-10T08:00:00Z',
        // Backend legacy yang hanya mengirimkan integer ID user:
        'verified_by': 3,
        'asset_verified_by': '4',
        'approved_by': 5,
        'rejected_by': 6,
      };

      final model = MutationModel.fromJson(legacyJson);

      // Angka ID tidak boleh bocor sebagai nama
      expect(model.verifiedBy, isNull);
      expect(model.assetVerifiedBy, isNull);
      expect(model.approvedBy, isNull);
      expect(model.rejectedBy, isNull);
    });

    test('3. Resolves officer name from nested user object if ID is present', () {
      final payloadWithUserObjects = <String, dynamic>{
        'id': 103,
        'ticket_number': 'MUT-2026-0003',
        'asset_id': 'AST-003',
        'applicant_name': 'Zahra Rara',
        'origin_location': 'Kantor Pusat',
        'destination_location': 'Cabang Donggala',
        'current_pic': 'Zahra Rara',
        'target_pic': 'Zahra Rara',
        'reason': 'Pindah tugas',
        'status': 'menunggu_approval_pemimpin_divisi',
        'created_at': '2026-10-10T08:00:00Z',
        'verified_by': 3,
        'verified_by_user': {
          'id': 3,
          'name': 'Dirly Dwi Operator',
          'role': 'operator',
        },
        'approved_by': 4,
        'approved_by_user': {
          'id': 4,
          'name': 'Bagian Aset MutasiKu',
          'role': 'bagian_aset',
        },
      };

      final model = MutationModel.fromJson(payloadWithUserObjects);

      expect(model.verifiedBy, equals('Dirly Dwi Operator'));
      expect(model.approvedBy, equals('Bagian Aset MutasiKu'));
    });

    test('4. Empty, whitespace, or "null" string values are parsed as null', () {
      final edgeCasesJson = <String, dynamic>{
        'id': 104,
        'ticket_number': 'MUT-2026-0004',
        'asset_id': 'AST-004',
        'applicant_name': 'Zahra Rara',
        'origin_location': 'Kantor Pusat',
        'destination_location': 'Cabang Donggala',
        'current_pic': 'Zahra Rara',
        'target_pic': 'Zahra Rara',
        'reason': 'Pindah tugas',
        'status': 'diajukan',
        'created_at': '2026-10-10T08:00:00Z',
        'verified_by': '   ',
        'asset_verified_by': 'null',
        'approved_by': null,
      };

      final model = MutationModel.fromJson(edgeCasesJson);

      expect(model.verifiedBy, isNull);
      expect(model.assetVerifiedBy, isNull);
      expect(model.approvedBy, isNull);
    });

    test('5. MutationTrackingStep displays correct officer name and no raw numbers', () {
      final mutationWithName = MutationModel.fromJson({
        'id': 105,
        'ticket_number': 'MUT-2026-0005',
        'status': 'menunggu_approval_pemimpin_divisi',
        'verified_by': 'Dirly Dwi Operator',
        'asset_verified_by': 'Siti Bagian Aset',
      });

      final stepsWithName = MutationTrackingHelper.getStepsForMutation(
        mutationWithName.status,
        mutation: mutationWithName,
      );

      final operatorStep = stepsWithName.firstWhere((s) => s.key == 'operatorCheck');
      expect(operatorStep.subtitle, contains('oleh Dirly Dwi Operator'));

      final assetStep = stepsWithName.firstWhere((s) => s.key == 'assetVerification');
      expect(assetStep.subtitle, contains('oleh Siti Bagian Aset'));

      // Test with legacy raw numbers in JSON:
      final mutationWithNumbers = MutationModel.fromJson({
        'id': 106,
        'ticket_number': 'MUT-2026-0006',
        'status': 'menunggu_approval_pemimpin_divisi',
        'verified_by': 3,
        'asset_verified_by': '4',
      });

      final stepsWithNumbers = MutationTrackingHelper.getStepsForMutation(
        mutationWithNumbers.status,
        mutation: mutationWithNumbers,
      );

      final opStepClean = stepsWithNumbers.firstWhere((s) => s.key == 'operatorCheck');
      expect(opStepClean.subtitle, equals('Dinyatakan lengkap dan diteruskan'));
      expect(opStepClean.subtitle, isNot(contains('oleh 3')));

      final asStepClean = stepsWithNumbers.firstWhere((s) => s.key == 'assetVerification');
      expect(asStepClean.subtitle, equals('Terverifikasi valid'));
      expect(asStepClean.subtitle, isNot(contains('oleh 4')));
    });
  });
}
