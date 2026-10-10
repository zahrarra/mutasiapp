// lib/features/asset/data/repositories/asset_repository_impl.dart
//
// Implementasi AssetRepository dengan data mock aset.
// Sumber: SKILLS.md §7, TECHNICAL-DESIGN.md.

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/asset_model.dart';
import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_category.dart';
import '../../domain/entities/asset_history_item.dart';
import '../../domain/entities/asset_status.dart';
import '../../domain/repositories/asset_repository.dart';

class AssetRepositoryImpl implements AssetRepository {
  final ApiClient? apiClient;

  AssetRepositoryImpl({this.apiClient});
  static final List<AssetCategory> _mockCategories = [
    const AssetCategory(
      id: 'cat_1',
      code: 'ELK',
      name: 'Elektronik & IT',
      description: 'Laptop, Monitor, Printer',
      isActive: true,
    ),
    const AssetCategory(
      id: 'cat_2',
      code: 'FUR',
      name: 'Furniture & Mebel',
      description: 'Meja Kerja, Kursi Kantor, Lemari',
      isActive: true,
    ),
    const AssetCategory(
      id: 'cat_3',
      code: 'VEH',
      name: 'Kendaraan Operasional',
      description: 'Mobil Dinas, Sepeda Motor',
      isActive: true,
    ),
    const AssetCategory(
      id: 'cat_4',
      code: 'NET',
      name: 'Perangkat Jaringan',
      description: 'Switch, Router, Access Point',
      isActive: true,
    ),
  ];

