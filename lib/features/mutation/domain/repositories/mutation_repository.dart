// lib/features/mutation/domain/repositories/mutation_repository.dart
//
// Kontrak repository Mutation Submission.
// Sumber: ROLE-FLOW.md §3, TECHNICAL-DESIGN.md §19, SCREEN-SPEC.md REQ-003–007.

import '../../../../core/errors/result.dart';
import '../entities/mutation.dart';

/// Parameter untuk mengajukan mutasi baru.
class SubmitMutationParams {
  final String assetId;
  final String assetName;
  final String sourceLocation;
  final String targetLocation;
  final String targetPic;
  final String reason;
  final String? documentName;

  const SubmitMutationParams({
    required this.assetId,
    required this.assetName,
    required this.sourceLocation,
    required this.targetLocation,
    required this.targetPic,
    required this.reason,
    this.documentName,
  });
}

/// Kontrak repository untuk fitur pengajuan mutasi.
abstract class MutationRepository {
  /// Ajukan mutasi baru.
  ///
  /// Mengembalikan [Mutation] dengan ticket number yang di-generate server.
  /// Gagal jika aset locked atau data tidak valid.
  Future<Result<Mutation>> submitMutation(SubmitMutationParams params);

  /// Perbarui pengajuan mutasi yang berstatus [MutationStatus.returned].
  ///
  /// Sumber: SCREEN-SPEC.md REQ-008 (Edit Pengajuan).
  /// Setelah diperbarui, status kembali menjadi [MutationStatus.submitted]
  /// dan pengajuan masuk kembali ke antrean verifikasi Operator.
  /// Gagal jika mutasi tidak ditemukan atau status saat ini bukan `returned`.
  Future<Result<Mutation>> updateMutation({
    required String mutationId,
    required String targetLocation,
    required String targetPic,
    required String reason,
    String? documentName,
  });

  /// Ambil daftar mutasi milik user tertentu.
  Future<Result<List<Mutation>>> getMutationsByUser(String userId);

  /// Ambil detail satu mutasi berdasarkan ID.
  Future<Result<Mutation>> getMutationById(String id);

  /// Ambil semua daftar mutasi (untuk kebutuhan verifikasi Operator / manajemen).
  Future<Result<List<Mutation>>> getAllMutations();

  /// Verifikasi mutasi oleh Operator (status berubah menjadi waitingKabagApproval).
  Future<Result<Mutation>> verifyMutation({
    required String mutationId,
    required String operatorName,
  });

  /// Kembalikan pengajuan mutasi ke Pemohon dengan alasan pengembalian (status berubah menjadi returned).
  Future<Result<Mutation>> returnMutation({
    required String mutationId,
    required String reason,
    required String operatorName,
  });

  /// Persetujuan mutasi oleh Kabag Aset (status berubah menjadi approved).
  Future<Result<Mutation>> approveMutationKabag({
    required String mutationId,
    required String kabagName,
  });

  /// Penolakan mutasi oleh Kabag Aset dengan alasan (status berubah menjadi rejected).
  Future<Result<Mutation>> rejectMutationKabag({
    required String mutationId,
    required String reason,
    required String kabagName,
  });

  /// Persetujuan mutasi oleh Kadiv (status berubah menjadi approved / menunggu update aset).
  Future<Result<Mutation>> approveMutationKadiv({
    required String mutationId,
    required String kadivName,
  });

  /// Penolakan mutasi oleh Kadiv dengan alasan (status berubah menjadi rejected).
  Future<Result<Mutation>> rejectMutationKadiv({
    required String mutationId,
    required String reason,
    required String kadivName,
  });

  /// Konfirmasi mutasi oleh Pemohon (status berubah menjadi completed).
  ///
  /// Hanya valid jika status saat ini adalah [MutationStatus.pendingConfirmation].
  /// Sumber: ROLE-FLOW.md §3, SCREEN-SPEC.md REQ-009.
  Future<Result<Mutation>> confirmMutation({
    required String mutationId,
    required String confirmedBy,
  });
}
