// lib/features/auth/presentation/providers/auth_provider.dart
//
// Riverpod auth providers & state notifier for authentication flow.
// Sumber: TECHNICAL-DESIGN.md §4.1, PROJECT-SETUP.md §11.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';

import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/user_repository.dart';

/// Provider untuk [UserRepository].
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl.instance;
});

/// Provider untuk [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final userRepo = ref.watch(userRepositoryProvider);
  return AuthRepositoryImpl(
    secureStorage: secureStorage,
    userRepository: userRepo,
  );
});

/// Notifier untuk manajemen Master User oleh Admin.
class MasterUsersNotifier extends StateNotifier<AsyncValue<List<User>>> {
  final UserRepository _repository;

  MasterUsersNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadUsers();
  }

  Future<void> loadUsers() async {
    state = const AsyncValue.loading();
    final result = await _repository.getAllUsers();
    if (result is Success<List<User>>) {
      state = AsyncValue.data(result.data);
    } else if (result is AppFailure<List<User>>) {
      state = AsyncValue.error(
        result.failure.message ?? 'Terjadi kesalahan',
        StackTrace.current,
      );
    }
  }

  Future<Result<User>> createUser(User user) async {
    final result = await _repository.createUser(user);
    if (result is Success<User>) {
      await loadUsers();
    }
    return result;
  }

  Future<Result<User>> updateUser(User user) async {
    final result = await _repository.updateUser(user);
    if (result is Success<User>) {
      await loadUsers();
    }
    return result;
  }

  Future<Result<void>> toggleActive(String id, bool isActive) async {
    final result = await _repository.toggleUserActive(id, isActive);
    if (result is Success<void>) {
      await loadUsers();
    }
    return result;
  }

  Future<Result<void>> deleteUser(String id) async {
    final result = await _repository.deleteUser(id);
    if (result is Success<void>) {
      await loadUsers();
    }
    return result;
  }
}

final masterUsersProvider =
    StateNotifierProvider<MasterUsersNotifier, AsyncValue<List<User>>>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  return MasterUsersNotifier(repo);
});

/// Provider untuk [LoginUseCase].
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUseCase(repository: repository);
});

/// Provider untuk [LogoutUseCase].
final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LogoutUseCase(repository: repository);
});

/// State untuk AuthNotifier.
class AuthState {
  final bool isLoading;
  final User? user;
  final Failure? failure;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.failure,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    bool? isLoading,
    User? user,
    Failure? failure,
    bool clearUser = false,
    bool clearFailure = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

/// StateNotifier untuk mengelola status autentikasi aktif.
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final AuthRepository authRepository;

  AuthNotifier({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.authRepository,
    bool checkInitialStatus = true,
  }) : super(const AuthState(isLoading: true)) {
    if (checkInitialStatus) {
      _checkInitialAuthStatus();
    }
  }

  Future<void> _checkInitialAuthStatus() async {
    final result = await authRepository.getCurrentUser();
    result.when(
      onSuccess: (user) {
        state = AuthState(isLoading: false, user: user);
      },
      onFailure: (_) {
        state = const AuthState(isLoading: false, user: null);
      },
    );
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, clearFailure: true);

    final result = await loginUseCase(
      username: username,
      password: password,
    );

    if (result is Success<User>) {
      state = AuthState(isLoading: false, user: result.data);
      return true;
    } else if (result is AppFailure<User>) {
      state = AuthState(isLoading: false, user: null, failure: result.failure);
      return false;
    }

    return false;
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await logoutUseCase();
    state = const AuthState(isLoading: false, user: null);
  }
}

/// Provider utama state autentikasi aplikasi.
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final loginUseCase = ref.watch(loginUseCaseProvider);
  final logoutUseCase = ref.watch(logoutUseCaseProvider);
  final authRepository = ref.watch(authRepositoryProvider);

  return AuthNotifier(
    loginUseCase: loginUseCase,
    logoutUseCase: logoutUseCase,
    authRepository: authRepository,
  );
});
