// lib/features/operator/presentation/providers/operator_verification_provider.dart
//
// Riverpod state management untuk fitur Verifikasi Operator.
// Sumber: ROLE-FLOW.md §4, SCREEN-SPEC.md OPR-001–004.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/result.dart';
import '../../../asset/domain/entities/asset.dart';
import '../../../asset/presentation/providers/asset_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/domain/usecases/get_pending_verifications_usecase.dart';
import '../../../mutation/domain/usecases/return_mutation_usecase.dart';
import '../../../mutation/domain/usecases/verify_mutation_usecase.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../../../kabag/presentation/providers/kabag_approval_provider.dart';
import '../../../kadiv/presentation/providers/kadiv_approval_provider.dart';

// ─── Use Case Providers ───────────────────────────────────────────────────────

final verifyMutationUseCaseProvider = Provider<VerifyMutationUseCase>((ref) {
  final repo = ref.watch(mutationRepositoryProvider);
  return VerifyMutationUseCase(repository: repo);
});

final returnMutationUseCaseProvider = Provider<ReturnMutationUseCase>((ref) {
  final repo = ref.watch(mutationRepositoryProvider);
  return ReturnMutationUseCase(repository: repo);
});

final getPendingVerificationsUseCaseProvider =
    Provider<GetPendingVerificationsUseCase>((ref) {
  final repo = ref.watch(mutationRepositoryProvider);
  return GetPendingVerificationsUseCase(repository: repo);
});

/// Otomatis load asset dari AssetRepository berdasarkan assetId (SIMAK BMN).
final operatorMasterAssetProvider =
    FutureProvider.family<Asset?, String>((ref, assetId) async {
  final cleanId = assetId.trim();
  if (cleanId.isEmpty) return null;
  final assetRepo = ref.watch(assetRepositoryProvider);
  final result = await assetRepo.getAssetById(cleanId);
  if (result is Success<Asset>) {
    return result.data;
  }
  final listResult = await assetRepo.getAssets(query: cleanId);
  if (listResult is Success<List<Asset>> && listResult.data.isNotEmpty) {
    return listResult.data.firstWhere(
      (a) => a.id == cleanId || a.assetCode == cleanId,
      orElse: () => listResult.data.first,
    );
  }
  return null;
});

// ─── Filter & Search State ───────────────────────────────────────────────────

enum MutationSortOrder {
  newest,
  oldest;

  String get displayName => switch (this) {
        MutationSortOrder.newest => 'Terbaru',
        MutationSortOrder.oldest => 'Terlama',
      };
}

enum OperatorStatusFilter {
  submitted,
  returned,
  all;

  String get displayName => switch (this) {
        OperatorStatusFilter.submitted => 'Menunggu Verifikasi',
        OperatorStatusFilter.returned => 'Dikembalikan',
        OperatorStatusFilter.all => 'Semua Status',
      };
}

final operatorSearchQueryProvider = StateProvider<String>((ref) => '');

final operatorSortOrderProvider =
    StateProvider<MutationSortOrder>((ref) => MutationSortOrder.newest);

final operatorStatusFilterProvider = StateProvider<OperatorStatusFilter>(
    (ref) => OperatorStatusFilter.submitted);

// ─── Mutations Data Providers ────────────────────────────────────────────────

/// Provider seluruh mutasi untuk Operator (in-memory mock / API).
final operatorAllMutationsProvider = FutureProvider<List<Mutation>>((ref) async {
  final useCase = ref.watch(getPendingVerificationsUseCaseProvider);
  final result = await useCase();

  if (result is Success<List<Mutation>>) {
    return result.data;
  } else if (result is AppFailure<List<Mutation>>) {
    throw Exception(result.failure.userMessage);
  }
  return [];
});

/// Statistik verifikasi untuk Dashboard Operator (OPR-001).
class VerificationStats {
  final int pendingCount;
  final int returnedCount;
  final int waitingKabagCount;

  const VerificationStats({
    required this.pendingCount,
    required this.returnedCount,
    required this.waitingKabagCount,
  });
}

final verificationStatsProvider = Provider<VerificationStats>((ref) {
  final asyncMutations = ref.watch(operatorAllMutationsProvider);

  return asyncMutations.when(
    data: (mutations) {
      final pending = mutations
          .where((m) => m.status == MutationStatus.submitted)
          .length;
      final returned = mutations
          .where((m) => m.status == MutationStatus.returned)
          .length;
      final waitingKabag = mutations
          .where((m) => m.status == MutationStatus.waitingKabagApproval)
          .length;

      return VerificationStats(
        pendingCount: pending,
        returnedCount: returned,
        waitingKabagCount: waitingKabag,
      );
    },
    loading: () => const VerificationStats(
      pendingCount: 0,
      returnedCount: 0,
      waitingKabagCount: 0,
    ),
    error: (_, _) => const VerificationStats(
      pendingCount: 0,
      returnedCount: 0,
      waitingKabagCount: 0,
    ),
  );
});

