// test/features/kadiv/data/repositories/kadiv_approval_repository_test.dart
//
// Repository tests untuk MutationRepositoryImpl terkait flow Approval Kadiv.

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

  group('MutationRepositoryImpl Kadiv Approval Tests', () {
    test('approveMutationKadiv updates status to approved with Kadiv metadata',
        () async {
      final all = await repository.getAllMutations();
      final target = all.dataOrNull!.firstWhere(
        (m) => m.status == MutationStatus.waitingKadivApproval,
      );

      final result = await repository.approveMutationKadiv(
        mutationId: target.id,
        kadivName: 'Kadiv Test',
      );

      expect(result.isSuccess, true);
      final updated = result.dataOrNull!;
      expect(updated.status, MutationStatus.approved);
      expect(updated.kadivApprovedBy, 'Kadiv Test');
      expect(updated.kadivApprovedAt, isNotNull);
    });

    test('rejectMutationKadiv updates status to rejected with reason and metadata',
        () async {
      final all = await repository.getAllMutations();
      final target = all.dataOrNull!.firstWhere(
        (m) => m.status == MutationStatus.waitingKadivApproval,
      );

      const rejectionReason = 'Perangkat jaringan inti belum dapat direlokasi.';
      final result = await repository.rejectMutationKadiv(
        mutationId: target.id,
        reason: rejectionReason,
        kadivName: 'Kadiv Test',
      );

      expect(result.isSuccess, true);
      final updated = result.dataOrNull!;
      expect(updated.status, MutationStatus.rejected);
      expect(updated.rejectionReason, rejectionReason);
      expect(updated.rejectedBy, 'Kadiv Test');
      expect(updated.kadivRejectedBy, 'Kadiv Test');
      expect(updated.kadivRejectionReason, rejectionReason);
      expect(updated.kadivRejectedAt, isNotNull);
    });

    test('approveMutationKadiv returns NotFoundFailure for unknown mutation id',
        () async {
      final result = await repository.approveMutationKadiv(
        mutationId: 'unknown_kadiv_id',
        kadivName: 'Kadiv Test',
      );

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('rejectMutationKadiv returns NotFoundFailure for unknown mutation id',
        () async {
      final result = await repository.rejectMutationKadiv(
        mutationId: 'unknown_kadiv_id',
        reason: 'Alasan penolakan',
        kadivName: 'Kadiv Test',
      );

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });
}
