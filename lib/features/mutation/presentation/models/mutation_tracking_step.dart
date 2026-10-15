// lib/features/mutation/presentation/models/mutation_tracking_step.dart
//
// Model dan helper standarisasi tracking / stepper alur mutasi untuk seluruh role.
// Sumber kebenaran tunggal: Mutation.status & Mutation.requiresKadivApproval.

import '../../domain/entities/mutation.dart';
import '../../domain/entities/mutation_status.dart';

/// Status representasi visual untuk setiap langkah di alur mutasi.
enum TrackingStepState {
  /// Langkah telah selesai dikerjakan (ditandai centang hijau).
  completed,

  /// Langkah yang sedang aktif / sedang berjalan saat ini.
  current,

  /// Langkah di masa mendatang yang belum tercapai (abu-abu / inaktif).
  upcoming,

  /// Langkah mengalami peringatan atau pengembalian/penolakan (merah / oranye).
  alert;

  bool get isAlert => this == TrackingStepState.alert;
  bool get isCompleted => this == TrackingStepState.completed;
  bool get isCurrent => this == TrackingStepState.current;
  bool get isUpcoming => this == TrackingStepState.upcoming;
}

/// Item langkah tracking untuk UI stepper & timeline.
class MutationTrackingStep {
  final String key;
  final String title;
  final String shortLabel;
  final String subtitle;
  final String badgeText;
  final TrackingStepState state;

  const MutationTrackingStep({
    required this.key,
    required this.title,
    required this.shortLabel,
    required this.subtitle,
    required this.badgeText,
    required this.state,
  });

  bool get isCompleted => state == TrackingStepState.completed;
  bool get isCurrent => state == TrackingStepState.current;
  bool get isUpcoming => state == TrackingStepState.upcoming;
  bool get isAlert => state == TrackingStepState.alert;
}

