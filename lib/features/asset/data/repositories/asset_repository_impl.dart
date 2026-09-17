// lib/features/asset/data/repositories/asset_repository_impl.dart
//
// Implementasi AssetRepository dengan data mock aset.
// Sumber: SKILLS.md §7, TECHNICAL-DESIGN.md.

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_category.dart';
import '../../domain/entities/asset_history_item.dart';
import '../../domain/entities/asset_status.dart';
import '../../domain/repositories/asset_repository.dart';

class AssetRepositoryImpl implements AssetRepository {
  static const List<AssetCategory> _mockCategories = [
    AssetCategory(id: 'cat_1', code: 'ELK', name: 'Elektronik & IT', description: 'Laptop, Monitor, Printer'),
    AssetCategory(id: 'cat_2', code: 'FUR', name: 'Furniture & Mebel', description: 'Meja Kerja, Kursi Kantor, Lemari'),
    AssetCategory(id: 'cat_3', code: 'VEH', name: 'Kendaraan Operasional', description: 'Mobil Dinas, Sepeda Motor'),
    AssetCategory(id: 'cat_4', code: 'NET', name: 'Perangkat Jaringan', description: 'Switch, Router, Access Point'),
  ];

  static final List<Asset> _mockAssets = [
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
      hasActiveMutation: false,
      history: [
        AssetHistoryItem(
          id: 'hist_1',
          ticketNumber: 'MUT-2025-0012',
          date: DateTime(2025, 6, 15),
          previousLocation: 'Lantai 1 — Gudang Aset',
          newLocation: 'Lantai 3 — Ruang IT Developer',
          previousPic: 'Staff Aset (Gudang)',
          newPic: 'Budi Santoso (IT Dept)',
          updatedBy: 'Staff Aset — Rizky',
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
          updatedBy: 'Staff Aset — Rizky',
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
      hasActiveMutation: false,
    ),
  ];

  @override
  Future<Result<List<Asset>>> getAssets({
    String? query,
    String? categoryId,
    String? location,
    AssetStatus? status,
  }) async {
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
      filtered = filtered.where((asset) => asset.category.id == categoryId).toList();
    }

    if (status != null) {
      filtered = filtered.where((asset) => asset.status == status).toList();
    }

    return Result.success(filtered);
  }

  @override
  Future<Result<Asset>> getAssetById(String id) async {
    try {
      final asset = _mockAssets.firstWhere((a) => a.id == id);
      return Result.success(asset);
    } catch (_) {
      return Result.failure(const NotFoundFailure(message: 'Aset tidak ditemukan.'));
    }
  }

  @override
  Future<Result<List<AssetHistoryItem>>> getAssetHistory(String assetId) async {
    try {
      final asset = _mockAssets.firstWhere((a) => a.id == assetId);
      return Result.success(asset.history);
    } catch (_) {
      return Result.failure(const NotFoundFailure(message: 'Riwayat aset tidak ditemukan.'));
    }
  }

  @override
  Future<Result<List<AssetCategory>>> getCategories() async {
    return Result.success(_mockCategories);
  }
}
