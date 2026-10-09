// lib/features/auth/domain/entities/user_role.dart
//
// Role enum untuk domain layer resmi PRD V1.1.
// Sumber: AGENTS.md §10, TECHNICAL-DESIGN.md §7, ROLE-FLOW.md §9–10, PRD V1.1 §5.
//
// ATURAN:
// - Gunakan enum ini di seluruh UI — jangan gunakan string role mentah.
// - Mapping dari string API dilakukan di data layer (UserModel).
// - Role aktif hanya 5: Admin, Pemohon, Operator, Bagian Aset, Pemimpin Divisi (Kadiv).

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

  /// Pemimpin Divisi Umum dan Aset (Kadiv) — approval final.
  kadiv;

  /// Daftar role aktif resmi sesuai PRD V1.1 §5.
  static const List<UserRole> activeRoles = [
    UserRole.admin,
    UserRole.pemohon,
    UserRole.operator,
    UserRole.bagianAset,
    UserRole.kadiv,
  ];

  /// ID numerik role sesuai database backend.
  int get roleId => switch (this) {
    UserRole.admin => 1,
    UserRole.pemohon => 2,
    UserRole.operator => 3,
    UserRole.bagianAset => 4,
    UserRole.kadiv => 5,
  };

  /// Parse role dari ID numerik database backend.
  static UserRole fromRoleId(int id) => switch (id) {
    1 => UserRole.admin,
    2 => UserRole.pemohon,
    3 => UserRole.operator,
    4 => UserRole.bagianAset,
    5 => UserRole.kadiv,
    _ => UserRole.pemohon,
  };

  // ─── Display ──────────────────────────────────────────────────────────────

  /// Label tampilan untuk role ini.
  String get displayName => switch (this) {
    UserRole.admin => 'Admin',
    UserRole.pemohon => 'Pemohon',
    UserRole.operator => 'Operator',
    UserRole.bagianAset => 'Bagian Aset',
    UserRole.kadiv => 'Pemimpin Divisi',
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
    UserRole.kadiv => '/kadiv/dashboard',
  };

  // ─── Route Prefix ─────────────────────────────────────────────────────────

  /// Prefix route yang diizinkan untuk role ini.
  String get routePrefix => switch (this) {
    UserRole.admin => '/admin',
    UserRole.pemohon => '/pemohon',
    UserRole.operator => '/operator',
    UserRole.bagianAset => '/bagian-aset',
    UserRole.kadiv => '/kadiv',
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
      UserPermission.viewNotifications,
    },
    UserRole.kadiv => {
      UserPermission.approveKadiv,
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
    UserRole.kadiv => 'pemimpin_divisi',
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
      'kepala divisi' => UserRole.kadiv,
      'bagian_aset' ||
      'bagianaset' ||
      'bagian aset' ||
      'aset' ||
      'kabag_aset' ||
      'kabagaset' ||
      'kabag aset' ||
      'staff_aset' ||
      'staffaset' ||
      'staff aset' => UserRole.bagianAset,
      _ => null,
    };
  }
}
