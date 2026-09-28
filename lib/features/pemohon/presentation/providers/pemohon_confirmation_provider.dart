// lib/features/pemohon/presentation/providers/pemohon_confirmation_provider.dart
//
// Riverpod state management untuk fitur Konfirmasi Mutasi oleh Pemohon.
// Sumber: ROLE-FLOW.md §3, SCREEN-SPEC.md REQ-009, TECHNICAL-DESIGN.md.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/result.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mutation/domain/entities/mutation.dart';
import '../../../mutation/domain/entities/mutation_status.dart';
import '../../../mutation/domain/usecases/confirm_mutation_usecase.dart';
import '../../../mutation/presentation/providers/mutation_provider.dart';
import '../../../notification/domain/entities/notification_item.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../../asset/presentation/providers/asset_provider.dart';

// ─── Use Case Provider ────────────────────────────────────────────────────────

final confirmMutationUseCaseProvider = Provider<ConfirmMutationUseCase>((ref) {
  final repo = ref.watch(mutationRepositoryProvider);
  return ConfirmMutationUseCase(repository: repo);
});

// ─── Pending Confirmations Provider ──────────────────────────────────────────

/// Provider daftar mutasi milik user yang sedang menunggu konfirmasi Pemohon.
///
/// Filter: status == pendingConfirmation.
/// Sumber: ROLE-FLOW.md §3, SCREEN-SPEC.md REQ-001 & REQ-009.
final pendingConfirmationsProvider = FutureProvider<List<Mutation>>((
  ref,
) async {
  final asyncMutations = await ref.watch(mutationListProvider.future);

  return asyncMutations
      .where((m) => m.status == MutationStatus.pendingConfirmation)
      .toList();
});

// ─── Confirmation Action State ────────────────────────────────────────────────

class PemohonConfirmationActionState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final Mutation? result;

  const PemohonConfirmationActionState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.result,
  });

  PemohonConfirmationActionState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    Mutation? result,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return PemohonConfirmationActionState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      result: result ?? this.result,
    );
  }
}

// ─── Confirmation Action Notifier ─────────────────────────────────────────────

