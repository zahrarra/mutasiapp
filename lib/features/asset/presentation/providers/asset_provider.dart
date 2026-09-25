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
import '../../../auth/presentation/providers/auth_provider.dart';

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

/// AsyncProvider daftar aset tanggung jawab pengguna (PIC) yang sedang login.
final userResponsibleAssetsProvider = FutureProvider<List<Asset>>((ref) async {
  final user = ref.watch(authStateProvider).user;
  if (user == null) return [];

  final useCase = ref.watch(getAssetsUseCaseProvider);
  final result = await useCase();
  if (result is Success<List<Asset>>) {
    return _filterAssetsByUser(result.data, user);
  }
  return [];
});

List<Asset> _filterAssetsByUser(List<Asset> assets, dynamic user) {
  final userName = (user.name as String? ?? '').toLowerCase().trim();
  final userUsername = (user.username as String? ?? '').toLowerCase().trim();
  final isPemohon = user.role?.toString().toLowerCase().contains('pemohon') ?? false;

  return assets.where((asset) {
    // Hanya aset aktif yang belum dihapus/disposisi
    if (asset.status == AssetStatus.disposed) return false;

    final pic = asset.pic.toLowerCase().trim();
    if (userName.isNotEmpty && (pic.contains(userName) || userName.contains(pic))) {
      return true;
    }
    if (userUsername.isNotEmpty && pic.contains(userUsername)) {
      return true;
    }
    // Skenario akun default demo pemohon (username/name "pemohon" merepresentasikan Budi Santoso)
    if (isPemohon && (userUsername == 'pemohon' || userName.contains('pemohon'))) {
      if (pic.contains('budi santoso')) {
        return true;
      }
    }
    return false;
  }).toList();
}
