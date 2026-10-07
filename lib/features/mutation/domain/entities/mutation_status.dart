// lib/features/mutation/domain/entities/mutation_status.dart
//
// Enum status workflow mutasi.
// Sumber: ROLE-FLOW.md §1, TECHNICAL-DESIGN.md.

import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

/// Enum status workflow mutasi aset.
/// Enum status workflow mutasi aset.
/// Sumber: PRD V1.1 §7.
enum MutationStatus {
  /// Baru diajukan oleh Pemohon, menunggu pemeriksaan kelengkapan Operator.
  submitted,

  /// Telah dinyatakan lengkap oleh Operator dan sedang diverifikasi oleh Bagian Aset.
  waitingAssetVerification,

  /// Pengajuan dikembalikan oleh Operator atau Bagian Aset ke Pemohon.
  returned,

  /// Lolos verifikasi Bagian Aset, menunggu approval Pemimpin Divisi.
  waitingDivisionHeadApproval,

  /// Pengajuan ditolak oleh Pemimpin Divisi.
  rejected,

  /// Disetujui Pemimpin Divisi, menunggu konfirmasi fisik oleh Pemohon.
  waitingConfirmation,

  /// Pemohon telah memilih 'Sesuai' dan pembaruan data aset selesai.
  completed,

  /// Status lokal: pengajuan disimpan saat offline menunggu sinkronisasi server.
  waitingSync,

  // ─── Legacy Compatibility Aliases ──────────────────────────────────────────
  /// Legacy alias: waitingKabagApproval -> waitingAssetVerification.
  waitingKabagApproval,

  /// Legacy alias: waitingKadivApproval -> waitingDivisionHeadApproval.
  waitingKadivApproval,

  /// Legacy alias.
  verified,

  /// Legacy alias: approved -> waitingConfirmation.
  approved,

  /// Legacy alias: pendingConfirmation -> waitingConfirmation.
  pendingConfirmation;

  /// Label tampilan bahasa Indonesia sesuai PRD V1.1 §7.
  String get displayName => switch (this) {
        MutationStatus.submitted => 'Diajukan',
        MutationStatus.waitingAssetVerification =>
          'Menunggu Verifikasi Bagian Aset',
        MutationStatus.returned => 'Dikembalikan ke Pemohon',
        MutationStatus.waitingDivisionHeadApproval =>
          'Menunggu Approval Pemimpin Divisi',
        MutationStatus.rejected => 'Ditolak',
        MutationStatus.waitingConfirmation => 'Menunggu Konfirmasi Pemohon',
        MutationStatus.completed => 'Selesai',
        MutationStatus.waitingSync => 'Menunggu Sinkronisasi',

        // Legacy compatibility
        MutationStatus.waitingKabagApproval => 'Menunggu Verifikasi Bagian Aset',
        MutationStatus.waitingKadivApproval =>
          'Menunggu Approval Pemimpin Divisi',
        MutationStatus.verified => 'Terverifikasi',
        MutationStatus.approved => 'Disetujui',
        MutationStatus.pendingConfirmation => 'Menunggu Konfirmasi Pemohon',
      };

  /// Warna teks badge.
  Color get color => switch (this) {
        MutationStatus.submitted => AppColors.info,
        MutationStatus.waitingAssetVerification => AppColors.warning,
        MutationStatus.returned => AppColors.warning,
        MutationStatus.waitingDivisionHeadApproval => AppColors.warning,
        MutationStatus.rejected => AppColors.error,
        MutationStatus.waitingConfirmation => AppColors.warning,
        MutationStatus.completed => AppColors.success,
        MutationStatus.waitingSync => AppColors.textSecondary,

        // Legacy
        MutationStatus.waitingKabagApproval => AppColors.warning,
        MutationStatus.waitingKadivApproval => AppColors.warning,
        MutationStatus.verified => AppColors.info,
        MutationStatus.approved => AppColors.success,
        MutationStatus.pendingConfirmation => AppColors.warning,
      };

