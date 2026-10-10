// lib/features/admin/data/repositories/location_repository_impl.dart
//
// Implementasi in-memory LocationRepository untuk master lokasi.
// Sumber: PRD.md §5, ROLE-FLOW.md §2.

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/location_item.dart';
import '../../domain/repositories/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  final ApiClient? apiClient;
  // Cache in-memory lokasi yang diperoleh dari backend API atau ditambahkan saat test
  static final List<LocationItem> _locations = [
    const LocationItem(
      id: '22',
      name: 'Lantai 1',
      description: 'LT-1',
      isBranch: false,
      isActive: true,
    ),
    const LocationItem(
      id: '23',
      name: 'Lantai 2',
      description: 'LT-2',
      isBranch: false,
      isActive: true,
    ),
    const LocationItem(
      id: '24',
      name: 'Lantai 3',
      description: 'LT-3',
      isBranch: false,
      isActive: true,
    ),
    const LocationItem(
      id: '26',
      name: 'Ruang Divisi TI',
      description: 'RG-TI',
      isBranch: false,
      isActive: true,
    ),
    const LocationItem(
      id: '37',
      name: 'KCU Palu',
      description: 'CAB-PLU-KCU',
      isBranch: true,
      isActive: true,
    ),
    const LocationItem(
      id: '40',
      name: 'Cabang Donggala',
      description: 'CAB-DGL',
      isBranch: true,
      isActive: true,
    ),
    const LocationItem(
      id: '39',
      name: 'Cabang Sigi',
      description: 'CAB-SIGI',
      isBranch: true,
      isActive: true,
    ),
    const LocationItem(
      id: '43',
      name: 'Cabang Poso',
      description: 'CAB-POSO',
      isBranch: true,
      isActive: true,
    ),
  ];

  static const Set<String> _protectedLocationIds = {
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
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

  static final LocationRepositoryImpl instance = LocationRepositoryImpl();
  LocationRepositoryImpl({this.apiClient});

  @override
  List<LocationItem> get currentLocations => List.unmodifiable(_locations);

  @override
  Future<Result<List<LocationItem>>> getAllLocations() async {
    if (apiClient != null) {
      try {
        var res = await apiClient!.get('/admin/locations');
        if (res is AppFailure<Map<String, dynamic>>) {
          res = await apiClient!.get('/locations');
        }

        switch (res) {
          case Success(:final data):
            final rawList = data['data'] as List<dynamic>? ?? [];
            final locations = rawList.map((item) {
              final map = item as Map<String, dynamic>;
              final name = (map['name'] ?? '').toString();
              final code = map['code']?.toString();
              final isBranch = (code != null && code.toUpperCase().contains('CAB')) ||
                  name.toLowerCase().contains('cabang');
              final isActive = map['is_active'] == true ||
                  map['is_active'] == 1 ||
                  map['is_active'] == null;
              return LocationItem(
                id: map['id'].toString(),
                name: name,
                description: code ?? map['description']?.toString(),
                isBranch: isBranch,
                isActive: isActive,
              );
            }).toList();

            _locations.clear();
            _locations.addAll(locations);
            return Result.success(List.unmodifiable(locations));
          case AppFailure(:final failure):
            if (_locations.isNotEmpty) {
              return Result.success(List.unmodifiable(_locations));
            }
            return Result.failure(failure);
        }
      } catch (e) {
        if (_locations.isNotEmpty) {
          return Result.success(List.unmodifiable(_locations));
        }
        return Result.failure(ServerFailure(message: e.toString()));
      }
    }
    return Result.success(List.unmodifiable(_locations));
  }

  @override
  Future<Result<List<LocationItem>>> getActiveLocations() async {
    if (apiClient != null) {
      try {
        final res = await apiClient!.get('/locations');
        switch (res) {
          case Success(:final data):
            final rawList = data['data'] as List<dynamic>? ?? [];
            final locations = rawList.map((item) {
              final map = item as Map<String, dynamic>;
              final name = (map['name'] ?? '').toString();
              final code = map['code']?.toString();
              final isBranch = (code != null && code.toUpperCase().contains('CAB')) ||
                  name.toLowerCase().contains('cabang');
              return LocationItem(
                id: map['id'].toString(),
                name: name,
                description: code ?? map['description']?.toString(),
                isBranch: isBranch,
                isActive: true,
              );
            }).toList();
            _locations.clear();
            _locations.addAll(locations);
            return Result.success(List.unmodifiable(locations));
          case AppFailure(:final failure):
            if (failure is UnauthorizedFailure) {
              return Result.failure(failure);
            }
            if (_locations.isNotEmpty) {
              final active = _locations.where((l) => l.isActive).toList();
              return Result.success(List.unmodifiable(active));
            }
            return Result.failure(failure);
        }
      } catch (e) {
        if (_locations.isNotEmpty) {
          final active = _locations.where((l) => l.isActive).toList();
          return Result.success(List.unmodifiable(active));
        }
        return Result.failure(ServerFailure(message: e.toString()));
      }
    }
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

    if (apiClient != null) {
      try {
        final res = await apiClient!.post(
          '/admin/locations',
          body: {
            'name': cleanName,
            if (item.description != null && item.description!.trim().isNotEmpty)
              'code': item.description!.trim(),
            'is_active': item.isActive,
          },
        );
        if (res is Success<Map<String, dynamic>>) {
          final map = res.data['data'] as Map<String, dynamic>;
          final newLocation = LocationItem(
            id: map['id'].toString(),
            name: (map['name'] ?? cleanName).toString(),
            description: map['code']?.toString() ?? item.description?.trim(),
            isBranch: item.isBranch || cleanName.toLowerCase().contains('cabang'),
            isActive: map['is_active'] == true || map['is_active'] == 1 || map['is_active'] == null,
          );
          _locations.add(newLocation);
          return Result.success(newLocation);
        } else if (res is AppFailure<Map<String, dynamic>>) {
          return Result.failure(res.failure);
        }
      } catch (e) {
        return Result.failure(ServerFailure(message: e.toString()));
      }
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

    final isBranch =
        item.isBranch || cleanName.toLowerCase().contains('cabang');

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
    final cleanName = item.name.trim();
    if (cleanName.isEmpty) {
      return Result.failure(
        const ValidationFailure(message: 'Nama lokasi wajib diisi.'),
      );
    }

    if (apiClient != null) {
      try {
        final res = await apiClient!.put(
          '/admin/locations/${item.id}',
          body: {
            'name': cleanName,
            if (item.description != null && item.description!.trim().isNotEmpty)
              'code': item.description!.trim(),
            'is_active': item.isActive,
          },
        );
        if (res is Success<Map<String, dynamic>>) {
          final map = res.data['data'] as Map<String, dynamic>;
          final updated = LocationItem(
            id: map['id'].toString(),
            name: (map['name'] ?? cleanName).toString(),
            description: map['code']?.toString() ?? item.description?.trim(),
            isBranch: item.isBranch || cleanName.toLowerCase().contains('cabang'),
            isActive: map['is_active'] == true || map['is_active'] == 1 || map['is_active'] == null,
          );
          final index = _locations.indexWhere((l) => l.id == item.id);
          if (index != -1) {
            _locations[index] = updated;
          }
          return Result.success(updated);
        } else if (res is AppFailure<Map<String, dynamic>>) {
          return Result.failure(res.failure);
        }
      } catch (e) {
        return Result.failure(ServerFailure(message: e.toString()));
      }
    }

    final index = _locations.indexWhere((l) => l.id == item.id);
    if (index == -1) {
      return Result.failure(
        const NotFoundFailure(message: 'Lokasi tidak ditemukan.'),
      );
    }

    final duplicate = _locations.any(
      (l) => l.id != item.id && l.name.toLowerCase() == cleanName.toLowerCase(),
    );
    if (duplicate) {
      return Result.failure(
        ValidationFailure(message: 'Lokasi "$cleanName" sudah ada.'),
      );
    }

    final isBranch =
        item.isBranch || cleanName.toLowerCase().contains('cabang');

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
    if (apiClient != null) {
      try {
        final res = await apiClient!.put(
          '/admin/locations/$id',
          body: {'is_active': isActive},
        );
        if (res is Success<Map<String, dynamic>>) {
          final index = _locations.indexWhere((l) => l.id == id);
          if (index != -1) {
            _locations[index] = _locations[index].copyWith(isActive: isActive);
          }
          return Result.success(null);
        } else if (res is AppFailure<Map<String, dynamic>>) {
          return Result.failure(res.failure);
        }
      } catch (e) {
        return Result.failure(ServerFailure(message: e.toString()));
      }
    }

    final index = _locations.indexWhere((l) => l.id == id);
    if (index == -1) {
      return Result.failure(
        const NotFoundFailure(message: 'Lokasi tidak ditemukan.'),
      );
    }

    _locations[index] = _locations[index].copyWith(isActive: isActive);
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteLocation(String id) async {
    if (apiClient != null) {
      try {
        final res = await apiClient!.delete('/admin/locations/$id');
        if (res is Success<Map<String, dynamic>>) {
          _locations.removeWhere((l) => l.id == id);
          return Result.success(null);
        } else if (res is AppFailure<Map<String, dynamic>>) {
          return Result.failure(res.failure);
        }
      } catch (e) {
        return Result.failure(ServerFailure(message: e.toString()));
      }
    }

    if (_protectedLocationIds.contains(id)) {
      return Result.failure(
        const ValidationFailure(
          message: 'Lokasi default/histori tidak dapat dihapus permanen karena masih direferensikan. Silakan nonaktifkan lokasi.',
        ),
      );
    }

    _locations.removeWhere((l) => l.id == id);
    return Result.success(null);
  }
}
