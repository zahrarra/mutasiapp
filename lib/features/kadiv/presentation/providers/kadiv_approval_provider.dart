// lib/features/kadiv/presentation/providers/kadiv_approval_provider.dart
//
// Riverpod state management untuk fitur Approval Kadiv.
// Sumber: ROLE-FLOW.md §6, SCREEN-SPEC.md KDV-001–004, TECHNICAL-DESIGN.md.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/result.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/domain/usecases/approve_mutation_kadiv_usecase.dart';
import '../../../mutation/domain/usecases/get_kadiv_approvals_usecase.dart';
import '../../../mutation/domain/usecases/reject_mutation_kadiv_usecase.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';

// ─── Use Case Providers ───────────────────────────────────────────────────────

final approveMutationKadivUseCaseProvider =
    Provider<ApproveMutationKadivUseCase>((ref) {
  final repo = ref.watch(mutationRepositoryProvider);
  return ApproveMutationKadivUseCase(repository: repo);
});

final rejectMutationKadivUseCaseProvider =
    Provider<RejectMutationKadivUseCase>((ref) {
  final repo = ref.watch(mutationRepositoryProvider);
  return RejectMutationKadivUseCase(repository: repo);
});

final getKadivApprovalsUseCaseProvider =
    Provider<GetKadivApprovalsUseCase>((ref) {
  final repo = ref.watch(mutationRepositoryProvider);
  return GetKadivApprovalsUseCase(repository: repo);
});

// ─── Filter & Search State ───────────────────────────────────────────────────

enum KadivSortOrder {
  newest,
  oldest;

  String get displayName => switch (this) {
        KadivSortOrder.newest => 'Terbaru',
        KadivSortOrder.oldest => 'Terlama',
      };
}

enum KadivStatusFilter {
  waiting,
  approved,
  rejected,
  all;

  String get displayName => switch (this) {
        KadivStatusFilter.waiting => 'Menunggu Approval',
        KadivStatusFilter.approved => 'Disetujui',
        KadivStatusFilter.rejected => 'Ditolak',
        KadivStatusFilter.all => 'Semua',
      };
}

final kadivSearchQueryProvider = StateProvider<String>((ref) => '');

final kadivSortOrderProvider =
    StateProvider<KadivSortOrder>((ref) => KadivSortOrder.newest);

final kadivStatusFilterProvider =
    StateProvider<KadivStatusFilter>((ref) => KadivStatusFilter.waiting);

// ─── Mutations Data Providers ────────────────────────────────────────────────

/// Provider seluruh mutasi untuk keperluan Kadiv.
final kadivAllMutationsProvider = FutureProvider<List<Mutation>>((ref) async {
  final useCase = ref.watch(getKadivApprovalsUseCaseProvider);
  final result = await useCase();

  if (result is Success<List<Mutation>>) {
    return result.data;
  } else if (result is AppFailure<List<Mutation>>) {
    throw Exception(result.failure.userMessage);
  }
  return [];
});

/// Statistik overview approval untuk Dashboard Kadiv (KDV-001).
class KadivApprovalStats {
  final int waitingApprovalCount;
  final int approvedCount;
  final int rejectedCount;

  const KadivApprovalStats({
    required this.waitingApprovalCount,
    required this.approvedCount,
    required this.rejectedCount,
  });
}

final kadivStatsProvider = Provider<KadivApprovalStats>((ref) {
  final asyncMutations = ref.watch(kadivAllMutationsProvider);

  return asyncMutations.when(
    data: (mutations) {
      final waiting = mutations
          .where((m) => m.status == MutationStatus.waitingKadivApproval)
          .length;
      final approved = mutations
          .where((m) =>
              (m.status == MutationStatus.approved ||
                  m.status == MutationStatus.pendingConfirmation ||
                  m.status == MutationStatus.completed) &&
              (m.kadivApprovedBy != null || m.kadivApprovedAt != null))
          .length;
      final rejected = mutations
          .where((m) =>
              m.status == MutationStatus.rejected &&
              (m.kadivRejectedBy != null ||
                  m.kadivRejectedAt != null ||
                  m.kadivRejectionReason != null))
          .length;

      return KadivApprovalStats(
        waitingApprovalCount: waiting,
        approvedCount: approved,
        rejectedCount: rejected,
      );
    },
    loading: () => const KadivApprovalStats(
      waitingApprovalCount: 0,
      approvedCount: 0,
      rejectedCount: 0,
    ),
    error: (_, _) => const KadivApprovalStats(
      waitingApprovalCount: 0,
      approvedCount: 0,
      rejectedCount: 0,
    ),
  );
});