  static List<Asset> _generateInitialMockAssets() => [
    Asset(
      id: 'ast_1',
      assetCode: 'AST-ELK-2024-001',
      name: 'Laptop Lenovo ThinkPad T14 Gen 3',
      category: _mockCategories[0],
      location: 'Lantai 3 — Ruang IT Developer',
      pic: 'Budi Santoso (IT Dept)',
      status: AssetStatus.available,
      condition: 'Baik',
      serialNumber: 'PF-39X1A8',
      acquisitionYear: 2024,
      estimatedValue: 18500000.0,
      hasActiveMutation: false,
      history: [
        AssetHistoryItem(
          id: 'hist_1',
          ticketNumber: 'MUT-2025-0012',
          date: DateTime(2025, 6, 15),
          previousLocation: 'Lantai 1 — Gudang Aset',
          newLocation: 'Lantai 3 — Ruang IT Developer',
          previousPic: 'Bagian Aset (Gudang)',
          newPic: 'Budi Santoso (IT Dept)',
          updatedBy: 'Bagian Aset — Rizky',
        ),
      ],
    ),
    Asset(
      id: 'ast_2',
      assetCode: 'AST-ELK-2024-002',
      name: 'MacBook Pro M2 16 Inch',
      category: _mockCategories[0],
      location: 'Lantai 4 — Ruang Kadiv Aset',
      pic: 'Drs. Ahmad Dahlan (Kadiv)',
      status: AssetStatus.inMutation,
      condition: 'Sangat Baik',
      serialNumber: 'C02G9012MD6M',
      acquisitionYear: 2024,
      estimatedValue: 35000000.0,
      hasActiveMutation: true,
      activeMutationTicket: 'MUT-2026-0042',
      history: [
        AssetHistoryItem(
          id: 'hist_2',
          ticketNumber: 'MUT-2024-0099',
          date: DateTime(2024, 11, 1),
          previousLocation: 'Lantai 1 — Pembelian Baru',
          newLocation: 'Lantai 4 — Ruang Kadiv Aset',
          previousPic: 'Procurement Team',
          newPic: 'Drs. Ahmad Dahlan (Kadiv)',
          updatedBy: 'Bagian Aset — Rizky',
        ),
      ],
    ),
    Asset(
      id: 'ast_3',
      assetCode: 'AST-FUR-2023-015',
      name: 'Kursi Kerja Ergonomis Ergohuman',
      category: _mockCategories[1],
      location: 'Lantai 2 — Ruang Keuangan',
      pic: 'Siti Aminah (Finance)',
      status: AssetStatus.available,
      condition: 'Baik',
      serialNumber: 'EGO-8842-ID',
      acquisitionYear: 2023,
      estimatedValue: 4500000.0,
      hasActiveMutation: false,
    ),
    Asset(
      id: 'ast_4',
      assetCode: 'AST-NET-2025-004',
      name: 'Cisco Catalyst Switch 24-Port',
      category: _mockCategories[3],
      location: 'Lantai Server — Server Room B',
      pic: 'Network Support Team',
      status: AssetStatus.maintenance,
      condition: 'Perlu Perbaikan Fan',
      serialNumber: 'SN-CSC-994821',
      acquisitionYear: 2025,
      estimatedValue: 65000000.0,
      hasActiveMutation: false,
    ),
    Asset(
      id: 'ast_5',
      assetCode: 'AST-VEH-2022-001',
      name: 'Toyota Avanza 1.5 G M/T',
      category: _mockCategories[2],
      location: 'Gedung A — Parkir Operasional',
      pic: 'Driver Operasional General Affair',
      status: AssetStatus.available,
      condition: 'Baik',
      serialNumber: 'B-1234-SDK',
      acquisitionYear: 2022,
      estimatedValue: 180000000.0,
      hasActiveMutation: false,
    ),
    Asset(
      id: 'AST-PRN-009',
      assetCode: 'AST-PRN-009',
      name: 'Printer Epson L3210',
      category: _mockCategories[0],
      location: 'Ruang IT Pusat',
      pic: 'Staff IT (Pusat)',
      status: AssetStatus.available,
      condition: 'Baik',
      serialNumber: 'SN-EPS-009812',
      acquisitionYear: 2024,
      estimatedValue: 2800000.0,
      hasActiveMutation: false,
    ),
    Asset(
      id: 'AST-00124',
      assetCode: 'AST-ELK-2024-0124',
      name: 'Laptop Dell Latitude',
      category: _mockCategories[0],
      location: 'Kantor Pusat',
      pic: 'Rina',
      status: AssetStatus.available,
      condition: 'Baik',
      serialNumber: 'DL-7490-X1',
      acquisitionYear: 2024,
      estimatedValue: 14000000.0,
    ),
    Asset(
      id: 'AST-00042',
      assetCode: 'AST-VEH-2023-0042',
      name: 'Toyota Avanza 1.3 G',
      category: _mockCategories[2],
      location: 'Gedung A — Parkir Operasional',
      pic: 'Driver Operasional General Affair',
      status: AssetStatus.available,
      condition: 'Baik',
      serialNumber: 'B-2891-KFG',
      acquisitionYear: 2023,
      estimatedValue: 165000000.0,
    ),
    Asset(
      id: 'ast_6',
      assetCode: 'AST-ELK-2024-006',
      name: 'Monitor Dell UltraSharp 27 Inch 4K',
      category: _mockCategories[0],
      location: 'Lantai 3 — Ruang IT Developer',
      pic: 'Budi Santoso (IT Dept)',
      status: AssetStatus.available,
      condition: 'Sangat Baik',
      serialNumber: 'CN-0K382-74261',
      acquisitionYear: 2024,
      estimatedValue: 8500000.0,
      hasActiveMutation: false,
    ),
    Asset(
      id: 'ast_7',
      assetCode: 'AST-FUR-2024-007',
      name: 'Meja Kerja Ergonomis Standing Desk',
      category: _mockCategories[1],
      location: 'Lantai 3 — Ruang IT Developer',
      pic: 'Budi Santoso (IT Dept)',
      status: AssetStatus.available,
      condition: 'Baik',
      serialNumber: 'FUR-DSK-2024-01',
      acquisitionYear: 2024,
      estimatedValue: 5500000.0,
      hasActiveMutation: false,
    ),
  ];

  static List<Asset> _mockAssets = _generateInitialMockAssets();

  /// Reset state untuk testing.
  static void resetForTesting() {
    _mockAssets = _generateInitialMockAssets();
  }

  @override
  Future<Result<List<Asset>>> getAssets({
    String? query,
    String? categoryId,
    String? location,
    AssetStatus? status,
    bool? mine,
  }) async {
    if (apiClient != null) {
      final queryParams = <String, String>{};
      if (mine == true) {
        queryParams['mine'] = 'true';
      }
      final response = await apiClient!.get(
        '/api/v1/assets',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );
      switch (response) {
        case Success(:final data):
          final list = data['data'] as List<dynamic>? ?? [];
          List<Asset> assets = list
              .whereType<Map<String, dynamic>>()
              .map(AssetModel.fromJson)
              .toList();

          if (query != null && query.trim().isNotEmpty) {
            final q = query.toLowerCase().trim();
            assets = assets.where((asset) {
              return asset.name.toLowerCase().contains(q) ||
                  asset.assetCode.toLowerCase().contains(q) ||
                  asset.pic.toLowerCase().contains(q) ||
                  asset.location.toLowerCase().contains(q);
            }).toList();
          }

          if (categoryId != null && categoryId.isNotEmpty) {
            assets = assets
                .where((asset) => asset.category.id == categoryId)
                .toList();
          }

          if (status != null) {
            assets = assets.where((asset) => asset.status == status).toList();
          }

          return Result.success(assets);
        case AppFailure(:final failure):
          return Result.failure(failure);
      }
    }

    List<Asset> filtered = List.from(_mockAssets);

    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase().trim();
      filtered = filtered.where((asset) {
        return asset.name.toLowerCase().contains(q) ||
            asset.assetCode.toLowerCase().contains(q) ||
            asset.pic.toLowerCase().contains(q) ||
            asset.location.toLowerCase().contains(q);
      }).toList();
    }

