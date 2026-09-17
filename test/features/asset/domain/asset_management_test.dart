// test/features/asset/domain/asset_management_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mutasiku/features/asset/data/repositories/asset_repository_impl.dart';
import 'package:mutasiku/features/asset/domain/entities/asset.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_category.dart';
import 'package:mutasiku/features/asset/domain/entities/asset_status.dart';
import 'package:mutasiku/features/asset/domain/usecases/get_asset_detail_usecase.dart';
import 'package:mutasiku/features/asset/domain/usecases/get_assets_usecase.dart';

void main() {
  group('Asset Management Domain & Repository Tests', () {
    late AssetRepositoryImpl repository;
    late GetAssetsUseCase getAssetsUseCase;
    late GetAssetDetailUseCase getAssetDetailUseCase;

    setUp(() {
      repository = AssetRepositoryImpl();
      getAssetsUseCase = GetAssetsUseCase(repository: repository);
      getAssetDetailUseCase = GetAssetDetailUseCase(repository: repository);
    });

    test('AssetStatus enum parsing and display names', () {
      expect(AssetStatus.available.displayName, 'Tersedia');
      expect(AssetStatus.inMutation.displayName, 'Dalam Mutasi');
      expect(AssetStatus.fromApiValue('in_mutation'), AssetStatus.inMutation);
      expect(AssetStatus.fromApiValue('tersedia'), AssetStatus.available);
      expect(AssetStatus.fromApiValue('unknown'), AssetStatus.available);
    });

    test('Asset isLocked logic per TECHNICAL-DESIGN §23', () {
      const category = AssetCategory(id: 'c1', code: 'ELK', name: 'Elektronik');

      const availableAsset = Asset(
        id: 'a1',
        assetCode: 'AST-001',
        name: 'Laptop A',
        category: category,
        location: 'Lantai 1',
        pic: 'Budi',
        status: AssetStatus.available,
        condition: 'Baik',
        acquisitionYear: 2024,
        hasActiveMutation: false,
      );
      expect(availableAsset.isLocked, false);

      const lockedAsset = Asset(
        id: 'a2',
        assetCode: 'AST-002',
        name: 'MacBook B',
        category: category,
        location: 'Lantai 4',
        pic: 'Dahlan',
        status: AssetStatus.inMutation,
        condition: 'Baik',
        acquisitionYear: 2024,
        hasActiveMutation: true,
        activeMutationTicket: 'MUT-2026-0042',
      );
      expect(lockedAsset.isLocked, true);
    });

    test('GetAssetsUseCase search query filtering', () async {
      final result = await getAssetsUseCase(query: 'Lenovo');

      expect(result.isSuccess, true);
      final list = result.dataOrNull!;
      expect(list.length, 1);
      expect(list.first.assetCode, 'AST-ELK-2024-001');
    });

    test('GetAssetsUseCase status filter', () async {
      final result = await getAssetsUseCase(status: AssetStatus.inMutation);

      expect(result.isSuccess, true);
      final list = result.dataOrNull!;
      expect(list.length, 1);
      expect(list.first.id, 'ast_2');
    });

    test('GetAssetDetailUseCase returns correct asset by id', () async {
      final result = await getAssetDetailUseCase('ast_1');

      expect(result.isSuccess, true);
      final asset = result.dataOrNull!;
      expect(asset.id, 'ast_1');
      expect(asset.name, 'Laptop Lenovo ThinkPad T14 Gen 3');
      expect(asset.history.length, 1);
    });
  });
}