/// Helper sentral untuk menghasilkan daftar tracking step secara deterministik
/// dari status mutasi dan flag [requiresKadivApproval].
abstract final class MutationTrackingHelper {
  /// Membangun daftar langkah alur mutasi secara dinamis sesuai PRD V1.1:
  /// Pengajuan -> Pemeriksaan Kelengkapan -> Verifikasi Data Aset -> Approval Final -> Konfirmasi -> Pembaruan Data Aset
  static List<MutationTrackingStep> buildTrackingSteps({
    required MutationStatus status,
    bool requiresKadivApproval = true,
    String? applicantName,
    DateTime? createdAt,
    String? verifiedBy,
    String? returnReason,
    String? assetVerifiedBy,
    String? assetReturnReason,
    String? assetRejectedBy,
    String? approvedBy,
    String? rejectedBy,
    String? rejectionReason,
    String? kadivApprovedBy,
    String? kadivRejectedBy,
    String? kadivRejectionReason,
    DateTime? kadivRejectedAt,
    String? staffUpdatedBy,
    String? confirmationReason,
  }) {
    final isRejected = status == MutationStatus.rejected;
    final isReturned = status == MutationStatus.returned;
    final isWaitingOperator = status == MutationStatus.submitted;
    final isWaitingAsset = status.isWaitingAssetVerification;
    final isWaitingDivision = status.isWaitingDivisionApproval;
    final isWaitingConfirmation = status.isWaitingConfirmation;
    final isCompleted = status == MutationStatus.completed;

    final steps = <MutationTrackingStep>[];

    // ── 1. Step: Pengajuan (Pemohon) ─────────────────────────────────────
    final step1State = TrackingStepState.completed;
    const step1Badge = 'Selesai';
    final step1Subtitle = 'Diajukan oleh ${applicantName ?? "Pemohon"}';

    steps.add(
      MutationTrackingStep(
        key: 'submitted',
        title: 'Pengajuan Mutasi',
        shortLabel: 'Pengajuan',
        subtitle: step1Subtitle,
        badgeText: step1Badge,
        state: step1State,
      ),
    );

    // ── 2. Step: Pemeriksaan Kelengkapan (Operator) ──────────────────────
    final isOperatorReturned =
        isReturned && (assetReturnReason == null || assetReturnReason.isEmpty);
    final isAssetReturned =
        isReturned &&
        (assetReturnReason != null && assetReturnReason.isNotEmpty);

    final step2State = () {
      if (isOperatorReturned) {
        return TrackingStepState.alert;
      }
      if (isWaitingOperator) return TrackingStepState.current;
      return TrackingStepState.completed;
    }();
    final step2Badge = () {
      if (isOperatorReturned) {
        return 'Perlu Perbaikan';
      }
      if (isWaitingOperator) return 'Menunggu Pemeriksaan';
      return 'Lengkap';
    }();
    final step2ShortLabel = isOperatorReturned
        ? 'Perlu Perbaikan'
        : 'Pemeriksaan Operator';
    final step2Subtitle = () {
      if (isOperatorReturned) {
        final reason = (returnReason != null && returnReason.isNotEmpty)
            ? ': $returnReason'
            : ' untuk perbaikan berkas';
        return 'Dikembalikan oleh Operator$reason';
      }
      if (isWaitingOperator) {
        return 'Pemeriksaan kelengkapan data & SK SDM oleh Operator';
      }
      return 'Dinyatakan lengkap${verifiedBy != null ? " oleh $verifiedBy" : ""} dan diteruskan';
    }();

    steps.add(
      MutationTrackingStep(
        key: 'operatorCheck',
        title: isOperatorReturned
            ? 'Perlu Perbaikan (Operator)'
            : 'Pemeriksaan Kelengkapan Operator',
        shortLabel: step2ShortLabel,
        subtitle: step2Subtitle,
        badgeText: step2Badge,
        state: step2State,
      ),
    );

    // ── 3. Step: Verifikasi Data Aset (Bagian Aset) ───────────────────────
    final isKadivRejected = isRejected &&
        assetRejectedBy == null &&
        (kadivRejectedBy != null ||
            kadivRejectionReason != null ||
            kadivApprovedBy != null);
    final isAssetRejected = isRejected && !isKadivRejected;

    final step3State = () {
      if (isAssetReturned || isAssetRejected) {
        return TrackingStepState.alert;
      }
      if (isWaitingOperator || isOperatorReturned) {
        return TrackingStepState.upcoming;
      }
      if (isWaitingAsset) return TrackingStepState.current;
      return TrackingStepState.completed;
    }();
    final step3Badge = () {
      if (isAssetRejected) {
        return 'Ditolak';
      }
      if (isAssetReturned) {
        return 'Dikembalikan';
      }
      if (isWaitingAsset) return 'Sedang Diverifikasi';
      if (isWaitingOperator || isOperatorReturned) return 'Menunggu';
      return 'Valid';
    }();
    final step3Subtitle = () {
      if (isAssetRejected) {
        final reason = rejectionReason ?? 'Pengajuan ditolak oleh Bagian Aset';
        final by = assetRejectedBy ?? rejectedBy ?? 'Bagian Aset';
        return 'Ditolak oleh $by: $reason';
      }
      if (isAssetReturned) {
        final reason = assetReturnReason.isNotEmpty
            ? assetReturnReason
            : ((returnReason?.isNotEmpty == true)
                ? returnReason!
                : 'Aset tidak sesuai');
        return 'Dikembalikan oleh Bagian Aset: $reason — pengajuan telah selesai.';
      }
      if (isWaitingAsset) {
        return 'Verifikasi keabsahan aset, lokasi, SK SDM, dan penentuan PIC baru';
      }
      if (isWaitingOperator || isOperatorReturned) {
        return 'Menunggu pemeriksaan kelengkapan Operator selesai';
      }
      return 'Terverifikasi valid${assetVerifiedBy != null ? " oleh $assetVerifiedBy" : ""}';
    }();

    steps.add(
      MutationTrackingStep(
        key: 'assetVerification',
        title: isAssetRejected
            ? 'Verifikasi Bagian Aset (Ditolak)'
            : isAssetReturned
            ? 'Verifikasi Bagian Aset (Dikembalikan)'
            : 'Verifikasi Bagian Aset',
        shortLabel: 'Verifikasi Aset',
        subtitle: step3Subtitle,
        badgeText: step3Badge,
        state: step3State,
      ),
    );

    // Jika pengajuan dikembalikan / ditolak oleh Bagian Aset, alur berakhir di sini secara terminal.
    // Tidak diteruskan ke Pemimpin Divisi, tidak looping ke Operator atau Pemohon.
    if (isAssetReturned || isAssetRejected) {
      return steps;
    }

    // ── 4. Step: Approval Final (Pemimpin Divisi) ─────────────────────────
    final step4State = () {
      if (isKadivRejected) return TrackingStepState.alert;
      if (isWaitingDivision) return TrackingStepState.current;
      if (isWaitingOperator || isWaitingAsset || isReturned) {
        return TrackingStepState.upcoming;
      }
      return TrackingStepState.completed;
    }();
    final step4Badge = () {
      if (isKadivRejected) return 'Ditolak';
      if (isWaitingDivision) return 'Menunggu Approval';
      if (isWaitingOperator || isWaitingAsset || isReturned) return 'Menunggu';
      return 'Disetujui';
    }();
    final step4Subtitle = () {
      if (isKadivRejected) {
        final reason =
            kadivRejectionReason ?? rejectionReason ?? 'Pengajuan ditolak';
        final by = kadivRejectedBy ?? rejectedBy ?? 'Pemimpin Divisi';
        return 'Ditolak oleh $by: $reason';
      }
      if (isWaitingDivision) {
        return 'Menunggu approval final dari Pemimpin Divisi';
      }
      if (isWaitingOperator || isWaitingAsset || isReturned) {
        return 'Menunggu hasil verifikasi Bagian Aset';
      }
      final approver = kadivApprovedBy ?? approvedBy ?? 'Pemimpin Divisi';
      return 'Disetujui oleh $approver';
    }();

    steps.add(
      MutationTrackingStep(
        key: 'divisionApproval',
        title: 'Approval Pemimpin Divisi',
        shortLabel: 'Approval Final',
        subtitle: step4Subtitle,
        badgeText: step4Badge,
        state: step4State,
      ),
    );

    // Jika pengajuan ditolak oleh Pemimpin Divisi, alur berakhir di sini secara terminal.
    // Tidak diteruskan ke Konfirmasi Pemohon atau Pembaruan Data Aset.
    if (isKadivRejected) {
      return steps;
    }

    // ── 5. Step: Konfirmasi Pemohon ──────────────────────────────────────
    final step5State = () {
      if (isCompleted) return TrackingStepState.completed;
      if (isWaitingConfirmation) return TrackingStepState.current;
      return TrackingStepState.upcoming;
    }();
    final step5Badge = () {
      if (isCompleted) return 'Sesuai';
      if (isWaitingConfirmation) return 'Perlu Konfirmasi';
      return 'Menunggu';
    }();
    final step5Subtitle = () {
      if (isCompleted) {
        return 'Fisik aset telah diperiksa dan dikonfirmasi sesuai oleh Pemohon';
      }
      if (isWaitingConfirmation) {
        return 'Pengajuan disetujui. Pemohon memeriksa fisik aset di lokasi tujuan.';
      }
      return 'Pemeriksaan fisik aset di lokasi tujuan oleh Pemohon';
    }();

    steps.add(
      MutationTrackingStep(
        key: 'confirmation',
        title: 'Konfirmasi Pemohon',
        shortLabel: 'Konfirmasi',
        subtitle: step5Subtitle,
        badgeText: step5Badge,
        state: step5State,
      ),
    );

    // ── 6. Step: Selesai & Pembaruan Data Aset ────────────────────────────
    final step6State = isCompleted
        ? TrackingStepState.completed
        : TrackingStepState.upcoming;
    final step6Badge = isCompleted ? 'Selesai' : 'Menunggu';
    final step6Subtitle = isCompleted
        ? 'Data lokasi dan PIC aset berhasil diperbarui otomatis pada sistem'
        : 'Pembaruan otomatis data master lokasi dan PIC aset';

    steps.add(
      MutationTrackingStep(
        key: 'completed',
        title: 'Selesai & Pembaruan Data',
        shortLabel: 'Selesai',
        subtitle: step6Subtitle,
        badgeText: step6Badge,
        state: step6State,
      ),
    );

    return steps;
  }

