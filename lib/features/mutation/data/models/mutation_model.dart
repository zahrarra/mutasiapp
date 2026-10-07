// lib/features/mutation/data/models/mutation_model.dart
//
// DTO & Mapper untuk Entity Mutation.
// Memetakan JSON response Laravel (/api/v1/mutations) ke Entity Mutation.

import '../../../asset/domain/entities/asset.dart';
import '../../../asset/domain/entities/asset_category.dart';
import '../../../asset/domain/entities/asset_status.dart';
import '../../domain/entities/mutation.dart';
import '../../domain/entities/mutation_status.dart';

/// Metadata pagination dari response Laravel API.
class MutationPaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const MutationPaginationMeta({
    this.currentPage = 1,
    this.lastPage = 1,
    this.perPage = 15,
    this.total = 0,
  });

  factory MutationPaginationMeta.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MutationPaginationMeta();
    return MutationPaginationMeta(
      currentPage: _parseInt(json['current_page'] ?? json['currentPage'], 1),
      lastPage: _parseInt(json['last_page'] ?? json['lastPage'], 1),
      perPage: _parseInt(json['per_page'] ?? json['perPage'], 15),
      total: _parseInt(json['total'], 0),
    );
  }

  static int _parseInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}

/// DTO pembungkus response pagination dari Laravel API.
class PaginatedMutationResponse {
  final bool success;
  final String message;
  final List<MutationModel> data;
  final MutationPaginationMeta meta;

  const PaginatedMutationResponse({
    this.success = true,
    this.message = '',
    required this.data,
    required this.meta,
  });

  factory PaginatedMutationResponse.fromJson(Map<String, dynamic> json) {
    final list = MutationModel.listFromJson(json['data']);
    final metaMap = json['meta'] as Map<String, dynamic>?;
    return PaginatedMutationResponse(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? '',
      data: list,
      meta: MutationPaginationMeta.fromJson(metaMap),
    );
  }
}

/// Data Model / DTO untuk [Mutation].
class MutationModel extends Mutation {
  const MutationModel({
    required super.id,
    required super.ticketNumber,
    super.assetId,
    super.asset,
    super.isUnregisteredAsset = false,
    super.customAssetName,
    super.customSerialNumber,
    super.applicantId,
    required super.applicantName,
    required super.currentLocation,
    required super.targetLocation,
    required super.currentPic,
    required super.targetPic,
    required super.reason,
    super.documentName,
    super.documentPath,
    super.documentBytes,
    required super.status,
    super.isAssetMovingWithApplicant = true,
    super.confirmationReason,
    super.returnReason,
    super.requiresKadivApproval = false,
    super.rejectionReason,
    super.verifiedAt,
    super.verifiedBy,
    super.assetVerifiedAt,
    super.assetVerifiedBy,
    super.assetReturnReason,
    super.approvedAt,
    super.approvedBy,
    super.rejectedAt,
    super.rejectedBy,
    super.kadivApprovedAt,
    super.kadivApprovedBy,
    super.kadivRejectedAt,
    super.kadivRejectedBy,
    super.kadivRejectionReason,
    super.staffUpdatedAt,
    super.staffUpdatedBy,
    required super.createdAt,
  });

