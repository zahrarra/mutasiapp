// lib/features/auth/domain/entities/user_permission.dart
//
// Permission enum untuk RBAC MutasiKu.
// Sumber: ROLE-FLOW.md §9, TECHNICAL-DESIGN.md §6.

/// Hak akses spesifik dalam sistem MutasiKu.
enum UserPermission {
  /// Kelola user, role, lokasi, kategori aset (Admin).
  manageMasterData,

  /// Membuat dan mengajukan mutasi baru (Pemohon).
  submitMutation,

  /// Mengonfirmasi hasil mutasi aset (Sesuai / Tidak Sesuai) (Pemohon).
  confirmMutation,

  /// Pemeriksaan kelengkapan pengajuan dan dokumen (Operator).
  verifyMutation,

  /// Verifikasi keabsahan data aset, lokasi, SK SDM, dan penentuan PIC baru (Bagian Aset).
  verifyAssetData,

  /// Review & approval mutasi final (Pemimpin Divisi / Kadiv).
  approveKadiv,

  /// Review & approval mutasi level Kabag Aset (Legacy).
  approveKabag,

  /// Update lokasi & PIC aset (Legacy Staff Aset).
  updateAssetLocation,

  /// Melihat notifikasi aktivitas mutasi (Semua Role).
  viewNotifications,
}
