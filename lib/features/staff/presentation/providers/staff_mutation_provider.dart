// lib/features/staff/presentation/providers/staff_mutation_provider.dart
//
// Riverpod state management untuk fitur Pembaruan Aset oleh Staff Aset.
// Sumber: ROLE-FLOW.md §7, SCREEN-SPEC.md STF-001–003.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/result.dart';
import '../../../asset/presentation/providers/asset_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/domain/usecases/get_staff_mutations_usecase.dart';
import '../../../mutation/domain/usecases/process_staff_asset_update_usecase.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../../../pemohon/presentation/providers/pemohon_confirmation_provider.dart';

// ─── Use Case Providers ───────────────────────────────────────────────────────

final getStaffMutationsUseCaseProvider =
    Provider<GetStaffMutationsUseCase>((ref) {
  final repo = ref.watch(mutationRepositoryProvider);
  return GetStaffMutationsUseCase(repository: repo);
});

final processStaffAssetUpdateUseCaseProvider =
    Provider<ProcessStaffAssetUpdateUseCase>((ref) {
  final repo = ref.watch(mutationRepositoryProvider);
  return ProcessStaffAssetUpdateUseCase(repository: repo);
});

// ─── Filter & Search State ───────────────────────────────────────────────────

enum StaffStatusFilter {
  waitingUpdate,
  processed,
  completed,
  all;

  String get displayName => switch (this) {
        StaffStatusFilter.waitingUpdate => 'Menunggu Update',
        StaffStatusFilter.processed => 'Menunggu Konfirmasi',
        StaffStatusFilter.completed => 'Selesai',
        StaffStatusFilter.all => 'Semua Riwayat Staff',
      };
}

enum StaffSortOrder {
  newest,
  oldest;

  String get displayName => switch (this) {
        StaffSortOrder.newest => 'Terbaru',
        StaffSortOrder.oldest => 'Terlama',
      };
}

final staffSearchQueryProvider = StateProvider<String>((ref) => '');

final staffStatusFilterProvider =
    StateProvider<StaffStatusFilter>((ref) => StaffStatusFilter.waitingUpdate);

final staffSortOrderProvider =
    StateProvider<StaffSortOrder>((ref) => StaffSortOrder.newest);

// ─── Data Providers ──────────────────────────────────────────────────────────

/// Mengambil seluruh mutasi yang relevan untuk Staff Aset.
/// Staff HANYA memproses mutasi yang sudah disetujui (tidak mencampur mutasi yang masih menunggu approval).
final staffAllMutationsProvider = FutureProvider<List<Mutation>>((ref) async {
  final useCase = ref.watch(getStaffMutationsUseCaseProvider);
  final result = await useCase(onlyWaitingUpdate: false);

  if (result is Success<List<Mutation>>) {
    // Hanya mutasi yang sudah melewati tahap approval
    final staffScope = result.data.where((m) =>
        m.status == MutationStatus.approved ||
        m.status == MutationStatus.pendingConfirmation ||
        m.status == MutationStatus.completed).toList();
    return staffScope;
  } else if (result is AppFailure<List<Mutation>>) {
    throw Exception(result.failure.userMessage);
  }
  return [];
});

/// Statistik ringkasan untuk Dashboard Staff Aset.
class StaffStats {
  final int waitingUpdateCount;
  final int processedCount;
  final int completedCount;

  const StaffStats({
    required this.waitingUpdateCount,
    this.processedCount = 0,
    this.completedCount = 0,
  });
}

final staffStatsProvider = Provider<StaffStats>((ref) {
  final asyncMutations = ref.watch(staffAllMutationsProvider);

  return asyncMutations.when(
    data: (mutations) {
      final waiting = mutations
          .where((m) => m.status == MutationStatus.approved)
          .length;
      final processed = mutations
          .where((m) => m.status == MutationStatus.pendingConfirmation)
          .length;
      final completed = mutations
          .where((m) => m.status == MutationStatus.completed)
          .length;
      return StaffStats(
        waitingUpdateCount: waiting,
        processedCount: processed,
        completedCount: completed,
      );
    },
    loading: () => const StaffStats(waitingUpdateCount: 0),
    error: (_, _) => const StaffStats(waitingUpdateCount: 0),
  );
});

