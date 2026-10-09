// test/features/mutation/all_roles_ui_and_flow_verification_test.dart
//
// Final verification test suite:
// 1. Pemohon: Diproses -> Dialokasikan -> Dikembalikan -> Selesai/Ditolak
// 2. Operator: Tab status + Aset TI/Umum
// 3. Bagian Aset: Tab/filter status + no leftover in old tab
// 4. KADIV: Tab/filter status + no leftover in old tab
// 5. Invalidation/refresh persistence across all roles

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

Mutation _createTestMutation({
  required String id,
  required String ticketNumber,
  required MutationStatus status,
  required String assetName,
  required String categoryName,
  required String categoryCode,
}) {
  return Mutation(
    id: id,
    ticketNumber: ticketNumber,
    applicantName: 'Pemohon Test',
    currentLocation: 'Ruang A',
    targetLocation: 'Ruang B',
    currentPic: 'PIC A',
    targetPic: 'PIC B',
    reason: 'Keperluan operasional',
    status: status,
    createdAt: DateTime(2026, 3, 1),
    asset: Asset(
      id: 'asset-$id',
      assetCode: 'AST-$id',
      name: assetName,
      category: AssetCategory(
        id: 'cat-$id',
        name: categoryName,
        code: categoryCode,
      ),
      location: 'Gedung A Lantai 1',
      pic: 'PIC Lama',
      status: AssetStatus.inMutation,
      condition: 'Baik',
      acquisitionYear: 2024,
    ),
  );
}

