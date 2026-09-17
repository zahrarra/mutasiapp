// lib/features/mutation/domain/usecases/reject_mutation_kabag_usecase.dart
//
// Use case: Penolakan Pengajuan Mutasi oleh Kabag Aset.
// Sumber: PRD.md §6.4, §8 Aturan 7, ROLE-FLOW.md §5, SCREEN-SPEC.md KBG-004.

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../entities/mutation.dart';
import '../entities/mutation_status.dart';
import '../repositories/mutation_repository.dart';

class RejectMutationKabagUseCase {
  final MutationRepository repository;

  const RejectMutationKabagUseCase({required this.repository});

  Future<Result<Mutation>> call({
    required String mutationId,
    required String reason,
    required String kabagName,
  }) async {
    if (mutationId.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'ID mutasi tidak valid.'),
      );
    }

    // Aturan Bisnis PRD §8 Aturan 7: "Penolakan harus memiliki alasan."
    // SCREEN-SPEC.md KBG-004: "Alasan wajib diisi."
    if (reason.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Alasan penolakan wajib diisi.'),
      );
    }

    // Pastikan mutasi ada dan berstatus waitingKabagApproval
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

    if (mutation.status != MutationStatus.waitingKabagApproval) {
      return Result.failure(
        ValidationFailure(
          message:
              'Hanya pengajuan berstatus Menunggu Approval Kabag yang dapat ditolak (Status saat ini: ${mutation.status.displayName}).',
        ),
      );
    }

    return repository.rejectMutationKabag(
      mutationId: mutationId,
      reason: reason.trim(),
      kabagName: kabagName,
    );
  }
}
