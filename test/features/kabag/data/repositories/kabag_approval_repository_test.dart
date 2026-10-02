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
    test('approveMutationKabag updates status to waitingDivisionHeadApproval', () async {
      final all = await repository.getAllMutations();
      final target = all.dataOrNull!.firstWhere(
        (m) => m.status.isWaitingAssetVerification,
      );

      final result = await repository.approveMutationKabag(
        mutationId: target.id,
        kabagName: 'Kabag Test',
        requiresKadivApproval: false,
      );

      expect(result.isSuccess, true);
      final updated = result.dataOrNull!;
      expect(updated.status.isWaitingDivisionApproval, true);
      expect(updated.assetVerifiedBy, 'Kabag Test');
    });

    test('approveMutationKabag with requiresKadivApproval sets waitingKadivApproval', () async {
      final all = await repository.getAllMutations();
      final target = all.dataOrNull!.firstWhere(
        (m) => m.status.isWaitingAssetVerification,
      );

      final result = await repository.approveMutationKabag(
        mutationId: target.id,
        kabagName: 'Kabag Test',
        requiresKadivApproval: true,
      );

      expect(result.isSuccess, true);
      final updated = result.dataOrNull!;
      expect(updated.status.isWaitingDivisionApproval, true);
      expect(updated.requiresKadivApproval, true);
      expect(updated.assetVerifiedBy, 'Kabag Test');
    });

    test('rejectMutationKabag updates status to returned with reason', () async {
      final all = await repository.getAllMutations();
      final target = all.dataOrNull!.firstWhere(
        (m) => m.status.isWaitingAssetVerification,
      );

      const rejectionReason = 'Aset tidak diizinkan pindah cabang.';
      final result = await repository.rejectMutationKabag(
        mutationId: target.id,
        reason: rejectionReason,
        kabagName: 'Kabag Test',
      );

      expect(result.isSuccess, true);
      final updated = result.dataOrNull!;
      expect(updated.status, MutationStatus.returned);
      expect(updated.returnReason, rejectionReason);
      expect(updated.rejectedBy, 'Kabag Test');
      expect(updated.rejectedAt, isNotNull);
    });

    test('approveMutationKabag returns NotFoundFailure for unknown mutation id',
        () async {
      final result = await repository.approveMutationKabag(
        mutationId: 'unknown_kabag_id',
        kabagName: 'Kabag Test',
        requiresKadivApproval: false,
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
