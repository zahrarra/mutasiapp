// lib/features/mutation/domain/entities/mutation.dart
//
// Domain Entity: Mutation (Pengajuan Mutasi Aset).
// Sumber: ROLE-FLOW.md §3, TECHNICAL-DESIGN.md §5, SCREEN-SPEC.md REQ-005.

import '../../../asset/domain/entities/asset.dart';
import '../../../asset/domain/entities/asset_category.dart';
import '../../../asset/domain/entities/asset_status.dart';
import 'mutation_status.dart';

/// Entity domain permohonan pengajuan mutasi aset.
class Mutation {
  final String id;

  /// Nomor Tiket Server-Generated (Format: KATEGORI-TAHUN-NOURUT, misal: ELK-2026-00124)
  final String ticketNumber;

  /// ID Aset jika terdaftar di sistem master data.
  /// Bernilai `null` jika aset belum terdaftar (fallback).
  final String? _assetId;
  String? get assetId => isUnregisteredAsset ? null : (_assetId ?? _asset?.id);

  /// Aset yang dimutasi (internal snapshot)
  final Asset? _asset;

  /// Aset yang dimutasi.
  /// Jika aset belum terdaftar, mengembalikan representasi fallback aman
  /// tanpa membuat ID dummy palsu.
  Asset get asset {
    final existing = _asset;
    if (existing != null) return existing;
    return Asset(
      id: '',
      assetCode: customSerialNumber ?? '-',
      name: customAssetName ?? 'Aset Tidak Terdaftar',
      category: const AssetCategory(
        id: 'cat_unregistered',
        code: 'OTH',
        name: 'Tidak Terdaftar',
      ),
      location: currentLocation,
      pic: currentPic,
      status: AssetStatus.available,
      condition: 'Belum Terdaftar',
      serialNumber: customSerialNumber,
      acquisitionYear: createdAt.year,
    );
  }

  /// Menandai apakah mutasi ini untuk aset yang belum terdaftar di database.
  final bool isUnregisteredAsset;

  /// Nama aset manual (jika [isUnregisteredAsset] true)
  final String? customAssetName;

  /// Nomor seri aset manual (jika [isUnregisteredAsset] true)
  final String? customSerialNumber;

  /// Getter helper untuk nama aset yang ditampilkan
  String get displayAssetName =>
      isUnregisteredAsset ? (customAssetName ?? 'Aset Tidak Terdaftar') : asset.name;

  /// Getter helper untuk kode/nomor seri aset yang ditampilkan
  String get displayAssetCode =>
      isUnregisteredAsset ? (customSerialNumber ?? '-') : asset.assetCode;

  /// ID Pemohon (user login yang mengajukan)
  final String? applicantId;

  /// Nama Pemohon
  final String applicantName;

  /// Lokasi aset saat ini sebelum mutasi
  final String currentLocation;

  /// Lokasi tujuan mutasi yang diajukan
  final String targetLocation;

  /// PIC aset saat ini
  final String currentPic;

  /// PIC / Penanggung jawab baru yang diajukan
  final String targetPic;

  /// Alasan / Justifikasi mutasi
  final String reason;

  /// Nama dokumen pendukung (opsional)
  final String? documentName;

  /// Path lokal dokumen di perangkat (opsional)
  final String? documentPath;

  /// Raw byte array dokumen untuk rendering langsung (opsional)
  final List<int>? documentBytes;

  /// Status pengajuan mutasi
  final MutationStatus status;

  /// Catatan / alasan pengembalian jika ditolak/dikembalikan oleh Operator
  final String? returnReason;

  /// Apakah mutasi ini memerlukan approval Kadiv sebelum lanjut ke Staff Aset.
  /// Ditentukan oleh Kabag Aset saat menyetujui pengajuan.
  final bool requiresKadivApproval;

  /// Catatan / alasan penolakan jika ditolak oleh Kabag Aset
  final String? rejectionReason;

  /// Tanggal verifikasi / pengembalian dilakukan oleh Operator
  final DateTime? verifiedAt;

  /// Nama Operator yang melakukan verifikasi / pengembalian
  final String? verifiedBy;

  /// Tanggal persetujuan dilakukan oleh Kabag Aset
  final DateTime? approvedAt;

  /// Nama Kabag Aset yang menyetujui
  final String? approvedBy;

  /// Tanggal penolakan dilakukan oleh Kabag Aset
  final DateTime? rejectedAt;

  /// Nama Kabag Aset yang menolak
  final String? rejectedBy;

  /// Tanggal persetujuan dilakukan oleh Kadiv
  final DateTime? kadivApprovedAt;

  /// Nama Kadiv yang menyetujui
  final String? kadivApprovedBy;

