// lib/features/mutation/domain/usecases/get_kabag_approvals_usecase.dart
//
// Use case: Mengambil daftar pengajuan mutasi untuk antrean Approval Kabag Aset.
// Sumber: ROLE-FLOW.md §5, SCREEN-SPEC.md KBG-001 & KBG-002.

import '../../../../core/errors/result.dart';
import '../entities/mutation.dart';
import '../entities/mutation_status.dart';
import '../repositories/mutation_repository.dart';

class GetKabagApprovalsUseCase {
  final MutationRepository repository;

  const GetKabagApprovalsUseCase({required this.repository});

  /// Mengambil pengajuan mutasi. Jika [onlyWaitingApproval] true, hanya mengambil yang berstatus `waitingKabagApproval`.
  Future<Result<List<Mutation>>> call({bool onlyWaitingApproval = false}) async {
    final result = await repository.getAllMutations();

    if (result is Success<List<Mutation>>) {
      if (onlyWaitingApproval) {
        final filtered = result.data
            .where((m) => m.status == MutationStatus.waitingKabagApproval)
            .toList();
        return Result.success(filtered);
      }
      return result;
    }

    return result;
  }
}
