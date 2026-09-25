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
  alert,
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
  /// Membangun daftar langkah alur mutasi secara dinamis.
  ///
  /// Alur tanpa Kadiv (5 tahap):
  /// submitted -> waitingKabagApproval -> approvedWaitingAssetUpdate -> pendingConfirmation -> completed
  ///
  /// Alur dengan Kadiv (6 tahap):
  /// submitted -> waitingKabagApproval -> waitingKadivApproval -> approvedWaitingAssetUpdate -> pendingConfirmation -> completed
  static List<MutationTrackingStep> buildTrackingSteps({
    required MutationStatus status,
    required bool requiresKadivApproval,
    String? applicantName,
    DateTime? createdAt,
    String? verifiedBy,
    String? returnReason,
    String? approvedBy,
    String? rejectedBy,
    String? rejectionReason,
    String? kadivApprovedBy,
    String? kadivRejectedBy,
    String? kadivRejectionReason,
    DateTime? kadivRejectedAt,
    String? staffUpdatedBy,
  }) {
    final isKadivRejected = status == MutationStatus.rejected &&
        (kadivRejectionReason != null || kadivRejectedAt != null);
    final isKabagRejected =
        status == MutationStatus.rejected && !isKadivRejected;

    final steps = <MutationTrackingStep>[];

    // ── 1. Step: Diajukan ────────────────────────────────────────────────
    final step1State = switch (status) {
      MutationStatus.returned => TrackingStepState.alert,
      MutationStatus.submitted => TrackingStepState.current,
      _ => TrackingStepState.completed,
    };
    final step1Badge = switch (status) {
      MutationStatus.returned => 'Perlu Perbaikan',
      MutationStatus.submitted => 'Menunggu Verifikasi',
      _ => 'Tiket Dibuat',
    };
    final step1Subtitle = switch (status) {
      MutationStatus.returned =>
        'Pengajuan dikembalikan oleh Operator: ${returnReason?.trim().isNotEmpty == true ? returnReason : "Perlu perbaikan kelengkapan"}',
      MutationStatus.submitted =>
        'Pemohon: ${applicantName ?? "-"} • Menunggu verifikasi Operator',
      _ =>
        'Diajukan oleh ${applicantName ?? "Pemohon"}${verifiedBy != null ? " • Diverifikasi oleh $verifiedBy" : ""}',
    };

    steps.add(
      MutationTrackingStep(
        key: 'submitted',
        title: 'Diajukan oleh Pemohon',
        shortLabel: 'Diajukan',
        subtitle: step1Subtitle,
        badgeText: step1Badge,
        state: step1State,
      ),
    );

    // ── 2. Step: Approval Kabag Aset ─────────────────────────────────────
    final step2State = () {
      if (isKabagRejected) return TrackingStepState.alert;
      if (status == MutationStatus.submitted ||
          status == MutationStatus.returned) {
        return TrackingStepState.upcoming;
      }
      if (status == MutationStatus.waitingKabagApproval ||
          status == MutationStatus.verified) {
        return TrackingStepState.current;
      }
      return TrackingStepState.completed;
    }();
    final step2Badge = () {
      if (isKabagRejected) return 'Ditolak';
      if (status == MutationStatus.waitingKabagApproval ||
          status == MutationStatus.verified) {
        return 'Pemeriksaan Wewenang';
      }
      if (status == MutationStatus.submitted ||
          status == MutationStatus.returned) {
        return 'Menunggu';
      }
      return 'Disetujui';
    }();
    final step2Subtitle = () {
      if (isKabagRejected) {
        return 'Ditolak oleh ${rejectedBy ?? "Kabag Aset"}${rejectionReason != null ? ": $rejectionReason" : ""}';
      }
      if (status == MutationStatus.waitingKabagApproval ||
          status == MutationStatus.verified) {
        return 'Menunggu peninjauan batas wewenang & keputusan Kabag Aset';
      }
      if (status == MutationStatus.submitted ||
          status == MutationStatus.returned) {
        return 'Menunggu verifikasi pengajuan selesai';
      }
      return 'Disetujui oleh ${approvedBy ?? "Kabag Aset"}';
    }();

    steps.add(
      MutationTrackingStep(
        key: 'waitingKabagApproval',
        title: 'Approval Kabag Aset',
        shortLabel: 'Approval Kabag',
        subtitle: step2Subtitle,
        badgeText: step2Badge,
        state: step2State,
      ),
    );

    // ── 3. Step: Approval Kadiv (HANYA MUNCUL JIKA requiresKadivApproval == true) ──
    if (requiresKadivApproval) {
      final stepKadivState = () {
        if (isKadivRejected) return TrackingStepState.alert;
        if (status == MutationStatus.submitted ||
            status == MutationStatus.returned ||
            status == MutationStatus.waitingKabagApproval ||
            status == MutationStatus.verified ||
            isKabagRejected) {
          return TrackingStepState.upcoming;
        }
        if (status == MutationStatus.waitingKadivApproval) {
          return TrackingStepState.current;
        }
        return TrackingStepState.completed;
      }();
      final stepKadivBadge = () {
        if (isKadivRejected) return 'Ditolak';
        if (status == MutationStatus.waitingKadivApproval) {
          return 'Menunggu Kadiv';
        }
        if (status == MutationStatus.approved ||
            status == MutationStatus.pendingConfirmation ||
            status == MutationStatus.completed) {
          return 'Disetujui';
        }
        return 'Menunggu';
      }();
      final stepKadivSubtitle = () {
        if (isKadivRejected) {
          return 'Ditolak oleh ${kadivRejectedBy ?? "Kadiv"}${kadivRejectionReason != null ? ": $kadivRejectionReason" : ""}';
        }
        if (status == MutationStatus.waitingKadivApproval) {
          return 'Menunggu peninjauan & persetujuan Kepala Divisi';
        }
        if (status == MutationStatus.approved ||
            status == MutationStatus.pendingConfirmation ||
            status == MutationStatus.completed) {
          return 'Disetujui oleh ${kadivApprovedBy ?? "Kepala Divisi"}';
        }
        return 'Menunggu persetujuan Kabag Aset';
      }();

      steps.add(
        MutationTrackingStep(
          key: 'waitingKadivApproval',
          title: 'Approval Kepala Divisi (Kadiv)',
          shortLabel: 'Approval Kadiv',
          subtitle: stepKadivSubtitle,
          badgeText: stepKadivBadge,
          state: stepKadivState,
        ),
      );
    }

    // ── 4. Step: Disetujui — Menunggu Update Aset ─────────────────────────
    final stepApprovedState = () {
      if (status == MutationStatus.pendingConfirmation ||
          status == MutationStatus.completed) {
        return TrackingStepState.completed;
      }
      if (status == MutationStatus.approved) {
        return TrackingStepState.current;
      }
      return TrackingStepState.upcoming;
    }();
    final stepApprovedBadge = () {
      if (status == MutationStatus.pendingConfirmation ||
          status == MutationStatus.completed) {
        return 'Fisik Terpindah';
      }
      if (status == MutationStatus.approved) {
        return 'Dalam Proses';
      }
      return 'Menunggu';
    }();
    final stepApprovedSubtitle = () {
      if (status == MutationStatus.pendingConfirmation ||
          status == MutationStatus.completed) {
        return 'Pembaruan fisik & lokasi selesai oleh ${staffUpdatedBy ?? "Staff Aset"}';
      }
      if (status == MutationStatus.approved) {
        return 'Disetujui. Menugaskan pemindahan fisik & update data ke Staff Aset';
      }
      return 'Menunggu persetujuan pejabat berwenang';
    }();

    steps.add(
      MutationTrackingStep(
        key: 'approvedWaitingAssetUpdate',
        title: 'Disetujui — Menunggu Update Aset',
        shortLabel: 'Update Aset',
        subtitle: stepApprovedSubtitle,
        badgeText: stepApprovedBadge,
        state: stepApprovedState,
      ),
    );

    // ── 5. Step: Konfirmasi Penerimaan Aset (pendingConfirmation) ──────────
    final stepConfirmState = () {
      if (status == MutationStatus.completed) {
        return TrackingStepState.completed;
      }
      if (status == MutationStatus.pendingConfirmation) {
        return TrackingStepState.current;
      }
      return TrackingStepState.upcoming;
    }();
    final stepConfirmBadge = () {
      if (status == MutationStatus.completed) {
        return 'Terkonfirmasi';
      }
      if (status == MutationStatus.pendingConfirmation) {
        return 'Konfirmasi Diperlukan';
      }
      return 'Menunggu';
    }();
    final stepConfirmSubtitle = () {
      if (status == MutationStatus.completed) {
        return 'Penerimaan fisik aset telah dikonfirmasi sesuai oleh Pemohon (${applicantName ?? "-"})';
      }
      if (status == MutationStatus.pendingConfirmation) {
        return 'Staff Aset telah menyelesaikan update aset. Pemohon wajib memeriksa fisik dan mengonfirmasi.';
      }
      return 'Pemeriksaan fisik unit di lokasi tujuan oleh Pemohon';
    }();

    steps.add(
      MutationTrackingStep(
        key: 'pendingConfirmation',
        title: 'Konfirmasi Penerimaan Aset',
        shortLabel: 'Konfirmasi',
        subtitle: stepConfirmSubtitle,
        badgeText: stepConfirmBadge,
        state: stepConfirmState,
      ),
    );

    // ── 6. Step: Selesai (completed) ──────────────────────────────────────
    final stepCompletedState = status == MutationStatus.completed
        ? TrackingStepState.completed
        : TrackingStepState.upcoming;
    final stepCompletedBadge =
        status == MutationStatus.completed ? 'Selesai' : 'Menunggu';
    final stepCompletedSubtitle = status == MutationStatus.completed
        ? 'Mutasi selesai secara menyeluruh dan terarsip ke buku besar aset'
        : 'Penyelesaian akhir seluruh alur mutasi aset';

    steps.add(
      MutationTrackingStep(
        key: 'completed',
        title: 'Selesai',
        shortLabel: 'Selesai',
        subtitle: stepCompletedSubtitle,
        badgeText: stepCompletedBadge,
        state: stepCompletedState,
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
      approvedBy: mutation?.approvedBy,
      rejectedBy: mutation?.rejectedBy,
      rejectionReason: mutation?.rejectionReason,
      kadivApprovedBy: mutation?.kadivApprovedBy,
      kadivRejectedBy: mutation?.kadivRejectedBy,
      kadivRejectionReason: mutation?.kadivRejectionReason,
      kadivRejectedAt: mutation?.kadivRejectedAt,
      staffUpdatedBy: mutation?.staffUpdatedBy,
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
