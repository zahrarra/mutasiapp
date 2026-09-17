// lib/features/mutation/domain/usecases/approve_mutation_kadiv_usecase.dart
//
// Use case: Persetujuan Pengajuan Mutasi oleh Kepala Divisi (Kadiv).
// Sumber: PRD.md §6.5, ROLE-FLOW.md §6, SCREEN-SPEC.md KDV-003.

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../entities/mutation.dart';
import '../entities/mutation_status.dart';
import '../repositories/mutation_repository.dart';

class ApproveMutationKadivUseCase {
  final MutationRepository repository;

  const ApproveMutationKadivUseCase({required this.repository});

  Future<Result<Mutation>> call({
    required String mutationId,
    required String kadivName,
  }) async {
    if (mutationId.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'ID mutasi tidak valid.'),
      );
    }

    // Pastikan mutasi ada dan berstatus waitingKadivApproval
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

    if (mutation.status != MutationStatus.waitingKadivApproval) {
      return Result.failure(
        ValidationFailure(
          message:
              'Hanya pengajuan berstatus Menunggu Approval Kadiv yang dapat disetujui (Status saat ini: ${mutation.status.displayName}).',
        ),
      );
    }

    return repository.approveMutationKadiv(
      mutationId: mutationId,
      kadivName: kadivName,
    );
  }
}