class PemohonConfirmationActionNotifier
    extends StateNotifier<PemohonConfirmationActionState> {
  final ConfirmMutationUseCase confirmUseCase;
  final Ref ref;

  PemohonConfirmationActionNotifier({
    required this.confirmUseCase,
    required this.ref,
  }) : super(const PemohonConfirmationActionState());

  /// Konfirmasi mutasi oleh Pemohon — status berubah menjadi [completed].
  ///
  /// Mengembalikan `true` jika berhasil, `false` jika gagal.
  /// Status TIDAK berubah sebelum backend berhasil — sesuai ROLE-FLOW.md §8.
  Future<bool> confirm({required String mutationId}) async {
    final authState = ref.read(authStateProvider);
    final confirmedBy = authState.user?.name ?? 'Pemohon';
    final userId = authState.user?.id;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    final result = await confirmUseCase(
      ConfirmMutationParams(
        mutationId: mutationId,
        confirmedBy: confirmedBy,
        userId: userId,
      ),
    );

    if (result is Success<Mutation>) {
      state = PemohonConfirmationActionState(
        isLoading: false,
        successMessage: 'Konfirmasi berhasil. Mutasi aset telah selesai.',
        result: result.data,
      );
      // Refresh daftar mutasi dan detail
      ref.invalidate(mutationListProvider);
      ref.invalidate(mutationDetailProvider(mutationId));
      ref.invalidate(pendingConfirmationsProvider);
      ref.invalidate(assetListProvider);
      ref.invalidate(userResponsibleAssetsProvider);

      // Perbarui notifikasi terkait
      try {
        final notifNotifier = ref.read(notificationProvider.notifier);
        final notifs = ref.read(notificationProvider);
        for (final n in notifs) {
          if (n.relatedMutationId == mutationId && !n.isRead) {
            notifNotifier.markAsRead(n.id);
          }
        }
        notifNotifier.notifyRole(
          targetRole: UserRole.staffAset,
          title: 'Mutasi Selesai',
          message:
              'Pemohon telah mengonfirmasi penerimaan aset untuk pengajuan ${result.data.ticketNumber}.',
          type: NotificationType.success,
          relatedMutationId: mutationId,
        );
        notifNotifier.notifyUser(
          targetUserId: result.data.applicantId ?? 'usr_pemohon',
          targetRole: UserRole.pemohon,
          title: 'Mutasi Selesai',
          message:
              'Mutasi aset ${result.data.ticketNumber} telah dikonfirmasi dan selesai.',
          type: NotificationType.success,
          relatedMutationId: mutationId,
        );
      } catch (_) {}

      return true;
    } else if (result is AppFailure<Mutation>) {
      state = PemohonConfirmationActionState(
        isLoading: false,
        error: result.failure.userMessage,
      );
      return false;
    }

    state = const PemohonConfirmationActionState(
      isLoading: false,
      error: 'Terjadi kesalahan sistem saat melakukan konfirmasi.',
    );
    return false;
  }

  /// Melaporkan ketidaksesuaian hasil update aset saat proses konfirmasi.
  ///
  /// PENTING (koreksi semantik): method ini dipanggil oleh Pemohon ketika
  /// hasil update data aset dari Staff Aset TIDAK sesuai dengan kondisi
  /// fisik (mis. SN tidak cocok, lokasi/PIC salah). Pemohon di sini berperan
  /// sebagai PELAPOR, bukan pihak yang melakukan kesalahan — pihak yang
  /// perlu memperbaiki data adalah Staff Aset.
  ///
  /// Catatan teknis: karena `MutationStatus` belum punya status khusus untuk
  /// membedakan "Operator mengembalikan ke Pemohon di tahap awal" vs
  /// "Pemohon melaporkan ketidaksesuaian setelah update aset", keduanya
  /// masih memakai [MutationStatus.returned] yang sama (lihat catatan di
  /// `mutation_status.dart`). UI (pemohon_confirmation_screen.dart,
  /// pemohon_mutation_list_screen.dart) membedakan kedua kasus ini secara
  /// kontekstual menggunakan `staffUpdatedAt != null` sebagai penanda bahwa
  /// ini adalah laporan ketidaksesuaian dari Pemohon, bukan pengembalian
  /// oleh Operator. Jika suatu saat status baru (mis.
  /// `disputedByApplicant`) ditambahkan di backend, method ini sebaiknya
  /// diarahkan ke status tersebut, bukan `returned`.
  Future<bool> returnForRevision({
    required String mutationId,
    required String reason,
  }) async {
    final authState = ref.read(authStateProvider);
    final pemohonName = authState.user?.name ?? 'Pemohon';

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    final repo = ref.read(mutationRepositoryProvider);
    final result = await repo.returnMutation(
      mutationId: mutationId,
      reason: reason,
      operatorName: pemohonName,
    );

    if (result is Success<Mutation>) {
      state = PemohonConfirmationActionState(
        isLoading: false,
        successMessage:
            'Laporan ketidaksesuaian terkirim. Staff Aset akan '
            'meninjau dan memperbaiki data aset Anda.',
        result: result.data,
      );
      ref.invalidate(mutationListProvider);
      ref.invalidate(mutationDetailProvider(mutationId));
      ref.invalidate(pendingConfirmationsProvider);

      // Perbarui notifikasi terkait
      try {
        final notifNotifier = ref.read(notificationProvider.notifier);
        final notifs = ref.read(notificationProvider);
        for (final n in notifs) {
          if (n.relatedMutationId == mutationId && !n.isRead) {
            notifNotifier.markAsRead(n.id);
          }
        }
        // Notifikasi ke Pemohon sendiri: konfirmasi bahwa laporannya
        // diteruskan, BUKAN menyuruhnya memperbaiki apa pun.
        notifNotifier.addNotification(
          NotificationItem(
            id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Laporan Ketidaksesuaian Terkirim',
            message:
                'Laporan ketidaksesuaian untuk pengajuan ${result.data.ticketNumber} '
                'telah diteruskan ke Staff Aset: $reason',
            type: NotificationType.warning,
            createdAt: DateTime.now(),
            isRead: false,
            relatedMutationId: mutationId,
            targetRole: UserRole.pemohon,
            targetUserId: result.data.applicantId,
          ),
        );
      } catch (_) {}

      return true;
    } else if (result is AppFailure<Mutation>) {
      state = PemohonConfirmationActionState(
        isLoading: false,
        error: result.failure.userMessage,
      );
      return false;
    }

    state = const PemohonConfirmationActionState(
      isLoading: false,
      error: 'Terjadi kesalahan sistem saat memproses laporan.',
    );
    return false;
  }

  void reset() {
    state = const PemohonConfirmationActionState();
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final pemohonConfirmationActionProvider =
    StateNotifierProvider<
      PemohonConfirmationActionNotifier,
      PemohonConfirmationActionState
    >((ref) {
      final useCase = ref.watch(confirmMutationUseCaseProvider);
      return PemohonConfirmationActionNotifier(
        confirmUseCase: useCase,
        ref: ref,
      );
    });
