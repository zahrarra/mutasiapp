import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/features/asset/data/repositories/asset_repository_impl.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_status.dart';
import 'package:mutasiku/features/mutation/data/repositories/mutation_repository_impl.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';

void main() {
  late AssetRepositoryImpl assetRepo;
  late MutationRepositoryImpl mutationRepo;

  setUp(() {
    MutationRepositoryImpl.resetForTesting();
    assetRepo = AssetRepositoryImpl();
    mutationRepo = MutationRepositoryImpl(assetRepository: assetRepo);
  });

  group('MutationRepositoryImpl - Registered Asset Submissions', () {
    test('fetches asset from AssetRepository and snapshots location and PIC', () async {
      // ast_1 in mock is 'Laptop Lenovo ThinkPad T14 Gen 3'
      // location: 'Lantai 3 — Ruang IT Developer', pic: 'Budi Santoso (IT Dept)'
      final submitResult = await mutationRepo.submitMutation(
        const SubmitMutationParams(
          applicantId: 'usr_pemohon_1',
          applicantName: 'Pemohon Test',
          assetId: 'ast_1',
          sourceLocation: 'Lokasi Asal di Form',
          targetLocation: 'Cabang Medan',
          currentPic: 'PIC di Form',
          targetPic: 'PIC Baru Medan',
          reason: 'Peremajaan cabang Medan',
        ),
      );

      expect(submitResult.isSuccess, isTrue);
      final mutation = submitResult.dataOrNull!;
      expect(mutation.assetId, equals('ast_1'));
      expect(mutation.isUnregisteredAsset, isFalse);
      expect(mutation.asset.name, equals('Laptop Lenovo ThinkPad T14 Gen 3'));
      // Snapshot harus diambil dari master asset
      expect(mutation.currentLocation, equals('Lantai 3 — Ruang IT Developer'));
      expect(mutation.currentPic, equals('Budi Santoso (IT Dept)'));
      expect(mutation.status, equals(MutationStatus.submitted));
    });

    test('master asset in AssetRepository remains unchanged during submission', () async {
      final initialAsset = (await assetRepo.getAssetById('ast_1')).dataOrNull!;
      expect(initialAsset.location, equals('Lantai 3 — Ruang IT Developer'));
      expect(initialAsset.status, equals(AssetStatus.available));

      await mutationRepo.submitMutation(
        const SubmitMutationParams(
          applicantId: 'usr_pemohon_1',
          applicantName: 'Pemohon Test',
          assetId: 'ast_1',
          sourceLocation: 'Lantai 3 — Ruang IT Developer',
          targetLocation: 'Cabang Medan',
          targetPic: 'PIC Baru',
          reason: 'Kebutuhan mutasi',
        ),
      );

      // Verify master asset in asset repository is UNCHANGED
      final afterAsset = (await assetRepo.getAssetById('ast_1')).dataOrNull!;
      expect(afterAsset.location, equals('Lantai 3 — Ruang IT Developer'));
      expect(afterAsset.pic, equals(initialAsset.pic));
      expect(afterAsset.status, equals(AssetStatus.available));
    });

    test('prevents duplicate active mutation for the same asset', () async {
      // First submission
      final firstResult = await mutationRepo.submitMutation(
        const SubmitMutationParams(
          applicantId: 'usr_pemohon_1',
          assetId: 'ast_1',
          sourceLocation: 'Lantai 3',
          targetLocation: 'Cabang A',
          targetPic: 'PIC A',
          reason: 'Mutasi pertama',
        ),
      );
      expect(firstResult.isSuccess, isTrue);

      // Second submission for the same asset while first is active (submitted)
      final secondResult = await mutationRepo.submitMutation(
        const SubmitMutationParams(
          applicantId: 'usr_pemohon_2',
          assetId: 'ast_1',
          sourceLocation: 'Lantai 3',
          targetLocation: 'Cabang B',
          targetPic: 'PIC B',
          reason: 'Mutasi kedua aset sama',
        ),
      );

      expect(secondResult.isFailure, isTrue);
      expect(
        secondResult.failureOrNull?.userMessage,
        contains('sedang memiliki pengajuan mutasi aktif'),
      );
    });
  });

  group('MutationRepositoryImpl - Unregistered Asset Submissions', () {
    test('submits unregistered asset with assetId == null and isUnregisteredAsset == true', () async {
      final submitResult = await mutationRepo.submitMutation(
        const SubmitMutationParams(
          applicantId: 'usr_pemohon_1',
          applicantName: 'Pemohon Test',
          assetId: null,
          isUnregisteredAsset: true,
          customAssetName: 'Printer Epson L3210 (Manual)',
          customSerialNumber: 'SN-UNREG-8821',
          sourceLocation: 'Gudang Lama',
          targetLocation: 'Cabang Semarang',
          currentPic: 'Pak Slamet',
          targetPic: 'Bu Siti',
          reason: 'Aset tidak terdaftar dari kantor cabang lama',
        ),
      );

      expect(submitResult.isSuccess, isTrue);
      final mutation = submitResult.dataOrNull!;
      expect(mutation.assetId, isNull);
      expect(mutation.isUnregisteredAsset, isTrue);
      expect(mutation.customAssetName, equals('Printer Epson L3210 (Manual)'));
      expect(mutation.customSerialNumber, equals('SN-UNREG-8821'));
      expect(mutation.displayAssetName, equals('Printer Epson L3210 (Manual)'));
      expect(mutation.displayAssetCode, equals('SN-UNREG-8821'));
      // No dummy id
      expect(mutation.asset.id, isEmpty);
    });

    test('Staff Aset does not fail or call updateAssetLocationAndPic for unregistered asset', () async {
      final submitResult = await mutationRepo.submitMutation(
        const SubmitMutationParams(
          applicantId: 'usr_pemohon_1',
          applicantName: 'Pemohon Test',
          assetId: null,
          isUnregisteredAsset: true,
          customAssetName: 'Meja Rapat Kayu Jati',
          sourceLocation: 'Lantai 2',
          targetLocation: 'Lantai 5',
          targetPic: 'Staff Umum',
          reason: 'Pindah ruang rapat',
        ),
      );

      expect(submitResult.isSuccess, isTrue);
      final mutationId = submitResult.dataOrNull!.id;

      // Operator verifies
      await mutationRepo.verifyMutation(
        mutationId: mutationId,
        operatorName: 'Siti Rahma',
        requiresKadivApproval: false,
      );

      // Kabag approves -> status becomes approved
      await mutationRepo.approveMutationKabag(
        mutationId: mutationId,
        kabagName: 'Budi Santoso',
        requiresKadivApproval: false,
      );

      // Staff Aset updates location and pic for unregistered asset
      final staffUpdateResult = await mutationRepo.processStaffAssetUpdate(
        mutationId: mutationId,
        newLocation: 'Lantai 5 — Ruang VIP',
        newPic: 'Staff Umum',
        staffName: 'Agus Pratama',
      );

      expect(staffUpdateResult.isSuccess, isTrue);
      final updated = staffUpdateResult.dataOrNull!;
      expect(updated.status, equals(MutationStatus.pendingConfirmation));
      expect(updated.targetLocation, equals('Lantai 5 — Ruang VIP'));
      expect(updated.isUnregisteredAsset, isTrue);
      expect(updated.assetId, isNull);
    });
  });
}
