// lib/features/asset/domain/entities/asset.dart
//
// Domain Entity: Asset.
// Sumber: SKILLS.md §7 (asset-management), TECHNICAL-DESIGN.md §8, §23 (Asset Lock).

import 'asset_category.dart';
import 'asset_history_item.dart';
import 'asset_status.dart';

/// Domain entity utama untuk Aset MutasiKu.
class Asset {
  final String id;

  /// Nomor / Kode Unik Aset (misal: AST-2026-0042)
  final String assetCode;

  /// Nama aset (misal: Laptop Lenovo ThinkPad T14)
  final String name;

  /// Kategori aset
  final AssetCategory category;

  /// Lokasi fisik aset saat ini
  final String location;

  /// Penanggung jawab (PIC) aset saat ini
  final String pic;

  /// Status ketersediaan / operasional aset
  final AssetStatus status;

  /// Kondisi fisik (Baik, Rusak Ringan, Rusak Berat)
  final String condition;

  /// Nomor seri manufaktur (opsional)
  final String? serialNumber;

  /// Tahun perolehan / pengadaan
  final int acquisitionYear;

  /// Menandakan apakah aset sedang memiliki mutasi aktif yang belum selesai.
  /// Sumber: TECHNICAL-DESIGN.md §23 (Asset Lock).
  final bool hasActiveMutation;

  /// Nomor tiket mutasi aktif (jika [hasActiveMutation] true)
  final String? activeMutationTicket;

  /// Riwayat mutasi aset
  final List<AssetHistoryItem> history;

  const Asset({
    required this.id,
    required this.assetCode,
    required this.name,
    required this.category,
    required this.location,
    required this.pic,
    required this.status,
    required this.condition,
    this.serialNumber,
    required this.acquisitionYear,
    this.hasActiveMutation = false,
    this.activeMutationTicket,
    this.history = const [],
  });

  /// Status kunci mutasi: jika status == inMutation atau hasActiveMutation == true.
  bool get isLocked => hasActiveMutation || status == AssetStatus.inMutation;

  Asset copyWith({
    String? id,
    String? assetCode,
    String? name,
    AssetCategory? category,
    String? location,
    String? pic,
    AssetStatus? status,
    String? condition,
    String? serialNumber,
    int? acquisitionYear,
    bool? hasActiveMutation,
    String? activeMutationTicket,
    List<AssetHistoryItem>? history,
  }) {
    return Asset(
      id: id ?? this.id,
      assetCode: assetCode ?? this.assetCode,
      name: name ?? this.name,
      category: category ?? this.category,
      location: location ?? this.location,
      pic: pic ?? this.pic,
      status: status ?? this.status,
      condition: condition ?? this.condition,
      serialNumber: serialNumber ?? this.serialNumber,
      acquisitionYear: acquisitionYear ?? this.acquisitionYear,
      hasActiveMutation: hasActiveMutation ?? this.hasActiveMutation,
      activeMutationTicket: activeMutationTicket ?? this.activeMutationTicket,
      history: history ?? this.history,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Asset &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          assetCode == other.assetCode &&
          name == other.name &&
          hasActiveMutation == other.hasActiveMutation;

  @override
  int get hashCode =>
      id.hashCode ^ assetCode.hashCode ^ name.hashCode ^ hasActiveMutation.hashCode;
}