  /// Tanggal penolakan dilakukan oleh Kadiv
  final DateTime? kadivRejectedAt;

  /// Nama Kadiv yang menolak
  final String? kadivRejectedBy;

  /// Catatan / alasan penolakan jika ditolak oleh Kadiv
  final String? kadivRejectionReason;

  /// Tanggal pembaruan lokasi & PIC fisik dilakukan oleh Staff Aset
  final DateTime? staffUpdatedAt;

  /// Nama Staff Aset yang melakukan pembaruan
  final String? staffUpdatedBy;

  /// Waktu pembuatan pengajuan
  final DateTime createdAt;

  const Mutation({
    required this.id,
    required this.ticketNumber,
    String? assetId,
    Asset? asset,
    this.isUnregisteredAsset = false,
    this.customAssetName,
    this.customSerialNumber,
    this.applicantId,
    required this.applicantName,
    required this.currentLocation,
    required this.targetLocation,
    required this.currentPic,
    required this.targetPic,
    required this.reason,
    this.documentName,
    this.documentPath,
    this.documentBytes,
    required this.status,
    this.returnReason,
    this.requiresKadivApproval = false,
    this.rejectionReason,
    this.verifiedAt,
    this.verifiedBy,
    this.approvedAt,
    this.approvedBy,
    this.rejectedAt,
    this.rejectedBy,
    this.kadivApprovedAt,
    this.kadivApprovedBy,
    this.kadivRejectedAt,
    this.kadivRejectedBy,
    this.kadivRejectionReason,
    this.staffUpdatedAt,
    this.staffUpdatedBy,
    required this.createdAt,
    // ignore: prefer_initializing_formals
  })  : _assetId = assetId,
        // ignore: prefer_initializing_formals
        _asset = asset;

  Mutation copyWith({
    String? id,
    String? ticketNumber,
    String? assetId,
    Asset? asset,
    bool? isUnregisteredAsset,
    String? customAssetName,
    String? customSerialNumber,
    String? applicantId,
    String? applicantName,
    String? currentLocation,
    String? targetLocation,
    String? currentPic,
    String? targetPic,
    String? reason,
    String? documentName,
    String? documentPath,
    List<int>? documentBytes,
    MutationStatus? status,
    String? returnReason,
    bool? requiresKadivApproval,
    String? rejectionReason,
    DateTime? verifiedAt,
    String? verifiedBy,
    DateTime? approvedAt,
    String? approvedBy,
    DateTime? rejectedAt,
    String? rejectedBy,
    DateTime? kadivApprovedAt,
    String? kadivApprovedBy,
    DateTime? kadivRejectedAt,
    String? kadivRejectedBy,
    String? kadivRejectionReason,
    DateTime? staffUpdatedAt,
    String? staffUpdatedBy,
    DateTime? createdAt,
  }) {
    return Mutation(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      assetId: assetId ?? this.assetId,
      asset: asset ?? _asset,
      isUnregisteredAsset: isUnregisteredAsset ?? this.isUnregisteredAsset,
      customAssetName: customAssetName ?? this.customAssetName,
      customSerialNumber: customSerialNumber ?? this.customSerialNumber,
      applicantId: applicantId ?? this.applicantId,
      applicantName: applicantName ?? this.applicantName,
      currentLocation: currentLocation ?? this.currentLocation,
      targetLocation: targetLocation ?? this.targetLocation,
      currentPic: currentPic ?? this.currentPic,
      targetPic: targetPic ?? this.targetPic,
      reason: reason ?? this.reason,
      documentName: documentName ?? this.documentName,
      documentPath: documentPath ?? this.documentPath,
      documentBytes: documentBytes ?? this.documentBytes,
      status: status ?? this.status,
      returnReason: returnReason ?? this.returnReason,
      requiresKadivApproval:
          requiresKadivApproval ?? this.requiresKadivApproval,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      kadivApprovedAt: kadivApprovedAt ?? this.kadivApprovedAt,
      kadivApprovedBy: kadivApprovedBy ?? this.kadivApprovedBy,
      kadivRejectedAt: kadivRejectedAt ?? this.kadivRejectedAt,
      kadivRejectedBy: kadivRejectedBy ?? this.kadivRejectedBy,
      kadivRejectionReason: kadivRejectionReason ?? this.kadivRejectionReason,
      staffUpdatedAt: staffUpdatedAt ?? this.staffUpdatedAt,
      staffUpdatedBy: staffUpdatedBy ?? this.staffUpdatedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Mutation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ticketNumber == other.ticketNumber;

  @override
  int get hashCode => id.hashCode ^ ticketNumber.hashCode;
}
