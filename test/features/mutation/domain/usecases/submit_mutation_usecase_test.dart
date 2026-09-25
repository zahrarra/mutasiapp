import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/core/errors/result.dart';
import 'package:mutasiku/features/asset/domain/entities/asset.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_category.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_status.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation.dart';
import 'package:mutasiku/features/mutation/domain/entities/mutation_status.dart';
import 'package:mutasiku/features/mutation/domain/repositories/mutation_repository.dart';
import 'package:mutasiku/features/mutation/domain/usecases/submit_mutation_usecase.dart';

class _MockMutationRepository implements MutationRepository {
  SubmitMutationParams? lastParams;

  @override
  Future<Result<Mutation>> submitMutation(SubmitMutationParams params) async {
    lastParams = params;
    final cat = const AssetCategory(id: 'cat_1', code: 'ELK', name: 'Elektronik');
    final asset = params.isUnregisteredAsset
        ? null
        : Asset(
            id: params.assetId ?? 'ast_1',
            assetCode: params.assetId ?? 'ast_1',
            name: params.assetName,
            category: cat,
            location: params.sourceLocation,
            pic: params.currentPic ?? '-',
            status: AssetStatus.available,
            condition: 'Baik',
            acquisitionYear: 2024,
          );

    return Result.success(
      Mutation(
        id: 'mut_test_01',
        ticketNumber: 'ELK-2026-00001',
        assetId: params.assetId,
        asset: asset,
        isUnregisteredAsset: params.isUnregisteredAsset,
        customAssetName: params.customAssetName,
        customSerialNumber: params.customSerialNumber,
        applicantName: params.applicantName ?? 'Pemohon Test',
        currentLocation: params.sourceLocation,
        targetLocation: params.targetLocation,
        currentPic: params.currentPic ?? '-',
        targetPic: params.targetPic,
        reason: params.reason,
        status: MutationStatus.submitted,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _MockMutationRepository mockRepo;
  late SubmitMutationUseCase useCase;

  setUp(() {
    mockRepo = _MockMutationRepository();
    useCase = SubmitMutationUseCase(mutationRepository: mockRepo);
  });

  group('SubmitMutationUseCase - Registered Asset Validation', () {
    test('succeeds when registered asset has valid assetId and all required fields', () async {
      final params = const SubmitMutationParams(
        applicantId: 'usr_1',
        applicantName: 'Budi',
        assetId: 'AST-ELK-001',
        assetName: 'ThinkPad T14',
        sourceLocation: 'Ruang IT',
        targetLocation: 'Cabang Bandung',
        currentPic: 'Budi',
        targetPic: 'Ahmad',
        reason: 'Rotasi perangkat kantor',
      );

      final result = await useCase(params);

      expect(result.isSuccess, isTrue);
      expect(mockRepo.lastParams?.assetId, equals('AST-ELK-001'));
      expect(mockRepo.lastParams?.isUnregisteredAsset, isFalse);
    });

    test('fails when registered asset has null assetId', () async {
      final params = const SubmitMutationParams(
        assetId: null,
        assetName: 'ThinkPad T14',
        sourceLocation: 'Ruang IT',
        targetLocation: 'Cabang Bandung',
        targetPic: 'Ahmad',
        reason: 'Rotasi perangkat',
        isUnregisteredAsset: false,
      );

      final result = await useCase(params);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.userMessage, contains('ID Aset terdaftar wajib diisi'));
    });

    test('fails when registered asset has empty assetId', () async {
      final params = const SubmitMutationParams(
        assetId: '   ',
        assetName: 'ThinkPad T14',
        sourceLocation: 'Ruang IT',
        targetLocation: 'Cabang Bandung',
        targetPic: 'Ahmad',
        reason: 'Rotasi perangkat',
        isUnregisteredAsset: false,
      );

      final result = await useCase(params);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.userMessage, contains('ID Aset terdaftar wajib diisi'));
    });
  });

  group('SubmitMutationUseCase - Unregistered Asset Validation', () {
    test('succeeds when unregistered asset has isUnregisteredAsset: true, assetId: null, and customAssetName', () async {
      final params = const SubmitMutationParams(
        applicantId: 'usr_1',
        applicantName: 'Budi',
        assetId: null,
        isUnregisteredAsset: true,
        customAssetName: 'Printer Epson L3110 (Manual)',
        customSerialNumber: 'SN-MANUAL-999',
        sourceLocation: 'Gudang Lama',
        targetLocation: 'Cabang Cirebon',
        currentPic: 'Staff Lama',
        targetPic: 'Staff Baru',
        reason: 'Aset hibah kantor lama',
      );

      final result = await useCase(params);

      expect(result.isSuccess, isTrue);
      final created = result.dataOrNull!;
      expect(created.isUnregisteredAsset, isTrue);
      expect(created.assetId, isNull);
      expect(created.customAssetName, equals('Printer Epson L3110 (Manual)'));
      expect(created.customSerialNumber, equals('SN-MANUAL-999'));
      expect(created.displayAssetName, equals('Printer Epson L3110 (Manual)'));
      expect(created.displayAssetCode, equals('SN-MANUAL-999'));
    });

    test('fails when unregistered asset has non-null assetId (invalid state combination)', () async {
      final params = const SubmitMutationParams(
        assetId: 'AST-FAKE-001',
        isUnregisteredAsset: true,
        customAssetName: 'Printer Manual',
        sourceLocation: 'Gudang',
        targetLocation: 'Cabang Cirebon',
        targetPic: 'Staff',
        reason: 'Rotasi',
      );

      final result = await useCase(params);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.userMessage, contains('tidak boleh memiliki ID aset'));
    });

    test('fails when unregistered asset has empty customAssetName and empty assetName', () async {
      final params = const SubmitMutationParams(
        assetId: null,
        isUnregisteredAsset: true,
        customAssetName: '  ',
        assetName: '  ',
        sourceLocation: 'Gudang',
        targetLocation: 'Cabang Cirebon',
        targetPic: 'Staff',
        reason: 'Rotasi',
      );

      final result = await useCase(params);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.userMessage, contains('Nama aset tidak terdaftar wajib diisi'));
    });
  });
}
