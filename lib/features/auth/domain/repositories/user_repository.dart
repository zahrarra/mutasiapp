// lib/features/auth/domain/repositories/user_repository.dart
//
// Kontrak repository untuk manajemen data master User oleh Admin.
// Sumber: PRD.md §5, ROLE-FLOW.md §2.

import '../../../../core/errors/result.dart';
import '../entities/user.dart';

abstract class UserRepository {
  /// Mengambil seluruh data user (aktif maupun nonaktif).
  Future<Result<List<User>>> getAllUsers();

  /// Mengambil user berdasarkan ID.
  Future<Result<User>> getUserById(String id);

  /// Mengambil user berdasarkan username (case-insensitive).
  Future<Result<User>> getUserByUsername(String username);

  /// Menambahkan user baru.
  Future<Result<User>> createUser(User user);

  /// Memperbarui informasi user.
  Future<Result<User>> updateUser(User user);

  /// Mengaktifkan atau menonaktifkan akun user.
  Future<Result<void>> toggleUserActive(String id, bool isActive);

  /// Menghapus user jika aman (tidak memiliki riwayat mutasi/histori).
  Future<Result<void>> deleteUser(String id);
}