    if (categoryId != null && categoryId.isNotEmpty) {
      filtered = filtered
          .where((asset) => asset.category.id == categoryId)
          .toList();
    }

    if (status != null) {
      filtered = filtered.where((asset) => asset.status == status).toList();
    }

    return Result.success(filtered);
  }

  @override
  Future<Result<Asset>> getAssetById(String id) async {
    if (apiClient != null) {
      final response = await apiClient!.get('/api/v1/assets/$id');
      switch (response) {
        case Success(:final data):
          final assetMap = data['data'] as Map<String, dynamic>?;
          if (assetMap != null) {
            return Result.success(AssetModel.fromJson(assetMap));
          }
        case AppFailure(:final failure):
          if (!SecureStorage.isTestEnvironment) {
            return Result.failure(failure);
          }
          break;
      }
    }

    try {
      final asset = _mockAssets.firstWhere(
        (a) => a.id == id || a.assetCode == id,
      );
      return Result.success(asset);
    } catch (_) {
      return Result.failure(
        const NotFoundFailure(message: 'Aset tidak ditemukan.'),
      );
    }
  }

  @override
  Future<Result<List<AssetHistoryItem>>> getAssetHistory(String assetId) async {
    if (apiClient != null) {
      final cleanId = assetId.replaceAll('ast_', '');
      final res = await apiClient!.get('/assets/$cleanId/history');
      if (res is Success<Map<String, dynamic>>) {
        final rawList = res.data['data'] as List<dynamic>? ?? [];
        final list = rawList.map((item) {
          final map = item as Map<String, dynamic>;
          final prevLoc = map['previous_location'] is Map
              ? map['previous_location']['name']?.toString()
              : map['previous_location_id']?.toString();
          final newLoc = map['new_location'] is Map
              ? map['new_location']['name']?.toString()
              : map['new_location_id']?.toString();
          final prevPic = map['previous_pic'] is Map
              ? map['previous_pic']['name']?.toString()
              : map['previous_pic_id']?.toString();
          final newPic = map['new_pic'] is Map
              ? map['new_pic']['name']?.toString()
              : map['new_pic_id']?.toString();
          final updater = map['updater'] is Map
              ? map['updater']['name']?.toString()
              : map['updated_by']?.toString();

          return AssetHistoryItem(
            id: (map['id'] ?? '').toString(),
            ticketNumber: (map['ticket_number'] ?? '-').toString(),
            date: DateTime.tryParse(map['date']?.toString() ?? '') ??
                DateTime.tryParse(map['created_at']?.toString() ?? '') ??
                DateTime.now(),
            previousLocation: prevLoc ?? '-',
            newLocation: newLoc ?? '-',
            previousPic: prevPic ?? '-',
            newPic: newPic ?? '-',
            updatedBy: updater ?? 'System',
          );
        }).toList();
        return Result.success(List.unmodifiable(list));
      } else if (res is AppFailure<Map<String, dynamic>>) {
        return Result.failure(res.failure);
      }
    }

    try {
      final asset = _mockAssets.firstWhere((a) => a.id == assetId || a.assetCode == assetId);
      return Result.success(asset.history);
    } catch (_) {
      return Result.failure(
        const NotFoundFailure(message: 'Riwayat aset tidak ditemukan.'),
      );
    }
  }


  @override
  Future<Result<List<AssetCategory>>> getCategories() async {
    if (apiClient != null) {
      try {
        final res = await apiClient!.get('/asset-categories');
        if (res is Success<Map<String, dynamic>>) {
          final rawList = res.data['data'] as List<dynamic>? ?? [];
          final list = rawList.map((item) {
            final map = item as Map<String, dynamic>;
            return AssetCategory(
              id: map['id'].toString(),
              code: (map['code'] ?? '').toString(),
              name: (map['name'] ?? '').toString(),
              description: map['description']?.toString(),
              isActive: map['is_active'] != false,
            );
          }).toList();
          return Result.success(List.unmodifiable(list));
        } else if (res is AppFailure<Map<String, dynamic>>) {
          return Result.failure(res.failure);
        }
      } catch (e) {
        return Result.failure(ServerFailure(message: e.toString()));
      }
    }
    return Result.success(List.unmodifiable(_mockCategories));
  }

  @override
  Future<Result<AssetCategory>> addCategory(AssetCategory category) async {
    final cleanName = category.name.trim();
    final cleanCode = category.code.trim().toUpperCase();
    if (cleanName.isEmpty || cleanCode.isEmpty) {
      return Result.failure(
        const ValidationFailure(message: 'Kode dan nama kategori wajib diisi.'),
      );
    }

    if (apiClient != null) {
      try {
        final res = await apiClient!.post(
          '/admin/asset-categories',
          body: {
            'name': cleanName,
            'code': cleanCode,
          },
        );
        if (res is Success<Map<String, dynamic>>) {
          final map = res.data['data'] as Map<String, dynamic>;
          final newCategory = AssetCategory(
            id: map['id'].toString(),
            code: (map['code'] ?? cleanCode).toString(),
            name: (map['name'] ?? cleanName).toString(),
            description: map['description']?.toString() ?? category.description?.trim(),
            isActive: true,
          );
          _mockCategories.add(newCategory);
          return Result.success(newCategory);
        } else if (res is AppFailure<Map<String, dynamic>>) {
          return Result.failure(res.failure);
        }
      } catch (e) {
        return Result.failure(ServerFailure(message: e.toString()));
      }
    }


    final exists = _mockCategories.any(
      (c) =>
          c.code.toUpperCase() == cleanCode ||
          c.name.toLowerCase() == cleanName.toLowerCase(),
    );
    if (exists) {
      return Result.failure(
        ValidationFailure(
          message:
              'Kategori dengan kode "$cleanCode" atau nama "$cleanName" sudah ada.',
        ),
      );
    }

    final newId = category.id.isNotEmpty
        ? category.id
        : 'cat_${DateTime.now().millisecondsSinceEpoch}';

    final newCategory = category.copyWith(
      id: newId,
      code: cleanCode,
      name: cleanName,
      description: category.description?.trim(),
      isActive: true,
    );

    _mockCategories.add(newCategory);
    return Result.success(newCategory);
  }

  @override
  Future<Result<AssetCategory>> updateCategory(AssetCategory category) async {
    final cleanName = category.name.trim();
    final cleanCode = category.code.trim().toUpperCase();
    if (cleanName.isEmpty || cleanCode.isEmpty) {
      return Result.failure(
        const ValidationFailure(message: 'Kode dan nama kategori wajib diisi.'),
      );
    }

    if (apiClient != null) {
      try {
        final res = await apiClient!.put(
          '/admin/asset-categories/${category.id}',
          body: {
            'name': cleanName,
            'code': cleanCode,
          },
        );
        if (res is Success<Map<String, dynamic>>) {
          final map = res.data['data'] as Map<String, dynamic>;
          final updated = AssetCategory(
            id: map['id'].toString(),
            code: (map['code'] ?? cleanCode).toString(),
            name: (map['name'] ?? cleanName).toString(),
            description: map['description']?.toString() ?? category.description?.trim(),
            isActive: true,
          );
          final idx = _mockCategories.indexWhere((c) => c.id == category.id);
          if (idx != -1) _mockCategories[idx] = updated;
          return Result.success(updated);
        } else if (res is AppFailure<Map<String, dynamic>>) {
          return Result.failure(res.failure);
        }
      } catch (e) {
        return Result.failure(ServerFailure(message: e.toString()));
      }
    }


    final index = _mockCategories.indexWhere((c) => c.id == category.id);
    if (index == -1) {
      return Result.failure(
        const NotFoundFailure(message: 'Kategori tidak ditemukan.'),
      );
    }

    final duplicate = _mockCategories.any(
      (c) =>
          c.id != category.id &&
          (c.code.toUpperCase() == cleanCode ||
              c.name.toLowerCase() == cleanName.toLowerCase()),
    );
    if (duplicate) {
      return Result.failure(
        ValidationFailure(
          message: 'Kode "$cleanCode" atau nama "$cleanName" sudah digunakan.',
        ),
      );
    }

    final updated = category.copyWith(
      code: cleanCode,
      name: cleanName,
      description: category.description?.trim(),
    );

    _mockCategories[index] = updated;
    return Result.success(updated);
  }

  @override
  Future<Result<void>> toggleCategoryActive(String id, bool isActive) async {
    final index = _mockCategories.indexWhere((c) => c.id == id);
    if (index == -1) {
      return Result.failure(
        const NotFoundFailure(message: 'Kategori tidak ditemukan.'),
      );
    }

    _mockCategories[index] = _mockCategories[index].copyWith(
      isActive: isActive,
    );
    return Result.success(null);
  }

  @override
  Future<Result<void>> deleteCategory(String id) async {
    if (apiClient != null) {
      try {
        final res = await apiClient!.delete('/admin/asset-categories/$id');
        if (res is Success<Map<String, dynamic>>) {
          _mockCategories.removeWhere((c) => c.id == id);
          return Result.success(null);
        } else if (res is AppFailure<Map<String, dynamic>>) {
          return Result.failure(res.failure);
        }
      } catch (e) {
        return Result.failure(ValidationFailure(message: e.toString()));
      }
    }


    final isUsed = _mockAssets.any(
      (a) => a.category.id == id || a.category.code == id,
    );
    if (isUsed) {
      return Result.failure(
        const ValidationFailure(
          message:
              'Kategori tidak dapat dihapus permanen karena masih digunakan oleh aset terdaftar. Silakan nonaktifkan kategori.',
        ),
      );
    }

    _mockCategories.removeWhere((c) => c.id == id);
    return Result.success(null);
  }

  @override
  Future<Result<Asset>> updateAssetLocationAndPic({
    required String assetId,
    required String newLocation,
    required String newPic,
    required String ticketNumber,
    required String updatedBy,
  }) async {
    final index = _mockAssets.indexWhere(
      (a) => a.id == assetId || a.assetCode == assetId,
    );

    final historyItem = AssetHistoryItem(
      id: 'hist_${DateTime.now().millisecondsSinceEpoch}',
      ticketNumber: ticketNumber,
      date: DateTime.now(),
      previousLocation: index != -1 ? _mockAssets[index].location : '-',
      newLocation: newLocation,
      previousPic: index != -1 ? _mockAssets[index].pic : '-',
      newPic: newPic,
      updatedBy: updatedBy,
    );

    if (index == -1) {
      final newAsset = Asset(
        id: assetId,
        assetCode: assetId,
        name: 'Aset $assetId',
        category: _mockCategories[0],
        location: newLocation,
        pic: newPic,
        status: AssetStatus.inMutation,
        condition: 'Baik',
        acquisitionYear: DateTime.now().year,
        history: [historyItem],
      );
      _mockAssets.add(newAsset);
      return Result.success(newAsset);
    }

    final current = _mockAssets[index];
    final updated = current.copyWith(
      location: newLocation,
      pic: newPic,
      history: [...current.history, historyItem],
    );

    _mockAssets[index] = updated;
    return Result.success(updated);
  }

  @override
  Future<Result<Asset>> updateAsset(Asset asset) async {
    final index = _mockAssets.indexWhere(
      (a) => a.id == asset.id || a.assetCode == asset.assetCode,
    );
    if (index == -1) {
      _mockAssets.add(asset);
      return Result.success(asset);
    }
    _mockAssets[index] = asset;
    return Result.success(asset);
  }

  @override
  Future<Result<Asset>> createAsset(CreateAssetParams params) async {
    if (apiClient != null) {
      // 1. Resolve asset_category_id (harus integer yang valid di tabel asset_categories)
      int? categoryId = int.tryParse(params.assetCategoryId);
      if (categoryId == null) {
        try {
          final catRes = await apiClient!.get('/api/v1/asset-categories');
          if (catRes is Success<Map<String, dynamic>>) {
            final list = catRes.data['data'] as List<dynamic>? ?? [];
            for (final item in list) {
              if (item is Map<String, dynamic>) {
                final id = int.tryParse(item['id']?.toString() ?? '');
                final code = item['code']?.toString().toLowerCase();
                final name = item['name']?.toString().toLowerCase();
                final paramLower = params.assetCategoryId.toLowerCase();
                if (id != null &&
                    (code == paramLower ||
                        name == paramLower ||
                        paramLower.contains(code ?? ''))) {
                  categoryId = id;
                  break;
                }
              }
            }
          }
        } catch (_) {}
      }
      categoryId ??= 1;

      // 2. Resolve location_id (harus integer yang valid di tabel locations)
      int? locationId = int.tryParse(params.locationId);
      if (locationId == null) {
        try {
          final locRes = await apiClient!.get('/api/v1/locations');
          if (locRes is Success<Map<String, dynamic>>) {
            final list = locRes.data['data'] as List<dynamic>? ?? [];
            for (final item in list) {
              if (item is Map<String, dynamic>) {
                final id = int.tryParse(item['id']?.toString() ?? '');
                final name = item['name']?.toString().toLowerCase() ?? '';
                final code = item['code']?.toString().toLowerCase() ?? '';
                final paramLower = params.locationId.toLowerCase();
                if (id != null &&
                    (paramLower.contains(name) ||
                        name.contains(paramLower) ||
                        code == paramLower)) {
                  locationId = id;
                  break;
                }
              }
            }
          }
        } catch (_) {}
      }
      locationId ??= 1;

      // 3. Resolve pic_id (harus integer yang valid dan aktif di tabel users)
      int? picId = int.tryParse(params.picId);
      if (picId == null) {
        try {
          final usersRes = await apiClient!.get('/api/v1/admin/users');
          if (usersRes is Success<Map<String, dynamic>>) {
            final list = usersRes.data['data'] as List<dynamic>? ?? [];
            final pLower = params.picId.toLowerCase().trim();
            for (final item in list) {
              if (item is Map<String, dynamic>) {
                final id = int.tryParse(item['id']?.toString() ?? '');
                final name = item['name']?.toString().toLowerCase() ?? '';
                final email = item['email']?.toString().toLowerCase() ?? '';
                final nip = item['nip']?.toString().toLowerCase() ?? '';
                final isActive = item['is_active'] == true || item['is_active'] == 1;
                if (id != null && isActive &&
                    (name == pLower ||
                        email == pLower ||
                        nip == pLower ||
                        pLower.contains(name) ||
                        name.contains(pLower))) {
                  picId = id;
                  break;
                }
              }
            }
          }
        } catch (_) {}
      }

      final body = <String, dynamic>{
        'asset_code': params.assetCode.trim(),
        'name': params.name.trim(),
        'asset_category_id': categoryId,
        'location_id': locationId,
        'pic_id': picId,
        'condition': params.condition.trim(),
        'serial_number': params.serialNumber.trim(),
        'acquisition_year': params.acquisitionYear,
        if (params.usageYear != null) 'usage_year': params.usageYear,
        'is_active': params.isActive,
      };

      final response = await apiClient!.post(
        '/api/v1/admin/assets',
        body: body,
      );

      switch (response) {
        case Success(:final data):
          final success = data['success'] as bool? ?? true;
          if (!success) {
            return Result.failure(
              ServerFailure(
                message:
                    data['message'] as String? ?? 'Gagal menambahkan aset.',
              ),
            );
          }
          final assetMap = data['data'] as Map<String, dynamic>?;
          if (assetMap == null) {
            return const Result.failure(
              ServerFailure(message: 'Data response aset tidak valid.'),
            );
          }
          try {
            final newAsset = AssetModel.fromJson(assetMap);
            final existingIndex =
                _mockAssets.indexWhere((a) => a.id == newAsset.id);
            if (existingIndex != -1) {
              _mockAssets[existingIndex] = newAsset;
            } else {
              _mockAssets.insert(0, newAsset);
            }
            return Result.success(newAsset);
          } catch (e) {
            return Result.failure(
              ServerFailure(message: 'Format data aset tidak valid: $e'),
            );
          }
        case AppFailure(:final failure):
          return Result.failure(failure);
      }
    }

    final category = _mockCategories.firstWhere(
      (c) => c.id == params.assetCategoryId,
      orElse: () => AssetCategory(
        id: params.assetCategoryId,
        code: 'CAT',
        name: 'Kategori ${params.assetCategoryId}',
        isActive: true,
      ),
    );
    final newAsset = Asset(
      id: 'ast_${DateTime.now().millisecondsSinceEpoch}',
      assetCode: params.assetCode.trim(),
      name: params.name.trim(),
      category: category,
      location: 'Lokasi ${params.locationId}',
      pic: 'PIC ${params.picId}',
      status: AssetStatus.available,
      condition: params.condition.trim(),
      serialNumber: params.serialNumber.trim(),
      acquisitionYear: params.acquisitionYear,
      hasActiveMutation: false,
    );
    _mockAssets.insert(0, newAsset);
    return Result.success(newAsset);
  }
}
