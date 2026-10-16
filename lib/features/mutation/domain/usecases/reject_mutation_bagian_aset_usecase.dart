// lib/features/mutation/domain/usecases/reject_mutation_bagian_aset_usecase.dart
//
// Use case: Penolakan Pengajuan Mutasi oleh Bagian Aset.
// Bagian Aset berwenang menolak pengajuan yang tidak memenuhi kelayakan data/fisik aset.
// Status pengajuan menjadi ditolak (MutationStatus.rejected).

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../entities/mutation.dart';
import '../repositories/mutation_repository.dart';

class RejectMutationBagianAsetUseCase {
  final MutationRepository repository;

  const RejectMutationBagianAsetUseCase({required this.repository});

  Future<Result<Mutation>> call({
    required String mutationId,
    required String reason,
    required String verifierName,
  }) async {
    if (mutationId.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'ID mutasi tidak valid.'),
      );
    }

    if (reason.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Alasan penolakan wajib diisi.'),
      );
    }

    // Pastikan mutasi ada dan berstatus waitingAssetVerification
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

    if (!mutation.status.isWaitingAssetVerification) {
      return Result.failure(
        ValidationFailure(
          message:
              'Hanya pengajuan berstatus Menunggu Verifikasi Bagian Aset yang dapat ditolak (Status saat ini: ${mutation.status.displayName}).',
        ),
      );
    }

    return repository.assetSectionReject(
      mutationId: mutationId,
      reason: reason.trim(),
      verifierName: verifierName,
    );
  }
}
