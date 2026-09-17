// lib/features/auth/domain/usecases/logout_usecase.dart

import '../repositories/auth_repository.dart';

/// Use case: logout — invalidasi session dan hapus credential tersimpan.
class LogoutUseCase {
  const LogoutUseCase({required this.repository});

  final AuthRepository repository;

  Future<void> call() => repository.logout();
}
