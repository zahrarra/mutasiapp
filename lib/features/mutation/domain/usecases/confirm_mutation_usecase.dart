// lib/features/mutation/domain/usecases/confirm_mutation_usecase.dart
//
// Use Case: Konfirmasi mutasi oleh Pemohon.
// Sumber: ROLE-FLOW.md §3, SCREEN-SPEC.md REQ-009, TECHNICAL-DESIGN.md.

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../entities/mutation.dart';
import '../entities/mutation_status.dart';
import '../repositories/mutation_repository.dart';

/// Parameter untuk mengonfirmasi mutasi oleh Pemohon.
class ConfirmMutationParams {
  final String mutationId;
  final String confirmedBy;

  const ConfirmMutationParams({
    required this.mutationId,
    required this.confirmedBy,
  });
}

/// Use case: Pemohon mengonfirmasi hasil mutasi yang telah diperbarui oleh Staff Aset.
///
/// Pre-condition: status harus [MutationStatus.pendingConfirmation].
/// Post-condition: status berubah menjadi [MutationStatus.completed].
/// Sumber: ROLE-FLOW.md §3 "Jika menunggu konfirmasi", SCREEN-SPEC.md REQ-009.
class ConfirmMutationUseCase {
  final MutationRepository repository;

  const ConfirmMutationUseCase({required this.repository});

  Future<Result<Mutation>> call(ConfirmMutationParams params) async {
    // Validasi: hanya bisa konfirmasi jika status pendingConfirmation
    final detailResult = await repository.getMutationById(params.mutationId);

    if (detailResult.isFailure) {
      return Result.failure(
        detailResult.failureOrNull ?? const NotFoundFailure(message: 'Pengajuan mutasi tidak ditemukan.'),
      );
    }

    final mutation = detailResult.dataOrNull!;

    if (mutation.status != MutationStatus.pendingConfirmation) {
      return const Result.failure(
        ValidationFailure(
          message: 'Konfirmasi hanya dapat dilakukan pada pengajuan berstatus "Menunggu Konfirmasi".',
        ),
      );
    }

    return repository.confirmMutation(
      mutationId: params.mutationId,
      confirmedBy: params.confirmedBy,
    );
  }
}
