// lib/features/mutation/domain/usecases/verify_mutation_usecase.dart
//
// Use case: Verifikasi Mutasi Valid oleh Operator.
// Sumber: PRD.md §6.3, ROLE-FLOW.md §4, SCREEN-SPEC.md OPR-003.

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../entities/mutation.dart';
import '../entities/mutation_status.dart';
import '../repositories/mutation_repository.dart';

class VerifyMutationUseCase {
  final MutationRepository repository;

  const VerifyMutationUseCase({required this.repository});

  Future<Result<Mutation>> call({
    required String mutationId,
    required String operatorName,
    bool requiresKadivApproval = false,
  }) async {
    if (mutationId.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'ID mutasi tidak valid.'),
      );
    }

    // Pastikan mutasi ada dan berstatus Diajukan (submitted)
    final existingResult = await repository.getMutationById(mutationId);
    if (existingResult is AppFailure<Mutation>) {
      return Result.failure(existingResult.failure);
    }

    final mutation = existingResult.dataOrNull;
    if (mutation == null) {
      return const Result.failure(
        NotFoundFailure(message: 'Pengajuan mutasi tidak ditemukan.'),
      );
    }

    if (mutation.status != MutationStatus.submitted) {
      return Result.failure(
        ValidationFailure(
          message: 'Hanya pengajuan berstatus Diajukan yang dapat diverifikasi (Status saat ini: ${mutation.status.displayName}).',
        ),
      );
    }

    return repository.verifyMutation(
      mutationId: mutationId,
      operatorName: operatorName,
      requiresKadivApproval: requiresKadivApproval,
    );
  }
}
