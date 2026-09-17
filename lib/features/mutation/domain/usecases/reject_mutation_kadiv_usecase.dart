// lib/features/mutation/domain/usecases/reject_mutation_kadiv_usecase.dart
//
// Use case: Penolakan Pengajuan Mutasi oleh Kepala Divisi (Kadiv).
// Sumber: PRD.md §6.5, §8 Aturan 7, ROLE-FLOW.md §6, SCREEN-SPEC.md KDV-004.

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../entities/mutation.dart';
import '../entities/mutation_status.dart';
import '../repositories/mutation_repository.dart';

class RejectMutationKadivUseCase {
  final MutationRepository repository;

  const RejectMutationKadivUseCase({required this.repository});

  Future<Result<Mutation>> call({
    required String mutationId,
    required String reason,
    required String kadivName,
  }) async {
    if (mutationId.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'ID mutasi tidak valid.'),
      );
    }

    // Aturan Bisnis PRD §8 Aturan 7: "Penolakan harus memiliki alasan."
    // SCREEN-SPEC.md KDV-004: "Reason wajib."
    if (reason.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Alasan penolakan wajib diisi.'),
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
              'Hanya pengajuan berstatus Menunggu Approval Kadiv yang dapat ditolak (Status saat ini: ${mutation.status.displayName}).',
        ),
      );
    }

    return repository.rejectMutationKadiv(
      mutationId: mutationId,
      reason: reason.trim(),
      kadivName: kadivName,
    );
  }
}
