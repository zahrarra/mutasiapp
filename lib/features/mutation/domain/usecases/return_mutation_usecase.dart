// lib/features/mutation/domain/usecases/return_mutation_usecase.dart
//
// Use case: Kembalikan Pengajuan Mutasi oleh Operator.
// Sumber: PRD.md §6.3, §8 (Aturan 5), ROLE-FLOW.md §4, SCREEN-SPEC.md OPR-004.

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../entities/mutation.dart';
import '../entities/mutation_status.dart';
import '../repositories/mutation_repository.dart';

class ReturnMutationUseCase {
  final MutationRepository repository;

  const ReturnMutationUseCase({required this.repository});

  Future<Result<Mutation>> call({
    required String mutationId,
    required String reason,
    required String operatorName,
  }) async {
    if (mutationId.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'ID mutasi tidak valid.'),
      );
    }

    // Aturan Bisnis PRD.md §8 Aturan 5: "Pengajuan tidak valid harus dikembalikan dengan alasan."
    // SCREEN-SPEC.md OPR-004: "Reason required."
    if (reason.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Alasan pengembalian wajib diisi.'),
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
          message: 'Hanya pengajuan berstatus Diajukan yang dapat dikembalikan (Status saat ini: ${mutation.status.displayName}).',
        ),
      );
    }

    return repository.returnMutation(
      mutationId: mutationId,
      reason: reason.trim(),
      operatorName: operatorName,
    );
  }
}
