// lib/features/bagian_aset/presentation/providers/bagian_aset_verification_provider.dart
//
// Riverpod state management untuk fitur Verifikasi Bagian Aset.
// Sumber: PRD V1.1 §5, §6.4, §8 Aturan 12 & 13.
//
// Bagian Aset BUKAN approver:
// - Memverifikasi data aset, lokasi tujuan, dan SK SDM.
// - Menentukan PIC baru jika pemohon tidak membawa aset (isAssetMovingWithApplicant == false).
// - Mengembalikan pengajuan jika tidak valid.
// - Meneruskan pengajuan yang valid ke antrean Approval Pemimpin Divisi.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/result.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../kadiv/presentation/providers/kadiv_approval_provider.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/domain/usecases/get_bagian_aset_verifications_usecase.dart';
import '../../../mutation/domain/usecases/return_mutation_bagian_aset_usecase.dart';
import '../../../mutation/domain/usecases/verify_and_forward_mutation_usecase.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../../../notification/domain/entities/notification_item.dart';
import '../../../notification/presentation/providers/notification_provider.dart';

// ─── Use Case Providers ───────────────────────────────────────────────────────

final verifyAndForwardMutationUseCaseProvider =
    Provider<VerifyAndForwardMutationUseCase>((ref) {
  final repo = ref.watch(mutationRepositoryProvider);
  return VerifyAndForwardMutationUseCase(repository: repo);
});

final returnMutationBagianAsetUseCaseProvider =
    Provider<ReturnMutationBagianAsetUseCase>((ref) {
  final repo = ref.watch(mutationRepositoryProvider);
  return ReturnMutationBagianAsetUseCase(repository: repo);
});

final getBagianAsetVerificationsUseCaseProvider =
    Provider<GetBagianAsetVerificationsUseCase>((ref) {
  final repo = ref.watch(apiMutationRepositoryProvider);
  return GetBagianAsetVerificationsUseCase(repository: repo);
});

/// Provider detail satu mutasi untuk Bagian Aset via API Laravel.
final bagianAsetMutationDetailProvider = apiMutationDetailProvider;

/// Compatibility alias untuk pengujian atau kode transisi
final kabagMutationDetailProvider = bagianAsetMutationDetailProvider;

// ─── Filter & Search State ───────────────────────────────────────────────────

enum BagianAsetSortOrder {
  newest,
  oldest;

  String get displayName => switch (this) {
        BagianAsetSortOrder.newest => 'Terbaru',
        BagianAsetSortOrder.oldest => 'Terlama',
      };
}

enum BagianAsetStatusFilter {
  waiting,
  verified,
  returned,
  rejected,
  approved,
  all;

  String get displayName => switch (this) {
        BagianAsetStatusFilter.waiting => 'Menunggu Verifikasi',
        BagianAsetStatusFilter.verified ||
        BagianAsetStatusFilter.approved =>
          'Lolos Verifikasi',
        BagianAsetStatusFilter.returned ||
        BagianAsetStatusFilter.rejected =>
          'Dikembalikan',
        BagianAsetStatusFilter.all => 'Semua',
      };
}

final bagianAsetSearchQueryProvider = StateProvider<String>((ref) => '');

final bagianAsetSortOrderProvider =
    StateProvider<BagianAsetSortOrder>((ref) => BagianAsetSortOrder.newest);

final bagianAsetStatusFilterProvider = StateProvider<BagianAsetStatusFilter>(
    (ref) => BagianAsetStatusFilter.waiting);

// ─── Mutations Data Providers ────────────────────────────────────────────────

/// Provider seluruh mutasi untuk Bagian Aset.
final bagianAsetAllMutationsProvider =
    FutureProvider<List<Mutation>>((ref) async {
  final useCase = ref.watch(getBagianAsetVerificationsUseCaseProvider);
  final result = await useCase();

  if (result is Success<List<Mutation>>) {
    return result.data;
  } else if (result is AppFailure<List<Mutation>>) {
    throw Exception(result.failure.userMessage);
  }
  return [];
});

/// Compatibility alias untuk pengujian atau kode transisi
final kabagAllMutationsProvider = bagianAsetAllMutationsProvider;

/// Statistik overview verifikasi untuk Dashboard Bagian Aset.
class BagianAsetVerificationStats {
  final int waitingVerificationCount;
  final int verifiedCount;
  final int returnedCount;

  const BagianAsetVerificationStats({
    required this.waitingVerificationCount,
    required this.verifiedCount,
    required this.returnedCount,
  });

  int get waitingApprovalCount => waitingVerificationCount;
  int get approvedCount => verifiedCount;
  int get rejectedCount => returnedCount;
}

