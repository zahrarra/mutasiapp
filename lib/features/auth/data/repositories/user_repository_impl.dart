// lib/features/auth/data/repositories/user_repository_impl.dart
//
// Implementasi in-memory UserRepository untuk data master User.
// Sumber: PRD.md §5, ROLE-FLOW.md §2.

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  // Shared state agar login & screen admin selalu mengacu pada store yang sama
  static final List<User> _users = [
    const User(
      id: 'usr_pemohon',
      username: 'pemohon',
      name: 'Rina (Pemohon)',
      role: UserRole.pemohon,
      email: 'pemohon@mutasiku.id',
      department: 'Divisi Keuangan & Akuntansi',
      isActive: true,
    ),
    const User(
      id: 'usr_operator',
      username: 'operator',
      name: 'Budi Santoso (Operator)',
      role: UserRole.operator,
      email: 'operator@mutasiku.id',
      department: 'Operasional Logistik & Inventaris',
      isActive: true,
    ),
    const User(
      id: 'usr_kabag',
      username: 'kabag',
      name: 'H. M. Yusuf (Kabag Aset)',
      role: UserRole.kabagAset,
      email: 'kabag@mutasiku.id',
      department: 'Bagian Pengelolaan Aset Perusahaan',
      isActive: true,
    ),
    const User(
      id: 'usr_kadiv',
      username: 'kadiv',
      name: 'Drs. Ahmad Dahlan (Kadiv)',
      role: UserRole.kadiv,
      email: 'kadiv@mutasiku.id',
      department: 'Divisi Umum & Perlengkapan',
      isActive: true,
    ),
    const User(
      id: 'usr_staff',
      username: 'staff',
      name: 'Rizky Pratama (Staff Aset)',
      role: UserRole.staffAset,
      email: 'staff@mutasiku.id',
      department: 'Staf Pemeliharaan & Lapangan',
      isActive: true,
    ),
    const User(
      id: 'usr_admin',
      username: 'admin',
      name: 'System Administrator',
      role: UserRole.admin,
      email: 'admin@mutasiku.id',
      department: 'IT Enterprise & Governance',
      isActive: true,
    ),
  ];

  static const Set<String> _protectedUserIds = {
    'usr_pemohon',
    'usr_operator',
    'usr_kabag',
    'usr_kadiv',
    'usr_staff',
    'usr_admin',
  };

  static final UserRepositoryImpl instance = UserRepositoryImpl._();
  UserRepositoryImpl._();
  factory UserRepositoryImpl() => instance;

  @override
  Future<Result<List<User>>> getAllUsers() async {
    return Result.success(List.unmodifiable(_users));
  }

  @override
  Future<Result<User>> getUserById(String id) async {
    try {
      final user = _users.firstWhere((u) => u.id == id);
      return Result.success(user);
    } catch (_) {
      return Result.failure(const NotFoundFailure(message: 'User tidak ditemukan.'));
    }
  }

  @override
  Future<Result<User>> getUserByUsername(String username) async {
    try {
      final user = _users.firstWhere(
        (u) => u.username.trim().toLowerCase() == username.trim().toLowerCase(),
      );
      return Result.success(user);
    } catch (_) {
      return Result.failure(const NotFoundFailure(message: 'User tidak ditemukan.'));
    }
  }

  @override
  Future<Result<User>> createUser(User user) async {
    final cleanUsername = user.username.trim();
    if (cleanUsername.isEmpty || user.name.trim().isEmpty) {
      return Result.failure(
        const ValidationFailure(message: 'Nama dan username wajib diisi.'),
      );
    }

    final exists = _users.any(
      (u) => u.username.toLowerCase() == cleanUsername.toLowerCase(),
    );
    if (exists) {
      return Result.failure(
        ValidationFailure(message: 'Username "$cleanUsername" sudah digunakan.'),
      );
    }

    final newId = user.id.isNotEmpty
        ? user.id
        : 'usr_${DateTime.now().millisecondsSinceEpoch}';

    final newUser = user.copyWith(
      id: newId,
      username: cleanUsername,
      name: user.name.trim(),
      email: user.email?.trim(),
      department: user.department?.trim(),
      isActive: true,
    );

    _users.add(newUser);
    return Result.success(newUser);
  }

  @override
  Future<Result<User>> updateUser(User user) async {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index == -1) {
      return Result.failure(const NotFoundFailure(message: 'User tidak ditemukan.'));
    }

    final cleanUsername = user.username.trim();
    final duplicate = _users.any(
      (u) =>
          u.id != user.id &&
          u.username.toLowerCase() == cleanUsername.toLowerCase(),
    );
    if (duplicate) {
      return Result.failure(
        ValidationFailure(message: 'Username "$cleanUsername" sudah digunakan.'),
      );
    }

    final updated = user.copyWith(
      username: cleanUsername,
      name: user.name.trim(),
      email: user.email?.trim(),
      department: user.department?.trim(),
    );

    _users[index] = updated;
    return Result.success(updated);
  }

  @override
  Future<Result<void>> toggleUserActive(String id, bool isActive) async {
    final index = _users.indexWhere((u) => u.id == id);
    if (index == -1) {
      return Result.failure(const NotFoundFailure(message: 'User tidak ditemukan.'));
    }

    _users[index] = _users[index].copyWith(isActive: isActive);
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteUser(String id) async {
    if (_protectedUserIds.contains(id)) {
      return Result.failure(
        const ValidationFailure(
          message:
              'User sistem/histori tidak dapat dihapus permanen untuk menjaga integritas data. Silakan nonaktifkan akun.',
        ),
      );
    }

    _users.removeWhere((u) => u.id == id);
    return Result.success(null);
  }
}
