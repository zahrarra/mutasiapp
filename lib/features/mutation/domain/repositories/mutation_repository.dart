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

  /// Menandakan apakah mutasi untuk aset yang belum terdaftar di database.
  final bool isUnregisteredAsset;

  /// Nama aset manual (jika [isUnregisteredAsset] true).
  final String? customAssetName;

  /// Nomor seri aset manual (jika [isUnregisteredAsset] true).
  final String? customSerialNumber;

  const SubmitMutationParams({
    this.applicantId,
    this.applicantName,
    this.assetId,
    this.assetName = '',
    required this.sourceLocation,
    required this.targetLocation,
    this.currentPic,
    required this.targetPic,
    required this.reason,
    this.documentName,
    this.documentPath,
    this.documentBytes,
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

  /// Verifikasi mutasi oleh Operator.
  Future<Result<Mutation>> verifyMutation({
    required String mutationId,
    required String operatorName,
    bool requiresKadivApproval = false,
  });

  /// Kembalikan pengajuan mutasi ke Pemohon.
  Future<Result<Mutation>> returnMutation({
    required String mutationId,
    required String reason,
    required String operatorName,
  });

  /// Persetujuan mutasi oleh Kabag Aset.
  ///
  /// Jika [requiresKadivApproval] true, status menjadi [waitingKadivApproval].
  /// Jika false, status menjadi [approved] (langsung ke Staff Aset).
  Future<Result<Mutation>> approveMutationKabag({
    required String mutationId,
    required String kabagName,
    required bool requiresKadivApproval,
  });

  /// Penolakan mutasi oleh Kabag Aset.
  Future<Result<Mutation>> rejectMutationKabag({
    required String mutationId,
    required String reason,
    required String kabagName,
  });

  /// Persetujuan mutasi oleh Kadiv.
  Future<Result<Mutation>> approveMutationKadiv({
    required String mutationId,
    required String kadivName,
  });

  /// Penolakan mutasi oleh Kadiv.
  Future<Result<Mutation>> rejectMutationKadiv({
    required String mutationId,
    required String reason,
    required String kadivName,
  });

  /// Konfirmasi mutasi oleh Pemohon.
  Future<Result<Mutation>> confirmMutation({
    required String mutationId,
    required String confirmedBy,
  });

  /// Pembaruan lokasi dan PIC fisik aset oleh Staff Aset.
  ///
  /// Mengubah status mutasi dari [approved] menjadi [pendingConfirmation].
  Future<Result<Mutation>> processStaffAssetUpdate({
    required String mutationId,
    required String newLocation,
    required String newPic,
    required String staffName,
  });
}
