// test/features/operator/domain/usecases/verification_usecases_test.dart
//
// Unit tests untuk Use Cases Verification Operator.
// Sumber: PRD.md §6.3, §8 Aturan 5, ROLE-FLOW.md §4.

import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/errors/failures.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/features/asset/domain/entities/asset.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_category.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_status.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';
import 'package:mutasiku/features/mutation/domain/usecases/get_pending_verifications_usecase.dart';
import 'package:mutasiku/features/mutation/domain/usecases/return_mutation_usecase.dart';
import 'package:mutasiku/features/mutation/domain/usecases/verify_mutation_usecase.dart';

class FakeMutationRepository implements MutationRepository {
  final List<Mutation> mutations;

  FakeMutationRepository(this.mutations);

  @override
  Future<Result<Mutation>> submitMutation(SubmitMutationParams params) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<Mutation>> updateMutation({
    required String mutationId,
    required String targetLocation,
    required String targetPic,
    required String reason,
    String? documentName,
  }) async {
    final index = mutations.indexWhere((m) => m.id == mutationId);

    if (index == -1) {
      return const Result.failure(
        NotFoundFailure(message: 'Pengajuan mutasi tidak ditemukan.'),
      );
    }

    final current = mutations[index];

    final updated = current.copyWith(
      targetLocation: targetLocation,
      targetPic: targetPic,
      reason: reason,
      status: MutationStatus.submitted,
    );

    mutations[index] = updated;

    return Result.success(updated);
  }

  @override
  Future<Result<List<Mutation>>> getMutationsByUser(String userId) async {
    return Result.success(mutations);
  }

  @override
  Future<Result<Mutation>> getMutationById(String id) async {
    try {
      final item = mutations.firstWhere((m) => m.id == id);
      return Result.success(item);
    } catch (_) {
      return const Result.failure(
        NotFoundFailure(message: 'Pengajuan mutasi tidak ditemukan.'),
      );
    }
  }

  @override
  Future<Result<List<Mutation>>> getAllMutations() async {
    return Result.success(mutations);
  }

  @override
  Future<Result<Mutation>> verifyMutation({
    required String mutationId,
    required String operatorName,
  }) async {
    final index = mutations.indexWhere((m) => m.id == mutationId);
    if (index == -1) {
      return const Result.failure(
        NotFoundFailure(message: 'Pengajuan mutasi tidak ditemukan.'),
      );
    }
    final updated = mutations[index].copyWith(
      status: MutationStatus.waitingKabagApproval,
      verifiedBy: operatorName,
      verifiedAt: DateTime.now(),
    );
    mutations[index] = updated;
    return Result.success(updated);
  }

  @override
  Future<Result<Mutation>> returnMutation({
    required String mutationId,
    required String reason,
    required String operatorName,
  }) async {
    final index = mutations.indexWhere((m) => m.id == mutationId);
    if (index == -1) {
      return const Result.failure(
        NotFoundFailure(message: 'Pengajuan mutasi tidak ditemukan.'),
      );
    }
    final updated = mutations[index].copyWith(
      status: MutationStatus.returned,
      returnReason: reason,
      verifiedBy: operatorName,
      verifiedAt: DateTime.now(),
    );
    mutations[index] = updated;
    return Result.success(updated);
  }

