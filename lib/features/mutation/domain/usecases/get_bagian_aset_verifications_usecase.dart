// lib/features/mutation/domain/usecases/get_bagian_aset_verifications_usecase.dart
//
// Use case: Mengambil daftar pengajuan mutasi untuk antrean Verifikasi Bagian Aset.
// Sumber: PRD V1.1 §5, §6.4.

import '../../../../core/errors/result.dart';
import '../entities/mutation.dart';
import '../repositories/mutation_repository.dart';

class GetBagianAsetVerificationsUseCase {
  final MutationRepository repository;

  const GetBagianAsetVerificationsUseCase({required this.repository});

  /// Mengambil pengajuan mutasi. Jika [onlyWaitingVerification] true,
  /// hanya mengambil yang berstatus `waitingAssetVerification`.
  Future<Result<List<Mutation>>> call({
    bool onlyWaitingVerification = false,
  }) async {
    final result = await repository.getAllMutations();

    if (result is Success<List<Mutation>>) {
      if (onlyWaitingVerification) {
        final filtered = result.data
            .where((m) => m.status.isWaitingAssetVerification)
            .toList();
        return Result.success(filtered);
      }
      return result;
    }

    return result;
  }
}
