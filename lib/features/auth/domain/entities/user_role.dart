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

  /// Operator — memeriksa kelengkapan pengajuan & dokumen.
  operator,

  /// Bagian Aset — memverifikasi keabsahan data aset & menentukan PIC baru.
  bagianAset,

  /// Kepala Bagian Aset (Legacy alias untuk bagianAset).
  kabagAset,

  /// Pemimpin Divisi Umum dan Aset (Kadiv) — approval final.
  kadiv,

  /// Staff Aset (Legacy).
  staffAset;

  /// Daftar role aktif resmi sesuai PRD V1.1 §5.
  static const List<UserRole> activeRoles = [
    UserRole.admin,
    UserRole.pemohon,
    UserRole.operator,
    UserRole.bagianAset,
    UserRole.kadiv,
  ];

  // ─── Display ──────────────────────────────────────────────────────────────

  /// Label tampilan untuk role ini.
  String get displayName => switch (this) {
        UserRole.admin => 'Admin',
        UserRole.pemohon => 'Pemohon',
        UserRole.operator => 'Operator',
        UserRole.bagianAset => 'Bagian Aset',
        UserRole.kabagAset => 'Kabag Aset',
        UserRole.kadiv => 'Pemimpin Divisi',
        UserRole.staffAset => 'Staff Aset',
      };

  /// Label alias untuk displayName.
  String get label => displayName;

  // ─── Default Route ────────────────────────────────────────────────────────

  /// Path navigasi default (home) setelah login untuk role ini.
  /// Sumber: ROLE-FLOW.md §10 & PRD V1.1.
  String get defaultRoute => switch (this) {
        UserRole.admin => '/admin/dashboard',
        UserRole.pemohon => '/pemohon/dashboard',
        UserRole.operator => '/operator/dashboard',
        UserRole.bagianAset => '/bagian-aset/dashboard',
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
        UserRole.bagianAset => '/bagian-aset',
        UserRole.kabagAset => '/kabag',
        UserRole.kadiv => '/kadiv',
        UserRole.staffAset => '/staff-aset',
      };

  // ─── Permissions ──────────────────────────────────────────────────────────

  /// Daftar permission yang dimiliki oleh role ini.
  /// Sumber: PRD V1.1 §5.
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
        UserRole.bagianAset => {
            UserPermission.verifyAssetData,
            UserPermission.approveKabag,
            UserPermission.updateAssetLocation,
            UserPermission.viewNotifications,
          },
        UserRole.kabagAset => {
            UserPermission.verifyAssetData,
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
        UserRole.bagianAset => 'bagian_aset',
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
      'kadiv' ||
      'pemimpin_divisi' ||
      'pemimpin divisi' ||
      'kadiv_aset' ||
      'kadiv aset' ||
      'pemimpin_divisi_aset' ||
      'pemimpin divisi aset' ||
      'kepala_divisi' ||
      'kepala divisi' =>
        UserRole.kadiv,
      'bagian_aset' || 'bagianaset' || 'bagian aset' || 'aset' => UserRole.bagianAset,
      'kabag_aset' || 'kabagaset' || 'kabag aset' => UserRole.kabagAset,
      'staff_aset' || 'staffaset' || 'staff aset' => UserRole.staffAset,
      _ => null,
    };
  }
}
