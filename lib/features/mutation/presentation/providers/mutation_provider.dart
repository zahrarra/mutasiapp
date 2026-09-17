// lib/features/mutation/presentation/providers/mutation_provider.dart
//
// Riverpod providers untuk Mutation Submission.
// Sumber: ROLE-FLOW.md §3, SCREEN-SPEC.md REQ-002–007.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/result.dart';
import '../../../asset/domain/entities/asset.dart';
import '../../../asset/presentation/providers/asset_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/mutation_repository_impl.dart';
import '../../domain/entities/mutation.dart';
import '../../domain/repositories/mutation_repository.dart';
import '../../domain/usecases/get_mutation_detail_usecase.dart';
import '../../domain/usecases/get_mutations_usecase.dart';
import '../../domain/usecases/submit_mutation_usecase.dart';

// ─── Repository & Use Case Providers ─────────────────────────────────────────

/// Provider untuk [MutationRepository].
final mutationRepositoryProvider = Provider<MutationRepository>((ref) {
  final assetRepo = ref.watch(assetRepositoryProvider);
  return MutationRepositoryImpl(assetRepository: assetRepo);
});

/// Provider untuk [SubmitMutationUseCase].
final submitMutationUseCaseProvider = Provider<SubmitMutationUseCase>((ref) {
  final mutationRepo = ref.watch(mutationRepositoryProvider);
  final assetRepo = ref.watch(assetRepositoryProvider);
  return SubmitMutationUseCase(
    mutationRepository: mutationRepo,
    assetRepository: assetRepo,
  );
});

/// Provider untuk [GetMutationsUseCase].
final getMutationsUseCaseProvider = Provider<GetMutationsUseCase>((ref) {
  final repo = ref.watch(mutationRepositoryProvider);
  return GetMutationsUseCase(repository: repo);
});

/// Provider untuk [GetMutationDetailUseCase].
final getMutationDetailUseCaseProvider = Provider<GetMutationDetailUseCase>((ref) {
  final repo = ref.watch(mutationRepositoryProvider);
  return GetMutationDetailUseCase(repository: repo);
});

// ─── Eligible Assets Provider ────────────────────────────────────────────────

/// Provider yang memfilter aset eligible untuk mutasi.
///
/// Eligible = tidak locked (!isLocked).
/// Sumber: SCREEN-SPEC.md REQ-003.
final eligibleAssetsProvider = FutureProvider<List<Asset>>((ref) async {
  final useCase = ref.watch(getAssetsUseCaseProvider);
  final result = await useCase();

  if (result is Success<List<Asset>>) {
    // Hanya return aset yang tidak locked
    return result.data.where((asset) => !asset.isLocked).toList();
  } else if (result is AppFailure<List<Asset>>) {
    throw Exception(result.failure.userMessage);
  }
  return [];
});

/// Provider yang mengambil semua aset (termasuk locked) untuk tampilan
/// dengan indikator lock.
final allUserAssetsProvider = FutureProvider<List<Asset>>((ref) async {
  final useCase = ref.watch(getAssetsUseCaseProvider);
  final result = await useCase();

  if (result is Success<List<Asset>>) {
    return result.data;
  } else if (result is AppFailure<List<Asset>>) {
    throw Exception(result.failure.userMessage);
  }
  return [];
});

// ─── Mutation List Provider ──────────────────────────────────────────────────

/// Provider daftar mutasi milik user saat ini.
final mutationListProvider = FutureProvider<List<Mutation>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final useCase = ref.watch(getMutationsUseCaseProvider);

  if (!authState.isAuthenticated) {
    return [];
  }

  final result = await useCase(authState.user!.id);

  if (result is Success<List<Mutation>>) {
    return result.data;
  } else if (result is AppFailure<List<Mutation>>) {
    throw Exception(result.failure.userMessage);
  }
  return [];
});

// ─── Mutation Detail Provider ────────────────────────────────────────────────

/// Provider detail satu mutasi berdasarkan ID.
final mutationDetailProvider =
    FutureProvider.family<Mutation, String>((ref, id) async {
  final useCase = ref.watch(getMutationDetailUseCaseProvider);
  final result = await useCase(id);

  if (result is Success<Mutation>) {
    return result.data;
  } else if (result is AppFailure<Mutation>) {
    throw Exception(result.failure.userMessage);
  }
  throw Exception('Pengajuan mutasi tidak ditemukan.');
});

// ─── Submit Mutation Provider ────────────────────────────────────────────────

/// State untuk proses submit mutasi.
class SubmitMutationState {
  final bool isLoading;
  final Mutation? result;
  final String? error;

  const SubmitMutationState({
    this.isLoading = false,
    this.result,
    this.error,
  });

  SubmitMutationState copyWith({
    bool? isLoading,
    Mutation? result,
    String? error,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return SubmitMutationState(
      isLoading: isLoading ?? this.isLoading,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier untuk mengelola proses submit mutasi.
class SubmitMutationNotifier extends StateNotifier<SubmitMutationState> {
  final SubmitMutationUseCase useCase;
  final Ref ref;

  SubmitMutationNotifier({required this.useCase, required this.ref})
      : super(const SubmitMutationState());

  Future<Mutation?> submit(SubmitMutationParams params) async {
    state = state.copyWith(isLoading: true, clearError: true, clearResult: true);

    final result = await useCase(params);

    if (result is Success<Mutation>) {
      state = SubmitMutationState(isLoading: false, result: result.data);
      // Invalidate mutation list agar ter-refresh
      ref.invalidate(mutationListProvider);
      return result.data;
    } else if (result is AppFailure<Mutation>) {
      state = SubmitMutationState(
        isLoading: false,
        error: result.failure.userMessage,
      );
      return null;
    }

    state = const SubmitMutationState(
      isLoading: false,
      error: 'Terjadi kesalahan. Coba lagi.',
    );
    return null;
  }

  void reset() {
    state = const SubmitMutationState();
  }
}

/// Provider untuk [SubmitMutationNotifier].
final submitMutationProvider =
    StateNotifierProvider<SubmitMutationNotifier, SubmitMutationState>((ref) {
  final useCase = ref.watch(submitMutationUseCaseProvider);
  return SubmitMutationNotifier(useCase: useCase, ref: ref);
});
