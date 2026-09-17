// lib/features/asset/domain/usecases/get_assets_usecase.dart

import '../../../../core/errors/result.dart';
import '../entities/asset.dart';
import '../entities/asset_status.dart';
import '../repositories/asset_repository.dart';

class GetAssetsUseCase {
  final AssetRepository repository;

  const GetAssetsUseCase({required this.repository});

  Future<Result<List<Asset>>> call({
    String? query,
    String? categoryId,
    String? location,
    AssetStatus? status,
  }) {
    return repository.getAssets(
      query: query,
      categoryId: categoryId,
      location: location,
      status: status,
    );
  }
}
