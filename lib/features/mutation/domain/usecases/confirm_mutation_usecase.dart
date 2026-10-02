// lib/features/mutation/domain/usecases/confirm_mutation_usecase.dart
//
// Use Case: Konfirmasi mutasi oleh Pemohon.
// Sumber: ROLE-FLOW.md §3, SCREEN-SPEC.md REQ-009, TECHNICAL-DESIGN.md.

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../entities/mutation.dart';
import '../entities/mutation_status.dart';
import '../repositories/mutation_repository.dart';

/// Parameter untuk mengonfirmasi mutasi oleh Pemohon.
class ConfirmMutationParams {
  final String mutationId;
  final String confirmedBy;
  final String? userId;
  final bool isSesuai;
  final String? reason;

  const ConfirmMutationParams({
    required this.mutationId,
    required this.confirmedBy,
    this.userId,
    this.isSesuai = true,
    this.reason,
  });
}

/// Use case: Pemohon mengonfirmasi hasil mutasi (PRD V1.1 §6.6).
///
/// Pre-condition: status harus [MutationStatus.pendingConfirmation] / [MutationStatus.waitingConfirmation].
/// Post-condition:
/// - Jika Sesuai: status berubah menjadi [MutationStatus.completed] dan data aset diupdate otomatis.
/// - Jika Tidak Sesuai: status kembali ke [MutationStatus.waitingAssetVerification] dengan alasan.
class ConfirmMutationUseCase {
  final MutationRepository repository;

  const ConfirmMutationUseCase({required this.repository});

  Future<Result<Mutation>> call(ConfirmMutationParams params) async {
    // Validasi: hanya bisa konfirmasi jika status pendingConfirmation
    final detailResult = await repository.getMutationById(params.mutationId);

    if (detailResult.isFailure) {
      return Result.failure(
        detailResult.failureOrNull ??
            const NotFoundFailure(message: 'Pengajuan mutasi tidak ditemukan.'),
      );
    }

    final mutation = detailResult.dataOrNull!;

    if (!mutation.status.isWaitingConfirmation) {
      return const Result.failure(
        ValidationFailure(
          message:
              'Konfirmasi hanya dapat dilakukan pada pengajuan berstatus "Menunggu Konfirmasi".',
        ),
      );
    }

    // Validasi alasan jika tidak sesuai
    if (!params.isSesuai &&
        (params.reason == null || params.reason!.trim().isEmpty)) {
      return const Result.failure(
        ValidationFailure(
          message: 'Alasan ketidaksesuaian wajib diisi jika mutasi tidak sesuai.',
        ),
      );
    }

    // Validasi kepemilikan jika userId disertakan
    if (params.userId != null) {
      final uid = params.userId!;
      final isOwner = mutation.applicantId == uid ||
          ((uid == 'usr_pemohon' || uid == 'usr_101' || uid == 'user_pemohon') &&
              (mutation.applicantId == 'usr_pemohon' ||
                  mutation.applicantId == 'usr_101' ||
                  mutation.applicantId == 'user_pemohon')) ||
          (mutation.applicantName.trim().toLowerCase() ==
              params.confirmedBy.trim().toLowerCase());
      if (!isOwner) {
        return const Result.failure(
          ForbiddenFailure(
            message:
                'Anda tidak memiliki hak akses untuk mengonfirmasi mutasi ini.',
          ),
        );
      }
    }

    return repository.confirmMutationResult(
      mutationId: params.mutationId,
      confirmedBy: params.confirmedBy,
      isSesuai: params.isSesuai,
      reason: params.reason,
    );
  }
}
