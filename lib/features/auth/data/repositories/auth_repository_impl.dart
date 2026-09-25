// lib/features/auth/data/repositories/auth_repository_impl.dart
//
// Implementasi skeleton AuthRepository untuk Foundation.
// Sumber: SKILLS.md §5 (authentication), TECHNICAL-DESIGN.md §4.1.

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/auth_repository.dart';

import '../../domain/repositories/user_repository.dart';
import 'user_repository_impl.dart';

/// Implementasi in-memory & secure storage untuk [AuthRepository].
class AuthRepositoryImpl implements AuthRepository {
  final SecureStorage secureStorage;
  final UserRepository userRepository;
  User? _currentUser;

  AuthRepositoryImpl({
    required this.secureStorage,
    UserRepository? userRepository,
  }) : userRepository = userRepository ?? UserRepositoryImpl.instance;

  @override
  Future<Result<User>> login({
    required String username,
    required String password,
  }) async {
    if (username.trim().isEmpty || password.isEmpty) {
      return Result.failure(
        const ValidationFailure(message: 'Username dan password tidak boleh kosong'),
      );
    }

    final userResult = await userRepository.getUserByUsername(username);
    User user;
    if (userResult is Success<User>) {
      final found = userResult.data;
      if (!found.isActive) {
        return Result.failure(
          const UnauthorizedFailure(
            message: 'Akun Anda telah dinonaktifkan oleh Administrator. Silakan hubungi Admin.',
          ),
        );
      }
      user = found;
    } else {
      // Determine role based on username prefix for testing convenience
      UserRole role = UserRole.pemohon;
      final lower = username.toLowerCase();
      if (lower.contains('admin')) {
        role = UserRole.admin;
      } else if (lower.contains('operator')) {
        role = UserRole.operator;
      } else if (lower.contains('kabag')) {
        role = UserRole.kabagAset;
      } else if (lower.contains('kadiv')) {
        role = UserRole.kadiv;
      } else if (lower.contains('staff')) {
        role = UserRole.staffAset;
      }

      final userId = role == UserRole.pemohon
          ? 'usr_pemohon'
          : 'usr_${DateTime.now().millisecondsSinceEpoch}';

      user = User(
        id: userId,
        username: username,
        name: username.toUpperCase(),
        email: '$lower@mutasiku.id',
        role: role,
        department: 'Aset & Logistik',
        isActive: true,
      );
    }

    _currentUser = user;
    await secureStorage.saveAuthToken('token_${user.id}');
    await secureStorage.saveUserId(user.id);

    return Result.success(user);
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    await secureStorage.clearAll();
  }

  @override
  Future<Result<User?>> getCurrentUser() async {
    if (_currentUser != null) return Result.success(_currentUser);

    final hasToken = await secureStorage.hasAuthToken();
    if (!hasToken) return Result.success(null);

    final userId = await secureStorage.getUserId();
    if (userId == null) return Result.success(null);

    final userResult = await userRepository.getUserById(userId);
    if (userResult is Success<User>) {
      _currentUser = userResult.data;
    } else {
      _currentUser = User(
        id: userId,
        username: 'user_mutasiku',
        name: 'User MutasiKu',
        email: 'user@mutasiku.id',
        role: UserRole.pemohon,
        department: 'Umum',
      );
    }
    return Result.success(_currentUser);
  }
}
