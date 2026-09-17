// lib/features/auth/domain/usecases/login_usecase.dart
//
// Use case: Login.
// Sumber: TECHNICAL-DESIGN.md §11 (Repository Pattern).

import '../../../../core/errors/result.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case: login dengan username dan password.
class LoginUseCase {
  const LoginUseCase({required this.repository});

  final AuthRepository repository;

  /// Eksekusi login.
  Future<Result<User>> call({
    required String username,
    required String password,
  }) {
    return repository.login(username: username, password: password);
  }
}
