// lib/features/auth/data/repositories/user_repository_impl.dart
//
// Implementasi UserRepository terintegrasi backend Laravel API & local mock fallback.
// Sumber: PRD.md §5, ROLE-FLOW.md §2, TECHNICAL-DESIGN.md §4.1.

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final ApiClient? apiClient;

  // Cache dinamis role ID dari tabel roles di backend
  static final Map<String, int> _roleNameToIdCache = {};

  // Shared state agar login & screen admin selalu mengacu pada store yang sama saat mock (apiClient == null)
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
      id: 'usr_bagian_aset',
      username: 'bagian_aset',
      name: 'Hendra Setiawan (Bagian Aset)',
      role: UserRole.bagianAset,
      email: 'aset@mutasiku.id',
      department: 'Bagian Pengelolaan Aset & Logistik',
      isActive: true,
    ),
    const User(
      id: 'usr_kadiv',
      username: 'kadiv',
      name: 'Drs. Ahmad Dahlan (Pemimpin Divisi)',
      role: UserRole.kadiv,
      email: 'kadiv@mutasiku.id',
      department: 'Divisi Umum & Aset',
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
    'usr_bagian_aset',
    'usr_kadiv',
    'usr_admin',
  };

  UserRepositoryImpl({this.apiClient});

  static final UserRepositoryImpl instance = UserRepositoryImpl();
  factory UserRepositoryImpl.withClient(ApiClient? client) =>
      UserRepositoryImpl(apiClient: client);

  /// Resolusi dinamis ID role dari backend jika tabel roles memiliki urutan ID berbeda.
  Future<int> resolveRoleId(UserRole role) async {
    final roleName = role.apiValue;
    if (_roleNameToIdCache.containsKey(roleName)) {
      return _roleNameToIdCache[roleName]!;
    }

    if (apiClient != null) {
      try {
        final res = await apiClient!.get('/api/v1/admin/roles');
        if (res is Success<Map<String, dynamic>>) {
          final list = (res.data['data'] as List<dynamic>?) ?? [];
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              final name = (item['name'] as String?)?.toLowerCase();
              final id = item['id'];
              if (name != null && id is int) {
                _roleNameToIdCache[name] = id;
              }
            }
          }
        }
      } catch (_) {}
    }

    return _roleNameToIdCache[roleName] ?? role.roleId;
  }

  @override
  Future<Result<List<User>>> getAllUsers() async {
    if (apiClient != null) {
      final response = await apiClient!.get('/api/v1/admin/users');
      switch (response) {
        case Success(:final data):
          final list = (data['data'] as List<dynamic>?) ?? [];
          final users = list.map((item) {
            final m = item as Map<String, dynamic>;
            final roleName = m['role'] as String?;
            final role = UserRole.fromApiValue(roleName) ?? UserRole.pemohon;
            return User(
              id: m['id'].toString(),
              username: (m['nip'] ?? m['email'] ?? '').toString(),
              name: (m['name'] ?? '').toString(),
              email: m['email'] as String?,
              department: (m['department'] as String?) ?? 'Unit Kerja',
              role: role,
              isActive: m['is_active'] == true,
              mustChangePassword: m['must_change_password'] == true,
            );
          }).toList();
          return Result.success(users);
        case AppFailure(:final failure):
          // Kegagalan API nyata dilaporkan langsung ke pemanggil, tidak disamarkan
          return Result.failure(failure);
      }
    }

    // Fallback murni untuk lingkungan pengujian test non-HTTP
    return Result.success(List.unmodifiable(_users));
  }

  @override
  Future<Result<User>> getUserById(String id) async {
    if (apiClient != null) {
      final response = await apiClient!.get('/api/v1/admin/users/$id');
      switch (response) {
        case Success(:final data):
          final m = (data['data'] ?? data) as Map<String, dynamic>;
          final roleName = m['role'] as String?;
          final role = UserRole.fromApiValue(roleName) ?? UserRole.pemohon;
          return Result.success(
            User(
              id: m['id'].toString(),
              username: (m['nip'] ?? m['email'] ?? '').toString(),
              name: (m['name'] ?? '').toString(),
              email: m['email'] as String?,
              department: (m['department'] as String?) ?? 'Unit Kerja',
              role: role,
              isActive: m['is_active'] == true,
              mustChangePassword: m['must_change_password'] == true,
            ),
          );
        case AppFailure(:final failure):
          return Result.failure(failure);
      }
    }

    try {
      final user = _users.firstWhere((u) => u.id == id);
      return Result.success(user);
    } catch (_) {
      return Result.failure(
        const NotFoundFailure(message: 'User tidak ditemukan.'),
      );
    }
  }

  @override
  Future<Result<User>> getUserByUsername(String username) async {
    final clean = username.trim().toLowerCase();
    if (apiClient != null) {
      final all = await getAllUsers();
      switch (all) {
        case Success(:final data):
          try {
            final found = data.firstWhere(
              (u) =>
                  u.username.toLowerCase() == clean ||
                  (u.email?.toLowerCase() == clean),
            );
            return Result.success(found);
          } catch (_) {
            return Result.failure(
              const NotFoundFailure(message: 'User tidak ditemukan.'),
            );
          }
        case AppFailure(:final failure):
          return Result.failure(failure);
      }
    }

    try {
      final user = _users.firstWhere(
        (u) =>
            u.username.trim().toLowerCase() == clean ||
            (u.email?.trim().toLowerCase() == clean),
      );
      return Result.success(user);
    } catch (_) {
      return Result.failure(
        const NotFoundFailure(message: 'User tidak ditemukan.'),
      );
    }
  }

  @override
  Future<Result<User>> createUser(User user, {String? password}) async {
    final cleanUsername = user.username.trim();
    if (cleanUsername.isEmpty || user.name.trim().isEmpty) {
      return Result.failure(
        const ValidationFailure(message: 'Nama dan username wajib diisi.'),
      );
    }

    if (apiClient != null) {
      final resolvedRoleId = await resolveRoleId(user.role);
      final response = await apiClient!.post(
        '/api/v1/admin/users',
        body: {
          'name': user.name.trim(),
          'email': user.email?.trim(),
          'password': password ?? 'password',
          'role_id': resolvedRoleId,
          'role': user.role.apiValue,
          if (cleanUsername.isNotEmpty) 'nip': cleanUsername,
          'is_active': user.isActive,
        },
      );

      switch (response) {
        case Success(:final data):
          final m = (data['data'] ?? data) as Map<String, dynamic>;
          final roleName = m['role'] as String?;
          final role = UserRole.fromApiValue(roleName) ?? user.role;
          final created = User(
            id: m['id'].toString(),
            username: (m['nip'] ?? m['email'] ?? cleanUsername).toString(),
            name: (m['name'] ?? user.name).toString(),
            email: m['email'] as String? ?? user.email,
            department: user.department,
            role: role,
            isActive: m['is_active'] == true,
            mustChangePassword: m['must_change_password'] == true,
          );
          return Result.success(created);

        case AppFailure(:final failure):
          return Result.failure(failure);
      }
    }

    final exists = _users.any(
      (u) => u.username.toLowerCase() == cleanUsername.toLowerCase(),
    );
    if (exists) {
      return Result.failure(
        ValidationFailure(
          message: 'Username "$cleanUsername" sudah digunakan.',
        ),
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
  Future<Result<User>> updateUser(User user, {String? password}) async {
    final cleanUsername = user.username.trim();
    if (apiClient != null) {
      final resolvedRoleId = await resolveRoleId(user.role);
      final body = <String, dynamic>{
        'name': user.name.trim(),
        if (user.email != null) 'email': user.email!.trim(),
        'role_id': resolvedRoleId,
        'role': user.role.apiValue,
        if (cleanUsername.isNotEmpty) 'nip': cleanUsername,
        'is_active': user.isActive,
        if (password != null && password.isNotEmpty) 'password': password,
      };

      final response = await apiClient!.put(
        '/api/v1/admin/users/${user.id}',
        body: body,
      );

      switch (response) {
        case Success(:final data):
          final m = (data['data'] ?? data) as Map<String, dynamic>;
          final roleName = m['role'] as String?;
          final role = UserRole.fromApiValue(roleName) ?? user.role;
          final updated = user.copyWith(
            name: (m['name'] ?? user.name).toString(),
            email: m['email'] as String? ?? user.email,
            role: role,
            isActive: m['is_active'] == true,
          );
          return Result.success(updated);

        case AppFailure(:final failure):
          return Result.failure(failure);
      }
    }

    final index = _users.indexWhere((u) => u.id == user.id);
    if (index == -1) {
      return Result.failure(
        const NotFoundFailure(message: 'User tidak ditemukan.'),
      );
    }

    final duplicate = _users.any(
      (u) =>
          u.id != user.id &&
          u.username.toLowerCase() == cleanUsername.toLowerCase(),
    );
    if (duplicate) {
      return Result.failure(
        ValidationFailure(
          message: 'Username "$cleanUsername" sudah digunakan.',
        ),
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
    if (apiClient != null) {
      final response = await apiClient!.put(
        '/api/v1/admin/users/$id',
        body: {'is_active': isActive},
      );
      switch (response) {
        case Success():
          return Result.success(null);
        case AppFailure(:final failure):
          return Result.failure(failure);
      }
    }

    final index = _users.indexWhere((u) => u.id == id);
    if (index == -1) {
      return Result.failure(
        const NotFoundFailure(message: 'User tidak ditemukan.'),
      );
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

    if (apiClient != null) {
      final response = await apiClient!.delete('/api/v1/admin/users/$id');
      switch (response) {
        case Success():
          return Result.success(null);
        case AppFailure(:final failure):
          return Result.failure(failure);
      }
    }

    _users.removeWhere((u) => u.id == id);
    return Result.success(null);
  }
}
