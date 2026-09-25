// lib/features/kabag/presentation/providers/kabag_approval_provider.dart
//
// Riverpod state management untuk fitur Approval Kabag Aset.
// Sumber: ROLE-FLOW.md §5, SCREEN-SPEC.md KBG-001–004.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/result.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/domain/usecases/approve_mutation_kabag_usecase.dart';
import '../../../mutation/domain/usecases/get_kabag_approvals_usecase.dart';
import '../../../mutation/domain/usecases/reject_mutation_kabag_usecase.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../kadiv/presentation/providers/kadiv_approval_provider.dart';
import '../../../notification/domain/entities/notification_item.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../../staff/presentation/providers/staff_mutation_provider.dart';

// ─── Use Case Providers ───────────────────────────────────────────────────────

final approveMutationKabagUseCaseProvider =
    Provider<ApproveMutationKabagUseCase>((ref) {
  final repo = ref.watch(mutationRepositoryProvider);
  return ApproveMutationKabagUseCase(repository: repo);
});

final rejectMutationKabagUseCaseProvider =
    Provider<RejectMutationKabagUseCase>((ref) {
  final repo = ref.watch(mutationRepositoryProvider);
  return RejectMutationKabagUseCase(repository: repo);
});

final getKabagApprovalsUseCaseProvider =
    Provider<GetKabagApprovalsUseCase>((ref) {
  final repo = ref.watch(mutationRepositoryProvider);
  return GetKabagApprovalsUseCase(repository: repo);
});

// ─── Filter & Search State ───────────────────────────────────────────────────

enum KabagSortOrder {
  newest,
  oldest;

  String get displayName => switch (this) {
        KabagSortOrder.newest => 'Terbaru',
        KabagSortOrder.oldest => 'Terlama',
      };
}

enum KabagStatusFilter {
  waiting,
  approved,
  rejected,
  all;

  String get displayName => switch (this) {
        KabagStatusFilter.waiting => 'Menunggu Approval',
        KabagStatusFilter.approved => 'Disetujui',
        KabagStatusFilter.rejected => 'Ditolak',
        KabagStatusFilter.all => 'Semua',
      };
}

final kabagSearchQueryProvider = StateProvider<String>((ref) => '');

final kabagSortOrderProvider =
    StateProvider<KabagSortOrder>((ref) => KabagSortOrder.newest);

final kabagStatusFilterProvider =
    StateProvider<KabagStatusFilter>((ref) => KabagStatusFilter.waiting);

// ─── Mutations Data Providers ────────────────────────────────────────────────

/// Provider seluruh mutasi untuk Kabag Aset.
final kabagAllMutationsProvider = FutureProvider<List<Mutation>>((ref) async {
  final useCase = ref.watch(getKabagApprovalsUseCaseProvider);
  final result = await useCase();

  if (result is Success<List<Mutation>>) {
    return result.data;
  } else if (result is AppFailure<List<Mutation>>) {
    throw Exception(result.failure.userMessage);
  }
  return [];
});

/// Statistik overview approval untuk Dashboard Kabag (KBG-001).
class KabagApprovalStats {
  final int waitingApprovalCount;
  final int approvedCount;
  final int rejectedCount;

  const KabagApprovalStats({
    required this.waitingApprovalCount,
    required this.approvedCount,
    required this.rejectedCount,
  });
}

final kabagStatsProvider = Provider<KabagApprovalStats>((ref) {
  final asyncMutations = ref.watch(kabagAllMutationsProvider);

  return asyncMutations.when(
    data: (mutations) {
      final waiting = mutations
          .where((m) => m.status == MutationStatus.waitingKabagApproval)
          .length;
      final approved = mutations.where((m) {
        return m.approvedBy != null ||
            m.approvedAt != null ||
            m.status == MutationStatus.waitingKadivApproval ||
            m.status == MutationStatus.approved ||
            m.status == MutationStatus.pendingConfirmation ||
            m.status == MutationStatus.completed;
      }).length;
      final rejected = mutations.where((m) {
        return m.status == MutationStatus.rejected;
      }).length;

      return KabagApprovalStats(
        waitingApprovalCount: waiting,
        approvedCount: approved,
        rejectedCount: rejected,
      );
    },
    loading: () => const KabagApprovalStats(
      waitingApprovalCount: 0,
      approvedCount: 0,
      rejectedCount: 0,
    ),
    error: (_, _) => const KabagApprovalStats(
      waitingApprovalCount: 0,
      approvedCount: 0,
      rejectedCount: 0,
    ),
  );
});

/// Provider antrean mutasi untuk Kabag Aset dengan filter status, pencarian, dan sorting.
final filteredKabagApprovalsProvider =
    Provider<AsyncValue<List<Mutation>>>((ref) {
  final asyncAll = ref.watch(kabagAllMutationsProvider);
  final query = ref.watch(kabagSearchQueryProvider).toLowerCase().trim();
  final sortOrder = ref.watch(kabagSortOrderProvider);
  final statusFilter = ref.watch(kabagStatusFilterProvider);

  return asyncAll.whenData((mutations) {
    // 1. Filter status
    var list = mutations.where((m) {
      return switch (statusFilter) {
        KabagStatusFilter.waiting =>
          m.status == MutationStatus.waitingKabagApproval,
        KabagStatusFilter.approved =>
          m.approvedBy != null ||
              m.approvedAt != null ||
              m.status == MutationStatus.waitingKadivApproval ||
              m.status == MutationStatus.approved ||
              m.status == MutationStatus.pendingConfirmation ||
              m.status == MutationStatus.completed,
        KabagStatusFilter.rejected =>
          m.status == MutationStatus.rejected,
        KabagStatusFilter.all =>
          m.status == MutationStatus.waitingKabagApproval ||
              m.status == MutationStatus.waitingKadivApproval ||
              m.status == MutationStatus.approved ||
              m.status == MutationStatus.rejected ||
              m.status == MutationStatus.pendingConfirmation ||
              m.status == MutationStatus.completed ||
              m.approvedBy != null ||
              m.rejectedBy != null,
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
      if (sortOrder == KabagSortOrder.oldest) {
        return a.createdAt.compareTo(b.createdAt);
      } else {
        return b.createdAt.compareTo(a.createdAt);
      }
    });

    return list;
  });
});

// ─── Kabag Action Notifier ───────────────────────────────────────────────────

class KabagApprovalActionState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final Mutation? result;

  const KabagApprovalActionState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.result,
  });

  KabagApprovalActionState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    Mutation? result,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return KabagApprovalActionState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      result: result ?? this.result,
    );
  }
}

