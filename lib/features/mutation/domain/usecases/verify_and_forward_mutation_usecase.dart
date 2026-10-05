// lib/features/mutation/domain/usecases/verify_and_forward_mutation_usecase.dart
//
// Use case: Verifikasi Data Aset & Teruskan ke Pemimpin Divisi oleh Bagian Aset.
// Sumber: PRD V1.1 §5, §6.4, §8 Aturan 12 & 15.
//
// Bagian Aset BUKAN approver:
// 1. Memeriksa keabsahan data aset, lokasi tujuan, dan SK SDM.
// 2. Menentukan PIC baru jika pemohon tidak membawa aset (isAssetMovingWithApplicant == false).
// 3. Meneruskan pengajuan yang valid ke antrean Approval Pemimpin Divisi.

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../entities/mutation.dart';
import '../repositories/mutation_repository.dart';

class VerifyAndForwardMutationUseCase {
  final MutationRepository repository;

  const VerifyAndForwardMutationUseCase({required this.repository});

  Future<Result<Mutation>> call({
    required String mutationId,
    required String verifierName,
    String? newPic,
  }) async {
    if (mutationId.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'ID mutasi tidak valid.'),
      );
    }

    // 1. Pastikan mutasi ada dan berstatus waitingAssetVerification
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
              'Hanya pengajuan berstatus Menunggu Verifikasi Bagian Aset yang dapat diverifikasi (Status saat ini: ${mutation.status.displayName}).',
        ),
      );
    }

    // 2. Validasi PIC baru jika aset ditinggalkan / targetPic kosong
    final isLeftBehind = !mutation.isAssetMovingWithApplicant;
    final needsPic = isLeftBehind || mutation.targetPic.trim().isEmpty;
    final effectivePic = (newPic != null && newPic.trim().isNotEmpty)
        ? newPic.trim()
        : mutation.targetPic.trim();

    if (needsPic && effectivePic.isEmpty) {
      return const Result.failure(
        ValidationFailure(
          message:
              'PIC baru wajib ditentukan oleh Bagian Aset sebelum meneruskan pengajuan.',
        ),
      );
    }

    // 3. Teruskan ke Pemimpin Divisi (tanpa conditional threshold)
    return repository.assetSectionForward(
      mutationId: mutationId,
      verifierName: verifierName,
      newPic: effectivePic.isNotEmpty ? effectivePic : null,
    );
  }
}