final bagianAsetStatsProvider = Provider<BagianAsetVerificationStats>((ref) {
  final asyncMutations = ref.watch(bagianAsetAllMutationsProvider);

  return asyncMutations.when(
    data: (mutations) {
      final waiting = mutations
          .where((m) => m.status.isWaitingAssetVerification)
          .length;
      final verified = mutations.where((m) {
        return m.status.isWaitingDivisionApproval ||
            m.status.isWaitingConfirmation ||
            m.status == MutationStatus.completed ||
            m.assetVerifiedBy != null;
      }).length;
      final returned = mutations.where((m) {
        return m.status == MutationStatus.returned ||
            m.status == MutationStatus.rejected;
      }).length;

      return BagianAsetVerificationStats(
        waitingVerificationCount: waiting,
        verifiedCount: verified,
        returnedCount: returned,
      );
    },
    loading: () => const BagianAsetVerificationStats(
      waitingVerificationCount: 0,
      verifiedCount: 0,
      returnedCount: 0,
    ),
    error: (_, _) => const BagianAsetVerificationStats(
      waitingVerificationCount: 0,
      verifiedCount: 0,
      returnedCount: 0,
    ),
  );
});

/// Provider antrean mutasi untuk Bagian Aset dengan filter status, pencarian, dan sorting.
final filteredBagianAsetVerificationsProvider =
    Provider<AsyncValue<List<Mutation>>>((ref) {
  final asyncAll = ref.watch(bagianAsetAllMutationsProvider);
  final query = ref.watch(bagianAsetSearchQueryProvider).toLowerCase().trim();
  final sortOrder = ref.watch(bagianAsetSortOrderProvider);
  final statusFilter = ref.watch(bagianAsetStatusFilterProvider);

  return asyncAll.whenData((mutations) {
    // 1. Filter status
    var list = mutations.where((m) {
      return switch (statusFilter) {
        BagianAsetStatusFilter.waiting => m.status.isWaitingAssetVerification,
        BagianAsetStatusFilter.verified ||
        BagianAsetStatusFilter.approved =>
          m.status.isWaitingDivisionApproval ||
              m.status.isWaitingConfirmation ||
              m.status == MutationStatus.completed ||
              m.assetVerifiedBy != null,
        BagianAsetStatusFilter.returned ||
        BagianAsetStatusFilter.rejected =>
          m.status == MutationStatus.returned ||
              m.status == MutationStatus.rejected,
        BagianAsetStatusFilter.all => m.status.isWaitingAssetVerification ||
            m.status.isWaitingDivisionApproval ||
            m.status == MutationStatus.rejected ||
            m.status == MutationStatus.returned ||
            m.status.isWaitingConfirmation ||
            m.status == MutationStatus.completed ||
            m.assetVerifiedBy != null,
      };
    }).toList();

    // 2. Filter search query
    if (query.isNotEmpty) {
      list = list.where((m) {
        final matchTicket = m.ticketNumber.toLowerCase().contains(query);
        final matchAsset = m.asset.name.toLowerCase().contains(query);
        final matchApplicant = m.applicantName.toLowerCase().contains(query);
        final matchLocation = m.targetLocation.toLowerCase().contains(query);
        return matchTicket || matchAsset || matchApplicant || matchLocation;
      }).toList();
    }

    // 3. Sorting berdasarkan createdAt
    list.sort((a, b) {
      if (sortOrder == BagianAsetSortOrder.oldest) {
        return a.createdAt.compareTo(b.createdAt);
      } else {
        return b.createdAt.compareTo(a.createdAt);
      }
    });

    return list;
  });
});

/// Compatibility alias untuk pengujian legacy
final kabagStatsProvider = bagianAsetStatsProvider;
final kabagStatusFilterProvider = bagianAsetStatusFilterProvider;
typedef KabagStatusFilter = BagianAsetStatusFilter;
final filteredKabagApprovalsProvider = filteredBagianAsetVerificationsProvider;

// ─── Action Notifier ─────────────────────────────────────────────────────────

class BagianAsetVerificationActionState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final Mutation? result;

  const BagianAsetVerificationActionState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.result,
  });

  BagianAsetVerificationActionState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    Mutation? result,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return BagianAsetVerificationActionState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      result: result ?? this.result,
    );
  }
}

