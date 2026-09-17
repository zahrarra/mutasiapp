// lib/features/auth/domain/repositories/auth_repository.dart
//
// Kontrak repository autentikasi.
// Sumber: TECHNICAL-DESIGN.md §15, PROJECT-SETUP.md §14.
//
// ATURAN:
// - Ini adalah abstract contract — UI tidak bergantung pada implementasi.
// - Implementasi dapat diganti (mock → real API) tanpa mengubah UI.
// - OPEN QUESTION: mekanisme autentikasi final belum ditentukan (PRD §13.6).
//   JWT / Sanctum / OAuth / SSO — semua dapat diimplementasikan
//   tanpa mengubah interface ini.

import '../../../../core/errors/result.dart';
import '../entities/user.dart';

/// Kontrak repository untuk operasi autentikasi.
///
/// Semua implementasi (mock, API, SSO) harus mengikuti interface ini.
///
/// Implementasi saat ini: [MockAuthRepositoryImpl]
/// Implementasi production: belum ditentukan (OPEN QUESTION).
abstract class AuthRepository {
  /// Login dengan username dan password.
  ///
  /// Mengembalikan [User] jika berhasil.
  /// Mengembalikan [UnauthorizedFailure] jika credential salah.
  ///
  /// OPEN QUESTION: mekanisme autentikasi backend belum final.
  Future<Result<User>> login({
    required String username,
    required String password,
  });

  /// Ambil user yang sedang login dari session/storage.
  ///
  /// Mengembalikan [User?] — null jika belum login.
  /// Digunakan saat app start untuk memeriksa session.
  Future<Result<User?>> getCurrentUser();

  /// Logout — invalidasi session dan hapus credential tersimpan.
  Future<void> logout();
}
