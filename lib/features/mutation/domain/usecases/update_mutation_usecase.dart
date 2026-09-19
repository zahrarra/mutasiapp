// lib/features/mutation/domain/usecases/update_mutation_usecase.dart
//
// Use case: Edit Pengajuan Mutasi yang Dikembalikan.
// Sumber: SCREEN-SPEC.md REQ-008, ROLE-FLOW.md §3.

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../entities/mutation.dart';
import '../repositories/mutation_repository.dart';

/// Parameter untuk mengedit pengajuan mutasi yang berstatus `returned`.
class UpdateMutationParams {
  final String mutationId;
  final String targetLocation;
  final String targetPic;
  final String reason;
  final String? documentName;

  const UpdateMutationParams({
    required this.mutationId,
    required this.targetLocation,
    required this.targetPic,
    required this.reason,
    this.documentName,
  });
}

/// Use case untuk memperbarui pengajuan mutasi yang dikembalikan Operator
/// (REQ-008: Edit Pengajuan), lalu mengirimkannya kembali ke antrean
/// verifikasi (status -> submitted).
class UpdateMutationUseCase {
  final MutationRepository repository;

  const UpdateMutationUseCase({required this.repository});

  Future<Result<Mutation>> call(UpdateMutationParams params) async {
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

    return repository.updateMutation(
      mutationId: params.mutationId,
      targetLocation: params.targetLocation,
      targetPic: params.targetPic,
      reason: params.reason,
      documentName: params.documentName,
    );
  }
}
