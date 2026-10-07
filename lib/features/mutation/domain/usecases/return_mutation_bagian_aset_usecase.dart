// lib/features/mutation/domain/usecases/return_mutation_bagian_aset_usecase.dart
//
// Use case: Pengembalian Pengajuan Mutasi oleh Bagian Aset ke Pemohon.
// Sumber: PRD V1.1 §5, §6.4, §8 Aturan 13.
//
// Pengajuan yang tidak valid pada verifikasi Bagian Aset harus dikembalikan
// kepada Pemohon dengan alasan wajib diisi.

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../entities/mutation.dart';
import '../repositories/mutation_repository.dart';

class ReturnMutationBagianAsetUseCase {
  final MutationRepository repository;

  const ReturnMutationBagianAsetUseCase({required this.repository});

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
        ValidationFailure(message: 'Alasan pengembalian wajib diisi.'),
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
              'Hanya pengajuan berstatus Menunggu Verifikasi Bagian Aset yang dapat dikembalikan (Status saat ini: ${mutation.status.displayName}).',
        ),
      );
    }

    return repository.assetSectionReturn(
      mutationId: mutationId,
      reason: reason.trim(),
      verifierName: verifierName,
    );
  }
}