/// Provider antrean mutasi terfilter untuk Staff Aset.
/// Staff Aset HANYA melihat pengajuan yang sudah disetujui dan relevan.
final filteredStaffMutationsProvider =
    Provider<AsyncValue<List<Mutation>>>((ref) {
  final asyncMutations = ref.watch(staffAllMutationsProvider);
  final query = ref.watch(staffSearchQueryProvider).toLowerCase().trim();
  final statusFilter = ref.watch(staffStatusFilterProvider);
  final sortOrder = ref.watch(staffSortOrderProvider);

  return asyncMutations.whenData((mutations) {
    // 1. Filter status
    var list = mutations.where((m) {
      return switch (statusFilter) {
        StaffStatusFilter.waitingUpdate =>
          m.status == MutationStatus.approved,
        StaffStatusFilter.processed =>
          m.status == MutationStatus.pendingConfirmation,
        StaffStatusFilter.completed =>
          m.status == MutationStatus.completed,
        StaffStatusFilter.all =>
          m.status == MutationStatus.approved ||
              m.status == MutationStatus.pendingConfirmation ||
              m.status == MutationStatus.completed,
      };
    }).toList();

    // 2. Filter search query
    if (query.isNotEmpty) {
      list = list.where((m) {
        return m.ticketNumber.toLowerCase().contains(query) ||
            m.asset.name.toLowerCase().contains(query) ||
            m.asset.assetCode.toLowerCase().contains(query) ||
            m.applicantName.toLowerCase().contains(query) ||
            m.targetLocation.toLowerCase().contains(query) ||
            m.targetPic.toLowerCase().contains(query);
      }).toList();
    }

    // 3. Sorting berdasarkan tanggal pembuatan
    list.sort((a, b) {
      if (sortOrder == StaffSortOrder.oldest) {
        return a.createdAt.compareTo(b.createdAt);
      } else {
        return b.createdAt.compareTo(a.createdAt);
      }
    });

    return list;
  });
});

// ─── Action State & Notifier ─────────────────────────────────────────────────

class StaffAssetUpdateActionState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;
  final Mutation? updatedMutation;

  const StaffAssetUpdateActionState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
    this.updatedMutation,
  });

  StaffAssetUpdateActionState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
    Mutation? updatedMutation,
    bool clearError = false,
  }) {
    return StaffAssetUpdateActionState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: clearError ? null : (error ?? this.error),
      updatedMutation: updatedMutation ?? this.updatedMutation,
    );
  }
}

class StaffAssetUpdateActionNotifier
    extends StateNotifier<StaffAssetUpdateActionState> {
  final Ref _ref;

  StaffAssetUpdateActionNotifier(this._ref)
      : super(const StaffAssetUpdateActionState());

  Future<bool> processUpdate({
    required String mutationId,
    required String newLocation,
    required String newPic,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final authState = _ref.read(authStateProvider);
    final staffName = authState.user?.name ?? 'Staff Aset';

    final useCase = _ref.read(processStaffAssetUpdateUseCaseProvider);
    final result = await useCase(
      mutationId: mutationId,
      newLocation: newLocation,
      newPic: newPic,
      staffName: staffName,
    );

    if (result is Success<Mutation>) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        updatedMutation: result.data,
      );

      // Invalidate relevant providers to guarantee UI sync
      _ref.invalidate(staffAllMutationsProvider);
      _ref.invalidate(mutationDetailProvider(mutationId));
      _ref.invalidate(mutationListProvider);
      _ref.invalidate(pendingConfirmationsProvider);
      _ref.invalidate(assetListProvider);
      _ref.invalidate(assetDetailProvider(result.data.asset.id));
      _ref.invalidate(userResponsibleAssetsProvider);

      return true;
    } else if (result is AppFailure<Mutation>) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        error: result.failure.userMessage,
      );
      return false;
    }

    state = state.copyWith(isLoading: false);
    return false;
  }

  void reset() {
    state = const StaffAssetUpdateActionState();
  }
}

final staffAssetUpdateActionProvider = StateNotifierProvider<
    StaffAssetUpdateActionNotifier, StaffAssetUpdateActionState>((ref) {
  return StaffAssetUpdateActionNotifier(ref);
});
