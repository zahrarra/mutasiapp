// test/features/kabag/data/repositories/kabag_approval_repository_test.dart
//
// Repository tests untuk MutationRepositoryImpl terkait flow Approval Kabag.

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

  group('MutationRepositoryImpl Kabag Approval Tests', () {
    test('approveMutationKabag updates status to approved', () async {
      final all = await repository.getAllMutations();
      final target = all.dataOrNull!.firstWhere(
        (m) => m.status == MutationStatus.waitingKabagApproval,
      );

      final result = await repository.approveMutationKabag(
        mutationId: target.id,
        kabagName: 'Kabag Test',
      );

      expect(result.isSuccess, true);
      final updated = result.dataOrNull!;
      expect(updated.status, MutationStatus.approved);
      expect(updated.approvedBy, 'Kabag Test');
      expect(updated.approvedAt, isNotNull);
    });

    test('rejectMutationKabag updates status to rejected with reason', () async {
      final all = await repository.getAllMutations();
      final target = all.dataOrNull!.firstWhere(
        (m) => m.status == MutationStatus.waitingKabagApproval,
      );

      const rejectionReason = 'Aset tidak diizinkan pindah cabang.';
      final result = await repository.rejectMutationKabag(
        mutationId: target.id,
        reason: rejectionReason,
        kabagName: 'Kabag Test',
      );

      expect(result.isSuccess, true);
      final updated = result.dataOrNull!;
      expect(updated.status, MutationStatus.rejected);
      expect(updated.rejectionReason, rejectionReason);
      expect(updated.rejectedBy, 'Kabag Test');
      expect(updated.rejectedAt, isNotNull);
    });

    test('approveMutationKabag returns NotFoundFailure for unknown mutation id',
        () async {
      final result = await repository.approveMutationKabag(
        mutationId: 'unknown_kabag_id',
        kabagName: 'Kabag Test',
      );

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('rejectMutationKabag returns NotFoundFailure for unknown mutation id',
        () async {
      final result = await repository.rejectMutationKabag(
        mutationId: 'unknown_kabag_id',
        reason: 'Alasan penolakan',
        kabagName: 'Kabag Test',
      );

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });
}
