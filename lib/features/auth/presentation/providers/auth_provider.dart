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

/// Provider untuk [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(secureStorage: secureStorage);
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
  }) : super(const AuthState(isLoading: true)) {
    _checkInitialAuthStatus();
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
