// lib/features/auth/domain/entities/user.dart
//
// Domain entity: User.
// Sumber: PROJECT-SETUP.md §10, TECHNICAL-DESIGN.md §10.

import 'user_permission.dart';
import 'user_role.dart';

/// Domain entity untuk pengguna yang terautentikasi.
class User {
  const User({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    this.email,
    this.department,
    this.isActive = true,
  });

  /// Identifier unik user (dari backend).
  final String id;

  /// Username untuk login.
  final String username;

  /// Nama lengkap user.
  final String name;

  /// Role aktif user pada MVP.
  final UserRole role;

  /// Email user (opsional).
  final String? email;

  /// Departemen user (opsional).
  final String? department;

  /// Status aktif user (true = aktif, false = dinonaktifkan).
  final bool isActive;

  /// Periksa apakah user memiliki permission tertentu melalui rolenya.
  bool hasPermission(UserPermission permission) => role.hasPermission(permission);

  // ─── Equality ─────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username &&
          name == other.name &&
          role == other.role &&
          email == other.email &&
          department == other.department &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      username.hashCode ^
      name.hashCode ^
      role.hashCode ^
      email.hashCode ^
      department.hashCode ^
      isActive.hashCode;

  // ─── Copy ─────────────────────────────────────────────────────────────────

  User copyWith({
    String? id,
    String? username,
    String? name,
    UserRole? role,
    String? email,
    String? department,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      role: role ?? this.role,
      email: email ?? this.email,
      department: department ?? this.department,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() =>
      'User(id: $id, username: $username, name: $name, role: ${role.displayName}, active: $isActive)';
}