/// Provider antrean mutasi untuk Kadiv (KDV-002 & Riwayat) dengan filter status, pencarian, dan sorting.
final filteredKadivApprovalsProvider =
    Provider<AsyncValue<List<Mutation>>>((ref) {
  final asyncAll = ref.watch(kadivAllMutationsProvider);
  final query = ref.watch(kadivSearchQueryProvider).toLowerCase().trim();
  final statusFilter = ref.watch(kadivStatusFilterProvider);
  final sortOrder = ref.watch(kadivSortOrderProvider);

  return asyncAll.whenData((mutations) {
    // 1. Filter berdasarkan status tab
    var list = mutations.where((m) {
      return switch (statusFilter) {
        KadivStatusFilter.waiting =>
          m.status == MutationStatus.waitingKadivApproval,
        KadivStatusFilter.approved =>
          (m.status == MutationStatus.approved ||
                  m.status == MutationStatus.pendingConfirmation ||
                  m.status == MutationStatus.completed) &&
              (m.kadivApprovedBy != null || m.kadivApprovedAt != null),
        KadivStatusFilter.rejected =>
          m.status == MutationStatus.rejected &&
              (m.kadivRejectedBy != null ||
                  m.kadivRejectedAt != null ||
                  m.kadivRejectionReason != null),
        KadivStatusFilter.all =>
          m.status == MutationStatus.waitingKadivApproval ||
              m.kadivApprovedBy != null ||
              m.kadivRejectedBy != null,
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

    // 3. Sorting
    list.sort((a, b) {
      if (sortOrder == KadivSortOrder.oldest) {
        return a.createdAt.compareTo(b.createdAt);
      } else {
        return b.createdAt.compareTo(a.createdAt);
      }
    });

    return list;
  });
});

// ─── Kadiv Action Notifier ───────────────────────────────────────────────────

class KadivApprovalActionState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final Mutation? result;

  const KadivApprovalActionState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.result,
  });

  KadivApprovalActionState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    Mutation? result,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return KadivApprovalActionState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      result: result ?? this.result,
    );
  }
}

class KadivApprovalActionNotifier
    extends StateNotifier<KadivApprovalActionState> {
  final ApproveMutationKadivUseCase approveUseCase;
  final RejectMutationKadivUseCase rejectUseCase;
  final Ref ref;

  KadivApprovalActionNotifier({
    required this.approveUseCase,
    required this.rejectUseCase,
    required this.ref,
  }) : super(const KadivApprovalActionState());

  /// Eksekusi Approve oleh Kadiv
  Future<bool> approve({required String mutationId}) async {
    final authState = ref.read(authStateProvider);
    final kadivName = authState.user?.name ?? 'Kadiv';

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    final result = await approveUseCase(
      mutationId: mutationId,
      kadivName: kadivName,
    );

    if (result is Success<Mutation>) {
      state = KadivApprovalActionState(
        isLoading: false,
        successMessage: 'Pengajuan mutasi berhasil disetujui oleh Kadiv.',
        result: result.data,
      );
      ref.invalidate(kadivAllMutationsProvider);
      ref.invalidate(mutationDetailProvider(mutationId));
      ref.invalidate(mutationListProvider);
      return true;
    } else if (result is AppFailure<Mutation>) {
      state = KadivApprovalActionState(
        isLoading: false,
        error: result.failure.userMessage,
      );
      return false;
    }

    state = const KadivApprovalActionState(
      isLoading: false,
      error: 'Terjadi kesalahan sistem saat menyetujui mutasi.',
    );
    return false;
  }

  /// Eksekusi Reject oleh Kadiv
  Future<bool> reject({
    required String mutationId,
    required String reason,
  }) async {
    final authState = ref.read(authStateProvider);
    final kadivName = authState.user?.name ?? 'Kadiv';

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    final result = await rejectUseCase(
      mutationId: mutationId,
      reason: reason,
      kadivName: kadivName,
    );

    if (result is Success<Mutation>) {
      state = KadivApprovalActionState(
        isLoading: false,
        successMessage: 'Pengajuan mutasi berhasil ditolak oleh Kadiv.',
        result: result.data,
      );
      ref.invalidate(kadivAllMutationsProvider);
      ref.invalidate(mutationDetailProvider(mutationId));
      ref.invalidate(mutationListProvider);
      return true;
    } else if (result is AppFailure<Mutation>) {
      state = KadivApprovalActionState(
        isLoading: false,
        error: result.failure.userMessage,
      );
      return false;
    }

    state = const KadivApprovalActionState(
      isLoading: false,
      error: 'Terjadi kesalahan sistem saat menolak mutasi.',
    );
    return false;
  }

  void reset() {
    state = const KadivApprovalActionState();
  }
}

final kadivApprovalActionProvider = StateNotifierProvider<
    KadivApprovalActionNotifier, KadivApprovalActionState>((ref) {
  final approveUseCase = ref.watch(approveMutationKadivUseCaseProvider);
  final rejectUseCase = ref.watch(rejectMutationKadivUseCaseProvider);
  return KadivApprovalActionNotifier(
    approveUseCase: approveUseCase,
    rejectUseCase: rejectUseCase,
    ref: ref,
  );
});