  /// Konversi dari Entity [Mutation] ke [MutationModel].
  factory MutationModel.fromEntity(Mutation mutation) {
    return MutationModel(
      id: mutation.id,
      ticketNumber: mutation.ticketNumber,
      assetId: mutation.assetId,
      asset: mutation.asset,
      isUnregisteredAsset: mutation.isUnregisteredAsset,
      customAssetName: mutation.customAssetName,
      customSerialNumber: mutation.customSerialNumber,
      applicantId: mutation.applicantId,
      applicantName: mutation.applicantName,
      currentLocation: mutation.currentLocation,
      targetLocation: mutation.targetLocation,
      currentPic: mutation.currentPic,
      targetPic: mutation.targetPic,
      reason: mutation.reason,
      documentName: mutation.documentName,
      documentPath: mutation.documentPath,
      documentBytes: mutation.documentBytes,
      status: mutation.status,
      isAssetMovingWithApplicant: mutation.isAssetMovingWithApplicant,
      confirmationReason: mutation.confirmationReason,
      returnReason: mutation.returnReason,
      requiresKadivApproval: mutation.requiresKadivApproval,
      rejectionReason: mutation.rejectionReason,
      verifiedAt: mutation.verifiedAt,
      verifiedBy: mutation.verifiedBy,
      assetVerifiedAt: mutation.assetVerifiedAt,
      assetVerifiedBy: mutation.assetVerifiedBy,
      assetReturnReason: mutation.assetReturnReason,
      approvedAt: mutation.approvedAt,
      approvedBy: mutation.approvedBy,
      rejectedAt: mutation.rejectedAt,
      rejectedBy: mutation.rejectedBy,
      kadivApprovedAt: mutation.kadivApprovedAt,
      kadivApprovedBy: mutation.kadivApprovedBy,
      kadivRejectedAt: mutation.kadivRejectedAt,
      kadivRejectedBy: mutation.kadivRejectedBy,
      kadivRejectionReason: mutation.kadivRejectionReason,
      staffUpdatedAt: mutation.staffUpdatedAt,
      staffUpdatedBy: mutation.staffUpdatedBy,
      createdAt: mutation.createdAt,
    );
  }