  /// Warna container badge.
  Color get backgroundColor => switch (this) {
        MutationStatus.submitted => AppColors.infoContainer,
        MutationStatus.waitingAssetVerification => AppColors.warningContainer,
        MutationStatus.returned => AppColors.warningContainer,
        MutationStatus.waitingDivisionHeadApproval =>
          AppColors.warningContainer,
        MutationStatus.rejected => AppColors.errorContainer,
        MutationStatus.waitingConfirmation => AppColors.warningContainer,
        MutationStatus.completed => AppColors.successContainer,
        MutationStatus.waitingSync => AppColors.surface,

        // Legacy
        MutationStatus.waitingKabagApproval => AppColors.warningContainer,
        MutationStatus.waitingKadivApproval => AppColors.warningContainer,
        MutationStatus.verified => AppColors.infoContainer,
        MutationStatus.approved => AppColors.successContainer,
        MutationStatus.pendingConfirmation => AppColors.warningContainer,
      };

  /// Helper untuk mengecek status verifikasi bagian aset.
  bool get isWaitingAssetVerification =>
      this == MutationStatus.waitingAssetVerification ||
      this == MutationStatus.waitingKabagApproval;

  /// Helper untuk mengecek status approval pemimpin divisi.
  bool get isWaitingDivisionApproval =>
      this == MutationStatus.waitingDivisionHeadApproval ||
      this == MutationStatus.waitingKadivApproval;

  /// Helper untuk mengecek status konfirmasi pemohon.
  bool get isWaitingConfirmation =>
      this == MutationStatus.waitingConfirmation ||
      this == MutationStatus.pendingConfirmation ||
      this == MutationStatus.approved;

  /// Mengonversi nilai string status dari API backend Laravel ke enum [MutationStatus].
  ///
  /// Status backend yang valid:
  /// - `diajukan` -> [MutationStatus.submitted]
  /// - `menunggu_verifikasi_bagian_aset` -> [MutationStatus.waitingAssetVerification]
  /// - `dikembalikan_ke_pemohon` -> [MutationStatus.returned]
  /// - `menunggu_approval_pemimpin_divisi` -> [MutationStatus.waitingDivisionHeadApproval]
  /// - `ditolak` -> [MutationStatus.rejected]
  /// - `menunggu_konfirmasi_pemohon` -> [MutationStatus.waitingConfirmation]
  /// - `selesai` -> [MutationStatus.completed]
  ///
  /// Fallback aman jika status tidak dikenali atau null adalah [MutationStatus.submitted].
  static MutationStatus fromApiValue(String? value) {
    if (value == null) return MutationStatus.submitted;
    switch (value.trim().toLowerCase()) {
      case 'diajukan':
        return MutationStatus.submitted;
      case 'menunggu_verifikasi_bagian_aset':
        return MutationStatus.waitingAssetVerification;
      case 'dikembalikan_ke_pemohon':
        return MutationStatus.returned;
      case 'menunggu_approval_pemimpin_divisi':
        return MutationStatus.waitingDivisionHeadApproval;
      case 'ditolak':
        return MutationStatus.rejected;
      case 'menunggu_konfirmasi_pemohon':
        return MutationStatus.waitingConfirmation;
      case 'selesai':
        return MutationStatus.completed;
      // Status lokal / legacy fallback
      case 'waiting_sync':
      case 'menunggu_sinkronisasi':
        return MutationStatus.waitingSync;
      default:
        return MutationStatus.submitted;
    }
  }

  /// Nilai status untuk komunikasi dengan API backend.
  String get apiValue => switch (this) {
        MutationStatus.submitted => 'diajukan',
        MutationStatus.waitingAssetVerification =>
          'menunggu_verifikasi_bagian_aset',
        MutationStatus.returned => 'dikembalikan_ke_pemohon',
        MutationStatus.waitingDivisionHeadApproval =>
          'menunggu_approval_pemimpin_divisi',
        MutationStatus.rejected => 'ditolak',
        MutationStatus.waitingConfirmation => 'menunggu_konfirmasi_pemohon',
        MutationStatus.completed => 'selesai',
        MutationStatus.waitingSync => 'diajukan',
        // Legacy
        MutationStatus.waitingKabagApproval =>
          'menunggu_verifikasi_bagian_aset',
        MutationStatus.waitingKadivApproval =>
          'menunggu_approval_pemimpin_divisi',
        MutationStatus.verified => 'menunggu_verifikasi_bagian_aset',
        MutationStatus.approved => 'menunggu_konfirmasi_pemohon',
        MutationStatus.pendingConfirmation => 'menunggu_konfirmasi_pemohon',
      };
}

