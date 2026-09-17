// lib/features/asset/domain/entities/asset_status.dart
//
// Enum status aset MutasiKu.
// Sumber: SKILLS.md §7 (asset-management), TECHNICAL-DESIGN.md §8.

import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

/// Enum status kondisi / ketersediaan aset.
enum AssetStatus {
  /// Aset aktif, siap digunakan atau dimutasi.
  available,

  /// Aset sedang dalam proses mutasi aktif (locked for new mutation).
  inMutation,

  /// Aset dalam perbaikan / perawatan.
  maintenance,

  /// Aset telah di-disposisi / di-penghapusan.
  disposed;

  /// Label tampilan bahasa Indonesia.
  String get displayName => switch (this) {
        AssetStatus.available => 'Tersedia',
        AssetStatus.inMutation => 'Dalam Mutasi',
        AssetStatus.maintenance => 'Perawatan',
        AssetStatus.disposed => 'Disposisi',
      };

  /// Warna teks badge.
  Color get color => switch (this) {
        AssetStatus.available => AppColors.success,
        AssetStatus.inMutation => AppColors.warning,
        AssetStatus.maintenance => AppColors.info,
        AssetStatus.disposed => AppColors.textDisabled,
      };

  /// Warna container / background badge.
  Color get backgroundColor => switch (this) {
        AssetStatus.available => AppColors.successContainer,
        AssetStatus.inMutation => AppColors.warningContainer,
        AssetStatus.maintenance => AppColors.infoContainer,
        AssetStatus.disposed => AppColors.disabledBackground,
      };

  /// Parse dari string API.
  static AssetStatus fromApiValue(String? value) {
    if (value == null) return AssetStatus.available;
    return switch (value.toLowerCase()) {
      'available' || 'tersedia' => AssetStatus.available,
      'in_mutation' || 'mutating' || 'dalam mutasi' => AssetStatus.inMutation,
      'maintenance' || 'perawatan' => AssetStatus.maintenance,
      'disposed' || 'disposisi' => AssetStatus.disposed,
      _ => AssetStatus.available,
    };
  }
}
