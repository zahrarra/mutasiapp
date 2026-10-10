// lib/features/mutation/domain/repositories/mutation_repository.dart
//
// Kontrak repository Mutation Submission.
// Sumber: ROLE-FLOW.md §3, TECHNICAL-DESIGN.md §19, SCREEN-SPEC.md REQ-003–007.

import '../../../../core/errors/result.dart';
import '../entities/mutation.dart';

/// Parameter untuk mengajukan mutasi baru.
class SubmitMutationParams {
  /// ID user yang mengajukan mutasi.
  ///
  /// Diisi otomatis dari user yang sedang login
  /// pada SubmitMutationNotifier.
  final String? applicantId;
  final String? applicantName;

  final String? assetId;
  final String assetName;
  final String sourceLocation;
  final String targetLocation;
  final String? currentPic;
  final String targetPic;
  final String reason;
  final String? documentName;
  final String? documentPath;
  final List<int>? documentBytes;

  /// Pertanyaan: "Aset ikut saya pindah?" (Ya / Tidak) (PRD V1.1 §6.2).
  final bool isAssetMovingWithApplicant;

  /// Menandakan apakah mutasi untuk aset yang belum terdaftar di database (legacy).
  final bool isUnregisteredAsset;

  /// Nama aset manual (jika [isUnregisteredAsset] true).
  final String? customAssetName;

  /// Nomor seri aset manual (jika [isUnregisteredAsset] true).
  final String? customSerialNumber;

  /// ID database riil lokasi tujuan (jika tersedia dari master data).
  final String? destinationLocationId;

  const SubmitMutationParams({
    this.applicantId,
    this.applicantName,
    this.assetId,
    this.assetName = '',
    required this.sourceLocation,
    required this.targetLocation,
    this.destinationLocationId,
    this.currentPic,
    required this.targetPic,
    required this.reason,
    this.documentName,
    this.documentPath,
    this.documentBytes,
    this.isAssetMovingWithApplicant = true,
    this.isUnregisteredAsset = false,
    this.customAssetName,
    this.customSerialNumber,
  });
}

/// Kontrak repository untuk fitur pengajuan mutasi.
abstract class MutationRepository {
  /// Ajukan mutasi baru.
  ///
  /// Mengembalikan [Mutation] dengan ticket number
  /// yang di-generate oleh repository/server.
  Future<Result<Mutation>> submitMutation(SubmitMutationParams params);

  /// Perbarui pengajuan mutasi yang dikembalikan ke Pemohon.
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

  /// Ambil semua daftar mutasi.
  ///
  /// Digunakan oleh Operator untuk melihat seluruh pengajuan.
  Future<Result<List<Mutation>>> getAllMutations();

  // ─── PRD V1.1 Workflow Operations ──────────────────────────────────────────

  /// Pemeriksaan kelengkapan oleh Operator: Teruskan ke Bagian Aset (PRD V1.1 §6.3).
  Future<Result<Mutation>> operatorForward({
    required String mutationId,
    required String operatorName,
  });

  /// Pemeriksaan kelengkapan oleh Operator: Kembalikan ke Pemohon dengan alasan (PRD V1.1 §6.3).
  Future<Result<Mutation>> operatorReturn({
    required String mutationId,
    required String reason,
    required String operatorName,
  });

  /// Verifikasi data aset oleh Bagian Aset: Teruskan ke Pemimpin Divisi (PRD V1.1 §6.4).
  /// [newPic] wajib diisi jika saat pengajuan pemohon tidak membawa aset (PIC kosong).
  Future<Result<Mutation>> assetSectionForward({
    required String mutationId,
    required String verifierName,
    String? newPic,
  });

  /// Verifikasi data aset oleh Bagian Aset: Kembalikan ke Pemohon dengan alasan (PRD V1.1 §6.4).
  Future<Result<Mutation>> assetSectionReturn({
    required String mutationId,
    required String reason,
    required String verifierName,
  });

  /// Persetujuan final oleh Pemimpin Divisi (PRD V1.1 §6.5).
  Future<Result<Mutation>> divisionApprove({
    required String mutationId,
    required String divisionHeadName,
  });

  /// Penolakan final oleh Pemimpin Divisi dengan alasan (PRD V1.1 §6.5).
  Future<Result<Mutation>> divisionReject({
    required String mutationId,
    required String reason,
    required String divisionHeadName,
  });

  /// Konfirmasi hasil mutasi oleh Pemohon (PRD V1.1 §6.6):
  /// - [isSesuai] true -> status Selesai, server otomatis update lokasi & PIC aset master, riwayat disimpan.
  /// - [isSesuai] false -> status kembali ke Bagian Aset dengan [reason].
  Future<Result<Mutation>> confirmMutationResult({
    required String mutationId,
    required String confirmedBy,
    required bool isSesuai,
    String? reason,
  });

  /// Melaporkan ketidaksesuaian fisik hasil mutasi oleh Pemohon (POST /mutations/{id}/report-discrepancy).
  Future<Result<Mutation>> reportDiscrepancy({
    required String mutationId,
    required String reason,
  });

  // ─── Legacy Compatibility Methods ──────────────────────────────────────────

  /// Verifikasi mutasi oleh Operator (Legacy).
  Future<Result<Mutation>> verifyMutation({
    required String mutationId,
    required String operatorName,
    bool requiresKadivApproval = false,
  });

  /// Kembalikan pengajuan mutasi ke Pemohon (Legacy).
  Future<Result<Mutation>> returnMutation({
    required String mutationId,
    required String reason,
    required String operatorName,
  });

  /// Persetujuan mutasi oleh Kadiv (Legacy).
  Future<Result<Mutation>> approveMutationKadiv({
    required String mutationId,
    required String kadivName,
  });

  /// Penolakan mutasi oleh Kadiv (Legacy).
  Future<Result<Mutation>> rejectMutationKadiv({
    required String mutationId,
    required String reason,
    required String kadivName,
  });

  /// Konfirmasi mutasi oleh Pemohon (Legacy).
  Future<Result<Mutation>> confirmMutation({
    required String mutationId,
    required String confirmedBy,
  });
}