class BagianAsetVerificationActionNotifier
    extends StateNotifier<BagianAsetVerificationActionState> {
  final VerifyAndForwardMutationUseCase verifyAndForwardUseCase;
  final ReturnMutationBagianAsetUseCase returnUseCase;
  final Ref ref;

  BagianAsetVerificationActionNotifier({
    required this.verifyAndForwardUseCase,
    required this.returnUseCase,
    required this.ref,
  }) : super(const BagianAsetVerificationActionState());

  /// Eksekusi Verifikasi & Teruskan ke Pemimpin Divisi oleh Bagian Aset (PRD V1.1 §6.4)
  Future<bool> verifyAndForward({
    required String mutationId,
    String? newPic,
  }) async {
    final authState = ref.read(authStateProvider);
    final verifierName = authState.user?.name ?? 'Bagian Aset';

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    final result = await verifyAndForwardUseCase(
      mutationId: mutationId,
      verifierName: verifierName,
      newPic: newPic,
    );

    if (result is Success<Mutation>) {
      state = BagianAsetVerificationActionState(
        isLoading: false,
        successMessage:
            'Data aset diverifikasi dan diteruskan ke Pemimpin Divisi.',
        result: result.data,
      );
      ref.invalidate(bagianAsetAllMutationsProvider);
      ref.invalidate(bagianAsetMutationDetailProvider(mutationId));
      ref.invalidate(apiMutationDetailProvider(mutationId));
      ref.invalidate(mutationDetailProvider(mutationId));
      ref.invalidate(mutationListProvider);
      ref.invalidate(kadivAllMutationsProvider);

      try {
        ref.read(notificationProvider.notifier).notifyRole(
              targetRole: UserRole.kadiv,
              title: 'Menunggu Persetujuan Final',
              message:
                  'Pengajuan mutasi ${result.data.ticketNumber} (${result.data.asset.name}) telah diverifikasi oleh Bagian Aset dan memerlukan persetujuan Pemimpin Divisi.',
              type: NotificationType.action,
              relatedMutationId: mutationId,
            );
      } catch (_) {}
      return true;
    } else if (result is AppFailure<Mutation>) {
      state = BagianAsetVerificationActionState(
        isLoading: false,
        error: result.failure.userMessage,
      );
      return false;
    }

    state = const BagianAsetVerificationActionState(
      isLoading: false,
      error: 'Terjadi kesalahan sistem saat memverifikasi mutasi.',
    );
    return false;
  }

  /// Eksekusi Kembalikan Pengajuan ke Pemohon oleh Bagian Aset (PRD V1.1 §6.4)
  Future<bool> returnToApplicant({
    required String mutationId,
    required String reason,
  }) async {
    final authState = ref.read(authStateProvider);
    final verifierName = authState.user?.name ?? 'Bagian Aset';

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    final result = await returnUseCase(
      mutationId: mutationId,
      reason: reason,
      verifierName: verifierName,
    );

    if (result is Success<Mutation>) {
      state = BagianAsetVerificationActionState(
        isLoading: false,
        successMessage: 'Pengajuan mutasi berhasil dikembalikan ke Pemohon.',
        result: result.data,
      );
      ref.invalidate(bagianAsetAllMutationsProvider);
      ref.invalidate(bagianAsetMutationDetailProvider(mutationId));
      ref.invalidate(apiMutationDetailProvider(mutationId));
      ref.invalidate(mutationDetailProvider(mutationId));
      ref.invalidate(mutationListProvider);

      try {
        ref.read(notificationProvider.notifier).notifyRole(
              targetRole: UserRole.pemohon,
              title: 'Pengajuan Dikembalikan Bagian Aset',
              message:
                  'Pengajuan mutasi ${result.data.ticketNumber} dikembalikan: $reason',
              type: NotificationType.warning,
              relatedMutationId: mutationId,
            );
      } catch (_) {}
      return true;
    } else if (result is AppFailure<Mutation>) {
      state = BagianAsetVerificationActionState(
        isLoading: false,
        error: result.failure.userMessage,
      );
      return false;
    }

    state = const BagianAsetVerificationActionState(
      isLoading: false,
      error: 'Terjadi kesalahan sistem saat mengembalikan mutasi.',
    );
    return false;
  }

  /// Compatibility alias untuk pemanggilan approval legacy (memetakan ke verifikasi & penerusan)
  Future<bool> approve({
    required String mutationId,
    bool? requiresKadivApproval,
    String? newPic,
  }) async {
    return verifyAndForward(mutationId: mutationId, newPic: newPic);
  }

  /// Compatibility alias untuk pemanggilan reject legacy (memetakan ke pengembalian berkas)
  Future<bool> reject({
    required String mutationId,
    required String reason,
  }) async {
    return returnToApplicant(mutationId: mutationId, reason: reason);
  }

  void reset() {
    state = const BagianAsetVerificationActionState();
  }
}

final bagianAsetVerificationActionProvider = StateNotifierProvider<
    BagianAsetVerificationActionNotifier,
    BagianAsetVerificationActionState>((ref) {
  final verifyAndForwardUseCase =
      ref.watch(verifyAndForwardMutationUseCaseProvider);
  final returnUseCase = ref.watch(returnMutationBagianAsetUseCaseProvider);
  return BagianAsetVerificationActionNotifier(
    verifyAndForwardUseCase: verifyAndForwardUseCase,
    returnUseCase: returnUseCase,
    ref: ref,
  );
});
