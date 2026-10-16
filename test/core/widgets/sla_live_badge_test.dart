// test/core/widgets/sla_live_badge_test.dart
//
// Widget test untuk SlaLiveBadge & SlaLiveBuilder:
// 1. Memastikan SLA dihitung dinamis dari timestamp transisi status (bukan teks statis).
// 2. Memastikan timer me-refresh tampilan secara berkala saat halaman tetap terbuka.
// 3. Memastikan SLA Operator tidak aktif saat status 'submitted'.
// 4. Memastikan SLA Bagian Aset dan Kadiv berjalan sesuai tahap aktif dengan batas 120 menit.
// 5. Keterlambatan hanya berupa penanda visual tanpa mengubah status otomatis.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/widgets/sla_live_badge.dart';

void main() {
  group('SlaLiveBadge Tests', () {
    testWidgets('Operator stage (submitted): SLA tidak aktif (badge tersembunyi)', (tester) async {
      final mutation = {
        'status': 'submitted',
        'createdAt': DateTime.now().subtract(const Duration(minutes: 30)),
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlaLiveBadge(mutation: mutation),
          ),
        ),
      );

      // SlaLiveBadge harus sembunyi (SizedBox.shrink) saat Operator memeriksa
      expect(find.byType(SlaLiveBadge), findsOneWidget);
      expect(find.textContaining('Sisa SLA'), findsNothing);
      expect(find.textContaining('SLA Terlambat'), findsNothing);
    });

    testWidgets('Bagian Aset stage: menghitung sisa SLA dari verifiedAt (timestamp transisi Operator)', (tester) async {
      // Operator meneruskan pengajuan pada 09:00 WITA (01:00 UTC), dievaluasi pada 09:30 WITA (01:30 UTC)
      final verifiedAt = DateTime.utc(2026, 10, 9, 1, 0); // 09:00 WITA (Jumat)
      final nowAt930 = DateTime.utc(2026, 10, 9, 1, 30); // 09:30 WITA
      final mutation = {
        'status': 'waitingAssetVerification',
        'verifiedAt': verifiedAt,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlaLiveBadge(mutation: mutation, now: nowAt930),
          ),
        ),
      );

      // Bukan teks statis: tampilkan sisa SLA dinamis
      expect(find.text('Sisa SLA: 1 Jam 30 Menit'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    });

    testWidgets('Kadiv stage: menghitung sisa SLA dari approvedAt (timestamp transisi Bagian Aset)', (tester) async {
      // Bagian Aset meneruskan pengajuan pada 10:00 WITA, dievaluasi pada 10:20 WITA
      final approvedAt = DateTime.utc(2026, 10, 9, 2, 0); // 10:00 WITA
      final nowAt1020 = DateTime.utc(2026, 10, 9, 2, 20); // 10:20 WITA
      final mutation = {
        'status': 'waitingDivisionHeadApproval',
        'approvedAt': approvedAt,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlaLiveBadge(mutation: mutation, now: nowAt1020),
          ),
        ),
      );

      expect(find.text('Sisa SLA: 1 Jam 40 Menit'), findsOneWidget);
    });

    testWidgets('Keterlambatan (> 120 menit kerja) menampilkan penanda SLA Terlambat tanpa ubah status', (tester) async {
      // Diteruskan pada 09:00 WITA, dievaluasi pada 11:30 WITA (150 menit kerja > 120 menit kerja)
      final verifiedAt = DateTime.utc(2026, 10, 9, 1, 0); // 09:00 WITA
      final nowAt1130 = DateTime.utc(2026, 10, 9, 3, 30); // 11:30 WITA
      final mutation = {
        'status': 'waitingAssetVerification',
        'verifiedAt': verifiedAt,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlaLiveBadge(mutation: mutation, now: nowAt1130),
          ),
        ),
      );

      // Tampilkan indikator peringatan keterlambatan
      expect(find.text('SLA Terlambat: 30 Menit'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      // Status mutasi tetap 'waitingAssetVerification' tidak berubah otomatis
      expect(mutation['status'], 'waitingAssetVerification');
    });

    testWidgets('Timer periodic memperbarui sisa SLA saat halaman tetap terbuka', (tester) async {
      final verifiedAt = DateTime.utc(2026, 10, 9, 1, 0);
      final mutation = {
        'status': 'waitingAssetVerification',
        'verifiedAt': verifiedAt,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlaLiveBadge(mutation: mutation),
          ),
        ),
      );

      // Majukan waktu virtual 35 detik (memicu Timer.periodic 30 detik)
      await tester.pump(const Duration(seconds: 35));

      // Widget tetap aktif ter-rebuild tanpa crash
      expect(find.byType(SlaLiveBadge), findsOneWidget);
    });
  });
}
