// lib/features/admin/domain/repositories/location_repository.dart
//
// Kontrak repository data master Lokasi & Unit Kerja.
// Sumber: PRD.md §5, ROLE-FLOW.md §2.

import '../../../../core/errors/result.dart';
import '../entities/location_item.dart';

abstract class LocationRepository {
  /// Mengambil snapshot sinkron seluruh lokasi.
  List<LocationItem> get currentLocations;

  /// Mengambil semua lokasi (aktif & nonaktif).
  Future<Result<List<LocationItem>>> getAllLocations();

  /// Mengambil lokasi yang aktif saja (untuk dropdown form mutasi).
  Future<Result<List<LocationItem>>> getActiveLocations();

  /// Menambah lokasi baru ke master data.
  Future<Result<LocationItem>> addLocation(LocationItem item);

  /// Memperbarui informasi lokasi yang ada.
  Future<Result<LocationItem>> updateLocation(LocationItem item);

  /// Mengaktifkan atau menonaktifkan lokasi.
  Future<Result<void>> toggleLocationActive(String id, bool isActive);

  /// Menghapus lokasi jika aman dari referensi historis.
  Future<Result<void>> deleteLocation(String id);
}
