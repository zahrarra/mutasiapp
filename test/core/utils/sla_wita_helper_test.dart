import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/utils/sla_wita_helper.dart';

void main() {
  group('SlaWitaHelper Tests', () {
    test('toWita converts UTC to WITA (UTC+8)', () {
      final utc = DateTime.utc(2026, 10, 9, 3, 30); // 03:30 UTC
      final wita = SlaWitaHelper.toWita(utc);

      expect(wita.hour, 11);
      expect(wita.minute, 30);
    });

    test('formatDateTimeWita formats with WITA suffix', () {
      final utc = DateTime.utc(2026, 10, 9, 6, 15); // 14:15 WITA
      final formatted = SlaWitaHelper.formatDateTimeWita(utc);

      expect(formatted, contains('09 Okt 2026'));
      expect(formatted, contains('14:15 WITA'));
    });

    test('calculateBusinessMinutes counts only Monday-Friday 08:00-17:00 WITA', () {
      // Jumat, 09 Okt 2026 09:00 WITA (01:00 UTC) s/d 12:00 WITA (04:00 UTC) = 3 jam = 180 menit
      final start = DateTime.utc(2026, 10, 9, 1, 0);
      final end = DateTime.utc(2026, 10, 9, 4, 0);

      final minutes = SlaWitaHelper.calculateBusinessMinutes(start, end);
      expect(minutes, 180);
      expect(SlaWitaHelper.formatBusinessDuration(minutes), '3 Jam');
    });

    test('calculateBusinessMinutes skips weekend and after-hours', () {
      // Jumat 16:00 WITA (08:00 UTC) s/d Senin 10:00 WITA (02:00 UTC)
      // Jumat 16:00 - 17:00 = 60 menit
      // Sabtu & Minggu = 0 menit
      // Senin 08:00 - 10:00 = 120 menit
      // Total = 180 menit (3 Jam)
      final start = DateTime.utc(2026, 10, 9, 8, 0);
      final end = DateTime.utc(2026, 10, 12, 2, 0);

      final minutes = SlaWitaHelper.calculateBusinessMinutes(start, end);
      expect(minutes, 180);
    });

    test('evaluateStageSla handles remaining, overdue, and finished stages with 2-hour limit', () {
      final start = DateTime.utc(2026, 10, 9, 1, 0); // 09:00 WITA (Jumat)

      // Berjalan 30 menit (stageEnd = null, now = 09:30 WITA) -> Sisa 90 menit (1 Jam 30 Menit)
      final nowRunning30 = DateTime.utc(2026, 10, 9, 1, 30); // 09:30 WITA
      final resultRunning = SlaWitaHelper.evaluateStageSla(start, null, nowRunning30);
      expect(resultRunning.isFinished, false);
      expect(resultRunning.isOverdue, false);
      expect(resultRunning.remainingMinutes, 90);
      expect(resultRunning.label, 'Sisa SLA: 1 Jam 30 Menit');

      // Selesai dalam 45 menit -> Durasi: 45 Menit
      final endFinished = DateTime.utc(2026, 10, 9, 1, 45); // 09:45 WITA
      final resultFinished = SlaWitaHelper.evaluateStageSla(start, endFinished);
      expect(resultFinished.isFinished, true);
      expect(resultFinished.label, 'Durasi: 45 Menit');

      // Berjalan 150 menit (lewat batas 120 menit) -> SLA Terlambat: 30 Menit
      final nowOverdue = DateTime.utc(2026, 10, 9, 3, 30); // 11:30 WITA
      final resOverdue = SlaWitaHelper.evaluateStageSla(start, null, nowOverdue);
      expect(resOverdue.elapsedMinutes, 150);
      expect(resOverdue.isFinished, false);
      expect(resOverdue.isOverdue, true);
      expect(resOverdue.overdueMinutes, 30);
      expect(resOverdue.label, 'SLA Terlambat: 30 Menit');
    });

    test('evaluateMutationSla respects rules: Operator no SLA, Bagian Aset starts from verifiedAt, Kadiv starts from approvedAt', () {
      final createdAt = DateTime.utc(2026, 10, 9, 0, 30); // 08:30 WITA
      final verifiedAt = DateTime.utc(2026, 10, 9, 1, 0); // 09:00 WITA (Operator forward ke Bagian Aset)
      final approvedAt = DateTime.utc(2026, 10, 9, 2, 30); // 10:30 WITA (Bagian Aset forward ke Kadiv)

      // 1. Operator stage (submitted): SLA TIDAK BERJALAN
      final mockOperatorMutation = {
        'status': 'submitted',
        'createdAt': createdAt,
      };
      final resOperator = SlaWitaHelper.evaluateMutationSla(mockOperatorMutation);
      expect(resOperator.slaActive, false);
      expect(resOperator.isOverdue, false);
      expect(resOperator.label, 'Dalam Pemeriksaan Operator');

      // 2. Bagian Aset stage (waitingAssetVerification):
      // SLA mulai tepat dari timestamp Operator meneruskan (verifiedAt = 09:00 WITA)
      final mockAssetMutation = {
        'status': 'waitingAssetVerification',
        'createdAt': createdAt,
        'verifiedAt': verifiedAt,
      };
      // Pada 10:00 WITA (02:00 UTC) -> berjalan 60 menit, sisa 60 menit (1 Jam)
      final nowAt10 = DateTime.utc(2026, 10, 9, 2, 0);
      final resAsset = SlaWitaHelper.evaluateMutationSla(mockAssetMutation, now: nowAt10);
      expect(resAsset.slaActive, true);
      expect(resAsset.elapsedMinutes, 60);
      expect(resAsset.remainingMinutes, 60);
      expect(resAsset.label, 'Sisa SLA: 1 Jam');
      expect(resAsset.isOverdue, false);

      // Pada 11:30 WITA (03:30 UTC) -> berjalan 150 menit (> 120 menit) -> Terlambat 30 Menit
      final nowAt1130 = DateTime.utc(2026, 10, 9, 3, 30);
      final resAssetOverdue = SlaWitaHelper.evaluateMutationSla(mockAssetMutation, now: nowAt1130);
      expect(resAssetOverdue.isOverdue, true);
      expect(resAssetOverdue.overdueMinutes, 30);
      expect(resAssetOverdue.label, 'SLA Terlambat: 30 Menit');

      // 3. Kadiv stage (waitingDivisionHeadApproval):
      // SLA Bagian Aset berhenti. SLA Kadiv mulai tepat saat Bagian Aset meneruskan (approvedAt = 10:30 WITA)
      final mockKadivMutation = {
        'status': 'waitingDivisionHeadApproval',
        'createdAt': createdAt,
        'verifiedAt': verifiedAt,
        'approvedAt': approvedAt,
      };
      // Pada 11:15 WITA (03:15 UTC) -> berjalan 45 menit untuk Kadiv, sisa 75 menit (1 Jam 15 Menit)
      final nowAt1115 = DateTime.utc(2026, 10, 9, 3, 15);
      final resKadiv = SlaWitaHelper.evaluateMutationSla(mockKadivMutation, now: nowAt1115);
      expect(resKadiv.slaActive, true);
      expect(resKadiv.elapsedMinutes, 45);
      expect(resKadiv.remainingMinutes, 75);
      expect(resKadiv.label, 'Sisa SLA: 1 Jam 15 Menit');
      expect(resKadiv.isOverdue, false);

      // 4. Pemohon stage (waitingConfirmation / returned):
      // Waktu tunggu Pemohon tidak dihitung sebagai SLA petugas
      final mockPemohonMutation = {
        'status': 'waitingConfirmation',
        'createdAt': createdAt,
      };
      final resPemohon = SlaWitaHelper.evaluateMutationSla(mockPemohonMutation);
      expect(resPemohon.slaActive, false);
      expect(resPemohon.isApplicantWaiting, true);
      expect(resPemohon.label, 'Menunggu Pemohon');
    });
  });
}
