// test/features/mutation/history_category_and_tab_flow_test.dart
//
// Test suite komprehensif untuk Single Source of Truth History Pengajuan
// di SEMUA ROLE (Pemohon, Operator, Kadiv, Bagian Aset).

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mutasiku/features/asset/domain/entities/asset.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_category.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_status.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/operator/presentation/providers/operator_verification_provider.dart';
import 'package:mutasiku/features/bagian_aset/presentation/providers/bagian_aset_verification_provider.dart';
import 'package:mutasiku/features/kadiv/presentation/providers/kadiv_approval_provider.dart';
import 'package:mutasiku/features/mutation/presentation/providers/mutation_provider.dart';

void main() {
  group('1. Single Source of Truth: MutationStatus -> MutationHistoryCategory Mapping', () {
    test('Setiap status backend memetakan secara tepat ke kategori tab yang benar', () {
      // 1. Diproses
      expect(MutationStatus.submitted.historyCategory, MutationHistoryCategory.processing);
      expect(MutationStatus.waitingSync.historyCategory, MutationHistoryCategory.processing);

      // 2. Dialokasikan
      expect(MutationStatus.waitingAssetVerification.historyCategory, MutationHistoryCategory.allocated);
      expect(MutationStatus.verified.historyCategory, MutationHistoryCategory.allocated);
      expect(MutationStatus.waitingDivisionHeadApproval.historyCategory, MutationHistoryCategory.allocated);
      expect(MutationStatus.waitingKadivApproval.historyCategory, MutationHistoryCategory.allocated);
      expect(MutationStatus.waitingConfirmation.historyCategory, MutationHistoryCategory.allocated);
      expect(MutationStatus.approved.historyCategory, MutationHistoryCategory.allocated);
      expect(MutationStatus.pendingConfirmation.historyCategory, MutationHistoryCategory.allocated);

      // 3. Dikembalikan
      expect(MutationStatus.returned.historyCategory, MutationHistoryCategory.returned);

      // 4. Selesai
      expect(MutationStatus.completed.historyCategory, MutationHistoryCategory.completed);

      // 5. Ditolak
      expect(MutationStatus.rejected.historyCategory, MutationHistoryCategory.rejected);
    });

    test('Eksklusivitas tab: Satu status hanya pernah match tepat ke SATU tab spesifik', () {
      final allStatuses = MutationStatus.values;
      final specificCategories = [
        MutationHistoryCategory.processing,
        MutationHistoryCategory.allocated,
        MutationHistoryCategory.returned,
        MutationHistoryCategory.completed,
        MutationHistoryCategory.rejected,
      ];

      for (final status in allStatuses) {
        final matchingCategories = specificCategories.where((c) => c.matches(status)).toList();
        expect(
          matchingCategories.length,
          1,
          reason: 'Status $status harus match tepat ke 1 kategori spesifik',
        );
        // Dan selalu match dengan kategori All
        expect(MutationHistoryCategory.all.matches(status), isTrue);
      }
    });
  });

  group('2. Operator History Provider Filtering (Multi-Tab Single Truth)', () {
    final sampleAsset = Asset(
      id: 'ast-1',
      assetCode: 'TI-LAP-001',
      name: 'ThinkPad T14',
      category: const AssetCategory(id: 'cat-ti', code: 'TI', name: 'Aset TI'),
      location: 'Divisi TI',
      pic: 'Dirly',
      status: AssetStatus.inMutation,
      condition: 'Baik',
      acquisitionYear: 2024,
    );

    Mutation createMutation(String id, MutationStatus status) {
      return Mutation(
        id: id,
        ticketNumber: 'MUT-$id',
        applicantName: 'Pemohon $id',
        currentLocation: 'Divisi Lama',
        targetLocation: 'Divisi Baru',
        currentPic: 'PIC Lama',
        targetPic: 'PIC Baru',
        reason: 'Alasan mutasi',
        status: status,
        createdAt: DateTime(2026, 1, 1),
        asset: sampleAsset,
      );
    }

    test('OperatorStatusFilter memfilter mutasi secara eksklusif dan konsisten', () async {
      final mutations = [
        createMutation('1', MutationStatus.submitted),
        createMutation('2', MutationStatus.waitingAssetVerification),
        createMutation('3', MutationStatus.waitingDivisionHeadApproval),
        createMutation('4', MutationStatus.waitingConfirmation),
        createMutation('5', MutationStatus.returned),
        createMutation('6', MutationStatus.completed),
        createMutation('7', MutationStatus.rejected),
      ];

      final container = ProviderContainer(
        overrides: [
          operatorAllMutationsProvider.overrideWith(
            (ref) => Future.value(mutations),
          ),
        ],
      );

      // Pastikan future selesai dimuat
      await container.read(operatorAllMutationsProvider.future);

      // Tab: submitted / Menunggu
      container.read(operatorStatusFilterProvider.notifier).state =
          OperatorStatusFilter.submitted;
      var filtered = container.read(filteredIncomingMutationsProvider).valueOrNull!;
      expect(filtered.map((m) => m.id), ['1']);

      // Tab: allocated / Dialokasikan
      container.read(operatorStatusFilterProvider.notifier).state =
          OperatorStatusFilter.allocated;
      filtered = container.read(filteredIncomingMutationsProvider).valueOrNull!;
      expect(filtered.map((m) => m.id), ['2', '3', '4']);

      // Tab: returned / Dikembalikan
      container.read(operatorStatusFilterProvider.notifier).state =
          OperatorStatusFilter.returned;
      filtered = container.read(filteredIncomingMutationsProvider).valueOrNull!;
      expect(filtered.map((m) => m.id), ['5']);

      // Tab: completed / Selesai
      container.read(operatorStatusFilterProvider.notifier).state =
          OperatorStatusFilter.completed;
      filtered = container.read(filteredIncomingMutationsProvider).valueOrNull!;
      expect(filtered.map((m) => m.id), ['6']);

      // Tab: rejected / Ditolak
      container.read(operatorStatusFilterProvider.notifier).state =
          OperatorStatusFilter.rejected;
      filtered = container.read(filteredIncomingMutationsProvider).valueOrNull!;
      expect(filtered.map((m) => m.id), ['7']);

      // Tab: all / Semua
      container.read(operatorStatusFilterProvider.notifier).state =
          OperatorStatusFilter.all;
      filtered = container.read(filteredIncomingMutationsProvider).valueOrNull!;
      expect(filtered.length, 7);
    });
  });

  group('3. Cross-Role Invalidation saat Perubahan Status', () {
    test('invalidateAllRoleMutationProviders me-refresh semua provider antar role', () {
      var pemohonRefreshed = 0;
      var operatorRefreshed = 0;

      final container = ProviderContainer(
        overrides: [
          mutationListProvider.overrideWith((ref) {
            pemohonRefreshed++;
            return Future.value([]);
          }),
          operatorAllMutationsProvider.overrideWith((ref) {
            operatorRefreshed++;
            return Future.value([]);
          }),
        ],
      );

      // Baca awal
      container.read(mutationListProvider);
      container.read(operatorAllMutationsProvider);
      expect(pemohonRefreshed, 1);
      expect(operatorRefreshed, 1);

      // Panggil invalidateAllRoleMutationProviders
      invalidateAllRoleMutationProviders(container, 'mut-123');

      // Baca ulang
      container.read(mutationListProvider);
      container.read(operatorAllMutationsProvider);
      expect(pemohonRefreshed, 2);
      expect(operatorRefreshed, 2);
    });
  });

  group('4. Skenario Transisi Status ke Tab History yang Tepat', () {
    test('status -> Diproses -> tab Diproses', () {
      final status = MutationStatus.submitted;
      expect(MutationHistoryCategory.processing.matches(status), isTrue);
      expect(MutationHistoryCategory.allocated.matches(status), isFalse);
      expect(MutationHistoryCategory.returned.matches(status), isFalse);
      expect(MutationHistoryCategory.completed.matches(status), isFalse);
      expect(MutationHistoryCategory.rejected.matches(status), isFalse);
    });

    test('status -> Dialokasikan -> tab Dialokasikan', () {
      // Saat diteruskan oleh Operator ke Bagian Aset atau Kadiv
      final statuses = [
        MutationStatus.waitingAssetVerification,
        MutationStatus.waitingDivisionHeadApproval,
        MutationStatus.waitingConfirmation,
      ];
      for (final s in statuses) {
        expect(MutationHistoryCategory.allocated.matches(s), isTrue,
            reason: '$s harus berada di tab Dialokasikan');
        expect(MutationHistoryCategory.processing.matches(s), isFalse);
        expect(MutationHistoryCategory.returned.matches(s), isFalse);
        expect(MutationHistoryCategory.completed.matches(s), isFalse);
        expect(MutationHistoryCategory.rejected.matches(s), isFalse);
      }
    });

    test('status -> Dikembalikan -> tab Dikembalikan', () {
      final status = MutationStatus.returned;
      expect(MutationHistoryCategory.returned.matches(status), isTrue);
      expect(MutationHistoryCategory.processing.matches(status), isFalse);
      expect(MutationHistoryCategory.allocated.matches(status), isFalse);
      expect(MutationHistoryCategory.completed.matches(status), isFalse);
      expect(MutationHistoryCategory.rejected.matches(status), isFalse);
    });

    test('status -> Selesai -> tab Selesai', () {
      final status = MutationStatus.completed;
      expect(MutationHistoryCategory.completed.matches(status), isTrue);
      expect(MutationHistoryCategory.processing.matches(status), isFalse);
      expect(MutationHistoryCategory.allocated.matches(status), isFalse);
      expect(MutationHistoryCategory.returned.matches(status), isFalse);
      expect(MutationHistoryCategory.rejected.matches(status), isFalse);
    });

    test('status -> Ditolak -> tab Ditolak', () {
      final status = MutationStatus.rejected;
      expect(MutationHistoryCategory.rejected.matches(status), isTrue);
      expect(MutationHistoryCategory.processing.matches(status), isFalse);
      expect(MutationHistoryCategory.allocated.matches(status), isFalse);
      expect(MutationHistoryCategory.returned.matches(status), isFalse);
      expect(MutationHistoryCategory.completed.matches(status), isFalse);
    });
  });

  group('4. Bagian Aset Status Filter (Single Source of Truth)', () {
    test('BagianAsetStatusFilter mencakup semua 5 status history dan konsisten', () {
      expect(BagianAsetStatusFilter.all.displayName, 'Semua');
      expect(BagianAsetStatusFilter.processing.displayName, 'Diproses');
      expect(BagianAsetStatusFilter.allocated.displayName, 'Dialokasikan');
      expect(BagianAsetStatusFilter.returned.displayName, 'Dikembalikan');
      expect(BagianAsetStatusFilter.completed.displayName, 'Selesai');
      expect(BagianAsetStatusFilter.rejected.displayName, 'Ditolak');
    });
  });

  group('5. Kadiv Status Filter (Single Source of Truth)', () {
    test('KadivStatusFilter mencakup semua 5 status history dan konsisten', () {
      expect(KadivStatusFilter.all.displayName, 'Semua');
      expect(KadivStatusFilter.processing.displayName, 'Diproses');
      expect(KadivStatusFilter.allocated.displayName, 'Dialokasikan');
      expect(KadivStatusFilter.returned.displayName, 'Dikembalikan');
      expect(KadivStatusFilter.completed.displayName, 'Selesai');
      expect(KadivStatusFilter.rejected.displayName, 'Ditolak');
    });
  });
}

