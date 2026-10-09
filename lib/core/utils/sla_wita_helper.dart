// lib/core/utils/sla_wita_helper.dart
//
// Helper sentral untuk penanganan zona waktu WITA (Asia/Makassar, UTC+8)
// dan kalkulasi Service Level Agreement (SLA) jam kerja operasional:
// - Hari kerja: Senin – Jumat
// - Jam kerja: 08.00 – 17.00 WITA
// - Akhir pekan (Sabtu & Minggu): Tidak dihitung
// - Tidak mengubah status mutasi secara otomatis saat SLA terlewati
// - Tidak mengarang target durasi SLA yang belum ditentukan dalam spesifikasi

abstract final class SlaWitaHelper {
  /// Offset WITA terhadap UTC (+8 jam)
  static const Duration witaOffset = Duration(hours: 8);

  static const int workStartHour = 8;
  static const int workEndHour = 17;

  /// Konversi sembarang [DateTime] ke waktu WITA (UTC+8) secara deterministik.
  static DateTime toWita(DateTime dt) {
    final utc = dt.toUtc();
    return utc.add(witaOffset);
  }

  /// Format tanggal singkat dalam WITA: "09 Okt 2026, 14:30 WITA"
  static String formatDateTimeWita(DateTime? dt) {
    if (dt == null) return '-';
    final wita = toWita(dt);

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    final day = wita.day.toString().padLeft(2, '0');
    final month = months[wita.month - 1];
    final year = wita.year;
    final hour = wita.hour.toString().padLeft(2, '0');
    final minute = wita.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute WITA';
  }

  /// Format tanggal saja dalam WITA: "09 Okt 2026"
  static String formatDateWita(DateTime? dt) {
    if (dt == null) return '-';
    final wita = toWita(dt);

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    final day = wita.day.toString().padLeft(2, '0');
    final month = months[wita.month - 1];
    final year = wita.year;

    return '$day $month $year';
  }

  /// Menghitung akumulasi jam & menit kerja bisnis (Senin–Jumat 08.00–17.00 WITA)
  /// yang telah berjalan sejak [start] hingga [end] (default: sekarang).
  /// Akhir pekan dan malam hari tidak dihitung.
  static int calculateBusinessMinutes(DateTime start, [DateTime? end]) {
    final startWita = toWita(start);
    final endWita = toWita(end ?? DateTime.now());

    if (!startWita.isBefore(endWita)) {
      return 0;
    }

    int totalMinutes = 0;
    DateTime current = startWita;

    while (current.isBefore(endWita)) {
      // Lewati Sabtu (6) dan Minggu (7)
      if (current.weekday == DateTime.saturday ||
          current.weekday == DateTime.sunday) {
        final nextDay = DateTime.utc(
          current.year,
          current.month,
          current.day,
        ).add(const Duration(days: 1));
        current = DateTime.utc(
          nextDay.year,
          nextDay.month,
          nextDay.day,
          workStartHour,
        );
        continue;
      }

      // Jika sebelum jam 08:00 pada hari kerja, majukan ke 08:00
      if (current.hour < workStartHour) {
        current = DateTime.utc(
          current.year,
          current.month,
          current.day,
          workStartHour,
        );
        if (!current.isBefore(endWita)) {
          break;
        }
      }

      // Jika sudah >= 17:00, lompat ke 08:00 hari kerja berikutnya
      if (current.hour >= workEndHour) {
        final nextDay = DateTime.utc(
          current.year,
          current.month,
          current.day,
        ).add(const Duration(days: 1));
        current = DateTime.utc(
          nextDay.year,
          nextDay.month,
          nextDay.day,
          workStartHour,
        );
        continue;
      }

      // Akhir jam kerja hari ini (17:00)
      final endOfToday = DateTime.utc(
        current.year,
        current.month,
        current.day,
        workEndHour,
      );
      final segmentEnd = endWita.isBefore(endOfToday) ? endWita : endOfToday;

      final diffMinutes = segmentEnd.difference(current).inMinutes;
      if (diffMinutes > 0) {
        totalMinutes += diffMinutes;
      }

      final nextDay = DateTime.utc(
        current.year,
        current.month,
        current.day,
      ).add(const Duration(days: 1));
      current = DateTime.utc(
        nextDay.year,
        nextDay.month,
        nextDay.day,
        workStartHour,
      );
    }

    return totalMinutes;
  }

