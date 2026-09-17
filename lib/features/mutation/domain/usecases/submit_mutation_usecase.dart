// lib/features/mutation/domain/usecases/submit_mutation_usecase.dart
//
// Use case: Ajukan Mutasi.
// Sumber: ROLE-FLOW.md §3, TECHNICAL-DESIGN.md §19.

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../asset/domain/repositories/asset_repository.dart';
import '../entities/mutation.dart';
import '../repositories/mutation_repository.dart';

/// Use case untuk mengajukan pengajuan mutasi baru.
///
/// Validasi:
/// 1. Aset harus exist.
/// 2. Aset tidak boleh locked (hasActiveMutation / inMutation).
/// 3. Field wajib: targetLocation, targetPic, reason.
class SubmitMutationUseCase {
  final MutationRepository mutationRepository;
  final AssetRepository assetRepository;

  const SubmitMutationUseCase({
    required this.mutationRepository,
    required this.assetRepository,
  });

  Future<Result<Mutation>> call(SubmitMutationParams params) async {
    // Validasi field wajib
    if (params.targetLocation.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Lokasi tujuan wajib dipilih.'),
      );
    }

    if (params.targetPic.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Penanggung jawab baru wajib dipilih.'),
      );
    }

    if (params.reason.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Alasan mutasi wajib diisi.'),
      );
    }

    // Validasi aset: harus ada dan tidak locked
    final assetResult = await assetRepository.getAssetById(params.assetId);
    if (assetResult.isFailure) {
      return const Result.failure(
        NotFoundFailure(message: 'Aset tidak ditemukan.'),
      );
    }

    final asset = assetResult.dataOrNull!;
    if (asset.isLocked) {
      return const Result.failure(
        ConflictFailure(
          message: 'Aset sedang dalam proses mutasi lain. Pengajuan tidak dapat dilanjutkan.',
        ),
      );
    }

    // Submit ke repository
    return mutationRepository.submitMutation(params);
  }
}
