// lib/features/asset/domain/usecases/create_asset_usecase.dart

import '../../../../core/errors/result.dart';
import '../entities/asset.dart';
import '../repositories/asset_repository.dart';

class CreateAssetUseCase {
  final AssetRepository repository;

  const CreateAssetUseCase({required this.repository});

  Future<Result<Asset>> call(CreateAssetParams params) {
    return repository.createAsset(params);
  }
}
