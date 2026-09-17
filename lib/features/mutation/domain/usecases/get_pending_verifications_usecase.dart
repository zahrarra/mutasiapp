// lib/features/mutation/domain/usecases/get_pending_verifications_usecase.dart
//
// Use case: Ambil daftar pengajuan mutasi untuk antrean verifikasi Operator.
// Sumber: ROLE-FLOW.md §4, SCREEN-SPEC.md OPR-001 & OPR-002.

import '../../../../core/errors/result.dart';
import '../entities/mutation.dart';
import '../entities/mutation_status.dart';
import '../repositories/mutation_repository.dart';

class GetPendingVerificationsUseCase {
  final MutationRepository repository;

  const GetPendingVerificationsUseCase({required this.repository});

  /// Mengambil pengajuan mutasi. Jika [onlySubmitted] true, hanya mengambil yang berstatus `submitted`.
  Future<Result<List<Mutation>>> call({bool onlySubmitted = false}) async {
    final result = await repository.getAllMutations();

    if (result is Success<List<Mutation>>) {
      if (onlySubmitted) {
        final filtered = result.data
            .where((m) => m.status == MutationStatus.submitted)
            .toList();
        return Result.success(filtered);
      }
      return result;
    }

    return result;
  }
}
