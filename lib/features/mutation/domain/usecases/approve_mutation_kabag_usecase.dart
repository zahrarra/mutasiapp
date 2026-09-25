// lib/features/mutation/domain/usecases/approve_mutation_kabag_usecase.dart
//
// Use case: Persetujuan Pengajuan Mutasi oleh Kabag Aset.
// Sumber: PRD.md §6.4, ROLE-FLOW.md §5, SCREEN-SPEC.md KBG-003.

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../entities/mutation.dart';
import '../entities/mutation_status.dart';
import '../repositories/mutation_repository.dart';

class ApproveMutationKabagUseCase {
  final MutationRepository repository;

  const ApproveMutationKabagUseCase({required this.repository});

  Future<Result<Mutation>> call({
    required String mutationId,
    required String kabagName,
    bool? requiresKadivApproval,
  }) async {
    if (mutationId.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'ID mutasi tidak valid.'),
      );
    }

    // 1. Pastikan mutasi ada dan berstatus waitingKabagApproval
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
              'Hanya pengajuan berstatus Menunggu Approval Kabag yang dapat disetujui (Status saat ini: ${mutation.status.displayName}).',
        ),
      );
    }

    // 2. Gunakan requiresKadivApproval dari mutasi atau override jika disediakan
    final effectiveRequiresKadiv =
        requiresKadivApproval ?? mutation.requiresKadivApproval;

    return repository.approveMutationKabag(
      mutationId: mutationId,
      kabagName: kabagName,
      requiresKadivApproval: effectiveRequiresKadiv,
    );
  }
}
