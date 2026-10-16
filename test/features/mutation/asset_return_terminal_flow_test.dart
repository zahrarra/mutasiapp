// test/features/mutation/asset_return_terminal_flow_test.dart
//
// Pengujian Regresi Lengkap: Alur Penolakan/Pengembalian Bagian Aset — Langsung Selesai.
// Memverifikasi status terminal, timeline terhenti di Bagian Aset, kategori Selesai di Pemohon,
// ketiadaan aksi edit/resubmit, dan tampilan notifikasi/riwayat.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/features/asset/domain/entities/asset.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_category.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_status.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/presentation/models/mutation_tracking_step.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';
import 'package:mutasiku/features/pemohon/presentation/screens/pemohon_mutation_detail_screen.dart';
import 'package:mutasiku/features/pemohon/presentation/widgets/pemohon_mutation_card.dart';

void main() {
  final testAsset = Asset(
    id: 'asset_01',
    assetCode: 'AST-KTR-001',
    name: 'MacBook Pro M2',
    category: const AssetCategory(id: 'cat_01', name: 'TI', code: 'TI'),
    location: 'Ruang IT',
    pic: 'Rizal Pemohon',
    status: AssetStatus.inMutation,
    condition: 'Baik',
    acquisitionYear: 2024,
    estimatedValue: 20000000,
  );

  final returnedMutation = Mutation(
    id: 'mut_ret_99',
    ticketNumber: 'MUT-RET-2026-0099',
    asset: testAsset,
    applicantId: 'usr_pemohon_01',
    applicantName: 'Rizal Pemohon',
    currentLocation: 'Ruang IT',
    targetLocation: 'Cabang Palu',
    currentPic: 'Rizal Pemohon',
    targetPic: 'Budi Penerima',
    reason: 'Pindah penugasan',
    status: MutationStatus.returned,
    returnReason: 'Fisik aset tidak sesuai spesifikasi permohonan',
    assetReturnReason: 'Fisik aset tidak sesuai spesifikasi permohonan',
    verifiedBy: 'Operator Sahrul',
    assetVerifiedBy: 'Hendra Aset',
    createdAt: DateTime(2026, 3, 10, 10, 30),
  );

  group('Alur Penolakan Bagian Aset — Timeline & Tracking Tests', () {
    test('1 & 7 & 8. Timeline stops at Bagian Aset with alert & Dikembalikan badge without looping back', () {
      final steps = MutationTrackingHelper.getStepsForMutation(
        MutationStatus.returned,
        mutation: returnedMutation,
      );

      // Timeline harus tepat 3 tahap (Pengajuan -> Operator -> Bagian Aset)
      expect(steps.length, 3);

      // Tahap 1: Pengajuan (Selesai)
      expect(steps[0].key, 'submitted');
      expect(steps[0].state, TrackingStepState.completed);
      expect(steps[0].badgeText, 'Selesai');

      // Tahap 2: Pemeriksaan Operator (Lengkap)
      expect(steps[1].key, 'operatorCheck');
      expect(steps[1].state, TrackingStepState.completed);
      expect(steps[1].badgeText, 'Lengkap');

      // Tahap 3: Verifikasi Bagian Aset (Dikembalikan / Terminal)
      expect(steps[2].key, 'assetVerification');
      expect(steps[2].state, TrackingStepState.alert);
      expect(steps[2].badgeText, 'Dikembalikan');
      expect(steps[2].title, contains('Verifikasi Bagian Aset'));
      expect(
        steps[2].subtitle,
        contains('Dikembalikan oleh Bagian Aset: Fisik aset tidak sesuai spesifikasi permohonan — pengajuan telah selesai.'),
      );

      // Tidak ada tahap persetujuan Kadiv, Konfirmasi, atau Update
      expect(steps.any((s) => s.key == 'divisionApproval'), isFalse);
      expect(steps.any((s) => s.key == 'confirmation'), isFalse);
      expect(steps.any((s) => s.key == 'completed'), isFalse);

      // Indikator nomor tahap aktif menunjukkan tahap 3
      expect(MutationTrackingHelper.getActiveStageNumber(steps), 3);
    });
  });

  group('Alur Penolakan Bagian Aset — Pemohon Card & Detail Widgets', () {
    testWidgets('4 & 5. Pemohon Mutation Card displays Dikembalikan and Pengajuan Berakhir without edit/resubmit', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PemohonMutationCard(
              mutation: returnedMutation,
            ),
          ),
        ),
      );

      // Label badge status
      expect(find.text('Dikembalikan'), findsOneWidget);
      // Status pengajuan berakhir
      expect(find.text('Pengajuan Berakhir'), findsOneWidget);
      // Alasan pengembalian
      expect(find.text('Fisik aset tidak sesuai spesifikasi permohonan'), findsOneWidget);

      // Tidak boleh ada tombol edit ulang, perbaiki, atau resubmit
      expect(find.text('Perbaiki'), findsNothing);
      expect(find.text('Edit & Ajukan Ulang'), findsNothing);
      expect(find.text('Konfirmasi Diterima'), findsNothing);
    });

    testWidgets('6 & 9. Detail screen displays clear banner showing mutation returned by Bagian Aset and completed', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mutationDetailProvider(returnedMutation.id).overrideWith(
              (ref) => Future.value(returnedMutation),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PemohonMutationDetailScreen(
                mutationId: returnedMutation.id,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Banner menyatakan proses telah selesai
      expect(
        find.text('Dikembalikan oleh Bagian Aset — Pengajuan Telah Selesai'),
        findsOneWidget,
      );
      expect(find.text('Oleh: Bagian Aset'), findsOneWidget);
      expect(find.text('Fisik aset tidak sesuai spesifikasi permohonan'), findsOneWidget);
      expect(
        find.text('Pengajuan ini tidak diterima dan tiket telah ditutup. Tiket ini tidak dapat diedit atau diajukan ulang. Jika masih diperlukan, silakan buat pengajuan mutasi baru.'),
        findsOneWidget,
      );

      // Tombol Ajukan Mutasi Baru tersedia, sedangkan Edit/Resubmit tidak ada
      expect(find.byKey(const Key('btn_ajukan_mutasi_baru')), findsOneWidget);
      expect(find.text('Edit & Ajukan Ulang'), findsNothing);
      expect(find.text('Perbaiki Berkas'), findsNothing);
    });
  });

  group('Alur Penolakan Bagian Aset vs Kadiv — Timeline & Card Differentiation', () {
    final assetRejectedMutation = Mutation(
      id: 'mut_rej_asset_01',
      ticketNumber: 'MUT-REJ-2026-0001',
      asset: testAsset,
      applicantId: 'usr_pemohon_01',
      applicantName: 'Rizal Pemohon',
      currentLocation: 'Ruang IT',
      targetLocation: 'Cabang Palu',
      currentPic: 'Rizal Pemohon',
      targetPic: 'Budi Penerima',
      reason: 'Pindah penugasan',
      status: MutationStatus.rejected,
      rejectionReason: 'Aset rusak berat dan tidak layak dimutasi',
      verifiedBy: 'Operator Sahrul',
      assetRejectedBy: 'Hendra Bagian Aset',
      rejectedBy: 'Hendra Bagian Aset',
      createdAt: DateTime(2026, 3, 10, 10, 30),
    );

    final kadivRejectedMutation = Mutation(
      id: 'mut_rej_kadiv_01',
      ticketNumber: 'MUT-REJ-2026-0002',
      asset: testAsset,
      applicantId: 'usr_pemohon_01',
      applicantName: 'Rizal Pemohon',
      currentLocation: 'Ruang IT',
      targetLocation: 'Cabang Palu',
      currentPic: 'Rizal Pemohon',
      targetPic: 'Budi Penerima',
      reason: 'Pindah penugasan',
      status: MutationStatus.rejected,
      rejectionReason: 'Aset masih dibutuhkan di divisi asal',
      kadivRejectionReason: 'Aset masih dibutuhkan di divisi asal',
      verifiedBy: 'Operator Sahrul',
      assetVerifiedBy: 'Hendra Bagian Aset',
      kadivRejectedBy: 'Drs. Ahmad Dahlan (Kadiv)',
      rejectedBy: 'Drs. Ahmad Dahlan (Kadiv)',
      createdAt: DateTime(2026, 3, 10, 10, 30),
    );

    test('Penolakan Bagian Aset mengakhiri alur di tahap 3 tanpa diteruskan ke Kadiv', () {
      expect(assetRejectedMutation.isAssetRejected, isTrue);
      expect(assetRejectedMutation.isKadivRejected, isFalse);

      final steps = MutationTrackingHelper.getStepsForMutation(
        MutationStatus.rejected,
        mutation: assetRejectedMutation,
      );

      // Tepat 3 tahap
      expect(steps.length, 3);
      expect(steps[0].key, 'submitted');
      expect(steps[1].key, 'operatorCheck');
      expect(steps[2].key, 'assetVerification');
      expect(steps[2].state, TrackingStepState.alert);
      expect(steps[2].badgeText, 'Ditolak');
      expect(steps[2].subtitle, contains('Ditolak oleh Hendra Bagian Aset: Aset rusak berat dan tidak layak dimutasi'));

      // Kadiv approval tidak ada di timeline
      expect(steps.any((s) => s.key == 'divisionApproval'), isFalse);
      expect(MutationTrackingHelper.getActiveStageNumber(steps), 3);
    });

    test('Penolakan Kadiv mengakhiri alur di tahap 4 (Kadiv) tanpa lanjut ke Pemohon/Selesai', () {
      expect(kadivRejectedMutation.isAssetRejected, isFalse);
      expect(kadivRejectedMutation.isKadivRejected, isTrue);

      final steps = MutationTrackingHelper.getStepsForMutation(
        MutationStatus.rejected,
        mutation: kadivRejectedMutation,
      );

      // Tepat 4 tahap
      expect(steps.length, 4);
      expect(steps[0].key, 'submitted');
      expect(steps[1].key, 'operatorCheck');
      expect(steps[2].key, 'assetVerification');
      expect(steps[2].state, TrackingStepState.completed);
      expect(steps[2].badgeText, 'Valid');

      expect(steps[3].key, 'divisionApproval');
      expect(steps[3].state, TrackingStepState.alert);
      expect(steps[3].badgeText, 'Ditolak');
      expect(steps[3].subtitle, contains('Ditolak oleh Drs. Ahmad Dahlan (Kadiv): Aset masih dibutuhkan di divisi asal'));

      // Konfirmasi dan selesai tidak ada
      expect(steps.any((s) => s.key == 'confirmation'), isFalse);
      expect(steps.any((s) => s.key == 'completed'), isFalse);
      expect(MutationTrackingHelper.getActiveStageNumber(steps), 4);
    });

    testWidgets('Kartu Pemohon membedakan penolakan Bagian Aset dengan jelas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PemohonMutationCard(mutation: assetRejectedMutation),
          ),
        ),
      );

      expect(find.text('Ditolak Bagian Aset'), findsOneWidget);
      expect(find.text('Berakhir di Bagian Aset'), findsOneWidget);
      expect(find.text('Ditolak Bagian Aset: Aset rusak berat dan tidak layak dimutasi'), findsOneWidget);
    });

    testWidgets('Kartu Pemohon membedakan penolakan Kadiv dengan jelas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PemohonMutationCard(mutation: kadivRejectedMutation),
          ),
        ),
      );

      expect(find.text('Ditolak Pemimpin Divisi'), findsOneWidget);
      expect(find.text('Berakhir di Kadiv'), findsOneWidget);
      expect(find.text('Ditolak Kadiv: Aset masih dibutuhkan di divisi asal'), findsOneWidget);
    });
  });
}
