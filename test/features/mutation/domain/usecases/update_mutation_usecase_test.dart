// test/features/mutation/domain/usecases/update_mutation_usecase_test.dart
//
// Unit test untuk UpdateMutationUseCase dan MutationRepository.updateMutation.
// Sumber: SCREEN-SPEC.md REQ-008, ROLE-FLOW.md §3.

import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/errors/failures.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/features/asset/data/repositories/asset_repository_impl.dart';
import 'package:mutasiku/features/asset/domain/entities/asset.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_category.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_status.dart';
import 'package:mutasiku/features/mutation/data/repositories/mutation_repository_impl.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';
import 'package:mutasiku/features/mutation/domain/usecases/update_mutation_usecase.dart';

class _FakeMutationRepository implements MutationRepository {
  final List<Mutation> mutations;

  _FakeMutationRepository(this.mutations);

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
    if (current.status != MutationStatus.returned) {
      return const Result.failure(
        ConflictFailure(
          message:
              'Pengajuan ini tidak dapat diedit karena bukan berstatus "Dikembalikan ke Pemohon".',
        ),
      );
    }
    final updated = current.copyWith(
      targetLocation: targetLocation,
      targetPic: targetPic,
      reason: reason,
      documentName: documentName,
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
    final found = mutations.where((m) => m.id == id).firstOrNull;
    if (found == null) {
      return const Result.failure(NotFoundFailure(message: 'Not found'));
    }
    return Result.success(found);
  }

  @override
  Future<Result<List<Mutation>>> getAllMutations() async {
    return Result.success(mutations);
  }

  @override
  Future<Result<Mutation>> verifyMutation({
    required String mutationId,
    required String operatorName,
    bool requiresKadivApproval = false,
  }) async => throw UnimplementedError();

  @override
  Future<Result<Mutation>> returnMutation({
    required String mutationId,
    required String reason,
    required String operatorName,
  }) async => throw UnimplementedError();

  @override
  Future<Result<Mutation>> approveMutationKabag({
    required String mutationId,
    required String kabagName,
    required bool requiresKadivApproval,
  }) async => throw UnimplementedError();

  @override
  Future<Result<Mutation>> rejectMutationKabag({
    required String mutationId,
    required String reason,
    required String kabagName,
  }) async => throw UnimplementedError();

  @override
  Future<Result<Mutation>> approveMutationKadiv({
    required String mutationId,
    required String kadivName,
  }) async => throw UnimplementedError();

  @override
  Future<Result<Mutation>> rejectMutationKadiv({
    required String mutationId,
    required String reason,
    required String kadivName,
  }) async => throw UnimplementedError();

  @override
  Future<Result<Mutation>> confirmMutation({
    required String mutationId,
    required String confirmedBy,
  }) async => throw UnimplementedError();

  @override
  Future<Result<Mutation>> processStaffAssetUpdate({
    required String mutationId,
    required String newLocation,
    required String newPic,
    required String staffName,
  }) async => throw UnimplementedError();
}

Mutation _createTestMutation({
  required String id,
  required MutationStatus status,
  String? returnReason,
}) {
  return Mutation(
    id: id,
    ticketNumber: 'ELK-2026-00001',
    asset: const Asset(
      id: 'ast_1',
      assetCode: 'AST-ELK-2026-0001',
      name: 'Laptop Dell XPS 15',
      category: AssetCategory(id: 'c1', code: 'ELK', name: 'Elektronik'),
      location: 'Lantai 2 - Ruang IT',
      pic: 'Budi Santoso',
      status: AssetStatus.inMutation,
      condition: 'Baik',
      acquisitionYear: 2024,
    ),
    applicantName: 'Budi Santoso',
    currentLocation: 'Lantai 2 - Ruang IT',
    targetLocation: 'Lantai 3 - Finance',
    currentPic: 'Budi Santoso',
    targetPic: 'Siti Rahma',
    reason: 'Rotasi penugasan kerja',
    status: status,
    returnReason: returnReason,
    createdAt: DateTime.now(),
  );
}

