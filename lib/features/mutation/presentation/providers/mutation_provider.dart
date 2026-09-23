// lib/features/mutation/presentation/providers/mutation_provider.dart
//
// Riverpod providers untuk Mutation Submission.
// Sumber: ROLE-FLOW.md §3, SCREEN-SPEC.md REQ-002–007.
//
// FLOW PENGAJUAN BARU:
// Pemohon menginput data aset secara manual.
// Aset tidak harus sudah tersedia di database.
// SubmitMutationUseCase tidak melakukan pencarian aset.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

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
import '../../domain/usecases/update_mutation_usecase.dart';

// ─── Repository & Use Case Providers ─────────────────────────────────────────

/// Provider untuk [MutationRepository].
///
/// MutationRepositoryImpl masih menggunakan AssetRepository sebagai
/// dependency repository karena dependency tersebut masih digunakan
/// pada struktur data/repository lain.
final mutationRepositoryProvider = Provider<MutationRepository>((ref) {
  final assetRepo = ref.watch(assetRepositoryProvider);

  return MutationRepositoryImpl(assetRepository: assetRepo);
});

/// Provider untuk [SubmitMutationUseCase].
///
/// PENTING:
/// SubmitMutationUseCase TIDAK lagi membutuhkan AssetRepository.
///
/// Data aset berasal dari input manual Pemohon:
/// - assetName
/// - assetId
/// - sourceLocation
/// - targetLocation
/// - targetPic
/// - reason
/// - documentName
final submitMutationUseCaseProvider = Provider<SubmitMutationUseCase>((ref) {
  final mutationRepo = ref.watch(mutationRepositoryProvider);

  return SubmitMutationUseCase(mutationRepository: mutationRepo);
});

/// Provider untuk [GetMutationsUseCase].
final getMutationsUseCaseProvider = Provider<GetMutationsUseCase>((ref) {
  final repo = ref.watch(mutationRepositoryProvider);

  return GetMutationsUseCase(repository: repo);
});

/// Provider untuk [GetMutationDetailUseCase].
final getMutationDetailUseCaseProvider = Provider<GetMutationDetailUseCase>((
  ref,
) {
  final repo = ref.watch(mutationRepositoryProvider);

  return GetMutationDetailUseCase(repository: repo);
});

/// Provider untuk [UpdateMutationUseCase].
final updateMutationUseCaseProvider = Provider<UpdateMutationUseCase>((ref) {
  final repo = ref.watch(mutationRepositoryProvider);

  return UpdateMutationUseCase(repository: repo);
});

// ─── Eligible Assets Provider ────────────────────────────────────────────────
//
// Provider di bawah masih dipertahankan karena kemungkinan masih digunakan
// oleh halaman/fitur aset lain.
//
// Namun FORM PENGAJUAN MUTASI BARU tidak menggunakan provider ini.
// Pemohon langsung mengisi data aset secara manual.

/// Provider yang memfilter aset eligible untuk mutasi.
///
/// Eligible = tidak locked (!isLocked).
/// Sumber: SCREEN-SPEC.md REQ-003.
final eligibleAssetsProvider = FutureProvider<List<Asset>>((ref) async {
  final useCase = ref.watch(getAssetsUseCaseProvider);
  final result = await useCase();

  if (result is Success<List<Asset>>) {
    return result.data.where((asset) => !asset.isLocked).toList();
  }

  if (result is AppFailure<List<Asset>>) {
    throw Exception(result.failure.userMessage);
  }

  return [];
});

/// Provider yang mengambil semua aset termasuk locked.
///
/// Provider ini tetap dipertahankan untuk kebutuhan halaman aset
/// atau fitur lama yang masih menampilkan daftar aset.
final allUserAssetsProvider = FutureProvider<List<Asset>>((ref) async {
  final useCase = ref.watch(getAssetsUseCaseProvider);
  final result = await useCase();

  if (result is Success<List<Asset>>) {
    return result.data;
  }

  if (result is AppFailure<List<Asset>>) {
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
  }

  if (result is AppFailure<List<Mutation>>) {
    throw Exception(result.failure.userMessage);
  }

  return [];
});