  /// Memetakan JSON response Laravel (/api/v1/mutations) ke [MutationModel].
  factory MutationModel.fromJson(Map<String, dynamic> json) {
    // 1. Ekstraksi nested Applicant
    final applicantMap = json['applicant'] as Map<String, dynamic>?;
    final applicantId = applicantMap?['id']?.toString() ??
        json['applicant_id']?.toString() ??
        json['applicantId']?.toString();
    final applicantName = applicantMap?['name']?.toString() ??
        json['applicant_name']?.toString() ??
        json['applicantName']?.toString() ??
        'Pemohon';

    // 2. Ekstraksi nested Location (.name)
    final originLocMap = json['origin_location'] as Map<String, dynamic>?;
    final currentLocation = originLocMap?['name']?.toString() ??
        json['current_location']?.toString() ??
        json['currentLocation']?.toString() ??
        'Lokasi Asal';

    final destLocMap = json['destination_location'] as Map<String, dynamic>?;
    final targetLocation = destLocMap?['name']?.toString() ??
        json['target_location']?.toString() ??
        json['targetLocation']?.toString() ??
        'Lokasi Tujuan';

    // 3. Ekstraksi nested PIC (.name)
    final currentPicMap = json['current_pic'] as Map<String, dynamic>?;
    final currentPic = currentPicMap?['name']?.toString() ??
        json['current_pic_name']?.toString() ??
        (json['current_pic'] is String ? json['current_pic'] as String : null) ??
        json['currentPic']?.toString() ??
        '-';

    final targetPicMap = json['target_pic'] as Map<String, dynamic>?;
    final targetPic = targetPicMap?['name']?.toString() ??
        json['target_pic_name']?.toString() ??
        (json['target_pic'] is String ? json['target_pic'] as String : null) ??
        json['targetPic']?.toString() ??
        '-';

    // 4. Ekstraksi nested Asset
    Asset? assetEntity;
    final assetMap = json['asset'] as Map<String, dynamic>?;
    if (assetMap != null) {
      final catMap = assetMap['category'] as Map<String, dynamic>?;
      final category = AssetCategory(
        id: catMap?['id']?.toString() ?? 'cat_unregistered',
        code: catMap?['code']?.toString() ?? 'OTH',
        name: catMap?['name']?.toString() ?? 'Umum',
      );

      final locMap = assetMap['location'] as Map<String, dynamic>?;
      final assetLocation = locMap?['name']?.toString() ??
          (assetMap['location'] is String ? assetMap['location'] as String : null) ??
          currentLocation;

      final picObj = assetMap['pic'] as Map<String, dynamic>?;
      final assetPic = picObj?['name']?.toString() ??
          (assetMap['pic'] is String ? assetMap['pic'] as String : null) ??
          currentPic;

      final acqYear = int.tryParse(
              assetMap['acquisition_year']?.toString() ??
                  assetMap['acquisitionYear']?.toString() ??
                  '') ??
          DateTime.now().year;

      final estValue = double.tryParse(
          assetMap['estimated_value']?.toString() ??
              assetMap['estimatedValue']?.toString() ??
              '');

      assetEntity = Asset(
        id: assetMap['id']?.toString() ?? '',
        assetCode: assetMap['asset_code']?.toString() ??
            assetMap['assetCode']?.toString() ??
            '-',
        name: assetMap['name']?.toString() ?? 'Aset',
        category: category,
        location: assetLocation,
        pic: assetPic,
        status: AssetStatus.inMutation,
        condition: assetMap['condition']?.toString() ?? 'Baik',
        serialNumber: assetMap['serial_number']?.toString() ??
            assetMap['serialNumber']?.toString(),
        acquisitionYear: acqYear,
        estimatedValue: estValue,
        hasActiveMutation: json['status'] != 'selesai' && json['status'] != 'ditolak',
        activeMutationTicket: json['ticket_number']?.toString(),
      );
    }

    // 5. Ekstraksi Dokumen SK
    final skDoc = json['sk_document']?.toString() ?? json['skDocument']?.toString();
    final docPath = json['document_path']?.toString() ??
        json['documentPath']?.toString() ??
        skDoc;
    final docName = json['document_name']?.toString() ??
        json['documentName']?.toString() ??
        (docPath != null ? docPath.split(RegExp(r'[\\/]')).last : null);

    // 6. Boolean is_asset_moves_with_applicant
    final isMovingRaw = json['is_asset_moves_with_applicant'] ??
        json['isAssetMovingWithApplicant'];
    bool isMoving = true;
    if (isMovingRaw is bool) {
      isMoving = isMovingRaw;
    } else if (isMovingRaw != null) {
      isMoving = isMovingRaw == 1 ||
          isMovingRaw == '1' ||
          isMovingRaw == 'true';
    }

    // 7. Status mapping
    final status = MutationStatus.fromApiValue(json['status']?.toString());

    // 8. Reasons
    final returnReason = json['return_reason']?.toString() ??
        json['returnReason']?.toString();
    final rejectionReason = json['rejection_reason']?.toString() ??
        json['rejectionReason']?.toString();
    final confirmationReason = json['confirmation_reason']?.toString() ??
        json['confirmationReason']?.toString();

    // 9. Timestamps & Audit
    final createdAt = _parseDateTime(json['created_at'] ?? json['createdAt']) ??
        DateTime.now();

    final verifiedAt = _parseDateTime(json['verified_at'] ?? json['verifiedAt']);
    final verifiedBy = json['verified_by']?.toString() ?? json['verifiedBy']?.toString();

    final assetVerifiedAt =
        _parseDateTime(json['asset_verified_at'] ?? json['assetVerifiedAt']);
    final assetVerifiedBy = json['asset_verified_by']?.toString() ??
        json['assetVerifiedBy']?.toString();
    final assetReturnReason = json['asset_return_reason']?.toString() ??
        json['assetReturnReason']?.toString() ??
        returnReason;

    final approvedAt = _parseDateTime(json['approved_at'] ?? json['approvedAt']);
    final approvedBy = json['approved_by']?.toString() ?? json['approvedBy']?.toString();

    final rejectedAt = _parseDateTime(json['rejected_at'] ?? json['rejectedAt']);
    final rejectedBy = json['rejected_by']?.toString() ?? json['rejectedBy']?.toString();

    final kadivApprovedAt =
        _parseDateTime(json['kadiv_approved_at'] ?? json['kadivApprovedAt']);
    final kadivApprovedBy = json['kadiv_approved_by']?.toString() ??
        json['kadivApprovedBy']?.toString();

    final kadivRejectedAt =
        _parseDateTime(json['kadiv_rejected_at'] ?? json['kadivRejectedAt']);
    final kadivRejectedBy = json['kadiv_rejected_by']?.toString() ??
        json['kadivRejectedBy']?.toString();
    final kadivRejectionReason = json['kadiv_rejection_reason']?.toString() ??
        json['kadivRejectionReason']?.toString() ??
        rejectionReason;

    final staffUpdatedAt =
        _parseDateTime(json['staff_updated_at'] ?? json['staffUpdatedAt']);
    final staffUpdatedBy = json['staff_updated_by']?.toString() ??
        json['staffUpdatedBy']?.toString();

    final requiresKadivApproval = json['requires_kadiv_approval'] as bool? ??
        json['requiresKadivApproval'] as bool? ??
        false;

    return MutationModel(
      id: json['id']?.toString() ?? '',
      ticketNumber: json['ticket_number']?.toString() ??
          json['ticketNumber']?.toString() ??
          '',
      assetId: json['asset_id']?.toString() ?? json['assetId']?.toString(),
      asset: assetEntity,
      isUnregisteredAsset: json['is_unregistered_asset'] as bool? ??
          json['isUnregisteredAsset'] as bool? ??
          false,
      customAssetName: json['custom_asset_name']?.toString() ??
          json['customAssetName']?.toString(),
      customSerialNumber: json['custom_serial_number']?.toString() ??
          json['customSerialNumber']?.toString(),
      applicantId: applicantId,
      applicantName: applicantName,
      currentLocation: currentLocation,
      targetLocation: targetLocation,
      currentPic: currentPic,
      targetPic: targetPic,
      reason: json['reason']?.toString() ?? '',
      documentName: docName,
      documentPath: docPath,
      status: status,
      isAssetMovingWithApplicant: isMoving,
      confirmationReason: confirmationReason,
      returnReason: returnReason,
      requiresKadivApproval: requiresKadivApproval,
      rejectionReason: rejectionReason,
      verifiedAt: verifiedAt,
      verifiedBy: verifiedBy,
      assetVerifiedAt: assetVerifiedAt,
      assetVerifiedBy: assetVerifiedBy,
      assetReturnReason: assetReturnReason,
      approvedAt: approvedAt,
      approvedBy: approvedBy,
      rejectedAt: rejectedAt,
      rejectedBy: rejectedBy,
      kadivApprovedAt: kadivApprovedAt,
      kadivApprovedBy: kadivApprovedBy,
      kadivRejectedAt: kadivRejectedAt,
      kadivRejectedBy: kadivRejectedBy,
      kadivRejectionReason: kadivRejectionReason,
      staffUpdatedAt: staffUpdatedAt,
      staffUpdatedBy: staffUpdatedBy,
      createdAt: createdAt,
    );
  }

