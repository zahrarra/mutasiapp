// lib/features/mutation/domain/usecases/process_staff_asset_update_usecase.dart
//
// Use case: Staff Aset memperbarui lokasi & PIC fisik aset pada sistem.
// Sumber: ROLE-FLOW.md §7, SCREEN-SPEC.md STF-003.

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../entities/mutation.dart';
import '../repositories/mutation_repository.dart';

class ProcessStaffAssetUpdateUseCase {
  final MutationRepository repository;

  const ProcessStaffAssetUpdateUseCase({required this.repository});

  Future<Result<Mutation>> call({
    required String mutationId,
    required String newLocation,
    required String newPic,
    required String staffName,
  }) async {
    if (mutationId.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'ID mutasi tidak boleh kosong.'),
      );
    }

    if (newLocation.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'Lokasi baru wajib diisi.'),
      );
    }

    if (newPic.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'PIC baru wajib diisi.'),
      );
    }

    return repository.processStaffAssetUpdate(
      mutationId: mutationId.trim(),
      newLocation: newLocation.trim(),
      newPic: newPic.trim(),
      staffName: staffName.trim(),
    );
  }
}
