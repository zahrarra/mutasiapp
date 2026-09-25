// lib/features/mutation/domain/entities/mutation_status.dart
//
// Enum status workflow mutasi.
// Sumber: ROLE-FLOW.md §1, TECHNICAL-DESIGN.md.

import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

/// Enum status workflow mutasi aset.
enum MutationStatus {
  /// Baru diajukan oleh Pemohon, menunggu verifikasi Operator.
  submitted,

  /// Dikembalikan oleh Operator ke Pemohon karena tidak valid / dokumen tidak lengkap.
  returned,

  /// Telah diverifikasi Operator valid, menunggu approval Kabag Aset.
  waitingKabagApproval,

  /// Telah disetujui Kabag Aset dan memenuhi kriteria Kadiv, menunggu approval Kadiv.
  waitingKadivApproval,

  /// Telah diverifikasi Operator (alias / kompatibilitas).
  verified,

  /// Disetujui oleh Kabag (dan Kadiv jika diperlukan), menunggu update lokasi oleh Staff Aset.
  approved,

  /// Ditolak oleh Kabag Aset atau Kadiv.
  rejected,

  /// Telah di-update oleh Staff Aset, menunggu konfirmasi Pemohon.
  pendingConfirmation,

  /// Mutasi selesai dan dikonfirmasi oleh Pemohon.
  completed;

  /// Label tampilan bahasa Indonesia.
  String get displayName => switch (this) {
        MutationStatus.submitted => 'Diajukan',
        MutationStatus.returned => 'Dikembalikan ke Pemohon',
        MutationStatus.waitingKabagApproval => 'Menunggu Approval Kabag',
        MutationStatus.waitingKadivApproval => 'Menunggu Approval Kadiv',
        MutationStatus.verified => 'Terverifikasi',
        MutationStatus.approved => 'Disetujui — Menunggu Update Aset',
        MutationStatus.rejected => 'Ditolak',
        MutationStatus.pendingConfirmation => 'Menunggu Konfirmasi',
        MutationStatus.completed => 'Selesai',
      };

  /// Warna teks badge.
  Color get color => switch (this) {
        MutationStatus.submitted => AppColors.info,
        MutationStatus.returned => AppColors.warning,
        MutationStatus.waitingKabagApproval => AppColors.warning,
        MutationStatus.waitingKadivApproval => AppColors.warning,
        MutationStatus.verified => AppColors.info,
        MutationStatus.approved => AppColors.success,
        MutationStatus.rejected => AppColors.error,
        MutationStatus.pendingConfirmation => AppColors.warning,
        MutationStatus.completed => AppColors.success,
      };

  /// Warna container badge.
  Color get backgroundColor => switch (this) {
        MutationStatus.submitted => AppColors.infoContainer,
        MutationStatus.returned => AppColors.warningContainer,
        MutationStatus.waitingKabagApproval => AppColors.warningContainer,
        MutationStatus.waitingKadivApproval => AppColors.warningContainer,
        MutationStatus.verified => AppColors.infoContainer,
        MutationStatus.approved => AppColors.successContainer,
        MutationStatus.rejected => AppColors.errorContainer,
        MutationStatus.pendingConfirmation => AppColors.warningContainer,
        MutationStatus.completed => AppColors.successContainer,
      };
}