  /// Helper praktis dari objek [Mutation].
  static List<MutationTrackingStep> getStepsForMutation(
    MutationStatus status, {
    Mutation? mutation,
    bool? requiresKadivApproval,
  }) {
    final kadivReq =
        requiresKadivApproval ?? mutation?.requiresKadivApproval ?? false;
    return buildTrackingSteps(
      status: status,
      requiresKadivApproval: kadivReq,
      applicantName: mutation?.applicantName,
      createdAt: mutation?.createdAt,
      verifiedBy: mutation?.verifiedBy,
      returnReason: mutation?.returnReason,
      assetVerifiedBy: mutation?.assetVerifiedBy,
      assetReturnReason: mutation?.assetReturnReason,
      assetRejectedBy: mutation?.assetRejectedBy,
      approvedBy: mutation?.approvedBy,
      rejectedBy: mutation?.rejectedBy,
      rejectionReason: mutation?.rejectionReason,
      kadivApprovedBy: mutation?.kadivApprovedBy,
      kadivRejectedBy: mutation?.kadivRejectedBy,
      kadivRejectionReason: mutation?.kadivRejectionReason,
      kadivRejectedAt: mutation?.kadivRejectedAt,
      staffUpdatedBy: mutation?.staffUpdatedBy,
      confirmationReason: mutation?.confirmationReason,
    );
  }

  /// Menghitung nomor tahap aktif (1-indexed) untuk label "Tahap X dari Y".
  static int getActiveStageNumber(List<MutationTrackingStep> steps) {
    final currentIndex = steps.indexWhere((s) => s.isCurrent || s.isAlert);
    if (currentIndex != -1) {
      return currentIndex + 1;
    }
    if (steps.every((s) => s.isCompleted)) {
      return steps.length;
    }
    return 1;
  }
}