  /// Mengonversi struktur list dinamis atau paginated payload menjadi `List<MutationModel>`.
  static List<MutationModel> listFromJson(dynamic json) {
    if (json == null) return [];
    if (json is List) {
      return json
          .whereType<Map<String, dynamic>>()
          .map((item) => MutationModel.fromJson(item))
          .toList();
    }
    if (json is Map<String, dynamic>) {
      final innerData = json['data'];
      if (innerData is List) {
        return innerData
            .whereType<Map<String, dynamic>>()
            .map((item) => MutationModel.fromJson(item))
            .toList();
      }
      if (innerData is Map<String, dynamic>) {
        return [MutationModel.fromJson(innerData)];
      }
    }
    return [];
  }

  /// Helper parsing DateTime secara aman.
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  /// Mengembalikan instance domain entity [Mutation].
  Mutation toEntity() => this;

  /// Konversi ke Map JSON (opsional / untuk keperluan serialisasi lokal).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_number': ticketNumber,
      'asset_id': assetId,
      'applicant_id': applicantId,
      'applicant_name': applicantName,
      'current_location': currentLocation,
      'target_location': targetLocation,
      'current_pic': currentPic,
      'target_pic': targetPic,
      'reason': reason,
      'sk_document': documentPath,
      'status': status.apiValue,
      'is_asset_moves_with_applicant': isAssetMovingWithApplicant,
      'return_reason': returnReason,
      'rejection_reason': rejectionReason,
      'confirmation_reason': confirmationReason,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