  /// Batas SLA maksimal 2 jam kerja (120 menit) untuk setiap tahap petugas.
  static const int stageTargetMinutes = 120;

  /// Format durasi menit kerja bisnis menjadi string deskriptif ringkas: "X Jam Y Menit" atau "X Menit".
  static String formatBusinessDuration(int minutes) {
    if (minutes <= 0) return '0 Menit';
    final hours = minutes ~/ 60;
    final remMinutes = minutes % 60;

    if (hours > 0 && remMinutes > 0) {
      return '$hours Jam $remMinutes Menit';
    }
    if (hours > 0) {
      return '$hours Jam';
    }
    return '$remMinutes Menit';
  }

  /// Evaluasi SLA per tahap petugas:
  /// - Menghitung jam kerja Senin–Jumat 08.00–17.00 WITA.
  /// - Batas maksimal 2 jam (120 menit).
  /// - Jika selesai: tampilkan "Durasi: X".
  /// - Jika masih berjalan dan <= 120 menit: tampilkan "Sisa SLA: X".
  /// - Jika masih berjalan dan > 120 menit: tampilkan "SLA Terlambat: X" (tanpa ubah status otomatis).
  static SlaStageResult evaluateStageSla(
    DateTime stageStart, [
    DateTime? stageEnd,
    DateTime? now,
  ]) {
    final isFinished = stageEnd != null;
    final effectiveEnd = stageEnd ?? now ?? DateTime.now();
    final elapsed = calculateBusinessMinutes(stageStart, effectiveEnd);

    if (isFinished) {
      return SlaStageResult(
        elapsedMinutes: elapsed,
        isFinished: true,
        isOverdue: elapsed > stageTargetMinutes,
        label: 'Durasi: ${formatBusinessDuration(elapsed)}',
      );
    }

    if (elapsed <= stageTargetMinutes) {
      final remaining = stageTargetMinutes - elapsed;
      return SlaStageResult(
        elapsedMinutes: elapsed,
        remainingMinutes: remaining,
        isFinished: false,
        isOverdue: false,
        label: 'Sisa SLA: ${formatBusinessDuration(remaining)}',
      );
    }

    final overdue = elapsed - stageTargetMinutes;
    return SlaStageResult(
      elapsedMinutes: elapsed,
      overdueMinutes: overdue,
      isFinished: false,
      isOverdue: true,
      label: 'SLA Terlambat: ${formatBusinessDuration(overdue)}',
    );
  }

  /// Menghasilkan label ringkas SLA untuk UI:
  /// "Sisa SLA: X", "SLA Terlambat: X", atau "Durasi: X".
  static String getOperationalSlaLabel(
    DateTime createdAt, [
    DateTime? completedAt,
  ]) {
    final res = evaluateStageSla(createdAt, completedAt);
    return res.label;
  }

