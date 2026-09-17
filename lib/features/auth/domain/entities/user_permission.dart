// lib/features/auth/domain/entities/user_permission.dart
//
// Permission enum untuk RBAC MutasiKu.
// Sumber: ROLE-FLOW.md §9, TECHNICAL-DESIGN.md §6.

/// Hak akses spesifik dalam sistem MutasiKu.
enum UserPermission {
  /// Kelola user, role, lokasi, kategori, kriteria approval (Admin).
  manageMasterData,

  /// Membuat dan mengajukan mutasi baru (Pemohon).
  submitMutation,

  /// Mengonfirmasi hasil mutasi aset yang selesai di-update (Pemohon).
  confirmMutation,

  /// Verifikasi kelengkapan dan validitas pengajuan mutasi (Operator).
  verifyMutation,

  /// Review & approval mutasi level Kabag Aset (Kabag Aset).
  approveKabag,

  /// Review & approval mutasi kondisional level Kadiv (Kadiv).
  approveKadiv,

  /// Update lokasi & PIC aset serta simpan riwayat mutasi (Staff Aset).
  updateAssetLocation,

  /// Melihat notifikasi aktivitas mutasi (Semua Role).
  viewNotifications,
}
