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
    final step1State = isWaitingOperator
        ? TrackingStepState.current
        : TrackingStepState.completed;
    final step1Badge = isWaitingOperator ? 'Diproses' : 'Selesai';
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
    final step2State = () {
      if (isReturned && (returnReason != null && returnReason.isNotEmpty)) {
        return TrackingStepState.alert;
      }
      if (isWaitingOperator) return TrackingStepState.current;
      return TrackingStepState.completed;
    }();
    final step2Badge = () {
      if (isReturned && (returnReason != null && returnReason.isNotEmpty)) {
        return 'Perlu Perbaikan';
      }
      if (isWaitingOperator) return 'Sedang Diperiksa';
      return 'Lengkap';
    }();
    final step2Subtitle = () {
      if (isReturned && (returnReason != null && returnReason.isNotEmpty)) {
        return 'Dikembalikan oleh Operator: $returnReason';
      }
      if (isWaitingOperator) {
        return 'Pemeriksaan kelengkapan data & SK SDM oleh Operator';
      }
      return 'Dinyatakan lengkap${verifiedBy != null ? " oleh $verifiedBy" : ""} dan diteruskan';
    }();

    steps.add(
      MutationTrackingStep(
        key: 'operatorCheck',
        title: 'Pemeriksaan Kelengkapan',
        shortLabel: 'Kelengkapan',
        subtitle: step2Subtitle,
        badgeText: step2Badge,
        state: step2State,
      ),
    );

    // ── 3. Step: Verifikasi Data Aset (Bagian Aset) ───────────────────────
    final step3State = () {
      if (isReturned && (assetReturnReason != null && assetReturnReason.isNotEmpty)) {
        return TrackingStepState.alert;
      }
      if (isWaitingOperator || (isReturned && !step2State.isAlert)) {
        return TrackingStepState.upcoming;
      }
      if (isWaitingAsset) return TrackingStepState.current;
      return TrackingStepState.completed;
    }();
    final step3Badge = () {
      if (isReturned && (assetReturnReason != null && assetReturnReason.isNotEmpty)) {
        return 'Tidak Valid';
      }
      if (isWaitingAsset) return 'Sedang Diverifikasi';
      if (isWaitingOperator) return 'Menunggu';
      return 'Valid';
    }();
    final step3Subtitle = () {
      if (isReturned && (assetReturnReason != null && assetReturnReason.isNotEmpty)) {
        return 'Dikembalikan oleh Bagian Aset: $assetReturnReason';
      }
      if (isWaitingAsset) {
        return 'Verifikasi keabsahan aset, lokasi, SK SDM, dan penentuan PIC baru';
      }
      if (isWaitingOperator) {
        return 'Menunggu pemeriksaan kelengkapan Operator selesai';
      }
      return 'Terverifikasi valid${assetVerifiedBy != null ? " oleh $assetVerifiedBy" : ""}';
    }();

    steps.add(
      MutationTrackingStep(
        key: 'assetVerification',
        title: 'Verifikasi Bagian Aset',
        shortLabel: 'Verifikasi Aset',
        subtitle: step3Subtitle,
        badgeText: step3Badge,
        state: step3State,
      ),
    );

    // ── 4. Step: Approval Final (Pemimpin Divisi) ─────────────────────────
    final step4State = () {
      if (isRejected) return TrackingStepState.alert;
      if (isWaitingDivision) return TrackingStepState.current;
      if (isWaitingOperator || isWaitingAsset || isReturned) {
        return TrackingStepState.upcoming;
      }
      return TrackingStepState.completed;
    }();
    final step4Badge = () {
      if (isRejected) return 'Ditolak';
      if (isWaitingDivision) return 'Menunggu Approval';
      if (isWaitingOperator || isWaitingAsset || isReturned) return 'Menunggu';
      return 'Disetujui';
    }();
    final step4Subtitle = () {
      if (isRejected) {
        final reason = kadivRejectionReason ?? rejectionReason ?? 'Pengajuan ditolak';
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
