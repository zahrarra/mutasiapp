// lib/features/admin/data/repositories/location_repository_impl.dart
//
// Implementasi in-memory LocationRepository untuk master lokasi.
// Sumber: PRD.md §5, ROLE-FLOW.md §2.

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/location_item.dart';
import '../../domain/repositories/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  static final List<LocationItem> _locations = [
    const LocationItem(
      id: 'loc_1',
      name: 'Lantai 1 — Lobby & Reception',
      description: 'Unit Kerja Kantor Pusat / Reception',
      isBranch: false,
      isActive: true,
    ),
    const LocationItem(
      id: 'loc_2',
      name: 'Lantai 2 — Ruang Keuangan',
      description: 'Unit Kerja Kantor Pusat / Divisi Keuangan',
      isBranch: false,
      isActive: true,
    ),
    const LocationItem(
      id: 'loc_3',
      name: 'Lantai 3 — Ruang IT Developer',
      description: 'Unit Kerja Kantor Pusat / Divisi Teknologi',
      isBranch: false,
      isActive: true,
    ),
    const LocationItem(
      id: 'loc_4',
      name: 'Lantai 4 — Ruang Kadiv Aset',
      description: 'Unit Kerja Kantor Pusat / Manajemen Aset',
      isBranch: false,
      isActive: true,
    ),
    const LocationItem(
      id: 'loc_5',
      name: 'Lantai Server — Server Room B',
      description: 'Unit Kerja Data Center & Server',
      isBranch: false,
      isActive: true,
    ),
    const LocationItem(
      id: 'loc_6',
      name: 'Gedung A — Parkir Operasional',
      description: 'Unit Kerja Kantor Pusat / Lapangan GA',
      isBranch: false,
      isActive: true,
    ),
    const LocationItem(
      id: 'loc_7',
      name: 'Cabang Surabaya',
      description: 'Unit Kerja Kantor Cabang Regional Surabaya',
      isBranch: true,
      isActive: true,
    ),
    const LocationItem(
      id: 'loc_8',
      name: 'Cabang Bandung',
      description: 'Unit Kerja Kantor Cabang Regional Bandung',
      isBranch: true,
      isActive: true,
    ),
    const LocationItem(
      id: 'loc_9',
      name: 'Cabang Semarang',
      description: 'Unit Kerja Kantor Cabang Regional Semarang',
      isBranch: true,
      isActive: true,
    ),
  ];

  static const Set<String> _protectedLocationIds = {
    'loc_1',
    'loc_2',
    'loc_3',
    'loc_4',
    'loc_5',
    'loc_6',
    'loc_7',
    'loc_8',
    'loc_9',
  };

  static final LocationRepositoryImpl instance = LocationRepositoryImpl._();
  LocationRepositoryImpl._();
  factory LocationRepositoryImpl() => instance;

  @override
  List<LocationItem> get currentLocations => List.unmodifiable(_locations);

  @override
  Future<Result<List<LocationItem>>> getAllLocations() async {
    return Result.success(List.unmodifiable(_locations));
  }

  @override
  Future<Result<List<LocationItem>>> getActiveLocations() async {
    final active = _locations.where((l) => l.isActive).toList();
    return Result.success(List.unmodifiable(active));
  }

  @override
  Future<Result<LocationItem>> addLocation(LocationItem item) async {
    final cleanName = item.name.trim();
    if (cleanName.isEmpty) {
      return Result.failure(
        const ValidationFailure(message: 'Nama lokasi wajib diisi.'),
      );
    }

    final exists = _locations.any(
      (l) => l.name.toLowerCase() == cleanName.toLowerCase(),
    );
    if (exists) {
      return Result.failure(
        ValidationFailure(message: 'Lokasi "$cleanName" sudah ada.'),
      );
    }

    final newId = item.id.isNotEmpty
        ? item.id
        : 'loc_${DateTime.now().millisecondsSinceEpoch}';

    final isBranch = item.isBranch || cleanName.toLowerCase().contains('cabang');

    final newLocation = item.copyWith(
      id: newId,
      name: cleanName,
      description: item.description?.trim(),
      isBranch: isBranch,
      isActive: true,
    );

    _locations.add(newLocation);
    return Result.success(newLocation);
  }

  @override
  Future<Result<LocationItem>> updateLocation(LocationItem item) async {
    final index = _locations.indexWhere((l) => l.id == item.id);
    if (index == -1) {
      return Result.failure(const NotFoundFailure(message: 'Lokasi tidak ditemukan.'));
    }

    final cleanName = item.name.trim();
    if (cleanName.isEmpty) {
      return Result.failure(
        const ValidationFailure(message: 'Nama lokasi wajib diisi.'),
      );
    }

    final duplicate = _locations.any(
      (l) =>
          l.id != item.id && l.name.toLowerCase() == cleanName.toLowerCase(),
    );
    if (duplicate) {
      return Result.failure(
        ValidationFailure(message: 'Lokasi "$cleanName" sudah ada.'),
      );
    }

    final isBranch = item.isBranch || cleanName.toLowerCase().contains('cabang');

    final updated = item.copyWith(
      name: cleanName,
      description: item.description?.trim(),
      isBranch: isBranch,
    );

    _locations[index] = updated;
    return Result.success(updated);
  }

  @override
  Future<Result<void>> toggleLocationActive(String id, bool isActive) async {
    final index = _locations.indexWhere((l) => l.id == id);
    if (index == -1) {
      return Result.failure(const NotFoundFailure(message: 'Lokasi tidak ditemukan.'));
    }

    _locations[index] = _locations[index].copyWith(isActive: isActive);
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteLocation(String id) async {
    if (_protectedLocationIds.contains(id)) {
      return Result.failure(
        const ValidationFailure(
          message:
              'Lokasi default/histori tidak dapat dihapus permanen karena masih direferensikan. Silakan nonaktifkan lokasi.',
        ),
      );
    }

    _locations.removeWhere((l) => l.id == id);
    return Result.success(null);
  }
}