void main() {
  group('UpdateMutationUseCase Validation', () {
    late _FakeMutationRepository fakeRepo;
    late UpdateMutationUseCase useCase;

    setUp(() {
      fakeRepo = _FakeMutationRepository([
        _createTestMutation(
          id: 'mut_returned',
          status: MutationStatus.returned,
          returnReason: 'Alasan tidak lengkap',
        ),
      ]);
      useCase = UpdateMutationUseCase(repository: fakeRepo);
    });

    test('returns ValidationFailure when targetLocation is empty', () async {
      final result = await useCase(
        const UpdateMutationParams(
          mutationId: 'mut_returned',
          targetLocation: '   ',
          targetPic: 'Siti Rahma',
          reason: 'Alasan perbaikan',
        ),
      );

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('returns ValidationFailure when targetPic is empty', () async {
      final result = await useCase(
        const UpdateMutationParams(
          mutationId: 'mut_returned',
          targetLocation: 'Lantai 3',
          targetPic: '',
          reason: 'Alasan perbaikan',
        ),
      );

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('returns ValidationFailure when reason is empty', () async {
      final result = await useCase(
        const UpdateMutationParams(
          mutationId: 'mut_returned',
          targetLocation: 'Lantai 3',
          targetPic: 'Siti Rahma',
          reason: '  ',
        ),
      );

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('successfully updates and resets status to submitted', () async {
      final result = await useCase(
        const UpdateMutationParams(
          mutationId: 'mut_returned',
          targetLocation: 'Lantai 4 - Marketing',
          targetPic: 'Ahmad Dahlan',
          reason: 'Alasan mutasi yang diperjelas',
          documentName: 'surat_tugas.pdf',
        ),
      );

      expect(result.isSuccess, true);
      final updated = result.dataOrNull!;
      expect(updated.targetLocation, 'Lantai 4 - Marketing');
      expect(updated.targetPic, 'Ahmad Dahlan');
      expect(updated.reason, 'Alasan mutasi yang diperjelas');
      expect(updated.documentName, 'surat_tugas.pdf');
      expect(updated.status, MutationStatus.submitted);
    });
  });

  group('MutationRepositoryImpl.updateMutation Concrete Implementation', () {
    late MutationRepositoryImpl repository;

    setUp(() {
      MutationRepositoryImpl.resetForTesting();
      final assetRepo = AssetRepositoryImpl();
      repository = MutationRepositoryImpl(assetRepository: assetRepo);
    });

    test('returns NotFoundFailure when mutation ID does not exist', () async {
      final result = await repository.updateMutation(
        mutationId: 'non_existent_id',
        targetLocation: 'Lantai 3',
        targetPic: 'PIC Baru',
        reason: 'Alasan baru',
      );

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('returns ConflictFailure when mutation is not in returned status', () async {
      final all = await repository.getAllMutations();
      final submitted = all.dataOrNull!.firstWhere(
        (m) => m.status == MutationStatus.submitted,
      );

      final result = await repository.updateMutation(
        mutationId: submitted.id,
        targetLocation: 'Lantai 3',
        targetPic: 'PIC Baru',
        reason: 'Alasan baru',
      );

      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<ConflictFailure>());
    });

    test('successfully updates returned mutation in MutationRepositoryImpl', () async {
      // Return a mutation first so it has returned status
      final all = await repository.getAllMutations();
      final submitted = all.dataOrNull!.firstWhere(
        (m) => m.status == MutationStatus.submitted,
      );

      await repository.returnMutation(
        mutationId: submitted.id,
        reason: 'Dokumen belum lengkap',
        operatorName: 'Operator Test',
      );

      final result = await repository.updateMutation(
        mutationId: submitted.id,
        targetLocation: 'Lantai 5 - Direksi',
        targetPic: 'Bambang Sudiro',
        reason: 'Kebutuhan mendesak direksi',
        documentName: 'revisi_dokumen.pdf',
      );

      expect(result.isSuccess, true);
      final updated = result.dataOrNull!;
      expect(updated.status, MutationStatus.submitted);
      expect(updated.targetLocation, 'Lantai 5 - Direksi');
      expect(updated.targetPic, 'Bambang Sudiro');
      expect(updated.reason, 'Kebutuhan mendesak direksi');
      expect(updated.documentName, 'revisi_dokumen.pdf');
    });
  });
}
