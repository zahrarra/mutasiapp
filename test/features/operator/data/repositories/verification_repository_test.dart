// test/features/operator/data/repositories/verification_repository_test.dart
//
// Repository tests untuk MutationRepositoryImpl terkait flow verifikasi.

import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/errors/failures.dart';
import 'package:mutasiku/features/asset/data/repositories/asset_repository_impl.dart';
import 'package:mutasiku/features/mutation/data/repositories/mutation_repository_impl.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';

void main() {
  late MutationRepositoryImpl repository;

  setUp(() {
    MutationRepositoryImpl.resetForTesting();
    final assetRepo = AssetRepositoryImpl();
    repository = MutationRepositoryImpl(assetRepository: assetRepo);
  });

  group('MutationRepositoryImpl Verification Tests', () {
    test('getAllMutations returns seeded initial mutations', () async {
      final result = await repository.getAllMutations();

      expect(result.isSuccess, true);
      final list = result.dataOrNull!;
      expect(list.isNotEmpty, true);
      // Ada pengajuan dengan status submitted
      expect(list.any((m) => m.status == MutationStatus.submitted), true);
    });

    test('verifyMutation updates status to waitingKabagApproval', () async {
      // Ambil mutasi pertama (mut_001 berstatus submitted)
      final all = await repository.getAllMutations();
      final target =
          all.dataOrNull!.firstWhere((m) => m.status == MutationStatus.submitted);

      final result = await repository.verifyMutation(
        mutationId: target.id,
        operatorName: 'Operator Test',
      );

      expect(result.isSuccess, true);
      final updated = result.dataOrNull!;
      expect(updated.status, MutationStatus.waitingKabagApproval);
      expect(updated.verifiedBy, 'Operator Test');
      expect(updated.verifiedAt, isNotNull);
    });

    test('returnMutation updates status to returned with reason', () async {
      final all = await repository.getAllMutations();
      final target =
          all.dataOrNull!.firstWhere((m) => m.status == MutationStatus.submitted);

      const returnReason = 'Data lokasi tujuan tidak valid';
      final result = await repository.returnMutation(
        mutationId: target.id,
        reason: returnReason,
        operatorName: 'Operator Test',
      );

      expect(result.isSuccess, true);
      final updated = result.dataOrNull!;
      expect(updated.status, MutationStatus.returned);
      expect(updated.returnReason, returnReason);
      expect(updated.verifiedBy, 'Operator Test');
    });

    test('verifyMutation returns NotFoundFailure for unknown mutation id',
        () async {
      final result = await repository.verifyMutation(
        mutationId: 'unknown_id_9999',
        operatorName: 'Operator Test',
      );

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('returnMutation returns NotFoundFailure for unknown mutation id',
        () async {
      final result = await repository.returnMutation(
        mutationId: 'unknown_id_9999',
        reason: 'Alasan',
        operatorName: 'Operator Test',
      );

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });
}