// ─── Mutation Detail Provider ────────────────────────────────────────────────

/// Provider detail satu mutasi berdasarkan ID.
final mutationDetailProvider = FutureProvider.family<Mutation, String>((
  ref,
  id,
) async {
  final useCase = ref.watch(getMutationDetailUseCaseProvider);

  final result = await useCase(id);

  if (result is Success<Mutation>) {
    return result.data;
  }

  if (result is AppFailure<Mutation>) {
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

  const SubmitMutationState({this.isLoading = false, this.result, this.error});

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
    debugPrint('========== SUBMIT START ==========');
    debugPrint('assetId: ${params.assetId}');
    debugPrint('assetName: ${params.assetName}');
    debugPrint('sourceLocation: ${params.sourceLocation}');
    debugPrint('targetLocation: ${params.targetLocation}');
    debugPrint('targetPic: ${params.targetPic}');
    debugPrint('reason: ${params.reason}');
    debugPrint('==================================');

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearResult: true,
    );

    final result = await useCase(params);

    debugPrint('[SubmitMutation] RESULT TYPE: ${result.runtimeType}');

    if (result is Success<Mutation>) {
      debugPrint('[SubmitMutation] SUCCESS');
      debugPrint('[SubmitMutation] Ticket: ${result.data.ticketNumber}');
      debugPrint('[SubmitMutation] ID: ${result.data.id}');

      state = SubmitMutationState(isLoading: false, result: result.data);

      // Invalidate list agar mutationListProvider langsung diperbarui dengan data baru
      ref.invalidate(mutationListProvider);

      return result.data;
    }

    if (result is AppFailure<Mutation>) {
      debugPrint(
        '[SubmitMutation] FAILURE TYPE: '
        '${result.failure.runtimeType}',
      );
      debugPrint(
        '[SubmitMutation] FAILURE MESSAGE: '
        '${result.failure.message}',
      );
      debugPrint(
        '[SubmitMutation] USER MESSAGE: '
        '${result.failure.userMessage}',
      );

      state = SubmitMutationState(
        isLoading: false,
        error: result.failure.userMessage,
      );

      return null;
    }

    debugPrint('[SubmitMutation] UNKNOWN RESULT');

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

// ─── Update (Edit) Mutation Provider ─────────────────────────────────────────

/// State untuk proses edit pengajuan mutasi (REQ-008).
class UpdateMutationState {
  final bool isLoading;
  final Mutation? result;
  final String? error;

  const UpdateMutationState({this.isLoading = false, this.result, this.error});

  UpdateMutationState copyWith({
    bool? isLoading,
    Mutation? result,
    String? error,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return UpdateMutationState(
      isLoading: isLoading ?? this.isLoading,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier untuk mengelola proses edit pengajuan mutasi
/// yang dikembalikan.
class UpdateMutationNotifier extends StateNotifier<UpdateMutationState> {
  final UpdateMutationUseCase useCase;
  final Ref ref;

  UpdateMutationNotifier({required this.useCase, required this.ref})
    : super(const UpdateMutationState());

  Future<Mutation?> submit(UpdateMutationParams params) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearResult: true,
    );

    final result = await useCase(params);

    if (result is Success<Mutation>) {
      state = UpdateMutationState(isLoading: false, result: result.data);

      // Refresh list & detail.
      ref.invalidate(mutationListProvider);
      ref.invalidate(mutationDetailProvider(params.mutationId));

      return result.data;
    }

    if (result is AppFailure<Mutation>) {
      state = UpdateMutationState(
        isLoading: false,
        error: result.failure.userMessage,
      );

      return null;
    }

    state = const UpdateMutationState(
      isLoading: false,
      error: 'Terjadi kesalahan. Coba lagi.',
    );

    return null;
  }

  void reset() {
    state = const UpdateMutationState();
  }
}

/// Provider untuk [UpdateMutationNotifier].
final updateMutationProvider =
    StateNotifierProvider<UpdateMutationNotifier, UpdateMutationState>((ref) {
      final useCase = ref.watch(updateMutationUseCaseProvider);

      return UpdateMutationNotifier(useCase: useCase, ref: ref);
    });
