import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/errors/failures.dart';
import 'package:mutasiku/features/asset/data/repositories/asset_repository_impl.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_status.dart';
import 'package:mutasiku/features/mutation/data/repositories/mutation_repository_impl.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';

void main() {
  late AssetRepositoryImpl assetRepo;
  late MutationRepositoryImpl mutationRepo;

  setUp(() {
    AssetRepositoryImpl.resetForTesting();
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
          sourceLocation: '', // Empty to test snapshotting from master asset
          targetLocation: 'Cabang Medan',
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

    test('master asset in AssetRepository location and pic remain unchanged during submission, status locked to inMutation', () async {
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

      // Verify master asset in asset repository location and pic are UNCHANGED during submission,
      // but asset is locked to inMutation per PRD V1.1 §8 Rule 5
      final afterAsset = (await assetRepo.getAssetById('ast_1')).dataOrNull!;
      expect(afterAsset.location, equals('Lantai 3 — Ruang IT Developer'));
      expect(afterAsset.pic, equals(initialAsset.pic));
      expect(afterAsset.status, equals(AssetStatus.inMutation));
      expect(afterAsset.hasActiveMutation, isTrue);
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

  group('MutationRepositoryImpl - Unregistered Asset Submissions (PRD V1.1 §8 Rule 3)', () {
    test('rejects unregistered asset with isUnregisteredAsset == true', () async {
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

      expect(submitResult.isFailure, isTrue);
      expect(submitResult.failureOrNull, isA<ValidationFailure>());
      expect(
        submitResult.failureOrNull?.userMessage,
        contains('Aset yang dimutasi harus merupakan aset terdaftar'),
      );
    });

    test('rejects submission when assetId is null or empty', () async {
      final submitResult = await mutationRepo.submitMutation(
        const SubmitMutationParams(
          applicantId: 'usr_pemohon_1',
          applicantName: 'Pemohon Test',
          assetId: '',
          isUnregisteredAsset: false,
          sourceLocation: 'Lantai 2',
          targetLocation: 'Lantai 5',
          targetPic: 'Staff Umum',
          reason: 'Pindah ruang rapat',
        ),
      );

      expect(submitResult.isFailure, isTrue);
      expect(submitResult.failureOrNull, isA<ValidationFailure>());
    });
  });
}