class KabagApprovalActionNotifier
    extends StateNotifier<KabagApprovalActionState> {
  final ApproveMutationKabagUseCase approveUseCase;
  final RejectMutationKabagUseCase rejectUseCase;
  final Ref ref;

  KabagApprovalActionNotifier({
    required this.approveUseCase,
    required this.rejectUseCase,
    required this.ref,
  }) : super(const KabagApprovalActionState());

  /// Eksekusi Approve oleh Kabag Aset
  Future<bool> approve({
    required String mutationId,
    bool? requiresKadivApproval,
  }) async {
    final authState = ref.read(authStateProvider);
    final kabagName = authState.user?.name ?? 'Kabag Aset';

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    final result = await approveUseCase(
      mutationId: mutationId,
      kabagName: kabagName,
      requiresKadivApproval: requiresKadivApproval,
    );

    if (result is Success<Mutation>) {
      final isKadiv = result.data.requiresKadivApproval;
      state = KabagApprovalActionState(
        isLoading: false,
        successMessage: isKadiv
            ? 'Pengajuan disetujui dan diteruskan ke Kadiv.'
            : 'Pengajuan mutasi berhasil disetujui.',
        result: result.data,
      );
      ref.invalidate(kabagAllMutationsProvider);
      ref.invalidate(mutationDetailProvider(mutationId));
      ref.invalidate(mutationListProvider);

      if (isKadiv) {
        ref.invalidate(kadivAllMutationsProvider);
        try {
          ref.read(notificationProvider.notifier).notifyRole(
                targetRole: UserRole.kadiv,
                title: 'Menunggu Approval Kadiv',
                message:
                    'Pengajuan mutasi ${result.data.ticketNumber} (${result.data.asset.name}) disetujui Kabag dan memerlukan persetujuan akhir Kadiv.',
                type: NotificationType.action,
                relatedMutationId: mutationId,
              );
        } catch (_) {}
      } else {
        ref.invalidate(staffAllMutationsProvider);
        try {
          ref.read(notificationProvider.notifier).notifyRole(
                targetRole: UserRole.staffAset,
                title: 'Menunggu Pembaruan Aset',
                message:
                    'Pengajuan mutasi ${result.data.ticketNumber} (${result.data.asset.name}) telah disetujui Kabag dan siap diperbarui oleh Staff Aset.',
                type: NotificationType.action,
                relatedMutationId: mutationId,
              );
        } catch (_) {}
      }
      return true;
    } else if (result is AppFailure<Mutation>) {
      state = KabagApprovalActionState(
        isLoading: false,
        error: result.failure.userMessage,
      );
      return false;
    }

    state = const KabagApprovalActionState(
      isLoading: false,
      error: 'Terjadi kesalahan sistem saat menyetujui mutasi.',
    );
    return false;
  }

  /// Eksekusi Reject oleh Kabag Aset
  Future<bool> reject({
    required String mutationId,
    required String reason,
  }) async {
    final authState = ref.read(authStateProvider);
    final kabagName = authState.user?.name ?? 'Kabag Aset';

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    final result = await rejectUseCase(
      mutationId: mutationId,
      reason: reason,
      kabagName: kabagName,
    );

    if (result is Success<Mutation>) {
      state = KabagApprovalActionState(
        isLoading: false,
        successMessage: 'Pengajuan mutasi berhasil ditolak.',
        result: result.data,
      );
      ref.invalidate(kabagAllMutationsProvider);
      ref.invalidate(mutationDetailProvider(mutationId));
      ref.invalidate(mutationListProvider);

      try {
        if (result.data.applicantId != null) {
          ref.read(notificationProvider.notifier).notifyUser(
                targetUserId: result.data.applicantId!,
                targetRole: UserRole.pemohon,
                title: 'Pengajuan Mutasi Ditolak Kabag',
                message:
                    'Pengajuan mutasi ${result.data.ticketNumber} ditolak oleh Kabag Aset dengan alasan: $reason',
                type: NotificationType.warning,
                relatedMutationId: mutationId,
              );
        }
      } catch (_) {}
      return true;
    } else if (result is AppFailure<Mutation>) {
      state = KabagApprovalActionState(
        isLoading: false,
        error: result.failure.userMessage,
      );
      return false;
    }

    state = const KabagApprovalActionState(
      isLoading: false,
      error: 'Terjadi kesalahan sistem saat menolak mutasi.',
    );
    return false;
  }

  void reset() {
    state = const KabagApprovalActionState();
  }
}

final kabagApprovalActionProvider = StateNotifierProvider<
    KabagApprovalActionNotifier, KabagApprovalActionState>((ref) {
  final approveUseCase = ref.watch(approveMutationKabagUseCaseProvider);
  final rejectUseCase = ref.watch(rejectMutationKabagUseCaseProvider);
  return KabagApprovalActionNotifier(
    approveUseCase: approveUseCase,
    rejectUseCase: rejectUseCase,
    ref: ref,
  );
});