/// Provider daftar pengajuan masuk yang difilter dan di-sort untuk Operator.
final filteredIncomingMutationsProvider = Provider<AsyncValue<List<Mutation>>>((ref) {
  final asyncAll = ref.watch(operatorAllMutationsProvider);
  final query = ref.watch(operatorSearchQueryProvider).toLowerCase().trim();
  final sortOrder = ref.watch(operatorSortOrderProvider);
  final statusFilter = ref.watch(operatorStatusFilterProvider);

  return asyncAll.whenData((mutations) {
    // 1. Filter status
    var list = mutations.where((m) {
      return switch (statusFilter) {
        OperatorStatusFilter.submitted => m.status == MutationStatus.submitted,
        OperatorStatusFilter.returned => m.status == MutationStatus.returned,
        OperatorStatusFilter.all => m.status == MutationStatus.submitted ||
            m.status == MutationStatus.returned ||
            m.status == MutationStatus.waitingKabagApproval,
      };
    }).toList();

    // 2. Search query filter (No. Tiket, Nama Aset, Pemohon, Lokasi)
    if (query.isNotEmpty) {
      list = list.where((m) {
        final matchTicket = m.ticketNumber.toLowerCase().contains(query);
        final matchAsset = m.asset.name.toLowerCase().contains(query) ||
            m.displayAssetName.toLowerCase().contains(query) ||
            m.asset.assetCode.toLowerCase().contains(query) ||
            m.displayAssetCode.toLowerCase().contains(query) ||
            (m.customAssetName?.toLowerCase().contains(query) ?? false) ||
            (m.customSerialNumber?.toLowerCase().contains(query) ?? false);
        final matchApplicant = m.applicantName.toLowerCase().contains(query);
        final matchLocation = m.targetLocation.toLowerCase().contains(query);
        return matchTicket || matchAsset || matchApplicant || matchLocation;
      }).toList();
    }

    // 3. Sort order berdasarkan createdAt
    list.sort((a, b) {
      if (sortOrder == MutationSortOrder.newest) {
        return b.createdAt.compareTo(a.createdAt);
      } else {
        return a.createdAt.compareTo(b.createdAt);
      }
    });

    return list;
  });
});

// ─── Verification Action Notifier ────────────────────────────────────────────

class VerificationActionState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final Mutation? result;

  const VerificationActionState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.result,
  });

  VerificationActionState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    Mutation? result,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return VerificationActionState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      result: result ?? this.result,
    );
  }
}

class VerificationActionNotifier extends StateNotifier<VerificationActionState> {
  final VerifyMutationUseCase verifyUseCase;
  final ReturnMutationUseCase returnUseCase;
  final Ref ref;

  VerificationActionNotifier({
    required this.verifyUseCase,
    required this.returnUseCase,
    required this.ref,
  }) : super(const VerificationActionState());

  /// Eksekusi Verifikasi Valid
  Future<bool> verify({
    required String mutationId,
    bool requiresKadivApproval = false,
  }) async {
    final authState = ref.read(authStateProvider);
    final operatorName = authState.user?.name ?? 'Operator';

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    final result = await verifyUseCase(
      mutationId: mutationId,
      operatorName: operatorName,
      requiresKadivApproval: requiresKadivApproval,
    );

    if (result is Success<Mutation>) {
      state = VerificationActionState(
        isLoading: false,
        successMessage: 'Pengajuan mutasi berhasil diverifikasi dan diteruskan ke Kabag Aset.',
        result: result.data,
      );
      // Invalidate list agar ter-refresh
      ref.invalidate(operatorAllMutationsProvider);
      ref.invalidate(mutationDetailProvider(mutationId));
      ref.invalidate(mutationListProvider);
      ref.invalidate(kabagAllMutationsProvider);
      ref.invalidate(kadivAllMutationsProvider);
      return true;
    } else if (result is AppFailure<Mutation>) {
      state = VerificationActionState(
        isLoading: false,
        error: result.failure.userMessage,
      );
      return false;
    }

    state = const VerificationActionState(
      isLoading: false,
      error: 'Terjadi kesalahan sistem saat memverifikasi.',
    );
    return false;
  }

  /// Eksekusi Kembalikan Pengajuan
  Future<bool> returnMutation({
    required String mutationId,
    required String reason,
  }) async {
    final authState = ref.read(authStateProvider);
    final operatorName = authState.user?.name ?? 'Operator';

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    final result = await returnUseCase(
      mutationId: mutationId,
      reason: reason,
      operatorName: operatorName,
    );

    if (result is Success<Mutation>) {
      state = VerificationActionState(
        isLoading: false,
        successMessage: 'Pengajuan mutasi berhasil dikembalikan ke Pemohon.',
        result: result.data,
      );
      ref.invalidate(operatorAllMutationsProvider);
      ref.invalidate(mutationDetailProvider(mutationId));
      ref.invalidate(mutationListProvider);
      ref.invalidate(kabagAllMutationsProvider);
      return true;
    } else if (result is AppFailure<Mutation>) {
      state = VerificationActionState(
        isLoading: false,
        error: result.failure.userMessage,
      );
      return false;
    }

    state = const VerificationActionState(
      isLoading: false,
      error: 'Terjadi kesalahan sistem saat mengembalikan pengajuan.',
    );
    return false;
  }

  void reset() {
    state = const VerificationActionState();
  }
}

final verificationActionProvider =
    StateNotifierProvider<VerificationActionNotifier, VerificationActionState>(
        (ref) {
  final verifyUseCase = ref.watch(verifyMutationUseCaseProvider);
  final returnUseCase = ref.watch(returnMutationUseCaseProvider);
  return VerificationActionNotifier(
    verifyUseCase: verifyUseCase,
    returnUseCase: returnUseCase,
    ref: ref,
  );
});
