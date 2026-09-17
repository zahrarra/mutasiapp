// lib/features/asset/domain/entities/asset_history_item.dart
//
// Entity domain: AssetHistoryItem (Riwayat Mutasi / Perubahan Aset).
// Sumber: SKILLS.md §7, TECHNICAL-DESIGN.md.

class AssetHistoryItem {
  final String id;
  final String ticketNumber;
  final DateTime date;
  final String previousLocation;
  final String newLocation;
  final String previousPic;
  final String newPic;
  final String updatedBy;

  const AssetHistoryItem({
    required this.id,
    required this.ticketNumber,
    required this.date,
    required this.previousLocation,
    required this.newLocation,
    required this.previousPic,
    required this.newPic,
    required this.updatedBy,
  });
}
