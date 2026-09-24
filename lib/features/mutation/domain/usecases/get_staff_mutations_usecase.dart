// lib/features/mutation/domain/usecases/get_staff_mutations_usecase.dart
//
// Use case: Ambil daftar pengajuan mutasi untuk antrean pembaruan aset oleh Staff Aset.
// Sumber: ROLE-FLOW.md §7, SCREEN-SPEC.md STF-001 & STF-002.

import '../../../../core/errors/result.dart';
import '../entities/mutation.dart';
import '../entities/mutation_status.dart';
import '../repositories/mutation_repository.dart';

class GetStaffMutationsUseCase {
  final MutationRepository repository;

  const GetStaffMutationsUseCase({required this.repository});

  /// Mengambil pengajuan mutasi untuk Staff Aset.
  /// Jika [onlyWaitingUpdate] bernilai true, hanya mengambil mutasi berstatus [MutationStatus.approved].
  Future<Result<List<Mutation>>> call({bool onlyWaitingUpdate = true}) async {
    final result = await repository.getAllMutations();

    if (result is Success<List<Mutation>>) {
      if (onlyWaitingUpdate) {
        final filtered = result.data
            .where((m) => m.status == MutationStatus.approved)
            .toList();
        return Result.success(filtered);
      }
      return result;
    }

    return result;
  }
}