void main() {
  group('FINAL VERIFICATION - PEMOHON FLOW: Diproses -> Dialokasikan -> Dikembalikan -> Selesai/Ditolak', () {
    test('Pengajuan berpindah tab secara tepat tanpa duplikasi antar tab', () {
      // 1. Initial State: Diproses (submitted)
      var mutation = _createTestMutation(
        id: 'mut-1',
        ticketNumber: 'MUT-001',
        status: MutationStatus.submitted,
        assetName: 'Laptop Dell XPS',
        categoryName: 'Teknologi Informasi',
        categoryCode: 'TI',
      );

      expect(MutationHistoryCategory.processing.matches(mutation.status), isTrue);
      expect(MutationHistoryCategory.allocated.matches(mutation.status), isFalse);
      expect(MutationHistoryCategory.returned.matches(mutation.status), isFalse);
      expect(MutationHistoryCategory.completed.matches(mutation.status), isFalse);
      expect(MutationHistoryCategory.rejected.matches(mutation.status), isFalse);

      // 2. Transition: Dialokasikan (waitingAssetVerification / waitingDivisionHeadApproval / waitingConfirmation)
      mutation = mutation.copyWith(status: MutationStatus.waitingAssetVerification);
      expect(MutationHistoryCategory.processing.matches(mutation.status), isFalse,
          reason: 'Tidak boleh lagi muncul di tab Diproses');
      expect(MutationHistoryCategory.allocated.matches(mutation.status), isTrue,
          reason: 'Harus berpindah ke tab Dialokasikan');
      expect(MutationHistoryCategory.returned.matches(mutation.status), isFalse);
      expect(MutationHistoryCategory.completed.matches(mutation.status), isFalse);

      mutation = mutation.copyWith(status: MutationStatus.waitingDivisionHeadApproval);
      expect(MutationHistoryCategory.allocated.matches(mutation.status), isTrue);

      mutation = mutation.copyWith(status: MutationStatus.waitingConfirmation);
      expect(MutationHistoryCategory.allocated.matches(mutation.status), isTrue);

      // 3. Transition: Dikembalikan (returned)
      mutation = mutation.copyWith(status: MutationStatus.returned);
      expect(MutationHistoryCategory.allocated.matches(mutation.status), isFalse,
          reason: 'Tidak boleh lagi muncul di tab Dialokasikan');
      expect(MutationHistoryCategory.processing.matches(mutation.status), isFalse);
      expect(MutationHistoryCategory.returned.matches(mutation.status), isTrue,
          reason: 'Harus berpindah ke tab Dikembalikan');
      expect(MutationHistoryCategory.completed.matches(mutation.status), isFalse);

      // 4a. Transition: Selesai (completed)
      var completedMutation = mutation.copyWith(status: MutationStatus.completed);
      expect(MutationHistoryCategory.returned.matches(completedMutation.status), isFalse);
      expect(MutationHistoryCategory.completed.matches(completedMutation.status), isTrue,
          reason: 'Harus berpindah ke tab Selesai');
      expect(MutationHistoryCategory.rejected.matches(completedMutation.status), isFalse);

      // 4b. Transition: Ditolak (rejected)
      var rejectedMutation = mutation.copyWith(status: MutationStatus.rejected);
      expect(MutationHistoryCategory.returned.matches(rejectedMutation.status), isFalse);
      expect(MutationHistoryCategory.rejected.matches(rejectedMutation.status), isTrue,
          reason: 'Harus berpindah ke tab Ditolak');
      expect(MutationHistoryCategory.completed.matches(rejectedMutation.status), isFalse);
    });
  });

  group('FINAL VERIFICATION - OPERATOR: Tab Status + Aset TI/Umum', () {
    test('Filter tab status dan filter kategori TI/Umum bekerja independen dan konsisten', () async {
      final mTiSubmitted = _createTestMutation(
        id: '1',
        ticketNumber: 'MUT-TI-1',
        status: MutationStatus.submitted,
        assetName: 'Laptop Asus ROG',
        categoryName: 'Teknologi Informasi',
        categoryCode: 'TI',
      );
      final mUmumAllocated = _createTestMutation(
        id: '2',
        ticketNumber: 'MUT-UMUM-2',
        status: MutationStatus.waitingAssetVerification,
        assetName: 'Meja Kantor Kayu',
        categoryName: 'Mebel Kayu',
        categoryCode: 'MBL',
      );
      final mTiReturned = _createTestMutation(
        id: '3',
        ticketNumber: 'MUT-TI-3',
        status: MutationStatus.returned,
        assetName: 'Monitor Dell 27 Inch',
        categoryName: 'Teknologi Informasi',
        categoryCode: 'TI',
      );
      final mUmumCompleted = _createTestMutation(
        id: '4',
        ticketNumber: 'MUT-UMUM-4',
        status: MutationStatus.completed,
        assetName: 'Sofa Tamu',
        categoryName: 'Mebel Kayu',
        categoryCode: 'MBL',
      );

      final allMutations = [mTiSubmitted, mUmumAllocated, mTiReturned, mUmumCompleted];

      // Verifikasi TI vs Umum
      expect(isTiAsset(mTiSubmitted), isTrue);
      expect(isTiAsset(mUmumAllocated), isFalse);
      expect(isTiAsset(mTiReturned), isTrue);
      expect(isTiAsset(mUmumCompleted), isFalse);

      // Verifikasi Filter Provider Operator
      final container = ProviderContainer(
        overrides: [
          operatorAllMutationsProvider.overrideWith((ref) => Future.value(allMutations)),
        ],
      );
      await container.read(operatorAllMutationsProvider.future);

      // Tab Diproses (submitted)
      container.read(operatorStatusFilterProvider.notifier).state = OperatorStatusFilter.submitted;
      container.read(operatorCategoryFilterProvider.notifier).state = OperatorCategoryFilter.all;
      var filtered = container.read(filteredIncomingMutationsProvider).value!;
      expect(filtered.map((m) => m.id).toList(), ['1']);

      // Tab Dialokasikan (allocated)
      container.read(operatorStatusFilterProvider.notifier).state = OperatorStatusFilter.allocated;
      filtered = container.read(filteredIncomingMutationsProvider).value!;
      expect(filtered.map((m) => m.id).toList(), ['2']);

      // Tab Dikembalikan (returned)
      container.read(operatorStatusFilterProvider.notifier).state = OperatorStatusFilter.returned;
      filtered = container.read(filteredIncomingMutationsProvider).value!;
      expect(filtered.map((m) => m.id).toList(), ['3']);

      // Tab Selesai (completed)
      container.read(operatorStatusFilterProvider.notifier).state = OperatorStatusFilter.completed;
      filtered = container.read(filteredIncomingMutationsProvider).value!;
      expect(filtered.map((m) => m.id).toList(), ['4']);

      // Tab Aset TI
      container.read(operatorStatusFilterProvider.notifier).state = OperatorStatusFilter.all;
      container.read(operatorCategoryFilterProvider.notifier).state = OperatorCategoryFilter.ti;
      filtered = container.read(filteredIncomingMutationsProvider).value!;
      expect(filtered.map((m) => m.id).toList(), ['1', '3']);

      // Tab Aset Umum
      container.read(operatorCategoryFilterProvider.notifier).state = OperatorCategoryFilter.umum;
      filtered = container.read(filteredIncomingMutationsProvider).value!;
      expect(filtered.map((m) => m.id).toList(), ['2', '4']);

      container.dispose();
    });
  });

  group('FINAL VERIFICATION - BAGIAN ASET: Tab Status & Perpindahan Bersih', () {
    test('Tidak ada mutasi yang tertinggal di tab lama setelah status berubah', () async {
      var itemA = _createTestMutation(
        id: 'ba-1',
        ticketNumber: 'TKT-BA-1',
        status: MutationStatus.waitingAssetVerification,
        assetName: 'Printer Epson L3110',
        categoryName: 'Elektronik',
        categoryCode: 'ELK',
      );

      // Verifikasi awal: masuk ke tab Dialokasikan
      expect(MutationHistoryCategory.allocated.matches(itemA.status), isTrue);
      expect(MutationHistoryCategory.returned.matches(itemA.status), isFalse);

      // Bagian aset mengembalikan (status berubah jadi returned)
      itemA = itemA.copyWith(status: MutationStatus.returned);
      expect(MutationHistoryCategory.allocated.matches(itemA.status), isFalse,
          reason: 'Item TIDAK BOLEH tertinggal di tab Dialokasikan');
      expect(MutationHistoryCategory.returned.matches(itemA.status), isTrue,
          reason: 'Item HARUS masuk ke tab Dikembalikan');

      // Bagian Aset Filter Provider
      final container = ProviderContainer(
        overrides: [
          bagianAsetAllMutationsProvider.overrideWith((ref) => Future.value([itemA])),
        ],
      );
      await container.read(bagianAsetAllMutationsProvider.future);

      // Di tab Dialokasikan -> kosong
      container.read(bagianAsetStatusFilterProvider.notifier).state = BagianAsetStatusFilter.allocated;
      var listAllocated = container.read(filteredBagianAsetVerificationsProvider).value!;
      expect(listAllocated, isEmpty, reason: 'Tab Dialokasikan harus bersih');

      // Di tab Dikembalikan -> ada itemA
      container.read(bagianAsetStatusFilterProvider.notifier).state = BagianAsetStatusFilter.returned;
      var listReturned = container.read(filteredBagianAsetVerificationsProvider).value!;
      expect(listReturned.length, 1);
      expect(listReturned.first.id, 'ba-1');

      container.dispose();
    });
  });

  group('FINAL VERIFICATION - KADIV: Tab Status & Perpindahan Bersih', () {
    test('Tidak ada mutasi yang tertinggal di tab lama setelah approval atau rejection', () async {
      var itemK = _createTestMutation(
        id: 'k-1',
        ticketNumber: 'TKT-K-1',
        status: MutationStatus.waitingDivisionHeadApproval,
        assetName: 'Server Dell PowerEdge',
        categoryName: 'Server & Network',
        categoryCode: 'NET',
      );

      // Awalnya di Dialokasikan
      expect(MutationHistoryCategory.allocated.matches(itemK.status), isTrue);

      // Kasus 1: Kadiv Menolak
      final rejectedItem = itemK.copyWith(status: MutationStatus.rejected);
      expect(MutationHistoryCategory.allocated.matches(rejectedItem.status), isFalse);
      expect(MutationHistoryCategory.rejected.matches(rejectedItem.status), isTrue);

      // Kasus 2: Kadiv Menyetujui dan lanjut sampai Selesai
      final completedItem = itemK.copyWith(status: MutationStatus.completed);
      expect(MutationHistoryCategory.allocated.matches(completedItem.status), isFalse);
      expect(MutationHistoryCategory.completed.matches(completedItem.status), isTrue);

      // Kadiv Filter Provider Test
      final container = ProviderContainer(
        overrides: [
          kadivAllMutationsProvider.overrideWith((ref) => Future.value([rejectedItem])),
        ],
      );
      await container.read(kadivAllMutationsProvider.future);

      // Di tab Dialokasikan -> kosong
      container.read(kadivStatusFilterProvider.notifier).state = KadivStatusFilter.allocated;
      expect(container.read(filteredKadivApprovalsProvider).value!, isEmpty);

      // Di tab Ditolak -> ada 1
      container.read(kadivStatusFilterProvider.notifier).state = KadivStatusFilter.rejected;
      final rejectedList = container.read(filteredKadivApprovalsProvider).value!;
      expect(rejectedList.length, 1);
      expect(rejectedList.first.id, 'k-1');

      container.dispose();
    });
  });

  group('FINAL VERIFICATION - REFRESH & INVALIDATION INTEGRITY', () {
    test('invalidateAllRoleMutationProviders me-refresh provider seluruh 4 role tanpa duplikasi', () {
      final container = ProviderContainer();

      expect(container.read(operatorStatusFilterProvider), OperatorStatusFilter.submitted);
      expect(container.read(bagianAsetStatusFilterProvider), BagianAsetStatusFilter.waiting);
      expect(container.read(kadivStatusFilterProvider), KadivStatusFilter.waiting);

      // Panggil invalidate cross role
      invalidateAllRoleMutationProviders(container);

      // State filter tetap terjaga dan provider siap fetch status terbaru
      expect(container.read(operatorStatusFilterProvider), OperatorStatusFilter.submitted);
      expect(container.read(bagianAsetStatusFilterProvider), BagianAsetStatusFilter.waiting);
      expect(container.read(kadivStatusFilterProvider), KadivStatusFilter.waiting);

      container.dispose();
    });
  });
}