  /// Evaluasi SLA spesifik per tahap aktif petugas:
  /// - Batas maksimal: 2 jam kerja (120 menit)
  /// - Dihitung hanya untuk tahap petugas yang sedang menunggu tindakan (Operator, Bagian Aset, Kadiv)
  /// - Waktu tunggu Pemohon (returned / waitingConfirmation) tidak dihitung sebagai SLA petugas
  /// - Menghasilkan label ringkas: 'Sisa SLA: X', 'SLA Terlambat: X', atau 'Durasi: X'
  static SlaStageResult evaluateMutationSla(
    dynamic mutation, {
    DateTime? now,
  }) {
    final dynamic rawStatus;
    final DateTime? createdAt;
    final DateTime? verifiedAt;
    final DateTime? approvedAt;
    final DateTime? assetVerifiedAt;
    final DateTime? kadivApprovedAt;
    final DateTime? kadivRejectedAt;

    if (mutation is Map) {
      rawStatus = mutation['status'];
      createdAt = mutation['createdAt'] as DateTime? ?? mutation['created_at'] as DateTime?;
      verifiedAt = mutation['verifiedAt'] as DateTime? ?? mutation['verified_at'] as DateTime?;
      approvedAt = mutation['approvedAt'] as DateTime? ?? mutation['approved_at'] as DateTime?;
      assetVerifiedAt = mutation['assetVerifiedAt'] as DateTime? ?? mutation['asset_verified_at'] as DateTime?;
      kadivApprovedAt = mutation['kadivApprovedAt'] as DateTime? ?? mutation['kadiv_approved_at'] as DateTime?;
      kadivRejectedAt = mutation['kadivRejectedAt'] as DateTime? ?? mutation['kadiv_rejected_at'] as DateTime?;
    } else {
      rawStatus = mutation.status;
      createdAt = mutation.createdAt as DateTime?;
      verifiedAt = mutation.verifiedAt as DateTime?;
      approvedAt = mutation.approvedAt as DateTime?;
      assetVerifiedAt = mutation.assetVerifiedAt as DateTime?;
      kadivApprovedAt = mutation.kadivApprovedAt as DateTime?;
      kadivRejectedAt = mutation.kadivRejectedAt as DateTime?;
    }

    final statusName = rawStatus is Enum ? rawStatus.name : rawStatus.toString();

    switch (statusName) {
      // 1. SLA tidak berjalan saat pengajuan masih diproses Operator
      case 'submitted':
        return const SlaStageResult(
          elapsedMinutes: 0,
          isFinished: false,
          isOverdue: false,
          isApplicantWaiting: false,
          slaActive: false,
          label: 'Dalam Pemeriksaan Operator',
        );

      // 2. SLA mulai berjalan tepat saat Operator berhasil meneruskan ke Bagian Aset
      // Menggunakan timestamp transisi status dari backend (verifiedAt)
      case 'waitingAssetVerification':
        final start = verifiedAt ?? createdAt ?? DateTime.now();
        final end = assetVerifiedAt;
        return evaluateStageSla(start, end, now);

      // 4. Setelah tahap Bagian Aset selesai dan diteruskan ke Kadiv:
      // Hentikan SLA Bagian Aset. Mulai SLA Kadiv dari timestamp transisi ke tahap Kadiv (approvedAt / assetVerifiedAt)
      case 'waitingDivisionHeadApproval':
      case 'waitingKadivApproval':
        final start = approvedAt ??
            assetVerifiedAt ??
            verifiedAt ??
            createdAt ??
            DateTime.now();
        final end = kadivApprovedAt ?? kadivRejectedAt;
        return evaluateStageSla(start, end, now);

      // 5. Waktu tunggu Pemohon tidak dihitung sebagai SLA petugas
      case 'returned':
      case 'waitingConfirmation':
      case 'pendingConfirmation':
        return const SlaStageResult(
          elapsedMinutes: 0,
          isFinished: false,
          isOverdue: false,
          isApplicantWaiting: true,
          slaActive: false,
          label: 'Menunggu Pemohon',
        );

      case 'completed':
      case 'rejected':
      default:
        final end = mutation.kadivApprovedAt ??
            mutation.kadivRejectedAt ??
            mutation.approvedAt ??
            mutation.assetVerifiedAt ??
            mutation.verifiedAt;
        return evaluateStageSla(mutation.createdAt, end, now);
    }
  }
}

/// Hasil evaluasi SLA per tahap petugas
class SlaStageResult {
  final int elapsedMinutes;
  final int? remainingMinutes;
  final int? overdueMinutes;
  final bool isFinished;
  final bool isOverdue;
  final bool isApplicantWaiting;
  final bool slaActive;
  final String label;

  const SlaStageResult({
    required this.elapsedMinutes,
    this.remainingMinutes,
    this.overdueMinutes,
    this.isFinished = false,
    this.isOverdue = false,
    this.isApplicantWaiting = false,
    this.slaActive = true,
    required this.label,
  });
}
