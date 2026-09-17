// lib/features/auth/domain/entities/user_role.dart
//
// Role enum untuk domain layer.
// Sumber: AGENTS.md §10, TECHNICAL-DESIGN.md §7, ROLE-FLOW.md §9–10.
//
// ATURAN:
// - Gunakan enum ini di seluruh UI — jangan gunakan string role mentah.
// - Mapping dari string API dilakukan di data layer (UserModel).
// - Admin dan Operator adalah role BERBEDA (AGENTS.md §10).

import 'user_permission.dart';

/// Enum role pengguna MutasiKu.
enum UserRole {
  /// Administrator — mengelola master data.
  admin,

  /// Pemohon — mengajukan dan mengkonfirmasi mutasi.
  pemohon,

  /// Operator — memverifikasi pengajuan.
  operator,

  /// Kepala Bagian Aset — menyetujui atau menolak pengajuan.
  kabagAset,

  /// Kepala Divisi — approval kondisional.
  kadiv,

  /// Staff Aset — memperbarui data aset setelah approval.
  staffAset;

  // ─── Display ──────────────────────────────────────────────────────────────

  /// Label tampilan untuk role ini.
  String get displayName => switch (this) {
        UserRole.admin => 'Admin',
        UserRole.pemohon => 'Pemohon',
        UserRole.operator => 'Operator',
        UserRole.kabagAset => 'Kabag Aset',
        UserRole.kadiv => 'Kadiv',
        UserRole.staffAset => 'Staff Aset',
      };

  /// Label alias untuk displayName.
  String get label => displayName;

  // ─── Default Route ────────────────────────────────────────────────────────

  /// Path navigasi default (home) setelah login untuk role ini.
  /// Sumber: ROLE-FLOW.md §10.
  String get defaultRoute => switch (this) {
        UserRole.admin => '/admin/dashboard',
        UserRole.pemohon => '/pemohon/dashboard',
        UserRole.operator => '/operator/dashboard',
        UserRole.kabagAset => '/kabag/dashboard',
        UserRole.kadiv => '/kadiv/dashboard',
        UserRole.staffAset => '/staff-aset/dashboard',
      };

  // ─── Route Prefix ─────────────────────────────────────────────────────────

  /// Prefix route yang diizinkan untuk role ini.
  String get routePrefix => switch (this) {
        UserRole.admin => '/admin',
        UserRole.pemohon => '/pemohon',
        UserRole.operator => '/operator',
        UserRole.kabagAset => '/kabag',
        UserRole.kadiv => '/kadiv',
        UserRole.staffAset => '/staff-aset',
      };

  // ─── Permissions ──────────────────────────────────────────────────────────

  /// Daftar permission yang dimiliki oleh role ini.
  /// Sumber: ROLE-FLOW.md §9.
  Set<UserPermission> get permissions => switch (this) {
        UserRole.admin => {
            UserPermission.manageMasterData,
            UserPermission.viewNotifications,
          },
        UserRole.pemohon => {
            UserPermission.submitMutation,
            UserPermission.confirmMutation,
            UserPermission.viewNotifications,
          },
        UserRole.operator => {
            UserPermission.verifyMutation,
            UserPermission.viewNotifications,
          },
        UserRole.kabagAset => {
            UserPermission.approveKabag,
            UserPermission.viewNotifications,
          },
        UserRole.kadiv => {
            UserPermission.approveKadiv,
            UserPermission.viewNotifications,
          },
        UserRole.staffAset => {
            UserPermission.updateAssetLocation,
            UserPermission.viewNotifications,
          },
      };

  /// Periksa apakah role memiliki [permission] tertentu.
  bool hasPermission(UserPermission permission) =>
      permissions.contains(permission);

  // ─── Mapping dari string API ───────────────────────────────────────────────

  /// String nilai yang diharapkan dari API untuk role ini.
  String get apiValue => switch (this) {
        UserRole.admin => 'admin',
        UserRole.pemohon => 'pemohon',
        UserRole.operator => 'operator',
        UserRole.kabagAset => 'kabag_aset',
        UserRole.kadiv => 'kadiv',
        UserRole.staffAset => 'staff_aset',
      };

  /// Parse dari string API.
  static UserRole? fromApiValue(String? value) {
    if (value == null) return null;
    return switch (value.toLowerCase()) {
      'admin' => UserRole.admin,
      'pemohon' => UserRole.pemohon,
      'operator' => UserRole.operator,
      'kabag_aset' || 'kabagaset' || 'kabag aset' => UserRole.kabagAset,
      'kadiv' => UserRole.kadiv,
      'staff_aset' || 'staffaset' || 'staff aset' => UserRole.staffAset,
      _ => null,
    };
  }
}
