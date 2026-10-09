// lib/features/asset/domain/repositories/asset_repository.dart
//
// Kontrak repository Asset Management.
// Sumber: SKILLS.md §7, TECHNICAL-DESIGN.md §8.

import '../../../../core/errors/result.dart';
import '../entities/asset.dart';
import '../entities/asset_category.dart';
import '../entities/asset_history_item.dart';
import '../entities/asset_status.dart';

abstract class AssetRepository {
  /// Ambil daftar aset dengan filter opsional.
  Future<Result<List<Asset>>> getAssets({
    String? query,
    String? categoryId,
    String? location,
    AssetStatus? status,
    bool? mine,
  });

  /// Ambil detail satu aset berdasarkan ID.
  Future<Result<Asset>> getAssetById(String id);

  /// Ambil riwayat mutasi aset.
  Future<Result<List<AssetHistoryItem>>> getAssetHistory(String assetId);

  /// Ambil daftar kategori aset.
  Future<Result<List<AssetCategory>>> getCategories();

  /// Menambah kategori aset baru oleh Admin.
  Future<Result<AssetCategory>> addCategory(AssetCategory category);

  /// Memperbarui informasi kategori aset oleh Admin.
  Future<Result<AssetCategory>> updateCategory(AssetCategory category);

  /// Mengaktifkan atau menonaktifkan kategori aset oleh Admin.
  Future<Result<void>> toggleCategoryActive(String id, bool isActive);

  /// Menghapus kategori aset jika tidak digunakan oleh aset terdaftar.
  Future<Result<void>> deleteCategory(String id);

  /// Update lokasi dan PIC aset serta catat riwayat perubahan.
  Future<Result<Asset>> updateAssetLocationAndPic({
    required String assetId,
    required String newLocation,
    required String newPic,
    required String ticketNumber,
    required String updatedBy,
  });

  /// Memperbarui informasi aset (status, lokasi, PIC).
  Future<Result<Asset>> updateAsset(Asset asset);

  /// Menambahkan aset baru oleh Admin (POST /api/v1/admin/assets).
  Future<Result<Asset>> createAsset(CreateAssetParams params);
}

class CreateAssetParams {
  final String assetCode;
  final String name;
  final String assetCategoryId;
  final String locationId;
  final String picId;
  final String condition;
  final String serialNumber;
  final int acquisitionYear;
  final int? usageYear;
  final bool isActive;

  const CreateAssetParams({
    required this.assetCode,
    required this.name,
    required this.assetCategoryId,
    required this.locationId,
    required this.picId,
    required this.condition,
    required this.serialNumber,
    required this.acquisitionYear,
    this.usageYear,
    this.isActive = true,
  });
}
