// lib/features/asset/presentation/providers/asset_provider.dart
//
// Riverpod providers untuk Asset Management.
// Sumber: SKILLS.md §7, TECHNICAL-DESIGN.md.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/result.dart';
import '../../data/repositories/asset_repository_impl.dart';
import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_category.dart';
import '../../domain/entities/asset_status.dart';
import '../../domain/repositories/asset_repository.dart';
import '../../domain/usecases/get_asset_detail_usecase.dart';
import '../../domain/usecases/get_assets_usecase.dart';

/// Provider untuk [AssetRepository].
final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepositoryImpl();
});

/// Provider untuk [GetAssetsUseCase].
final getAssetsUseCaseProvider = Provider<GetAssetsUseCase>((ref) {
  final repo = ref.watch(assetRepositoryProvider);
  return GetAssetsUseCase(repository: repo);
});

/// Provider untuk [GetAssetDetailUseCase].
final getAssetDetailUseCaseProvider = Provider<GetAssetDetailUseCase>((ref) {
  final repo = ref.watch(assetRepositoryProvider);
  return GetAssetDetailUseCase(repository: repo);
});

/// State filter pencarian teks aset.
final assetSearchQueryProvider = StateProvider<String>((ref) => '');

/// State filter kategori aset.
final assetCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// State filter status aset.
final assetStatusFilterProvider = StateProvider<AssetStatus?>((ref) => null);

/// AsyncProvider daftar aset terfilter.
final assetListProvider = FutureProvider<List<Asset>>((ref) async {
  final useCase = ref.watch(getAssetsUseCaseProvider);
  final query = ref.watch(assetSearchQueryProvider);
  final categoryId = ref.watch(assetCategoryFilterProvider);
  final status = ref.watch(assetStatusFilterProvider);

  final result = await useCase(
    query: query,
    categoryId: categoryId,
    status: status,
  );

  if (result is Success<List<Asset>>) {
    return result.data;
  } else if (result is AppFailure<List<Asset>>) {
    throw Exception(result.failure.userMessage);
  }
  return [];
});

/// AsyncProvider detail satu aset berdasarkan ID.
final assetDetailProvider =
    FutureProvider.family<Asset, String>((ref, id) async {
  final useCase = ref.watch(getAssetDetailUseCaseProvider);
  final result = await useCase(id);

  if (result is Success<Asset>) {
    return result.data;
  } else if (result is AppFailure<Asset>) {
    throw Exception(result.failure.userMessage);
  }
  throw Exception('Aset tidak ditemukan');
});

/// AsyncProvider daftar kategori aset.
final assetCategoriesProvider = FutureProvider<List<AssetCategory>>((ref) async {
  final repo = ref.watch(assetRepositoryProvider);
  final result = await repo.getCategories();

  if (result is Success<List<AssetCategory>>) {
    return result.data;
  } else if (result is AppFailure<List<AssetCategory>>) {
    throw Exception(result.failure.userMessage);
  }
  return [];
});
