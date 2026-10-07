// lib/features/auth/data/repositories/auth_repository_impl.dart
//
// Implementasi AuthRepository terintegrasi backend Laravel API & local SecureStorage.
// Sumber: SKILLS.md §5 (authentication), TECHNICAL-DESIGN.md §4.1.

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_repository.dart';
import 'user_repository_impl.dart';

/// Implementasi [AuthRepository] dengan integrasi HTTP [ApiClient] dan [SecureStorage].
class AuthRepositoryImpl implements AuthRepository {
  final SecureStorage secureStorage;
  final ApiClient? apiClient;
  final UserRepository? userRepository;
  User? _currentUser;

  AuthRepositoryImpl({
    required this.secureStorage,
    this.apiClient,
    UserRepository? userRepository,
  }) : userRepository = userRepository ?? (apiClient == null ? UserRepositoryImpl.instance : null);

  @override
  Future<Result<User>> login({
    required String username,
    required String password,
  }) async {
    if (username.trim().isEmpty || password.isEmpty) {
      return Result.failure(
        const ValidationFailure(message: 'Email dan password tidak boleh kosong'),
      );
    }

    // Alur utama: Otentikasi langsung ke API backend Laravel
    if (apiClient != null) {
      final response = await apiClient!.post(
        '/api/v1/auth/login',
        body: {
          'email': username.trim(),
          'password': password,
        },
      );

      switch (response) {
        case Success(:final data):
          final success = data['success'] as bool? ?? false;
          if (!success) {
            return Result.failure(
              UnauthorizedFailure(
                message: data['message'] as String? ?? 'Email atau password salah.',
              ),
            );
          }

          final token = (data['token'] ?? data['data']?['token']) as String?;
          if (token == null || token.isEmpty) {
            return Result.failure(
              const ServerFailure(message: 'Token autentikasi tidak valid'),
            );
          }

          final userMap =
              (data['user'] ?? data['data']?['user']) as Map<String, dynamic>?;
          if (userMap == null) {
            return Result.failure(
              const ServerFailure(message: 'Data user tidak valid'),
            );
          }

          final roleStr =
              (data['role'] ?? userMap['role'] ?? data['data']?['role']) as String?;
          final role = UserRole.fromApiValue(roleStr) ?? UserRole.pemohon;

          final user = User(
            id: userMap['id'].toString(),
            username: userMap['email'] as String? ?? username,
            name: userMap['name'] as String? ?? '',
            email: userMap['email'] as String? ?? username,
            role: role,
            department: userMap['department'] as String? ?? 'Aset & Logistik',
            isActive: userMap['is_active'] as bool? ?? true,
          );

          _currentUser = user;
          await secureStorage.saveAuthToken(token);
          await secureStorage.saveUserId(user.id);
          apiClient!.setAuthToken(token);

          return Result.success(user);

        case AppFailure(:final failure):
          return Result.failure(failure);
      }
    }

    // Fallback: in-memory mock untuk unit test yang tidak menggunakan HTTP
    if (userRepository != null) {
      final userResult = await userRepository!.getUserByUsername(username);
      if (userResult is Success<User>) {
        final found = userResult.data;
        if (!found.isActive) {
          return Result.failure(
            const UnauthorizedFailure(
              message:
                  'Akun Anda telah dinonaktifkan oleh Administrator. Silakan hubungi Admin.',
            ),
          );
        }
        _currentUser = found;
        await secureStorage.saveAuthToken('token_${found.id}');
        await secureStorage.saveUserId(found.id);
        return Result.success(found);
      }
    }

    return Result.failure(
      const UnauthorizedFailure(message: 'Email atau password salah.'),
    );
  }

  @override
  Future<void> logout() async {
    if (apiClient != null) {
      try {
        await apiClient!.post('/api/v1/auth/logout');
      } catch (_) {}
      apiClient!.clearAuthToken();
    }
    _currentUser = null;
    await secureStorage.clearAll();
  }

  @override
  Future<Result<User?>> getCurrentUser() async {
    if (_currentUser != null) return Result.success(_currentUser);

    final hasToken = await secureStorage.hasAuthToken();
    if (!hasToken) return Result.success(null);

    final token = await secureStorage.getAuthToken();
    if (token != null && apiClient != null) {
      apiClient!.setAuthToken(token);
      final response = await apiClient!.get('/api/v1/auth/me');
      switch (response) {
        case Success(:final data):
          final userMap = data['data']?['user'] as Map<String, dynamic>?;
          if (userMap != null) {
            final roleStr = userMap['role'] as String?;
            final role = UserRole.fromApiValue(roleStr) ?? UserRole.pemohon;

            _currentUser = User(
              id: userMap['id'].toString(),
              username: userMap['email'] as String? ?? '',
              name: userMap['name'] as String? ?? '',
              email: userMap['email'] as String? ?? '',
              role: role,
              department: userMap['department'] as String? ?? 'Aset & Logistik',
              isActive: userMap['is_active'] as bool? ?? true,
            );
            return Result.success(_currentUser);
          }
          return Result.success(null);

        case AppFailure():
          await secureStorage.clearAll();
          apiClient!.clearAuthToken();
          return Result.success(null);
      }
    }

    final userId = await secureStorage.getUserId();
    if (userId == null) return Result.success(null);

    if (userRepository != null) {
      final userResult = await userRepository!.getUserById(userId);
      if (userResult is Success<User>) {
        _currentUser = userResult.data;
        return Result.success(_currentUser);
      }
    }

    return Result.success(null);
  }
}