  @override
  Future<Result<Mutation>> approveMutationKabag({
    required String mutationId,
    required String kabagName,
    required bool requiresKadivApproval,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<Mutation>> rejectMutationKabag({
    required String mutationId,
    required String reason,
    required String kabagName,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<Mutation>> approveMutationKadiv({
    required String mutationId,
    required String kadivName,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<Mutation>> rejectMutationKadiv({
    required String mutationId,
    required String reason,
    required String kadivName,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<Mutation>> confirmMutation({
    required String mutationId,
    required String confirmedBy,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<Mutation>> processStaffAssetUpdate({
    required String mutationId,
    required String newLocation,
    required String newPic,
    required String staffName,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  const dummyAsset = Asset(
    id: 'AST-001',
    assetCode: 'AST-ELK-2024-0001',
    name: 'MacBook Air M1',
    category: AssetCategory(id: 'cat_1', code: 'ELK', name: 'Elektronik & IT'),
    location: 'Kantor Pusat',
    pic: 'Rina',
    status: AssetStatus.inMutation,
    condition: 'Baik',
    acquisitionYear: 2024,
  );

  Mutation createDummyMutation({
    required String id,
    MutationStatus status = MutationStatus.submitted,
  }) {
    return Mutation(
      id: id,
      ticketNumber: 'ELK-2026-00001',
      asset: dummyAsset,
      applicantName: 'Rina',
      currentLocation: 'Kantor Pusat',
      targetLocation: 'Cabang Surabaya',
      currentPic: 'Rina',
      targetPic: 'Rina',
      reason: 'Mutasi kerja',
      status: status,
      createdAt: DateTime.now(),
    );
  }

  group('VerifyMutationUseCase tests', () {
    test('succeeds when mutation status is submitted', () async {
      final fakeRepo = FakeMutationRepository([
        createDummyMutation(id: 'mut_1', status: MutationStatus.submitted),
      ]);
      final useCase = VerifyMutationUseCase(repository: fakeRepo);

      final result = await useCase(
        mutationId: 'mut_1',
        operatorName: 'Operator Joko',
      );

      expect(result.isSuccess, true);
      final updated = result.dataOrNull!;
      expect(updated.status, MutationStatus.waitingKabagApproval);
      expect(updated.verifiedBy, 'Operator Joko');
      expect(updated.verifiedAt, isNotNull);
    });

    test('fails if mutationId is empty', () async {
      final fakeRepo = FakeMutationRepository([]);
      final useCase = VerifyMutationUseCase(repository: fakeRepo);

      final result = await useCase(
        mutationId: '   ',
        operatorName: 'Operator Joko',
      );

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('fails if mutation is not found', () async {
      final fakeRepo = FakeMutationRepository([]);
      final useCase = VerifyMutationUseCase(repository: fakeRepo);

      final result = await useCase(
        mutationId: 'mut_nonexistent',
        operatorName: 'Operator Joko',
      );

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test(
      'fails if mutation is not in submitted status (e.g. already returned)',
      () async {
        final fakeRepo = FakeMutationRepository([
          createDummyMutation(id: 'mut_1', status: MutationStatus.returned),
        ]);
        final useCase = VerifyMutationUseCase(repository: fakeRepo);

        final result = await useCase(
          mutationId: 'mut_1',
          operatorName: 'Operator Joko',
        );

        expect(result.isFailure, true);
        expect(result.failureOrNull, isA<ValidationFailure>());
        expect(
          result.failureOrNull?.message,
          contains(
            'Hanya pengajuan berstatus Diajukan yang dapat diverifikasi',
          ),
        );
      },
    );
  });

  group('ReturnMutationUseCase tests', () {
    test(
      'succeeds when mutation is submitted and reason is provided',
      () async {
        final fakeRepo = FakeMutationRepository([
          createDummyMutation(id: 'mut_1', status: MutationStatus.submitted),
        ]);
        final useCase = ReturnMutationUseCase(repository: fakeRepo);

        final result = await useCase(
          mutationId: 'mut_1',
          reason: 'Dokumen SK Mutasi belum lengkap.',
          operatorName: 'Operator Joko',
        );

        expect(result.isSuccess, true);
        final updated = result.dataOrNull!;
        expect(updated.status, MutationStatus.returned);
        expect(updated.returnReason, 'Dokumen SK Mutasi belum lengkap.');
        expect(updated.verifiedBy, 'Operator Joko');
      },
    );

    test('fails when reason is empty or whitespace (PRD Aturan 5)', () async {
      final fakeRepo = FakeMutationRepository([
        createDummyMutation(id: 'mut_1', status: MutationStatus.submitted),
      ]);
      final useCase = ReturnMutationUseCase(repository: fakeRepo);

      final result = await useCase(
        mutationId: 'mut_1',
        reason: '    ',
        operatorName: 'Operator Joko',
      );

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(
        result.failureOrNull?.message,
        contains('Alasan pengembalian wajib diisi'),
      );
    });

    test('fails if mutation is not in submitted status', () async {
      final fakeRepo = FakeMutationRepository([
        createDummyMutation(
          id: 'mut_1',
          status: MutationStatus.waitingKabagApproval,
        ),
      ]);
      final useCase = ReturnMutationUseCase(repository: fakeRepo);

      final result = await useCase(
        mutationId: 'mut_1',
        reason: 'Alasan pengembalian valid',
        operatorName: 'Operator Joko',
      );

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('GetPendingVerificationsUseCase tests', () {
    test('filters only submitted status when onlySubmitted is true', () async {
      final fakeRepo = FakeMutationRepository([
        createDummyMutation(id: 'mut_1', status: MutationStatus.submitted),
        createDummyMutation(id: 'mut_2', status: MutationStatus.returned),
        createDummyMutation(
          id: 'mut_3',
          status: MutationStatus.waitingKabagApproval,
        ),
        createDummyMutation(id: 'mut_4', status: MutationStatus.submitted),
      ]);
      final useCase = GetPendingVerificationsUseCase(repository: fakeRepo);

      final result = await useCase(onlySubmitted: true);

      expect(result.isSuccess, true);
      final list = result.dataOrNull!;
      expect(list.length, 2);
      expect(list.every((m) => m.status == MutationStatus.submitted), true);
    });

    test('returns all mutations when onlySubmitted is false', () async {
      final fakeRepo = FakeMutationRepository([
        createDummyMutation(id: 'mut_1', status: MutationStatus.submitted),
        createDummyMutation(id: 'mut_2', status: MutationStatus.returned),
      ]);
      final useCase = GetPendingVerificationsUseCase(repository: fakeRepo);

      final result = await useCase(onlySubmitted: false);

      expect(result.isSuccess, true);
      expect(result.dataOrNull!.length, 2);
    });
  });
}
