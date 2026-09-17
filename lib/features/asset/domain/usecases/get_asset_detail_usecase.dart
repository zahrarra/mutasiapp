// lib/features/asset/domain/usecases/get_asset_detail_usecase.dart

import '../../../../core/errors/result.dart';
import '../entities/asset.dart';
import '../repositories/asset_repository.dart';

class GetAssetDetailUseCase {
  final AssetRepository repository;

  const GetAssetDetailUseCase({required this.repository});

  Future<Result<Asset>> call(String id) {
    return repository.getAssetById(id);
  }
}
